#!/usr/bin/env bash
set -uo pipefail
width=50

connect_menu() {
  if ! bluetoothctl show | grep "PowerState: on"; then
    notify-send "Bluetooth menu" "Bluetooth off, unable to start"
    exit 1
  fi

  opt=""
  cx=$(hyprctl -j cursorpos | jq -r '[.x] | @tsv')
  cy=$(hyprctl -j cursorpos | jq -r '[.y] | @tsv')

  read -r mx my < <(
    hyprctl -j monitors |
      jq -r '.[] | select(.focused == true) | "\(.x) \(.y)"'
  )

  lx=$((cx - mx))
  ly=$((cy - my))

  lx=$((lx - 1))
  ly=$((ly - 35))

  while [ -z "$opt" ]; do
    opt=$(
      printf "search\nconnect existing" | fuzzel --dmenu \
      --anchor=top-left \
      --x-margin="$lx" \
      --y-margin="$ly" \
      --prompt="Action: " \
      --placeholder="Choose an option..." \
      --lines=10 \
      --minimal-lines \
      --width=$width
    )
    if [ -z "$opt" ]; then
      notify-send "Bluetooth menu exiting" "Reason: User aborted"
      exit 0
    fi

    case "$opt" in
      search)
        conn="$(
          {
            bluetoothctl devices \
              | sed -u 's/\x1b\[[0-9;]*m//g' \
              | grep -oP 'Device\s+\K[0-9A-F:]{17}\s+.+'
            bluetoothctl --timeout 10 scan on \
              | sed -u 's/\x1b\[[0-9;]*m//g' \
              | grep --line-buffered -oP '\[NEW\]\s+Device\s+\K[0-9A-F:]{17}\s+.+'
          } | fuzzel --dmenu \
            --anchor=top-left \
            --x-margin="$lx" \
            --y-margin="$ly" \
            --prompt="Select a device: " \
            --placeholder="Select to connect..." \
            --lines=10 \
            --width=$width
        )" || exit 0
        [ -z "$conn" ] && exit 0

        mac=$(echo "$conn" | awk '{print $1}')

        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
          notify-send "Bluetooth menu" "Device already connected. exiting..."
          exit 0
        fi

        if bluetoothctl connect "$mac"; then
          notify-send "Bluetooth menu" "Connected to $conn"
        else
          notify-send "Bluetooth menu error" "Failed to connect to $conn"
        fi
      ;;
      "connect existing")
        devices=$(
          bluetoothctl devices 2>/dev/null |
            grep -oP '[0-9A-F:]{17} .+' |
            sort -u
        )
        if [ -z "$devices" ]; then
          notify-send "Bluetooth menu error" "No saved devices found"
          exit 0
        fi
        conn=$(
          echo "$devices" | fuzzel --dmenu \
            --anchor=top-left \
            --x-margin="$lx" \
            --y-margin="$ly" \
            --prompt="Select a device: " \
            --placeholder="Select to connect..." \
            --lines=10 \
            --minimal-lines \
            --width=$width
        )
        mac=$(echo "$conn" | awk '{print $1}')

        if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
          notify-send "Bluetooth menu" "Device already connected. exiting..."
          exit 0
        fi

        notify-send "Bluetooth Menu" "Attempting to connect to $conn"
        if bluetoothctl connect "$mac"; then
          notify-send "Bluetooth menu" "Connected to $conn"
        else
          notify-send "Bluetooth menu error" "Failed to connect to $conn"
        fi
      ;;
      *)
        notify-send "Bluetooth menu error" "Incorrect action"
        opt=""
      ;;
    esac
  done
}

power_toggle() {
  if bluetoothctl show | grep "PowerState: on"; then
    bluetoothctl power off
    notify-send "Bluetooth" "Power State changed to: off"
  else
    bluetoothctl power on
    notify-send "Bluetooth" "Power State changed to: on"
  fi
}

case "${1:-}" in 
  menu) connect_menu ;;
  power_toggle) power_toggle ;;
  *)
    echo "usage: $0 {menu|power_toggle}" >&2
    exit 1
    ;;
esac
