# ============================================================
#  AUTOINSTALADOR 100NOME — Windows
#  Copyright (C) 2026  João Frade
#  Licenciado sob a GNU General Public License v3.0
#  https://100nome.netlify.app
# ============================================================

#Requires -Version 5.1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ── Constantes ───────────────────────────────────────────────
$SCRIPT_VERSION     = "2.0"
$SP_FOLDER          = "_100NOME"
$PACK_START         = "Pacote 100Nome"
$PACK_DEFAULT       = "pacote normal"
$FILE_NOTES         = "NOTAS.html"
$FILE_HELP          = "INSTALAR.html"
$FILE_CONFIG        = ".autoinstalacao"
$BACKUP_PATH        = "$SP_FOLDER\original"
$BACKUP_PARTIAL     = " - parcial"
$SITE_BASE          = "https://100nome.netlify.app"
$DISCORD_URL        = "https://discord.gg/Xv7ax2VkEp"

# ── Variáveis de estado ───────────────────────────────────────
$gameName           = ""
$fileName           = ""
$baseUpLevels       = 0
$expectedFiles      = ""
$expectedDirs       = ""
$filesForRemoval    = ""
$urlEnd             = ""
$trLicenseFileName  = ""
$packName           = ""
$exeDir             = ""
$gameDir            = ""
$packList           = @()
$dirsToSearch       = @("C:\", "C:\Program Files", "C:\Program Files (x86)",
                        "C:\Games", "D:\", "D:\Games", "D:\SteamLibrary",
                        "C:\Users\$env:USERNAME\AppData\Local",
                        "$env:ProgramFiles\Steam\steamapps\common",
                        "${env:ProgramFiles(x86)}\Steam\steamapps\common")
$installed          = $false
$postInstallNote    = ""
$installCmd         = ""
$revertCmd          = ""
$revertNote         = ""
$errorLog           = @()
$SCRIPT_DIR         = ""


# ════════════════════════════════════════════════════════════
#  UTILITÁRIOS DE APRESENTAÇÃO
# ════════════════════════════════════════════════════════════

function Write-Hr {
    param([string]$Color = "DarkGray")
    Write-Host ("  " + ("─" * 58)) -ForegroundColor $Color
}

function Write-Gap { Write-Host "" }

function Write-Section {
    param([string]$Title)
    Write-Gap
    Write-Hr "DarkYellow"
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Hr "DarkYellow"
    Write-Gap
}

function Write-Ok   { param([string]$msg) Write-Host "  " -NoNewline; Write-Host "✔" -ForegroundColor Green -NoNewline; Write-Host "  $msg" }
function Write-Warn { param([string]$msg) Write-Host "  " -NoNewline; Write-Host "⚠" -ForegroundColor Yellow -NoNewline; Write-Host "  $msg" }
function Write-Err  { param([string]$msg) Write-Host "  " -NoNewline; Write-Host "✘" -ForegroundColor Red -NoNewline; Write-Host "  $msg" -ForegroundColor White }
function Write-Info { param([string]$msg) Write-Host "  " -NoNewline; Write-Host "›" -ForegroundColor Cyan -NoNewline; Write-Host "  $msg" }
function Write-Gray { param([string]$msg) Write-Host "  $msg" -ForegroundColor DarkGray }

function Write-HighlightBox {
    param([string]$Label, [string]$Value)
    if ($Label) { Write-Host "  $Label" -ForegroundColor DarkGray }
    Write-Host "  $Value" -ForegroundColor Cyan
}

function Write-BoxYellow {
    param([string]$Line1, [string]$Line2 = "")
    Write-Gap
    Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║  $($Line1.PadRight(51))║" -ForegroundColor Yellow
    if ($Line2) {
        Write-Host "  ║  $($Line2.PadRight(51))║" -ForegroundColor Yellow
    }
    Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Gap
}

function Write-Prompt {
    param([string]$Label)
    Write-Host "  $Label" -ForegroundColor DarkYellow
    Write-Host -NoNewline "  "
    Write-Host -NoNewline "› " -ForegroundColor Yellow
    return Read-Host
}

