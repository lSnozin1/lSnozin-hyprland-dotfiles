# GRUB Miku Dating Sim Override

My two braincells kept mixing up which CachyOS install was which at boot, so now Miku tells me directly. Nya~ ✨

## Upstream Dependency
- **Base theme:** [Thang1191/Miku-Dating-Sim-GRUB-Theme](https://github.com/Thang1191/Miku-Dating-Sim-GRUB-Theme)
- `install.sh` clones it automatically into a temp folder, installs it, and cleans up after itself.

## What Everything Does
- **`weird-linux.png` (1920x1080):** Edited copy of `arch.png` where Miku's gift box says `WEIRD LINUX` so the secondary CachyOS gets its own screen.
- **`40_custom`:** Replaces GRUB's auto-detected menu soup with just 3 entries (Primary CachyOS, Windows 11, Secondary CachyOS) using static `/boot/vmlinuz-linux-cachyos` paths and `--class weird-linux`.
- **`install.sh`:** Installs the base theme, drops in `weird-linux.png` and `40_custom` (backing up the old `40_custom` first), runs `chmod -x` on `/etc/grub.d/{10_linux,30_os-prober,30_uefi-firmware,31_efi_bootnext}` to hide fallback and `EFI BootNext` clutter, and rebuilds `/boot/grub/grub.cfg`.

## Run It
```bash
./install.sh
```

## Heads-Up (Before Running Elsewhere)
- **`40_custom` hardcodes this desktop's partition UUIDs** (`b1e4e6cc-c72e-44c7-b253-0e78321ed5a9`, `9022-B3B3`, `9ebf1173-18b8-460c-ad14-11bba386f3b6`). Update those if you ever reformat a drive or use this on another machine.
- If a big `grub` update resets `/etc/grub.d/` permissions and extra entries come back, just re-run `./install.sh`.

## Undo / Restore Default Entries
```bash
sudo chmod +x /etc/grub.d/10_linux /etc/grub.d/30_os-prober /etc/grub.d/30_uefi-firmware /etc/grub.d/31_efi_bootnext && sudo grub-mkconfig -o /boot/grub/grub.cfg
```
