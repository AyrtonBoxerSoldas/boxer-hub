-- Achado ao ligar o fluxo de pedido (2026-08-28): hub_fn_calcular_preco,
-- hub_fn_validar_credito e hub_fn_submeter_pedido sao SECURITY DEFINER e nao
-- conferiam se o cliente_id/pedido_id pertence a quem chama. Qualquer
-- autenticado podia, chamando a RPC direto, ver preco negociado e limite de
-- credito de outro cliente, ou submeter o pedido de outro. A policy de
-- insert em hub_pedido_itens tambem so exigia status='rascunho', sem checar
-- dono do pedido.
--
-- Regra de acesso replicada das policies de hub_pedidos: dealer no proprio
-- cliente_id, representante nos clientes da carteira, staff (admin/manager/
-- analyst/financial) em qualquer um.

CREATE OR REPLACE FUNCTION comercial.hub_pode_acessar_cliente(p_cliente_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = comercial, public
AS $$
  SELECT
    (comercial.hub_user_tipo() = 'cliente' AND p_cliente_id = comercial.hub_user_cliente_id())
    OR (comercial.hub_user_tipo() = 'representante' AND p_cliente_id IN (
          SELECT cliente_id FROM comercial.hub_carteira
           WHERE representante_id = comercial.hub_user_representante_id() AND ativo = true))
    OR comercial.hub_user_role() = ANY (ARRAY['admin', 'manager', 'analyst', 'financial']);
$$;

COMMENT ON FUNCTION comercial.hub_pode_acessar_cliente(uuid) IS
  'Mesma regra de dono das policies de hub_pedidos. Usada nas RPCs SECURITY DEFINER para nao vazar preco/credito de outro cliente.';

GRANT EXECUTE ON FUNCTION comercial.hub_pode_acessar_cliente(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION comercial.hub_fn_calcular_preco(p_cliente_id uuid, p_produto_id uuid, p_quantidade integer DEFAULT 1)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_tabela_id uuid;
  v_item record;
  v_promo record;
  v_preco_final numeric(12,2);
begin
  if not comercial.hub_pode_acessar_cliente(p_cliente_id) then
    return jsonb_build_object('ok', false, 'erro', 'Acesso negado');
  end if;

  select tabela_preco_id into v_tabela_id
  from comercial.hub_clientes
  where id = p_cliente_id and ativo = true;

  if v_tabela_id is null then
    return jsonb_build_object('ok', false, 'erro', 'Cliente sem tabela de preco vinculada');
  end if;

  select * into v_item
  from comercial.hub_tabela_preco_itens
  where tabela_preco_id = v_tabela_id
    and produto_id = p_produto_id;

  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Produto nao encontrado na tabela de precos');
  end if;

  v_preco_final := v_item.preco_base;

  select cp.preco_promocional, cp.desconto_percentual,
         cp.quantidade_limite, cp.quantidade_vendida
  into v_promo
  from comercial.hub_campanha_produtos cp
  join comercial.hub_campanhas ca on ca.id = cp.campanha_id
  where cp.produto_id = p_produto_id
    and ca.ativo = true
    and current_date between ca.data_inicio and ca.data_fim
    and (cp.quantidade_limite is null or cp.quantidade_vendida < cp.quantidade_limite)
  order by ca.data_inicio desc
  limit 1;

  if found then
    if v_promo.preco_promocional is not null then
      v_preco_final := v_promo.preco_promocional;
    elsif v_promo.desconto_percentual is not null then
      v_preco_final := v_item.preco_base * (1 - v_promo.desconto_percentual / 100);
    end if;

    return jsonb_build_object(
      'ok', true,
      'preco_base', v_item.preco_base,
      'preco_final', v_preco_final,
      'preco_minimo', v_item.preco_minimo,
      'ipi', v_item.ipi_percentual,
      'icms', v_item.icms_percentual,
      'desconto_max', v_item.desconto_maximo_percentual,
      'em_promocao', true,
      'subtotal', v_preco_final * p_quantidade
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'preco_base', v_item.preco_base,
    'preco_final', v_preco_final,
    'preco_minimo', v_item.preco_minimo,
    'ipi', v_item.ipi_percentual,
    'icms', v_item.icms_percentual,
    'desconto_max', v_item.desconto_maximo_percentual,
    'em_promocao', false,
    'subtotal', v_preco_final * p_quantidade
  );
end;
$function$;

CREATE OR REPLACE FUNCTION comercial.hub_fn_validar_credito(p_cliente_id uuid, p_valor numeric)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_limite numeric;
  v_disponivel numeric;
  v_status text;
begin
  if not comercial.hub_pode_acessar_cliente(p_cliente_id) then
    return jsonb_build_object('ok', false, 'erro', 'Acesso negado');
  end if;

  select limite_credito, limite_disponivel, status_cadastro
  into v_limite, v_disponivel, v_status
  from comercial.hub_clientes
  where id = p_cliente_id and ativo = true;

  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Cliente nao encontrado');
  end if;

  if v_status != 'ativo' then
    return jsonb_build_object('ok', false, 'erro', 'Cadastro nao esta ativo', 'status', v_status);
  end if;

  if p_valor > v_disponivel then
    return jsonb_build_object(
      'ok', false,
      'erro', 'Limite insuficiente',
      'limite_total', v_limite,
      'disponivel', v_disponivel,
      'valor_pedido', p_valor,
      'excedente', p_valor - v_disponivel
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'limite_total', v_limite,
    'disponivel', v_disponivel,
    'disponivel_apos', v_disponivel - p_valor
  );
end;
$function$;

CREATE OR REPLACE FUNCTION comercial.hub_fn_submeter_pedido(p_pedido_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_pedido record;
  v_total numeric(12,2);
  v_itens integer;
  v_numero text;
begin
  select * into v_pedido
  from comercial.hub_pedidos
  where id = p_pedido_id and ativo = true;

  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Pedido nao encontrado');
  end if;

  if not comercial.hub_pode_acessar_cliente(v_pedido.cliente_id) then
    return jsonb_build_object('ok', false, 'erro', 'Acesso negado');
  end if;

  if v_pedido.status != 'rascunho' then
    return jsonb_build_object('ok', false, 'erro', 'Pedido ja foi submetido');
  end if;

  select count(*), coalesce(sum(subtotal_item), 0)
  into v_itens, v_total
  from comercial.hub_pedido_itens
  where pedido_id = p_pedido_id;

  if v_itens = 0 then
    return jsonb_build_object('ok', false, 'erro', 'Pedido sem itens');
  end if;

  v_numero := comercial.hub_fn_gerar_numero();

  update comercial.hub_pedidos set
    numero = v_numero,
    subtotal = v_total,
    valor_total = v_total - coalesce(desconto_valor, 0) + coalesce(valor_frete, 0),
    status = 'submetido',
    atualizado_em = now()
  where id = p_pedido_id;

  return jsonb_build_object(
    'ok', true,
    'numero', v_numero,
    'valor_total', v_total - coalesce(v_pedido.desconto_valor, 0) + coalesce(v_pedido.valor_frete, 0),
    'itens', v_itens
  );
end;
$function$;

-- hub_pedido_itens_insert so exigia status='rascunho', sem checar dono do
-- pedido -- um cliente podia inserir item no rascunho de outro.
DROP POLICY IF EXISTS hub_pedido_itens_insert ON comercial.hub_pedido_itens;
CREATE POLICY hub_pedido_itens_insert ON comercial.hub_pedido_itens
  FOR INSERT
  TO authenticated
  WITH CHECK (
    pedido_id IN (
      SELECT id FROM comercial.hub_pedidos
       WHERE status = 'rascunho'
         AND comercial.hub_pode_acessar_cliente(cliente_id)
    )
  );
