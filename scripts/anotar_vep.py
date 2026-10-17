#!/usr/bin/env python3
"""
Anota as variantes de um VCF usando a API REST do Ensembl VEP.

O VEP (Variant Effect Predictor) diz, para cada variante, em qual gene ela
cai, qual o efeito previsto (ex.: missense, stop_gained) e se ela já é
conhecida em bancos como o dbSNP e o ClinVar (significância clínica).

Aqui usamos o VEP pela internet (API), então não é preciso baixar o cache
de dezenas de GB do VEP. Em troca, é preciso estar conectado e a API aceita
no máximo 200 variantes por pedido.

Como usar:
    python scripts/anotar_vep.py --vcf resultados/03_variantes/amostra.normalizado.vcf.gz \\
        --saida-json resultados/04_anotacao/amostra.vep.json \\
        --saida-tsv resultados/04_anotacao/amostra.vep.tsv

Documentação da API: https://rest.ensembl.org/documentation/info/vep_region_post
"""

import argparse
import csv
import gzip
import json
import sys
import time
from pathlib import Path

import requests

# ---------------------------------------------------------------------------
# Configurações da API
# ---------------------------------------------------------------------------
SERVIDORES_VEP = {
    "GRCh37": "https://grch37.rest.ensembl.org",  # hg19
    "GRCh38": "https://rest.ensembl.org",          # hg38
}
ROTA_VEP = "/vep/homo_sapiens/region"
VARIANTES_POR_PEDIDO = 200   # limite da API do Ensembl
TENTATIVAS_MAXIMAS = 5       # quantas vezes tentar de novo se a API falhar
TEMPO_LIMITE_SEGUNDOS = 120  # tempo máximo de espera por resposta
PAUSA_ENTRE_PEDIDOS = 0.5    # respeita o limite de pedidos por segundo
CABECALHOS = {"Content-Type": "application/json", "Accept": "application/json"}

COLUNAS_TSV = [
    "cromossomo", "posicao", "ref", "alt", "gene",
    "consequencia", "impacto", "ids_conhecidos", "significancia_clinica",
]


def ler_variantes_do_vcf(caminho_vcf: Path) -> list[str]:
    """
    Lê o VCF (.vcf ou .vcf.gz) e devolve cada variante no formato que a API
    do VEP aceita: "CROMOSSOMO POSICAO ID REF ALT . . .".
    O prefixo "chr" é removido porque o Ensembl usa "6" e não "chr6".
    """
    abrir = gzip.open if caminho_vcf.suffix == ".gz" else open
    variantes = []
    with abrir(caminho_vcf, "rt", encoding="utf-8") as arquivo:
        for linha in arquivo:
            if linha.startswith("#"):
                continue  # linhas de cabeçalho
            cromossomo, posicao, ident, ref, alt = linha.split("\t")[:5]
            cromossomo = cromossomo.removeprefix("chr")
            variantes.append(f"{cromossomo} {posicao} {ident} {ref} {alt} . . .")
    return variantes


def dividir_em_lotes(itens: list[str], tamanho: int) -> list[list[str]]:
    """Divide a lista em pedaços de até `tamanho` itens (limite da API)."""
    return [itens[inicio:inicio + tamanho] for inicio in range(0, len(itens), tamanho)]


def consultar_vep(url: str, lote: list[str]) -> list[dict]:
    """
    Envia um lote de variantes para o VEP e devolve as anotações.
    Se a API pedir para esperar (erro 429) ou estiver instável (erro 5xx),
    espera e tenta de novo, aumentando o tempo a cada tentativa.
    """
    corpo = {"variants": lote}
    for tentativa in range(1, TENTATIVAS_MAXIMAS + 1):
        try:
            resposta = requests.post(url, headers=CABECALHOS, json=corpo,
                                     timeout=TEMPO_LIMITE_SEGUNDOS)
        except requests.RequestException as erro:
            espera = 2 ** tentativa
            print(f"  Falha de conexão ({erro}). Tentando de novo em {espera}s...")
            time.sleep(espera)
            continue

        if resposta.ok:
            return resposta.json()

        if resposta.status_code == 429 or resposta.status_code >= 500:
            espera = float(resposta.headers.get("Retry-After", 2 ** tentativa))
            print(f"  API ocupada (erro {resposta.status_code}). Esperando {espera:.0f}s...")
            time.sleep(espera)
            continue

        # Erros 4xx (exceto 429) indicam problema no pedido: não adianta repetir.
        resposta.raise_for_status()

    raise RuntimeError("A API do VEP não respondeu depois de várias tentativas. "
                       "Confira sua internet e rode o pipeline de novo.")


