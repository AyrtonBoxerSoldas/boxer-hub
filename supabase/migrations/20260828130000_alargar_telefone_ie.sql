-- Import real de clientes Zen (2026-08-28): 15 de ~39 lotes falharam com
-- "value too long for type character varying(20)". telefone e
-- inscricao_estadual vinham em varchar(20), estreito demais para o dado
-- livre do ERP (telefone com extensao/observacao, IE fora do padrao). Como
-- o insert e em lote, uma linha estourando o limite derrubava o lote
-- inteiro -- 3.114 clientes ficaram de fora por causa de poucas linhas.

ALTER TABLE comercial.hub_clientes
  ALTER COLUMN telefone TYPE varchar(50),
  ALTER COLUMN inscricao_estadual TYPE varchar(50);
