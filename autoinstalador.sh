#!/bin/bash

# ============================================================
#  AUTOINSTALADOR 100NOME
#  Copyright (C) 2026  João Frade
#  Licenciado sob a GNU General Public License v3.0
#  https://100nome.netlify.app
# ============================================================

export LANG=pt_PT.UTF-8
export LC_ALL=pt_PT.UTF-8

# ── Cores ────────────────────────────────────────────────────
GOLD='\033[38;5;214m'       # dourado — cor principal 100Nome
GOLD_DIM='\033[38;5;178m'   # dourado escuro — subtítulos
WHITE='\033[1;37m'          # branco — texto em destaque
GRAY='\033[0;90m'           # cinzento — texto secundário
GREEN='\033[0;32m'          # verde — sucesso
YELLOW='\033[1;33m'         # amarelo — aviso
RED='\033[0;31m'            # vermelho — erro
CYAN='\033[0;36m'           # ciano — progresso / info
NC='\033[0m'                # reset

# ── Constantes ───────────────────────────────────────────────
readonly SCRIPT_VERSION="2.0.1"
readonly SP_FOLDER="_100NOME"
readonly PACK_START="Pacote 100Nome"
readonly PACK_DEFAULT="pacote normal"
readonly FILE_NOTES="NOTAS.html"
readonly FILE_HELP="INSTALAR.html"
readonly FILE_CONFIG=".autoinstalacao"
readonly BACKUP_PATH="${SP_FOLDER}/original"
readonly BACKUP_PARTIAL_SUFFIX=" - parcial"
readonly SITE_BASE="https://100nome.netlify.app"
readonly DISCORD_URL="https://discord.gg/Xv7ax2VkEp"

# ── Variáveis de estado ──────────────────────────────────────
gameName=""
fileName=""
baseUpLevels=0
expectedFiles=""
expectedDirs=""
filesForRemoval=""
urlEnd=""
trLicenseFileName=""
packName=""
exeDir=""
gameDir=""
packList=()
dirsToSearch="/ /home /media /mnt /opt /usr/local/games"
performBackup=1
installed=0
postInstallNote=""
installCmd=""
error_log=()              # registo de eventos para o ficheiro de erro
SCRIPT_DIR=""             # definido em main() após cd


# ════════════════════════════════════════════════════════════
#  UTILITÁRIOS DE APRESENTAÇÃO
# ════════════════════════════════════════════════════════════

# Linha separadora com cor opcional
hr() {
    local color="${1:-$GRAY}"
    echo -e "${color}$(printf '─%.0s' {1..60})${NC}"
}

# Espaço vertical
gap() { echo ""; }

# Título de secção
section() {
    gap
    hr "$GOLD_DIM"
    echo -e "  ${GOLD}${1}${NC}"
    hr "$GOLD_DIM"
    gap
}

# Mensagem de estado com ícone
msg_ok()   { echo -e "  ${GREEN}✔${NC}  ${1}"; }
msg_warn() { echo -e "  ${YELLOW}⚠${NC}  ${1}"; }
msg_err()  { echo -e "  ${RED}✘${NC}  ${WHITE}${1}${NC}"; }
msg_info() { echo -e "  ${CYAN}›${NC}  ${1}"; }
msg_gray() { echo -e "  ${GRAY}${1}${NC}"; }

# Prompt de input estilizado
prompt() {
    local label="$1"
    local var="$2"
    echo -e "  ${GOLD_DIM}${label}${NC}"
    echo -ne "  ${GOLD}›${NC} "
    read -r "$var"
}

# Prompt de tecla simples
press_any_key() {
    gap
    echo -e "  ${GRAY}Prima qualquer tecla para continuar...${NC}"
    read -r -n 1 -s
}

# Caixa de destaque (para caminhos, valores importantes)
highlight_box() {
    local label="$1"
    local value="$2"
    echo -e "  ${GRAY}${label}${NC}"
    echo -e "  ${CYAN}${value}${NC}"
}


# ════════════════════════════════════════════════════════════
#  ECRÃ INICIAL
# ════════════════════════════════════════════════════════════

draw_header() {
    clear

    # ASCII art com animação linha a linha
    echo -e "${GOLD}"
    local lines=(
    "   ██╗ ██████╗  ██████╗ ███╗   ██╗ ██████╗ ███╗   ███╗███████╗"
    "  ███║██╔═████╗██╔═████╗████╗  ██║██╔═══██╗████╗ ████║██╔════╝"
    "  ╚██║██║██╔██║██║██╔██║██╔██╗ ██║██║   ██║██╔████╔██║█████╗  "
    "   ██║████╔╝██║████╔╝██║██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══╝  "
    "   ██║╚██████╔╝╚██████╔╝██║ ╚████║╚██████╔╝██║ ╚═╝ ██║███████╗"
    "   ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝"
    )
    for line in "${lines[@]}"; do
        echo "  $line"
        sleep 0.04
    done
    echo -e "${NC}"

    # Subtítulo e versão
    printf "  ${GOLD_DIM}%-46s${GRAY}v%s${NC}\n" \
        "Traduções PT-PT desde 2012" "$SCRIPT_VERSION"
    gap
    hr
    printf "  ${GRAY}%-40s%s${NC}\n" \
        "Copyright (C) 2024  João Frade" \
        "GNU GPL v3.0"
    hr
    gap
}

draw_header_compact() {
    clear
    echo ""
    hr "$GOLD_DIM"
    echo -e "  ${GOLD}100NOME${GOLD_DIM} — Autoinstalador${GRAY}  v${SCRIPT_VERSION}${NC}"
    hr "$GOLD_DIM"
    gap
}


# ════════════════════════════════════════════════════════════
#  CARREGAMENTO DE CONFIGURAÇÃO
# ════════════════════════════════════════════════════════════

load_variables() {
    local config_file="$FILE_CONFIG"
    local required="gameName urlEnd"

    if [[ ! -f "$config_file" ]]; then
        msg_err "Ficheiro de configuração '$config_file' não encontrado."
        return 1
    fi

    while IFS=' ' read -r key value || [[ -n "$key" ]]; do
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        [[ -n "$key" ]] && declare -g "$key=$value"
    done < "$config_file"

    for var in $required; do
        if [[ -z "${!var}" ]]; then
            msg_err "Configuração obrigatória ausente: '$var'"
            return 1
        fi
    done

    return 0
}

