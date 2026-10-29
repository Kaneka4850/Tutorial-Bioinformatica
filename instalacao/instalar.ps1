<#
=============================================================================
 Instala tudo o que o tutorial precisa no Windows 10 e no Windows 11.
-----------------------------------------------------------------------------
 Como usar:
   1. Abra o PowerShell como administrador (menu Iniciar > digite PowerShell >
      botão direito em "Windows PowerShell" > Executar como administrador).
   2. Entre na pasta do repositório, por exemplo:
          cd $HOME\Downloads\Tutorial-Bioinformatica
   3. Libere scripts só nesta janela e rode o instalador:
          Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
          .\instalacao\instalar.ps1

 Opções:
   -SemDocker   não instala o Docker Desktop
   -SemVSCode   não instala o VS Code
   -SoMostrar   só mostra o que seria feito, sem instalar nada

 O que ele faz:
   1. Confere a versão do Windows e se a virtualização está ligada.
   2. Instala o WSL 2 com o Ubuntu 22.04 (na primeira vez pede para reiniciar
      o computador e rodar este script de novo).
   3. Instala o Docker Desktop e o VS Code pelo winget (loja oficial da
      Microsoft para programas).
   4. Copia este repositório para dentro do Ubuntu (~/Tutorial-Bioinformatica)
      e roda lá o instalacao/instalar.sh (Python 3.13, Miniconda e as
      ferramentas de bioinformática).

 Pode rodar quantas vezes quiser: o que já estiver instalado é pulado.
 Nada é apagado.
=============================================================================
#>

[CmdletBinding()]
param(
    [switch]$SemDocker,
    [switch]$SemVSCode,
    [switch]$SoMostrar
)

$ErrorActionPreference = 'Stop'

$Distro = 'Ubuntu-22.04'
$PastaNoUbuntu = '~/Tutorial-Bioinformatica'
$BuildMinimoWslInstall = 19041   # Windows 10 versão 2004
$BuildMinimoWsl2 = 18362         # Windows 10 versão 1903
$PastaRepositorio = Split-Path -Parent $PSScriptRoot

# O wsl.exe escreve em UTF-16 por padrão; isto pede UTF-8 (WSL recente).
$env:WSL_UTF8 = '1'

function Informar([string]$Mensagem) {
    Write-Host ''
    Write-Host ">>> $Mensagem" -ForegroundColor Cyan
}

function Avisar([string]$Mensagem) {
    Write-Host ''
    Write-Host "!!! ATENÇÃO: $Mensagem" -ForegroundColor Yellow
}

function Falhar([string]$Mensagem) {
    Write-Host ''
    Write-Host "ERRO: $Mensagem" -ForegroundColor Red
    exit 1
}

# Roda um comando, ou só mostra o que faria quando -SoMostrar foi usado.
function Executar([string]$Descricao, [scriptblock]$Acao) {
    if ($SoMostrar) {
        Write-Host "    [faria] $Descricao" -ForegroundColor DarkGray
        return
    }
    Write-Host "    $Descricao"
    & $Acao
}

# Saída do wsl.exe como texto limpo (remove os caracteres nulos do UTF-16).
function Rodar-Wsl {
    # No Windows PowerShell 5.1, texto no stderr de um programa vira erro fatal
    # com 'Stop'; aqui queremos só ler a saída.
    $ErrorActionPreference = 'Continue'
    $saida = & wsl.exe @args 2>&1 | Out-String
    return ($saida -replace "`0", '').Trim()
}

# -----------------------------------------------------------------------------
# 1. Windows e virtualização
# -----------------------------------------------------------------------------
function Conferir-Administrador {
    $identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identidade)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Falhar 'abra o PowerShell como ADMINISTRADOR (botão direito > Executar como administrador) e rode de novo.'
    }
}

