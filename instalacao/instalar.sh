#!/usr/bin/env bash
# =============================================================================
# Instala tudo o que o tutorial precisa, em Ubuntu (inclusive no WSL) e macOS.
# -----------------------------------------------------------------------------
# Como usar (dentro da pasta do repositório):
#     bash instalacao/instalar.sh
#
# Opções:
#     --sem-docker      não instala o Docker
#     --sem-conda       não instala o Miniconda nem o ambiente "bioinfo"
#     --docker-engine   (só WSL) instala o Docker Engine dentro do Ubuntu em vez
#                       de usar o Docker Desktop do Windows
#     --ajuda           mostra esta ajuda
#
# O que ele faz:
#   1. Descobre o sistema (Ubuntu, WSL ou macOS) e o processador (Intel ou ARM).
#   2. Instala os programas básicos, o Git e o Python 3.13.
#   3. Instala o Docker (Docker Engine no Ubuntu; Docker Desktop no macOS).
#      No WSL, o padrão é usar o Docker Desktop do Windows.
#   4. Instala o Miniconda em ~/miniconda3, conferindo a assinatura (SHA-256)
#      do instalador antes de rodá-lo, e configura os canais de bioinformática.
#   5. Cria o ambiente virtual .venv (Python 3.13 + bibliotecas) e o ambiente
#      conda "bioinfo" (FastQC, BWA, SAMtools, BCFtools, bedtools, GATK...).
#   6. Roda instalacao/verificar.sh para mostrar o que ficou instalado.
#
# Pode rodar quantas vezes quiser: o que já estiver instalado é pulado.
# Nada é apagado. Tudo fica em ~/miniconda3 e na pasta do repositório, a não
# ser os pacotes do sistema (apt/brew), que pedem a sua senha.
# Um registro completo fica em instalacao/instalar.log.
# =============================================================================

set -euo pipefail

# Sempre trabalha a partir da pasta principal do repositório.
cd "$(dirname "$0")/.."
PASTA_REPOSITORIO="$PWD"
ARQUIVO_LOG="$PASTA_REPOSITORIO/instalacao/instalar.log"

PASTA_MINICONDA="$HOME/miniconda3"
URL_MINICONDA="https://repo.anaconda.com/miniconda"
NOME_AMBIENTE="bioinfo"

INSTALAR_DOCKER=1
INSTALAR_CONDA=1
DOCKER_ENGINE_NO_WSL=0

# Grava tudo o que aparece na tela também no arquivo de log.
exec > >(tee -a "$ARQUIVO_LOG") 2>&1

informar() {
    echo -e "\n>>> $*"
}

avisar() {
    echo -e "\n!!! ATENÇÃO: $*"
}

falhar() {
    echo -e "\nERRO: $*" >&2
    echo "O registro completo está em $ARQUIVO_LOG" >&2
    exit 1
}

mostrar_ajuda() {
    sed -n '2,31p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

ler_opcoes() {
    for opcao in "$@"; do
        case "$opcao" in
            --sem-docker) INSTALAR_DOCKER=0 ;;
            --sem-conda) INSTALAR_CONDA=0 ;;
            --docker-engine) DOCKER_ENGINE_NO_WSL=1 ;;
            --ajuda|-h|--help) mostrar_ajuda ;;
            *) falhar "opção desconhecida: $opcao (use --ajuda)" ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# 1. Descobrir o sistema
