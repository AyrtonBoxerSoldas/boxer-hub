# ADR-001: Arquitetura Connector-First

**Status:** Proposta
**Data:** 2026-08-04
**Decisor:** Andre Coelho / Arquitetura Boxer Hub

---

## Contexto

O Boxer Hub precisa integrar multiplos sistemas externos (ERP ZEN, bureaus de credito, bancos, transportadoras, comunicacao). Esses sistemas podem mudar ao longo da vida util da plataforma (10+ anos). A dependencia direta entre modulos da plataforma e sistemas externos criaria acoplamento que tornaria qualquer substituicao extremamente custosa.

## Decisao

Adotar uma arquitetura Connector-First onde **nenhum modulo do Boxer Hub se comunica diretamente com sistemas externos**. Toda integracao ocorre atraves de conectores independentes com interface padronizada.

### Estrutura de um Conector

```
Modulo Boxer Hub → Interface do Conector (contrato) → Implementacao do Conector → Sistema Externo
```

Cada conector implementa uma interface padronizada. Substituir o sistema externo exige apenas uma nova implementacao do conector, sem alterar os modulos consumidores.

### Exemplo Concreto

```
Portal Cliente → IERPConnector.getPedidoStatus() → ZenERPConnector → ZEN API
                                                  → FuturoERPConnector → Novo ERP API
```

## Consequencias

### Positivas
- Substituicao de ERP sem impacto nos modulos
- Testabilidade (mock de conectores em testes)
- Isolamento de falhas (conector falha, modulo degrada graciosamente)
- Possibilidade de migracoes graduais

### Negativas
- Camada adicional de abstracao (complexidade inicial)
- Mapeamento de dados entre formatos (transformacao no conector)
- Potencial overhead de latencia (mitigavel com cache)

## Alternativas Consideradas

1. **Integracao direta com ERP:** Descartada por criar acoplamento irreversivel.
2. **ESB / Barramento:** Descartada por ser overkill para o volume atual e adicionar dependencia de infraestrutura.
3. **API Gateway:** Complementar, nao substituta. Gateway gerencia trafego; conector gerencia transformacao e logica de integracao.
