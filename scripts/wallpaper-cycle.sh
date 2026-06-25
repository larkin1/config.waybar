#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/.config/wallpapers/catppuccin/"
STATE_FILE="/tmp/waybar-state.wallpaper"

walls=$(ls "$WALLPAPER_DIR")

if [ -z "$walls" ]; then
  echo "No wallpapers found in $WALLPAPER_DIR!"
  exit 1
fi

touch "$STATE_FILE"

mtr=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
current_wall=$(cat "$STATE_FILE")

if [ -z "$current_wall" ]; then
  case $1 in
    next)
      next_wall=$(echo "$walls" | head -n 1)
      ;;
    prev)
      next_wall=$(echo "$walls" | tail -n 1)
      ;;
    *)
      echo "Please specify an action (next/prev)"
      exit 1
      ;;
  esac
else
  case $1 in
    next)
      next_wall=$(echo "$walls" | grep -F -x "$current_wall" -A 1 | sed -n '2p')
      ;;
    prev)
      next_wall=$(echo "$walls" | grep -F -x "$current_wall" -B 1 | sed -n '1p')
      ;;
    *)
      echo "Please specify an action (next/prev)"
      exit 1
      ;;
  esac
fi

echo "$next_wall"

if [ -z "$next_wall" ]; then
  case $1 in
    prev)
      next_wall=$(echo "$walls" | tail -n 1)
      ;;
    next)
      next_wall=$(echo "$walls" | head -n 1)
      ;;
  esac
fi 

echo "$next_wall" > "$STATE_FILE"

hyprctl hyprpaper wallpaper "$mtr,$WALLPAPER_DIR/$next_wall"

notify-send "Wallpaper" "Changed wallpaper to $next_wall"
