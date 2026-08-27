-- Agrupamento e ordenacao das categorias do catalogo
--
-- Problema: public.categorias numera `ordem` por tabela de preco. Principal (1)
-- e Automacao (2) ambas comecam em 0, entao LASER/ROBOS (tab 2) apareciam
-- embaralhados no meio das maquinas (tab 1). E 28 chips nao cabem numa linha.
--
-- Regra de negocio: maquinas no topo, consumiveis e acessorios no fim.
--
-- Tabela de configuracao em vez de CASE na view: a ordem e decisao comercial e
-- muda com o tempo. Editar aqui nao exige migration nem deploy.

CREATE TABLE IF NOT EXISTS comercial.hub_categoria_config (
  categoria_nome text PRIMARY KEY,
  grupo          text    NOT NULL,
  grupo_ordem    int     NOT NULL,
  ordem          int     NOT NULL DEFAULT 0,
  oculta         boolean NOT NULL DEFAULT false,
  criado_em      timestamptz NOT NULL DEFAULT now(),
  ativo          boolean NOT NULL DEFAULT true
);

COMMENT ON TABLE comercial.hub_categoria_config IS
  'Agrupamento e ordem de exibicao das categorias no catalogo. categoria_nome casa com public.categorias.nome.';

INSERT INTO comercial.hub_categoria_config (categoria_nome, grupo, grupo_ordem, ordem, oculta) VALUES
  -- 1. Maquinas primeiro
  ('INVERSORAS',                    'Máquinas',    1,  1, false),
  ('MULTI PROCESSO',                'Máquinas',    1,  2, false),
  ('MIG DUPLO PULSADO',             'Máquinas',    1,  3, false),
  ('TIG',                           'Máquinas',    1,  4, false),
  ('CORTE PLASMA',                  'Máquinas',    1,  5, false),
  ('LASER',                         'Máquinas',    1,  6, false),
  -- 2. Automacao
  ('ROBÔS',                         'Automação',   2,  1, false),
  ('FONTES P/ ROBÔ',                'Automação',   2,  2, false),
  ('EQUIPAMENTOS ROBÔS',            'Automação',   2,  3, false),
  ('TOCHAS PARA ROBÔS',             'Automação',   2,  4, false),
  -- 3. Protecao
  ('MÁSCARAS',                      'Proteção',    3,  1, false),
  ('LUVAS',                         'Proteção',    3,  2, false),
  -- 4. Tochas
  ('TOCHAS',                        'Tochas',      4,  1, false),
  -- 5. Acessorios
  ('ACESSÓRIOS MÁQUINAS',           'Acessórios',  5,  1, false),
  ('ACESSÓRIOS MÁSCARAS',           'Acessórios',  5,  2, false),
  ('REGULADORES DE GÁS',            'Acessórios',  5,  3, false),
  ('FERRAMENTAS',                   'Acessórios',  5,  4, false),
  ('PERIFÉRICOS',                   'Acessórios',  5,  5, false),
  ('CABOS POR METRO',               'Acessórios',  5,  6, false),
  ('TUNGSTÊNIOS',                   'Acessórios',  5,  7, false),
  ('ANTI RESPINGOS',                'Acessórios',  5,  8, false),
  ('ROLDANAS',                      'Acessórios',  5,  9, false),
  -- 6. Consumiveis por ultimo
  ('CONSUMÍVEIS',                   'Consumíveis', 6,  1, false),
  ('CONSUMÍVEIS TOCHAS MIG-MAG',    'Consumíveis', 6,  2, false),
  ('CONSUMÍVEIS TOCHAS TIG',        'Consumíveis', 6,  3, false),
  ('CONSUMÍVEIS TOCHAS PLASMA',     'Consumíveis', 6,  4, false),
  ('CONSUMÍVEIS TOCHAS ROBÔ',       'Consumíveis', 6,  5, false),
  ('CONSUMÍVEIS LASER',             'Consumíveis', 6,  6, false),
  -- 7. Pecas de reposicao: fora dos chips, so por filtro explicito ou busca
  ('VISTA EXPLODIDA TOCHAS BX',     'Peças',       7,  1, true),
  ('VISTA EXPLODIDA TOCHAS M',      'Peças',       7,  2, true),
  ('VISTA EXPLODIDA TOCHAS PLASMA', 'Peças',       7,  3, true)
ON CONFLICT (categoria_nome) DO NOTHING;

ALTER TABLE comercial.hub_categoria_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS hub_cat_config_select ON comercial.hub_categoria_config;
CREATE POLICY hub_cat_config_select
  ON comercial.hub_categoria_config FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS hub_cat_config_admin ON comercial.hub_categoria_config;
CREATE POLICY hub_cat_config_admin
  ON comercial.hub_categoria_config FOR ALL TO authenticated
  USING (comercial.hub_user_role() IN ('admin', 'manager'))
  WITH CHECK (comercial.hub_user_role() IN ('admin', 'manager'));

GRANT SELECT ON comercial.hub_categoria_config TO anon, authenticated;
