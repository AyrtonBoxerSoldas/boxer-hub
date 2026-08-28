-- Achado numa auditoria pedida pelo Andre (2026-08-28): nenhum trigger ou
-- funcao decrementava hub_clientes.limite_disponivel quando um pedido era
-- gravado. hub_fn_validar_credito so LIA o saldo -- um cliente podia enviar
-- pedido atras de pedido, cada um passando isolado na checagem, sem o
-- "disponivel" nunca descontar o que ja tinha sido pedido.
--
-- Decisao de negocio confirmada com o Andre: reservar ao SUBMETER (nao so ao
-- aprovar), liberar automaticamente ao cancelar/rejeitar.
--
-- A reserva entra dentro de hub_fn_submeter_pedido (nao num trigger em cima
-- do UPDATE de status) com SELECT ... FOR UPDATE travando a linha do
-- cliente -- fecha a janela de corrida em que dois pedidos concorrentes
-- veriam o mesmo saldo "disponivel" e os dois passariam. A funcao volta a
-- ser a unica porta de saida de rascunho, e agora e ela quem decide, de
-- forma atomica, se ha credito -- hub_fn_validar_credito continua existindo
-- so como pre-check informativo pro front (mostrar erro cedo), mas quem
-- decide de verdade e essa funcao.

CREATE OR REPLACE FUNCTION comercial.hub_fn_submeter_pedido(p_pedido_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_pedido record;
  v_cliente record;
  v_total numeric(12,2);
  v_itens integer;
  v_numero text;
  v_valor_total numeric(12,2);
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

  v_valor_total := v_total - coalesce(v_pedido.desconto_valor, 0) + coalesce(v_pedido.valor_frete, 0);

  -- trava a linha do cliente ate o fim da transacao: um segundo pedido
  -- concorrente do mesmo cliente espera aqui, nao le um saldo desatualizado
  select * into v_cliente
  from comercial.hub_clientes
  where id = v_pedido.cliente_id
  for update;

  if v_cliente.status_cadastro != 'ativo' then
    return jsonb_build_object('ok', false, 'erro', 'Cadastro nao esta ativo', 'status', v_cliente.status_cadastro);
  end if;

  if v_valor_total > v_cliente.limite_disponivel then
    return jsonb_build_object(
      'ok', false,
      'erro', 'Limite insuficiente',
      'limite_total', v_cliente.limite_credito,
      'disponivel', v_cliente.limite_disponivel,
      'valor_pedido', v_valor_total,
      'excedente', v_valor_total - v_cliente.limite_disponivel
    );
  end if;

  v_numero := comercial.hub_fn_gerar_numero();

  update comercial.hub_clientes
     set limite_disponivel = limite_disponivel - v_valor_total,
         atualizado_em = now()
   where id = v_pedido.cliente_id;

  update comercial.hub_pedidos set
    numero = v_numero,
    subtotal = v_total,
    valor_total = v_valor_total,
    status = 'submetido',
    atualizado_em = now()
  where id = p_pedido_id;

  return jsonb_build_object(
    'ok', true,
    'numero', v_numero,
    'valor_total', v_valor_total,
    'itens', v_itens
  );
end;
$function$;

-- Libera o credito reservado quando o pedido sai de um estado que consumia
-- credito direto para cancelado/rejeitado. Cobre o caminho que nao passa
-- por hub_fn_submeter_pedido -- por exemplo um admin mudando o status
-- direto pela policy hub_pedidos_update_interno.
CREATE OR REPLACE FUNCTION comercial.hub_trg_liberar_credito_pedido()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_reservados text[] := ARRAY['submetido', 'em_analise', 'aprovado', 'em_separacao', 'faturado', 'enviado', 'entregue'];
begin
  if OLD.status is distinct from NEW.status
     and OLD.status = ANY (v_reservados)
     and NEW.status IN ('cancelado', 'rejeitado') then
    update comercial.hub_clientes
       set limite_disponivel = limite_disponivel + coalesce(OLD.valor_total, 0),
           atualizado_em = now()
     where id = NEW.cliente_id;
  end if;
  return NEW;
end;
$function$;

COMMENT ON FUNCTION comercial.hub_trg_liberar_credito_pedido() IS
  'Devolve o credito reservado ao limite_disponivel quando o pedido e cancelado ou rejeitado depois de ja ter reservado credito.';

DROP TRIGGER IF EXISTS trg_hub_liberar_credito_pedido ON comercial.hub_pedidos;
CREATE TRIGGER trg_hub_liberar_credito_pedido
  AFTER UPDATE ON comercial.hub_pedidos
  FOR EACH ROW
  EXECUTE FUNCTION comercial.hub_trg_liberar_credito_pedido();
