# ADR-003: Politica Comercial como Ativo Independente

**Status:** Proposta
**Data:** 2026-08-04
**Decisor:** Andre Coelho / Arquitetura Boxer Hub

---

## Contexto

A Politica Comercial da Boxer define descontos, condicoes, alcadas, campanhas e restricoes. Atualmente, partes dessa politica estao no ERP, partes em planilhas e partes na memoria dos gestores. O ERP nao e o dono natural dessa politica — ele a aplica, mas nao a governa.

## Decisao

Tratar a Politica Comercial como um ativo digital independente, gerenciado exclusivamente pelo Boxer Hub (via CIE), com as seguintes caracteristicas:

1. **Armazenamento proprio.** Dados da politica ficam no banco do Boxer Hub, nao no ERP.
2. **Versionamento.** Toda versao e preservada com historico completo.
3. **Interface de gestao.** Gerentes configuram via Portal ADM, sem TI.
4. **Publicacao controlada.** Novas versoes podem ser agendadas ou publicadas imediatamente.
5. **Propagacao ao ERP.** Regras relevantes sao sincronizadas ao ERP via conector, nao o contrario.

## Consequencias

### Positivas
- Fonte unica de verdade para regras comerciais
- Autonomia da equipe comercial
- Historico e auditoria completos
- Independencia do ERP

### Negativas
- Necessidade de sincronizar regras relevantes ao ERP
- Risco de divergencia se ERP for alterado diretamente (mitigavel com monitoramento)