load_pack_variables() {
    local config_file="$packName/$FILE_CONFIG"
    local required="fileName baseUpLevels expectedFiles expectedDirs filesForRemoval trLicenseFileName"

    if [[ ! -f "$config_file" ]]; then
        msg_err "Configuração do pacote não encontrada: '$config_file'"
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # postInstallNote pode ter espaços — lê tudo após a chave
        if [[ "$line" == postInstallNote\ * ]]; then
            postInstallNote="${line#postInstallNote }"
            continue
        fi
        # Para todas as outras variáveis: primeira palavra = chave, resto = valor
        local key value
        key="${line%% *}"
        value="${line#* }"
        [[ "$key" == "$value" ]] && value=""   # linha com só uma palavra, sem valor
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        [[ -n "$key" ]] && declare -g "$key=$value"
    done < "$config_file"

    for var in $required; do
        if [[ -z "${!var+x}" ]]; then
            msg_err "Campo obrigatório ausente no pacote: '$var'"
            return 1
        fi
    done

    return 0
}


# ════════════════════════════════════════════════════════════
#  SELEÇÃO DE PACOTE
# ════════════════════════════════════════════════════════════

list_packs() {
    packList=()
    for dir in */; do
        dir="${dir%/}"
        if [[ "$dir" == ${PACK_START}* && -f "$dir/$FILE_CONFIG" ]]; then
            packList+=("$dir")
        fi
    done

    [[ ${#packList[@]} -gt 0 ]]
}

pack_choice() {
    local count=${#packList[@]}

    section "PACOTE DE TRADUÇÃO"

    if [[ $count -eq 1 ]]; then
        local pack_label="${packList[0]:$((${#PACK_START}+1))}"
        [[ -z "$pack_label" ]] && pack_label="$PACK_DEFAULT"

        msg_info "Jogo: ${WHITE}${gameName}${NC}"
        [[ -n "$pack_label" && "$pack_label" != "$PACK_DEFAULT" ]] && \
            msg_info "Pacote: ${WHITE}${pack_label}${NC}"
        gap
        press_any_key
        packName="${packList[0]}"
        return 0
    fi

    echo -e "  ${WHITE}Estão disponíveis ${count} pacotes para ${gameName}:${NC}"
    gap

    local i=0
    for pack in "${packList[@]}"; do
        i=$((i+1))
        local label="${pack:$((${#PACK_START}+1))}"
        [[ -z "$label" ]] && label="$PACK_DEFAULT"
        echo -e "  ${GOLD}[${i}]${NC}  ${label}"
    done

    gap
    msg_gray "Verifica a versão do teu jogo e escolhe o pacote correspondente."
    gap
    prompt "Número do pacote:" choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || \
       [[ $choice -lt 1 || $choice -gt $count ]]; then
        msg_err "Opção inválida."
        return 1
    fi

    packName="${packList[$((choice-1))]}"
    local chosen_label="${packName:$((${#PACK_START}+1))}"
    [[ -z "$chosen_label" ]] && chosen_label="$PACK_DEFAULT"

    gap
    msg_ok "Pacote selecionado: ${WHITE}${chosen_label}${NC}"
    gap
    return 0
}


# ════════════════════════════════════════════════════════════
#  PESQUISA DO JOGO
# ════════════════════════════════════════════════════════════

_verify_game_dir() {
    local base="$1"
    local ok=1

    for file in $expectedFiles; do
        if [[ -f "${base}${file}" ]]; then
            msg_ok "${GRAY}${file}${NC}"
            error_log+=("  ENCONTRADO (ficheiro): ${base}${file}")
        else
            msg_err "${GRAY}${file}${NC} — não encontrado"
            error_log+=("  NÃO ENCONTRADO (ficheiro): ${base}${file}")
            ok=0
        fi
    done

    for dir in $expectedDirs; do
        if [[ -d "${base}${dir}" ]]; then
            msg_ok "${GRAY}${dir}/${NC}"
            error_log+=("  ENCONTRADO (pasta): ${base}${dir}")
        else
            msg_err "${GRAY}${dir}/${NC} — não encontrado"
            error_log+=("  NÃO ENCONTRADO (pasta): ${base}${dir}")
            ok=0
        fi
    done

    return $((1 - ok))
}

_search_in_path() {
    local search_root="$1"
    local context="${2:-instalar}"   # "instalar" ou "desinstalar"

    # Recolhe TODOS os resultados primeiro num array —
    # evita que o read do prompt leia do pipe do find em vez do teclado
    local -a found_files=()
    while IFS= read -r -d '' f; do
        found_files+=("$f")
    done < <(find "$search_root" -name "$fileName" -type f -print0 2>/dev/null)

    [[ ${#found_files[@]} -eq 0 ]] && return 1

    # Agora itera sobre o array — stdin está livre para o teclado
    for found_file in "${found_files[@]}"; do
        local found_exe_dir
        found_exe_dir="$(dirname "$found_file")/"

        local base="$found_exe_dir"
        base="${base%/}"
        for ((l=1; l<=baseUpLevels; l++)); do
            base="$(dirname "$base")"
        done
        base="${base}/"

        error_log+=("Executável encontrado: $found_file")
        [[ $baseUpLevels -gt 0 ]] &&             error_log+=("  baseUpLevels=${baseUpLevels} → pasta base resolvida: ${base}")

        section "DIRETÓRIO ENCONTRADO"
        highlight_box "Executável:" "$found_file"
        [[ $baseUpLevels -gt 0 ]] &&             msg_gray "  (${baseUpLevels} nível(is) acima → ${base})"
        gap
        echo -e "  ${GRAY}A verificar ficheiros e pastas esperados...${NC}"
        gap

        if _verify_game_dir "$base"; then
            gap
            msg_ok "Todos os ficheiros verificados."
            gap
            if [[ "$context" == "desinstalar" ]]; then
                highlight_box "Desinstalar em:" "$base"
                gap
                echo -e "  ${GOLD}[S]${NC}  Desinstalar aqui"
            else
                highlight_box "Instalar em:" "$base"
                gap
                echo -e "  ${GOLD}[S]${NC}  Instalar aqui"
            fi
            echo -e "  ${GOLD}[N]${NC}  Continuar pesquisa"
            echo -e "  ${GOLD}[X]${NC}  Cancelar"
            gap
            prompt "Opção:" choice

            case "${choice,,}" in
                s)
                    exeDir="$found_exe_dir"
                    gameDir="$base"
                    return 0
                    ;;
                n)
                    msg_gray "A continuar pesquisa..."
                    gap
                    ;;
                *)
                    exit 0
                    ;;
            esac
        else
            gap
            msg_warn "Este diretório não parece correto — a continuar pesquisa..."
            gap
        fi
    done

    return 1
}

search_units() {
    local context="${1:-instalar}"

    section "PESQUISA AUTOMÁTICA"
    msg_info "À procura de: ${WHITE}${gameName}${NC}"
    gap

    for path in $dirsToSearch; do
        [[ ! -d "$path" ]] && continue
        msg_gray "A pesquisar em: $path"
        error_log+=("Pesquisado: $path")
        if _search_in_path "$path" "$context"; then
            return 0
        fi
    done

    return 1
}


# ════════════════════════════════════════════════════════════
#  CÓPIA DE SEGURANÇA
# ════════════════════════════════════════════════════════════

_make_backup_dir() {
    local dir="${gameDir}${BACKUP_PATH}"
    [[ $performBackup -eq 0 ]] && dir="${dir}${BACKUP_PARTIAL_SUFFIX}"
    mkdir -p "$dir"
    echo "$dir"
}

_move_to_backup() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -f "$dst" ]]; then
        mv "$src" "$dst" && msg_ok "Guardado: ${GRAY}$(basename "$src")${NC}" \
                        || msg_err "Erro ao mover: $src"
    else
        msg_warn "Cópia já existe — ignorado: $(basename "$src")"
    fi
}

create_backup() {
    local backup_dir
    backup_dir="$(_make_backup_dir)"

    section "CÓPIA DE SEGURANÇA"

    if [[ $performBackup -eq 0 ]]; then
        msg_info "Modo parcial — apenas ficheiros a remover serão guardados."
        highlight_box "Destino:" "$backup_dir"
        gap
        _backup_removal_files "$backup_dir"
        return
    fi

    msg_info "A salvaguardar ficheiros originais do jogo antes de instalar."
    highlight_box "Destino:" "$backup_dir"
    gap

    # Caminhos absolutos reais (resolve ../ e symlinks)
    local pack_path game_path
    pack_path="$(cd "${SCRIPT_DIR}/${packName}" && pwd)"
    game_path="${gameDir%/}"

    # Recolhe todos os ficheiros do pacote
    local -a pack_files=()
    while IFS= read -r -d "" f; do
        pack_files+=("$f")
    done < <(find "$pack_path" -type f -print0)

    if [[ ${#pack_files[@]} -eq 0 ]]; then
        msg_warn "Nenhum ficheiro encontrado no pacote."
        return
    fi

    # Manifesto: lista todos os ficheiros que serão instalados
    # — usado depois para reversão (saber o que remover)
    local manifest="${backup_dir}/.manifesto_instalacao"
    local found_any=0

    for src_file in "${pack_files[@]}"; do
        local rel="${src_file#${pack_path}/}"

        # Salta ficheiros internos do instalador — não existem no jogo
        [[ "$rel" == _100NOME* ]] && continue
        [[ "$rel" == .auto*    ]] && continue

        # Regista no manifesto — independentemente de existir original
        echo "file:$rel" >> "$manifest"

        local original="${game_path}/${rel}"
        local backup="${backup_dir}/${rel}"

        if [[ -f "$original" ]]; then
            found_any=1
            _move_to_backup "$original" "$backup"
        fi
    done

    # Guarda revertCmd e revertNote no manifesto
    [[ -n "$revertCmd"  ]] && echo "revertCmd:${revertCmd}"  >> "$manifest"
    [[ -n "$revertNote" ]] && echo "revertNote:${revertNote}" >> "$manifest"

    # Também salvaguarda ficheiros marcados para remoção
    _backup_removal_files "$backup_dir"

    if [[ $found_any -eq 0 ]]; then
        msg_gray "Nenhum ficheiro original encontrado — o jogo ainda não tinha tradução."
        msg_gray "O manifesto foi guardado para permitir reversão futura."
    fi
}

_backup_removal_files() {
    local backup_dir="$1"
    [[ -z "$filesForRemoval" ]] && return

    msg_info "A remover ficheiros conflituantes..."
    gap
    for file in $filesForRemoval; do
        local target="${gameDir}${file}"
        local backup="${backup_dir}/${file}"
        [[ -f "$target" ]] && _move_to_backup "$target" "$backup"
    done
}

check_backup() {
    local backup_dir="${gameDir}${BACKUP_PATH}"

    if [[ ! -d "$backup_dir" ]]; then
        create_backup
        return
    fi

    section "ATUALIZAÇÃO DE TRADUÇÃO"
    msg_info "Já existe uma cópia dos ficheiros originais."
    msg_gray "A cópia original será preservada. Apenas os ficheiros de"
    msg_gray "tradução serão atualizados."
    gap

    local manifest="${backup_dir}/.manifesto_instalacao"
    local pack_path
    pack_path="$(cd "${SCRIPT_DIR}/${packName}" && pwd)"
    : > "$manifest"

    local -a pack_files=()
    while IFS= read -r -d "" f; do
        pack_files+=("$f")
    done < <(find "$pack_path" -type f -print0)

    for src_file in "${pack_files[@]}"; do
        local rel="${src_file#${pack_path}/}"
        [[ "$rel" == _100NOME* ]] && continue
        [[ "$rel" == .auto*    ]] && continue
        echo "file:$rel" >> "$manifest"
    done
    [[ -n "$revertCmd"  ]] && echo "revertCmd:${revertCmd}"  >> "$manifest"
    [[ -n "$revertNote" ]] && echo "revertNote:${revertNote}" >> "$manifest"

    msg_ok "Manifesto atualizado."
    gap
    echo -e "  ${GOLD}[S]${NC}  Continuar com a instalação"
    echo -e "  ${GOLD}[X]${NC}  Cancelar"
    gap
    prompt "Opção:" choice
    [[ "${choice,,}" != "s" ]] && exit 0
}


# ════════════════════════════════════════════════════════════
#  REVERSÃO / RESTAURO
# ════════════════════════════════════════════════════════════

restore_backup() {
    local backup_base="${gameDir}${BACKUP_PATH}"
    local game_path="${gameDir%/}"

    # Lista cópias disponíveis (exclui parciais)
    local -a backups=()
    for d in "${backup_base}"*; do
        [[ -d "$d" && "$d" != *"${BACKUP_PARTIAL_SUFFIX}" ]] && backups+=("$d")
    done

    if [[ ${#backups[@]} -eq 0 ]]; then
        msg_err "Nenhuma cópia de segurança encontrada."
        msg_gray "Não é possível reverter sem cópia de segurança."
        gap
        press_any_key
        return 1
    fi

    section "REVERSÃO — ESCOLHER CÓPIA"

    if [[ ${#backups[@]} -eq 1 ]]; then
        msg_info "Cópia disponível:"
        highlight_box "" "${backups[0]}"
        gap
        local chosen="${backups[0]}"
    else
        echo -e "  ${WHITE}Cópias de segurança disponíveis:${NC}"
        gap
        local i=0
        for b in "${backups[@]}"; do
            i=$((i+1))
            echo -e "  ${GOLD}[${i}]${NC}  $(basename "$b")"
        done
        gap
        prompt "Número da cópia a restaurar:" choice
        if ! [[ "$choice" =~ ^[0-9]+$ ]] ||            [[ $choice -lt 1 || $choice -gt ${#backups[@]} ]]; then
            msg_err "Opção inválida."
            press_any_key
            return 1
        fi
        local chosen="${backups[$((choice-1))]}"
    fi

    local manifest="${chosen}/.manifesto_instalacao"

    # Lê revertCmd e revertNote do manifesto
    local _revertCmd="" _revertNote=""
    if [[ -f "$manifest" ]]; then
        while IFS= read -r mline; do
            [[ "$mline" == revertCmd:*  ]] && _revertCmd="${mline#revertCmd:}"
            [[ "$mline" == revertNote:* ]] && _revertNote="${mline#revertNote:}"
        done < "$manifest"
    fi
    [[ -z "$_revertCmd"  && -n "$revertCmd"  ]] && _revertCmd="$revertCmd"
    [[ -z "$_revertNote" && -n "$revertNote" ]] && _revertNote="$revertNote"

    section "REVERSÃO — CONFIRMAÇÃO"
    highlight_box "Cópia a restaurar:" "$chosen"
    gap
    msg_warn "Este processo irá:"
    echo -e "  ${GRAY}  1. Remover todos os ficheiros instalados pela tradução${NC}"
    echo -e "  ${GRAY}  2. Restaurar os ficheiros originais do jogo${NC}"
    [[ -n "$_revertCmd" ]] &&         echo -e "  ${GRAY}  3. Executar: ${_revertCmd}${NC}"
    gap
    echo -e "  ${GOLD}[S]${NC}  Confirmar reversão"
    echo -e "  ${GOLD}[X]${NC}  Cancelar"
    gap
    prompt "Opção:" choice
    [[ "${choice,,}" != "s" ]] && return 0

    section "A REVERTER..."
    local removed=0 restored=0 errors=0

    # Passo 1: remove ficheiros instalados (listados no manifesto)
    if [[ -f "$manifest" ]]; then
        msg_info "A remover ficheiros da tradução..."
        gap
        while IFS= read -r mline; do
            [[ "$mline" != file:* ]] && continue
            local rel="${mline#file:}"
            [[ -z "$rel" ]] && continue
            local installed_file="${game_path}/${rel}"
            if [[ -f "$installed_file" ]]; then
                rm "$installed_file"                     && { msg_ok "Removido: ${GRAY}${rel}${NC}"; removed=$((removed+1)); }                     || { msg_err "Erro ao remover: ${rel}"; errors=$((errors+1)); }
            fi
        done < "$manifest"

        # Remove pastas vazias deixadas pela tradução (de baixo para cima)
        while IFS= read -r rel; do
            [[ -z "$rel" ]] && continue
            local dir
            dir="$(dirname "${game_path}/${rel}")"
            # Só remove se estiver vazia e não for a raiz do jogo
            [[ "$dir" != "$game_path" && -d "$dir" ]] &&                 rmdir "$dir" 2>/dev/null || true
        done < <(grep "^file:" "$manifest" | sed "s/^file://" | sort -r)
        gap
    else
        msg_warn "Manifesto não encontrado — apenas os ficheiros originais serão restaurados."
        msg_gray "Ficheiros exclusivos da tradução podem ter ficado no jogo."
        gap
    fi

    # Passo 2: restaura ficheiros originais da cópia de segurança
    msg_info "A restaurar ficheiros originais..."
    gap
    local -a backup_files=()
    while IFS= read -r -d "" f; do
        backup_files+=("$f")
    done < <(find "$chosen" -type f -not -name ".manifesto_instalacao" -print0)

    for backup_file in "${backup_files[@]}"; do
        local rel="${backup_file#${chosen}/}"
        local target="${game_path}/${rel}"
        mkdir -p "$(dirname "$target")"
        mv "$backup_file" "$target"             && { msg_ok "Restaurado: ${GRAY}${rel}${NC}"; restored=$((restored+1)); }             || { msg_err "Erro ao restaurar: ${rel}"; errors=$((errors+1)); }
    done

    gap
    hr "$GOLD_DIM"
    gap
    msg_info "Removidos:  ${WHITE}${removed}${NC} ficheiro(s) da tradução"
    msg_info "Restaurados: ${WHITE}${restored}${NC} ficheiro(s) original(is)"
    [[ $errors -gt 0 ]] && msg_err "Erros: ${errors}"
    gap

    if [[ $errors -eq 0 ]]; then
        msg_ok "Reversão concluída com sucesso."
        rm -rf "$chosen" 2>/dev/null || true
    else
        msg_warn "Reversão concluída com erros. Verifica o estado do jogo."
    fi

    # Passo 3: revertCmd com fallback para revertNote
    if [[ -n "$_revertCmd" ]]; then
        gap
        hr "$GOLD_DIM"
        msg_info "A executar comando de reversão..."
        msg_gray "  $ ${_revertCmd}"
        gap
        # Corre no diretório do jogo; erros visíveis para diagnóstico
        local revert_out revert_rc
        revert_out=$(cd "$game_path" && eval "$_revertCmd" 2>&1)
        revert_rc=$?
        if [[ $revert_rc -eq 0 ]]; then
            msg_ok "Comando executado com sucesso."
            [[ -n "$revert_out" ]] && msg_gray "$revert_out"
        else
            msg_warn "O comando de reversão falhou (código $revert_rc)."
            [[ -n "$revert_out" ]] && msg_gray "  Erro: $revert_out"
            if [[ -n "$_revertNote" ]]; then
                gap
                echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
                echo -e "  ${YELLOW}║  ⚠  AÇÃO MANUAL NECESSÁRIA                           ║${NC}"
                echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
                gap
                echo -e "  ${WHITE}${_revertNote}${NC}"
            else
                msg_gray "Sem instruções manuais — verifica o estado do jogo."
            fi
        fi
    elif [[ -n "$_revertNote" ]]; then
        gap
        echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${YELLOW}║  ⚠  AÇÃO MANUAL NECESSÁRIA                           ║${NC}"
        echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
        gap
        echo -e "  ${WHITE}${_revertNote}${NC}"
    fi

    gap
    press_any_key
}

# ════════════════════════════════════════════════════════════
#  INSTALAÇÃO
# ════════════════════════════════════════════════════════════

copy_files() {
    section "A INSTALAR"

    highlight_box "Origem:"  "$(pwd)/$packName"
    gap
    highlight_box "Destino:" "$gameDir"
    gap

    msg_info "A copiar ficheiros..."
    gap

    if cp -r "$(pwd)/$packName/"* "$gameDir" 2>/dev/null; then
        msg_ok "${GREEN}${WHITE}Ficheiros copiados com sucesso!${NC}"
        installed=1
    else
        msg_err "Ocorreu um erro durante a cópia de ficheiros."
        msg_gray "Verifica as permissões do diretório do jogo."
        installed=0
        return
    fi

    # installCmd — configuração automática pós-cópia (ex: mudar idioma no .ini)
    if [[ -n "$installCmd" ]]; then
        gap
        msg_info "A configurar o jogo..."
        msg_gray "  $ ${installCmd}"
        gap
        local install_out install_rc
        install_out=$(cd "${gameDir%/}" && eval "$installCmd" 2>&1)
        install_rc=$?
        if [[ $install_rc -eq 0 ]]; then
            msg_ok "Configuração aplicada com sucesso."
            [[ -n "$install_out" ]] && msg_gray "$install_out"
            # installCmd correu — postInstallNote não é necessário
            postInstallNote=""
        else
            msg_warn "A configuração automática falhou (código $install_rc)."
            [[ -n "$install_out" ]] && msg_gray "  Erro: $install_out"
            # postInstallNote (se existir) será mostrado no menu final como fallback
        fi
    fi
}


# ════════════════════════════════════════════════════════════
#  MENU FINAL
# ════════════════════════════════════════════════════════════

_open_file() {
    local path="$1"
    xdg-open "$path" 2>/dev/null || open "$path" 2>/dev/null
}

draw_success_banner() {
    gap
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║                                                      ║"
    echo "  ║   ✔  TRADUÇÃO INSTALADA COM SUCESSO                  ║"
    echo "  ║                                                      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    gap
}

end_menu() {
    draw_header_compact

    if [[ $installed -eq 1 ]]; then
        draw_success_banner
        msg_info "Jogo: ${WHITE}${gameName}${NC}"
        gap

        # Nota pós-instalação — só aparece se installCmd falhou ou não existe
        if [[ -n "$postInstallNote" ]]; then
            echo -e "  ${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
            if [[ -n "$installCmd" ]]; then
                echo -e "  ${YELLOW}║  ⚠  CONFIGURAÇÃO AUTOMÁTICA FALHOU                   ║${NC}"
            else
                echo -e "  ${YELLOW}║  ⚠  PASSO ADICIONAL NECESSÁRIO                       ║${NC}"
            fi
            echo -e "  ${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
            gap
            echo -e "  ${WHITE}${postInstallNote}${NC}"
            gap
        fi
    else
        section "INSTALAÇÃO INCOMPLETA"
        msg_warn "A tradução pode não ter sido instalada corretamente."
        gap
    fi

    hr "$GOLD_DIM"
    gap

    # Opções disponíveis dinamicamente
    echo -e "  ${GOLD_DIM}O QUE FAZER A SEGUIR:${NC}"
    gap

    [[ -f "$FILE_HELP" ]] && \
        echo -e "  ${GOLD}[A]${NC}   Abrir ficheiro de ajuda  ${GRAY}(INSTALAR.html)${NC}"

    if [[ -n "$packName" ]]; then
        [[ -f "$packName/$SP_FOLDER/$FILE_NOTES" || -f "$FILE_NOTES" ]] && \
            echo -e "  ${GOLD}[N]${NC}   Notas da Tradução         ${GRAY}(versão, créditos)${NC}"
        [[ -f "$packName/$SP_FOLDER/$trLicenseFileName" ]] && \
            echo -e "  ${GOLD}[L]${NC}   Licença da Tradução"
    fi

    if [[ $installed -eq 1 ]]; then
        [[ -d "$gameDir" ]] && \
            echo -e "  ${GOLD}[P]${NC}   Abrir pasta do jogo"
        [[ -f "${exeDir}${fileName}" ]] && \
            echo -e "  ${GOLD}[J]${NC}   Iniciar jogo"
    fi

    # Mostra opção de reversão se existir cópia de segurança
    local _backup_base="${gameDir}${BACKUP_PATH}"
    local _has_backup=0
    for _d in "${_backup_base}"*; do
        [[ -d "$_d" && "$_d" != *"${BACKUP_PARTIAL_SUFFIX}" ]] && { _has_backup=1; break; }
    done
    [[ $_has_backup -eq 1 ]] && \
        echo -e "  ${GOLD}[D]${NC}   Desinstalar tradução  ${GRAY}(restaurar originais)${NC}"

    gap
    hr "$GOLD_DIM"
    echo -e "  ${GOLD}[H]${NC}   Ajuda / Reportar problema"
    echo -e "  ${GOLD}[T]${NC}   Terminar"
    gap
    hr "$GOLD_DIM"
    gap

    while true; do
        prompt "Opção:" choice

        case "${choice,,}" in
            a)
                [[ -f "$FILE_HELP" ]] && _open_file "$FILE_HELP"
                ;;
            n)
                local notes=""
                [[ -f "$FILE_NOTES" ]]                             && notes="$FILE_NOTES"
                [[ -f "$packName/$SP_FOLDER/$FILE_NOTES" ]]        && notes="$packName/$SP_FOLDER/$FILE_NOTES"
                [[ -n "$notes" ]] && _open_file "$notes"
                ;;
            l)
                local lic="$packName/$SP_FOLDER/$trLicenseFileName"
                [[ -f "$lic" ]] && _open_file "$lic"
                ;;
            p)
                [[ $installed -eq 1 && -d "$gameDir" ]] && _open_file "$gameDir"
                ;;
            j)
                if [[ $installed -eq 1 && -f "${exeDir}${fileName}" ]]; then
                    cd "$exeDir" || return
                    gap
                    msg_info "A lançar ${WHITE}${gameName}${NC}..."
                    msg_gray "Aguarda enquanto o jogo carrega. Este terminal voltará quando fechares o jogo."
                    gap
                    hr
                    gap

                    # Abre a página do jogo em background enquanto o jogo lança
                    [[ -n "$urlEnd" ]] && _open_file "${SITE_BASE}/${urlEnd}" &

                    # Corre o jogo — bloqueia até o utilizador fechar
                    if [[ -x "${exeDir}${fileName}" ]]; then
                        "./${fileName}"
                    else
                        # Tenta via xdg-open mas espera (não usa &)
                        xdg-open "${exeDir}${fileName}" 2>/dev/null                             || open "${exeDir}${fileName}" 2>/dev/null
                        # Pausa para o utilizador ver a saída do lançador
                        press_any_key
                    fi

                    # Volta ao diretório do instalador e redesenha o menu
                    cd - > /dev/null 2>&1 || true
                    gap
                    hr
                    msg_ok "Jogo fechado. De volta ao instalador."
                    gap
                    end_menu
                    return
                fi
                ;;
                d)
                if [[ -n "$gameDir" ]]; then
                    restore_backup
                    end_menu
                    return
                fi
                ;;
            h)
                menu_help_error
                # volta ao end_menu se o utilizador não terminar lá
                end_menu
                return
                ;;
            t)
                gap
                if [[ $installed -eq 1 && -n "$urlEnd" ]]; then
                    msg_gray "A abrir página do jogo no site 100Nome..."
                    _open_file "${SITE_BASE}/${urlEnd}"
                fi
                gap
                msg_ok "Obrigado por usares o 100Nome. Boa sorte!"
                gap
                exit 0
                ;;
            *)
                msg_warn "Opção não reconhecida."
                ;;
        esac
        gap
    done
}




# ════════════════════════════════════════════════════════════
#  DESINSTALAÇÃO
# ════════════════════════════════════════════════════════════

uninstall_flow() {
    if ! list_packs; then fatal_no_packs; return; fi
    if ! pack_choice; then return; fi
    if ! load_pack_variables; then fatal_pack_error; return; fi

    section "DESINSTALAR TRADUÇÃO"
    msg_info "Jogo: ${WHITE}${gameName}${NC}"
    msg_gray "Vai pesquisar o jogo da mesma forma que a instalação."
    gap

    if [[ -n "$exeDir" ]]; then
        local base="${exeDir%/}"
        for ((l=1; l<=baseUpLevels; l++)); do base="$(dirname "$base")"; done
        gameDir="${base}/"
    else
        echo -e "  ${GOLD}[S]${NC}  Pesquisar automaticamente"
        echo -e "  ${GOLD}[X]${NC}  Cancelar"
        gap
        prompt "Opção:" choice
        [[ "${choice,,}" != "s" ]] && return
        if ! search_units "desinstalar"; then
            section "JOGO NÃO ENCONTRADO"
            msg_err "${gameName} não foi encontrado."
            gap; press_any_key; return
        fi
    fi

    local backup_dir="${gameDir}${BACKUP_PATH}"

    if [[ ! -d "$backup_dir" ]]; then
        section "SEM CÓPIA DE SEGURANÇA"
        msg_warn "Não foi encontrada cópia de segurança para ${gameName}."
        gap
        msg_gray "Sem cópia de segurança não é possível restaurar os ficheiros"
        msg_gray "originais — apenas os ficheiros de tradução serão removidos."
        gap
        echo -e "  ${GOLD}[S]${NC}  Remover ficheiros de tradução mesmo assim"
        echo -e "  ${GOLD}[X]${NC}  Cancelar"
        gap
        prompt "Opção:" choice
        [[ "${choice,,}" == "s" ]] && _uninstall_files_only
        return
    fi

    restore_backup
}

_uninstall_files_only() {
    section "A REMOVER FICHEIROS DE TRADUÇÃO..."
    local game_path="${gameDir%/}"
    local pack_path
    pack_path="$(cd "${SCRIPT_DIR}/${packName}" && pwd)"
    local removed=0 errors=0

    local -a pack_files=()
    while IFS= read -r -d "" f; do
        pack_files+=("$f")
    done < <(find "$pack_path" -type f -print0)

    for src_file in "${pack_files[@]}"; do
        local rel="${src_file#${pack_path}/}"
        [[ "$rel" == _100NOME* ]] && continue
        [[ "$rel" == .auto*    ]] && continue
        local target="${game_path}/${rel}"
        if [[ -f "$target" ]]; then
            rm "$target" \
                && { msg_ok "Removido: ${GRAY}${rel}${NC}"; removed=$((removed+1)); } \
                || { msg_err "Erro: ${rel}"; errors=$((errors+1)); }
        fi
    done

    gap
    msg_info "Removidos: ${WHITE}${removed}${NC} ficheiro(s)"
    [[ $errors -gt 0 ]] && msg_err "Erros: ${errors}"
    gap
    press_any_key
}

# ════════════════════════════════════════════════════════════
#  MENU DE AJUDA / ERRO
# ════════════════════════════════════════════════════════════

menu_help_error() {
    while true; do
        draw_header_compact
        gap
        echo -e "  ${RED}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${RED}║  ✘  ALGO CORREU MAL?                                 ║${NC}"
        echo -e "  ${RED}╚══════════════════════════════════════════════════════╝${NC}"
        gap

        [[ -n "$gameName" ]] && msg_info "Jogo: ${WHITE}${gameName}${NC}"
        gap
        hr "$GOLD_DIM"
        gap

        [[ -f "$FILE_HELP" ]] &&             echo -e "  ${GOLD}[A]${NC}   Abrir instruções de instalação manual"
        echo -e "  ${GOLD}[R]${NC}   Gerar registo de erro  ${GRAY}(para enviar no Discord)${NC}"
        echo -e "  ${GOLD}[D]${NC}   Abrir Discord do 100Nome"
        gap
        hr "$GOLD_DIM"
        echo -e "  ${GOLD}[T]${NC}   Terminar"
        gap

        prompt "Opção:" choice

        case "${choice,,}" in
            a)
                if [[ -f "$FILE_HELP" ]]; then
                    _open_file "$FILE_HELP"
                    msg_gray "A abrir INSTALAR.html..."
                else
                    msg_warn "Ficheiro INSTALAR.html não encontrado."
                fi
                ;;
            r)
                generate_error_report
                press_any_key
                ;;
            d)
                gap
                msg_gray "A abrir o Discord do 100Nome..."
                _open_file "$DISCORD_URL"
                gap
                ;;
            t)
                gap
                msg_ok "Obrigado por usares o 100Nome."
                gap
                exit 1
                ;;
            *)
                msg_warn "Opção não reconhecida."
                ;;
        esac
        gap
    done
}

