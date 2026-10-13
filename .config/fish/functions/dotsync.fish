function dotsync -d "Apply dotfiles (stow) and sync sddm with safety checks"
    # dotsync - apply dotfiles (stow) and sync sddm files to the system
    #
    # Usage: dotsync [-n|--dry-run] [-y|--yes] [-c|--clean]
    #
    # What it does, in order:
    #   1. Pre-checks (tools, repo, sddm files, theme in sddm.conf)
    #   2. stow: symlinks the repo into ~ (root package + vsCode-Extensions)
    #   3. sddm: compares the repo with /usr/share/sddm and /etc/sddm.conf,
    #      shows the differences, asks for confirmation and applies with backup
    #   4. extras: reports broken links to the repo and uncommitted git changes
    #
    # Modes:
    #   (no flags)     Full run. Stow is applied right away. For sddm it shows
    #                  the differences and asks "Type 'y' to confirm" ('y' or
    #                  'yes' are accepted). Files are copied with sudo,
    #                  overwritten ones go to the backup.
    #
    #   -n, --dry-run  Simulation only. Stow runs with -n (shows what it would
    #                  link), sddm differences and pending removals are listed,
    #                  but nothing is changed, no prompt, no sudo, manifest is
    #                  not updated. Extras still run.
    #
    #   -y, --yes      Skips the normal "y" confirmation for sddm.
    #                  Does NOT skip the removal confirmation: if files will be
    #                  removed from the system, you must still type 'yes'.
    #
    #   -c, --clean    Stow runs in restow mode (-R) instead of -S: it unlinks
    #                  and relinks everything, which also removes dangling links
    #                  to files you deleted from the repo. The sddm part is
    #                  not affected.
    #
    #   Flags can be combined, e.g. "dotsync -n -c" simulates a clean restow.
    #
    # Removals (sddm):
    #   rsync runs WITHOUT --delete, so default sddm files are never touched.
    #   dotsync keeps a manifest of the files it installed last time. Files that
    #   are in the manifest but no longer in the repo are the only removal
    #   candidates, and they are MOVED to the backup, not deleted.
    #
    # Ignored files:
    #   Stray files inside sddm/ in the repo (.directory, .gitignore,
    #   .gitattributes, .gitkeep, *~, *.swp) are never copied to the system
    #   and never listed in the manifest.
    #
    # Files:
    #   ~/.local/state/dotsync/<timestamp>/   backup of overwritten/removed files
    #   ~/.local/state/dotsync/manifest       files installed by the last run
    #
    # Exit code: 0 on success, 1 on error, failed apply or cancelled confirmation.

    argparse n/dry-run y/yes c/clean -- $argv; or return 1

    set -l repo ~/Documents/lSnozin-hyprland-dotfiles
    set -l src $repo/sddm/usr/share/sddm/
    set -l dst /usr/share/sddm/
    set -l conf_src $repo/sddm/etc/sddm.conf
    set -l state ~/.local/state/dotsync
    set -l manifest $state/manifest

    # stray files that must never be copied to the system
    set -l ignore .directory .gitignore .gitattributes .gitkeep '*~' '*.swp'
    set -l excl
    set -l fnd
    for p in $ignore
        set -a excl --exclude=$p
        set -a fnd ! -name $p
    end

    # --- pre-checks ---
    for cmd in stow rsync git
        if not command -q $cmd
            echo "missing: $cmd"
            return 1
        end
    end
    if test (id -u) -eq 0
        echo "do not run as root"
        return 1
    end
    if not test -d $repo/.git
        echo "repo not found: $repo"
        return 1
    end
    if test (count $src/themes/*) -eq 0; or not test -s $conf_src
        echo "sddm files in the repo are incomplete, aborting"
        return 1
    end
    set -l theme (string match -rg '^\s*Current=\s*(\S+)' <$conf_src | head -n1)
    if test -n "$theme"; and not test -d $src/themes/$theme; and not test -d $dst/themes/$theme
        echo "theme '$theme' (Current= in sddm.conf) exists neither in the repo nor on the system"
        return 1
    end

    # --- stow ---
    set -l mode -S
    set -q _flag_clean; and set mode -R
    set -l sn
    set -q _flag_dry_run; and set sn -n

    stow --no-folding $mode $sn -v -d $repo -t ~ .; or return 1
    stow --no-folding $mode $sn -v -d $repo -t ~ vsCode-Extensions; or return 1

    # --- sddm: content-based dry run (-c), changes nothing (-n) ---
    set -l flags -rlpc --chmod=D755,Fa+r,Fgo-w $excl
    set -l changes (rsync $flags -n -i $src $dst); or return 1

    set -l conf_diff 0
    cmp -s /etc/sddm.conf $conf_src; or set conf_diff 1

    # files dotsync installed last time that are no longer in the repo
    set -l now (find $src ! -type d $fnd -printf '%P\n' | env LC_ALL=C sort)
    set -l gone
    if test -f $manifest
        for f in (env LC_ALL=C comm -23 $manifest (printf '%s\n' $now | psub))
            test -z "$f"; and continue
            string match -qr '(^/|(^|/)\.\.(/|$))' -- $f; and continue
            if test -e $dst/$f; or test -L $dst/$f
                set -a gone $f
            end
        end
    end

    set -l rc 0

    if test (count $changes) -eq 0; and test $conf_diff -eq 0; and test (count $gone) -eq 0
        echo "sddm: nothing to update."
        if not set -q _flag_dry_run; and test (count $now) -gt 0
            mkdir -p $state; and printf '%s\n' $now >$manifest
        end
    else
        if test (count $changes) -gt 0
            echo "sddm: differences in /usr/share/sddm ("(count $changes)" items):"
            printf '%s\n' $changes | head -n 30
            test (count $changes) -gt 30; and echo "... and "(math (count $changes) - 30)" more"
        end
        if test (count $gone) -gt 0
            set_color red
            echo "WARNING: "(count $gone)" file(s) you removed from the repo will be REMOVED from the system:"
            set_color normal
            printf '  %s\n' $gone
        end
        if test $conf_diff -eq 1
            if test -e /etc/sddm.conf
                echo "sddm: /etc/sddm.conf differs from the repo:"
                diff /etc/sddm.conf $conf_src
            else
                echo "sddm: /etc/sddm.conf does not exist, it will be created"
            end
        end

        set -l go 1
        set -l need y
        test (count $gone) -gt 0; and set need yes

        if set -q _flag_dry_run
            set go 0
        else if test "$need" = yes; or not set -q _flag_yes
            read -l -P "Apply? Type '$need' to confirm: " resp
            set -l accepted 0
            if test "$need" = yes
                string match -qi -- yes "$resp"; and set accepted 1
            else
                string match -qri -- '^(y|yes)$' "$resp"; and set accepted 1
            end
            if test $accepted -eq 0
                echo "sddm: cancelled (stow was already applied)."
                set go 0
                set rc 1
            end
        end

        # validate sudo BEFORE touching anything
        if test $go -eq 1; and not sudo -v
            echo "sddm: sudo failed, nothing was applied"
            set go 0
            set rc 1
        end

        if test $go -eq 1
            # --- backup + apply ---
            set -l bk $state/(date +%Y%m%d-%H%M%S)
            set -l ok 1
            mkdir -p $bk; or set ok 0

            if test $ok -eq 1; and test $conf_diff -eq 1; and test -e /etc/sddm.conf
                sudo cp -a /etc/sddm.conf $bk/sddm.conf; or set ok 0
            end
            if test $ok -eq 1; and test (count $changes) -gt 0
                sudo rsync $flags --backup --backup-dir=$bk $src $dst; or set ok 0
            end
            if test $ok -eq 1; and test (count $gone) -gt 0
                pushd $dst >/dev/null
                sudo rsync -aR --remove-source-files -- $gone $bk/; or set ok 0
                popd >/dev/null
            end
            if test $ok -eq 1; and test $conf_diff -eq 1
                sudo install -m 644 -o root -g root $conf_src /etc/sddm.conf; or set ok 0
            end

            if test $ok -eq 1
                test (count $now) -gt 0; and printf '%s\n' $now >$manifest
                echo "sddm: applied. Backup in $bk"
            else
                echo "sddm: FAILED midway (see the error above). Backup in $bk"
                set rc 1
            end
        end
    end

    # --- extras ---
    set -l broken (find ~/.config ~/.local/bin ~/.local/share/applications -xtype l -lname '*lSnozin-hyprland-dotfiles*' 2>/dev/null)
    if test (count $broken) -gt 0
        echo "broken links pointing to the repo (use dotsync --clean):"
        printf '%s\n' $broken
    end

    set -l pending (git -C $repo status --short | count)
    test $pending -gt 0; and echo "git: $pending file(s) with uncommitted changes"
    return $rc
end