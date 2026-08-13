# ADR-002: Motor de Inteligencia Comercial (CIE) Parametrizado

**Status:** Proposta
**Data:** 2026-08-04
**Decisor:** Andre Coelho / Arquitetura Boxer Hub

---

## Contexto

A Boxer Soldas possui regras comerciais complexas que mudam frequentemente: descontos por canal, alcadas de aprovacao, campanhas, restricoes regionais, cross-sell, tabelas de precos com vigencia. Codificar essas regras diretamente no codigo tornaria cada alteracao um deploy, com risco de erro e dependencia de TI.

## Decisao

Criar o Commercial Intelligence Engine (CIE) como componente interno do Boxer Hub, responsavel por avaliar todas as regras comerciais de forma 100% parametrizada.

### Principios do CIE

1. **Nenhuma regra comercial hardcoded.** Todas sao parametrizadas e configuradas via interface.
2. **Versionamento de regras.** Toda alteracao gera uma versao com autor, data e diff.
3. **Vigencia temporal.** Regras possuem data de inicio e fim, permitindo agendamento.
4. **Composicao.** Multiplas regras podem coexistir e ser avaliadas em sequencia (pipeline de regras).
5. **Auditoria.** Toda decisao do CIE e registrada com a regra aplicada e o resultado.

### Dominio do CIE

| Area | Exemplos de Regras |
|---|---|
| Precificacao | Tabela base, desconto por canal, campanha, kit, preco especial |
| Elegibilidade | Cliente pode comprar produto X? Canal tem acesso a categoria Y? |
| Aprovacao | Valor > R$ X.000 exige aprovacao do gerente? |
| Recomendacao | Cliente comprou A, sugerir B (cross-sell)? |
| Restricao | Produto Z nao vende na regiao W? |
| Credito | Score < X bloqueia pedido automaticamente? |

## Consequencias

### Positivas
- Equipe comercial altera regras sem TI
- Reducao drastica de bugs de regra comercial
- Auditoria completa de decisoes
- Possibilidade de simular impacto antes de publicar

### Negativas
- Complexidade de desenvolvimento do motor
- Necessidade de interface de configuracao robusta
- Curva de aprendizado para a equipe comercial

## Alternativas Consideradas

1. **Regras no codigo:** Descartada por inflexibilidade e risco.
2. **Rules Engine externo (Drools, etc.):** Descartada por adicionar dependencia de stack Java e complexidade operacional desproporcional.
3. **Low-code (Retool, etc.):** Descartada por falta de controle e lock-in.
