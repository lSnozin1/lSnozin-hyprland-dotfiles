#!/usr/bin/env bash

# this is the 'core' of this fastfetch configuration, the main idea behind it is that fastfetch does not have a native way to display two 'columns'
# so this script runs fastfetch twice, once with the left column config and once with the right column config
# and then merges the output side by side when the terminal is wide enough, or stacks them when the terminal is narrow.
# it uses shell as its the most lightweight enough and interact directly with the terminal

# god knows how much AI helped with this script, and even the text in the comments
# but also, only god knows why native fastfetch is so limited, and why it doesn't have a native way to do this
# so yea, it is what it is, could be worse, could be better, but it works

# because it runs a script on top of the terminal, there has a chance for it to freeze the terminal for n reasons (like a overworked computer or smh)
# so it was projected to not freeze the terminal with some precautions:
#   - the two columns run in parallel 
#   - temporary files are always cleaned, even on error/Ctrl+C
#   - every fastfetch call has a timeout (FASTFETCH_TIMEOUT)
# if the timeout is reached, the script falls back to a normal fastfetch call instead of hanging

# bash thingy to make unexistent variables give a error and not silent treatment
set -u

# forces UTF-8 inside the script, no matter the outside environment. (kinda)
# without this, 'special characters' like nerd font icons, ascii art, all these characters beyond typical letters and numbers
# would be treated differently and would possibly break partially the fastfetch
# although it's kinda useless since the fastfetch config itself is already set to use UTF-8, but just in case, this is here
export LC_ALL=C.UTF-8

# verifies if fastfetch exists, >/dev/null is to not print it to the screen, 
if ! command -v fastfetch >/dev/null 2>&1; then
    # if fastfetch does not exists, exit with a error
    echo "dualfetch.sh: fastfetch não encontrado no PATH" >&2
    exit 1
fi

# makes the .config fastfetch folder a variable
CONFIG_DIR="$HOME/.config/fastfetch"

# makes the left, right and narrow modules config files variables
LEFT_CONFIG="$CONFIG_DIR/config.jsonc"
RIGHT_CONFIG="$CONFIG_DIR/SecColumn.jsonc"
NARROW_MODULES_CONFIG="$CONFIG_DIR/narrow-modules.jsonc"

# sets the threshold for the terminal width to switch between wide and 'narrow' mode
WIDE_THRESHOLD=180

# counted as seconds, the ceiling for each fastfetch call to run, if a single one takes more than this, it gets killed, 
# and the terminal opens without fastfetch instead of hanging
FASTFETCH_TIMEOUT=2

# sets the esc button as a variable, so it can be used in the script without having to write the escape sequence every time
ESC=$'\033'

# Temporary directory to store the output of the two fastfetch calls, will be cleaned up on exit
# uses TMPDIR if it already exists, otherwise creates it on /tmp, the XXXXXX sets a random suffix
# || exit 1 makes the script exit if the temporary directory cannot be created
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/dualfetch.XXXXXX") || exit 1

# deletes the temporary directory on exit, even if the script is interrupted by Ctrl+C or any other signal
trap 'rm -rf "$tmpdir"' EXIT

# sets run fastfetch as a function to be able to call it with different parameters, pretty much the main part of the script
run_fastfetch() {
    # $1 = config file | $2 = output file
    local config="$1" outfile="$2"

    # sets the timeout for the fastfetch call, if it takes longer than this, it will just open the terminal without fastfetch
    timeout "${FASTFETCH_TIMEOUT}s" fastfetch \
        -c "$config" --pipe false >"$outfile" 2>/dev/null
}

