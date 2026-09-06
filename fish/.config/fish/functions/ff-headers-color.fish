function ff-headers-color
    set -l code $argv[1]
    for f in ~/.config/fastfetch/config.jsonc ~/.config/fastfetch/software.jsonc ~/.config/fastfetch/narrow-modules.jsonc
        sed -i -E 's/u001b\[[0-9;]*m([┌└])/u001b['"$code"'m\1/g' (realpath $f)
    end
end
