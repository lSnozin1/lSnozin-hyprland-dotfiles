#!/usr/bin/env bash
#
# dualfetch.sh — substituto em shell do antigo dualfetch.py
#
# Roda o fastfetch duas vezes (config.jsonc = coluna esquerda,
# software.jsonc = coluna direita) e funde a saída lado a lado quando
# o terminal é largo o suficiente; caso contrário usa o fallback
# empilhado (logo-only.jsonc + narrow-modules.jsonc).
#
# Projetado pra nunca travar o terminal:
#   - toda chamada ao fastfetch tem timeout (FASTFETCH_TIMEOUT)
#   - não existe nenhum loop de espera artificial (usa tput cols direto)
#   - as duas colunas rodam em paralelo, não em série
#   - arquivos temporários são sempre limpos, mesmo em erro/Ctrl+C

set -u

# Força uma locale UTF-8 dentro do script, não importa o que o ambiente
# de fora tenha configurado. Sem isso, "${#string}" no bash conta BYTES
# em vez de CARACTERES pra qualquer coisa multi-byte (ícones Nerd Font,
# bordas ┌─┐ etc.) sempre que a locale ativa não é UTF-8 — e isso quebra
# o alinhamento das colunas de um jeito sutil e difícil de notar.
# C.UTF-8 vem embutida na glibc e não depende de locale-gen.
export LC_ALL=C.UTF-8

CONFIG_DIR="$HOME/.config/fastfetch"
LEFT_CONFIG="$CONFIG_DIR/config.jsonc"
RIGHT_CONFIG="$CONFIG_DIR/software.jsonc"
LOGO_ONLY_CONFIG="$CONFIG_DIR/logo-only.jsonc"
NARROW_MODULES_CONFIG="$CONFIG_DIR/narrow-modules.jsonc"

GAP=4                 # espaço entre a coluna esquerda e a direita
WIDE_THRESHOLD=160     # abaixo disso, cai pro layout empilhado (1 coluna)
CAPTURE_WIDTH=300      # largura "falsa" passada ao fastfetch pra ele não truncar
FASTFETCH_TIMEOUT=2    # segundos — teto absoluto por chamada ao fastfetch

ESC=$'\033'

# --- diretório temporário, sempre limpo ao sair (erro, Ctrl+C, timeout...) ---
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/dualfetch.XXXXXX") || exit 1
trap 'rm -rf "$tmpdir"' EXIT

strip_ansi() {
    # remove sequências de escape ANSI de um arquivo — só usado pra medir
    # a largura visível de cada linha, nunca pro texto que é impresso
    sed -E "s/${ESC}\[[0-9;]*[a-zA-Z]//g" "$1"
}

run_fastfetch() {
    # $1 = arquivo de config | $2 = arquivo de saída | $3 = largura forçada (opcional)
    local config="$1" outfile="$2" cols="${3:-}"
    if [[ -n "$cols" ]]; then
        COLUMNS="$cols" timeout "${FASTFETCH_TIMEOUT}s" fastfetch \
            -c "$config" --pipe false >"$outfile" 2>/dev/null
    else
        timeout "${FASTFETCH_TIMEOUT}s" fastfetch \
            -c "$config" --pipe false >"$outfile" 2>/dev/null
    fi
}

render_wide() {
    local leftraw="$tmpdir/left.raw" rightraw="$tmpdir/right.raw"
    local leftstripped="$tmpdir/left.stripped"

    # as duas colunas rodam em paralelo — corta o tempo total quase pela metade
    run_fastfetch "$LEFT_CONFIG" "$leftraw" "$CAPTURE_WIDTH" &
    local pid_left=$!
    run_fastfetch "$RIGHT_CONFIG" "$rightraw" "$CAPTURE_WIDTH" &
    local pid_right=$!
    wait "$pid_left"
    wait "$pid_right"

    # se alguma chamada falhou ou estourou o timeout, cai pro fastfetch padrão
    # (1 coluna só) em vez de mostrar uma tela quebrada ou vazia
    if [[ ! -s "$leftraw" || ! -s "$rightraw" ]]; then
        timeout "${FASTFETCH_TIMEOUT}s" fastfetch
        return
    fi

    strip_ansi "$leftraw" >"$leftstripped"

    mapfile -t left_lines < "$leftraw"
    mapfile -t right_lines < "$rightraw"
    mapfile -t left_stripped < "$leftstripped"

    local left_width=0 len line
    for line in "${left_stripped[@]}"; do
        len=${#line}
        (( len > left_width )) && left_width=$len
    done
    (( left_width += GAP ))

    local total=${#left_lines[@]}
    (( ${#right_lines[@]} > total )) && total=${#right_lines[@]}

    local out="" i l r ls pad
    for (( i = 0; i < total; i++ )); do
        l="${left_lines[i]-}"
        ls="${left_stripped[i]-}"
        r="${right_lines[i]-}"
        pad=$(( left_width - ${#ls} ))
        (( pad < 0 )) && pad=0
        out+="${l}$(printf '%*s' "$pad" '')${r}"$'\n'
    done

    # limpa a tela e imprime tudo numa única chamada (evita ficar
    # com a tela em branco caso algo falhe entre o clear e o print)
    printf '%s%s' "${ESC}[2J${ESC}[3J${ESC}[H" "$out"
}

render_narrow() {
    local logofile="$tmpdir/logo.raw" modulesfile="$tmpdir/modules.raw"

    # roda logo e módulos em paralelo também, mesmo que o resultado final
    # seja empilhado — reduz o tempo total no pior caso pela metade
    run_fastfetch "$LOGO_ONLY_CONFIG" "$logofile" &
    local pid_logo=$!
    run_fastfetch "$NARROW_MODULES_CONFIG" "$modulesfile" &
    local pid_modules=$!
    wait "$pid_logo"
    wait "$pid_modules"

    if [[ ! -s "$logofile" && ! -s "$modulesfile" ]]; then
        timeout "${FASTFETCH_TIMEOUT}s" fastfetch
        return
    fi

    printf '%s' "${ESC}[2J${ESC}[3J${ESC}[H"
    [[ -s "$logofile" ]] && cat "$logofile"
    [[ -s "$modulesfile" ]] && cat "$modulesfile"
}

main() {
    if ! command -v fastfetch >/dev/null 2>&1; then
        echo "dualfetch.sh: fastfetch não encontrado no PATH" >&2
        exit 1
    fi

    local cols="${COLUMNS:-}"
    [[ -z "$cols" ]] && cols=$(tput cols 2>/dev/null)
    [[ -z "$cols" ]] && cols=80   # último recurso — nunca deixa cols vazio

    if (( cols >= WIDE_THRESHOLD )); then
        render_wide
    else
        render_narrow
    fi
}

main "$@"