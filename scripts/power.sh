#!/usr/bin/env bash
set -uo pipefail
width=30

menu() {
  opt=""

  cx=$(hyprctl -j cursorpos | jq -r '[.x] | @tsv')
  cy=$(hyprctl -j cursorpos | jq -r '[.y] | @tsv')

  read -r mx my < <(
    hyprctl -j monitors |
      jq -r '.[] | select(.focused == true) | "\(.x) \(.y)"'
  )

  lx=$((cx - mx))
  ly=$((cy - my))

  lx=$((lx - $width*8 - 10))
  ly=$((ly - 25))

  while [ -z "$opt" ]; do
    opt=$(
      printf "poweroff\nreboot\nsleep\nhibernate" | fuzzel --dmenu \
      --anchor=top-left \
      --x-margin="$lx" \
      --y-margin="$ly" \
      --prompt="Action: " \
      --placeholder="Enter an action..." \
      --lines=10 \
      --minimal-lines \
      --width=$width
    )
    if [ -z "$opt" ]; then
      notify-send "Power menu exiting" "Reason: User aborted"
      exit 0
    fi

    case "$opt" in
      poweroff)
        systemctl poweroff
      ;;
      hibernate)
        systemctl hibernate
      ;;
      sleep)
        systemctl sleep
      ;;
      reboot)
        systemctl reboot
      ;;
      *)
        notify-send "Power menu error" "Incorrect action"
        opt=""
      ;;
    esac
  done
}

case "${1:-}" in 
  menu) menu ;;
  *)
    echo "usage: $0 {menu}" >&2
    exit 1
    ;;
esac