function Conferir-Windows {
    $build = [System.Environment]::OSVersion.Version.Build
    $nome = (Get-CimInstance Win32_OperatingSystem).Caption
    Informar "1/4 Sistema: $nome (build $build)"

    if ($build -ge $BuildMinimoWslInstall) {
        Write-Host '    Versão do Windows OK.'
        return
    }
    if ($build -ge $BuildMinimoWsl2) {
        Avisar 'seu Windows 10 é antigo demais para a instalação automática do WSL.'
        Write-Host '    Siga a seção "Windows 10 versão 1903 ou 1909" do README (instalação manual),'
        Write-Host '    ou atualize o Windows em Configurações > Atualização e Segurança.'
        exit 1
    }
    Falhar "o WSL 2 precisa do Windows 10 versão 1903 (build $BuildMinimoWsl2) ou mais novo. Atualize o Windows."
}

function Conferir-Virtualizacao {
    $computador = Get-CimInstance Win32_ComputerSystem
    if ($computador.HypervisorPresent) {
        Write-Host '    Virtualização ligada.'
        return
    }
    $processador = Get-CimInstance Win32_Processor | Select-Object -First 1
    if ($processador.VirtualizationFirmwareEnabled) {
        Write-Host '    Virtualização ligada na BIOS.'
        return
    }
    Avisar 'a virtualização parece DESLIGADA na BIOS/UEFI do computador.'
    Write-Host '    O WSL 2 e o Docker não funcionam sem ela. Reinicie, entre na BIOS (F2, F10, Del ou Esc'
    Write-Host '    durante a inicialização) e ligue "Intel VT-x", "Intel Virtualization Technology",'
    Write-Host '    "AMD-V" ou "SVM Mode". Depois rode este script de novo.'
}

# -----------------------------------------------------------------------------
# 2. WSL 2 + Ubuntu 22.04
# -----------------------------------------------------------------------------
function Ubuntu-Instalado {
    $lista = Rodar-Wsl --list --quiet
    return ($lista -split "`r?`n" | ForEach-Object { $_.Trim() }) -contains $Distro
}

function Ubuntu-Pronto {
    # Pronto = já tem um usuário criado e responde a comandos.
    $usuario = Rodar-Wsl -d $Distro -- whoami
    return ($LASTEXITCODE -eq 0 -and $usuario -ne '')
}

function Instalar-Wsl {
    $ErrorActionPreference = 'Continue'
    Informar "2/4 WSL 2 e $Distro"

    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue) -or -not (Ubuntu-Instalado)) {
        Executar "wsl --install -d $Distro" { wsl.exe --install -d $Distro }
        if ($SoMostrar) { return }
        Avisar 'o WSL e o Ubuntu foram instalados. Agora:'
        Write-Host '    1. REINICIE o computador (se o Windows pedir).'
        Write-Host "    2. Abra '$Distro' no menu Iniciar e crie seu usuário e senha"
        Write-Host '       (só letras minúsculas, sem espaço; ANOTE a senha).'
        Write-Host '    3. Abra o PowerShell como administrador e rode este script de novo.'
        exit 0
    }

    Executar 'wsl --update (atualiza o WSL)' { wsl.exe --update | Out-Null }
    Executar 'wsl --set-default-version 2' { wsl.exe --set-default-version 2 | Out-Null }

    $versoes = Rodar-Wsl --list --verbose
    $linha = ($versoes -split "`r?`n") | Where-Object { $_ -match [regex]::Escape($Distro) } | Select-Object -First 1
    if ($linha -and $linha -match '\s1\s*$') {
        Executar "converter $Distro para WSL 2" { wsl.exe --set-version $Distro 2 }
    } else {
        Write-Host "    $Distro já está no WSL 2."
    }

    # Com o Ubuntu como padrão, o Docker Desktop liga a integração sozinho.
    Executar "deixar $Distro como distribuição padrão do WSL" { wsl.exe --set-default $Distro | Out-Null }

    if (-not $SoMostrar -and -not (Ubuntu-Pronto)) {
        Avisar "o $Distro ainda não tem usuário. Abra '$Distro' no menu Iniciar, crie usuário e senha e rode este script de novo."
        exit 0
    }
}

# -----------------------------------------------------------------------------
# 3. Docker Desktop e VS Code
# -----------------------------------------------------------------------------
function Instalar-ComWinget([string]$Id, [string]$Nome) {
    $ErrorActionPreference = 'Continue'
    & winget.exe list -e --id $Id --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    $Nome já instalado."
        return
    }
    Executar "winget install $Id" {
        & winget.exe install -e --id $Id --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { Avisar "o winget não conseguiu instalar o $Nome. Instale pelo site oficial." }
    }
}

