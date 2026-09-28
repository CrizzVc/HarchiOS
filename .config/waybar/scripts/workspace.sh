#!/usr/bin/env bash
# Estado del escritorio N para el waybar (salida JSON).
# Se usa porque en este Hyprland (config en Lua) el modulo nativo
# hyprland/workspaces envia "dispatch workspace N", que ya no es valido.
#
# Uso: workspace.sh <numero_de_escritorio>

n="${1:?falta el numero de escritorio}"

# hyprctl activeworkspace -j  ->  { "id": 2, "name": "2", ... }
active="$(hyprctl activeworkspace -j 2>/dev/null | grep -m1 '"id"' | tr -dc '0-9-')"
[ -n "$active" ] || active=1

if [ "$active" = "$n" ]; then
  printf '{"text":"%s","class":"active","tooltip":"Escritorio %s (activo)"}\n' "$n" "$n"
else
  printf '{"text":"%s","class":"empty","tooltip":"Escritorio %s"}\n' "$n" "$n"
fi
