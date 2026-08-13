# ADR-006: Modelo de Dados — Projeto Supabase Dedicado

**Status:** Proposta
**Data:** 2026-08-04
**Decisor:** Andre Coelho / Arquitetura Boxer Hub

---

## Contexto

Diferente do Padrao Boxer basico (que compartilha `boxer-sistemas`), o Boxer Hub tera seu proprio projeto Supabase dedicado (ver ADR-005). Isso permite uma estrutura de dados limpa, sem prefixos de isolamento, com schemas funcionais.

## Decisao

Todas as tabelas do Boxer Hub serao criadas no projeto Supabase dedicado, usando o schema `public` (padrao) com nomenclatura limpa em portugues, snake_case.

### Nomenclatura

```
public.clientes
public.representantes
public.carteira               -- vinculo representante-cliente
public.pedidos
public.pedido_itens
public.produtos
public.categorias
public.tabela_precos
public.tabela_preco_itens
public.regras_comerciais
public.campanhas
public.campanha_produtos
public.pesquisas
public.pesquisa_perguntas
public.pesquisa_respostas
public.log_alteracoes
public.log_autenticacao
```

### Convencoes
- **snake_case** em portugues para tabelas e colunas
- Coluna `criado_em` (timestamp) obrigatoria em todas as tabelas
- Coluna `ativo` (boolean) para exclusao logica
- RLS ativado em 100% das tabelas
- UUIDs como chave primaria (`gen_random_uuid()`)

## Consequencias

### Positivas
- Nomenclatura limpa e legivel (sem prefixos de isolamento ou schemas de setor)
- Projeto isolado — sem risco de conflito com outros sistemas
- Gestao total pelo lider do projeto
- Estrutura intuitiva para novos desenvolvedores

### Negativas
- Fora do padrao `boxer-sistemas` (excecao justificada pela escala do projeto)
- Dados do Boxer Hub nao sao acessiveis por outros sistemas Boxer via mesmo projeto (integracao via conectores)
