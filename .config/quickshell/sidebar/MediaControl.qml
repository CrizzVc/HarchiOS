import QtQuick
import Quickshell
import Quickshell.Io

// Controles de reproduccion. Usa `playerctl` (lo mismo que tus keybinds):
// el modulo Mpris de quickshell no descubre jugadores aqui (players = 0),
// pero playerctl si ve spotify y brave.
Column {
    id: root

    spacing: 2
    width: 60

    property string status: ""
    readonly property bool available: status === "Playing" || status === "Paused"

    visible: available
    height: available ? 40 : 0

    Process {
        id: poll
        running: false
        command: ["sh", "-c", "playerctl status 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.status = root.raw(this.text).trim()
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    function raw(s) { return s === null || s === undefined ? "" : s }

    function run(cmd) {
        Quickshell.execDetached(["playerctl", cmd])
        status = "Playing"
        poll.running = true
    }

    component MediaBtn: Rectangle {
        id: btn
        required property string glyph
        property var action: () => {}
        width: 20
        height: 40
        radius: Theme.rSm
        color: hover.hovered ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
        Behavior on color { ColorAnimation { duration: 130 } }

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            font.family: Theme.fontIcon
            font.pixelSize: 19
            color: Theme.fgVar
        }

        HoverHandler { id: hover }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.action()
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter

        MediaBtn {
            glyph: "skip_previous"
            action: () => root.run("previous")
        }
        MediaBtn {
            glyph: root.status === "Playing" ? "pause" : "play_arrow"
            action: () => root.run("play-pause")
        }
        MediaBtn {
            glyph: "skip_next"
            action: () => root.run("next")
        }
    }
}
