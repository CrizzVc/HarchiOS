import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Control de volumen: rueda para subir/bajar, click para abrir el popup con slider.
//
// Lee y escribe con `wpctl` (lo mismo que usan tus keybinds) en vez del modulo
// Pipewire de quickshell: su nodo por defecto nunca llega a `ready` en 0.3.1,
// asi que reporta volumen 0 aunque el equipo este al 100%.
IconButton {
    id: root

    // La barra que aloja el popup (asi puede salirse del ancho de la barra)
    property Item host
    property bool popupOpen: false

    property real vol: 0
    property bool muted: false

    readonly property int pct: Math.round(Math.min(vol, 1) * 100)
    readonly property string glyph: muted || pct < 1 ? "volume_off"
                                  : pct > 66 ? "volume_up"
                                  : "volume_down"

    icon: glyph
    tooltip: ""          // sin tooltip: el popup ya muestra el porcentaje

    onClicked: popupOpen = !popupOpen
    onWheelUp:   setVol(pct + 5)
    onWheelDown: setVol(pct - 5)

    // ---- lectura ----
    Process {
        id: read
        running: false
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /Volume:\s*([0-9.]+)/.exec(root.raw(this.text))
                if (m) root.vol = parseFloat(m[1])
                root.muted = this.text.indexOf("MUTED") !== -1
            }
        }
    }

    Timer {
        id: refresh
        interval: 130
        running: false
        repeat: false
        onTriggered: read.running = true
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: read.running = true
    }

    // ---- escritura ----
    function raw(s) { return s === null || s === undefined ? "" : s }

    function setVol(v) {
        v = Math.max(0, Math.min(100, Math.round(v)))
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v + "%"])
        vol = v / 100          // feedback inmediato
        refresh.restart()
    }

    function toggleMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        muted = !muted
        refresh.restart()
    }

    function applyFromX(x) {
        setVol((x / slider.width) * 100)
    }

    // Posicion vertical del popup: binding (no funcionaba bien setearla a mano,
    // si se abria antes del reflow del layout salia en y=0).
    readonly property real popupTargetY: {
        if (!host) return 0
        return column.y + root.y + root.height / 2 - popupRoot.height / 2
    }

    // Contenedor: sombra y popup van en el mismo padre, asi el orden esta garantizado
    Item {
        id: popupRoot
        parent: root.host
        visible: root.popupOpen
        width: 184 + 6
        height: 74 + 7
        x: root.host ? root.host.width + 12 : 0
        y: root.host
           ? Math.max(4, Math.min(root.host.height - height - 4, root.popupTargetY))
           : 0

        Rectangle {                       // sombra (detrás)
            anchors.fill: parent
            radius: 18 + 3
            color: Qt.rgba(0, 0, 0, 0.45)
        }

        Rectangle {                       // popup (delante)
            id: popup
            x: 3
            y: 2
            width: 184
            height: 74
            radius: 18
            color: Theme.surfaceHigh
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.09)

            RowLayout {
                id: head
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 14
                height: 20
                spacing: 6

                Text {
                    text: root.glyph
                    font.family: Theme.fontIcon
                    font.pixelSize: 17
                    color: Theme.primary
                }
                Text {
                    text: root.muted ? "silenciado" : root.pct + "%"
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    color: Theme.fg
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "volumen"
                    font.family: Theme.fontUi
                    font.pixelSize: 10
                    color: Theme.outline
                }
            }

            Item {
                id: slider
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.bottomMargin: 16
                height: 22

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.surfaceLow

                    Rectangle {
                        width: parent.width * Math.min(root.pct, 100) / 100
                        height: parent.height
                        radius: 3
                        color: Theme.primary
                        Behavior on width { NumberAnimation { duration: 90 } }
                    }

                    Rectangle {          // pulsador
                        x: parent.width * Math.min(root.pct, 100) / 100 - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 13
                        height: 13
                        radius: 7
                        color: Theme.fg
                        border.width: 2
                        border.color: Theme.primary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    property bool dragging: false
                    onPressed: (m) => { dragging = true; root.applyFromX(m.x) }
                    onPositionChanged: (m) => { if (dragging) root.applyFromX(m.x) }
                    onReleased: dragging = false
                    onExited: dragging = false
                }
            }

            // click en la cabecera -> silenciar
            MouseArea {
                anchors.fill: head
                onClicked: root.toggleMute()
            }
        }
    }
}
