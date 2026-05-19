#!/bin/bash

get_playing_icon() {
  local stat
  stat="$(playerctl status)"
  if [[ $stat != 'Playing' ]]; then
    echo ""
  else
    echo ""
  fi
}

get_current_player() {
  playerctl metadata -f "{{playerName}}" 2>/dev/null
}

get_player_icon() {
  case "$(get_current_player)" in
    firefox) echo "󰈹" ;;
    spotify) echo "" ;;
    chromium|chrome|google-chrome) echo "" ;;
    edge|microsoft-edge|microsoft-edge-beta|microsoft-edge-dev) echo "" ;;
    brave-browser|brave) echo "" ;;
    vlc) echo "󰕼" ;;
    mpv) echo "" ;;
    rhythmbox) echo "󰓃";;
    *) echo "" ;;
  esac
}

get_playing_string() {
  echo "$(get_player_icon) $(get_playing_icon) $(playerctl metadata -f '{{title}} - {{artist}}')"
}

toggle() {
  playerctl play-pause
}

player_menu() {
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
  
  echo $cx
  echo $cy
  echo $lx
  echo $ly
  echo $mx
  echo $my

  chosen="$(
    playerctl -l 2>/dev/null | sort -u | \
      fuzzel --dmenu \
        --anchor=top-left \
        --x-margin="$lx" \
        --y-margin="$ly" \
        --lines=10 \
        --minimal-lines \
        --width=22 \
        --no-sort \
        --placeholder="Select to Play/Pause"
  )"

  [ -n "$chosen" ] || exit 0
  playerctl -p "$chosen" play-pause
}

case "${1:-}" in 
  playing)
    get_playing_string
    ;;
  icon)
    get_playing_icon
    ;;
  play)
    toggle
    ;;
  menu)
    player_menu
    ;;
  *)
    echo "usage: $0 {playing|players|play}" >&2
    exit 1
    ;;
esac
