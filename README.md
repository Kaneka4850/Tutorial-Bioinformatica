# Tutorial de Bioinformática: do zero ao pipeline de variantes

Este repositório é para quem **nunca usou programação**. Ao final você vai ter no seu computador
(Windows 10, Windows 11 ou macOS):

- Um ambiente Linux para trabalhar: **Ubuntu 22.04 dentro do Windows** (pelo **WSL 2**) ou o
  próprio terminal do **macOS**
- **Git**, **Python 3.13**, **Docker** e **Miniconda**
- As principais ferramentas de bioinformática (**FastQC, BWA, SAMtools, BCFtools, bedtools,
  GATK, VEP**)
- Editores de código (**VS Code**, **Antigravity IDE**) e assistentes de IA no terminal
  (**Claude Code**, **Antigravity CLI**, **OpenCode**)
- Um **pipeline completo** rodando em casa: FASTQ → BAM/CRAM → BED → VCF → anotação →
  contagem de variantes patogênicas, VUS e benignas
- E, principalmente, a **explicação de cada arquivo e de cada etapa** (Parte II)

> **Regra de ouro:** você não precisa entender todos os comandos agora. Copie, cole, aperte
> **Enter** e espere terminar antes de colar o próximo. Se algo der errado, veja
> [Problemas comuns](#17-problemas-comuns).

---

## Sumário

**Parte I: Instalação**

0. [Antes de começar](#0-antes-de-começar)
1. [Instalação automática (recomendada)](#1-instalação-automática-recomendada)
2. [Instalação manual no Windows (WSL 2 + Ubuntu 22.04)](#2-instalação-manual-no-windows-wsl-2--ubuntu-2204)
3. [Instalação manual no macOS](#3-instalação-manual-no-macos)
4. [Dentro do Ubuntu ou do macOS: Git, Python, Miniconda e ferramentas](#4-dentro-do-ubuntu-ou-do-macos-git-python-miniconda-e-ferramentas)
5. [Editores de código (IDEs)](#5-editores-de-código-ides)
6. [Assistentes de IA no terminal](#6-assistentes-de-ia-no-terminal)
7. [Baixar este repositório](#7-baixar-este-repositório)

**Parte II: Entendendo um pipeline de bioinformática**

8. [O que é um pipeline de variantes](#8-o-que-é-um-pipeline-de-variantes)
9. [FASTQ e métricas de qualidade](#9-fastq-e-métricas-de-qualidade)
10. [Genoma de referência e alinhamento](#10-genoma-de-referência-e-alinhamento)
11. [SAM, BAM e CRAM](#11-sam-bam-e-cram)
12. [BED: regiões do genoma](#12-bed-regiões-do-genoma)
13. [Chamada de variantes e o arquivo VCF](#13-chamada-de-variantes-e-o-arquivo-vcf)
14. [Anotação e classificação clínica (ACMG/ClinGen e AMP/VICC)](#14-anotação-e-classificação-clínica-acmgclingen-e-ampvicc)
15. [Outros métodos que você vai ouvir falar](#15-outros-métodos-que-você-vai-ouvir-falar)

**Parte III: Rodar e interpretar**

16. [Rodar o pipeline](#16-rodar-o-pipeline)
17. [Problemas comuns](#17-problemas-comuns)
18. [Segurança e privacidade](#18-segurança-e-privacidade)

---

# Parte I: Instalação

## 0. Antes de começar

### O que é cada coisa

| Nome | O que é, em uma frase |
|------|-----------------------|
| **Terminal** | Uma janela onde você digita comandos em vez de clicar em botões. |
| **PowerShell** | O terminal do Windows. |
| **WSL** | "Subsistema Windows para Linux": um Linux de verdade rodando dentro do Windows. A bioinformática quase toda roda em Linux. |
| **Ubuntu** | A versão (distribuição) de Linux que vamos usar. |
| **Terminal do macOS** | O macOS já é parecido com Linux por dentro (os dois vêm do Unix), então não precisa de WSL. |
| **Comando** | Uma linha de texto que manda o computador fazer algo. |
| **Docker** | Roda programas dentro de "caixas" (containers) que já vêm com tudo instalado. |
| **Conda** | Instala programas científicos em "ambientes" separados, sem bagunçar o computador. |

### Requisitos mínimos

- **Windows 10** versão 2004 ou mais nova (a 1903/1909 também serve, com
  [instalação manual](#22-windows-10-versão-1903-ou-1909-instalação-manual)), ou **Windows 11**
- ou **macOS 12 (Monterey)** ou mais novo, em Mac Intel ou Apple (M1, M2, M3, M4)
- **8 GB de RAM** (16 GB é mais confortável)
- **20 GB livres** no disco
- Internet

**Como descobrir sua versão do Windows:** aperte `Windows + R`, digite `winver` e aperte Enter.
Aparece algo como "Versão 22H2 (Compilação do SO 19045)". O número da **compilação** (build)
é o que importa: 19041 ou maior é Windows 10 versão 2004 ou mais novo.

**Como descobrir sua versão do macOS:** menu  (maçã) > **Sobre Este Mac**. Ali também aparece
o **Chip** (Apple M1, M2...) ou o **Processador** (Intel).

### Como colar comandos

- **No PowerShell:** clique com o **botão direito** dentro da janela, ou use `Ctrl + V`.
- **No terminal do Ubuntu:** use `Ctrl + Shift + V` ou o **botão direito**.
- **No Terminal do macOS:** use `Cmd + V`.
- Quando o terminal pedir **senha**, nada aparece enquanto você digita (nem bolinhas). Isso é
  normal: digite e aperte **Enter**.
- Linhas que começam com `#` dentro dos blocos são **comentários** (explicações). Pode colar
  junto, o terminal ignora.

---

## 1. Instalação automática (recomendada)

Preparamos dois instaladores que fazem **todos** os passos das seções 2 a 4 sozinhos. Eles podem
ser rodados várias vezes sem problema: o que já estiver instalado é pulado e nada é apagado.

| Arquivo | Onde roda | O que instala |
|---------|-----------|---------------|
| [`instalacao/instalar.ps1`](instalacao/instalar.ps1) | PowerShell do Windows | WSL 2, Ubuntu 22.04, Docker Desktop, VS Code, e chama o `instalar.sh` dentro do Ubuntu |
| [`instalacao/instalar.sh`](instalacao/instalar.sh) | Ubuntu (WSL) ou macOS | Git, Python 3.13, Docker, Miniconda, ambiente `.venv` (Python) e ambiente conda `bioinfo` (ferramentas) |
| [`instalacao/verificar.sh`](instalacao/verificar.sh) | Ubuntu (WSL) ou macOS | Não instala nada: mostra o que está instalado e o que falta |

> **Antes de rodar qualquer script baixado da internet, dê uma olhada nele.** Estes são arquivos
> de texto comentados em português: abra no Bloco de Notas ou no VS Code e leia o que cada parte
> faz. Veja também [Segurança e privacidade](#18-segurança-e-privacidade).

### 1.1 No Windows 10 ou 11

1. Baixe este repositório: no GitHub, clique em **Code** > **Download ZIP** e extraia em
   `Downloads` (fica `Downloads\Tutorial-Bioinformatica`). Se a pasta extraída se chamar
   `Tutorial-Bioinformatica-main`, tudo bem, use esse nome nos comandos abaixo.
2. Abra o **PowerShell como administrador**: menu **Iniciar** > digite **PowerShell** > botão
   direito em **Windows PowerShell** > **Executar como administrador**.
3. Cole, uma linha de cada vez:

```powershell
# Entra na pasta do repositório
cd $HOME\Downloads\Tutorial-Bioinformatica

# Permite rodar scripts SÓ nesta janela (quando fechar, volta ao normal)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# (opcional) mostra o que seria feito, sem instalar nada
.\instalacao\instalar.ps1 -SoMostrar

# Instala de verdade
.\instalacao\instalar.ps1
```

4. **Na primeira vez**, o script instala o WSL e o Ubuntu e pede para você:
   - **reiniciar o computador**;
   - abrir **Ubuntu 22.04** no menu Iniciar e criar um **usuário** (só letras minúsculas, sem
     espaço, ex.: `maria`) e uma **senha** (**anote**, você vai usar sempre que um comando tiver
     `sudo`);
   - abrir o PowerShell como administrador de novo e repetir o passo 3.
5. Na segunda vez ele deixa o Ubuntu-22.04 como distribuição padrão do WSL, instala o Docker
   Desktop e o VS Code, copia o repositório para dentro do Ubuntu (`~/Tutorial-Bioinformatica`)
   e roda lá o `instalar.sh`, que pede a **senha do Ubuntu**. Essa parte demora de 10 a 30
   minutos, dependendo da internet. Se a pasta `~/Tutorial-Bioinformatica` já existir no Ubuntu,
   ela é usada como está: o instalador nunca sobrescreve seus arquivos.
6. Abra o **Docker Desktop** pelo menu Iniciar, aceite os termos e espere o ícone ficar verde.

Opções: `-SemDocker` (não instala o Docker Desktop) e `-SemVSCode` (não instala o VS Code).

### 1.2 No macOS

1. Abra o **Terminal** (aperte `Cmd + Espaço`, digite **Terminal** e Enter).
2. Baixe o repositório e rode o instalador:

```bash
cd ~
git clone https://github.com/Kaneka4850/Tutorial-Bioinformatica.git
cd Tutorial-Bioinformatica
bash instalacao/instalar.sh
```

> Se o macOS disser que o `git` precisa das **Ferramentas de Linha de Comando**, clique em
> **Instalar**, espere terminar e rode o `git clone` de novo.

O script instala o [Homebrew](https://brew.sh/pt-br/) (o "loja de programas" do terminal do
macOS), o Python 3.13, o Docker Desktop e o Miniconda. Ele pede a **senha do seu Mac**.

### 1.3 Conferindo

No **terminal do Ubuntu** (Windows) ou no **Terminal** (macOS):

```bash
cd ~/Tutorial-Bioinformatica
bash instalacao/verificar.sh
```

Tudo com `[ OK ]`? Pule para [Rodar o pipeline](#16-rodar-o-pipeline). Se aparecer `[FALTA]`, a
linha diz o que fazer. As seções 2 a 4 explicam cada passo, caso você prefira instalar à mão ou
queira entender o que o instalador fez.

---

## 2. Instalação manual no Windows (WSL 2 + Ubuntu 22.04)

### 2.1 Windows 11 e Windows 10 versão 2004 ou mais nova

1. Abra o **PowerShell como administrador** (menu Iniciar > PowerShell > botão direito >
   **Executar como administrador**).
2. Cole e aperte Enter:

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

### 2.2 Windows 10 versão 1903 ou 1909 (instalação manual)

O comando `wsl --install` não existe nessas versões. Siga os passos do
[guia oficial da Microsoft](https://learn.microsoft.com/pt-br/windows/wsl/install-manual).
Se puder, prefira **atualizar o Windows** (Configurações > Atualização e Segurança > Windows
Update): é mais simples e mais seguro.

1. Confira a compilação com `winver`: precisa ser **18362.1049** ou maior (ou 18363.1049).
2. No **PowerShell como administrador**, ligue o WSL e a "Plataforma de Máquina Virtual":

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

3. **Reinicie o computador.**
4. Baixe e instale o
   [pacote de atualização do kernel do WSL 2 (x64)](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)
   (clique duas vezes no arquivo baixado).
5. No PowerShell, deixe o WSL 2 como padrão:

```powershell
wsl --set-default-version 2
```

6. Instale o [Ubuntu 22.04 pela Microsoft Store](https://apps.microsoft.com/detail/9PN20MSR04DW),
   abra e crie usuário e senha como no passo 2.1.

### 2.3 Limitar a memória do WSL

Por padrão o WSL pode usar até metade da RAM do Windows. Isso costuma ser suficiente. Se quiser
mudar, abra o **Bloco de Notas**, cole o texto abaixo (troque `6GB` por cerca de 60 a 75% da sua
RAM, e `4` pelo número de processadores que quer liberar), e salve como
`C:\Users\SEU_USUARIO\.wslconfig` (escolha "Todos os arquivos" no tipo):

```ini
[wsl2]
memory=6GB
processors=4
```

Depois, no PowerShell, rode `wsl --shutdown` e abra o Ubuntu de novo.

### 2.4 Docker no Windows

O [Docker](https://www.docker.com/) roda programas dentro de "caixas" (containers) que já vêm
com tudo instalado. É o jeito mais seguro de rodar o pipeline: as mesmas versões em todos os
computadores, sem conflito, e com limite de memória para o PC não travar.

**Forma recomendada: Docker Desktop.** No PowerShell (não precisa ser administrador):

```powershell
winget install -e --id Docker.DockerDesktop
```

Abra o **Docker Desktop**, aceite os termos, e vá em **Settings** > **Resources** >
**WSL integration** > ative **Ubuntu-22.04** > **Apply & restart**. Teste no terminal do Ubuntu:

```bash
docker run --rm hello-world
```

Se aparecer `Hello from Docker!`, deu certo.

<details>
<summary><b>Alternativa: Docker Engine instalado dentro do Ubuntu</b> (sem Docker Desktop)</summary>

O Docker Engine precisa do `systemd` (o "gerenciador de serviços" do Linux). Este comando
**acrescenta** a configuração ao `/etc/wsl.conf` sem apagar o que já existe:

```bash
grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null || printf '\n[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf
```

No **PowerShell**, desligue o WSL para a mudança valer e abra o Ubuntu de novo:

```powershell
wsl --shutdown
```

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

**Feche o terminal do Ubuntu e abra de novo** (para a permissão valer) e teste com
`docker run --rm hello-world`. O `instalar.sh` faz tudo isso se você usar
`bash instalacao/instalar.sh --docker-engine`.

</details>

> **Daqui para frente, no Windows, todos os comandos são no terminal do Ubuntu** (procure
> "Ubuntu 22.04" no menu Iniciar), a não ser quando estiver escrito PowerShell. Continue na
> [seção 4](#4-dentro-do-ubuntu-ou-do-macos-git-python-miniconda-e-ferramentas).

---

## 3. Instalação manual no macOS

No macOS não existe WSL: o próprio **Terminal** já funciona como um terminal Linux para o que
vamos fazer. Abra o Terminal com `Cmd + Espaço` > **Terminal**.

### 3.1 Ferramentas de Linha de Comando da Apple

Instalam o `git`, o compilador e outros básicos. Abre uma janela: clique em **Instalar**.

```bash
xcode-select --install
```

### 3.2 Homebrew

O [Homebrew](https://brew.sh/pt-br/) é o gerenciador de programas do terminal do macOS (como o
`apt` do Ubuntu). O comando abaixo é o **instalador oficial** do site brew.sh. Ele pede sua
senha e um **Enter** para confirmar:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

No fim, o instalador mostra **"Next steps"** com dois comandos para colocar o `brew` no seu
terminal. **Copie e rode esses dois comandos.** Em Macs Apple eles são:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 3.3 Python 3.13 e Git

```bash
brew install git python@3.13
python3.13 --version
```

### 3.4 Docker Desktop

```bash
brew install --cask docker-desktop
```

Abra o **Docker** em Aplicativos, aceite os termos e espere o ícone da baleia ficar parado no
topo da tela. Teste com `docker run --rm hello-world`. Também dá para baixar pelo
[site oficial](https://docs.docker.com/desktop/setup/install/mac-install/) (escolha **Apple
Silicon** ou **Intel**).

> **Mac Apple (M1, M2, M3, M4):** a imagem do tutorial é construída nativamente para ARM. Se
> algum dia a construção falhar por falta de pacote para ARM, rode emulando Intel:
> `PLATAFORMA_DOCKER=linux/amd64 bash scripts/rodar_pipeline.sh`.

Continue na [seção 4](#4-dentro-do-ubuntu-ou-do-macos-git-python-miniconda-e-ferramentas)
(pule os comandos marcados como "só Ubuntu").

---

## 4. Dentro do Ubuntu ou do macOS: Git, Python, Miniconda e ferramentas

### 4.1 Atualizar o Ubuntu (só Ubuntu)

```bash
# Atualiza a lista de programas e instala as atualizações (pede a sua senha)
sudo apt update && sudo apt upgrade -y

# Programas básicos que vamos usar: downloads, compactação, compilação
sudo apt install -y curl wget unzip build-essential ca-certificates software-properties-common
```

### 4.2 Git

O [Git](https://git-scm.com/) guarda o histórico de versões do código e baixa repositórios do
[GitHub](https://github.com/), como este aqui.

```bash
sudo apt install -y git     # só Ubuntu (no macOS já veio no passo 3)
git --version
```

Configure seu nome e e-mail (troque pelos seus, mantendo as aspas):

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu.email@exemplo.com"
```

### 4.3 Python 3.13 (só Ubuntu)

O Ubuntu 22.04 vem com Python 3.10. Vamos instalar o **Python 3.13** pelo repositório
[deadsnakes](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa), que é a forma mais comum de
ter versões novas do Python no Ubuntu.

```bash
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.13 python3.13-venv python3.13-dev
python3.13 --version
```

As bibliotecas ficam listadas no arquivo [`requirements.txt`](requirements.txt). Vamos
instalá-las num **ambiente virtual** (uma pasta isolada só para este projeto) depois de baixar o
repositório, na [seção 7](#7-baixar-este-repositório).

| Biblioteca | Para que serve |
|------------|----------------|
| [snakemake](https://snakemake.readthedocs.io/) | Organiza e executa as etapas do pipeline |
| [pandas](https://pandas.pydata.org/) | Trabalha com tabelas |
| [requests](https://requests.readthedocs.io/) | Faz chamadas para APIs na internet (o VEP) |
| [psutil](https://psutil.readthedocs.io/) | Lê RAM, CPU e disco do computador |
| [pyyaml](https://pyyaml.org/) | Lê arquivos de configuração `.yaml` |

### 4.4 Miniconda

O [Miniconda](https://www.anaconda.com/docs/getting-started/miniconda/main) é a versão
**pequena** do Anaconda: instala só o gerenciador `conda`, e você escolhe o que mais quer. Com o
canal [Bioconda](https://bioconda.github.io/) ele instala milhares de ferramentas de
bioinformática com um comando.

Escolha o instalador certo para o seu computador:

| Sistema | Arquivo |
|---------|---------|
| Ubuntu / WSL (Intel ou AMD) | `Miniconda3-latest-Linux-x86_64.sh` |
| macOS com chip Apple (M1, M2...) | `Miniconda3-latest-MacOSX-arm64.sh` |
| macOS com Intel | `Miniconda3-latest-MacOSX-x86_64.sh` |

```bash
# Baixa o instalador (troque o nome do arquivo conforme a tabela acima)
curl -fL -o ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# Instala em ~/miniconda3 sem fazer perguntas (-b) e apaga o instalador
bash ~/miniconda.sh -b -p ~/miniconda3
rm ~/miniconda.sh

# Faz o conda abrir junto com o terminal (no macOS, troque bash por zsh)
~/miniconda3/bin/conda init bash
```

> O `instalar.sh` faz o mesmo e ainda confere a **assinatura SHA-256** do instalador, comparando
> com a publicada em [repo.anaconda.com/miniconda](https://repo.anaconda.com/miniconda/). Assim
> ele garante que o arquivo não foi corrompido nem trocado no caminho.

**Feche e abra o terminal.** Aparece `(base)` no começo da linha. Agora configure os canais:

```bash
# Aceita os termos de uso dos canais padrão da Anaconda (exigido nas versões novas)
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Canais de bioinformática (a ordem importa)
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict

# Não ativar o (base) sozinho, para não misturar com o Python 3.13 do projeto
conda config --set auto_activate_base false
```

### 4.5 Ferramentas de bioinformática

| Ferramenta | Para que serve | Saiba mais |
|------------|----------------|------------|
| **FastQC** | Relatório de qualidade das leituras (FASTQ) | [Site](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) · [GitHub](https://github.com/s-andrews/FastQC) |
| **BWA** | Alinha as leituras no genoma de referência | [GitHub](https://github.com/lh3/bwa) · [Manual](https://bio-bwa.sourceforge.net/bwa.shtml) |
| **SAMtools / BCFtools** | Manipulam arquivos SAM/BAM/CRAM (alinhamentos) e VCF (variantes) | [Site](https://www.htslib.org/) · [GitHub](https://github.com/samtools/samtools) |
| **bedtools** | Faz contas com regiões do genoma (arquivos BED) | [Site](https://bedtools.readthedocs.io/) · [GitHub](https://github.com/arq5x/bedtools2) |
| **GATK** | Marca duplicatas e chama variantes (HaplotypeCaller) | [Site](https://gatk.broadinstitute.org/) · [GitHub](https://github.com/broadinstitute/gatk) |
| **VEP** | Anota o efeito das variantes (gene, consequência, ClinVar) | [Site](https://www.ensembl.org/info/docs/tools/vep/index.html) · [GitHub](https://github.com/Ensembl/ensembl-vep) · [API REST](https://grch37.rest.ensembl.org/documentation/info/vep_region_post) |
| **Snakemake** | Liga todas as etapas em um pipeline | [Site](https://snakemake.readthedocs.io/) · [GitHub](https://github.com/snakemake/snakemake) |

Você tem **duas formas** de ter essas ferramentas. Escolha uma (ou as duas):

**Forma A, Docker (recomendada):** não precisa instalar nada agora. O script da
[seção 16](#16-rodar-o-pipeline) monta uma imagem Docker com todas elas.

**Forma B, conda:** cria um ambiente chamado `bioinfo` com tudo (rode depois da
[seção 7](#7-baixar-este-repositório), dentro da pasta do repositório):

```bash
conda env create -f environment.yml
conda activate bioinfo
fastqc --version && bwa 2>&1 | grep Version && samtools --version | head -1 && bedtools --version && gatk --version
```

> **E o VEP?** O VEP completo instalado no PC precisa de um "cache" de mais de 20 GB. Neste
> tutorial usamos o VEP **pela internet** (API REST do Ensembl), então não é preciso baixar nada.
> Para instalar localmente no futuro, veja o
> [guia de instalação do VEP](https://www.ensembl.org/info/docs/tools/vep/script/vep_download.html)
> ou use a imagem Docker oficial `ensemblorg/ensembl-vep`.

---

## 5. Editores de código (IDEs)

No Windows, os editores são instalados **no Windows** e se conectam ao Ubuntu do WSL. Cole no
**PowerShell** (não precisa ser administrador). No macOS, use os comandos `brew` indicados.

### VS Code

```powershell
winget install -e --id Microsoft.VisualStudioCode
```

No macOS: `brew install --cask visual-studio-code`.

No Windows, abra o VS Code, vá em **Extensões** (`Ctrl + Shift + X`), procure e instale **WSL**
(da Microsoft). Dentro do terminal do Ubuntu (ou do macOS), na pasta de um projeto, abra o editor
com:

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

## 6. Assistentes de IA no terminal

Instale **dentro do Ubuntu** (ou no Terminal do macOS). Você não precisa de todos, escolha o que
preferir. Cada um pede login na primeira vez que você abrir.

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

## 7. Baixar este repositório

Se você usou o `instalar.ps1`, o repositório já está em `~/Tutorial-Bioinformatica` dentro do
Ubuntu: pule para "Crie o ambiente virtual".

No Windows, sempre trabalhe **dentro da pasta do Ubuntu** (`~`), não em `/mnt/c/...`: o acesso
aos arquivos do Windows pelo WSL é bem mais lento.

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
├── instalacao/
│   ├── instalar.ps1              # instalador do Windows (PowerShell)
│   ├── instalar.sh               # instalador do Ubuntu/WSL e macOS (bash)
│   └── verificar.sh              # confere o que está instalado
└── scripts/
    ├── verificar_recursos.py     # mede RAM/CPU/disco do seu PC
    ├── preparar_referencia.sh    # indexa a referência (bash)
    ├── anotar_vep.py             # anota as variantes pela API do VEP
    ├── contar_variantes.py       # conta patogênicas, VUS, benignas...
    └── rodar_pipeline.sh         # roda tudo com um comando (Docker)
```

---

# Parte II: Entendendo um pipeline de bioinformática

> Dica para a aula: rode o pipeline primeiro ([seção 16](#16-rodar-o-pipeline)) e depois leia
> esta parte com os arquivos de resultado abertos. Cada seção tem um bloco **"Olhe você mesmo"**
> com os comandos para ver o arquivo de verdade.

## 8. O que é um pipeline de variantes

O **sequenciador** lê o DNA de uma amostra em milhões de pedacinhos curtos (as **leituras**, ou
*reads*, de ~150 letras cada). Ele não sabe de onde no genoma cada pedaço veio. A bioinformática
faz o resto:

1. **Confere a qualidade** das leituras.
2. **Alinha**: descobre de onde no genoma de referência cada leitura veio (como montar um quebra
   cabeça olhando a foto da caixa).
3. **Chama variantes**: procura as posições onde a amostra é diferente da referência.
4. **Anota**: diz em que gene cada variante cai e o que ela pode fazer.
5. **Classifica**: decide se a variante é patogênica, benigna ou de significado incerto.

Um **pipeline** é essa sequência de etapas automatizada: a saída de uma é a entrada da próxima.
Aqui quem organiza as etapas é o [Snakemake](https://snakemake.readthedocs.io/) (arquivo
[`Snakefile`](Snakefile)).

```
 amostra_R1.fastq ─┐
                   ├─► FastQC ──────────────────────► relatório de qualidade (.html)
 amostra_R2.fastq ─┤
                   └─► BWA-MEM + samtools sort ─► GATK MarkDuplicates ─► BAM ─┬─► CRAM
                                                                             ├─► flagstat
 chr6.fa.gz ─► preparar_referencia.sh                                        └─► bedtools ─► BED
              (bwa index, samtools faidx,                                            │
               gatk CreateSequenceDictionary)                                        ▼
                                                              GATK HaplotypeCaller (-L BED) ─► VCF
                                                                                     │
                                                                                     ▼
                                                              bcftools norm ─► bcftools stats
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
| 3b. CRAM | samtools view -C | O mesmo alinhamento, compactado usando a referência | `amostra.cram` |
| 3c. Regiões | bedtools | Lista as regiões do genoma que têm leituras | `amostra.regioes.bed` |
| 4. Chamada de variantes | GATK HaplotypeCaller | Encontra as posições diferentes da referência | `resultados/03_variantes/amostra.vcf.gz` |
| 5. Normalização | bcftools norm | Padroniza a escrita das variantes para o VEP reconhecê-las | `amostra.normalizado.vcf.gz` |
| 5b. Estatísticas | bcftools stats | Conta SNVs, indels e calcula a razão Ti/Tv | `amostra.stats.txt` |
| 6. Anotação | VEP (API) | Gene, efeito, rsID e significância clínica (ClinVar) | `resultados/04_anotacao/amostra.vep.tsv` |
| 7. Contagem | Python | Conta patogênicas, provavelmente patogênicas, VUS, provavelmente benignas e benignas | `resultados/05_contagem/amostra.contagem.csv` |

### Resumo dos formatos de arquivo

| Formato | O que guarda | É texto? | Seção |
|---------|--------------|----------|-------|
| **FASTA** (`.fa`) | Sequência do genoma de referência | Sim | [10](#10-genoma-de-referência-e-alinhamento) |
| **FASTQ** (`.fastq`) | Leituras do sequenciador + qualidade de cada base | Sim | [9](#9-fastq-e-métricas-de-qualidade) |
| **SAM** (`.sam`) | Leituras alinhadas | Sim | [11](#11-sam-bam-e-cram) |
| **BAM** (`.bam`) | O mesmo que o SAM, compactado | Não (binário) | [11](#11-sam-bam-e-cram) |
| **CRAM** (`.cram`) | O mesmo que o BAM, ainda menor (usa a referência) | Não (binário) | [11](#11-sam-bam-e-cram) |
| **BED** (`.bed`) | Regiões do genoma (início e fim) | Sim | [12](#12-bed-regiões-do-genoma) |
| **VCF** (`.vcf.gz`) | Variantes encontradas | Sim (compactado) | [13](#13-chamada-de-variantes-e-o-arquivo-vcf) |

---

## 9. FASTQ e métricas de qualidade

### 9.1 O arquivo FASTQ

Cada leitura ocupa **4 linhas**. Esta é a primeira leitura de `dados/amostra_R1.fastq` (cortamos
a sequência para caber na tela):

```
@NB551003:113:HG73YBGX7:1:22104:4069:1088          ← 1. nome da leitura (começa com @)
CCTCTGACCACCCGCCCGGGCTCGCGGGAGGGGAGAAAGG...        ← 2. a sequência (A, C, G, T e N)
+                                                  ← 3. separador
AAAAAEEEAAAEAEEAAEEEEEEEEEEEEEEEEEEEEEEE...        ← 4. qualidade de cada base
```

O nome traz a "etiqueta" da leitura: `NB551003` é o sequenciador (um Illumina NextSeq), `113` é
a corrida, `HG73YBGX7` a lâmina (*flow cell*), `1` a faixa (*lane*), `22104` o ladrilho
(*tile*) e `4069:1088` a posição x:y do ponto na lâmina.

**A linha de qualidade.** Cada letra é a **qualidade Phred** da base na mesma posição. Phred é
uma escala de probabilidade de erro:

| Phred (Q) | Chance de a base estar errada | Acerto |
|-----------|-------------------------------|--------|
| Q10 | 1 em 10 | 90% |
| Q20 | 1 em 100 | 99% |
| Q30 | 1 em 1.000 | 99,9% |
| Q40 | 1 em 10.000 | 99,99% |

A letra é o número Q somado a 33 na tabela ASCII (a "Phred+33"). Neste NextSeq aparecem só
cinco letras, porque ele agrupa as qualidades em faixas:

| Letra | `/` | `6` | `<` | `A` | `E` |
|-------|-----|-----|-----|-----|-----|
| Q | 14 | 21 | 27 | 32 | 36 |

**Paired-end (R1 e R2).** O sequenciador leu cada fragmento de DNA pelas **duas pontas**: R1 é a
leitura de "ida" e R2 a de "volta". As leituras na mesma posição dos dois arquivos são um
**par**, e o alinhador usa a distância entre elas para posicionar melhor.

**Olhe você mesmo:**

```bash
head -4 dados/amostra_R1.fastq                       # a primeira leitura
echo $(( $(wc -l < dados/amostra_R1.fastq) / 4 ))    # quantas leituras (linhas ÷ 4)
```

### 9.2 Métricas de qualidade (FastQC)

O [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gera um relatório
`.html` com vários módulos. Cada um ganha ✅ (normal), ⚠️ (atenção) ou ❌ (estranho). Esses
limites foram pensados para genoma inteiro: em painéis e exomas alguns ⚠️/❌ são esperados.

| Módulo | O que mostra | O que procurar |
|--------|--------------|----------------|
| **Per base sequence quality** | Qualidade em cada posição da leitura (caixinhas) | A maioria acima de Q28 (faixa verde). É normal cair no fim da leitura. |
| **Per sequence quality scores** | Quantas leituras têm cada qualidade média | Um pico alto à direita (Q30 ou mais). |
| **Per base sequence content** | % de A, C, G e T em cada posição | Linhas paralelas. Oscilação nas primeiras ~10 bases é comum. |
| **Per sequence GC content** | Distribuição do % de GC das leituras | Uma curva só, parecida com a teórica. Duas corcovas podem indicar contaminação. |
| **Sequence Duplication Levels** | Quantas leituras são repetidas | Em painéis e exomas a duplicação é naturalmente alta. |
| **Overrepresented sequences** | Sequências que aparecem demais | Geralmente adaptadores ou contaminantes. |
| **Adapter Content** | Pedaços de adaptador (DNA artificial da preparação) | Se subir no fim das leituras, vale **aparar** (*trimming*). |

**Q30** é a métrica mais citada: a % de bases com qualidade 30 ou mais. Corridas Illumina boas
passam de 80%. Quando a qualidade é ruim ou há adaptadores, aparamos as leituras com
[fastp](https://github.com/OpenGene/fastp) ou Trimmomatic. Este tutorial não apara, porque as
leituras já são boas, mas num projeto real essa etapa vem antes do alinhamento.

**Olhe você mesmo:** abra os relatórios no navegador.

```bash
explorer.exe resultados/01_qualidade    # Windows (WSL): abre a pasta no Explorador
open resultados/01_qualidade            # macOS: abre a pasta no Finder
```

---

## 10. Genoma de referência e alinhamento

### 10.1 A referência (FASTA) e os índices

O **genoma de referência** é uma sequência "modelo" do genoma humano, em formato **FASTA**: uma
linha de título começando com `>` e depois as letras.

```
>chr6
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...
```

(O começo dos cromossomos é cheio de `N`, que significa "base desconhecida".)

Usamos só o **cromossomo 6** da versão **hg19**, também chamada **GRCh37**. Existe uma versão mais
nova, a **GRCh38** (hg38), que é a recomendada hoje para projetos novos. As posições mudam entre
as versões, então **nunca misture arquivos de versões diferentes**. Atenção também aos nomes: a
UCSC chama de `chr6`, o Ensembl chama de `6`. O script do VEP tira o `chr` por isso.

Para achar posições rápido, as ferramentas criam **índices**, como o índice remissivo de um
livro. O `scripts/preparar_referencia.sh` cria:

| Arquivo | Quem cria | Para que serve |
|---------|-----------|----------------|
| `chr6.fa.amb .ann .bwt .pac .sa` | `bwa index` | Índice do BWA para alinhar |
| `chr6.fa.fai` | `samtools faidx` | Pular direto para qualquer posição |
| `chr6.dict` | `gatk CreateSequenceDictionary` | Lista de cromossomos e tamanhos, exigida pelo GATK |

### 10.2 Alinhamento com BWA-MEM

O [BWA-MEM](https://github.com/lh3/bwa) pega cada par de leituras e procura onde ele encaixa na
referência, permitindo algumas diferenças (que podem ser variantes ou erros). Depois, o
`samtools sort` **ordena** as leituras pela posição no cromossomo, como organizar fichas em ordem
alfabética.

No comando de alinhamento aparece o **read group** (`-R '@RG\tID:amostra\tSM:amostra...'`):
uma etiqueta dizendo de que amostra e de que corrida vieram as leituras. O GATK exige.

Depois do alinhamento, o **GATK MarkDuplicates** marca as **duplicatas de PCR**: cópias da
mesma molécula original, criadas na preparação da amostra. Elas não são evidência independente,
então a chamada de variantes as ignora. A % de duplicação está em
`resultados/02_alinhamento/amostra.duplicatas.txt` (coluna `PERCENT_DUPLICATION`).

**Olhe você mesmo:**

```bash
cat resultados/02_alinhamento/amostra.flagstat.txt    # resumo do alinhamento
grep -A2 PERCENT_DUPLICATION resultados/02_alinhamento/amostra.duplicatas.txt | cut -f3,9
```

No `flagstat`, as linhas mais importantes são `mapped` (% de leituras que encontraram lugar),
`properly paired` (% de pares alinhados na distância e orientação esperadas) e `duplicates`.
Neste tutorial: **99,75%** das 5.258 leituras alinharam, **99,24%** como pares corretos, e
**11,7%** são duplicatas.

---

## 11. SAM, BAM e CRAM

Os três guardam **a mesma informação**: cada leitura, onde ela alinhou e como.

| | **SAM** | **BAM** | **CRAM** |
|---|---------|---------|----------|
| Formato | Texto (dá para ler) | Binário, compactado | Binário, compactado contra a referência |
| Tamanho | Muito grande | ~3 a 4 vezes menor que o SAM | ~30 a 60% menor que o BAM |
| Índice | não tem | `.bai` | `.crai` |
| Precisa da referência para ler? | Não | Não | **Sim**, a mesma usada no alinhamento |
| Quando usar | Ver e aprender | Trabalho do dia a dia | Guardar por muito tempo (arquivamento) |

O **CRAM** é menor porque não guarda a sequência inteira de cada leitura, só **o que é diferente
da referência**. Por isso, se a referência se perder, o CRAM fica ilegível: guarde as duas
juntas. Neste tutorial:

| Arquivo | Tamanho |
|---------|---------|
| `amostra.bam` | 463 KB |
| `amostra.cram` | 171 KB (63% menor) |

### 11.1 Lendo uma linha de alinhamento

O `samtools view` mostra o BAM (ou o CRAM) como SAM, em texto. Cada linha é uma leitura, com 11
colunas obrigatórias. Esta é uma leitura real do nosso BAM (SEQ e QUAL cortadas):

```
NB551003:113:HG73YBGX7:3:23411:17960:10232  163  chr6  7542003  60  151M  =  7542217  364  CCTG...  AAAA...
```

| Coluna | Nome | O que é |
|--------|------|---------|
| 1 | QNAME | Nome da leitura (o mesmo do FASTQ) |
| 2 | **FLAG** | Um número que soma "etiquetas": pareada, reversa, R1/R2, duplicata... Decifre em [explain-flags](https://broadinstitute.github.io/picard/explain-flags.html). |
| 3 | RNAME | Cromossomo |
| 4 | POS | Posição onde a leitura começa (contando a partir de **1**) |
| 5 | **MAPQ** | Confiança de que o lugar está certo (0 = pode estar em vários lugares; 60 = certeza no BWA) |
| 6 | **CIGAR** | Como a leitura encaixa: `151M` = 151 bases alinhadas; `100M2D51M` = deleção de 2 bases; `30S121M` = 30 bases "cortadas" (soft clip) |
| 7 a 9 | RNEXT, PNEXT, TLEN | Onde está o par e o tamanho do fragmento |
| 10 | SEQ | A sequência |
| 11 | QUAL | A qualidade (igual ao FASTQ) |

Depois vêm etiquetas opcionais, como `NM:i:1` (número de diferenças) e `RG:Z:amostra` (read
group).

**Olhe você mesmo:**

```bash
ls -lh resultados/02_alinhamento/                                      # compare BAM x CRAM
samtools view -H resultados/02_alinhamento/amostra.bam | head          # cabeçalho
samtools view resultados/02_alinhamento/amostra.bam | head -3          # 3 leituras
samtools view -T dados/referencia/chr6.fa resultados/02_alinhamento/amostra.cram | head -3   # o CRAM precisa da referência (-T)
```

(Com Docker, rode esses comandos dentro do container: veja
[Comandos dentro do Docker](#163-comandos-dentro-do-docker).)

Para **ver** o alinhamento como um gráfico, abra o BAM e o `.bai` no
[IGV](https://igv.org/app/) (versão web, sem instalar): escolha o genoma **hg19**, depois
**Tracks > Local File**.

---

## 12. BED: regiões do genoma

O **BED** é o formato mais simples de bioinformática: uma tabela de **regiões**, uma por linha,
separadas por TAB. As três primeiras colunas são obrigatórias. Estas são as três primeiras regiões do
`amostra.regioes.bed` gerado pelo pipeline:

```
chr6    7541951    7542616
chr6    7543348    7543509
chr6    7549293    7549762
```

| Coluna | O que é |
|--------|---------|
| 1 | Cromossomo |
| 2 | Início da região |
| 3 | Fim da região |
| 4 em diante (opcionais) | Nome, pontuação, fita (+/-)... |

**A pegadinha do BED:** a contagem começa do **0** e o **fim não entra** na região. A região
`chr6 100 200` são as bases **101 a 200** quando contamos a partir de 1 (como no VCF e no SAM).
Ou seja, para converter de 1 para 0 diminui-se 1 **só do início**. Esse "erro de 1" é um dos bugs
mais comuns de bioinformática, e não dá mensagem de erro nenhuma.

**Para que serve:**

- **Painéis e exomas:** o fabricante do kit entrega um BED com as regiões capturadas. As análises
  olham só para elas.
- **Acelerar o pipeline:** aqui, o `bedtools` gera um BED das regiões que têm leituras (11
  regiões, somando cerca de 25 mil bases, todas no gene **DSP**), e o GATK procura variantes
  **só ali** (opção `-L`), em vez dos 171 milhões de bases do cromossomo 6.
- **Comparar regiões:** o [bedtools](https://bedtools.readthedocs.io/) faz interseção, união,
  cobertura etc. entre arquivos BED, BAM e VCF.

Não confunda com o **GTF/GFF**, que descreve genes, exons e transcritos e conta a partir de 1.

**Olhe você mesmo:**

```bash
cat resultados/02_alinhamento/amostra.regioes.bed
# Tamanho total coberto, em pares de bases
awk '{soma += $3 - $2} END {print soma, "pb"}' resultados/02_alinhamento/amostra.regioes.bed
```

---

## 13. Chamada de variantes e o arquivo VCF

### 13.1 Chamada de variantes

O **GATK HaplotypeCaller** olha todas as leituras empilhadas em cada região e decide onde a
amostra é diferente da referência e com qual **genótipo**. Ele reconstrói localmente as
sequências possíveis (os haplótipos), o que o deixa bom para achar **indels** (inserções e
deleções), além de **SNVs** (troca de uma letra).

| Tipo | Exemplo | Significa |
|------|---------|-----------|
| SNV | `A` → `G` | Troca de uma base |
| Inserção | `A` → `ATT` | Entraram 2 bases depois do A |
| Deleção | `ACT` → `A` | Saíram 2 bases depois do A |

### 13.2 Anatomia do VCF

O **VCF** (*Variant Call Format*) tem um **cabeçalho** (linhas com `##`, que explicam cada
campo), uma linha de **títulos** (`#CHROM...`) e depois **uma variante por linha**. Estas são as duas primeiras variantes do nosso VCF
(o INFO foi encurtado):

```
#CHROM  POS      ID  REF  ALT  QUAL     FILTER  INFO               FORMAT          amostra
chr6    7542253  .   G    A    1376.64  .       AC=1;AF=0.5;DP=148;...  GT:AD:DP:GQ:PL  0/1:69,66:135:99:1384,0,1510
chr6    7542511  .   TC   T    49.6     .       AC=1;AF=0.5;DP=6;...    GT:AD:DP:GQ:PL  0/1:4,2:6:57:57,0,132
```

| Coluna | O que é |
|--------|---------|
| CHROM, POS | Cromossomo e posição (contando a partir de **1**) |
| ID | Identificador conhecido (ex.: rsID do dbSNP), ou `.` |
| REF, ALT | Base(s) da referência e base(s) encontrada(s) na amostra |
| QUAL | Confiança de que existe uma variante ali (escala Phred) |
| FILTER | `PASS` se passou nos filtros, `.` se nenhum filtro foi aplicado |
| INFO | Informações da variante (ex.: `DP` = profundidade total) |
| FORMAT + amostra | Os campos da amostra, na ordem do FORMAT |

Os campos da amostra mais importantes:

| Campo | O que é | Exemplo |
|-------|---------|---------|
| **GT** | Genótipo: `0` = alelo da referência, `1` = alelo alternativo | `0/1` heterozigoto, `1/1` homozigoto alternativo |
| **AD** | Leituras com cada alelo (ref, alt) | `12,10` |
| **DP** | Profundidade: total de leituras na posição | `22` |
| **GQ** | Confiança no genótipo (Phred, máx. 99) | `99` |

Compare as duas variantes acima. A primeira (`G>A`) tem `AD=69,66`: quase metade das 135
leituras com cada alelo, exatamente o que se espera de um heterozigoto, e `GQ=99`. A segunda
(deleção `TC>T`) tem só **6 leituras** (`AD=4,2`), `QUAL` baixo e `GQ=57`: é uma chamada fraca,
que num laboratório seria confirmada por outro método (como Sanger) antes de entrar num laudo.

### 13.3 Normalização

A mesma variante pode ser escrita de jeitos diferentes. Uma deleção de um `T` dentro de `TTTT`
pode estar em qualquer um dos quatro `T`. O `bcftools norm`:

- **alinha os indels à esquerda** (escolhe sempre a posição mais à esquerda), e
- **separa variantes multialélicas** (`A → G,T` vira duas linhas).

Sem isso, a comparação com bancos de dados (ClinVar, gnomAD) pode falhar.

### 13.4 Estatísticas (bcftools stats)

O `amostra.stats.txt` resume o VCF. Duas métricas para olhar:

- **Número de SNVs e indels** (linhas `SN`).
- **Ti/Tv** (linha `TSTV`): razão entre **transições** (A↔G, C↔T) e **transversões** (as demais
  trocas). Em genoma humano inteiro é ~2,0 a 2,1; em exoma, ~2,8 a 3,0. Um valor bem abaixo
  disso sugere muitos falsos positivos. Com poucas variantes, como aqui, o valor oscila muito.

Neste tutorial: 33 variantes (30 SNVs e 3 indels) e Ti/Tv de 2,00.

**Olhe você mesmo:**

```bash
zcat resultados/03_variantes/amostra.normalizado.vcf.gz | grep -v "^##" | head    # macOS: gzcat
grep -E "^SN|^TSTV" resultados/03_variantes/amostra.stats.txt
```

---

## 14. Anotação e classificação clínica (ACMG/ClinGen e AMP/VICC)

### 14.1 Anotação com o VEP

Um VCF diz **onde** está a variante, mas não **o que** ela faz. O
[VEP](https://www.ensembl.org/info/docs/tools/vep/index.html) (*Variant Effect Predictor*)
acrescenta:

| Informação | Exemplo | Significa |
|------------|---------|-----------|
| Gene e transcrito | `DSP`, `ENST00000379802` | Onde a variante cai (o script prefere o transcrito canônico) |
| Consequência | `missense_variant`, `stop_gained`, `synonymous_variant`, `intron_variant` | O que muda na proteína |
| Impacto | HIGH, MODERATE, LOW, MODIFIER | Um resumo grosseiro da consequência |
| HGVS | `c.3337C>T`, `p.Arg1113Ter` | O "nome oficial" da variante: `c.` no RNA/DNA codificante, `p.` na proteína (`Ter` = códon de parada) |
| Exon | `23/24` | Exon 23 de 24 do transcrito |
| IDs conhecidos | `rs1234` (dbSNP), `COSV...` (COSMIC) | Já foi vista antes |
| Frequência populacional | gnomAD | Quão comum ela é na população |
| Significância clínica | ClinVar | O que laboratórios já disseram sobre ela |

Um gene tem vários **transcritos** (versões do RNA). A mesma variante pode ser missense em um e
intrônica em outro. Na rotina clínica usa-se o transcrito **MANE Select**, um padrão escolhido em
comum pelo NCBI e pelo Ensembl.

Este tutorial usa o VEP **pela internet**, então as variantes são enviadas para os servidores do
Ensembl. Por isso: **use só com dados públicos**, nunca com dados de pacientes (veja
[Segurança e privacidade](#18-segurança-e-privacidade)).

**Olhe você mesmo:**

```bash
column -t -s $'\t' resultados/04_anotacao/amostra.vep.tsv | less -S    # q para sair
cat resultados/05_contagem/amostra.contagem.csv
```

**O que este tutorial encontra.** Todas as variantes caem no gene **DSP** (desmoplaquina),
ligado à **cardiomiopatia arritmogênica**. A maioria é intrônica ou sinônima e benigna no
ClinVar. Uma delas, `chr6:7579760 C>T` (`rs746877365`), é **`stop_gained`**: cria um códon de
parada, a proteína sai cortada, e o ClinVar a classifica como patogênica. É um ótimo exemplo
para discutir o critério **PVS1** na seção 14.3.

### 14.2 Germinativa ou somática? A primeira pergunta

| | **Germinativa** | **Somática** |
|---|-----------------|--------------|
| De onde vem | Herdada ou presente desde o embrião, em **todas** as células | Surgiu depois, só em algumas células (ex.: um tumor) |
| Exemplo de amostra | Sangue, saliva | Biópsia do tumor |
| Pergunta clínica | "Essa variante **causa uma doença** hereditária?" | "Essa variante **impulsiona o tumor**? Existe **remédio** para ela?" |
| Como se classifica | **ACMG/AMP** + refinamentos **ClinGen** | **AMP/ASCO/CAP** (tiers) e **ClinGen/CGC/VICC** (oncogenicidade) |

Usar as regras germinativas numa variante de tumor (ou o contrário) é um **erro de categoria**:
são perguntas diferentes, com sistemas diferentes.

### 14.3 Variantes germinativas: ACMG/AMP e ClinGen

Em 2015, o ACMG e a AMP publicaram o padrão para classificar variantes germinativas em
**5 classes** ([Richards et al., 2015](https://doi.org/10.1038/gim.2015.30)):

| Classe | Em inglês | Sigla |
|--------|-----------|-------|
| Patogênica | Pathogenic | P |
| Provavelmente patogênica | Likely pathogenic | LP |
| Significado incerto | Variant of uncertain significance | **VUS** |
| Provavelmente benigna | Likely benign | LB |
| Benigna | Benign | B |

A classe sai da soma de **critérios**, cada um com um código e uma força:

| Força | A favor de patogênica | A favor de benigna |
|-------|-----------------------|--------------------|
| Muito forte / isolada | **PVS1** (variante nula: perda de função) | **BA1** (comum demais na população) |
| Forte | **PS1 a PS4** (ex.: PS3, estudo funcional mostra dano) | **BS1 a BS4** (ex.: BS1, frequência alta para a doença) |
| Moderada | **PM1 a PM6** (ex.: PM2, ausente/raríssima no gnomAD) | |
| De apoio | **PP1 a PP5** (ex.: PP3, programas preveem dano) | **BP1 a BP7** (ex.: BP4, programas preveem que não há dano) |

Alguns exemplos para a aula:

- **PVS1:** a variante destrói o gene (stop, frameshift, sítio de splice), num gene em que
  **perder uma cópia já causa a doença**.
- **PS2/PM6:** a variante é **de novo** (não está nos pais) num paciente com a doença.
- **PM2:** a variante não aparece (ou é raríssima) no [gnomAD](https://gnomad.broadinstitute.org/).
- **BA1:** a variante está em mais de 5% de alguma população: comum demais para causar doença
  rara.

**O que mudou depois de 2015 (refinamentos da ClinGen).** O grupo de interpretação de variantes
da [ClinGen](https://clinicalgenome.org/working-groups/sequence-variant-interpretation/)
publicou ajustes que todo laboratório usa hoje:

- **Sistema de pontos:** cada força vale pontos (apoio = 1, moderada = 2, forte = 4, muito
  forte = 8; critérios benignos descontam). Soma ≥ 10 = patogênica, 6 a 9 = provavelmente
  patogênica, 0 a 5 = VUS, −1 a −6 = provavelmente benigna, ≤ −7 = benigna
  ([Tavtigian et al., 2018](https://doi.org/10.1038/gim.2017.210) e
  [2020](https://doi.org/10.1002/humu.24088)).
- **PVS1 em degraus:** nem toda variante nula é "muito forte". Depende do mecanismo da doença e
  de onde está o códon de parada ([Abou Tayoun et al., 2018](https://doi.org/10.1002/humu.23626)).
  Um códon de parada que fica **antes do último exon** faz a célula destruir o RNA (o chamado
  *NMD*): perda de função de verdade, PVS1 com força total. Se ele estiver no **último exon**, a
  proteína cortada ainda pode ser produzida, e a força do PVS1 diminui.

  **Exercício:** em que exon do DSP está a `stop_gained` do tutorial? Veja a coluna `exon` do
  `amostra.vep.tsv`.
  <details><summary>Resposta</summary>

  No exon **23 de 24** (`c.3337C>T`, `p.Arg1113Ter`). O exon 23 é o penúltimo, e o códon de
  parada fica a cerca de 2.000 nucleotídeos da última junção entre exons, muito mais que o
  limite de ~50. Então o RNA deve ser destruído pelo NMD. E perder uma cópia do DSP é um
  mecanismo conhecido de cardiomiopatia arritmogênica. Por isso o **PVS1** se aplica com força
  muito forte (8 pontos). Com o PM2 de apoio (variante raríssima no gnomAD, 1 ponto), a soma
  dá 9: **provavelmente patogênica**. Basta mais um critério de apoio, como ter sido vista em
  outros pacientes com a doença, para chegar a 10: **patogênica**. Isso bate com o ClinVar,
  que tem as duas classificações para essa variante.
  </details>
- **PM2 rebaixado para "de apoio":** estar ausente do gnomAD é evidência fraca.
- **PP5 e BP6 aposentados:** "outro laboratório disse que é patogênica" não é evidência. É
  preciso olhar os dados originais.
- **PP3/BP4 calibrados:** usa-se **um** preditor calibrado (ex.: REVEL), com força definida por
  limites testados ([Pejaver et al., 2022](https://doi.org/10.1016/j.ajhg.2022.10.013)), e não
  vários programas somados.
- **Regras por gene:** para muitos genes existem especificações de painéis de especialistas
  (VCEPs), publicadas no [CSpec](https://cspec.genome.network/). Elas valem mais que as regras
  gerais.

Uma nova versão da diretriz (ACMG/AMP/CAP/ClinGen, "v4"), toda baseada em pontos, estava em fase
de testes em 2026. Fique de olho.

**ClinVar e as estrelas.** O [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/) junta as
classificações enviadas por laboratórios do mundo todo. As **estrelas** dizem quão confiável é
a classificação:

| Estrelas | Significa |
|----------|-----------|
| ★★★★ | Diretriz prática (practice guideline) |
| ★★★ | Revisada por painel de especialistas (VCEP) |
| ★★ | Vários laboratórios, com critérios e sem conflito |
| ★ | Um laboratório com critérios, **ou** vários em conflito |
| (nenhuma) | Sem critérios informados |

**Como o `contar_variantes.py` simplifica.** O script pega a classificação do ClinVar que o VEP
traz e, se houver mais de uma, fica com a **mais grave** (patogênica > provavelmente patogênica >
VUS > provavelmente benigna > benigna). Variantes sem classificação entram como **sem
classificação no ClinVar**. Isso é **só para estudo**: uma classificação de verdade aplica os
critérios ACMG/ClinGen, considera as estrelas do ClinVar e o fenótipo do paciente. Uma classificação
também **envelhece**: uma VUS de hoje pode virar patogênica ou benigna amanhã, quando surgirem
dados novos. Laboratórios reanalisam periodicamente.

### 14.4 Variantes somáticas: AMP/ASCO/CAP e VICC

No câncer fazemos **duas perguntas separadas**:

**1. A variante tem utilidade clínica neste tumor?** Sistema **AMP/ASCO/CAP**
([Li et al., 2017](https://doi.org/10.1016/j.jmoldx.2016.10.002)), em **tiers**:

| Tier | Significado | Exemplo típico |
|------|-------------|----------------|
| **I** | Significado clínico **forte**: remédio aprovado ou diretriz para este tumor | BRAF V600E em melanoma |
| **II** | Significado clínico **potencial**: remédio aprovado para outro tumor, ensaios clínicos | A mesma variante, num tumor em que o remédio ainda não foi aprovado |
| **III** | Significado **desconhecido** (a "VUS" somática) | Variante rara sem dados |
| **IV** | Benigna ou provavelmente benigna | Polimorfismo comum |

O tier **depende do tipo de tumor**: a mesma variante pode ser Tier I num câncer e Tier II em
outro.

**2. A variante é oncogênica (impulsiona o câncer)?** Sistema **ClinGen/CGC/VICC**
([Horak et al., 2022](https://doi.org/10.1016/j.gim.2022.01.001)), também em 5 classes e com
pontos, parecido com o ACMG: **oncogênica**, **provavelmente oncogênica**, **VUS**,
**provavelmente benigna**, **benigna**. Os critérios têm códigos próprios, como **OVS1**
(variante nula num gene supressor de tumor), **OS3** (*hotspot*, posição mutada em muitos
tumores) e **SBVS1** (frequente na população).

As duas perguntas são independentes: uma variante pode ser **oncogênica** e mesmo assim **Tier
III**, se ainda não existe remédio para ela. O [VICC](https://cancervariants.org/) (Variant
Interpretation for Cancer Consortium) junta bases como [CIViC](https://civicdb.org/),
[OncoKB](https://www.oncokb.org/) e [COSMIC](https://cancer.sanger.ac.uk/cosmic) para responder
a essas perguntas.

**Cuidado com amostras só de tumor:** sem comparar com uma amostra normal do mesmo paciente
(sangue), não dá para ter certeza se a variante é somática ou germinativa. Uma variante com
~50% ou ~100% das leituras pode ser germinativa. O ideal é sequenciar **tumor e normal
pareados**.

---

## 15. Outros métodos que você vai ouvir falar

| Método | O que é, em uma frase |
|--------|-----------------------|
| **Trimming** (fastp, Trimmomatic) | Corta adaptadores e pontas de baixa qualidade das leituras antes de alinhar. |
| **BQSR** (GATK) | Recalibra as qualidades das bases usando variantes conhecidas, corrigindo vícios do sequenciador. |
| **GVCF e joint calling** | Chama variantes de várias amostras juntas, para saber quem é igual à referência e quem não tem cobertura. |
| **DeepVariant** | Chamador de variantes do Google baseado em redes neurais. |
| **Filtragem de variantes** (VQSR, hard filters) | Remove variantes que parecem erro técnico (pouca cobertura, viés de fita etc.). |
| **CNV** (CNVkit, GATK gCNV) | Encontra ganhos e perdas de pedaços grandes do genoma (cópias a mais ou a menos). |
| **Variantes estruturais** (Manta, Sniffles) | Encontra inversões, translocações e grandes inserções/deleções. |
| **Leituras longas** (Nanopore, PacBio) | Leituras de milhares de bases: resolvem regiões repetitivas e variantes estruturais. |
| **RNA-seq** (STAR, salmon, DESeq2) | Mede quais genes estão ligados e quanto, em vez de olhar o DNA. |
| **Single-cell** (scanpy, Seurat) | RNA-seq célula por célula. |
| **Metagenômica** (Kraken2) | Identifica quais microrganismos estão numa amostra. |
| **Painel × exoma × genoma** | Painel = dezenas a centenas de genes; exoma = todos os exons (~2% do genoma); genoma = tudo. Quanto maior, mais caro e mais dados. |
| **Benchmarking** (hap.py, GIAB) | Mede a qualidade do pipeline comparando com amostras de referência cuja resposta é conhecida. |

---

# Parte III: Rodar e interpretar

## 16. Rodar o pipeline

### 16.1 Verificar se o seu PC aguenta

```bash
cd ~/Tutorial-Bioinformatica
source .venv/bin/activate
python scripts/verificar_recursos.py
```

O script mostra núcleos, threads, RAM e disco, e decide quantas threads e quanta memória o
pipeline vai usar, sempre deixando folga para o sistema. A decisão fica salva em
`config/recursos.yaml`. Se aparecer **ATENÇÃO**, leia o aviso (geralmente é só fechar o
navegador antes de rodar).

> **Núcleos x threads:** um *núcleo* (core) é uma unidade física de processamento. Muitos
> processadores rodam 2 *threads* por núcleo, ou seja, 2 tarefas ao mesmo tempo. O pipeline usa
> todas as threads **menos 2**, e no máximo metade da RAM livre.

### 16.2 Forma A: com Docker (recomendada)

Um comando só. Na primeira vez demora mais: baixa e monta a imagem (cerca de 3 GB) e indexa a
referência (cerca de 7 minutos no nosso teste). Nas próximas vezes é rápido.

```bash
bash scripts/rodar_pipeline.sh
```

O script:

1. Confere se o Docker está ligado
2. Roda o `verificar_recursos.py`
3. Constrói a imagem Docker `tutorial-bioinfo`
4. Prepara a referência com `scripts/preparar_referencia.sh`
5. Roda o Snakemake **dentro do Docker, com limite de CPU e memória**, para o PC não travar

### 16.3 Comandos dentro do Docker

Na Forma A, as ferramentas (samtools, bcftools...) estão **dentro da imagem**, não no seu
computador. Para usá-las nos blocos "Olhe você mesmo", abra um terminal dentro do container:

```bash
docker run --rm -it -v "$PWD":/pipeline -w /pipeline tutorial-bioinfo bash
# agora você está dentro do container; para sair, digite: exit
```

### 16.4 Forma B: com conda

```bash
conda activate bioinfo
python scripts/verificar_recursos.py
bash scripts/preparar_referencia.sh
snakemake --cores $(grep threads config/recursos.yaml | awk '{print $2}') --printshellcmds
```

### 16.5 Comandos úteis do Snakemake

```bash
snakemake -n                        # só mostra o que seria feito, sem rodar (dry-run)
snakemake --cores 2 --forceall      # refaz tudo do zero
snakemake --dag | dot -Tpng > dag.png   # desenha o pipeline (precisa: sudo apt install graphviz)
```

Para rodar com **outras amostras**, troque os caminhos em [`config/config.yaml`](config/config.yaml).

### 16.6 O resultado esperado

No fim, o pipeline mostra uma tabela como esta (com os dados deste repositório):

```
Classificação                    Variantes       %
--------------------------------------------------
Patogênica                               1    3.0%
Provavelmente patogênica                 0    0.0%
VUS (significado incerto)                0    0.0%
Provavelmente benigna                    3    9.1%
Benigna                                 26   78.8%
Conflitante no ClinVar                   0    0.0%
Sem classificação no ClinVar             3    9.1%
--------------------------------------------------
Total                                   33
```

Os números de "sem classificação" e das outras classes podem mudar um pouco com o tempo, porque o
ClinVar e o VEP são atualizados.

---

## 17. Problemas comuns

| Problema | Solução |
|----------|---------|
| `não pode ser carregado porque a execução de scripts foi desabilitada` (PowerShell) | Rode `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force` na mesma janela e tente de novo. |
| `winget` não é reconhecido | Instale o **Instalador de Aplicativo** (App Installer) pela Microsoft Store, ou instale Docker Desktop e VS Code pelos sites. |
| `WslRegisterDistribution failed` ou erro de virtualização | Ative a virtualização (Intel VT-x / AMD-V / SVM) na BIOS do computador e rode `wsl --install -d Ubuntu-22.04` de novo. |
| `The command 'docker' could not be found in this WSL 2 distro` | Abra o Docker Desktop > **Settings** > **Resources** > **WSL integration** > ligue **Ubuntu-22.04** > **Apply & restart**. |
| `permission denied ... docker.sock` | Rode `sudo usermod -aG docker $USER`, feche e abra o terminal. |
| `Cannot connect to the Docker daemon` | Docker Desktop: abra o app e espere ficar verde. Docker Engine no Ubuntu: `sudo service docker start` (e confira o systemd, [seção 2.4](#24-docker-no-windows)). |
| `python3.13: command not found` | Ubuntu: refaça a [seção 4.3](#43-python-313-só-ubuntu). macOS: `brew install python@3.13`. |
| `conda: command not found` | Rode `~/miniconda3/bin/conda init bash` (no macOS, `init zsh`), feche e abra o terminal. |
| Mac Apple: a imagem Docker não constrói | Rode `PLATAFORMA_DOCKER=linux/amd64 bash scripts/rodar_pipeline.sh`. |
| Mac Apple: `conda env create` falha com "PackagesNotFoundError" | Rode `CONDA_SUBDIR=osx-64 conda env create -f environment.yml` (usa pacotes Intel pelo Rosetta 2). O `instalar.sh` já tenta isso sozinho. |
| PC muito lento ou travando | Feche o navegador e outros programas, rode `python scripts/verificar_recursos.py` de novo e veja [Limitar a memória do WSL](#23-limitar-a-memória-do-wsl). |
| `A referência ainda não foi preparada` | Rode `bash scripts/preparar_referencia.sh` (Forma B) ou use a Forma A. |
| Erro 429 / falha de conexão no VEP | A API está ocupada. O script já tenta de novo sozinho; se falhar, espere alguns minutos e rode o pipeline de novo (ele continua de onde parou). |
| `bash\r: No such file or directory` | O arquivo ganhou fim de linha do Windows. Rode `sudo apt install -y dos2unix && dos2unix scripts/*.sh instalacao/*.sh`. |
| Snakemake diz `LockException` | Uma execução anterior foi interrompida. Rode `snakemake --unlock` (Forma B) ou apague a pasta `.snakemake/locks`. |

Se nada resolver, rode `bash instalacao/verificar.sh` e mande a saída para o professor, junto
com o arquivo `instalacao/instalar.log`.

---

## 18. Segurança e privacidade

O que este repositório faz (e não faz) no seu computador:

- **Os scripts do repositório não apagam nada fora da pasta do projeto.** Eles instalam programas
  pelos gerenciadores oficiais (apt, Homebrew, winget), o Miniconda em `~/miniconda3` e os
  ambientes `.venv` e `bioinfo`. Os resultados ficam em `resultados/`.
- **`sudo` só aparece para instalar programas do sistema.** O pipeline em si roda como o seu
  usuário. Na Forma A, roda dentro de um container Docker, com o seu usuário (não como root) e
  com **limite de CPU e memória**, para o computador não travar.
- **Downloads conferidos:** o instalador do Miniconda tem a assinatura SHA-256 conferida, e as
  chaves do Docker e do deadsnakes vêm dos repositórios oficiais.
- **`Set-ExecutionPolicy -Scope Process`** libera scripts **só na janela aberta**. Ao fechá-la,
  o Windows volta à proteção normal. Use essa liberação só para scripts que você leu.
- **Comandos `curl ... | bash`** (Homebrew e assistentes de IA) baixam e executam um script na
  hora. Use só com endereços oficiais, como os deste README. Para conferir antes, troque por
  `curl -fsSL ENDERECO -o instalador.sh`, leia o arquivo e depois rode `bash instalador.sh`.
- **Privacidade (LGPD):** a etapa de anotação envia as variantes para a API pública do Ensembl,
  na internet. Isso é ótimo para aprender, mas **dados genéticos de pacientes são dados pessoais
  sensíveis**. Nunca rode este pipeline com amostras de pacientes. Para isso, use o VEP instalado
  localmente, com cache, num ambiente aprovado pela instituição.
- **Assistentes de IA:** não cole dados de pacientes nem senhas em assistentes de IA.

Para desinstalar: apague a pasta `~/Tutorial-Bioinformatica` e `~/miniconda3`, e remova o
Docker Desktop pelo Painel de Controle (Windows) ou arrastando para o Lixo (macOS). No Windows,
o Ubuntu inteiro sai com `wsl --unregister Ubuntu-22.04` no PowerShell (**isso apaga todos os
arquivos dentro do Ubuntu**).

---

## Sobre os dados

- `dados/amostra_R1.fastq` e `dados/amostra_R2.fastq`: 2.629 pares de leituras de 150 pb
  (Illumina NextSeq) de uma região do cromossomo 6. Arquivos pequenos de propósito, para rodar em
  qualquer PC.
- `dados/referencia/chr6.fa.gz`: cromossomo 6 do genoma humano **hg19 (GRCh37)**.

## Referências

- Formatos: [SAM/BAM](https://samtools.github.io/hts-specs/SAMv1.pdf) ·
  [CRAM](https://samtools.github.io/hts-specs/CRAMv3.pdf) ·
  [VCF](https://samtools.github.io/hts-specs/VCFv4.2.pdf) ·
  [BED](https://samtools.github.io/hts-specs/BEDv1.pdf)
- Richards S, et al. Standards and guidelines for the interpretation of sequence variants.
  *Genet Med*. 2015;17:405-424. [doi:10.1038/gim.2015.30](https://doi.org/10.1038/gim.2015.30)
- Tavtigian SV, et al. Modeling the ACMG/AMP variant classification guidelines as a Bayesian
  classification framework. *Genet Med*. 2018;20:1054-1060.
  [doi:10.1038/gim.2017.210](https://doi.org/10.1038/gim.2017.210)
- Tavtigian SV, et al. Fitting a naturally scaled point system to the ACMG/AMP variant
  classification guidelines. *Hum Mutat*. 2020;41:1734-1737.
  [doi:10.1002/humu.24088](https://doi.org/10.1002/humu.24088)
- Abou Tayoun AN, et al. Recommendations for interpreting the loss of function PVS1 ACMG/AMP
  variant criterion. *Hum Mutat*. 2018;39:1517-1524.
  [doi:10.1002/humu.23626](https://doi.org/10.1002/humu.23626)
- Pejaver V, et al. Calibration of computational tools for missense variant pathogenicity
  classification and ClinGen recommendations for PP3/BP4 criteria. *Am J Hum Genet*.
  2022;109:2163-2177. [doi:10.1016/j.ajhg.2022.10.013](https://doi.org/10.1016/j.ajhg.2022.10.013)
- Li MM, et al. Standards and guidelines for the interpretation and reporting of sequence variants
  in cancer. *J Mol Diagn*. 2017;19:4-23.
  [doi:10.1016/j.jmoldx.2016.10.002](https://doi.org/10.1016/j.jmoldx.2016.10.002)
- Horak P, et al. Standards for the classification of pathogenicity of somatic variants in cancer
  (oncogenicity). *Genet Med*. 2022;24:986-998.
  [doi:10.1016/j.gim.2022.01.001](https://doi.org/10.1016/j.gim.2022.01.001)
