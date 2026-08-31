-- Politica Comercial de Revendas como REGRA EXECUTAVEL, nao so documento.
--
-- Andre (2026-08-31): "ao fechar pedido, a politica precisa ser acionada para
-- ver se pedido esta atendendo todas as regras de: faturamento minimo,
-- parcelamento, valor por parcela, cobranca de frete se houver [...] a politica
-- e a regra mestre de toda a venda".
--
-- Fonte dos numeros: Politica Comercial Revendas V2 (28/07/2026), a mesma
-- versao publicada em comercial_bmax_politica_conteudo (politica='revenda').
-- O texto continua sendo a fonte oficial para gente ler; estas tabelas sao a
-- traducao dele em parametros que o sistema consegue conferir. Ficam em
-- tabelas editaveis (nao hardcoded) para o comercial ajustar sem deploy.

-- ---------------------------------------------------------------------------
-- 1. Parametros escalares
CREATE TABLE IF NOT EXISTS comercial.hub_politica_parametros (
  chave         text PRIMARY KEY,
  valor         numeric(12,2) NOT NULL,
  descricao     text,
  criado_em     timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

COMMENT ON TABLE comercial.hub_politica_parametros IS
  'Parametros numericos da Politica Comercial de Revendas V2, conferidos no fechamento do pedido.';

INSERT INTO comercial.hub_politica_parametros (chave, valor, descricao) VALUES
  ('pedido_minimo_normal',        3000, 'Pedido minimo para itens normais da linha de revenda'),
  ('pedido_minimo_reposicao',      650, 'Pedido minimo de reposicao (perifericos, acessorios, consumiveis)'),
  ('pedido_minimo_entrega_agendada', 8000, 'Pedido minimo para cliente com entrega pre-agendada'),
  ('valor_minimo_duplicata',       800, 'Valor minimo por duplicata/parcela'),
  ('parcelamento_maximo',           12, 'Numero maximo de parcelas no cartao de credito'),
  ('classe_fisica_limite_1',     20000, 'Fisica: pedido acima deste valor entra na classe 1 (-8%)'),
  ('classe_fisica_limite_2',      7000, 'Fisica: pedido acima deste valor entra na classe 2 (-4%)'),
  ('classe_ecom_historico_3m',  175000, 'Ecommerce/Hibrido: compras em 3 meses para alcancar a classe 1')
ON CONFLICT (chave) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Frete por UF (capitulo 10 da politica)
CREATE TABLE IF NOT EXISTS comercial.hub_politica_frete (
  uf               char(2) PRIMARY KEY,
  tipo             text NOT NULL CHECK (tipo IN ('CIF', 'FOB')),
  pedido_minimo_cif numeric(12,2),
  frete_fixo        numeric(12,2),
  atualizado_em     timestamptz DEFAULT now()
);

COMMENT ON TABLE comercial.hub_politica_frete IS
  'CIF/FOB por UF. Em UF CIF, pedido abaixo do minimo paga o frete fixo na nota. FOB: transportadora indicada pelo cliente.';

INSERT INTO comercial.hub_politica_frete (uf, tipo, pedido_minimo_cif, frete_fixo) VALUES
  ('AC','FOB',NULL,NULL),   ('AL','FOB',NULL,NULL),   ('AM','CIF',4320,165),
  ('AP','FOB',NULL,NULL),   ('BA','CIF',3780,155),    ('CE','CIF',3240,140),
  ('DF','CIF',3240,126),    ('ES','CIF',3240,151),    ('GO','CIF',3240,126),
  ('MA','CIF',4320,160),    ('MG','CIF',3240,126),    ('MS','CIF',3240,132),
  ('MT','CIF',3240,130),    ('PA','FOB',NULL,NULL),   ('PB','CIF',3780,151),
  ('PE','CIF',3240,145),    ('PI','FOB',NULL,NULL),   ('PR','CIF',3240,126),
  ('RJ','CIF',3240,151),    ('RN','CIF',3240,133),    ('RO','CIF',3780,178),
  ('RR','CIF',4320,158),    ('RS','CIF',3240,145),    ('SC','CIF',3240,132),
  ('SE','FOB',NULL,NULL),   ('SP','CIF',3240,120),    ('TO','FOB',NULL,NULL)
ON CONFLICT (uf) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Taxas de parcelamento no cartao (capitulo 7.4)
CREATE TABLE IF NOT EXISTS comercial.hub_politica_parcelamento (
  parcelas        smallint PRIMARY KEY,
  taxa_percentual numeric(5,2) NOT NULL
);

INSERT INTO comercial.hub_politica_parcelamento (parcelas, taxa_percentual) VALUES
  (1,0.00),(2,0.00),(3,1.00),(4,2.00),(5,3.00),(6,4.00),
  (7,5.50),(8,7.00),(9,8.50),(10,10.00),(11,11.00),(12,12.00)
ON CONFLICT (parcelas) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 4. Quais grupos de categoria contam como "reposicao"
-- A politica fala em "perifericos, acessorios, consumiveis". Fica como flag
-- editavel porque e uma leitura do texto, nao uma lista literal dele.
ALTER TABLE comercial.hub_categoria_config
  ADD COLUMN IF NOT EXISTS reposicao boolean NOT NULL DEFAULT false;

UPDATE comercial.hub_categoria_config
   SET reposicao = (grupo IN ('Acessórios', 'Consumíveis', 'Peças'));

COMMENT ON COLUMN comercial.hub_categoria_config.reposicao IS
  'Grupo conta como reposicao (pedido minimo menor). Confirmar com o comercial se a leitura esta certa.';

-- ---------------------------------------------------------------------------
-- 5. Campos do pedido que a politica precisa conferir
ALTER TABLE comercial.hub_pedidos
  ADD COLUMN IF NOT EXISTS forma_pagamento  text,
  ADD COLUMN IF NOT EXISTS parcelas         smallint,
  ADD COLUMN IF NOT EXISTS entrega_agendada boolean NOT NULL DEFAULT false;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'hub_pedidos_forma_pagamento_check') THEN
    ALTER TABLE comercial.hub_pedidos
      ADD CONSTRAINT hub_pedidos_forma_pagamento_check
      CHECK (forma_pagamento IS NULL OR forma_pagamento IN
             ('boleto','pix','cartao_credito','transferencia','bradesco_b2b','credix'));
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 6. A validacao em si
--
-- Devolve { ok, violacoes[], avisos[], frete{}, ... }. Violacao impede o
-- pedido; aviso e informativo (o frete cobrado, por exemplo, nao barra a venda
-- -- entra na nota).
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

  -- parametros num jsonb so, para nao repetir SELECT
  SELECT jsonb_object_agg(chave, valor) INTO v_p FROM comercial.hub_politica_parametros;

  SELECT c.uf INTO v_uf FROM comercial.hub_clientes c WHERE c.id = v_pedido.cliente_id;

  SELECT count(*), coalesce(sum(subtotal_item), 0)
    INTO v_itens, v_subtotal
    FROM comercial.hub_pedido_itens WHERE pedido_id = p_pedido_id;

  IF v_itens = 0 THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido sem itens');
  END IF;

  -- --- pedido minimo -------------------------------------------------------
  -- reposicao so vale se TODOS os itens forem de grupo de reposicao; misturar
  -- uma maquina no carrinho traz o pedido de volta para o minimo normal.
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
                  v_minimo_rotulo, to_char(v_minimo, 'FM999G999D00'),
                  to_char(v_minimo - v_subtotal, 'FM999G999D00')),
      'exigido', v_minimo, 'atual', v_subtotal);
  END IF;

  -- --- parcelamento --------------------------------------------------------
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
      -- boleto/duplicata: cada parcela precisa respeitar o minimo
      IF v_subtotal / v_pedido.parcelas < (v_p->>'valor_minimo_duplicata')::numeric THEN
        v_violacoes := v_violacoes || jsonb_build_object(
          'regra', 'valor_minimo_duplicata',
          'mensagem', format('Cada duplicata precisa ser de no minimo R$ %s. Em %sx daria R$ %s.',
                      to_char((v_p->>'valor_minimo_duplicata')::numeric, 'FM999G999D00'),
                      v_pedido.parcelas,
                      to_char(v_subtotal / v_pedido.parcelas, 'FM999G999D00')),
          'exigido', (v_p->>'valor_minimo_duplicata')::numeric,
          'atual', round(v_subtotal / v_pedido.parcelas, 2));
      END IF;
    END IF;
  END IF;

  -- --- frete ---------------------------------------------------------------
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
                to_char(v_frete.pedido_minimo_cif, 'FM999G999D00'), v_uf));
  ELSE
    v_frete_info := jsonb_build_object('tipo', 'CIF', 'valor', v_frete.frete_fixo,
      'motivo', format('Frete de R$ %s cobrado na nota: pedido abaixo do minimo de R$ %s para %s.',
                to_char(v_frete.frete_fixo, 'FM999G999D00'),
                to_char(v_frete.pedido_minimo_cif, 'FM999G999D00'), v_uf));
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

