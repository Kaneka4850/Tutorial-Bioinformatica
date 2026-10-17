#!/usr/bin/env bash
# =============================================================================
# Prepara o genoma de referência para o alinhamento e a chamada de variantes.
# -----------------------------------------------------------------------------
# Como usar (dentro da pasta do repositório):
#     bash scripts/preparar_referencia.sh
#
# Etapas:
#   1. Descompacta chr6.fa.gz -> chr6.fa (BWA e GATK precisam do arquivo aberto)
#   2. bwa index ................ índice para o BWA achar onde cada read encaixa
#   3. samtools faidx ........... índice .fai para acessar qualquer posição rápido
#   4. gatk CreateSequenceDictionary  dicionário .dict exigido pelo GATK
#
# Cada etapa é pulada se o arquivo dela já existir, então você pode rodar o
# script várias vezes sem refazer trabalho.
# =============================================================================

# Para o script no primeiro erro, em variável não definida ou em falha de pipe.
set -euo pipefail

REFERENCIA_GZ="${1:-dados/referencia/chr6.fa.gz}"
REFERENCIA="${REFERENCIA_GZ%.gz}"
DICIONARIO="${REFERENCIA%.fa}.dict"

# Imprime uma mensagem destacada para o usuário acompanhar o progresso.
informar() {
    echo -e "\n>>> $*"
}

# Confere se um programa está instalado antes de começar.
exigir_programa() {
    if ! command -v "$1" > /dev/null 2>&1; then
        echo "ERRO: o programa '$1' não foi encontrado." >&2
        echo "Ative o ambiente conda (conda activate bioinfo) ou use scripts/rodar_pipeline.sh (Docker)." >&2
        exit 1
    fi
}

# Etapa 1: descompacta mantendo o .gz original.
descompactar_referencia() {
    if [[ -s "$REFERENCIA" ]]; then
        informar "Referência já descompactada: $REFERENCIA"
        return
    fi
    informar "Descompactando $REFERENCIA_GZ"
    gunzip -c "$REFERENCIA_GZ" > "$REFERENCIA"
}

# Etapa 2: índice do BWA (gera .amb .ann .bwt .pac .sa). Leva alguns minutos.
indexar_bwa() {
    if [[ -s "$REFERENCIA.bwt" ]]; then
        informar "Índice do BWA já existe"
        return
    fi
    informar "Criando índice do BWA (pode levar de 3 a 10 minutos)"
    bwa index "$REFERENCIA"
}

# Etapa 3: índice FASTA (.fai) usado pelo samtools e pelo GATK.
indexar_samtools() {
    if [[ -s "$REFERENCIA.fai" ]]; then
        informar "Índice .fai já existe"
        return
    fi
    informar "Criando índice .fai com samtools faidx"
    samtools faidx "$REFERENCIA"
}

# Etapa 4: dicionário de sequências (.dict) exigido pelo GATK.
criar_dicionario() {
    if [[ -s "$DICIONARIO" ]]; then
        informar "Dicionário .dict já existe"
        return
    fi
    informar "Criando dicionário com gatk CreateSequenceDictionary"
    gatk CreateSequenceDictionary -R "$REFERENCIA" -O "$DICIONARIO"
}

main() {
    for programa in gunzip bwa samtools gatk; do
        exigir_programa "$programa"
    done
    descompactar_referencia
    indexar_bwa
    indexar_samtools
    criar_dicionario
    informar "Referência pronta!"
}

main
