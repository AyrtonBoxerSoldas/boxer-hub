# ADR-007: Preparacao para IA sem Implementacao Inicial

**Status:** Proposta
**Data:** 2026-08-04
**Decisor:** Andre Coelho / Arquitetura Boxer Hub

---

## Contexto

O briefing solicita preparacao arquitetural para IA (assistente comercial, recomendacoes, analise preditiva) sem implementacao na fase inicial.

## Decisao

A arquitetura preve um **AI Connector** na camada de conectores, com interface definida mas sem implementacao ativa. Os modulos do Boxer Hub chamarao essa interface para:

1. Recomendacao de produtos (retorna lista ranqueada)
2. Analise de texto (classificacao de chamados)
3. Assistente conversacional (respostas contextuais)
4. Analise preditiva (score de churn, propensao de compra)

Na fase inicial, o AI Connector retornara respostas estaticas ou baseadas em regras simples do CIE. Quando IA for implementada, a troca sera transparente.

## Consequencias

### Positivas
- Sem retrabalho quando IA for adotada
- Interface ja testada com dados reais
- Possibilidade de migrar incrementalmente (regra → ML → LLM)

### Negativas
- Custo minimo de manter interface nao utilizada (aceitavel)
