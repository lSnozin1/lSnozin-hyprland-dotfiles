function cheat --description 'Show or search the personal cheat sheet'
    set -l file ~/.config/cheatsheet.md

    if not test -f $file
        echo "cheat: file not found: $file" >&2
        return 1
    end

    # With arguments: search the sheet, showing 1 line of context
    if test (count $argv) -gt 0
        rg --smart-case --context 1 -- $argv $file
        return
    end

    # Without arguments: print the whole sheet
    if type -q bat
        bat --language=markdown --style=plain --paging=never $file
    else
        cat $file
    end
end