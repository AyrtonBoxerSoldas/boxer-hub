-- Bug encontrado testando hub_fn_liberar_cliente (2026-08-28): a funcao grava
-- acao = 'liberar_acesso' em hub_log_alteracoes, mas o CHECK da coluna nao
-- previa esse valor -- toda liberacao de cliente bloqueado falhava.

ALTER TABLE comercial.hub_log_alteracoes
  DROP CONSTRAINT IF EXISTS hub_log_alteracoes_acao_check;

ALTER TABLE comercial.hub_log_alteracoes
  ADD CONSTRAINT hub_log_alteracoes_acao_check
  CHECK (acao = ANY (ARRAY[
    'insert', 'update', 'delete',
    'ativacao_cliente', 'rejeicao_onboarding', 'avancar_etapa', 'convite_criado',
    'liberar_acesso'
  ]));
