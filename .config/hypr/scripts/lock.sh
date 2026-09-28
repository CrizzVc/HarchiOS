#!/bin/bash
# Pantalla de bloqueo con hyprlock.
#
# Nota: antes aqui habia un hyprland-dialog de confirmacion, pero se llamaba
# con --message (hyprland-dialog usa --text) y eso hacia que el script saliera
# con codigo 1 -> lock.sh abortaba sin llegar a lanzar hyprlock. Por eso
# Super+L no bloqueaba nada.

exec hyprlock "$@"
