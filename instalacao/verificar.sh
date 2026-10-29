#!/usr/bin/env bash
# =============================================================================
# Confere se tudo o que o tutorial precisa está instalado.
# -----------------------------------------------------------------------------
# Como usar (dentro da pasta do repositório):
#     bash instalacao/verificar.sh
#
# Não instala nem muda nada: só mostra a versão de cada programa.
# [ OK ] = encontrado   [FALTA] = não encontrado   [AVISO] = existe mas com problema
# Se pedir ajuda ao professor, copie e cole a saída deste script.
# =============================================================================

set -uo pipefail

cd "$(dirname "$0")/.."

NOME_AMBIENTE="bioinfo"
FALTANDO=0

ok()    { printf '  [ OK ] %-12s %s\n' "$1" "$2"; }
falta() { printf '  [FALTA] %-11s %s\n' "$1" "$2"; FALTANDO=$((FALTANDO + 1)); }
aviso() { printf '  [AVISO] %-11s %s\n' "$1" "$2"; }

# Mostra a primeira linha da versão de um programa, ou marca como faltando.
conferir() {
    local nome="$1"; shift
    local dica="$1"; shift
    local saida
    if saida="$("$@" 2>&1 | grep -v '^\s*$' | head -1)" && [[ -n "$saida" ]]; then
        ok "$nome" "$saida"
    else
        falta "$nome" "${dica:-rode: conda env update -n bioinfo -f environment.yml}"
    fi
}

echo "============================================================"
echo " Verificação do ambiente do tutorial"
echo " Sistema: $(uname -s) $(uname -m)  |  $(date '+%d/%m/%Y %H:%M')"
echo "============================================================"

echo -e "\nProgramas do sistema"
conferir git "veja a seção Git do README" git --version
conferir python3.13 "veja a seção Python 3.13 do README" python3.13 --version

if [[ -x .venv/bin/python ]]; then
    if .venv/bin/python -c "import snakemake, pandas, requests, psutil, yaml" 2> /dev/null; then
        ok ".venv" "$(.venv/bin/python --version) com snakemake, pandas, requests, psutil, pyyaml"
    else
        aviso ".venv" "existe mas falta biblioteca: rode .venv/bin/pip install -r requirements.txt"
    fi
else
    falta ".venv" "rode: python3.13 -m venv .venv && .venv/bin/pip install -r requirements.txt"
fi

echo -e "\nDocker"
if command -v docker > /dev/null 2>&1 && docker --version > /dev/null 2>&1; then
    if docker info > /dev/null 2>&1; then
        ok docker "$(docker --version) (ligado)"
    else
        aviso docker "$(docker --version) instalado mas desligado ou sem permissão"
    fi
else
    falta docker "opcional se você for usar só o conda"
fi

echo -e "\nConda e ferramentas de bioinformática (ambiente '$NOME_AMBIENTE')"
CONDA=""
if [[ -x "$HOME/miniconda3/bin/conda" ]]; then
    CONDA="$HOME/miniconda3/bin/conda"
elif [[ -n "${CONDA_EXE:-}" && -x "${CONDA_EXE}" ]]; then
    CONDA="$CONDA_EXE"
fi

if [[ -z "$CONDA" ]]; then
    falta conda "opcional se você for usar só o Docker"
elif ! "$CONDA" env list | awk '{print $1}' | grep -qx "$NOME_AMBIENTE"; then
    ok conda "$("$CONDA" --version)"
    falta "$NOME_AMBIENTE" "rode: conda env create -f environment.yml"
else
    ok conda "$("$CONDA" --version)"
    rodar() { "$CONDA" run -n "$NOME_AMBIENTE" "$@"; }
    conferir fastqc   "" rodar fastqc --version
    conferir bwa      "" bash -c "'$CONDA' run -n $NOME_AMBIENTE bwa 2>&1 | grep Version"
    conferir samtools "" rodar samtools --version
    conferir bcftools "" rodar bcftools --version
    conferir bedtools "" rodar bedtools --version
    conferir gatk     "" bash -c "'$CONDA' run -n $NOME_AMBIENTE gatk --version 2>&1 | grep Toolkit"
    conferir snakemake "" rodar snakemake --version
    conferir python   "" rodar python --version
fi

echo -e "\nRecursos do computador"
if [[ -x .venv/bin/python ]]; then
    .venv/bin/python scripts/verificar_recursos.py
elif command -v python3 > /dev/null 2>&1; then
    python3 scripts/verificar_recursos.py
fi

echo
if [[ "$FALTANDO" -eq 0 ]]; then
    echo "Tudo certo! Você já pode rodar o pipeline (veja a seção 'Rodar o pipeline')."
else
    echo "$FALTANDO item(ns) faltando. Veja as dicas acima ou rode: bash instalacao/instalar.sh"
fi