# renders the two columns side by side when the terminal is wide enough
render_wide() {
    # creates temporary files for the left and right columns, will be cleaned up on exit
    local leftraw="$tmpdir/left.raw"
    local rightraw="$tmpdir/right.raw"

    # Detecta o arquivo usado pelo logo no config do Fastfetch.
    #
    # O PNG tem 30 colunas de largura.
    # O miku.txt tem 44 colunas de largura.
    #
    # Como o ASCII é 14 colunas mais largo, deslocamos a coluna direita
    # exatamente essas 14 colunas quando o source for um arquivo de texto.

    # creates a variable for the logo source, logo extension and the right column start position
    local logo_source
    local logo_ext
    local RIGHT_COLUMN

    # finds the logo source on the config.jsonc file, sets it as a variable
    logo_source=$( sed -nE 's/^[[:space:]]*"source"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' \ "$LEFT_CONFIG" | head -n1 )

    # finds the logo extension, sets it as a variable
    logo_ext="${logo_source##*.}"
    # converts the logo extension to lowercase, so it can be compared with the case statement
    logo_ext="${logo_ext,,}"

    # sets the right column start position based on the logo extension, if it's a text file, it will be 14 columns to the right
    # needed becase miku is WIDE, though if a different png or ascii is used, it will not be adjusted dynamically, so you'll need to change it manually here
    case "$logo_ext" in
        txt|text|ascii)
            RIGHT_COLUMN=120
            ;;
        *)
            RIGHT_COLUMN=106
            ;;
    esac

    # Runs fastfetch for the left column in the background
    run_fastfetch "$LEFT_CONFIG" "$leftraw" &
    # stores the process id that that was just executed
    local pid_left=$!

    # same for the right column
    run_fastfetch "$RIGHT_CONFIG" "$rightraw" &
    local pid_right=$!
    # this makes the processes of both the left and right column run in parallel, reducing the total time it takes to render both columns

    # now that both processes are running in the background simultaneously, the script waits for them to finish
    wait "$pid_left"
    wait "$pid_right"

    # confirms if the above processes created the output files, and if it possess data/content, if not, it will just open the terminal without fastfetch
    if [[ ! -s "$leftraw" || ! -s "$rightraw" ]]; then
        timeout "${FASTFETCH_TIMEOUT}s" fastfetch
        return
    fi

    # transforms the right column output into an array
    mapfile -t right_lines < "$rightraw"

    # H moves the cursor to the top left corner of the terminal, 2J clears the screen, 3J clears the scrollback buffer
    printf '%s' "${ESC}[2J${ESC}[3J${ESC}[H"

    # prints the left column output, which is already formatted by fastfetch, so it can be printed as is
    cat "$leftraw"

    # creates two variables, line_index for the loop index and line_current for the current line of the right column
    local line_index line_current

    # does smth idk bro this is black magic for me
    # though the actual explanation is, it loops through the right column output array, and prints each line at the correct position on the terminal, 
    # using the RIGHT_COLUMN variable to set the starting position of the right column
    # in another another words, a 'for' in C style
    for (( line_index = 0; line_index < ${#right_lines[@]}; line_index++ )); do
        # gets the current line of the right column output
        line_current="${right_lines[line_index]}"

        # sets the cursor position to the correct position, that sets the text printed there correctly
        printf '%s%s' "${ESC}[$((line_index + 1));${RIGHT_COLUMN}H" "$line_current"
    done

    # creates two variables needed here
    local right_height final_row

    # sets right_height to the number of lines in the right column output array
    right_height=${#right_lines[@]}

    # adds 2 to the right_height to account for the top and bottom borders of the terminal, sets it as final_row
    final_row=$((right_height + 2))

    # adds a 2-line margin after the last line of the right column,
    # so the shell prompt doesn't end up right under the output
    printf '%s' "${ESC}[${final_row};1H"
}

# this function is used when the terminal enters 'narrow' mode, when the terminal width is less than WIDE_THRESHOLD
render_narrow() {
    # defines the temp file for the narrow fastfetch output, will be cleaned up on exit
    local narrow_fastfetch_output="$tmpdir/narrow_output.raw"

    # executes fastfetch with the narrow-modules.jsonc, and saves the output on the temp file above
    run_fastfetch "$NARROW_MODULES_CONFIG" "$narrow_fastfetch_output" &
    
    # saves the id of the above process
    local narrow_fastfetch_pid=$!

    # waits for it to finish
    wait "$narrow_fastfetch_pid"

    # if the output is empty because fastfetch failed or timed out or smh, fall back to a normal fastfetch call like either the config.jsonc or wtv fastfetch finds
    if [[ ! -s "$narrow_fastfetch_output" ]]; then
        timeout "${FASTFETCH_TIMEOUT}s" fastfetch
        return
    fi

    # same thing of before of H moves the cursor to the top left corner of the terminal, 2J clears the screen, 3J clears the scrollback buffer
    printf '%s' "${ESC}[2J${ESC}[3J${ESC}[H"

    # prints the file content
    cat "$narrow_fastfetch_output"
}

# main (duh)
main() {

    # sets cols as either COLUMNS, or, if it does not exist, as ""
    local cols="${COLUMNS:-}"

    # this verifies if the cols is "", and if it is, uses 'tput' to discover the terminal width
    [[ -z "$cols" ]] && cols=$(tput cols 2>/dev/null)

    # if COLUMNS did not exist, and tput fails, it uses value '80' as a fallback, never letting cols be empty
    [[ -z "$cols" ]] && cols=80

    # here it's where the script decides the mode to use, if cols >= wide threshold that is set at the beginning it uses the wide fetch mode
    # like, if cols is 80, and the threeshold is the default 160, then 80 >= 160 is not valid, so it does not render wide, and goes to render the narrow version
    if (( cols >= WIDE_THRESHOLD )); then
        render_wide
    else
        render_narrow
    fi  # really who made the end if shell script be literally a fi, like why, i hate this language
}

# calls the main function, and any argument alongside it if it exists
main "$@"