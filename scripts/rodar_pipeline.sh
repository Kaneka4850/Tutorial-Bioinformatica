#!/usr/bin/env bash
# =============================================================================
# Roda o pipeline inteiro com UM comando, usando Docker.
# -----------------------------------------------------------------------------
# Como usar (dentro da pasta do repositório):
#     bash scripts/rodar_pipeline.sh
#
# Etapas:
#   1. Confere se o Docker está instalado e ligado.
#   2. Mede o seu computador (scripts/verificar_recursos.py) e decide quantas
#      threads e quanta RAM o pipeline pode usar.
#   3. Constrói a imagem Docker (só demora na primeira vez).
#   4. Prepara a referência (scripts/preparar_referencia.sh) dentro do Docker.
#   5. Roda o Snakemake dentro do Docker, com limite de CPU e memória, para o
#      computador não travar.
# =============================================================================

set -euo pipefail

IMAGEM="tutorial-bioinfo"
ARQUIVO_RECURSOS="config/recursos.yaml"

# Sempre trabalha a partir da pasta principal do repositório.
cd "$(dirname "$0")/.."

informar() {
    echo -e "\n>>> $*"
}

# Para o script com uma mensagem clara se o Docker não estiver pronto.
conferir_docker() {
    if ! command -v docker > /dev/null 2>&1; then
        echo "ERRO: Docker não instalado. Veja a seção 'Docker' do README." >&2
        exit 1
    fi
    if ! docker info > /dev/null 2>&1; then
        echo "ERRO: o Docker está instalado mas não está ligado (ou sem permissão)." >&2
        echo "Tente: sudo service docker start   e depois rode este script de novo." >&2
        exit 1
    fi
}

# Lê um valor numérico (ex.: threads) do config/recursos.yaml.
ler_recurso() {
    grep "^$1:" "$ARQUIVO_RECURSOS" | awk '{print $2}'
}

# Roda um comando dentro do container, com a pasta do repositório montada em
# /pipeline, com o seu usuário (para os arquivos não ficarem do root) e com os
# limites de CPU e memória calculados. HOME e user.home apontam para /tmp
# porque o seu usuário não existe dentro do container (senão o Java cria uma
# pasta "?" no repositório).
rodar_no_docker() {
    docker run --rm \
        --cpus "$THREADS" \
        --memory "${MEMORIA_GB}g" \
        --user "$(id -u):$(id -g)" \
        --env HOME=/tmp \
        --env JAVA_TOOL_OPTIONS=-Duser.home=/tmp \
        --volume "$PWD":/pipeline \
        --workdir /pipeline \
        "$IMAGEM" "$@"
}

main() {
    informar "1/5 Conferindo o Docker"
    conferir_docker

    informar "2/5 Medindo os recursos do computador"
    python3 scripts/verificar_recursos.py
    THREADS="$(ler_recurso threads)"
    MEMORIA_GB="$(ler_recurso memoria_gb)"

    informar "3/5 Construindo a imagem Docker (na primeira vez leva alguns minutos)"
    docker build -t "$IMAGEM" .

    informar "4/5 Preparando o genoma de referência"
    rodar_no_docker bash scripts/preparar_referencia.sh

    informar "5/5 Rodando o pipeline com $THREADS thread(s) e até ${MEMORIA_GB} GB de RAM"
    rodar_no_docker snakemake --cores "$THREADS" --printshellcmds

    informar "Pronto! Os resultados estão na pasta resultados/"
}

main "$@"