function Instalar-Programas {
    Informar '3/4 Docker Desktop e VS Code'
    if ($SemDocker -and $SemVSCode) {
        Write-Host '    Pulado (-SemDocker -SemVSCode).'
        return
    }
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        Avisar 'o winget não foi encontrado.'
        Write-Host '    Instale o "Instalador de Aplicativo" (App Installer) pela Microsoft Store e rode de novo,'
        Write-Host '    ou instale o Docker Desktop e o VS Code pelos sites oficiais.'
        return
    }
    if (-not $SemDocker) {
        Instalar-ComWinget 'Docker.DockerDesktop' 'Docker Desktop'
        Write-Host '    Depois, abra o Docker Desktop, aceite os termos e confira em'
        Write-Host "    Settings > Resources > WSL integration se o $Distro está ligado."
    }
    if (-not $SemVSCode) {
        Instalar-ComWinget 'Microsoft.VisualStudioCode' 'VS Code'
    }
}

# -----------------------------------------------------------------------------
# 4. Repositório dentro do Ubuntu + instalar.sh
# -----------------------------------------------------------------------------
function Rodar-InstaladorNoUbuntu {
    $ErrorActionPreference = 'Continue'
    Informar "4/4 Copiando o repositório para o $Distro e rodando instalacao/instalar.sh"

    if (-not (Test-Path (Join-Path $PastaRepositorio 'instalacao\instalar.sh'))) {
        Falhar "não achei instalacao\instalar.sh em $PastaRepositorio. Rode o script de dentro da pasta do repositório."
    }

    # Caminho da pasta do Windows visto de dentro do Ubuntu (ex.: /mnt/c/Users/...).
    $caminhoWindows = $PastaRepositorio -replace '\\', '/'
    $origem = Rodar-Wsl -d $Distro -- wslpath -a "$caminhoWindows"
    Write-Host "    Origem: $PastaRepositorio"
    Write-Host "    Destino no Ubuntu: $PastaNoUbuntu (trabalhar dentro do Ubuntu é bem mais rápido)"

    # Só copia se a pasta ainda não existir: nunca sobrescreve o que você já tem lá.
    $copiar = "if [ -e $PastaNoUbuntu ]; then echo '    A pasta $PastaNoUbuntu já existe no Ubuntu; usando ela.'; " +
              "else mkdir -p $PastaNoUbuntu && cp -a '$origem'/. $PastaNoUbuntu/ && echo '    Copiado.'; fi"
    Executar "copiar o repositório para $PastaNoUbuntu" { wsl.exe -d $Distro -- bash -c $copiar }

    $opcoes = ''
    if ($SemDocker) { $opcoes = ' --sem-docker' }
    Write-Host '    O Ubuntu vai pedir a SUA SENHA do Ubuntu (a que você criou). Nada aparece ao digitar.'
    Executar "bash instalacao/instalar.sh$opcoes (no Ubuntu)" {
        wsl.exe -d $Distro -- bash -c "cd $PastaNoUbuntu && bash instalacao/instalar.sh$opcoes"
        if ($LASTEXITCODE -ne 0) {
            Falhar "o instalar.sh terminou com erro. Veja o registro em $PastaNoUbuntu/instalacao/instalar.log"
        }
    }
}

# -----------------------------------------------------------------------------
Write-Host '============================================================'
Write-Host ' Instalador do Tutorial de Bioinformática (Windows)'
if ($SoMostrar) { Write-Host ' Modo -SoMostrar: nada será instalado.' -ForegroundColor Yellow }
Write-Host '============================================================'

if (-not $SoMostrar) { Conferir-Administrador }
Conferir-Windows
Conferir-Virtualizacao
Instalar-Wsl
Instalar-Programas
Rodar-InstaladorNoUbuntu

Informar 'Pronto!'
Write-Host "    Abra o '$Distro' no menu Iniciar e rode:"
Write-Host "        cd $PastaNoUbuntu"
Write-Host '        bash instalacao/verificar.sh'
