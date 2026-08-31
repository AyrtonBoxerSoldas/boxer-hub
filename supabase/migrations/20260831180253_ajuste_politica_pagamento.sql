-- Corrige a politica de pagamento pra bater com a regra real da Boxer (Andre,
-- 2026-08-31): a tabela hub_politica_parcelamento tinha taxa escalonada
-- (herdada de um mapeamento antigo), mas o cartao de credito e 1-10x SEM
-- juros (sem opcao de 11x/12x). Boleto/duplicata e ate 3x (28/56/84 dias),
-- sem juros, e so pra cliente com limite de credito ativo e sem titulo
-- vencido -- isso nunca foi validado no backend, so o valor minimo por
-- parcela.

-- 1) Cartao: 1-10x sem juros, remove 11x/12x da tabela.
update comercial.hub_politica_parcelamento set taxa_percentual = 0
 where parcelas between 1 and 10;
delete from comercial.hub_politica_parcelamento where parcelas > 10;

update comercial.hub_politica_parametros
   set valor = '10.00', atualizado_em = now()
 where chave = 'parcelamento_maximo';

-- 2) Boleto: teto de 3 parcelas (28/56/84 dias).
insert into comercial.hub_politica_parametros (chave, valor, descricao)
values ('parcelamento_maximo_boleto', '3.00', 'Numero maximo de parcelas em boleto/duplicata (28/56/84 dias)')
on conflict (chave) do update set valor = excluded.valor, atualizado_em = now();

-- 3) hub_fn_validar_politica: adiciona elegibilidade de boleto (limite de
-- credito ativo + sem titulo vencido) e teto de parcelas por forma de
-- pagamento. Frete: mantido igual pra UF CIF; para UF FOB sem frete_fixo
-- cadastrado, se o cliente pedir envio (nao retirada) o pedido segue mas com
-- aviso de frete "sob consulta" -- nao existe valor fixo definido pra FOB na
-- politica comercial hoje (todas as UF FOB tem frete_fixo null).
create or replace function comercial.hub_fn_validar_politica(p_pedido_id uuid)
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to ''
as $function$
DECLARE
  v_pedido      record;
  v_uf          text;
  v_subtotal    numeric(12,2);
  v_itens       integer;
  v_so_reposicao boolean;
  v_minimo      numeric(12,2);
  v_minimo_rotulo text;
  v_frete       record;
  v_taxa        numeric(5,2);
  v_violacoes   jsonb := '[]'::jsonb;
  v_avisos      jsonb := '[]'::jsonb;
  v_frete_info  jsonb := 'null'::jsonb;
  v_p           jsonb;
  v_limite_cliente numeric(12,2);
  v_tem_titulo_vencido boolean;