# ════════════════════════════════════════════════════════════
#  CONFIGURAÇÕES
# ════════════════════════════════════════════════════════════

show_configs() {
    while true; do
        draw_header_compact
        section "CONFIGURAÇÕES"

        echo -e "  ${GOLD_DIM}PESQUISA AUTOMÁTICA${NC}"
        gap
        echo -e "  ${GOLD}[UD]${NC}  Alterar ordem de pesquisa"
        highlight_box "  Ordem atual:" "$dirsToSearch"
        gap
        echo -e "  ${GOLD}[LE]${NC}  Definir localização manual do executável"
        if [[ -n "$exeDir" ]]; then
            highlight_box "  Localização definida:" "$exeDir"
        else
            msg_gray "  Pesquisa automática ativa."
        fi
        gap
        hr "$GOLD_DIM"
        echo -e "  ${GOLD}[V]${NC}   Voltar ao menu principal"
        gap

        prompt "Opção:" choice

        case "${choice,,}" in
            ud)
                gap
                highlight_box "Ordem atual:" "$dirsToSearch"
                gap
                msg_gray "Introduz caminhos completos separados por espaço."
                msg_gray "Deixa em branco para manter."
                gap
                prompt "Nova ordem:" new_order
                if [[ -n "$new_order" ]]; then
                    dirsToSearch="$new_order"
                    msg_ok "Ordem atualizada."
                else
                    msg_gray "Sem alterações."
                fi
                ;;
            le)
                gap
                msg_gray "Introduz o caminho completo da pasta do executável."
                msg_gray "Deixa em branco para reativar a pesquisa automática."
                gap
                prompt "Localização:" new_loc
                if [[ -n "$new_loc" ]]; then
                    exeDir="$new_loc"
                    msg_ok "Localização definida: $exeDir"
                else
                    exeDir=""
                    msg_ok "Pesquisa automática reativada."
                fi
                ;;
            v)
                return
                ;;
            *)
                msg_warn "Opção não reconhecida."
                ;;
        esac

        gap
        press_any_key
    done
}