def extrair_termos_clinicos(anotacao: dict) -> list[str]:
    """
    Junta os termos de significância clínica (ClinVar) das variantes já
    conhecidas na mesma posição, mantendo só os que valem para o alelo
    alternativo desta variante. Ex.: ["pathogenic", "uncertain_significance"].

    O campo clin_sig_allele vem no formato "A:pathogenic;A:benign;G:benign".
    Termos compostos como "benign/likely_benign" são separados em dois.
    """
    alelo_alt = anotacao.get("allele_string", "/").split("/")[-1]
    termos = set()
    for conhecida in anotacao.get("colocated_variants", []):
        if "clin_sig_allele" in conhecida:
            for par in conhecida["clin_sig_allele"].split(";"):
                alelo, _, termo = par.partition(":")
                if alelo == alelo_alt:
                    termos.update(termo.split("/"))
        else:
            termos.update(conhecida.get("clin_sig", []))
    return sorted(termos)


def resumir_anotacao(anotacao: dict) -> dict:
    """Transforma a resposta do VEP em uma linha simples para a tabela TSV."""
    cromossomo, posicao, _, ref, alt = anotacao["input"].split()[:5]
    transcritos = anotacao.get("transcript_consequences", [])
    # O primeiro transcrito com o efeito mais grave representa a variante.
    mais_grave = anotacao.get("most_severe_consequence", "")
    principal = next(
        (t for t in transcritos if mais_grave in t.get("consequence_terms", [])),
        transcritos[0] if transcritos else {},
    )
    ids = [c["id"] for c in anotacao.get("colocated_variants", []) if "id" in c]
    return {
        "cromossomo": cromossomo,
        "posicao": posicao,
        "ref": ref,
        "alt": alt,
        "gene": principal.get("gene_symbol", ""),
        "consequencia": mais_grave,
        "impacto": principal.get("impact", ""),
        "ids_conhecidos": ",".join(ids),
        "significancia_clinica": ",".join(extrair_termos_clinicos(anotacao)),
    }


def salvar_json(anotacoes: list[dict], caminho: Path) -> None:
    """Salva a resposta completa do VEP (útil para explorar depois)."""
    caminho.parent.mkdir(parents=True, exist_ok=True)
    caminho.write_text(json.dumps(anotacoes, indent=2), encoding="utf-8")


def salvar_tsv(anotacoes: list[dict], caminho: Path) -> None:
    """Salva uma tabela resumida, que abre no Excel/LibreOffice."""
    caminho.parent.mkdir(parents=True, exist_ok=True)
    with open(caminho, "w", newline="", encoding="utf-8") as arquivo:
        escritor = csv.DictWriter(arquivo, fieldnames=COLUNAS_TSV, delimiter="\t")
        escritor.writeheader()
        escritor.writerows(resumir_anotacao(a) for a in anotacoes)


def ler_argumentos() -> argparse.Namespace:
    """Define as opções de linha de comando do script."""
    parser = argparse.ArgumentParser(description="Anota um VCF pela API do Ensembl VEP.")
    parser.add_argument("--vcf", type=Path, required=True, help="VCF de entrada (.vcf ou .vcf.gz)")
    parser.add_argument("--build", choices=SERVIDORES_VEP, default="GRCh37",
                        help="Versão do genoma (hg19 = GRCh37)")
    parser.add_argument("--saida-json", type=Path, required=True, help="Resposta completa do VEP")
    parser.add_argument("--saida-tsv", type=Path, required=True, help="Tabela resumida")
    return parser.parse_args()


def main() -> int:
    """Lê o VCF, consulta o VEP em lotes e salva os resultados."""
    argumentos = ler_argumentos()
    url = SERVIDORES_VEP[argumentos.build] + ROTA_VEP

    variantes = ler_variantes_do_vcf(argumentos.vcf)
    print(f"{len(variantes)} variantes encontradas no VCF.")

    anotacoes = []
    lotes = dividir_em_lotes(variantes, VARIANTES_POR_PEDIDO)
    for numero, lote in enumerate(lotes, start=1):
        print(f"Consultando o VEP: lote {numero}/{len(lotes)} ({len(lote)} variantes)")
        anotacoes.extend(consultar_vep(url, lote))
        time.sleep(PAUSA_ENTRE_PEDIDOS)

    salvar_json(anotacoes, argumentos.saida_json)
    salvar_tsv(anotacoes, argumentos.saida_tsv)
    print(f"Anotação salva em {argumentos.saida_json} e {argumentos.saida_tsv}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
