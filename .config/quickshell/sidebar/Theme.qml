pragma Singleton

import QtQuick

// Paleta Material You oscura calida. Extraida de ~/.config/waybar/skwd-theme.css
// para que la barra lateral case con la waybar que ya tienes.
//
// Nota: las variantes "sobre X" NO se llaman onX porque QML interpretaria
// onX: como un manejador de senal de la propiedad x.
QtObject {
    readonly property color bg:          "#140c0b"
    readonly property color surface:     "#1a1110"
    readonly property color surfaceLow:  "#231918"
    readonly property color surfaceHigh: "#322826"
    readonly property color fg:          "#f1dedc"
    readonly property color fgVar:       "#d8c2bf"
    readonly property color primary:     "#ffb4ab"
    readonly property color primaryFg:   "#561e19"
    readonly property color primaryCont: "#73332e"
    readonly property color tertiary:    "#e0c38c"
    readonly property color outline:     "#a08c8a"
    readonly property color outlineVar:  "#534341"
    readonly property color error:       "#ff8f80"

    readonly property string fontUi:   "Rubik"
    readonly property string fontIcon: "Material Symbols Rounded"

    readonly property int rSm: 12
    readonly property int rMd: 16
    readonly property int rLg: 24

    // Geometria de la barra
    readonly property int barW: 80      // ancho visible de la barra
    readonly property int gap: 16       // margen respecto al borde del monitor
    readonly property int topGap: 10    // separacion respecto al borde superior
}
