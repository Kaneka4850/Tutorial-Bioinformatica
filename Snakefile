# =============================================================================
# Pipeline de variantes: FASTQ -> BAM -> VCF -> anotação VEP -> contagem
# -----------------------------------------------------------------------------
# O Snakemake funciona como uma receita: cada "rule" diz qual arquivo ela
# produz (output), de quais arquivos precisa (input) e qual comando roda
# (shell). Ele descobre sozinho a ordem certa e pula etapas já prontas.
#
# Antes de rodar, prepare a referência:  bash scripts/preparar_referencia.sh
# Para rodar tudo:                       snakemake --cores 4
# Para só ver o que seria feito:         snakemake -n
# =============================================================================

import os

import yaml
from snakemake.exceptions import WorkflowError

configfile: "config/config.yaml"

# -----------------------------------------------------------------------------
# Recursos: lidos de config/recursos.yaml (gerado por verificar_recursos.py).
# Se o arquivo não existir, usamos valores pequenos e seguros.
# -----------------------------------------------------------------------------
ARQUIVO_RECURSOS = "config/recursos.yaml"
RECURSOS = {"threads": 2, "memoria_gb": 2}
if os.path.exists(ARQUIVO_RECURSOS):
    with open(ARQUIVO_RECURSOS, encoding="utf-8") as arquivo:
        RECURSOS.update(yaml.safe_load(arquivo) or {})

THREADS = int(RECURSOS["threads"])
MEMORIA_GB = int(RECURSOS["memoria_gb"])
# Opção do Java que limita a memória do GATK (evita travar o PC). Deixamos
# 25% de folga porque o Java usa um pouco além do limite -Xmx.
JAVA_OPCOES = f"-Xmx{max(1, int(MEMORIA_GB * 0.75))}g"

# -----------------------------------------------------------------------------
# Nomes dos arquivos, montados uma vez a partir do config.yaml.
# -----------------------------------------------------------------------------
AMOSTRA = config["amostra"]
R1 = config["fastq_r1"]
R2 = config["fastq_r2"]
REFERENCIA = config["referencia"]
RES = config["pasta_resultados"]

# Arquivos criados por scripts/preparar_referencia.sh.
INDICES_REFERENCIA = [
    REFERENCIA + ".bwt",
    REFERENCIA + ".fai",
    REFERENCIA.removesuffix(".fa") + ".dict",
]
faltando = [caminho for caminho in INDICES_REFERENCIA if not os.path.exists(caminho)]
if faltando:
    raise WorkflowError(
        "A referência ainda não foi preparada. Rode primeiro:\n"
        "    bash scripts/preparar_referencia.sh\n"
        f"Arquivos que faltam: {', '.join(faltando)}"
    )


def nome_relatorio_fastqc(caminho_fastq):
    """O FastQC nomeia o relatório como <nome_do_fastq>_fastqc.html."""
    base = os.path.basename(caminho_fastq).removesuffix(".gz").removesuffix(".fastq")
    return f"{RES}/01_qualidade/{base}_fastqc.html"


# -----------------------------------------------------------------------------
# Regra final: pedir a contagem faz o Snakemake rodar todas as etapas antes.
# -----------------------------------------------------------------------------
rule todas:
    input:
        nome_relatorio_fastqc(R1),
        nome_relatorio_fastqc(R2),
        f"{RES}/02_alinhamento/{AMOSTRA}.flagstat.txt",
        f"{RES}/02_alinhamento/{AMOSTRA}.cram",
        f"{RES}/03_variantes/{AMOSTRA}.stats.txt",
        f"{RES}/05_contagem/{AMOSTRA}.contagem.csv",


# Etapa 1: relatório de qualidade das leituras (abra o .html no navegador).
rule controle_qualidade:
    input:
        r1=R1,
        r2=R2,
    output:
        nome_relatorio_fastqc(R1),
        nome_relatorio_fastqc(R2),
    params:
        pasta=f"{RES}/01_qualidade",
    threads: min(2, THREADS)
    shell:
        "fastqc --threads {threads} --outdir {params.pasta} {input.r1} {input.r2}"


# Etapa 2: alinha as leituras paired-end na referência e ordena por posição.
# O "read group" (-R) identifica a amostra e é obrigatório para o GATK.
rule alinhar:
    input:
        r1=R1,
        r2=R2,
        indices=INDICES_REFERENCIA,
    output:
        bam=temp(f"{RES}/02_alinhamento/{AMOSTRA}.ordenado.bam"),
    params:
        referencia=REFERENCIA,
        read_group=rf"@RG\tID:{AMOSTRA}\tSM:{AMOSTRA}\tPL:ILLUMINA\tLB:lib1",
    threads: THREADS
    shell:
        "bwa mem -t {threads} -R '{params.read_group}' {params.referencia} {input.r1} {input.r2}"
        " | samtools sort -@ {threads} -o {output.bam} -"


