#!/bin/sh
# Yet Another Luxurious but Laughably Unnecessary screenShot tool for Hyprland by Dregu
# Capture specific window, layer, region or output with a single command and pipe to satty.
# Usage: ./yallushot [region|window|output]

# TOLD YA!
# remember to add `windowrule = noanim,selection` or you will see slurp in your screenshots!

# PARAMS
# (none): shoots selected region OR clicked window/layer without decorations OR output when clicked outside a window/cancelled
# region: shoots selected region OR clicked window/layer with decorations
# window: shoots active window without decorations, ignores noscreenshare temporarily
# output: shoots active output

# REQUIRES
# slurp for aiming
# https://github.com/eriedaberrie/grim-hyprland for shooting (the standard one doesn't support hyprland window capture)
# satty for editing

# TODO
# that grim fork doesn't rotate rotated outputs in window mode

# OPTIONS
# margin is added to predefined non-fullscreen window regions in region mode to capture window decorations (make it < gaps)
MARGIN=12
DIR="$HOME/Pictures/Screenshots"
SLURP="slurp -d -b ffffff70 -B ffffff70"
GRIM="grim -t ppm"

NAME() {
  TIME=$(date +"%Y-%m-%d_%H-%M-%S_%N"|cut -b-23)
  echo "$DIR/shot_${TIME}_${1}.png"
}

SATTY() {
  satty -f - -o "$1" --init-tool brush --copy-command wl-copy --early-exit
}

# MAGIC, you can probably stop reading now
mkdir -p "$DIR"
WS=$(hyprctl monitors -j | jq -r '[.[].specialWorkspace.id, .[].activeWorkspace.id | select(. != null and . != 0)] | flatten | unique')
TOP=$(hyprctl -j layers | jq -r '.[].[]."2".[] | [.x,.y,.w,.h] | "\(.[0]),\(.[1]) \(.[2])x\(.[3])"')
OVERLAY=$(hyprctl -j layers | jq -r '.[].[]."3".[] | [.x,.y,.w,.h] | "\(.[0]),\(.[1]) \(.[2])x\(.[3])"')
if [ "$1" == "region" ]; then
  CLIENTS=$(hyprctl clients -j | jq --argjson WS "$WS" --argjson M $MARGIN -r '.[] | select(.workspace.id | IN($WS[])) | [.at[0], .at[1], .size[0], .size[1], (if .fullscreen == 1 then 0 else $M end)] | "\(.[0]-.[4]),\(.[1]-.[4]) \(.[2]+.[4]*2)x\(.[3]+.[4]*2)"')
  RECTS=$(echo -e "$TOP\n$OVERLAY\n$CLIENTS" | sed '/^$/N;/^\n/D')
  RECT=$(echo "$RECTS" | $SLURP 2> /dev/null)
  if [ ! -z "$RECT" ]; then
    FILE="$(NAME $1)"
    $GRIM -g "$RECT" - | (SATTY "$FILE"&)
  fi
elif [ "$1" == "window" ]; then
  ADDR=$(hyprctl activewindow -j | jq -r '.address')
  if [ ! -z "$ADDR" ]; then
    FILE="$(NAME $1)"
    hyprctl -q dispatch setprop address:$ADDR noscreenshare 0 lock
    $GRIM -w "$ADDR" - | (SATTY "$FILE"&)
    hyprctl -q dispatch setprop address:$ADDR noscreenshare unset
  fi
elif [ "$1" == "output" ]; then
  FILE="$(NAME $1)"
  $GRIM -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" - | ($SATTY "$FILE"&)
else
  CLIENTS=$(hyprctl clients -j | jq --argjson WS "$WS" -r '.[] | select(.workspace.id | IN($WS[])) | [.at[0], .at[1], .size[0], .size[1]] | "\(.[0]),\(.[1]) \(.[2])x\(.[3])"')
  RECTS=$(echo -e "$TOP\n$OVERLAY\n$CLIENTS" | sed '/^$/N;/^\n/D')
  RECT=$(echo -e "$RECTS" | $SLURP 2> /dev/null)
  WSID=$(hyprctl -j activeworkspace | jq -r .id)
  if [ -z "$RECT" ]; then
    FILE="$(NAME output)"
    $GRIM -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" - | (SATTY "$FILE"&)
    exit
  fi
  read X Y W H <<< $(echo "$RECT" | sed 's/[^0-9\-]/ /g')
  ADDR=$(hyprctl -j clients | jq -r "map(select(.at[0] == $X and .at[1] == $Y and .size[0] == $W and .size[1] == $H and .workspace.id == $WSID)).[].address")
  if [ ! -z "$ADDR" ]; then
    FILE="$(NAME window)"
    hyprctl -q dispatch setprop address:$ADDR noscreenshare 0 lock
    $GRIM -w "$ADDR" - | (SATTY "$FILE"&)
    hyprctl -q dispatch setprop address:$ADDR noscreenshare unset
  else
    FILE="$(NAME region)"
    $GRIM -g "$RECT" - | (SATTY "$FILE"&)
  fi
fi
