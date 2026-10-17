# Tutorial de Bioinformática: do zero ao pipeline de variantes

Este repositório é para quem **nunca usou programação**. Ao final você vai ter no
seu computador com Windows:

- Linux (Ubuntu 22.04) rodando dentro do Windows, pelo **WSL 2**
- **Git**, **Python 3.13**, **Docker** e **Miniconda**
- As principais ferramentas de bioinformática (**FastQC, BWA, SAMtools, GATK, VEP**)
- Editores de código (**VS Code**, **Antigravity IDE**) e assistentes de IA no terminal
  (**Claude Code**, **Antigravity CLI**, **OpenCode**)
- Um **pipeline completo** rodando em casa: FASTQ → BAM → VCF → anotação → contagem de
  variantes patogênicas, VUS e benignas

> **Regra de ouro:** você não precisa entender todos os comandos agora. Copie, cole, aperte
> **Enter** e espere terminar antes de colar o próximo. Se algo der errado, veja
> [Problemas comuns](#14-problemas-comuns).

---

## Sumário

0. [Antes de começar](#0-antes-de-começar)
1. [Instalar o WSL 2 com Ubuntu 22.04](#1-instalar-o-wsl-2-com-ubuntu-2204)
2. [Atualizar o Ubuntu](#2-atualizar-o-ubuntu)
3. [Git](#3-git)
4. [Python 3.13 e bibliotecas](#4-python-313-e-bibliotecas)
5. [Docker](#5-docker)
6. [Miniconda](#6-miniconda)
7. [Ferramentas de bioinformática](#7-ferramentas-de-bioinformática)
8. [Editores de código (IDEs)](#8-editores-de-código-ides)
9. [Assistentes de IA no terminal](#9-assistentes-de-ia-no-terminal)
10. [Baixar este repositório](#10-baixar-este-repositório)
11. [Verificar se o seu PC aguenta](#11-verificar-se-o-seu-pc-aguenta)
12. [Rodar o pipeline](#12-rodar-o-pipeline)
13. [Entendendo o pipeline e os resultados](#13-entendendo-o-pipeline-e-os-resultados)
14. [Problemas comuns](#14-problemas-comuns)

---

## 0. Antes de começar

### O que é cada coisa

| Nome | O que é, em uma frase |
|------|-----------------------|
| **Terminal** | Uma janela onde você digita comandos em vez de clicar em botões. |
| **PowerShell** | O terminal do Windows. |
| **WSL** | "Subsistema Windows para Linux": um Linux de verdade rodando dentro do Windows. A bioinformática quase toda roda em Linux. |
| **Ubuntu** | A versão (distribuição) de Linux que vamos usar. |
| **Comando** | Uma linha de texto que manda o computador fazer algo. |

### Requisitos mínimos

- Windows 10 (versão 2004 ou mais nova) ou Windows 11
- **8 GB de RAM** (16 GB é mais confortável)
- **20 GB livres** no disco
- Internet

### Como colar comandos

- **No PowerShell:** clique com o **botão direito** dentro da janela, ou use `Ctrl + V`.
- **No terminal do Ubuntu:** use `Ctrl + Shift + V` ou o **botão direito**.
- Quando o terminal pedir **senha**, nada aparece enquanto você digita (nem bolinhas). Isso é
  normal: digite e aperte **Enter**.
- Linhas que começam com `#` dentro dos blocos são **comentários** (explicações). Pode colar
  junto, o terminal ignora.

---

## 1. Instalar o WSL 2 com Ubuntu 22.04

1. Clique no menu **Iniciar**, digite **PowerShell**, clique com o botão direito em
   **Windows PowerShell** e escolha **Executar como administrador**.
2. Cole o comando abaixo e aperte Enter:

```powershell
wsl --install -d Ubuntu-22.04
```

3. Quando terminar, **reinicie o computador**.
4. Depois de reiniciar, a janela do Ubuntu abre sozinha (se não abrir, procure **Ubuntu 22.04**
   no menu Iniciar). Ela vai pedir:
   - **username:** um nome de usuário, só letras minúsculas e sem espaço (ex.: `maria`)
   - **password:** uma senha. **Anote**, você vai usar sempre que um comando tiver `sudo`.

5. Para confirmar que é o WSL **2**, abra o PowerShell de novo (não precisa ser administrador) e
   cole:

```powershell
wsl -l -v
```

Deve aparecer `Ubuntu-22.04` com `VERSION` igual a **2**. Se aparecer 1, cole:

```powershell
wsl --set-default-version 2
wsl --set-version Ubuntu-22.04 2
```

> **Daqui para frente, todos os comandos são no terminal do Ubuntu** (procure "Ubuntu 22.04" no
> menu Iniciar), a não ser quando estiver escrito PowerShell.

### Limitar a memória do WSL

Por padrão o WSL pode usar até metade da RAM do Windows. Isso costuma ser suficiente. Se quiser
mudar, abra o **Bloco de Notas**, cole o texto abaixo (troque `6GB` por cerca de 60–75% da sua
RAM, e `4` pelo número de processadores que quer liberar), e salve como
`C:\Users\SEU_USUARIO\.wslconfig` (escolha "Todos os arquivos" no tipo):

```ini
[wsl2]
memory=6GB
processors=4
```

Depois, no PowerShell, rode `wsl --shutdown` e abra o Ubuntu de novo.

---

## 2. Atualizar o Ubuntu

```bash
# Atualiza a lista de programas e instala as atualizações (pede a sua senha)
sudo apt update && sudo apt upgrade -y

# Programas básicos que vamos usar: downloads, compactação, compilação
sudo apt install -y curl wget unzip build-essential ca-certificates software-properties-common
```

---

## 3. Git

O [Git](https://git-scm.com/) guarda o histórico de versões do código e baixa repositórios do
[GitHub](https://github.com/), como este aqui.

```bash
sudo apt install -y git
git --version
```

Configure seu nome e e-mail (troque pelos seus, mantendo as aspas):

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu.email@exemplo.com"
```

---

## 4. Python 3.13 e bibliotecas

O Ubuntu 22.04 vem com Python 3.10. Vamos instalar o **Python 3.13** pelo repositório
[deadsnakes](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa), que é a forma mais comum de
ter versões novas do Python no Ubuntu.

```bash
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.13 python3.13-venv python3.13-dev
python3.13 --version
```

As bibliotecas ficam listadas no arquivo [`requirements.txt`](requirements.txt). Vamos instalá-las
num **ambiente virtual** (uma pasta isolada só para este projeto) depois de baixar o repositório,
no [passo 10](#10-baixar-este-repositório).

| Biblioteca | Para que serve |
|------------|----------------|
| [snakemake](https://snakemake.readthedocs.io/) | Organiza e executa as etapas do pipeline |
| [pandas](https://pandas.pydata.org/) | Trabalha com tabelas |
| [requests](https://requests.readthedocs.io/) | Faz chamadas para APIs na internet (o VEP) |
| [psutil](https://psutil.readthedocs.io/) | Lê RAM, CPU e disco do computador |
| [pyyaml](https://pyyaml.org/) | Lê arquivos de configuração `.yaml` |

---

## 5. Docker

O [Docker](https://www.docker.com/) roda programas dentro de "caixas" (containers) que já vêm com
tudo instalado. É o jeito mais seguro de rodar o pipeline: as mesmas versões em todos os
computadores, sem conflito, e com limite de memória para o PC não travar.

### 5.1 Ligar o systemd no WSL

O Docker precisa do `systemd` (o "gerenciador de serviços" do Linux). Cole:

```bash
echo -e "[boot]\nsystemd=true" | sudo tee /etc/wsl.conf
```

Agora, no **PowerShell**, desligue o WSL para a mudança valer:

```powershell
wsl --shutdown
```

Abra o Ubuntu de novo.

### 5.2 Instalar o Docker Engine

Comandos do [guia oficial do Docker para Ubuntu](https://docs.docker.com/engine/install/ubuntu/):

```bash
# Adiciona a chave de segurança do Docker
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Adiciona o repositório oficial do Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instala o Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Permite usar o Docker sem digitar sudo toda vez
sudo usermod -aG docker $USER
```

**Feche o terminal do Ubuntu e abra de novo** (para a permissão valer) e teste:

```bash
docker run hello-world
```

Se aparecer `Hello from Docker!`, deu certo.

> **Alternativa:** se você já usa o [Docker Desktop](https://www.docker.com/products/docker-desktop/)
> no Windows, não instale o Docker Engine acima. Abra o Docker Desktop → **Settings** →
> **Resources** → **WSL integration** → ative **Ubuntu-22.04** → **Apply & restart**.

---

## 6. Miniconda

O [Miniconda](https://www.anaconda.com/docs/getting-started/miniconda/main) é a versão
**pequena** do Anaconda: instala só o gerenciador `conda`, e você escolhe o que mais quer. Com o
canal [Bioconda](https://bioconda.github.io/) ele instala milhares de ferramentas de
bioinformática com um comando.

```bash
# Baixa o instalador
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh

# Instala em ~/miniconda3 sem fazer perguntas (-b) e apaga o instalador
bash ~/miniconda.sh -b -p ~/miniconda3
rm ~/miniconda.sh

# Faz o conda abrir junto com o terminal
~/miniconda3/bin/conda init bash
```

**Feche e abra o terminal.** Aparece `(base)` no começo da linha. Agora configure os canais:

```bash
# Aceita os termos de uso dos canais padrão da Anaconda (exigido nas versões novas)
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Canais de bioinformática (a ordem importa)
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict

# Não ativar o (base) sozinho, para não misturar com o Python 3.13 do sistema
conda config --set auto_activate_base false
```

---

## 7. Ferramentas de bioinformática

| Ferramenta | Para que serve | Saiba mais |
|------------|----------------|------------|
| **FastQC** | Relatório de qualidade das leituras (FASTQ) | [Site](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) · [GitHub](https://github.com/s-andrews/FastQC) |
| **BWA** | Alinha as leituras no genoma de referência | [GitHub](https://github.com/lh3/bwa) · [Manual](https://bio-bwa.sourceforge.net/bwa.shtml) |
| **SAMtools / BCFtools** | Manipulam arquivos BAM (alinhamentos) e VCF (variantes) | [Site](https://www.htslib.org/) · [GitHub](https://github.com/samtools/samtools) |
| **GATK** | Marca duplicatas e chama variantes (HaplotypeCaller) | [Site](https://gatk.broadinstitute.org/) · [GitHub](https://github.com/broadinstitute/gatk) |
| **VEP** | Anota o efeito das variantes (gene, consequência, ClinVar) | [Site](https://www.ensembl.org/info/docs/tools/vep/index.html) · [GitHub](https://github.com/Ensembl/ensembl-vep) · [API REST](https://grch37.rest.ensembl.org/documentation/info/vep_region_post) |
| **Snakemake** | Liga todas as etapas em um pipeline | [Site](https://snakemake.readthedocs.io/) · [GitHub](https://github.com/snakemake/snakemake) |

Você tem **duas formas** de ter essas ferramentas. Escolha uma (ou as duas):

**Forma A, Docker (recomendada):** não precisa instalar nada agora. O script do
[passo 12](#12-rodar-o-pipeline) monta uma imagem Docker com todas elas.

**Forma B, conda:** cria um ambiente chamado `bioinfo` com tudo (rode depois do
[passo 10](#10-baixar-este-repositório), dentro da pasta do repositório):

```bash
conda env create -f environment.yml
conda activate bioinfo
fastqc --version && bwa 2>&1 | grep Version && samtools --version | head -1 && gatk --version
```

> **E o VEP?** O VEP completo instalado no PC precisa de um "cache" de mais de 20 GB. Neste
> tutorial usamos o VEP **pela internet** (API REST do Ensembl), então não é preciso baixar nada.
> Para instalar localmente no futuro, veja o
> [guia de instalação do VEP](https://www.ensembl.org/info/docs/tools/vep/script/vep_download.html)
> ou use a imagem Docker oficial `ensemblorg/ensembl-vep`.

---

## 8. Editores de código (IDEs)

Os editores são instalados **no Windows** e se conectam ao Ubuntu do WSL. Cole no **PowerShell**
(não precisa ser administrador):

### VS Code

```powershell
winget install -e --id Microsoft.VisualStudioCode
```

Depois, abra o VS Code, vá em **Extensões** (`Ctrl + Shift + X`), procure e instale **WSL**
(da Microsoft). Dentro do terminal do Ubuntu, na pasta de um projeto, abra o editor com:

```bash
code .
```

Site: <https://code.visualstudio.com/>

### Google Antigravity IDE

Editor do Google com agentes de IA embutidos.

```powershell
winget install -e --id Google.AntigravityIDE
```

Site: <https://antigravity.google/>. Para abrir pastas do Ubuntu, use a opção de conexão remota
com o WSL dentro do editor.

---

## 9. Assistentes de IA no terminal

Instale **dentro do Ubuntu**. Você não precisa de todos, escolha o que preferir. Cada um pede
login na primeira vez que você abrir.

### Claude Code (Anthropic)

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Feche e abra o terminal, depois rode `claude` dentro da pasta do projeto. Precisa de uma conta
paga (Pro, Max, Team) ou de uma chave de API. [Documentação](https://code.claude.com/docs/pt/overview).

### Google Antigravity CLI

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

Feche e abra o terminal, depois rode `agy`. [GitHub](https://github.com/google-antigravity/antigravity-cli).

### OpenCode

Assistente de código aberto que funciona com vários modelos de IA.

```bash
curl -fsSL https://opencode.ai/install | bash
```

Feche e abra o terminal, depois rode `opencode`. [Site](https://opencode.ai/) ·
[GitHub](https://github.com/anomalyco/opencode).

> Se aparecer `command not found` depois de instalar, feche e abra o terminal. Se continuar,
> rode `source ~/.bashrc`.

---

## 10. Baixar este repositório

Sempre trabalhe **dentro da pasta do Ubuntu** (`~`), não em `/mnt/c/...`: o acesso aos arquivos
do Windows pelo WSL é bem mais lento.

```bash
cd ~
git clone https://github.com/Kaneka4850/Tutorial-Bioinformatica.git
cd Tutorial-Bioinformatica
```

Crie o ambiente virtual do Python 3.13 e instale as bibliotecas:

```bash
# Cria a pasta .venv com um Python só deste projeto
python3.13 -m venv .venv

# Ativa o ambiente (aparece (.venv) no começo da linha)
source .venv/bin/activate

# Instala as bibliotecas do requirements.txt
pip install --upgrade pip
pip install -r requirements.txt
```

> Toda vez que abrir um terminal novo para trabalhar no projeto, rode
> `cd ~/Tutorial-Bioinformatica && source .venv/bin/activate`.

### O que tem no repositório

```
Tutorial-Bioinformatica/
├── README.md                     # este tutorial
├── Snakefile                     # o pipeline (etapas e comandos)
├── Dockerfile                    # receita da imagem Docker com as ferramentas
├── environment.yml               # mesmas ferramentas, para o conda
├── requirements.txt              # bibliotecas Python
├── config/config.yaml            # caminhos dos arquivos e nome da amostra
├── dados/
│   ├── amostra_R1.fastq          # leituras paired-end (ida)
│   ├── amostra_R2.fastq          # leituras paired-end (volta)
│   └── referencia/chr6.fa.gz     # cromossomo 6 do genoma humano hg19
└── scripts/
    ├── verificar_recursos.py     # mede RAM/CPU/disco do seu PC
    ├── preparar_referencia.sh    # indexa a referência (bash)
    ├── anotar_vep.py             # anota as variantes pela API do VEP
    ├── contar_variantes.py       # conta patogênicas, VUS, benignas...
    └── rodar_pipeline.sh         # roda tudo com um comando (Docker)
```

---

## 11. Verificar se o seu PC aguenta

```bash
python3 scripts/verificar_recursos.py
```

O script mostra núcleos, threads, RAM e disco, e decide quantas threads e quanta memória o
pipeline vai usar, sempre deixando folga para o Windows. A decisão fica salva em
`config/recursos.yaml`. Se aparecer **ATENÇÃO**, leia o aviso (geralmente é só fechar o
navegador antes de rodar).

> **Núcleos x threads:** um *núcleo* (core) é uma unidade física de processamento. Muitos
> processadores rodam 2 *threads* por núcleo, ou seja, 2 tarefas ao mesmo tempo. O pipeline usa
> todas as threads **menos 2**, e no máximo metade da RAM livre.

---

## 12. Rodar o pipeline

### Forma A: com Docker (recomendada)

Um comando só. Na primeira vez demora mais (baixa e monta a imagem, cerca de 1 GB, e indexa a
referência, de 5 a 15 minutos). Nas próximas vezes é rápido.

```bash
bash scripts/rodar_pipeline.sh
```

O script:

1. Confere se o Docker está ligado
2. Roda o `verificar_recursos.py`
3. Constrói a imagem Docker `tutorial-bioinfo`
4. Prepara a referência com `scripts/preparar_referencia.sh`
5. Roda o Snakemake **dentro do Docker, com limite de CPU e memória**, para o PC não travar

### Forma B: com conda

```bash
conda activate bioinfo
python scripts/verificar_recursos.py
bash scripts/preparar_referencia.sh
snakemake --cores $(grep threads config/recursos.yaml | awk '{print $2}') --printshellcmds
```

### Comandos úteis do Snakemake

```bash
snakemake -n                        # só mostra o que seria feito, sem rodar (dry-run)
snakemake --cores 2 --forceall      # refaz tudo do zero
snakemake --dag | dot -Tpng > dag.png   # desenha o pipeline (precisa: sudo apt install graphviz)
```

Para rodar com **outras amostras**, troque os caminhos em [`config/config.yaml`](config/config.yaml).

---

## 13. Entendendo o pipeline e os resultados

```
 amostra_R1.fastq ─┐
                   ├─► FastQC ──────────────────────► relatório de qualidade (.html)
 amostra_R2.fastq ─┤
                   └─► BWA-MEM + samtools sort ─► GATK MarkDuplicates ─► BAM
                                                                         │
 chr6.fa.gz ─► preparar_referencia.sh                                    ▼
              (bwa index, samtools faidx,                     GATK HaplotypeCaller ─► VCF
               gatk CreateSequenceDictionary)                            │
                                                                         ▼
                                                     bcftools norm (normalização)
                                                                         │
                                                                         ▼
                                                     API do VEP ─► anotação (.json / .tsv)
                                                                         │
                                                                         ▼
                                                     contagem por classificação (.csv)
```

| Etapa | Ferramenta | O que acontece | Resultado |
|-------|------------|----------------|-----------|
| Preparar referência | bwa, samtools, gatk | Cria índices para achar posições no genoma rapidamente | `dados/referencia/chr6.fa.*` |
| 1. Qualidade | FastQC | Avalia a qualidade de cada base sequenciada | `resultados/01_qualidade/*.html` |
| 2. Alinhamento | BWA-MEM + samtools | Encontra de onde no cromossomo 6 veio cada par de leituras | `resultados/02_alinhamento/amostra.bam` |
| 3. Duplicatas | GATK MarkDuplicates | Marca cópias de PCR, que não são evidência nova | `amostra.duplicatas.txt` |
| 4. Chamada de variantes | GATK HaplotypeCaller | Encontra as posições diferentes da referência | `resultados/03_variantes/amostra.vcf.gz` |
| 5. Normalização | bcftools norm | Padroniza a escrita das variantes para o VEP reconhecê-las | `amostra.normalizado.vcf.gz` |
| 6. Anotação | VEP (API) | Gene, efeito, rsID e significância clínica (ClinVar) | `resultados/04_anotacao/amostra.vep.tsv` |
| 7. Contagem | Python | Conta patogênicas, provavelmente patogênicas, VUS, provavelmente benignas e benignas | `resultados/05_contagem/amostra.contagem.csv` |

### Formatos de arquivo

- **FASTA (`.fa`)**: a sequência do genoma de referência.
- **FASTQ (`.fastq`)**: as leituras do sequenciador, com a qualidade de cada base.
- **BAM (`.bam`)**: as leituras alinhadas no genoma (versão compactada do SAM).
- **VCF (`.vcf.gz`)**: a lista de variantes encontradas.

### Como a contagem decide a classificação

O VEP traz a classificação do [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/) para variantes já
conhecidas. Quando a mesma variante tem mais de uma classificação (laboratórios diferentes podem
discordar), o script usa a **mais grave**: patogênica > provavelmente patogênica > VUS >
provavelmente benigna > benigna. Variantes sem nenhuma dessas classificações entram como
**sem classificação**. É uma simplificação para estudo: na rotina clínica também se avaliam o
nível de revisão do ClinVar (estrelas) e os critérios ACMG.

### Olhando os resultados

```bash
cat resultados/05_contagem/amostra.contagem.csv
cat resultados/02_alinhamento/amostra.flagstat.txt
zcat resultados/03_variantes/amostra.normalizado.vcf.gz | grep -v "^##" | head
column -t -s $'\t' resultados/04_anotacao/amostra.vep.tsv | less -S   # q para sair
explorer.exe resultados/01_qualidade   # abre a pasta no Windows para ver o relatório do FastQC
```

---

## 14. Problemas comuns

| Problema | Solução |
|----------|---------|
| `WslRegisterDistribution failed` ou erro de virtualização | Ative a virtualização (Intel VT-x / AMD-V / SVM) na BIOS do computador e rode `wsl --install -d Ubuntu-22.04` de novo. |
| `permission denied ... docker.sock` | Rode `sudo usermod -aG docker $USER`, feche e abra o terminal. |
| `Cannot connect to the Docker daemon` | Rode `sudo service docker start`. Se não resolver, confira o passo 5.1 (systemd). |
| `python3.13: command not found` | Refaça o passo 4 (repositório deadsnakes). |
| `conda: command not found` | Rode `~/miniconda3/bin/conda init bash`, feche e abra o terminal. |
| PC muito lento ou travando | Feche o navegador e outros programas, rode `python3 scripts/verificar_recursos.py` de novo e veja [Limitar a memória do WSL](#limitar-a-memória-do-wsl). |
| `A referência ainda não foi preparada` | Rode `bash scripts/preparar_referencia.sh` (Forma B) ou use a Forma A. |
| Erro 429 / falha de conexão no VEP | A API está ocupada. O script já tenta de novo sozinho; se falhar, espere alguns minutos e rode o pipeline de novo (ele continua de onde parou). |
| `bash\r: No such file or directory` | O arquivo ganhou fim de linha do Windows. Rode `sudo apt install -y dos2unix && dos2unix scripts/*.sh`. |
| Snakemake diz `LockException` | Uma execução anterior foi interrompida. Rode `snakemake --unlock` (Forma B) ou apague a pasta `.snakemake/locks`. |

---

## Sobre os dados

- `dados/amostra_R1.fastq` e `dados/amostra_R2.fastq`: 2.629 pares de leituras de 150 pb
  (Illumina NextSeq) de uma região do cromossomo 6. Arquivos pequenos de propósito, para rodar em
  qualquer PC.
- `dados/referencia/chr6.fa.gz`: cromossomo 6 do genoma humano **hg19 (GRCh37)**.
