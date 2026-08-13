# ADR-004: Tabela de Precos como Fonte Oficial da Plataforma

**Status:** Proposta
**Data:** 2026-08-04
**Decisor:** Andre Coelho / Arquitetura Boxer Hub

---

## Contexto

A Boxer opera com multiplas tabelas de precos (por canal, por cliente, por campanha). Essas tabelas possuem vigencia, regras tributarias e excecoes. O ERP armazena precos operacionais, mas a logica de precificacao (qual tabela aplicar, quando, para quem) e um ativo comercial.

## Decisao

Manter a base de tabelas de precos como fonte oficial dentro do Boxer Hub, gerenciada pelo CIE, com:

1. **Multiplas tabelas coexistentes.** Canal, cliente, campanha, promocao.
2. **Vigencia temporal.** Data de inicio e fim para cada tabela.
3. **Hierarquia de resolucao.** CIE resolve conflitos: preco especial > campanha > tabela do cliente > tabela do canal > tabela base.
4. **Historico.** Todas as versoes de tabelas sao preservadas.
5. **Sincronizacao com ERP.** Preco final e enviado ao ERP junto com o pedido.

## Consequencias

### Positivas
- Preco exibido ao cliente e sempre correto e contextualizado
- Simulacao de impacto de mudancas de preco antes da publicacao
- Historico completo para auditoria e disputas

### Negativas
- Complexidade de resolucao de precos
- Necessidade de manter consistencia com ERP
