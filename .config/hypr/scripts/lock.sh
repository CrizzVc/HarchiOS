#!/bin/bash
# Pantalla de bloqueo en dos fases:
# 1. hyprland-dialog: pantalla simple de confirmación
# 2. hyprlock: pantalla de autenticación con contraseña

# Fase 1: Pantalla de confirmación simple
hyprland-dialog \
    --title "Bloquear pantalla" \
    --message "¿Desea bloquear la pantalla?" \
    --buttons "Bloquear,Cancelar" \
    2>/dev/null

# Si el usuario cancela (código de salida distinto de 0), no hacemos nada
if [ $? -ne 0 ]; then
    exit 0
fi

# Fase 2: Lanzar hyprlock para autenticación real
exec hyprlock
