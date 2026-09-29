import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

// Anillo de uso de CPU con la muestra hecha en /proc/stat
Item {
    id: root

    width: 60
    height: 74

    property int pct: 0

    readonly property string cpuProg: 'BEGIN{
        while((getline line < "/proc/stat") > 0)
            if (line ~ /^cpu /) { split(line, f, " "); u1 = f[2]+f[4]; t1 = f[2]+f[3]+f[4]+f[5] }
        close("/proc/stat");
        system("sleep 0.7");
        while((getline line < "/proc/stat") > 0)
            if (line ~ /^cpu /) { split(line, f, " "); u2 = f[2]+f[4]; t2 = f[2]+f[3]+f[4]+f[5] }
        d = t2 - t1; if (d <= 0) d = 1;
        v = (u2 - u1) / d * 100;
        if (v < 0) v = 0; if (v > 100) v = 100;
        printf "%.0f", v
    }'

    Process {
        id: proc
        running: false
        command: ["awk", root.cpuProg]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text, 10);
                if (!isNaN(v)) root.pct = v;
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Shape {
        id: ring
        width: 54
        height: 54
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 2

        ShapePath {
            strokeWidth: 5
            strokeColor: Theme.surfaceHigh
            fillColor: "transparent"
            PathAngleArc {
                centerX: 27; centerY: 27
                radiusX: 22; radiusY: 22
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeWidth: 5
            strokeColor: Theme.primary
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 27; centerY: 27
                radiusX: 22; radiusY: 22
                startAngle: -90
                sweepAngle: 360 * Math.min(root.pct, 100) / 100
            }
        }
    }

    Text {
        anchors.centerIn: ring
        text: root.pct
        font.family: Theme.fontUi
        font.pixelSize: 14
        font.bold: true
        color: Theme.fg
    }

    Text {
        width: parent.width
        anchors.bottom: parent.bottom
        horizontalAlignment: Text.AlignHCenter
        text: "CPU"
        font.family: Theme.fontUi
        font.pixelSize: 9
        font.letterSpacing: 2
        color: Theme.outline
    }
}
