pragma Singleton

import QtQuick

// Estado compartido entre ventanas (la barra lateral y el lanzador).
// Los singleton se declaran en el qmldir, igual que Theme.
QtObject {
    property bool launcherOpen: false
}
