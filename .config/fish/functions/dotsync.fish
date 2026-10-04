function dotsync -d "Aplica dotfiles (stow) e sincroniza o sddm com checagens"
    argparse n/dry-run y/yes c/clean -- $argv; or return 1

    set -l repo ~/Documents/lSnozin-hyprland-dotfiles
    set -l src $repo/sddm/usr/share/sddm/
    set -l dst /usr/share/sddm/
    set -l conf_src $repo/sddm/etc/sddm.conf

    # --- pre-checagens ---
    for cmd in stow rsync git
        if not command -q $cmd
            echo "faltando: $cmd"
            return 1
        end
    end
    if test (id -u) -eq 0
        echo "nao rode como root"
        return 1
    end
    if not test -d $repo/.git
        echo "repo nao encontrado: $repo"
        return 1
    end
    if not test -d $src/themes; or not test -s $conf_src
        echo "sddm no repo incompleto, abortando (evita --delete perigoso)"
        return 1
    end

    # --- stow ---
    set -l mode -S
    set -q _flag_clean; and set mode -R
    set -l sn
    set -q _flag_dry_run; and set sn -n

    stow --no-folding $mode $sn -v -d $repo -t ~ .; or return 1
    stow --no-folding $mode $sn -v -d $repo -t ~ vsCode-Extensions; or return 1

    # --- sddm: ensaio por conteudo (-c), nao altera nada (-n) ---
    set -l flags -rlc --delete --chmod=D755,F644
    set -l changes (rsync $flags -n -i $src $dst); or return 1

    set -l conf_diff 0
    cmp -s /etc/sddm.conf $conf_src; or set conf_diff 1

    if test (count $changes) -eq 0; and test $conf_diff -eq 0
        echo "sddm: nada a atualizar."
    else
        set -l dels
        if test (count $changes) -gt 0
            set dels (printf '%s\n' $changes | string match '*deleting*')
            echo "sddm: diferencas em /usr/share/sddm ("(count $changes)" itens):"
            printf '%s\n' $changes | head -n 30
            test (count $changes) -gt 30; and echo "... e mais "(math (count $changes) - 30)
        end
        if test $conf_diff -eq 1
            echo "sddm: /etc/sddm.conf difere do repo:"
            diff /etc/sddm.conf $conf_src
        end

        set -q _flag_dry_run; and return 0

        set -l need s
        if test (count $dels) -gt 0
            set need sim
            set_color red
            echo "ATENCAO: "(count $dels)" arquivo(s) serao REMOVIDOS do sistema."
            set_color normal
        end

        if test "$need" = sim; or not set -q _flag_yes
            read -l -P "Aplicar? Digite '$need' para confirmar: " resp
            if not string match -qi -- $need $resp
                echo "Cancelado."
                return 1
            end
        end

        # --- backup + aplicacao ---
        set -l bk ~/.local/state/dotsync/(date +%Y%m%d-%H%M%S)
        mkdir -p $bk; or return 1

        if test (count $changes) -gt 0
            sudo rsync $flags --backup --backup-dir=$bk $src $dst; or return 1
        end
        if test $conf_diff -eq 1
            sudo cp -a /etc/sddm.conf $bk/sddm.conf; or return 1
            sudo install -m 644 -o root -g root $conf_src /etc/sddm.conf; or return 1
        end
        echo "sddm: aplicado. Backup em $bk"
    end

    # --- extras ---
    set -l broken (find ~/.config ~/.local/bin ~/.local/share/applications -xtype l -lname '*lSnozin-hyprland-dotfiles*' 2>/dev/null)
    if test (count $broken) -gt 0
        echo "links quebrados apontando pro repo (use dotsync --clean):"
        printf '%s\n' $broken
    end

    set -l pending (git -C $repo status --short | count)
    test $pending -gt 0; and echo "git: $pending arquivo(s) com mudancas nao commitadas"
    return 0
end