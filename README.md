# QA Test - Performance (JMeter)

Teste de performance para o fluxo de compra de passagem aérea no [BlazDemo](https://www.blazedemo.com/), desenvolvido como parte de um teste técnico para QA.

## Sumário

- [Sobre o Projeto](#sobre-o-projeto)
- [Cenário de Teste](#cenário-de-teste)
- [Critério de Aceitação](#critério-de-aceitação)
- [Arquitetura do Teste](#arquitetura-do-teste)
- [Stack Tecnológica](#stack-tecnológica)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Pré-requisitos](#pré-requisitos)
- [Configuração e Execução](#configuração-e-execução)
- [Relatório de Execução](#relatório-de-execução)
- [Análise APDEX](#análise-apdex)
- [Conclusão](#conclusão)
- [Decisões Técnicas](#decisões-técnicas)

---

## Sobre o Projeto

Este projeto implementa dois tipos de teste de performance para o fluxo completo de compra de passagem aérea no site BlazDemo:

1. **Teste de Carga (Load Test)** — simula tráfego sustentado para medir a capacidade do sistema
2. **Teste de Pico (Spike Test)** — simula um aumento súbito de tráfego para avaliar a resiliência

Ambos os testes cobrem o fluxo end-to-end de 4 passos, com dados variados via CSV e assertions em cada etapa.

## Cenário de Teste

### Fluxo: Compra de passagem aérea — Passagem comprada com sucesso

O cenário simula o fluxo completo de um usuário comprando uma passagem:

| Step | Ação | Método | Endpoint | Validação |
|------|------|--------|----------|-----------|
| 1 | Acessar página inicial | GET | `/` | Contém "Welcome to the Simple Travel Agency" |
| 2 | Buscar voos (Paris → London) | POST | `/reserve.php` | Contém "Flights from Paris to London" |
| 3 | Selecionar voo (Virgin America #43) | POST | `/purchase.php` | Contém "Please submit the form below to purchase" |
| 4 | Confirmar compra (dados do passageiro) | POST | `/confirmation.php` | Contém "Thank you for your purchase today" |

### Dados de Teste

Os dados dos passageiros são variados via **CSV Data Set** (`test-data/passengers.csv`) com 10 registros diferentes, incluindo:
- Nomes, endereços e cidades brasileiras
- Diferentes tipos de cartão (Visa, Amex, Diner's Club)
- Números de cartão válidos para teste

Essa abordagem garante que o teste não envia dados idênticos em todas as requisições, simulando comportamento mais realista.

## Critério de Aceitação

| Métrica | Critério | Objetivo |
|---------|----------|----------|
| **Vazão (Throughput)** | 250 requisições por segundo | Garantir que o sistema suporta a carga esperada |
| **Tempo de resposta p90** | Inferior a 2 segundos | 90% das requisições devem responder em até 2s |

## Arquitetura do Teste

### Teste de Carga (Load Test)

| Parâmetro | Valor | Justificativa |
|-----------|-------|---------------|
| **Threads (usuários)** | 50 | Carga sustentada para atingir ~250 req/s com 4 steps por iteração |
| **Ramp-up** | 10 segundos | Subida gradual para não gerar pico artificial |
| **Iterações** | 10 por thread | Total: 50 × 10 × 4 steps = 2.000 requisições |
| **Think Time** | 500ms | Simula tempo de reflexão do usuário entre páginas |

### Teste de Pico (Spike Test)

| Parâmetro | Valor | Justificativa |
|-----------|-------|---------------|
| **Threads (usuários)** | 100 | Dobro da carga para simular pico súbito |
| **Ramp-up** | 5 segundos | Subida agressiva para estressar o sistema |
| **Iterações** | 5 por thread | Total: 100 × 5 × 4 steps = 2.000 requisições |
| **Think Time** | 500ms | Mesmo think time para comparação justa |

### Elementos Compartilhados

- **HTTP Request Defaults** — URL base, protocolo, timeouts centralizados
- **HTTP Cookie Manager** — gerencia cookies entre requests (sessão)
- **HTTP Header Manager** — simula headers de browser real (User-Agent, Accept)
- **CSV Data Set** — variação de dados de passageiros
- **Response Assertions** — valida conteúdo esperado em cada step
- **Summary Report** — coleta métricas agregadas

## Stack Tecnológica

| Tecnologia | Versão | Justificativa |
|-----------|--------|---------------|
| Apache JMeter | 5.6.3 | Ferramenta de performance mais utilizada, suporte a HTTP, relatórios HTML nativos |
| Java | 21 (OpenJDK) | Runtime necessário para o JMeter |

## Estrutura do Projeto

```
qa-test-performance-jmeter/
├── test-plans/
│   ├── compra-passagem-carga.jmx    # Plano de teste de carga
│   └── compra-passagem-pico.jmx     # Plano de teste de pico (spike)
├── test-data/
│   └── passengers.csv               # Dados variados de passageiros
├── reports/
│   ├── carga/                       # Relatório HTML do teste de carga
│   └── pico/                        # Relatório HTML do teste de pico
├── run-tests.sh                     # Script de execução automatizada
├── .gitignore
└── README.md
```

## Pré-requisitos

- **Java 17+** — [Download](https://adoptium.net/)
- **Apache JMeter 5.6+** — `brew install jmeter` (macOS) ou [Download](https://jmeter.apache.org/download_jmeter.cgi)
- **Git** — [Download](https://git-scm.com/)

## Configuração e Execução

```bash
# 1. Clonar o repositório
git clone https://github.com/filipeCardorso/qa-test-performance-jmeter.git
cd qa-test-performance-jmeter

# 2. Executar ambos os testes (carga + pico)
./run-tests.sh ambos

# 3. Executar apenas teste de carga
./run-tests.sh carga

# 4. Executar apenas teste de pico
./run-tests.sh pico

# 5. Abrir no JMeter GUI (para editar/visualizar)
jmeter -t test-plans/compra-passagem-carga.jmx
```

Após a execução, os relatórios HTML são gerados automaticamente em `results/`. Os relatórios da última execução também estão disponíveis em `reports/` no repositório.

## Relatório de Execução

### Teste de Carga — Resultados

| Métrica | Página Inicial | Buscar Voos | Selecionar Voo | Confirmar Compra | **TOTAL** |
|---------|---------------|-------------|----------------|-----------------|-----------|
| **Amostras** | 500 | 500 | 500 | 500 | **2.000** |
| **Erros** | 0 (0%) | 0 (0%) | 0 (0%) | 0 (0%) | **0 (0%)** |
| **Média (ms)** | 545 | 515 | 506 | 505 | **518** |
| **Mediana (ms)** | 480 | 478 | 469 | 474 | **475** |
| **Min (ms)** | 393 | 396 | 392 | 398 | **392** |
| **Max (ms)** | 1.323 | 1.392 | 1.211 | 1.313 | **1.392** |
| **p90 (ms)** | 815 | 646 | 651 | 632 | **676** |
| **p95 (ms)** | 908 | 741 | 754 | 684 | **799** |
| **p99 (ms)** | 1.082 | 1.160 | 1.007 | 869 | **1.044** |
| **Throughput (req/s)** | 10,1 | 10,2 | 10,2 | 10,2 | **38,0** |

### Teste de Pico (Spike) — Resultados

| Métrica | Página Inicial | Buscar Voos | Selecionar Voo | Confirmar Compra | **TOTAL** |
|---------|---------------|-------------|----------------|-----------------|-----------|
| **Amostras** | 500 | 500 | 500 | 500 | **2.000** |
| **Erros** | 0 (0%) | 0 (0%) | 0 (0%) | 0 (0%) | **0 (0%)** |
| **Média (ms)** | 649 | 569 | 566 | 557 | **585** |
| **Mediana (ms)** | 538 | 492 | 489 | 484 | **495** |
| **Min (ms)** | 392 | 405 | 396 | 393 | **392** |
| **Max (ms)** | 2.189 | 2.258 | 2.247 | 1.898 | **2.258** |
| **p90 (ms)** | 973 | 823 | 790 | 834 | **872** |
| **p95 (ms)** | 1.095 | 1.000 | 1.002 | 992 | **1.025** |
| **p99 (ms)** | 1.928 | 1.576 | 1.433 | 1.449 | **1.556** |
| **Throughput (req/s)** | 19,5 | 20,0 | 20,0 | 19,9 | **70,1** |

## Análise APDEX

O **APDEX (Application Performance Index)** é um padrão aberto que mede a satisfação do usuário com o tempo de resposta. A fórmula é:

```
APDEX = (Satisfeito + Tolerado/2) / Total
```

Utilizando o threshold T = 2 segundos (critério de aceitação):
- **Satisfeito:** response time ≤ T (≤ 2s)
- **Tolerado:** T < response time ≤ 4T (2s–8s)
- **Frustrado:** response time > 4T (> 8s)

### Cálculo APDEX

| Teste | Satisfeito | Tolerado | Frustrado | **APDEX** | **Classificação** |
|-------|-----------|----------|-----------|-----------|-------------------|
| **Carga** | 2.000 (100%) | 0 (0%) | 0 (0%) | **1,00** | Excelente |
| **Pico** | 2.000 (100%) | 0 (0%) | 0 (0%) | **1,00** | Excelente |

**Escala APDEX:**
| Faixa | Classificação |
|-------|---------------|
| 0,94 – 1,00 | Excelente |
| 0,85 – 0,93 | Bom |
| 0,70 – 0,84 | Satisfatório |
| 0,50 – 0,69 | Insatisfatório |
| < 0,50 | Inaceitável |

Ambos os testes atingiram **APDEX 1,00 (Excelente)** — todas as requisições responderam dentro do threshold de 2 segundos.

## Conclusão

### O critério de aceitação foi satisfeito?

**Parcialmente.**

#### Tempo de Resposta p90 < 2 segundos — **SATISFEITO**

| Teste | p90 | Critério | Resultado |
|-------|-----|----------|-----------|
| Carga | 676ms | < 2.000ms | **APROVADO** (66% abaixo do limite) |
| Pico | 872ms | < 2.000ms | **APROVADO** (56% abaixo do limite) |

O p99 de ambos os testes também ficou abaixo de 2 segundos (1.044ms e 1.556ms respectivamente), demonstrando consistência.

#### Vazão de 250 req/s — **NÃO ATINGIDO**

| Teste | Throughput | Critério | Resultado |
|-------|-----------|----------|-----------|
| Carga | 38,0 req/s | 250 req/s | **NÃO ATINGIDO** (15,2% do alvo) |
| Pico | 70,1 req/s | 250 req/s | **NÃO ATINGIDO** (28,0% do alvo) |

### Por que o throughput não atingiu 250 req/s?

Existem três fatores que explicam o throughput abaixo do esperado:

1. **Latência de rede:** O BlazDemo é um servidor externo (hospedado nos EUA). Cada requisição tem ~400ms de latência base (RTT), o que limita fisicamente quantas requisições cada thread consegue fazer por segundo. Com 400ms por request, cada thread faz ~2,5 req/s → 50 threads × 2,5 = ~125 req/s (sem think time).

2. **Think Time de 500ms:** O think time entre steps simula comportamento real do usuário, mas reduz o throughput. Com 400ms de latência + 500ms de think time, cada thread faz ~1,1 req/s → 50 × 1,1 = ~55 req/s.

3. **Limitação do servidor de demonstração:** O BlazDemo é um servidor de testes com capacidade limitada propositalmente. Não é dimensionado para suportar 250 req/s reais.

### Recomendações

Para atingir 250 req/s com o critério de p90 < 2s, seria necessário:

- **Aumentar o número de threads** para 250-300 (compensando a latência)
- **Reduzir ou remover o Think Time** (teste sintético vs. teste realista)
- **Executar mais perto do servidor** (reduzir latência de rede)
- **Ou testar contra uma aplicação local/staging** com latência desprezível

O fato de **todos os tempos de resposta estarem abaixo de 2s** e **0% de erros** demonstra que a aplicação é estável e performática dentro dos limites da infraestrutura de teste.

## Decisões Técnicas

| Decisão | Alternativa | Justificativa |
|---------|------------|---------------|
| JMeter CLI (`-n`) sobre GUI | JMeter GUI | Execução mais rápida, sem overhead gráfico, resultados mais confiáveis |
| CSV Data Set sobre dados fixos | Hardcoded | Simula cenário realista com dados variados |
| Think Time 500ms | Sem think time | Simula comportamento real — throughput puro seria artificial |
| 2 planos separados (carga/pico) | 1 plano com múltiplos Thread Groups | Isolamento — cada teste pode ser executado e analisado independentemente |
| Response Assertions em cada step | Sem assertions | Garante que cada etapa retornou o conteúdo correto (não apenas status 200) |
| Relatório HTML nativo | Plugins adicionais | Já inclui APDEX, percentis, gráficos — sem dependências extras |
| Script bash para execução | Manual | Automatiza a criação de diretórios, timestamps e geração de relatórios |
