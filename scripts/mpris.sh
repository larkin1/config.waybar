#!/bin/bash
get_playing_icon() {
  local stat
  if [[ $1 != 'Playing' ]]; then
    echo ""
  else
    echo ""
  fi
}

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

  if [ -n "$playing" ]; then
    echo "$playing" > "/tmp/waybar-state.mpris"
    IFS='|' read -r player stat track <<< "$playing"
  else
    playing=$(cat "/tmp/waybar-state.mpris")
    IFS='|' read -r player stat track <<< "$playing"
    stat="Paused"
  fi

  echo "$(get_player_icon "$player") $(get_playing_icon "$stat") $track"
}

get_player() {
  playing=$(cat "/tmp/waybar-state.mpris")
  IFS='|' read -r player stat track <<< "$playing"
  echo $player
}

play_current() {
  playerctl -p "$(get_player)" play-pause || playerctl play-pause
}

next_song() {
  playerctl -p "$(get_player)" next || playerctl next
}

prev_song() {
  playerctl -p "$(get_player)" previous || playerctl previous
}

player_menu() {
  width=50

  cx=$(hyprctl -j cursorpos | jq -r '[.x] | @tsv')
  cy=$(hyprctl -j cursorpos | jq -r '[.y] | @tsv')

  read -r mx my < <(
    hyprctl -j monitors |
      jq -r '.[] | select(.focused == true) | "\(.x) \(.y)"'
  )

  lx=$((cx - mx))
  ly=$((cy - my))

  lx=$((lx - 1))
  ly=$((ly - 25))
  
  player=$(
    printf "$(playerctl -l)\nvolume\npause-all\nplay-all" | fuzzel --dmenu \
    --anchor=top-left \
    --x-margin="$lx" \
    --y-margin="$ly" \
    --prompt="Player: " \
    --placeholder="Select a player to use or action..." \
    --lines=10 \
    --minimal-lines \
    --width=$width
  )

  if [ -z "$player" ]; then
    notify-send "Media menu exiting" "Reason: User aborted"
    exit 0
  fi

  case "$player" in
    pause-all)
      playerctl -a pause
    ;;
    play-all)
      playerctl -a play
    ;;
    volume)
      vol=$(
        printf "" | fuzzel --dmenu \
          --anchor=top-left \
          --x-margin="$lx" \
          --y-margin="$ly" \
          --prompt="Volume level: " \
          --placeholder="10 | +10 | -10dB | 0.5" \
          --lines=10 \
          --minimal-lines \
          --width=$width
      )
      if [ -z "$vol" ]; then
        notify-send "Media menu exiting" "Reason: User aborted"
        exit 0
      fi

      if [[ $vol =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]; then
        if [[ $vol == [+-]* ]] || awk "BEGIN { exit !($vol > 1) }"; then
          vol="${vol}%"
        fi
      fi

      if pactl set-sink-volume @DEFAULT_SINK@ "$vol"; then
        notify-send "Media menu" "Volume set"
      else
        notify-send "Media menu exiting" "Reason: Invalid volume set"
        exit 1
      fi
    ;;
    *)
      opt=$(
        printf "play\npause\nvolume\nnext\nprev" | fuzzel --dmenu \
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
        notify-send "Media menu exiting" "Reason: User aborted"
        exit 0
      fi
      case "$opt" in
        play)
          playerctl -p "$player" play
        ;;
        pause)
          playerctl -p "$player" pause
        ;;
        volume)
          vol=$(
            printf "" | fuzzel --dmenu \
              --anchor=top-left \
              --x-margin="$lx" \
              --y-margin="$ly" \
              --prompt="Volume level: " \
              --placeholder="0-100" \
              --lines=10 \
              --minimal-lines \
              --width=$width
          )
          if [ -z "$vol" ]; then
            notify-send "Media menu exiting" "Reason: User aborted"
            exit 0
          fi

          vol=$(awk "BEGIN { printf \"%.2f\", $vol / 100 }")

          if playerctl -p "$player" volume "$vol"; then
            notify-send "Media menu" "Volume set"
          else
            notify-send "Media menu exiting" "Reason: Invalid volume set"
          fi
        ;;
        next)
          playerctl -p "$player" next
        ;;
        previous)
          playerctl -p "$player" previous
        ;;
        *)
          notify-send "Media menu error" "Incorrect action"
          exit 1
        ;;
      esac
    ;;
  esac

}

case "${1:-}" in 
  playing) get_playing_string ;;
  menu) player_menu ;;
  play) play_current ;;
  next) next_song ;;
  prev) prev_song ;;
  *)
    echo "usage: $0 {playing|players|play}" >&2
    exit 1
    ;;
esac
