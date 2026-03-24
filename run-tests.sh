#!/bin/bash

# ============================================================
# Script de execução dos testes de performance
# Uso: ./run-tests.sh [carga|pico|ambos]
# ============================================================

set -e

JMETER_CMD="jmeter"
RESULTS_DIR="results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  Teste de Performance - BlazDemo                           ${NC}"
echo -e "${BLUE}  Compra de Passagem Aérea                                  ${NC}"
echo -e "${BLUE}============================================================${NC}"

# Verificar se JMeter está instalado
if ! command -v $JMETER_CMD &> /dev/null; then
    echo -e "${RED}ERRO: JMeter não encontrado. Instale com: brew install jmeter${NC}"
    exit 1
fi

echo -e "${GREEN}JMeter versão: $($JMETER_CMD --version 2>&1 | head -1)${NC}"

# Criar diretório de resultados
mkdir -p "$RESULTS_DIR"

MODE=${1:-ambos}

run_load_test() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  TESTE DE CARGA                                           ${NC}"
    echo -e "${YELLOW}  50 threads | 10s ramp-up | 10 iterações                  ${NC}"
    echo -e "${YELLOW}  Critério: 250 req/s com p90 < 2s                         ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    LOAD_RESULTS="$RESULTS_DIR/carga_${TIMESTAMP}"
    mkdir -p "$LOAD_RESULTS"

    $JMETER_CMD -n \
        -t test-plans/compra-passagem-carga.jmx \
        -l "$LOAD_RESULTS/results.jtl" \
        -j "$LOAD_RESULTS/jmeter.log" \
        -e -o "$LOAD_RESULTS/report"

    echo ""
    echo -e "${GREEN}Relatório de carga gerado em: $LOAD_RESULTS/report/index.html${NC}"
}

run_spike_test() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  TESTE DE PICO (SPIKE)                                    ${NC}"
    echo -e "${YELLOW}  100 threads | 5s ramp-up | 5 iterações                   ${NC}"
    echo -e "${YELLOW}  Objetivo: avaliar resiliência sob pico súbito            ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    SPIKE_RESULTS="$RESULTS_DIR/pico_${TIMESTAMP}"
    mkdir -p "$SPIKE_RESULTS"

    $JMETER_CMD -n \
        -t test-plans/compra-passagem-pico.jmx \
        -l "$SPIKE_RESULTS/results.jtl" \
        -j "$SPIKE_RESULTS/jmeter.log" \
        -e -o "$SPIKE_RESULTS/report"

    echo ""
    echo -e "${GREEN}Relatório de pico gerado em: $SPIKE_RESULTS/report/index.html${NC}"
}

case $MODE in
    carga)
        run_load_test
        ;;
    pico)
        run_spike_test
        ;;
    ambos)
        run_load_test
        echo ""
        echo -e "${BLUE}Aguardando 10s antes do teste de pico...${NC}"
        sleep 10
        run_spike_test
        ;;
    *)
        echo "Uso: ./run-tests.sh [carga|pico|ambos]"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}  Execução concluída!                                       ${NC}"
echo -e "${GREEN}  Relatórios disponíveis em: $RESULTS_DIR/                  ${NC}"
echo -e "${BLUE}============================================================${NC}"
