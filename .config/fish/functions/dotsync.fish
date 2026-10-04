function dotsync
    set -l repo ~/Documents/lSnozin-hyprland-dotfiles
    cd $repo; or return 1

    stow -R -v .; or return 1
    stow -R -v vsCode-Extensions; or return 1

    # Ensaio: compara por conteudo (-c), nao por data, e nao altera nada (-n)
    set -l changes (rsync -rlcn --delete -i sddm/usr/share/sddm/ /usr/share/sddm/)
    or return 1

    set -l conf_diff 0
    cmp -s /etc/sddm.conf sddm/etc/sddm.conf; or set conf_diff 1

    if test (count $changes) -eq 0; and test $conf_diff -eq 0
        echo "sddm: nada a atualizar."
        return 0
    end

    echo "sddm: diferencas encontradas:"
    printf '%s\n' $changes
    if test $conf_diff -eq 1
        diff /etc/sddm.conf sddm/etc/sddm.conf
    end

    read -l -P "Aplicar essas mudancas no sistema? [s/N] " resp
    if not contains -- $resp s S
        echo "Cancelado."
        return 1
    end

    sudo rsync -rlc --delete --chmod=D755,F644 sddm/usr/share/sddm/ /usr/share/sddm/; or return 1
    sudo install -m 644 -o root -g root sddm/etc/sddm.conf /etc/sddm.conf
end