COMMENT ON FUNCTION comercial.hub_fn_validar_politica(uuid) IS
  'Confere o pedido contra a Politica Comercial de Revendas V2: minimo, parcelamento, duplicata e frete.';

GRANT EXECUTE ON FUNCTION comercial.hub_fn_validar_politica(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 7. RLS: todo mundo autenticado le a politica; so admin/manager escreve.
ALTER TABLE comercial.hub_politica_parametros   ENABLE ROW LEVEL SECURITY;
ALTER TABLE comercial.hub_politica_frete        ENABLE ROW LEVEL SECURITY;
ALTER TABLE comercial.hub_politica_parcelamento ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['hub_politica_parametros','hub_politica_frete','hub_politica_parcelamento'] LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON comercial.%I', t || '_select', t);
    EXECUTE format($f$CREATE POLICY %I ON comercial.%I FOR SELECT TO authenticated USING (true)$f$, t || '_select', t);

    EXECUTE format('DROP POLICY IF EXISTS %I ON comercial.%I', t || '_write', t);
    EXECUTE format($f$CREATE POLICY %I ON comercial.%I FOR ALL TO authenticated
                      USING (comercial.hub_user_role() = ANY (ARRAY['admin','manager']))
                      WITH CHECK (comercial.hub_user_role() = ANY (ARRAY['admin','manager']))$f$,
                   t || '_write', t);
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 8. Submissao do pedido: reprecificar no servidor, acionar a politica, so
--    entao reservar credito e gravar.
--
-- Duas correcoes importantes aqui:
--
-- (a) PRECO AUTORITATIVO. Quem gravava preco_unitario em hub_pedido_itens era
--     o front. A policy hub_pedido_itens_insert deixa o proprio cliente
--     inserir itens no seu rascunho, entao dava para chamar a API direto e
--     mandar o preco que quisesse. Agora o servidor recalcula todo item pela
--     base mestre e sobrescreve antes de fechar -- o que o front mandou passa
--     a ser so uma estimativa para exibir.
--
-- (b) A POLITICA BARRA O PEDIDO. Minimo, duplicata e parcelamento sao
--     conferidos antes de reservar credito e mudar o status.
--
-- A faixa de desconto e definida pelo subtotal a PRECO DE TABELA (decisao do
-- Andre em 2026-08-31): medir na tabela evita a circularidade de o desconto
-- baixar o valor e o valor rebaixar a faixa.
CREATE OR REPLACE FUNCTION comercial.hub_fn_submeter_pedido(p_pedido_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_pedido    record;
  v_cliente   record;
  v_item      record;
  v_preco     jsonb;
  v_subtotal_tabela numeric(12,2) := 0;
  v_subtotal  numeric(12,2) := 0;
  v_itens     integer;
  v_numero    text;
  v_politica  jsonb;
  v_frete     numeric(12,2) := 0;
  v_total     numeric(12,2);
BEGIN
  SELECT * INTO v_pedido FROM comercial.hub_pedidos
   WHERE id = p_pedido_id AND ativo = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido nao encontrado');
  END IF;

  IF NOT comercial.hub_pode_acessar_cliente(v_pedido.cliente_id) THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Acesso negado');
  END IF;

  IF v_pedido.status != 'rascunho' THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido ja foi submetido');
  END IF;

  SELECT count(*) INTO v_itens
    FROM comercial.hub_pedido_itens WHERE pedido_id = p_pedido_id;
  IF v_itens = 0 THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Pedido sem itens');
  END IF;

  -- (1) subtotal a preco de tabela -> define a faixa/classe
  SELECT coalesce(sum(pi.quantidade * f.preco_tabela), 0)
    INTO v_subtotal_tabela
    FROM comercial.hub_pedido_itens pi
    JOIN comercial.hub_fn_precos_cliente(v_pedido.cliente_id, 0) f
      ON f.produto_id = pi.produto_id
   WHERE pi.pedido_id = p_pedido_id;

  -- (2) reprecificar cada item na faixa correta e sobrescrever
  FOR v_item IN
    SELECT id, produto_id, quantidade FROM comercial.hub_pedido_itens
     WHERE pedido_id = p_pedido_id
  LOOP
    v_preco := comercial.hub_fn_calcular_preco(
                 v_pedido.cliente_id, v_item.produto_id,
                 v_item.quantidade, v_subtotal_tabela);

    IF (v_preco->>'ok')::boolean IS NOT TRUE THEN
      RETURN jsonb_build_object('ok', false,
        'erro', coalesce(v_preco->>'erro', 'Falha ao precificar item'));
    END IF;

    UPDATE comercial.hub_pedido_itens
       SET preco_unitario = (v_preco->>'preco_base')::numeric,
           preco_final    = (v_preco->>'preco_final')::numeric,
           subtotal_item  = (v_preco->>'subtotal')::numeric
     WHERE id = v_item.id;
  END LOOP;

  SELECT coalesce(sum(subtotal_item), 0) INTO v_subtotal
    FROM comercial.hub_pedido_itens WHERE pedido_id = p_pedido_id;

  -- (3) politica comercial (minimo, duplicata, parcelamento, frete)
  UPDATE comercial.hub_pedidos SET subtotal = v_subtotal WHERE id = p_pedido_id;
  v_politica := comercial.hub_fn_validar_politica(p_pedido_id);

  IF (v_politica->>'ok')::boolean IS NOT TRUE THEN
    RETURN jsonb_build_object('ok', false,
      'erro', 'Pedido nao atende a politica comercial',
      'violacoes', coalesce(v_politica->'violacoes', '[]'::jsonb),
      'politica', v_politica);
  END IF;

  v_frete := coalesce((v_politica->'frete'->>'valor')::numeric, 0);
  v_total := v_subtotal - coalesce(v_pedido.desconto_valor, 0) + v_frete;

  -- (4) credito: trava a linha do cliente e reserva
  SELECT * INTO v_cliente FROM comercial.hub_clientes
   WHERE id = v_pedido.cliente_id FOR UPDATE;

  IF v_cliente.status_cadastro != 'ativo' THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Cadastro nao esta ativo',
                              'status', v_cliente.status_cadastro);
  END IF;

  IF v_total > v_cliente.limite_disponivel THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Limite insuficiente',
      'limite_total', v_cliente.limite_credito,
      'disponivel',   v_cliente.limite_disponivel,
      'valor_pedido', v_total,
      'excedente',    v_total - v_cliente.limite_disponivel);
  END IF;

  v_numero := comercial.hub_fn_gerar_numero();

  UPDATE comercial.hub_clientes
     SET limite_disponivel = limite_disponivel - v_total,
         atualizado_em = now()
   WHERE id = v_pedido.cliente_id;

  UPDATE comercial.hub_pedidos SET
    numero        = v_numero,
    subtotal      = v_subtotal,
    valor_frete   = v_frete,
    valor_total   = v_total,
    status        = 'submetido',
    atualizado_em = now()
  WHERE id = p_pedido_id;

  RETURN jsonb_build_object(
    'ok', true,
    'numero', v_numero,
    'subtotal', v_subtotal,
    'valor_frete', v_frete,
    'valor_total', v_total,
    'itens', v_itens,
    'politica', v_politica
  );
END $function$;
