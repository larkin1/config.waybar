#!/bin/bash
get_playing_icon() {
  local stat
  if [[ $1 != 'Playing' ]]; then
    echo ""
  else
    echo ""
  fi
}

# get_player_icon() {
#   case "$1" in
#     firefox) echo "󰈹" ;;
#     spotify) echo "" ;;
#     chromium|chrome|google-chrome) echo "" ;;
#     edge|microsoft-edge|microsoft-edge-beta|microsoft-edge-dev) echo "" ;;
#     brave-browser|brave) echo "" ;;
#     vlc) echo "󰕼" ;;
#     mpv) echo "" ;;
#     rhythmbox) echo "󰓃";;
#     *) echo "" ;;
#   esac
# }

get_player_icon() {
  case "$1" in
    firefox) echo '<span foreground="#fab387">󰈹</span>' ;;
    spotify) echo '<span foreground="#a6e3a1"></span>' ;;
    chromium|chrome|google-chrome) echo '<span foreground="#94e2d5"></span>' ;;
    edge|microsoft-edge|microsoft-edge-beta|microsoft-edge-dev) echo '<span foreground="#74c7ec"></span>' ;;
    brave-browser|brave) echo '<span foreground="#f38ba8"></span>' ;;
    vlc) echo '<span foreground="#fab387">󰕼</span>' ;;
    mpv) echo '<span foreground="#cba6f7"></span>' ;;
    rhythmbox) echo '<span foreground="#f9e2af">󰓃</span>' ;;
    *) echo '' ;;
  esac
}

get_playing_string() {
  items="$(playerctl -a metadata -f '{{playerName}}|{{status}}|{{markup_escape(title)}} - {{markup_escape(artist)}}' 2>/dev/null)"

  playing="$(grep '|Playing|' <<< "$items" | head -n1)"

  [ -n "$playing" ] || playing="$(head -n1 <<< "$items")"

  IFS='|' read -r player stat track <<< "$playing"

  echo "$(get_player_icon "$player") $(get_playing_icon "$stat") $track"
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
  menu)
    player_menu
    ;;
  *)
    echo "usage: $0 {playing|players|play}" >&2
    exit 1
    ;;
esac