# ════════════════════════════════════════════════════════════
#  LICENÇA
# ════════════════════════════════════════════════════════════

show_license() {
    draw_header_compact
    section "LICENÇA DO INSTALADOR"

    echo -e "${GRAY}"
    cat << 'EOF'
  GNU GENERAL PUBLIC LICENSE — Version 3, 29 June 2007

  Copyright (C) 2007 Free Software Foundation, Inc.
  Este programa é software livre: podes redistribuí-lo e/ou
  modificá-lo sob os termos da GNU General Public License
  publicada pela Free Software Foundation, versão 3 ou superior.

  Este programa é distribuído na esperança de que seja útil,
  mas SEM QUALQUER GARANTIA; sem mesmo a garantia implícita de
  COMERCIALIZAÇÃO ou ADEQUAÇÃO A UM FIM PARTICULAR.

  Para mais detalhes consulta: https://www.gnu.org/licenses/
EOF
    echo -e "${NC}"

    press_any_key
}



# ════════════════════════════════════════════════════════════
#  REGISTO DE ERRO
# ════════════════════════════════════════════════════════════

generate_error_report() {
    local timestamp
    timestamp="$(date +"%Y%m%d_%H%M%S")"
    local safe_name="${gameName// /_}"
    local report_file="${SCRIPT_DIR}/registo_erro_${safe_name}_${timestamp}.txt"

    # Informação do sistema
    local os_info bash_ver user_info distro
    os_info="$(uname -sr 2>/dev/null || echo "desconhecido")"
    bash_ver="${BASH_VERSION}"
    user_info="$(whoami 2>/dev/null || echo "desconhecido")"
    distro="$(grep -oP '(?<=^PRETTY_NAME=").*(?=")' /etc/os-release 2>/dev/null               || grep -m1 'PRETTY_NAME' /etc/os-release 2>/dev/null               || echo "desconhecido")"
    local root_status="não-root"
    [[ $EUID -eq 0 ]] && root_status="ROOT ⚠"

    {
        echo "================================================================"
        echo "  REGISTO DE ERRO — 100Nome Autoinstalador"
        echo "================================================================"
        echo ""
        echo "  Data:              $(date "+%Y-%m-%d %H:%M:%S")"
        echo "  Versão script:     ${SCRIPT_VERSION}"
        echo ""
        echo "  Jogo:              ${gameName:-desconhecido}"
        echo "  Pacote:            ${packName:-desconhecido}"
        echo ""
        echo "  Parâmetros do pacote (.autoinstalacao):"
        echo "    fileName:        ${fileName:-desconhecido}"
        echo "    baseUpLevels:    ${baseUpLevels}"
        echo "    expectedFiles:   ${expectedFiles:-nenhum}"
        echo "    expectedDirs:    ${expectedDirs:-nenhum}"
        echo "    filesForRemoval: ${filesForRemoval:-nenhum}"
        echo ""
        echo "  Dir instalador:    ${SCRIPT_DIR:-desconhecido}"
        echo "  Dir jogo:          ${gameDir:-não encontrado}"
        echo ""
        echo "  Sistema:           ${os_info}"
        echo "  Distro:            ${distro}"
        echo "  Bash:              ${bash_ver}"
        echo "  Utilizador:        ${user_info} (${root_status})"
        echo ""
        echo "----------------------------------------------------------------"
        echo "  DIRETÓRIOS PESQUISADOS"
        echo "----------------------------------------------------------------"
        if [[ ${#error_log[@]} -gt 0 ]]; then
            for entry in "${error_log[@]}"; do
                echo "  ${entry}"
            done
        else
            echo "  (nenhum registo)"
        fi
        echo ""
        echo "----------------------------------------------------------------"
        echo "  COMO OBTER AJUDA"
        echo "----------------------------------------------------------------"
        echo ""
        echo "  1. Junta este ficheiro à tua mensagem"
        echo "  2. Descreve o que aconteceu"
        echo "  3. Envia no Discord:"
        echo ""
        echo "  ${DISCORD_URL}"
        echo ""
        echo "================================================================"
    } > "$report_file"

    if [[ -f "$report_file" ]]; then
        gap
        msg_ok "Registo gerado:"
        highlight_box "" "$report_file"
        gap
        msg_gray "Anexa este ficheiro à tua mensagem no Discord."
        gap
    else
        msg_err "Não foi possível criar o ficheiro de registo."
        msg_gray "Verifica as permissões da pasta do instalador."
    fi
}

# ════════════════════════════════════════════════════════════
#  ERROS FATAIS
# ════════════════════════════════════════════════════════════

fatal_config_error() {
    section "ERRO DE CONFIGURAÇÃO"
    msg_err "Não é possível continuar com a instalação."
    gap
    msg_gray "Verifica se o pacote está completo e não está corrompido."
    gap
    menu_help_error
}

fatal_pack_error() {
    section "PACOTE CORROMPIDO"
    msg_err "O pacote de tradução parece estar danificado."
    gap
    msg_gray "Tenta descarregar o pacote novamente a partir do site."
    gap
    menu_help_error
}

fatal_no_packs() {
    section "NENHUM PACOTE ENCONTRADO"
    msg_err "Não foi encontrado nenhum pacote de tradução válido."
    gap
    msg_gray "Certifica-te de que:"
    echo -e "  ${GRAY}  • Extraíste o ZIP por completo${NC}"
    echo -e "  ${GRAY}  • Este script se encontra na pasta extraída${NC}"
    echo -e "  ${GRAY}  • A pasta '${PACK_START}...' está presente${NC}"
    gap
    menu_help_error
}

fatal_game_not_found() {
    section "JOGO NÃO ENCONTRADO"
    msg_err "${gameName} não foi encontrado em nenhum diretório."
    gap
    msg_gray "Verifica se o jogo está instalado e tenta novamente."
    msg_gray "Podes também definir o caminho manualmente em Configurações."
    gap
    menu_help_error
}


# ════════════════════════════════════════════════════════════
#  VERIFICAÇÃO ROOT
# ════════════════════════════════════════════════════════════

check_root() {
    if [[ $EUID -eq 0 ]]; then
        draw_header_compact
        section "AVISO DE SEGURANÇA"
        msg_warn "Estás a executar este script como root (administrador)."
        gap
        msg_gray "Não é necessário executar como root para a maioria dos jogos."
        msg_gray "Recomenda-se executar como utilizador normal."
        gap
        echo -e "  ${GOLD}[C]${NC}  Continuar mesmo assim"
        echo -e "  ${GOLD}[X]${NC}  Cancelar"
        gap
        prompt "Opção:" choice
        [[ "${choice,,}" != "c" ]] && exit 0
    fi
}


# ════════════════════════════════════════════════════════════
#  MENU PRINCIPAL
# ════════════════════════════════════════════════════════════

main_menu() {
    draw_header

    msg_info "Jogo: ${WHITE}${gameName}${NC}"
    gap
    hr "$GOLD_DIM"
    gap

    msg_gray "Antes de avançar:"
    echo -e "  ${GRAY}  1. Extrai o ZIP por completo${NC}"
    echo -e "  ${GRAY}  2. Executa este script a partir da pasta extraída${NC}"
    gap
    hr "$GOLD_DIM"
    gap

    echo -e "  ${GOLD}[A]${NC}   Instalar tradução"
    echo -e "  ${GOLD}[D]${NC}   Desinstalar tradução existente"
    echo -e "  ${GOLD}[CO]${NC}  Configurações"
    echo -e "  ${GOLD}[LI]${NC}  Licença do instalador"
    gap
    hr "$GOLD_DIM"
    gap
    prompt "Opção:" choice
}


# ════════════════════════════════════════════════════════════
#  PONTO DE ENTRADA
# ════════════════════════════════════════════════════════════

main() {
    check_root

    # Processa --root (passado pelo wrapper instalar.sh)
    # Se ausente, usa o diretório do próprio script como fallback
    local pack_root=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --root) pack_root="$2"; shift 2 ;;
            *) break ;;
        esac
    done

    if [[ -n "$pack_root" ]]; then
        cd "$pack_root" || exit 1
    else
        cd "$(dirname "$0")" || exit 1
    fi
    SCRIPT_DIR="$(pwd)"   # raiz do ZIP — onde estão os Pacotes 100Nome

    # Carrega configuração base
    if ! load_variables; then
        draw_header_compact
        fatal_config_error
    fi

    while true; do
        main_menu

        case "${choice,,}" in
            li)
                show_license
                continue
                ;;
            co)
                show_configs
                # Se o utilizador definiu exeDir nas configs, resolve gameDir
                if [[ -n "$exeDir" && -z "$gameDir" ]]; then
                    local _base="${exeDir%/}"
                    for ((l=1; l<=baseUpLevels; l++)); do
                        _base="$(dirname "$_base")"
                    done
                    gameDir="${_base}/"
                fi
                continue
                ;;
            d)
                uninstall_flow
                continue
                ;;
            a)
                break
                ;;
            *)
                continue
                ;;
        esac
    done

    # ── Seleção de pacote ──
    if ! list_packs; then
        fatal_no_packs
    fi

    if ! pack_choice; then
        main  # volta ao início se escolha inválida
        return
    fi

    if ! load_pack_variables; then
        fatal_pack_error
    fi

    # ── Localização do jogo ──
    section "LOCALIZAÇÃO DO JOGO"
    msg_info "Jogo: ${WHITE}${gameName}${NC}"
    gap

    if [[ -n "$exeDir" ]]; then
        # Localização manual já definida nas configurações
        highlight_box "Localização definida manualmente:" "$exeDir"
        gameDir="$exeDir"
        local base="$exeDir"
        base="${base%/}"
        for ((l=1; l<=baseUpLevels; l++)); do
            base="$(dirname "$base")"
        done
        gameDir="${base}/"
    else
        echo -e "  ${GOLD}[S]${NC}  Pesquisar automaticamente"
        echo -e "  ${GOLD}[X]${NC}  Cancelar"
        gap
        prompt "Opção:" choice

        [[ "${choice,,}" != "s" ]] && exit 0

        if ! search_units; then
            fatal_game_not_found
            return
        fi
    fi

    # ── Cópia de segurança e instalação ──
    check_backup
    copy_files

    # ── Menu final ──
    end_menu
}

main "$@"
