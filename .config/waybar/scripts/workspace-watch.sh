#!/usr/bin/env bash
# Escucha los eventos de Hyprland (.socket2.sock) y avisa al waybar
# (senal SIGRTMIN+11) para que refresque los botones de escritorio al
# cambiar de espacio de trabajo con teclado, raton o cualquier otro medio.
# Es solo una optimizacion: los modulos tambien hacen polling como respaldo.

pidfile="${XDG_RUNTIME_DIR:-/tmp}/waybar-workspace-watch.pid"
if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null; then
  exit 0   # ya hay un vigilante en marcha
fi
echo $$ > "$pidfile"
trap 'rm -f "$pidfile"' EXIT

exec python3 - <<'PY'
import os, signal, socket, sys, time

SIG = signal.SIGRTMIN + 11

def waybar_pids():
    pids = []
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            with open(f"/proc/{pid}/comm", "r") as f:
                if f.read().strip() == "waybar":
                    pids.append(int(pid))
        except OSError:
            pass
    return pids

def notify():
    for pid in waybar_pids():
        try:
            os.kill(pid, SIG)
        except OSError:
            pass

def run():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/run/user/1000")
    if not sig:
        return False
    path = os.path.join(runtime, "hypr", sig, ".socket2.sock")
    if not os.path.exists(path):
        return False

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.connect(path)
    except OSError:
        return False

    buf = b""
    eventos = (b"workspacev2>>", b"workspace>>", b"createworkspace", b"destroyworkspace",
               b"focusedmonv2>>", b"activespecial", b"configreloaded")
    try:
        while True:
            data = s.recv(4096)
            if not data:
                return True
            buf += data
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                if any(line.startswith(e) for e in eventos):
                    time.sleep(0.05)  # deja que Hyprland termine el cambio
                    notify()
    finally:
        s.close()

while True:
    try:
        if not run():
            sys.exit(0)   # sin Hyprland no hay nada que vigilar
    except Exception:
        pass
    time.sleep(2)         # reconecta si el socket se cayo
PY
