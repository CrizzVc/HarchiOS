import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Lanzador de aplicaciones estilo Raycast (busca en los .desktop del sistema
// y los lanza con DesktopEntry.execute(), sin wofi).
//
// Es una ventana a pantalla completa, transparente y en capa overlay: solo
// dibuja la tarjeta de busqueda centrada. El fondo atenuado cubre toda la
// superficie, asi que hyprland le aplica su blur (la ventana reutiliza el
// namespace de la barra lateral y por eso vale la misma regla de blur).
PanelWindow {
    id: win

    visible: AppState.launcherOpen

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:sidebar"
    // Exclusive mientras este abierto: el teclado llega al campo sin tener
    // que clicar antes (focusable: true solo daria OnDemand).
    WlrLayershell.keyboardFocus: AppState.launcherOpen
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Resultados de la busqueda: objetos planos { entry, title, sub, icon }.
    property var results: []
    property int selected: 0

    // image://icon/ no sirve si el nombre no existe (devuelve una textura de
    // cuadros que nunca da Image.Error), asi que se consulta con check=true
    // y se dibuja una letra de respaldo cuando no hay icono.
    function iconSource(icon) {
        if (!icon) return ""
        if (icon.startsWith("/")) return "file://" + icon
        if (icon.startsWith("file:") || icon.startsWith("image:") || icon.startsWith("qrc:")) return icon
        return Quickshell.iconPath(icon, true)
    }

    function refresh(reset) {
        const q = query.text.trim().toLowerCase()
        const words = q ? q.split(/\s+/).filter(w => w.length > 0) : []
        const vals = DesktopEntries.applications.values
        const out = []

        for (let i = 0; i < vals.length; i++) {
            const a = vals[i]
            if (a.noDisplay || !a.name) continue

            const name = a.name.toLowerCase()
            const generic = (a.genericName || "").toLowerCase()
            const comment = (a.comment || "").toLowerCase()
            const extra = ((a.keywords || []).join(" ") + " "
                         + (a.categories || []).join(" ")).toLowerCase()
            const hay = name + " " + generic + " " + comment + " " + extra

            let score = 0
            if (words.length > 0) {
                let hit = true
                for (let j = 0; j < words.length; j++) {
                    if (hay.indexOf(words[j]) === -1) { hit = false; break }
                }
                if (!hit) continue
                const w = words[0]
                score = name === w ? 100
                      : name.startsWith(w) ? 90
                      : name.split(/\s+/).some(s => s.startsWith(w)) ? 80
                      : name.indexOf(w) !== -1 ? 70
                      : generic.indexOf(w) !== -1 ? 50
                      : 30
                if (words.every(w2 => name.indexOf(w2) !== -1)) score += 5
            }

            out.push({
                entry: a,
                title: a.name,
                // solo el genericName: el comentario suele ser una frase larga
                // o exactamente el nombre, y ahi el subtitulo no aporta nada
                sub: a.genericName && a.genericName.toLowerCase() !== name
                    ? a.genericName : "",
                icon: a.icon || "",
                score: score
            })
        }

        out.sort((x, y) => (y.score - x.score) || x.title.localeCompare(y.title))
        results = out
        if (reset) selected = 0
        else if (selected >= results.length)
            selected = results.length > 0 ? results.length - 1 : 0
    }

    function step(dir) {
        if (results.length === 0) return
        selected = Math.max(0, Math.min(results.length - 1, selected + dir))
        list.positionViewAtIndex(selected, ListView.Contain)
    }

    function launch(index) {
        const r = results[index]
        if (!r) return
        AppState.launcherOpen = false
        r.entry.execute()
    }

    function dismiss() { AppState.launcherOpen = false }

    function focusField() {
        if (!win.visible) return
        query.forceActiveFocus()
        query.cursorPosition = query.length
    }

    onVisibleChanged: {
        if (!visible) return
        query.clear()
        refresh(true)
        Qt.callLater(focusField)
        focusTimer.restart()
    }

    // El mapa de la superficie tarda un poco en tener foco: un reintento.
    Timer { id: focusTimer; interval: 80; onTriggered: win.focusField() }

    Component.onCompleted: refresh(false)
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { win.refresh(false) }
    }

    IpcHandler {
        target: "launcher"
        function open(): void { AppState.launcherOpen = true }
        function close(): void { AppState.launcherOpen = false }
        function toggle(): void { AppState.launcherOpen = !AppState.launcherOpen }
    }

    // ---- fondo atenuado: clic fuera de la tarjeta cierra ----
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        MouseArea { anchors.fill: parent; onClicked: win.dismiss() }
    }

    // ---- tarjeta centrada (sombra + panel en el mismo padre, como Volume) ----
    Item {
        id: wrap
        anchors.centerIn: parent
        width: panel.width + 6
        height: panel.height + 6

        Rectangle {                      // sombra (detrás)
            anchors.fill: parent
            radius: 21
            color: Qt.rgba(0, 0, 0, 0.5)
        }

        Rectangle {
            id: panel
            x: 3
            y: 3
            width: Math.min(640, win.width - 48)
            height: body.implicitHeight
            radius: 18
            color: "#bf1a1110"           // mismo cristal que la barra lateral
            border.width: 1
            border.color: "#18ffffff"

            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: body
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                // fila de busqueda: icono + texto, sin recuadro (estilo Raycast)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    spacing: 12

                    Text {
                        text: "search"
                        font.family: Theme.fontIcon
                        font.pixelSize: 20
                        color: Theme.fgVar
                    }

                    TextField {
                        id: query
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        placeholderText: "Buscar aplicaciones…"
                        font.family: Theme.fontUi
                        font.pixelSize: 17
                        font.weight: Font.Medium
                        color: Theme.fg
                        placeholderTextColor: Theme.outline
                        selectionColor: Theme.primaryCont
                        selectedTextColor: Theme.fg
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0
                        verticalAlignment: TextInput.AlignVCenter
                        background: Item {}
                        selectByMouse: true
                        onTextChanged: win.refresh(true)
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Down) { win.step(1); event.accepted = true }
                            else if (event.key === Qt.Key_Up) { win.step(-1); event.accepted = true }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { win.launch(win.selected); event.accepted = true }
                            else if (event.key === Qt.Key_Escape) { win.dismiss(); event.accepted = true }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                Text {
                    text: "Resultados"
                    Layout.leftMargin: 18
                    Layout.topMargin: 14
                    Layout.bottomMargin: 6
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                    color: Theme.outline
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: win.results.length > 0
                        ? Math.min(win.results.length, 8) * 54 : 64

                    ListView {
                        id: list
                        anchors.fill: parent
                        visible: win.results.length > 0
                        model: win.results
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            width: list.width
                            height: 54

                            Rectangle {          // resaltado de la selección
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                radius: 10
                                color: row.index === win.selected
                                    ? Qt.rgba(1, 1, 1, 0.075) : "transparent"
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                spacing: 12

                                Item {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28

                                    Image {
                                        id: appIcon
                                        anchors.fill: parent
                                        source: win.iconSource(row.modelData.icon)
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectFit
                                        visible: source != "" && status === Image.Ready
                                    }

                                    Rectangle {      // respaldo sin icono
                                        anchors.fill: parent
                                        radius: 7
                                        color: Theme.surfaceHigh
                                        visible: appIcon.source == "" || appIcon.status !== Image.Ready
                                        Text {
                                            anchors.centerIn: parent
                                            text: row.modelData.title.charAt(0).toUpperCase()
                                            font.family: Theme.fontUi
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: Theme.primary
                                        }
                                    }
                                }

                                Text {
                                    text: row.modelData.title
                                    Layout.maximumWidth: panel.width - 96
                                    font.family: Theme.fontUi
                                    font.pixelSize: 15
                                    font.weight: Font.Medium
                                    color: Theme.fg
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: row.modelData.sub
                                    visible: text.length > 0
                                    Layout.maximumWidth: 200
                                    font.family: Theme.fontUi
                                    font.pixelSize: 13
                                    color: Theme.outline
                                    elide: Text.ElideRight
                                }

                                Item { Layout.fillWidth: true }   // empuja a la izquierda
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: win.selected = row.index
                                onClicked: win.launch(row.index)
                            }
                        }
                    }

                    Text {                     // sin resultados
                        anchors.centerIn: parent
                        visible: win.results.length === 0
                        text: query.text.trim().length > 0 ? "Sin resultados" : "Sin aplicaciones"
                        font.family: Theme.fontUi
                        font.pixelSize: 14
                        color: Theme.outline
                    }

                    Rectangle {                // scrollbar cuando hay más de 8
                        x: parent.width - 8
                        visible: win.results.length > 8 && list.contentHeight > list.height + 1
                        width: 4
                        radius: 2
                        height: Math.max(24, list.height * list.height / list.contentHeight)
                        y: list.visibleArea.heightRatio >= 1 ? 0
                             : (list.height - height) * list.visibleArea.position
                               / (1 - list.visibleArea.heightRatio)
                        color: Qt.rgba(1, 1, 1, 0.25)
                    }
                }
            }
        }
    }
}