# Etapa 3: marca leituras duplicadas de PCR (não são evidência independente).
rule marcar_duplicatas:
    input:
        bam=rules.alinhar.output.bam,
    output:
        bam=f"{RES}/02_alinhamento/{AMOSTRA}.bam",
        bai=f"{RES}/02_alinhamento/{AMOSTRA}.bam.bai",
        metricas=f"{RES}/02_alinhamento/{AMOSTRA}.duplicatas.txt",
    shell:
        "gatk --java-options '{JAVA_OPCOES}' MarkDuplicates"
        " -I {input.bam} -O {output.bam} -M {output.metricas}"
        " && samtools index {output.bam}"


# Estatísticas do alinhamento: quantas leituras alinharam, pares corretos etc.
rule estatisticas_alinhamento:
    input:
        bam=rules.marcar_duplicatas.output.bam,
    output:
        f"{RES}/02_alinhamento/{AMOSTRA}.flagstat.txt",
    shell:
        "samtools flagstat {input.bam} > {output}"


# Comparação didática: o mesmo alinhamento em CRAM. O CRAM guarda só as
# diferenças em relação à referência, por isso fica bem menor que o BAM, mas
# precisa da referência para ser lido. Compare: ls -lh resultados/02_alinhamento/
rule converter_cram:
    input:
        bam=rules.marcar_duplicatas.output.bam,
    output:
        cram=f"{RES}/02_alinhamento/{AMOSTRA}.cram",
        crai=f"{RES}/02_alinhamento/{AMOSTRA}.cram.crai",
    params:
        referencia=REFERENCIA,
    shell:
        "samtools view -C -T {params.referencia} -o {output.cram} {input.bam}"
        " && samtools index {output.cram}"


# Arquivo BED com as regiões onde há leituras alinhadas. O BED usa contagem
# a partir de 0 e o fim não entra no intervalo: "chr6 100 200" são as bases
# 101 a 200. Juntamos leituras a menos de 500 pb umas das outras em uma região.
rule gerar_bed:
    input:
        bam=rules.marcar_duplicatas.output.bam,
    output:
        bed=f"{RES}/02_alinhamento/{AMOSTRA}.regioes.bed",
    shell:
        "bedtools bamtobed -i {input.bam} | bedtools merge -d 500 -i - > {output.bed}"


# Etapa 4: chama variantes (SNVs e indels) com o GATK HaplotypeCaller.
# Com -L o GATK olha só as regiões do BED (mais 100 pb de margem), em vez do
# cromossomo 6 inteiro. É o mesmo que se faz com o BED de um painel ou exoma.
rule chamar_variantes:
    input:
        bam=rules.marcar_duplicatas.output.bam,
        bai=rules.marcar_duplicatas.output.bai,
        bed=rules.gerar_bed.output.bed,
    output:
        vcf=f"{RES}/03_variantes/{AMOSTRA}.vcf.gz",
    params:
        referencia=REFERENCIA,
    threads: THREADS
    shell:
        "gatk --java-options '{JAVA_OPCOES}' HaplotypeCaller"
        " -R {params.referencia} -I {input.bam} -O {output.vcf}"
        " -L {input.bed} --interval-padding 100"
        " --native-pair-hmm-threads {threads}"


# Etapa 5: normaliza as variantes (separa multialélicas e alinha indels à
# esquerda). Sem isso o VEP pode não reconhecer variantes já conhecidas.
rule normalizar_variantes:
    input:
        vcf=rules.chamar_variantes.output.vcf,
    output:
        vcf=f"{RES}/03_variantes/{AMOSTRA}.normalizado.vcf.gz",
    params:
        referencia=REFERENCIA,
    shell:
        "bcftools norm -m-any -f {params.referencia} -Oz -o {output.vcf} {input.vcf}"
        " && bcftools index -t {output.vcf}"


# Estatísticas do VCF: quantos SNVs e indels, razão Ti/Tv etc.
rule estatisticas_vcf:
    input:
        vcf=rules.normalizar_variantes.output.vcf,
    output:
        f"{RES}/03_variantes/{AMOSTRA}.stats.txt",
    shell:
        "bcftools stats {input.vcf} > {output}"


# Etapa 6: anota as variantes pela API do VEP (precisa de internet).
rule anotar_vep:
    input:
        vcf=rules.normalizar_variantes.output.vcf,
    output:
        json=f"{RES}/04_anotacao/{AMOSTRA}.vep.json",
        tsv=f"{RES}/04_anotacao/{AMOSTRA}.vep.tsv",
    params:
        build=config["build_genoma"],
    shell:
        "python scripts/anotar_vep.py --vcf {input.vcf} --build {params.build}"
        " --saida-json {output.json} --saida-tsv {output.tsv}"


# Etapa 7: conta variantes por classificação clínica (ClinVar).
rule contar_variantes:
    input:
        json=rules.anotar_vep.output.json,
    output:
        csv=f"{RES}/05_contagem/{AMOSTRA}.contagem.csv",
    shell:
        "python scripts/contar_variantes.py --json {input.json} --saida-csv {output.csv}"
