import QtQuick

// Boton cuadrado redondeado con hover animado y tooltip a la derecha.
Rectangle {
    id: ctrl

    property string icon: ""
    property string tooltip: ""
    property bool   active: false
    property bool   danger: false
    property int    iconSize: 26

    signal clicked()
    signal wheelUp()
    signal wheelDown()

    implicitWidth: 60
    implicitHeight: 52
    radius: Theme.rMd

    color: danger   ? Qt.rgba(1, 0.56, 0.5, 0.18)
         : active   ? Theme.primary
         : area.containsMouse ? Qt.rgba(1, 1, 1, 0.09)
         : "transparent"

    Behavior on color { ColorAnimation { duration: 140 } }

    scale: area.containsMouse ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Text {
        anchors.centerIn: parent
        text: ctrl.icon
        font.family: Theme.fontIcon
        font.pixelSize: ctrl.iconSize
        color: ctrl.danger ? Theme.error
             : ctrl.active ? Theme.primaryFg
             : Theme.fgVar
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: ctrl.clicked()
        onWheel: (w) => {
            if (w.angleDelta.y > 0) ctrl.wheelUp();
            else if (w.angleDelta.y < 0) ctrl.wheelDown();
        }
    }

    // Tooltip flotante a la derecha del boton
    Rectangle {
        id: tip
        parent: ctrl
        visible: ctrl.tooltip !== "" && area.containsMouse
        x: ctrl.width + 12
        y: (ctrl.height - height) / 2
        width: tipText.implicitWidth + 22
        height: 28
        radius: 9
        color: Theme.surfaceHigh
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.09)
        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.92
        transformOrigin: Item.Left
        Behavior on opacity { NumberAnimation { duration: 130 } }
        Behavior on scale   { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

        Text {
            id: tipText
            anchors.centerIn: parent
            text: ctrl.tooltip
            color: Theme.fg
            font.family: Theme.fontUi
            font.pixelSize: 12
        }
    }
}
