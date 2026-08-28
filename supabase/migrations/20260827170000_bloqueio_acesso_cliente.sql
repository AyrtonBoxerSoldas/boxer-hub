-- Cliente bloqueado/suspenso nao acessa o portal ate aprovacao do admin.
--
-- Regra definida em 2026-08-27: nao e "ve o catalogo mas nao compra" — e
-- ausencia de acesso. 2.339 dos 7.714 clientes importados do Zen chegam com a
-- tag 'blocked'.
--
-- Implementado como policy RESTRICTIVE de proposito. Policies permissivas se
-- combinam com OR: bastaria uma policy antiga liberal para anular a protecao —
-- foi exatamente o que aconteceu com hub_produto_anexos, onde uma policy com
-- USING (auth.uid() IS NOT NULL) deixava as fichas tecnicas visiveis. As
-- restritivas se combinam com AND, entao esta vale sobre todas as outras,
-- inclusive as que forem criadas depois.

-- Verdadeiro quando o usuario logado e um cliente cujo cadastro esta bloqueado.
-- Funcionario, representante e admin nunca sao barrados por aqui.
CREATE OR REPLACE FUNCTION comercial.hub_user_cliente_bloqueado()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = comercial, public
AS $$
  SELECT EXISTS (
    SELECT 1
      FROM comercial.hub_perfis p
      JOIN comercial.hub_clientes c ON c.id = p.cliente_id
     WHERE p.user_id = auth.uid()
       AND p.tipo = 'cliente'
       AND (c.bloqueado = true OR c.status_cadastro IN ('suspenso', 'bloqueado', 'pendente'))
  );
$$;

COMMENT ON FUNCTION comercial.hub_user_cliente_bloqueado() IS
  'true se o usuario logado e cliente com cadastro bloqueado/suspenso. Usada em policies RESTRICTIVE.';

GRANT EXECUTE ON FUNCTION comercial.hub_user_cliente_bloqueado() TO anon, authenticated;

-- Aplica a barreira em tudo que o cliente enxerga ou escreve.
-- hub_perfis entra na lista: sem conseguir ler o proprio perfil, o front nao
-- monta a sessao e as demais helpers (hub_user_cliente_id) devolvem nulo.
DO $$
DECLARE
  t text;
  alvos text[] := ARRAY[
    'hub_perfis', 'hub_clientes', 'hub_enderecos',
    'hub_pedidos', 'hub_pedido_itens',
    'hub_titulos', 'hub_notas_fiscais',
    'hub_solicitacoes_credito', 'hub_documentos_cadastrais',
    'hub_notificacoes', 'hub_pesquisa_respostas'
  ];
BEGIN
  FOREACH t IN ARRAY alvos LOOP
    IF to_regclass('comercial.' || t) IS NULL THEN CONTINUE; END IF;

    EXECUTE format('DROP POLICY IF EXISTS %I ON comercial.%I', t || '_nao_bloqueado', t);
    EXECUTE format($f$
      CREATE POLICY %I ON comercial.%I
        AS RESTRICTIVE
        FOR ALL
        TO authenticated
        USING (NOT comercial.hub_user_cliente_bloqueado())
    $f$, t || '_nao_bloqueado', t);
  END LOOP;
END $$;

-- Aprovacao pelo admin: liberar o acesso e limpar o bloqueio e a tag.
CREATE OR REPLACE FUNCTION comercial.hub_fn_liberar_cliente(p_cliente_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = comercial, public
AS $$
DECLARE
  v_role text;
  v_row  comercial.hub_clientes%ROWTYPE;
BEGIN
  SELECT role INTO v_role FROM comercial.hub_perfis
   WHERE user_id = auth.uid() AND ativo = true LIMIT 1;

  IF v_role IS NULL OR v_role NOT IN ('admin', 'manager') THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Apenas admin ou manager pode liberar');
  END IF;

  UPDATE comercial.hub_clientes
     SET bloqueado = false,
         status_cadastro = 'ativo',
         tags = array_remove(tags, 'blocked'),
         atualizado_em = now()
   WHERE id = p_cliente_id
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'Cliente nao encontrado');
  END IF;

  INSERT INTO comercial.hub_log_alteracoes
    (usuario_id, tabela_ref, registro_id, campo, valor_anterior, valor_novo, acao)
  VALUES
    (auth.uid(), 'hub_clientes', p_cliente_id::text, 'status_cadastro',
     'suspenso', 'ativo', 'liberar_acesso');

  RETURN jsonb_build_object('ok', true, 'cliente_id', p_cliente_id,
                            'nome', v_row.nome_exibicao);
END $$;

COMMENT ON FUNCTION comercial.hub_fn_liberar_cliente(uuid) IS
  'Admin/manager libera o acesso de um cliente suspenso. Registra em hub_log_alteracoes.';

GRANT EXECUTE ON FUNCTION comercial.hub_fn_liberar_cliente(uuid) TO authenticated;
