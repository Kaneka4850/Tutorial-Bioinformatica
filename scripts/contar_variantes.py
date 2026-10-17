#!/usr/bin/env python3
"""
Conta as variantes anotadas pelo VEP por classificação clínica (ClinVar):
patogênica, provavelmente patogênica, VUS (significado incerto),
provavelmente benigna e benigna.

Regra usada quando uma variante tem mais de uma classificação no ClinVar
(isso é comum, porque laboratórios diferentes enviam laudos diferentes):
fica a classificação mais grave, na ordem
    patogênica > provavelmente patogênica > VUS > provavelmente benigna > benigna.
É uma simplificação didática: na rotina clínica também se olha o número de
estrelas (review status) do ClinVar e os critérios ACMG.

Como usar:
    python scripts/contar_variantes.py --json resultados/04_anotacao/amostra.vep.json \\
        --saida-csv resultados/05_contagem/amostra.contagem.csv
"""

import argparse
import csv
import json
import sys
from collections import Counter
from pathlib import Path

# Reaproveita a leitura dos termos do ClinVar feita no script de anotação.
from anotar_vep import extrair_termos_clinicos

# Categorias em ordem de gravidade (a primeira encontrada vence).
# Cada categoria lista os termos do ClinVar/VEP que pertencem a ela.
CATEGORIAS = [
    ("Patogênica", {"pathogenic", "pathogenic,_low_penetrance", "pathogenic_low_penetrance"}),
    ("Provavelmente patogênica", {"likely_pathogenic", "likely_pathogenic,_low_penetrance",
                                  "likely_pathogenic_low_penetrance"}),
    ("VUS (significado incerto)", {"uncertain_significance"}),
    ("Provavelmente benigna", {"likely_benign"}),
    ("Benigna", {"benign"}),
]
CONFLITANTE = "Conflitante no ClinVar"
SEM_CLASSIFICACAO = "Sem classificação no ClinVar"
TERMOS_CONFLITANTES = {"conflicting_interpretations_of_pathogenicity",
                       "conflicting_classifications_of_pathogenicity"}

ORDEM_DA_TABELA = [nome for nome, _ in CATEGORIAS] + [CONFLITANTE, SEM_CLASSIFICACAO]


def classificar(termos: list[str]) -> str:
    """Escolhe a categoria mais grave entre os termos clínicos da variante."""
    for nome, termos_da_categoria in CATEGORIAS:
        if termos_da_categoria.intersection(termos):
            return nome
    if TERMOS_CONFLITANTES.intersection(termos):
        return CONFLITANTE
    return SEM_CLASSIFICACAO


def contar(anotacoes: list[dict]) -> Counter:
    """Conta quantas variantes caem em cada categoria."""
    return Counter(classificar(extrair_termos_clinicos(a)) for a in anotacoes)


def mostrar_tabela(contagem: Counter, total: int) -> None:
    """Imprime a contagem na tela, com a porcentagem de cada categoria."""
    print(f"\n{'Classificação':<32}{'Variantes':>10}{'%':>8}")
    print("-" * 50)
    for categoria in ORDEM_DA_TABELA:
        quantidade = contagem.get(categoria, 0)
        porcentagem = 100 * quantidade / total if total else 0
        print(f"{categoria:<32}{quantidade:>10}{porcentagem:>7.1f}%")
    print("-" * 50)
    print(f"{'Total':<32}{total:>10}\n")


def salvar_csv(contagem: Counter, caminho: Path) -> None:
    """Salva a contagem em CSV (abre no Excel/LibreOffice)."""
    caminho.parent.mkdir(parents=True, exist_ok=True)
    with open(caminho, "w", newline="", encoding="utf-8") as arquivo:
        escritor = csv.writer(arquivo)
        escritor.writerow(["classificacao", "variantes"])
        for categoria in ORDEM_DA_TABELA:
            escritor.writerow([categoria, contagem.get(categoria, 0)])


def ler_argumentos() -> argparse.Namespace:
    """Define as opções de linha de comando do script."""
    parser = argparse.ArgumentParser(description="Conta variantes por classificação clínica.")
    parser.add_argument("--json", type=Path, required=True, help="Saída JSON do anotar_vep.py")
    parser.add_argument("--saida-csv", type=Path, required=True, help="Tabela de contagem")
    return parser.parse_args()


def main() -> int:
    """Lê a anotação, conta, mostra e salva o resultado."""
    argumentos = ler_argumentos()
    anotacoes = json.loads(argumentos.json.read_text(encoding="utf-8"))
    contagem = contar(anotacoes)
    mostrar_tabela(contagem, total=len(anotacoes))
    salvar_csv(contagem, argumentos.saida_csv)
    print(f"Contagem salva em {argumentos.saida_csv}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
