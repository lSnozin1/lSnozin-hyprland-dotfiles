#!/usr/bin/env bash

# Thresholds
CPU_TEMP_MAX=85
GPU_TEMP_MAX=80
CPU_USE_MAX=85
RAM_MAX=85
VRAM_MAX=85
COOLDOWN=10   # seconds between repeated alerts of the same type

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sysalert"
mkdir -p "$STATE_DIR"

alert() {
    local key="$1" title="$2" msg="$3"
    local f="$STATE_DIR/$key" now last=0
    now=$(date +%s)
    [[ -f $f ]] && last=$(<"$f")
    if (( now - last >= COOLDOWN )); then
        notify-send -u critical "$title" "$msg"
        echo "$now" > "$f"
    fi
}

# CPU temperature
cpu_temp=$(sensors | awk '/^Tctl:/ {print int($2)}')

# CPU usage (sampled over 1s)
read -r _ a1 b1 c1 d1 e1 f1 g1 _ < /proc/stat
sleep 1
read -r _ a2 b2 c2 d2 e2 f2 g2 _ < /proc/stat
idle=$(( (d2+e2) - (d1+e1) ))
total=$(( (a2+b2+c2+d2+e2+f2+g2) - (a1+b1+c1+d1+e1+f1+g1) ))
cpu_use=$(( 100 * (total - idle) / total ))

# RAM (uses "available", not "used")
ram_pct=$(free -m | awk '/^Mem:/ {printf "%d", ($2-$7)*100/$2}')

# GPU
IFS=', ' read -r gpu_temp vram_used vram_total < <(nvidia-smi --query-gpu=temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits)
vram_pct=$(( 100 * vram_used / vram_total ))

(( cpu_temp > CPU_TEMP_MAX )) && alert cpu_temp "CPU hot" "Temperature: ${cpu_temp}°C"
(( gpu_temp > GPU_TEMP_MAX )) && alert gpu_temp "GPU hot" "Temperature: ${gpu_temp}°C"
(( cpu_use > CPU_USE_MAX ))   && alert cpu_use  "High CPU usage" "${cpu_use}% in use"
(( ram_pct > RAM_MAX ))       && alert ram      "RAM almost full" "${ram_pct}% in use"
(( vram_pct > VRAM_MAX ))     && alert vram     "GPU memory almost full" "${vram_pct}% in use (${vram_used}/${vram_total} MiB)"

exit 0