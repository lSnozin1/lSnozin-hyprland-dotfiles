source /usr/share/cachyos-fish-config/cachyos-config.fish

function fish_greeting
    if status is-interactive
        ~/.config/fastfetch/dualfetch.sh
    end
end


# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