BEGIN
  SELECT * INTO v_pedido FROM comercial.hub_pedidos WHERE id = p_pedido_id AND ativo = true;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao encontrado');
  END IF;

  IF NOT comercial.hub_pode_acessar_cliente(v_pedido.cliente_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Acesso negado');
  END IF;

  SELECT jsonb_object_agg(chave, valor) INTO v_p FROM comercial.hub_politica_parametros;

  SELECT c.uf INTO v_uf FROM comercial.hub_clientes c WHERE c.id = v_pedido.cliente_id;

  SELECT count(*), coalesce(sum(subtotal_item), 0)
    INTO v_itens, v_subtotal
    FROM comercial.hub_pedido_itens WHERE pedido_id = p_pedido_id;

  IF v_itens = 0 THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido sem itens');
  END IF;

  SELECT bool_and(coalesce(cc.reposicao, false))
    INTO v_so_reposicao
    FROM comercial.hub_pedido_itens pi
    LEFT JOIN comercial.hub_v_catalogo vc ON vc.produto_id = pi.produto_id
    LEFT JOIN comercial.hub_categoria_config cc ON cc.grupo = vc.categoria_grupo
   WHERE pi.pedido_id = p_pedido_id;

  IF v_pedido.entrega_agendada THEN
    v_minimo := (v_p->>'pedido_minimo_entrega_agendada')::numeric;
    v_minimo_rotulo := 'entrega agendada';
  ELSIF coalesce(v_so_reposicao, false) THEN
    v_minimo := (v_p->>'pedido_minimo_reposicao')::numeric;
    v_minimo_rotulo := 'reposicao';
  ELSE
    v_minimo := (v_p->>'pedido_minimo_normal')::numeric;
    v_minimo_rotulo := 'normal';
  END IF;

  IF v_subtotal < v_minimo THEN
    v_violacoes := v_violacoes || jsonb_build_object(
      'regra', 'pedido_minimo',
      'mensagem', format('Pedido minimo (%s) e R$ %s. Faltam R$ %s.',
                  v_minimo_rotulo, comercial.hub_fn_moeda(v_minimo),
                  comercial.hub_fn_moeda(v_minimo - v_subtotal)),
      'exigido', v_minimo, 'atual', v_subtotal);
  END IF;

  -- Elegibilidade de boleto/duplicata: precisa limite de credito ativo e
  -- nenhum titulo vencido (regra financeiro, Andre 2026-08-31).
  IF v_pedido.forma_pagamento = 'boleto' THEN
    SELECT limite_credito INTO v_limite_cliente
      FROM comercial.hub_clientes WHERE id = v_pedido.cliente_id;

    SELECT EXISTS(
      SELECT 1 FROM comercial.hub_titulos
       WHERE cliente_id = v_pedido.cliente_id AND status = 'vencido' AND ativo = true
    ) INTO v_tem_titulo_vencido;

    IF coalesce(v_limite_cliente, 0) <= 0 THEN
      v_violacoes := v_violacoes || jsonb_build_object(
        'regra', 'boleto_elegibilidade',
        'mensagem', 'Boleto/duplicata disponivel apenas para clientes com limite de credito ativo na Boxer.');
    ELSIF v_tem_titulo_vencido THEN
      v_violacoes := v_violacoes || jsonb_build_object(
        'regra', 'boleto_elegibilidade',
        'mensagem', 'Boleto/duplicata bloqueado: cliente tem titulo em atraso. Regularize para liberar.');
    END IF;

    IF coalesce(v_pedido.parcelas, 1) > (v_p->>'parcelamento_maximo_boleto')::int THEN
      v_violacoes := v_violacoes || jsonb_build_object(
        'regra', 'parcelamento',
        'mensagem', format('Boleto/duplicata permite no maximo %sx (28/56/84 dias).',
                    (v_p->>'parcelamento_maximo_boleto')::int));
    END IF;
  END IF;

  IF coalesce(v_pedido.parcelas, 1) > 1 THEN
    IF v_pedido.forma_pagamento = 'cartao_credito' THEN
      SELECT taxa_percentual INTO v_taxa
        FROM comercial.hub_politica_parcelamento WHERE parcelas = v_pedido.parcelas;

      IF v_taxa IS NULL THEN
        v_violacoes := v_violacoes || jsonb_build_object(
          'regra', 'parcelamento',
          'mensagem', format('Parcelamento em %sx nao previsto na politica (maximo %sx, sem juros).',
                      v_pedido.parcelas, (v_p->>'parcelamento_maximo')::int));
      ELSIF v_taxa > 0 THEN
        v_avisos := v_avisos || jsonb_build_object(
          'regra', 'parcelamento',
          'mensagem', format('Cartao em %sx tem taxa de %s%%.', v_pedido.parcelas, v_taxa),
          'taxa_percentual', v_taxa);
      END IF;
    ELSIF v_pedido.forma_pagamento = 'boleto' THEN
      IF v_subtotal / v_pedido.parcelas < (v_p->>'valor_minimo_duplicata')::numeric THEN
        v_violacoes := v_violacoes || jsonb_build_object(
          'regra', 'valor_minimo_duplicata',
          'mensagem', format('Cada duplicata precisa ser de no minimo R$ %s. Em %sx daria R$ %s.',
                      comercial.hub_fn_moeda((v_p->>'valor_minimo_duplicata')::numeric),
                      v_pedido.parcelas,
                      comercial.hub_fn_moeda(v_subtotal / v_pedido.parcelas)),
          'exigido', (v_p->>'valor_minimo_duplicata')::numeric,
          'atual', round(v_subtotal / v_pedido.parcelas, 2));
      END IF;
    END IF;
  END IF;

  SELECT * INTO v_frete FROM comercial.hub_politica_frete WHERE uf = v_uf;

  IF v_frete.uf IS NULL THEN
    v_avisos := v_avisos || jsonb_build_object(
      'regra', 'frete',
      'mensagem', coalesce('UF ' || v_uf || ' sem regra de frete cadastrada.',
                           'Cliente sem UF: frete a definir.'));
  ELSIF v_frete.tipo = 'FOB' THEN
    v_frete_info := jsonb_build_object('tipo', 'FOB', 'valor', 0,
      'retirada_disponivel', true,
      'envio_disponivel', false,
      'motivo', 'UF FOB: retirada gratuita em Campinas, Sao Paulo ou Guarulhos, ou transportadora indicada pelo cliente. Envio pela Boxer nesta UF nao tem preco fixo -- sob consulta com o comercial.');
    v_avisos := v_avisos || jsonb_build_object('regra', 'frete', 'mensagem', v_frete_info->>'motivo');
  ELSIF v_subtotal >= v_frete.pedido_minimo_cif THEN
    v_frete_info := jsonb_build_object('tipo', 'CIF', 'valor', 0,
      'retirada_disponivel', false,
      'envio_disponivel', true,
      'motivo', format('CIF sem custo: pedido atingiu o minimo de R$ %s para %s.',
                comercial.hub_fn_moeda(v_frete.pedido_minimo_cif), v_uf));
  ELSE
    v_frete_info := jsonb_build_object('tipo', 'CIF', 'valor', v_frete.frete_fixo,
      'retirada_disponivel', false,
      'envio_disponivel', true,
      'motivo', format('Frete de R$ %s cobrado na nota: pedido abaixo do minimo de R$ %s para %s. Pague o frete e enviamos.',
                comercial.hub_fn_moeda(v_frete.frete_fixo),
                comercial.hub_fn_moeda(v_frete.pedido_minimo_cif), v_uf));
    v_avisos := v_avisos || jsonb_build_object('regra', 'frete',
      'mensagem', v_frete_info->>'motivo', 'valor', v_frete.frete_fixo);
  END IF;

  RETURN jsonb_build_object(
    'ok',          jsonb_array_length(v_violacoes) = 0,
    'violacoes',   v_violacoes,
    'avisos',      v_avisos,
    'frete',       v_frete_info,
    'subtotal',    v_subtotal,
    'itens',       v_itens,
    'tipo_pedido', v_minimo_rotulo,
    'minimo_exigido', v_minimo
  );
END $function$;