function Press-AnyKey {
    Write-Gap
    Write-Host "  Prima qualquer tecla para continuar..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


# ════════════════════════════════════════════════════════════
#  ECRÃ INICIAL
# ════════════════════════════════════════════════════════════

function Draw-Header {
    Clear-Host
    $lines = @(
        "   ██╗ ██████╗  ██████╗ ███╗   ██╗ ██████╗ ███╗   ███╗███████╗",
        "  ███║██╔═████╗██╔═████╗████╗  ██║██╔═══██╗████╗ ████║██╔════╝",
        "  ╚██║██║██╔██║██║██╔██║██╔██╗ ██║██║   ██║██╔████╔██║█████╗  ",
        "   ██║████╔╝██║████╔╝██║██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══╝  ",
        "   ██║╚██████╔╝╚██████╔╝██║ ╚████║╚██████╔╝██║ ╚═╝ ██║███████╗",
        "   ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝"
    )
    Write-Host ""
    foreach ($line in $lines) {
        Write-Host "  $line" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 40
    }
    Write-Host ""
    $left  = "  Traduções PT-PT desde 2012"
    $right = "v$SCRIPT_VERSION"
    Write-Host ($left.PadRight(52) + $right) -ForegroundColor DarkYellow
    Write-Gap
    Write-Hr
    $copy  = "  Copyright (C) 2024  João Frade"
    $lic   = "GNU GPL v3.0"
    Write-Host ($copy.PadRight(52) + $lic) -ForegroundColor DarkGray
    Write-Hr
    Write-Gap
}

function Draw-HeaderCompact {
    Clear-Host
    Write-Host ""
    Write-Hr "DarkYellow"
    Write-Host "  " -NoNewline
    Write-Host "100NOME" -ForegroundColor Yellow -NoNewline
    Write-Host " — Autoinstalador" -ForegroundColor DarkYellow -NoNewline
    Write-Host "  v$SCRIPT_VERSION" -ForegroundColor DarkGray
    Write-Hr "DarkYellow"
    Write-Gap
}


# ════════════════════════════════════════════════════════════
#  CARREGAMENTO DE CONFIGURAÇÃO
# ════════════════════════════════════════════════════════════

function Load-Variables {
    $configFile = Join-Path $SCRIPT_DIR $FILE_CONFIG
    if (-not (Test-Path $configFile)) {
        Write-Err "Ficheiro de configuração '$FILE_CONFIG' não encontrado."
        return $false
    }
    foreach ($line in (Get-Content $configFile -Encoding UTF8)) {
        $line = $line.Trim()
        if (-not $line -or $line.StartsWith(";")) { continue }
        $parts = $line -split " ", 2
        if ($parts.Count -eq 2) {
            Set-Variable -Name $parts[0].Trim() -Value $parts[1].Trim() -Scope Script
        }
    }
    foreach ($var in @("gameName", "urlEnd")) {
        if (-not (Get-Variable -Name $var -Scope Script -ValueOnly -ErrorAction SilentlyContinue)) {
            Write-Err "Configuração obrigatória ausente: '$var'"
            return $false
        }
    }
    return $true
}

function Load-PackVariables {
    $configFile = Join-Path $SCRIPT_DIR "$packName\$FILE_CONFIG"
    if (-not (Test-Path $configFile)) {
        Write-Err "Configuração do pacote não encontrada."
        return $false
    }
    foreach ($line in (Get-Content $configFile -Encoding UTF8)) {
        $line = $line.Trim()
        if (-not $line -or $line.StartsWith(";")) { continue }
        # Campos de texto livre
        foreach ($key in @("postInstallNote","installCmd","revertCmd","revertNote")) {
            if ($line.StartsWith("$key ")) {
                Set-Variable -Name $key -Value $line.Substring($key.Length + 1) -Scope Script
                continue
            }
        }
        $parts = $line -split " ", 2
        if ($parts.Count -ge 1) {
            $val = if ($parts.Count -eq 2) { $parts[1].Trim() } else { "" }
            Set-Variable -Name $parts[0].Trim() -Value $val -Scope Script
        }
    }
    $required = @("fileName","baseUpLevels","expectedFiles","expectedDirs","filesForRemoval","trLicenseFileName")
    foreach ($var in $required) {
        if ($null -eq (Get-Variable -Name $var -Scope Script -ValueOnly -ErrorAction SilentlyContinue)) {
            Write-Err "Campo obrigatório ausente no pacote: '$var'"
            return $false
        }
    }
    return $true
}


# ════════════════════════════════════════════════════════════
#  SELEÇÃO DE PACOTE
# ════════════════════════════════════════════════════════════

function List-Packs {
    $script:packList = @()
    Get-ChildItem -Path $SCRIPT_DIR -Directory | Where-Object {
        $_.Name.StartsWith($PACK_START) -and
        (Test-Path (Join-Path $_.FullName $FILE_CONFIG))
    } | ForEach-Object { $script:packList += $_.Name }
    return $script:packList.Count -gt 0
}

function Pack-Choice {
    $count = $script:packList.Count
    Write-Section "PACOTE DE TRADUÇÃO"

    if ($count -eq 1) {
        $label = $script:packList[0].Substring([Math]::Min($PACK_START.Length + 1, $script:packList[0].Length))
        if (-not $label) { $label = $PACK_DEFAULT }
        Write-Info "Jogo: $gameName"
        if ($label -ne $PACK_DEFAULT) { Write-Info "Pacote: $label" }
        Write-Gap
        Press-AnyKey
        $script:packName = $script:packList[0]
        return $true
    }

    Write-Host "  Estão disponíveis $count pacotes para ${gameName}:" -ForegroundColor White
    Write-Gap
    for ($i = 0; $i -lt $count; $i++) {
        $label = $script:packList[$i].Substring([Math]::Min($PACK_START.Length + 1, $script:packList[$i].Length))
        if (-not $label) { $label = $PACK_DEFAULT }
        Write-Host "  " -NoNewline
        Write-Host "[$($i+1)]" -ForegroundColor Yellow -NoNewline
        Write-Host "  $label"
    }
    Write-Gap
    Write-Gray "Verifica a versão do teu jogo e escolhe o pacote correspondente."
    Write-Gap
    $choice = Write-Prompt "Número do pacote:"

    if ($choice -notmatch '^\d+$' -or [int]$choice -lt 1 -or [int]$choice -gt $count) {
        Write-Err "Opção inválida."
        return $false
    }
    $script:packName = $script:packList[[int]$choice - 1]
    $label = $script:packName.Substring([Math]::Min($PACK_START.Length + 1, $script:packName.Length))
    if (-not $label) { $label = $PACK_DEFAULT }
    Write-Gap
    Write-Ok "Pacote selecionado: $label"
    Write-Gap
    return $true
}


# ════════════════════════════════════════════════════════════
#  PESQUISA DO JOGO
# ════════════════════════════════════════════════════════════

function Verify-GameDir {
    param([string]$Base)
    $ok = $true
    foreach ($file in ($expectedFiles -split " ")) {
        if (-not $file) { continue }
        $path = Join-Path $Base $file
        if (Test-Path $path -PathType Leaf) {
            Write-Ok "$file"
            $script:errorLog += "  ENCONTRADO (ficheiro): $path"
        } else {
            Write-Err "$file — não encontrado"
            $script:errorLog += "  NÃO ENCONTRADO (ficheiro): $path"
            $ok = $false
        }
    }
    foreach ($dir in ($expectedDirs -split " ")) {
        if (-not $dir) { continue }
        $path = Join-Path $Base $dir
        if (Test-Path $path -PathType Container) {
            Write-Ok "$dir\"
            $script:errorLog += "  ENCONTRADO (pasta): $path"
        } else {
            Write-Err "$dir\ — não encontrado"
            $script:errorLog += "  NÃO ENCONTRADO (pasta): $path"
            $ok = $false
        }
    }
    return $ok
}

function Search-InPath {
    param([string]$SearchRoot, [string]$Context = "instalar")

    $foundFiles = @()
    try {
        $foundFiles = Get-ChildItem -Path $SearchRoot -Filter $fileName -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
    } catch { return $false }

    if ($foundFiles.Count -eq 0) { return $false }

    foreach ($foundFile in $foundFiles) {
        $foundExeDir = Split-Path $foundFile -Parent
        $base = $foundExeDir
        for ($l = 0; $l -lt [int]$baseUpLevels; $l++) {
            $base = Split-Path $base -Parent
        }
        $base = $base.TrimEnd("\") + "\"

        $script:errorLog += "Executável encontrado: $foundFile"
        if ([int]$baseUpLevels -gt 0) {
            $script:errorLog += "  baseUpLevels=$baseUpLevels → pasta base resolvida: $base"
        }

        Write-Section "DIRETÓRIO ENCONTRADO"
        Write-HighlightBox "Executável:" $foundFile
        if ([int]$baseUpLevels -gt 0) { Write-Gray "  ($baseUpLevels nível(is) acima → $base)" }
        Write-Gap
        Write-Gray "A verificar ficheiros e pastas esperados..."
        Write-Gap

        if (Verify-GameDir $base) {
            Write-Gap
            Write-Ok "Todos os ficheiros verificados."
            Write-Gap
            if ($Context -eq "desinstalar") {
                Write-HighlightBox "Desinstalar em:" $base
                Write-Gap
                Write-Host "  " -NoNewline; Write-Host "[S]" -ForegroundColor Yellow -NoNewline; Write-Host "  Desinstalar aqui"
            } else {
                Write-HighlightBox "Instalar em:" $base
                Write-Gap
                Write-Host "  " -NoNewline; Write-Host "[S]" -ForegroundColor Yellow -NoNewline; Write-Host "  Instalar aqui"
            }
            Write-Host "  " -NoNewline; Write-Host "[N]" -ForegroundColor Yellow -NoNewline; Write-Host "  Continuar pesquisa"
            Write-Host "  " -NoNewline; Write-Host "[X]" -ForegroundColor Yellow -NoNewline; Write-Host "  Cancelar"
            Write-Gap
            $choice = (Write-Prompt "Opção:").ToLower()

            switch ($choice) {
                "s" {
                    $script:exeDir  = $foundExeDir + "\"
                    $script:gameDir = $base
                    return $true
                }
                "n" { Write-Gray "A continuar pesquisa..."; Write-Gap }
                default { exit 0 }
            }
        } else {
            Write-Gap
            Write-Warn "Este diretório não parece correto — a continuar pesquisa..."
            Write-Gap
        }
    }
    return $false
}

function Search-Units {
    param([string]$Context = "instalar")

    Write-Section "PESQUISA AUTOMÁTICA"
    Write-Info "À procura de: $gameName"
    Write-Gap

    foreach ($path in $dirsToSearch) {
        if (-not (Test-Path $path -PathType Container)) { continue }
        Write-Gray "A pesquisar em: $path"
        $script:errorLog += "Pesquisado: $path"
        if (Search-InPath $path $Context) { return $true }
    }
    return $false
}


# ════════════════════════════════════════════════════════════
#  CÓPIA DE SEGURANÇA
# ════════════════════════════════════════════════════════════

function Get-BackupDir {
    $dir = Join-Path $gameDir $BACKUP_PATH
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

function Move-ToBackup {
    param([string]$Src, [string]$Dst)
    $dstDir = Split-Path $Dst -Parent
    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    if (-not (Test-Path $Dst)) {
        Move-Item $Src $Dst
        Write-Ok "Guardado: $(Split-Path $Src -Leaf)"
    } else {
        Write-Warn "Cópia já existe — ignorado: $(Split-Path $Src -Leaf)"
    }
}

function Create-Backup {
    $backupDir = Get-BackupDir
    Write-Section "CÓPIA DE SEGURANÇA"
    Write-Info "A salvaguardar ficheiros originais do jogo antes de instalar."
    Write-HighlightBox "Destino:" $backupDir
    Write-Gap

    $packPath = Join-Path $SCRIPT_DIR $packName
    $manifest = Join-Path $backupDir ".manifesto_instalacao"
    $manifestLines = @()
    $foundAny = $false

    $packFiles = Get-ChildItem -Path $packPath -Recurse -File -ErrorAction SilentlyContinue
    foreach ($f in $packFiles) {
        $rel = $f.FullName.Substring($packPath.Length).TrimStart("\")
        if ($rel.StartsWith($SP_FOLDER) -or $rel.StartsWith(".auto")) { continue }
        $manifestLines += "file:$rel"
        $original = Join-Path ($gameDir.TrimEnd("\")) $rel
        if (Test-Path $original -PathType Leaf) {
            $foundAny = $true
            $dst = Join-Path $backupDir $rel
            Move-ToBackup $original $dst
        }
    }

    if ($revertCmd)  { $manifestLines += "revertCmd:$revertCmd" }
    if ($revertNote) { $manifestLines += "revertNote:$revertNote" }
    $manifestLines | Set-Content $manifest -Encoding UTF8

    # Salvaguarda ficheiros a remover
    Backup-RemovalFiles $backupDir

    if (-not $foundAny) {
        Write-Gray "Nenhum ficheiro original encontrado — o jogo ainda não tinha tradução."
        Write-Gray "O manifesto foi guardado para permitir reversão futura."
    }
}

function Backup-RemovalFiles {
    param([string]$BackupDir)
    if (-not $filesForRemoval) { return }
    Write-Info "A remover ficheiros conflituantes..."
    Write-Gap
    foreach ($file in ($filesForRemoval -split " ")) {
        if (-not $file) { continue }
        $target = Join-Path ($gameDir.TrimEnd("\")) $file
        if (Test-Path $target -PathType Leaf) {
            $dst = Join-Path $BackupDir $file
            Move-ToBackup $target $dst
        }
    }
}

function Check-Backup {
    $backupDir = Join-Path $gameDir $BACKUP_PATH

    if (-not (Test-Path $backupDir -PathType Container)) {
        Create-Backup
        return
    }

    Write-Section "ATUALIZAÇÃO DE TRADUÇÃO"
    Write-Info "Já existe uma cópia dos ficheiros originais."
    Write-Gray "A cópia original será preservada. Apenas os ficheiros de"
    Write-Gray "tradução serão atualizados."
    Write-Gap

    $manifest = Join-Path $backupDir ".manifesto_instalacao"
    $packPath = Join-Path $SCRIPT_DIR $packName
    $manifestLines = @()

    $packFiles = Get-ChildItem -Path $packPath -Recurse -File -ErrorAction SilentlyContinue
    foreach ($f in $packFiles) {
        $rel = $f.FullName.Substring($packPath.Length).TrimStart("\")
        if ($rel.StartsWith($SP_FOLDER) -or $rel.StartsWith(".auto")) { continue }
        $manifestLines += "file:$rel"
    }
    if ($revertCmd)  { $manifestLines += "revertCmd:$revertCmd" }
    if ($revertNote) { $manifestLines += "revertNote:$revertNote" }
    $manifestLines | Set-Content $manifest -Encoding UTF8

    Write-Ok "Manifesto atualizado."
    Write-Gap
    Write-Host "  " -NoNewline; Write-Host "[S]" -ForegroundColor Yellow -NoNewline; Write-Host "  Continuar com a instalação"
    Write-Host "  " -NoNewline; Write-Host "[X]" -ForegroundColor Yellow -NoNewline; Write-Host "  Cancelar"
    Write-Gap
    $choice = (Write-Prompt "Opção:").ToLower()
    if ($choice -ne "s") { exit 0 }
}


# ════════════════════════════════════════════════════════════
#  REVERSÃO / RESTAURO
# ════════════════════════════════════════════════════════════

function Restore-Backup {
    $backupDir = Join-Path $gameDir $BACKUP_PATH
    $gamePath  = $gameDir.TrimEnd("\")

    if (-not (Test-Path $backupDir -PathType Container)) {
        Write-Err "Nenhuma cópia de segurança encontrada."
        Write-Gray "Não é possível reverter sem cópia de segurança."
        Write-Gap
        Press-AnyKey
        return $false
    }

    $manifest = Join-Path $backupDir ".manifesto_instalacao"

    # Lê revertCmd e revertNote do manifesto
    $_revertCmd = ""; $_revertNote = ""
    if (Test-Path $manifest) {
        foreach ($mline in (Get-Content $manifest -Encoding UTF8)) {
            if ($mline.StartsWith("revertCmd:"))  { $_revertCmd  = $mline.Substring(10) }
            if ($mline.StartsWith("revertNote:")) { $_revertNote = $mline.Substring(11) }
        }
    }
    if (-not $_revertCmd  -and $revertCmd)  { $_revertCmd  = $revertCmd }
    if (-not $_revertNote -and $revertNote) { $_revertNote = $revertNote }

    Write-Section "REVERSÃO — CONFIRMAÇÃO"
    Write-HighlightBox "Cópia original:" $backupDir
    Write-Gap
    Write-Warn "Este processo irá:"
    Write-Host "    1. Remover todos os ficheiros instalados pela tradução" -ForegroundColor DarkGray
    Write-Host "    2. Restaurar os ficheiros originais do jogo" -ForegroundColor DarkGray
    if ($_revertCmd) { Write-Host "    3. Executar: $_revertCmd" -ForegroundColor DarkGray }
    Write-Gap
    Write-Host "  " -NoNewline; Write-Host "[S]" -ForegroundColor Yellow -NoNewline; Write-Host "  Confirmar reversão"
    Write-Host "  " -NoNewline; Write-Host "[X]" -ForegroundColor Yellow -NoNewline; Write-Host "  Cancelar"
    Write-Gap
    $choice = (Write-Prompt "Opção:").ToLower()
    if ($choice -ne "s") { return $true }

    Write-Section "A REVERTER..."
    $removed = 0; $restored = 0; $errors = 0

    # Passo 1: remove ficheiros instalados via manifesto
    if (Test-Path $manifest) {
        Write-Info "A remover ficheiros da tradução..."
        Write-Gap
        $fileLines = Get-Content $manifest -Encoding UTF8 | Where-Object { $_.StartsWith("file:") }
        foreach ($mline in $fileLines) {
            $rel = $mline.Substring(5)
            $target = Join-Path $gamePath $rel
            if (Test-Path $target -PathType Leaf) {
                try {
                    Remove-Item $target -Force
                    Write-Ok "Removido: $(Split-Path $rel -Leaf)"
                    $removed++
                } catch {
                    Write-Err "Erro ao remover: $rel"
                    $errors++
                }
            }
        }
        # Remove pastas vazias (de baixo para cima)
        $dirs = $fileLines | ForEach-Object {
            Split-Path (Join-Path $gamePath $_.Substring(5)) -Parent
        } | Select-Object -Unique | Sort-Object -Descending
        foreach ($dir in $dirs) {
            if ($dir -ne $gamePath -and (Test-Path $dir) -and
                (Get-ChildItem $dir -Force).Count -eq 0) {
                Remove-Item $dir -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Gap
    } else {
        Write-Warn "Manifesto não encontrado — apenas os ficheiros originais serão restaurados."
        Write-Gap
    }

    # Passo 2: restaura originais
    Write-Info "A restaurar ficheiros originais..."
    Write-Gap
    $backupFiles = Get-ChildItem -Path $backupDir -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne ".manifesto_instalacao" }
    foreach ($bf in $backupFiles) {
        $rel    = $bf.FullName.Substring($backupDir.Length).TrimStart("\")
        $target = Join-Path $gamePath $rel
        $targetDir = Split-Path $target -Parent
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        try {
            Move-Item $bf.FullName $target -Force
            Write-Ok "Restaurado: $(Split-Path $rel -Leaf)"
            $restored++
        } catch {
            Write-Err "Erro ao restaurar: $rel"
            $errors++
        }
    }

    Write-Gap
    Write-Hr "DarkYellow"
    Write-Gap
    Write-Info "Removidos:   $removed ficheiro(s) da tradução"
    Write-Info "Restaurados: $restored ficheiro(s) original(is)"
    if ($errors -gt 0) { Write-Err "Erros: $errors" }
    Write-Gap

    if ($errors -eq 0) {
        Write-Ok "Reversão concluída com sucesso."
        Remove-Item $backupDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Warn "Reversão concluída com erros. Verifica o estado do jogo."
    }

    # Passo 3: revertCmd com fallback para revertNote
    if ($_revertCmd) {
        Write-Gap
        Write-Hr "DarkYellow"
        Write-Info "A executar comando de reversão..."
        Write-Gray "  > $_revertCmd"
        Write-Gap
        try {
            $out = cmd /c "cd /d `"$gamePath`" && $_revertCmd" 2>&1
            Write-Ok "Comando executado com sucesso."
            if ($out) { Write-Gray $out }
        } catch {
            Write-Warn "O comando de reversão falhou: $_"
            if ($_revertNote) {
                Write-BoxYellow "⚠  AÇÃO MANUAL NECESSÁRIA" $_revertNote
            } else {
                Write-Gray "Sem instruções manuais — verifica o estado do jogo."
            }
        }
    } elseif ($_revertNote) {
        Write-BoxYellow "⚠  AÇÃO MANUAL NECESSÁRIA" $_revertNote
    }

    Write-Gap
    Press-AnyKey
    return $true
}


# ════════════════════════════════════════════════════════════
#  INSTALAÇÃO
# ════════════════════════════════════════════════════════════

function Copy-Files {
    Write-Section "A INSTALAR"
    Write-HighlightBox "Origem:"  (Join-Path $SCRIPT_DIR $packName)
    Write-Gap
    Write-HighlightBox "Destino:" $gameDir
    Write-Gap
    Write-Info "A copiar ficheiros..."
    Write-Gap

    $packPath = Join-Path $SCRIPT_DIR $packName
    $packFiles = Get-ChildItem -Path $packPath -Recurse -File -ErrorAction SilentlyContinue
    $ok = $true
    foreach ($f in $packFiles) {
        $rel = $f.FullName.Substring($packPath.Length).TrimStart("\")
        if ($rel.StartsWith($SP_FOLDER) -or $rel.StartsWith(".auto")) { continue }
        $dst = Join-Path ($gameDir.TrimEnd("\")) $rel
        $dstDir = Split-Path $dst -Parent
        try {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            Copy-Item $f.FullName $dst -Force
        } catch {
            Write-Err "Erro ao copiar: $rel"
            $ok = $false
        }
    }

    if ($ok) {
        Write-Ok "Ficheiros copiados com sucesso!"
        $script:installed = $true
    } else {
        Write-Err "Ocorreu um erro durante a cópia de ficheiros."
        Write-Gray "Verifica as permissões do diretório do jogo."
        $script:installed = $false
        return
    }

    # installCmd com fallback para postInstallNote
    if ($installCmd) {
        Write-Gap
        Write-Info "A configurar o jogo..."
        Write-Gray "  > $installCmd"
        Write-Gap
        try {
            $out = cmd /c "cd /d `"$($gameDir.TrimEnd('\'))`" && $installCmd" 2>&1
            $rc = $LASTEXITCODE
            if ($rc -eq 0) {
                Write-Ok "Configuração aplicada com sucesso."
                if ($out) { Write-Gray $out }
                $script:postInstallNote = ""   # não é necessário mostrar fallback
            } else {
                Write-Warn "A configuração automática falhou (código $rc)."
                if ($out) { Write-Gray "  Erro: $out" }
            }
        } catch {
            Write-Warn "A configuração automática falhou: $_"
        }
    }
}


# ════════════════════════════════════════════════════════════
#  DESINSTALAÇÃO
# ════════════════════════════════════════════════════════════

function Uninstall-Flow {
    if (-not (List-Packs))       { Fatal-NoPacks;   return }
    if (-not (Pack-Choice))      { return }
    if (-not (Load-PackVariables)) { Fatal-PackError; return }

    Write-Section "DESINSTALAR TRADUÇÃO"
    Write-Info "Jogo: $gameName"
    Write-Gray "Vai pesquisar o jogo da mesma forma que a instalação."
    Write-Gap

    if ($exeDir) {
        $base = $exeDir.TrimEnd("\")
        for ($l = 0; $l -lt [int]$baseUpLevels; $l++) { $base = Split-Path $base -Parent }
        $script:gameDir = $base.TrimEnd("\") + "\"
    } else {
        Write-Host "  " -NoNewline; Write-Host "[S]" -ForegroundColor Yellow -NoNewline; Write-Host "  Pesquisar automaticamente"
        Write-Host "  " -NoNewline; Write-Host "[X]" -ForegroundColor Yellow -NoNewline; Write-Host "  Cancelar"
        Write-Gap
        $choice = (Write-Prompt "Opção:").ToLower()
        if ($choice -ne "s") { return }
        if (-not (Search-Units "desinstalar")) {
            Write-Section "JOGO NÃO ENCONTRADO"
            Write-Err "$gameName não foi encontrado."
            Write-Gap; Press-AnyKey; return
        }
    }

    $backupDir = Join-Path $gameDir $BACKUP_PATH
    if (-not (Test-Path $backupDir -PathType Container)) {
        Write-Section "SEM CÓPIA DE SEGURANÇA"
        Write-Warn "Não foi encontrada cópia de segurança para $gameName."
        Write-Gap
        Write-Gray "Sem cópia de segurança não é possível restaurar os ficheiros"
        Write-Gray "originais — apenas os ficheiros de tradução serão removidos."
        Write-Gap
        Write-Host "  " -NoNewline; Write-Host "[S]" -ForegroundColor Yellow -NoNewline; Write-Host "  Remover ficheiros de tradução mesmo assim"
        Write-Host "  " -NoNewline; Write-Host "[X]" -ForegroundColor Yellow -NoNewline; Write-Host "  Cancelar"
        Write-Gap
        $choice = (Write-Prompt "Opção:").ToLower()
        if ($choice -eq "s") { Uninstall-FilesOnly }
        return
    }
    Restore-Backup | Out-Null
}

function Uninstall-FilesOnly {
    Write-Section "A REMOVER FICHEIROS DE TRADUÇÃO..."
    $gamePath = $gameDir.TrimEnd("\")
    $packPath = Join-Path $SCRIPT_DIR $packName
    $removed = 0; $errors = 0

    $packFiles = Get-ChildItem -Path $packPath -Recurse -File -ErrorAction SilentlyContinue
    foreach ($f in $packFiles) {
        $rel = $f.FullName.Substring($packPath.Length).TrimStart("\")
        if ($rel.StartsWith($SP_FOLDER) -or $rel.StartsWith(".auto")) { continue }
        $target = Join-Path $gamePath $rel
        if (Test-Path $target -PathType Leaf) {
            try { Remove-Item $target -Force; Write-Ok "Removido: $rel"; $removed++ }
            catch { Write-Err "Erro: $rel"; $errors++ }
        }
    }
    Write-Gap
    Write-Info "Removidos: $removed ficheiro(s)"
    if ($errors -gt 0) { Write-Err "Erros: $errors" }
    Write-Gap
    Press-AnyKey
}


# ════════════════════════════════════════════════════════════
#  MENU DE AJUDA / ERRO
# ════════════════════════════════════════════════════════════

function Generate-ErrorReport {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeName  = $gameName -replace " ", "_"
    $reportFile = Join-Path $SCRIPT_DIR "registo_erro_${safeName}_${timestamp}.txt"

    $os      = (Get-CimInstance Win32_OperatingSystem).Caption
    $psVer   = $PSVersionTable.PSVersion.ToString()
    $user    = $env:USERNAME
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $adminStr = if ($isAdmin) { "Administrador ⚠" } else { "utilizador normal" }

    $lines = @(
        "================================================================",
        "  REGISTO DE ERRO — 100Nome Autoinstalador (Windows)",
        "================================================================",
        "",
        "  Data:              $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "  Versão script:     $SCRIPT_VERSION",
        "",
        "  Jogo:              $gameName",
        "  Pacote:            $packName",
        "",
        "  Parâmetros do pacote (.autoinstalacao):",
        "    fileName:        $fileName",
        "    baseUpLevels:    $baseUpLevels",
        "    expectedFiles:   $expectedFiles",
        "    expectedDirs:    $expectedDirs",
        "    filesForRemoval: $filesForRemoval",
        "",
        "  Dir instalador:    $SCRIPT_DIR",
        "  Dir jogo:          $(if ($gameDir) { $gameDir } else { 'não encontrado' })",
        "",
        "  Sistema:           $os",
        "  PowerShell:        $psVer",
        "  Utilizador:        $user ($adminStr)",
        "",
        "----------------------------------------------------------------",
        "  DIRETÓRIOS PESQUISADOS",
        "----------------------------------------------------------------"
    )
    if ($errorLog.Count -gt 0) {
        $lines += $errorLog
    } else {
        $lines += "  (nenhum registo)"
    }
    $lines += @(
        "",
        "----------------------------------------------------------------",
        "  COMO OBTER AJUDA",
        "----------------------------------------------------------------",
        "",
        "  1. Junta este ficheiro à tua mensagem",
        "  2. Descreve o que aconteceu",
        "  3. Envia no Discord:",
        "",
        "  $DISCORD_URL",
        "",
        "================================================================"
    )
    $lines | Set-Content $reportFile -Encoding UTF8

    if (Test-Path $reportFile) {
        Write-Gap
        Write-Ok "Registo gerado:"
        Write-HighlightBox "" $reportFile
        Write-Gap
        Write-Gray "Anexa este ficheiro à tua mensagem no Discord."
        Write-Gap
    } else {
        Write-Err "Não foi possível criar o ficheiro de registo."
    }
}

function Menu-HelpError {
    while ($true) {
        Draw-HeaderCompact
        Write-Gap
        Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "  ║  ✘  ALGO CORREU MAL?                                 ║" -ForegroundColor Red
        Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Red
        Write-Gap
        if ($gameName) { Write-Info "Jogo: $gameName" }
        Write-Gap
        Write-Hr "DarkYellow"
        Write-Gap
        if (Test-Path (Join-Path $SCRIPT_DIR $FILE_HELP)) {
            Write-Host "  " -NoNewline; Write-Host "[A]" -ForegroundColor Yellow -NoNewline
            Write-Host "   Abrir instruções de instalação manual"
        }
        Write-Host "  " -NoNewline; Write-Host "[R]" -ForegroundColor Yellow -NoNewline
        Write-Host "   Gerar registo de erro  " -NoNewline; Write-Host "(para enviar no Discord)" -ForegroundColor DarkGray
        Write-Host "  " -NoNewline; Write-Host "[D]" -ForegroundColor Yellow -NoNewline
        Write-Host "   Abrir Discord do 100Nome"
        Write-Gap
        Write-Hr "DarkYellow"
        Write-Host "  " -NoNewline; Write-Host "[T]" -ForegroundColor Yellow -NoNewline; Write-Host "   Terminar"
        Write-Gap

        $choice = (Write-Prompt "Opção:").ToLower()
        switch ($choice) {
            "a" {
                $f = Join-Path $SCRIPT_DIR $FILE_HELP
                if (Test-Path $f) { Start-Process $f }
                else { Write-Warn "Ficheiro $FILE_HELP não encontrado." }
            }
            "r" { Generate-ErrorReport; Press-AnyKey }
            "d" { Write-Gray "A abrir o Discord do 100Nome..."; Start-Process $DISCORD_URL }
            "t" { Write-Gap; Write-Ok "Obrigado por usares o 100Nome."; Write-Gap; exit 1 }
            default { Write-Warn "Opção não reconhecida." }
        }
        Write-Gap
    }
}


# ════════════════════════════════════════════════════════════
#  ERROS FATAIS
# ════════════════════════════════════════════════════════════

function Fatal-ConfigError {
    Write-Section "ERRO DE CONFIGURAÇÃO"
    Write-Err "Não é possível continuar com a instalação."
    Write-Gap
    Write-Gray "Verifica se o pacote está completo e não está corrompido."
    Write-Gap
    Menu-HelpError
}

function Fatal-PackError {
    Write-Section "PACOTE CORROMPIDO"
    Write-Err "O pacote de tradução parece estar danificado."
    Write-Gap
    Write-Gray "Tenta descarregar o pacote novamente a partir do site."
    Write-Gap
    Menu-HelpError
}

function Fatal-NoPacks {
    Write-Section "NENHUM PACOTE ENCONTRADO"
    Write-Err "Não foi encontrado nenhum pacote de tradução válido."
    Write-Gap
    Write-Gray "Certifica-te de que:"
    Write-Host "    • Extraíste o ZIP por completo" -ForegroundColor DarkGray
    Write-Host "    • Este script se encontra na pasta extraída" -ForegroundColor DarkGray
    Write-Host "    • A pasta '$PACK_START...' está presente" -ForegroundColor DarkGray
    Write-Gap
    Menu-HelpError
}

function Fatal-GameNotFound {
    Write-Section "JOGO NÃO ENCONTRADO"
    Write-Err "$gameName não foi encontrado em nenhum diretório."
    Write-Gap
    Write-Gray "Verifica se o jogo está instalado e tenta novamente."
    Write-Gap
    Menu-HelpError
}


# ════════════════════════════════════════════════════════════
#  CONFIGURAÇÕES
# ════════════════════════════════════════════════════════════

function Show-Configs {
    while ($true) {
        Draw-HeaderCompact
        Write-Section "CONFIGURAÇÕES"
        Write-Host "  " -NoNewline; Write-Host "[LE]" -ForegroundColor Yellow -NoNewline
        Write-Host "  Definir localização manual do executável"
        if ($exeDir) { Write-HighlightBox "  Localização definida:" $exeDir }
        else { Write-Gray "  Pesquisa automática ativa." }
        Write-Gap
        Write-Hr "DarkYellow"
        Write-Host "  " -NoNewline; Write-Host "[V]" -ForegroundColor Yellow -NoNewline; Write-Host "   Voltar"
        Write-Gap

        $choice = (Write-Prompt "Opção:").ToLower()
        switch ($choice) {
            "le" {
                Write-Gap
                Write-Gray "Introduz o caminho completo da pasta do executável."
                Write-Gray "Deixa em branco para reativar a pesquisa automática."
                Write-Gap
                $loc = Write-Prompt "Localização:"
                if ($loc) {
                    $script:exeDir = $loc.TrimEnd("\") + "\"
                    Write-Ok "Localização definida: $($script:exeDir)"
                } else {
                    $script:exeDir = ""
                    Write-Ok "Pesquisa automática reativada."
                }
            }
            "v" { return }
            default { Write-Warn "Opção não reconhecida." }
        }
        Write-Gap
        Press-AnyKey
    }
}


# ════════════════════════════════════════════════════════════
#  MENU FINAL
# ════════════════════════════════════════════════════════════

function Draw-SuccessBanner {
    Write-Gap
    Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                                                      ║" -ForegroundColor Green
    Write-Host "  ║   ✔  TRADUÇÃO INSTALADA COM SUCESSO                  ║" -ForegroundColor Green
    Write-Host "  ║                                                      ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Gap
}

function End-Menu {
    Draw-HeaderCompact

    if ($installed) {
        Draw-SuccessBanner
        Write-Info "Jogo: $gameName"
        Write-Gap
        if ($postInstallNote) {
            if ($installCmd) {
                Write-BoxYellow "⚠  CONFIGURAÇÃO AUTOMÁTICA FALHOU" $postInstallNote
            } else {
                Write-BoxYellow "⚠  PASSO ADICIONAL NECESSÁRIO" $postInstallNote
            }
        }
    } else {
        Write-Section "INSTALAÇÃO INCOMPLETA"
        Write-Warn "A tradução pode não ter sido instalada corretamente."
        Write-Gap
    }

    Write-Hr "DarkYellow"
    Write-Gap
    Write-Host "  " -NoNewline; Write-Host "O QUE FAZER A SEGUIR:" -ForegroundColor DarkYellow
    Write-Gap

    $helpFile  = Join-Path $SCRIPT_DIR $FILE_HELP
    $notesFile = Join-Path $SCRIPT_DIR $FILE_NOTES
    $packNotes = if ($packName) { Join-Path $SCRIPT_DIR "$packName\$SP_FOLDER\$FILE_NOTES" } else { "" }
    $licFile   = if ($packName) { Join-Path $SCRIPT_DIR "$packName\$SP_FOLDER\$trLicenseFileName" } else { "" }
    $exeFile   = if ($exeDir)   { Join-Path $exeDir $fileName } else { "" }
    $backupDir = if ($gameDir)  { Join-Path $gameDir $BACKUP_PATH } else { "" }
    $hasBackup = $backupDir -and (Test-Path $backupDir -PathType Container)

    if (Test-Path $helpFile)  { Write-Host "  " -NoNewline; Write-Host "[A]" -ForegroundColor Yellow -NoNewline; Write-Host "   Abrir ficheiro de ajuda  "; Write-Host "  (INSTALAR.html)" -ForegroundColor DarkGray }
    if ((Test-Path $notesFile) -or (Test-Path $packNotes)) {
        Write-Host "  " -NoNewline; Write-Host "[N]" -ForegroundColor Yellow -NoNewline; Write-Host "   Notas da Tradução  "; Write-Host "  (versão, créditos)" -ForegroundColor DarkGray
    }
    if ($licFile -and (Test-Path $licFile)) {
        Write-Host "  " -NoNewline; Write-Host "[L]" -ForegroundColor Yellow -NoNewline; Write-Host "   Licença da Tradução"
    }
    if ($installed -and $gameDir -and (Test-Path $gameDir)) {
        Write-Host "  " -NoNewline; Write-Host "[P]" -ForegroundColor Yellow -NoNewline; Write-Host "   Abrir pasta do jogo"
    }
    if ($installed -and $exeFile -and (Test-Path $exeFile)) {
        Write-Host "  " -NoNewline; Write-Host "[J]" -ForegroundColor Yellow -NoNewline; Write-Host "   Iniciar jogo"
    }
    if ($hasBackup) {
        Write-Host "  " -NoNewline; Write-Host "[D]" -ForegroundColor Yellow -NoNewline
        Write-Host "   Desinstalar tradução  " -NoNewline; Write-Host "(restaurar originais)" -ForegroundColor DarkGray
    }

    Write-Gap
    Write-Hr "DarkYellow"
    Write-Host "  " -NoNewline; Write-Host "[H]" -ForegroundColor Yellow -NoNewline; Write-Host "   Ajuda / Reportar problema"
    Write-Host "  " -NoNewline; Write-Host "[T]" -ForegroundColor Yellow -NoNewline; Write-Host "   Terminar"
    Write-Gap
    Write-Hr "DarkYellow"
    Write-Gap

    while ($true) {
        $choice = (Write-Prompt "Opção:").ToLower()
        switch ($choice) {
            "a" { if (Test-Path $helpFile)  { Start-Process $helpFile } }
            "n" {
                if   (Test-Path $packNotes) { Start-Process $packNotes }
                elseif (Test-Path $notesFile) { Start-Process $notesFile }
            }
            "l" { if ($licFile -and (Test-Path $licFile)) { Start-Process $licFile } }
            "p" { if ($gameDir -and (Test-Path $gameDir)) { Start-Process $gameDir } }
            "j" {
                if ($exeFile -and (Test-Path $exeFile)) {
                    Write-Gap
                    Write-Info "A lançar $gameName..."
                    Write-Gray "Aguarda enquanto o jogo carrega. Este terminal voltará quando fechares o jogo."
                    Write-Gap
                    if ($urlEnd) { Start-Process "$SITE_BASE/$urlEnd" }
                    $proc = Start-Process $exeFile -PassThru
                    $proc.WaitForExit()
                    Write-Gap
                    Write-Hr
                    Write-Ok "Jogo fechado. De volta ao instalador."
                    Write-Gap
                    End-Menu; return
                }
            }
            "d" {
                if ($hasBackup -and $gameDir) {
                    Restore-Backup | Out-Null
                    End-Menu; return
                }
            }
            "h" { Menu-HelpError; End-Menu; return }
            "t" {
                Write-Gap
                if ($installed -and $urlEnd) {
                    Write-Gray "A abrir página do jogo no site 100Nome..."
                    Start-Process "$SITE_BASE/$urlEnd"
                }
                Write-Gap
                Write-Ok "Obrigado por usares o 100Nome. Boa sorte!"
                Write-Gap
                exit 0
            }
            default { Write-Warn "Opção não reconhecida." }
        }
        Write-Gap
    }
}


# ════════════════════════════════════════════════════════════
#  MENU PRINCIPAL
# ════════════════════════════════════════════════════════════

function Main-Menu {
    Draw-Header
    Write-Info "Jogo: $gameName"
    Write-Gap
    Write-Hr "DarkYellow"
    Write-Gap
    Write-Gray "Antes de avançar:"
    Write-Host "    1. Extrai o ZIP por completo" -ForegroundColor DarkGray
    Write-Host "    2. Executa este script a partir da pasta extraída" -ForegroundColor DarkGray
    Write-Gap
    Write-Hr "DarkYellow"
    Write-Gap
    Write-Host "  " -NoNewline; Write-Host "[A]" -ForegroundColor Yellow -NoNewline; Write-Host "   Instalar tradução"
    Write-Host "  " -NoNewline; Write-Host "[D]" -ForegroundColor Yellow -NoNewline; Write-Host "   Desinstalar tradução existente"
    Write-Host "  " -NoNewline; Write-Host "[CO]" -ForegroundColor Yellow -NoNewline; Write-Host "  Configurações"
    Write-Host "  " -NoNewline; Write-Host "[LI]" -ForegroundColor Yellow -NoNewline; Write-Host "  Licença do instalador"
    Write-Gap
    Write-Hr "DarkYellow"
    Write-Gap
}


# ════════════════════════════════════════════════════════════
#  PONTO DE ENTRADA
# ════════════════════════════════════════════════════════════

# Muda para o diretório do script
$script:SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $SCRIPT_DIR

# Carrega configuração base
if (-not (Load-Variables)) {
    Draw-HeaderCompact
    Fatal-ConfigError
}

# Loop do menu principal
while ($true) {
    Main-Menu
    $choice = (Write-Prompt "Opção:").ToLower()

    switch ($choice) {
        "li" { 
            Draw-HeaderCompact
            Write-Section "LICENÇA DO INSTALADOR"
            Write-Host @"

  GNU GENERAL PUBLIC LICENSE — Version 3, 29 June 2007

  Copyright (C) 2007 Free Software Foundation, Inc.
  Este programa é software livre: podes redistribuí-lo e/ou
  modificá-lo sob os termos da GNU General Public License
  publicada pela Free Software Foundation, versão 3 ou superior.

  Para mais detalhes consulta: https://www.gnu.org/licenses/
"@ -ForegroundColor DarkGray
            Press-AnyKey
        }
        "co" {
            Show-Configs
            if ($exeDir -and -not $gameDir) {
                $base = $exeDir.TrimEnd("\")
                for ($l = 0; $l -lt [int]$baseUpLevels; $l++) { $base = Split-Path $base -Parent }
                $script:gameDir = $base.TrimEnd("\") + "\"
            }
        }
        "d"  { Uninstall-Flow }
        "a"  { break }
        default { continue }
    }
    if ($choice -eq "a") { break }
}

# Seleção de pacote
if (-not (List-Packs))         { Fatal-NoPacks }
if (-not (Pack-Choice))        { Main; exit }
if (-not (Load-PackVariables)) { Fatal-PackError }

# Localização do jogo
Write-Section "LOCALIZAÇÃO DO JOGO"
Write-Info "Jogo: $gameName"
Write-Gap

if ($exeDir) {
    Write-HighlightBox "Localização definida manualmente:" $exeDir
    $base = $exeDir.TrimEnd("\")
    for ($l = 0; $l -lt [int]$baseUpLevels; $l++) { $base = Split-Path $base -Parent }
    $script:gameDir = $base.TrimEnd("\") + "\"
} else {
    Write-Host "  " -NoNewline; Write-Host "[S]" -ForegroundColor Yellow -NoNewline; Write-Host "  Pesquisar automaticamente"
    Write-Host "  " -NoNewline; Write-Host "[X]" -ForegroundColor Yellow -NoNewline; Write-Host "  Cancelar"
    Write-Gap
    $choice = (Write-Prompt "Opção:").ToLower()
    if ($choice -ne "s") { exit 0 }

    if (-not (Search-Units)) {
        Fatal-GameNotFound
        exit
    }
}

# Cópia de segurança e instalação
Check-Backup
Copy-Files

# Menu final
End-Menu
