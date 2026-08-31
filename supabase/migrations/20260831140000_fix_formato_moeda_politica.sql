-- As mensagens da politica saiam em formato americano: "R$ 3,240.00" em vez
-- de "R$ 3.240,00". to_char() segue o lc_numeric do servidor, que nao e pt_BR,
-- entao o separador vinha trocado em texto que o revendedor le.

CREATE OR REPLACE FUNCTION comercial.hub_fn_moeda(p_valor numeric)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  -- to_char devolve "3,240.00"; translate troca os separadores de uma vez.
  SELECT translate(to_char(coalesce(p_valor, 0), 'FM999G999G999D00'), '.,', ',.');
$$;

COMMENT ON FUNCTION comercial.hub_fn_moeda(numeric) IS
  'Formata numero no padrao brasileiro (1.234,56), independente do lc_numeric do servidor.';

GRANT EXECUTE ON FUNCTION comercial.hub_fn_moeda(numeric) TO authenticated;

CREATE OR REPLACE FUNCTION comercial.hub_fn_validar_politica(p_pedido_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $$
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

  IF coalesce(v_pedido.parcelas, 1) > 1 THEN
    IF v_pedido.forma_pagamento = 'cartao_credito' THEN
      SELECT taxa_percentual INTO v_taxa
        FROM comercial.hub_politica_parcelamento WHERE parcelas = v_pedido.parcelas;

      IF v_taxa IS NULL THEN
        v_violacoes := v_violacoes || jsonb_build_object(
          'regra', 'parcelamento',
          'mensagem', format('Parcelamento em %sx nao previsto na politica (maximo %sx).',
                      v_pedido.parcelas, (v_p->>'parcelamento_maximo')::int));
      ELSIF v_taxa > 0 THEN
        v_avisos := v_avisos || jsonb_build_object(
          'regra', 'parcelamento',
          'mensagem', format('Cartao em %sx tem taxa de %s%%.', v_pedido.parcelas, v_taxa),
          'taxa_percentual', v_taxa);
      END IF;
    ELSE
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
      'motivo', 'UF FOB: transportadora indicada pelo cliente (retirada em Campinas, Sao Paulo ou Guarulhos).');
    v_avisos := v_avisos || jsonb_build_object('regra', 'frete', 'mensagem', v_frete_info->>'motivo');
  ELSIF v_subtotal >= v_frete.pedido_minimo_cif THEN
    v_frete_info := jsonb_build_object('tipo', 'CIF', 'valor', 0,
      'motivo', format('CIF sem custo: pedido atingiu o minimo de R$ %s para %s.',
                comercial.hub_fn_moeda(v_frete.pedido_minimo_cif), v_uf));
  ELSE
    v_frete_info := jsonb_build_object('tipo', 'CIF', 'valor', v_frete.frete_fixo,
      'motivo', format('Frete de R$ %s cobrado na nota: pedido abaixo do minimo de R$ %s para %s.',
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
END $$;
