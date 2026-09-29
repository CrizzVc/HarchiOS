import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Barra lateral flotante anclada a la izquierda.
PanelWindow {
    id: win

    anchors { left: true; top: true; bottom: true }
    margins { left: Theme.gap; top: Theme.topGap; bottom: Theme.gap }

    // ancho de la superficie = barra + hueco + popup de volumen
    implicitWidth: Theme.barW + 12 + 184
    // hyprland suma margins.left a la zona exclusiva: 80 + 16 = 96
    exclusiveZone: Theme.barW
    exclusionMode: ExclusionMode.Normal

    color: "transparent"
    focusable: false
    WlrLayershell.namespace: "quickshell:sidebar"

    // Regiones que capturan clics (la superficie es mas ancha que la barra)
    Item { id: narrowMask; x: 0; y: 0; width: Theme.barW; height: win.height }
    Item { id: wideMask;   x: 0; y: 0; width: win.implicitWidth; height: win.height }
    mask: Region { item: volume.popupOpen ? wideMask : narrowMask }

    // Clic fuera de la barra -> cierra el popup (queda por debajo de `bar`)
    MouseArea {
        anchors.fill: parent
        onClicked: volume.popupOpen = false
    }

    Rectangle {
        id: bar
        width: Theme.barW
        height: win.height
        radius: Theme.rLg
        color: "#bf1a1110"      // 75%: deja ver el blur de hyprland (cristal esmerilado)
        border.width: 1
        border.color: "#18ffffff"

        // brillo superior sutil
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.055) }
                GradientStop { position: 0.30; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            IconButton {
                Layout.alignment: Qt.AlignHCenter
                icon: "apps"
                tooltip: "Aplicaciones"
                onClicked: AppState.launcherOpen = true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            Workspaces {
                Layout.alignment: Qt.AlignHCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            MediaControl {
                Layout.alignment: Qt.AlignHCenter
            }

            Volume {
                id: volume
                host: bar
                Layout.alignment: Qt.AlignHCenter
            }

            CpuRing {
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            ClockWidget {
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            IconButton {
                Layout.alignment: Qt.AlignHCenter
                icon: "lock"
                tooltip: "Bloquear"
                onClicked: Quickshell.execDetached(["/home/cris/.config/hypr/scripts/lock.sh"])
            }

            IconButton {
                id: powerBtn
                Layout.alignment: Qt.AlignHCenter
                icon: "power"
                danger: confirm
                tooltip: confirm ? "Otra vez para salir" : "Salir de la sesión"
                property bool confirm: false

                onClicked: {
                    if (confirm) {
                        Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                    } else {
                        confirm = true
                        resetTimer.restart()
                    }
                }

                Timer {
                    id: resetTimer
                    interval: 3000
                    onTriggered: powerBtn.confirm = false
                }
            }
        }
    }

    // Si el lanzador se abre, el popup de volumen queda debajo de el: cierralo.
    Connections {
        target: AppState
        function onLauncherOpenChanged() {
            if (AppState.launcherOpen) volume.popupOpen = false
        }
    }

    IpcHandler {
        target: "sidebar"
        function toggle(): void { volume.popupOpen = !volume.popupOpen }
        function close(): void  { volume.popupOpen = false }
    }
}
