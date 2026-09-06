source /usr/share/cachyos-fish-config/cachyos-config.fish

function fish_greeting
    if status is-interactive
        ~/.config/fastfetch/dualfetch.sh
    end
end

# fica em 1 enquanto o terminal só tem o fetch (seguro pra redesenhar)
set -g __dualfetch_safe 1

# assim que você roda qualquer comando, marca como "não mexe mais"
function __dualfetch_mark_dirty --on-event fish_preexec
    set -g __dualfetch_safe 0
end

# só redesenha o fetch no resize se ainda estiver seguro
function __dualfetch_resize --on-signal WINCH
    if test "$__dualfetch_safe" = 1
        ~/.config/fastfetch/dualfetch.sh
    end
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

