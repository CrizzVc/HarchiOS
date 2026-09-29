import QtQuick
import Quickshell

// Reloj apilado: hora / minuto (acento) / dia de la semana
Column {
    id: root
    spacing: 1
    width: 60

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(clock.date, "hh")
        font.family: Theme.fontUi
        font.pixelSize: 26
        font.bold: true
        color: Theme.fg
    }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(clock.date, "mm")
        font.family: Theme.fontUi
        font.pixelSize: 26
        font.bold: true
        color: Theme.primary
    }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(clock.date, "ddd").toUpperCase()
        font.family: Theme.fontUi
        font.pixelSize: 9
        font.letterSpacing: 2
        color: Theme.outline
    }
}
