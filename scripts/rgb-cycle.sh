#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_THEME="${SCRIPT_DIR}/../current-theme.css"
BACKUP_THEME="${REAL_THEME}.bak"
TMP_THEME="/tmp/waybar-theme.css"

if [[ ! -f "$REAL_THEME" && ! -L "$REAL_THEME" ]]; then
    echo "ERROR: $REAL_THEME does not exist; put a real theme file there first." >&2
    exit 1
fi

if [[ -L "$REAL_THEME" ]] && [[ "$(readlink -f "$REAL_THEME")" == "$TMP_THEME" ]]; then
    if [[ -f "$BACKUP_THEME" ]]; then
        rm -f "$REAL_THEME"
        cp -- "$BACKUP_THEME" "$REAL_THEME"
    else
        echo "WARNING: $REAL_THEME points to $TMP_THEME but no backup exists; aborting." >&2
        exit 1
    fi
fi

if [[ ! -f "$REAL_THEME" ]]; then
    echo "ERROR: $REAL_THEME is not a regular file after restore; aborting." >&2
    exit 1
fi

cp -- "$REAL_THEME" "$BACKUP_THEME"
cp -- "$REAL_THEME" "$TMP_THEME"

rm -f "$REAL_THEME"
ln -s "$TMP_THEME" "$REAL_THEME"

# pkill -USR2 waybar || true

cleanup() {
    if [[ -f "$BACKUP_THEME" ]]; then
        rm -f "$REAL_THEME"
        cp -- "$BACKUP_THEME" "$REAL_THEME"
        rm -f "$BACKUP_THEME"
    fi
    rm -f "$TMP_THEME"
    pkill -USR2 waybar || true
    exit 0
}

trap cleanup INT TERM

step=0
while true; do
    color=$(python3 -c "
palette = [
    '#f5c2e7',  # pink
    '#cba6f7',  # mauve
    '#b4befe',  # lavender
    '#89b4fa',  # blue
    '#74c7ec',  # sapphire
    '#94e2d5',  # teal
    '#a6e3a1',  # green
    '#f9e2af',  # yellow
    '#fab387',  # peach
    '#eba0ac',  # maroon
    '#f38ba8',  # red
]

step = $step
blend_steps = 24

a = palette[(step // blend_steps) % len(palette)]
b = palette[(step // blend_steps + 1) % len(palette)]
t = (step % blend_steps) / blend_steps

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(rgb):
    return '#{:02x}{:02x}{:02x}'.format(*rgb)

ar, ag, ab = hex_to_rgb(a)
br, bg, bb = hex_to_rgb(b)

r = round(ar + (br - ar) * t)
g = round(ag + (bg - ag) * t)
b = round(ab + (bb - ab) * t)

print(rgb_to_hex((r, g, b)))
")

    python3 -c "
path = '$TMP_THEME'
color = '$color'
with open(path, 'r+') as f:
    lines = f.readlines()
    for i, line in enumerate(lines):
        if line.startswith('@define-color accent'):
            lines[i] = f'@define-color accent        {color};\\n'
            break
    f.seek(0)
    f.writelines(lines)
    f.truncate()
"

    step=$((step + 1))
    sleep 0.12
done
