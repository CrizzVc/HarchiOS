import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspaces en columna. Activo = pildora con acento, ocupado = fondo tenue.
Column {
    id: root

    spacing: 5
    width: 60

    readonly property int focused: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // 1..5 siempre presentes + cualquier workspace extra (max 10)
    readonly property var ids: {
        const live = Hyprland.workspaces.values
            .map(w => w.id)
            .filter(i => i > 0 && i <= 10);
        return Array.from(new Set([1, 2, 3, 4, 5].concat(live))).sort((a, b) => a - b);
    }

    Repeater {
        model: root.ids

        delegate: Rectangle {
            required property int modelData

            readonly property bool isFocused: modelData === root.focused
            readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === modelData)

            width: 60
            height: 30
            radius: Theme.rSm

            color: isFocused ? Theme.primary
                 : occupied  ? Theme.surfaceHigh
                 : area.containsMouse ? Qt.rgba(1, 1, 1, 0.07)
                 : "transparent"

            Behavior on color { ColorAnimation { duration: 160 } }

            scale: area.containsMouse && !isFocused ? 1.04 : 1.0
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: modelData
                font.family: Theme.fontUi
                font.pixelSize: 14
                font.bold: isFocused
                color: isFocused ? Theme.primaryFg
                     : occupied  ? Theme.fg
                     : Theme.outline
                Behavior on color { ColorAnimation { duration: 160 } }
            }

            // Indicador de foco a la izquierda
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 4
                width: 3
                height: isFocused ? 14 : 0
                radius: 2
                color: Theme.primaryFg
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Hyprland.dispatch("workspace " + modelData)
            }
        }
    }
}
