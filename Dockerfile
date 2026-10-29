# =============================================================================
# Imagem Docker do pipeline
# -----------------------------------------------------------------------------
# Uma "imagem" é como uma caixa fechada com todos os programas já instalados
# (FastQC, BWA, SAMtools, BCFtools, GATK, Snakemake e Python). Assim o
# pipeline roda igual em qualquer computador, sem conflito de versões.
#
# Construir:  docker build -t tutorial-bioinfo .
# (o script scripts/rodar_pipeline.sh já faz isso por você)
#
# A imagem base existe para processadores Intel/AMD (amd64) e ARM (arm64,
# Macs com chip Apple). Para forçar Intel num Mac Apple, use:
#   docker build --platform linux/amd64 -t tutorial-bioinfo .
# =============================================================================

# micromamba é uma versão leve do conda, feita para usar dentro do Docker.
FROM mambaorg/micromamba:2.0.5

# Reaproveita a mesma lista de programas do ambiente conda (environment.yml),
# então Docker e conda sempre usam as mesmas ferramentas.
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/environment.yml

# Instala tudo no ambiente "base" da imagem e apaga o cache para a imagem
# ficar menor.
RUN micromamba install -y -n base -f /tmp/environment.yml && \
    micromamba clean --all --yes

# Garante que os programas do ambiente fiquem disponíveis em qualquer comando.
ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENV PATH=/opt/conda/bin:$PATH

# Pasta de trabalho: o repositório do seu computador é "montado" aqui.
WORKDIR /pipeline
