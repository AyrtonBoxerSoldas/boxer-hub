-- Corrige bug achado na auditoria de 2026-08-31: cadastro.html tinha um botao
-- "Solicitar alteracao" que so mostrava um toast de sucesso e nao gravava
-- nada -- o cliente achava que tinha pedido e nao tinha. Cria a tabela que
-- faltava para o botao gravar de verdade. Mesmo padrao de
-- hub_solicitacoes_credito (dealer/rep pedem, staff analisa).
CREATE TABLE IF NOT EXISTS comercial.hub_solicitacoes_alteracao_cadastral (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id     uuid NOT NULL REFERENCES comercial.hub_clientes(id),
  solicitante_id uuid NOT NULL,
  descricao      text NOT NULL,
  status         varchar(20) DEFAULT 'pendente'
                 CHECK (status IN ('pendente', 'em_analise', 'concluida', 'rejeitada')),
  analisado_por  uuid,
  analisado_em   timestamptz,
  parecer        text,
  criado_em      timestamptz DEFAULT now(),
  atualizado_em  timestamptz DEFAULT now(),
  ativo          boolean DEFAULT true
);

COMMENT ON TABLE comercial.hub_solicitacoes_alteracao_cadastral IS
  'Pedidos de alteracao no cadastro (Meu Cadastro e read-only -- toda mudanca passa por aqui e aprovacao do ADM).';

ALTER TABLE comercial.hub_solicitacoes_alteracao_cadastral ENABLE ROW LEVEL SECURITY;

CREATE POLICY hub_altcad_insert_dealer ON comercial.hub_solicitacoes_alteracao_cadastral
  FOR INSERT
  WITH CHECK (comercial.hub_user_tipo() = 'cliente' AND cliente_id = comercial.hub_user_cliente_id());

CREATE POLICY hub_altcad_insert_rep ON comercial.hub_solicitacoes_alteracao_cadastral
  FOR INSERT
  WITH CHECK (
    comercial.hub_user_tipo() = 'representante'
    AND cliente_id IN (
      SELECT hub_carteira.cliente_id FROM comercial.hub_carteira
      WHERE hub_carteira.representante_id = comercial.hub_user_representante_id()
        AND hub_carteira.ativo = true
    )
  );

CREATE POLICY hub_altcad_select_dealer ON comercial.hub_solicitacoes_alteracao_cadastral
  FOR SELECT
  USING (comercial.hub_user_tipo() = 'cliente' AND cliente_id = comercial.hub_user_cliente_id());

CREATE POLICY hub_altcad_select_rep ON comercial.hub_solicitacoes_alteracao_cadastral
  FOR SELECT
  USING (
    comercial.hub_user_tipo() = 'representante'
    AND cliente_id IN (
      SELECT hub_carteira.cliente_id FROM comercial.hub_carteira
      WHERE hub_carteira.representante_id = comercial.hub_user_representante_id()
        AND hub_carteira.ativo = true
    )
  );

CREATE POLICY hub_altcad_select_interno ON comercial.hub_solicitacoes_alteracao_cadastral
  FOR SELECT
  USING (comercial.hub_user_role() = ANY (ARRAY['analyst', 'manager', 'admin']));

CREATE POLICY hub_altcad_update_interno ON comercial.hub_solicitacoes_alteracao_cadastral
  FOR UPDATE
  USING (comercial.hub_user_role() = ANY (ARRAY['analyst', 'manager', 'admin']));

CREATE POLICY hub_altcad_nao_bloqueado ON comercial.hub_solicitacoes_alteracao_cadastral
  FOR ALL TO authenticated
  USING (NOT comercial.hub_user_cliente_bloqueado());
