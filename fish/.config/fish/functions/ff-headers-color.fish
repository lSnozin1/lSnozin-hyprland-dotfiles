function ff-headers-color
    set -l code $argv[1]
    sed -i 's/u001b\[[0-9;]*m/u001b['$code'm/g' ~/.config/fastfetch/config.jsonc ~/.config/fastfetch/software.jsonc ~/.config/fastfetch/narrow-modules.jsonc
end