# -----------------------------------------------------------------------------
descobrir_sistema() {
    SISTEMA="$(uname -s)"
    PROCESSADOR="$(uname -m)"
    NO_WSL=0

    case "$SISTEMA" in
        Linux)
            if ! command -v apt-get > /dev/null 2>&1; then
                falhar "este script funciona em Ubuntu/Debian (apt). Para outros Linux, siga o README."
            fi
            if grep -qi microsoft /proc/version 2> /dev/null; then
                NO_WSL=1
            fi
            NOME_MINICONDA_SO="Linux"
            ;;
        Darwin)
            NOME_MINICONDA_SO="MacOSX"
            ;;
        *)
            falhar "sistema '$SISTEMA' não suportado. No Windows, use instalacao/instalar.ps1."
            ;;
    esac

    case "$PROCESSADOR" in
        x86_64|amd64) PROCESSADOR="x86_64" ;;
        aarch64|arm64)
            if [[ "$SISTEMA" == "Darwin" ]]; then PROCESSADOR="arm64"; else PROCESSADOR="aarch64"; fi
            ;;
        *) falhar "processador '$PROCESSADOR' não suportado." ;;
    esac

    # Root (comum no WSL de alguns cursos) não precisa de sudo.
    if [[ "$(id -u)" -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi

    local descricao="$SISTEMA $PROCESSADOR"
    if [[ "$NO_WSL" -eq 1 ]]; then descricao="$descricao (WSL)"; fi
    informar "1/6 Sistema detectado: $descricao"
}

# -----------------------------------------------------------------------------
# 2. Programas básicos, Git e Python 3.13
# -----------------------------------------------------------------------------
# apt-get sem telas de pergunta no meio da instalação.
rodar_apt() {
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get "$@"
}

instalar_basicos_ubuntu() {
    informar "2/6 Atualizando o Ubuntu e instalando Git e Python 3.13 (pede a sua senha)"
    rodar_apt update
    rodar_apt upgrade -y
    rodar_apt install -y curl wget unzip git build-essential ca-certificates \
        software-properties-common

    if command -v python3.13 > /dev/null 2>&1; then
        echo "Python 3.13 já instalado: $(python3.13 --version)"
    else
        # O Ubuntu 22.04 vem com Python 3.10. O repositório deadsnakes tem as
        # versões novas do Python empacotadas para o Ubuntu.
        $SUDO add-apt-repository -y ppa:deadsnakes/ppa
        rodar_apt update
    fi
    # Mesmo com o python3.13 instalado, garante o venv e o dev (o apt pula se já tiver).
    rodar_apt install -y python3.13 python3.13-venv python3.13-dev
    PYTHON="python3.13"
}

instalar_basicos_macos() {
    informar "2/6 Instalando ferramentas da Apple, Homebrew, Git e Python 3.13"

    if ! xcode-select -p > /dev/null 2>&1; then
        echo "Vai abrir uma janela pedindo para instalar as 'Ferramentas de Linha de Comando'."
        echo "Clique em Instalar, espere terminar e rode este script de novo."
        xcode-select --install || true
        exit 0
    fi

    if ! command -v brew > /dev/null 2>&1; then
        for caminho in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            if [[ -x "$caminho" ]]; then eval "$("$caminho" shellenv)"; fi
        done
    fi
    if ! command -v brew > /dev/null 2>&1; then
        echo "Instalando o Homebrew (gerenciador de programas do macOS) pelo instalador"
        echo "oficial em https://brew.sh. Ele vai pedir a sua senha e um Enter."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        for caminho in /opt/homebrew/bin/brew /usr/local/bin/brew; do
            if [[ -x "$caminho" ]]; then eval "$("$caminho" shellenv)"; fi
        done
        command -v brew > /dev/null 2>&1 || falhar "o Homebrew não foi instalado."
    fi

    brew install git python@3.13
    PYTHON="$(brew --prefix)/bin/python3.13"
}

# -----------------------------------------------------------------------------
# 3. Docker
# -----------------------------------------------------------------------------
docker_funcionando() {
    docker info > /dev/null 2>&1
}

instalar_docker_engine_ubuntu() {
    # Comandos do guia oficial: https://docs.docker.com/engine/install/ubuntu/
    $SUDO install -m 0755 -d /etc/apt/keyrings
    $SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    $SUDO chmod a+r /etc/apt/keyrings/docker.asc
    local codinome
    codinome="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codinome stable" \
        | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
    rodar_apt update
    rodar_apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    if [[ "$(id -u)" -ne 0 ]]; then
        $SUDO usermod -aG docker "$USER"
        avisar "feche e abra o terminal para usar o Docker sem sudo."
    fi
}

# O Docker Engine no WSL precisa do systemd. Só acrescenta a linha se ela não
# existir, para não apagar outras configurações do /etc/wsl.conf.
ligar_systemd_no_wsl() {
    if grep -qs '^systemd=true' /etc/wsl.conf; then
        return
    fi
    if grep -qs '^\[boot\]' /etc/wsl.conf; then
        $SUDO sed -i '/^\[boot\]/a systemd=true' /etc/wsl.conf
    else
        printf '\n[boot]\nsystemd=true\n' | $SUDO tee -a /etc/wsl.conf > /dev/null
    fi
    avisar "o systemd foi ligado. No PowerShell rode  wsl --shutdown  e abra o Ubuntu de novo."
}

instalar_docker() {
    if [[ "$INSTALAR_DOCKER" -eq 0 ]]; then
        informar "3/6 Docker: pulado (--sem-docker)"
        return
    fi
    informar "3/6 Docker"
    if docker_funcionando; then
        echo "Docker já instalado e ligado: $(docker --version)"
        return
    fi

    if [[ "$SISTEMA" == "Darwin" ]]; then
        if [[ -d "/Applications/Docker.app" ]]; then
            avisar "o Docker Desktop está instalado mas desligado. Abra o app Docker e espere ficar verde."
        else
            brew install --cask docker-desktop || brew install --cask docker
            avisar "abra o app Docker (Aplicativos > Docker), aceite os termos e espere ficar verde."
        fi
        return
    fi

    if [[ "$NO_WSL" -eq 1 && "$DOCKER_ENGINE_NO_WSL" -eq 0 ]]; then
        avisar "no WSL usamos o Docker Desktop do Windows (o instalar.ps1 já instala)."
        echo "Abra o Docker Desktop no Windows e ligue:"
        echo "  Settings > Resources > WSL integration > Ubuntu-22.04 > Apply & restart"
        echo "Prefere o Docker dentro do Ubuntu? Rode: bash instalacao/instalar.sh --docker-engine"
        return
    fi

    if command -v dockerd > /dev/null 2>&1; then
        echo "Docker Engine já instalado, mas desligado. Tente: $SUDO service docker start"
    else
        instalar_docker_engine_ubuntu
    fi
    if [[ "$NO_WSL" -eq 1 ]]; then
        ligar_systemd_no_wsl
    fi
}

# -----------------------------------------------------------------------------
# 4. Miniconda
# -----------------------------------------------------------------------------
calcular_sha256() {
    if command -v sha256sum > /dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

encontrar_conda() {
    if [[ -x "$PASTA_MINICONDA/bin/conda" ]]; then
        CONDA="$PASTA_MINICONDA/bin/conda"
    elif [[ -n "${CONDA_EXE:-}" && -x "${CONDA_EXE}" ]]; then
        CONDA="$CONDA_EXE"
    else
        CONDA=""
    fi
}

baixar_e_instalar_miniconda() {
    local nome="Miniconda3-latest-${NOME_MINICONDA_SO}-${PROCESSADOR}.sh"
    local pasta_temporaria
    pasta_temporaria="$(mktemp -d)"
    local instalador="$pasta_temporaria/$nome"

    echo "Baixando $nome"
    curl -fL --retry 3 -o "$instalador" "$URL_MINICONDA/$nome"

    # Confere se o arquivo baixado é exatamente o publicado pela Anaconda.
    local esperado obtido
    esperado="$(curl -fsSL "$URL_MINICONDA/" | grep -A3 "\"$nome\"" | grep -oE '[0-9a-f]{64}' | head -1 || true)"
    obtido="$(calcular_sha256 "$instalador")"
    if [[ -z "$esperado" ]]; then
        avisar "não consegui ler a assinatura publicada; seguindo sem conferir."
    elif [[ "$esperado" != "$obtido" ]]; then
        rm -f "$instalador"
        falhar "a assinatura SHA-256 do instalador não confere. O download pode estar corrompido. Rode de novo."
    else
        echo "Assinatura SHA-256 conferida."
    fi

    # -b = sem perguntas, -p = pasta de instalação
    bash "$instalador" -b -p "$PASTA_MINICONDA"
    rm -f "$instalador"
    rmdir "$pasta_temporaria" 2> /dev/null || true
}

configurar_conda() {
    # Faz o conda abrir junto com o terminal (bash e, no macOS, zsh).
    "$CONDA" init bash > /dev/null
    if [[ "$SISTEMA" == "Darwin" ]]; then
        "$CONDA" init zsh > /dev/null
    fi

    # Termos de uso dos canais padrão da Anaconda (exigido nas versões novas).
    # Versões antigas do conda não têm o comando "tos"; nesse caso ignoramos.
    "$CONDA" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main 2> /dev/null || true
    "$CONDA" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r 2> /dev/null || true

    # Canais de bioinformática (a ordem importa: o último adicionado vem primeiro).
    if ! "$CONDA" config --show channels | grep -q bioconda; then
        "$CONDA" config --add channels bioconda
    fi
    if ! "$CONDA" config --show channels | grep -q conda-forge; then
        "$CONDA" config --add channels conda-forge
    fi
    "$CONDA" config --set channel_priority strict
    # Não ativar o (base) sozinho, para não misturar com o Python 3.13 do projeto.
    "$CONDA" config --set auto_activate_base false
}

instalar_miniconda() {
    if [[ "$INSTALAR_CONDA" -eq 0 ]]; then
        informar "4/6 Miniconda: pulado (--sem-conda)"
        return
    fi
    informar "4/6 Miniconda"
    encontrar_conda
    if [[ -n "$CONDA" ]]; then
        echo "conda já instalado: $("$CONDA" --version) em $CONDA"
    else
        baixar_e_instalar_miniconda
        CONDA="$PASTA_MINICONDA/bin/conda"
    fi
    configurar_conda
}

# -----------------------------------------------------------------------------
# 5. Ambientes do projeto
# -----------------------------------------------------------------------------
criar_venv() {
    informar "5/6 Ambiente virtual Python (.venv) com as bibliotecas do requirements.txt"
    if [[ ! -x .venv/bin/python ]]; then
        "$PYTHON" -m venv .venv
    fi
    .venv/bin/python -m pip install --upgrade pip
    .venv/bin/python -m pip install -r requirements.txt
}

ambiente_conda_existe() {
    "$CONDA" env list | awk '{print $1}' | grep -qx "$NOME_AMBIENTE"
}

criar_ambiente_conda() {
    if [[ "$INSTALAR_CONDA" -eq 0 ]]; then
        return
    fi
    informar "5/6 Ambiente conda '$NOME_AMBIENTE' com as ferramentas (pode levar de 5 a 15 minutos)"
    if ambiente_conda_existe; then
        echo "Ambiente '$NOME_AMBIENTE' já existe. Atualizando com o environment.yml"
        "$CONDA" env update -n "$NOME_AMBIENTE" -f environment.yml
        return
    fi
    if "$CONDA" env create -f environment.yml; then
        return
    fi
    # Alguns pacotes podem faltar para o chip Apple. Plano B: usar pacotes
    # Intel, que o macOS roda pelo Rosetta 2.
    if [[ "$SISTEMA" == "Darwin" && "$PROCESSADOR" == "arm64" ]]; then
        avisar "tentando de novo com pacotes Intel (Rosetta 2)."
        softwareupdate --install-rosetta --agree-to-license || true
        CONDA_SUBDIR=osx-64 "$CONDA" env create -f environment.yml
        local pasta_ambiente
        pasta_ambiente="$("$CONDA" env list | awk -v nome="$NOME_AMBIENTE" '$1 == nome {print $NF}')"
        # Grava no ambiente que ele usa pacotes Intel (para futuras instalações).
        "$CONDA" config --file "$pasta_ambiente/.condarc" --set subdir osx-64
        return
    fi
    falhar "não foi possível criar o ambiente conda '$NOME_AMBIENTE'."
}

# -----------------------------------------------------------------------------
main() {
    ler_opcoes "$@"
    echo "===== instalar.sh iniciado em $(date) ====="
    descobrir_sistema

    if [[ "$SISTEMA" == "Darwin" ]]; then
        instalar_basicos_macos
    else
        instalar_basicos_ubuntu
    fi
    instalar_docker
    instalar_miniconda
    criar_venv
    criar_ambiente_conda

    informar "6/6 Conferindo a instalação"
    bash instalacao/verificar.sh || true

    informar "Instalação concluída!"
    echo "Feche e abra o terminal. Depois, para trabalhar no projeto:"
    echo "    cd \"$PASTA_REPOSITORIO\""
    echo "    source .venv/bin/activate        # Python 3.13 do projeto"
    echo "    conda activate $NOME_AMBIENTE              # ferramentas de bioinformática"
}

main "$@"
