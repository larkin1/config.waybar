#!/bin/bash

# Configuration
WALLPAPER_DIR="$HOME/.config/hypr/wallpapers/catppuccin/"  # Directory containing wallpapers
# MONITOR="HDMI-A-1"                    # Target monitor (replace with your monitor name)
STATE_FILE="$HOME/.config/hypr/wallpapers/state"  # State file to store current index

# Ensure wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
  echo "Wallpaper directory $WALLPAPER_DIR does not exist!"
  exit 1
fi

# Get list of wallpapers (assuming 1.png, 2.png, etc.)
WALLPAPERS=($(ls "$WALLPAPER_DIR" | grep -E '^[0-9]+\.png$' | sort -n))
TOTAL_WALLPAPERS=${#WALLPAPERS[@]}

# Check if there are any wallpapers
if [ $TOTAL_WALLPAPERS -eq 0 ]; then
  echo "No wallpapers found in $WALLPAPER_DIR!"
  exit 1
fi

MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
if [ -z "$MONITOR" ]; then
  echo "Could not determine focused monitor!"
  exit 1
fi

# Read current index from state file, default to 0 if not exists
if [ -f "$STATE_FILE" ]; then
  CURRENT_INDEX=$(cat "$STATE_FILE")
else
  CURRENT_INDEX=0
fi

# Calculate next index
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % TOTAL_WALLPAPERS ))

# Get next wallpaper
NEXT_WALLPAPER="${WALLPAPERS[$NEXT_INDEX]}"

# Update hyprpaper
hyprctl hyprpaper unload all
hyprctl hyprpaper preload "$WALLPAPER_DIR/$NEXT_WALLPAPER"
hyprctl hyprpaper wallpaper "$MONITOR,$WALLPAPER_DIR/$NEXT_WALLPAPER"

# Save next index to state file
echo "$NEXT_INDEX" > "$STATE_FILE"

echo "Set wallpaper to $NEXT_WALLPAPER on $MONITOR"
