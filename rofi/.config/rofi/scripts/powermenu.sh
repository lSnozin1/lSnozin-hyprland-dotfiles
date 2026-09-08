#!/usr/bin/env bash

shutdown="<span font=\"22\">⏻</span>   Desligar"
reboot="<span font=\"22\">󰜉</span>   Reiniciar"
lock="<span font=\"22\">ꗃ</span>   Bloquear"
suspend="<span font=\"22\">󰤄</span>   Suspender"
logout="<span font=\"22\">󰍃</span>   Sair"

options="$shutdown
$reboot
$lock
$suspend
$logout"

selected=$(echo -e "$options" | rofi -dmenu -i -markup-rows -p "Power Menu" -theme ~/.config/rofi/powermenu.rasi)

case "$selected" in
    *Desligar*)
        systemctl poweroff
        ;;
    *Reiniciar*)
        systemctl reboot
        ;;
    *Bloquear*)
        hyprlock
        ;;
    *Suspender*)
        systemctl suspend
        ;;
    *Sair*)
        hyprctl dispatch exit
        ;;
esac
