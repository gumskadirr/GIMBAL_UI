pragma Singleton
import QtQuick

// Single source of colors and sizes. Palette is a temporary neutral one until the IDS palette is chosen.
QtObject {
    property bool dark: true

    readonly property color background:    dark ? "#1e1f22" : "#f5f6f8"
    readonly property color surface:       dark ? "#2b2d31" : "#ffffff"
    readonly property color textPrimary:   dark ? "#e8e8e8" : "#1d1f23"
    readonly property color textSecondary: dark ? "#a0a4ab" : "#5b616b"
    readonly property color accent:        dark ? "#4c8dff" : "#2563eb"
    readonly property color textOnAccent:  "#ffffff"
    readonly property color warning:       dark ? "#e0a030" : "#b7791f"
    readonly property color error:         dark ? "#e5534b" : "#c53030"
    readonly property color border:        dark ? "#3c3f45" : "#d4d7dc"
    readonly property color disabled:      dark ? "#5c6068" : "#a8adb5"
    readonly property color focus:         dark ? "#8ab4ff" : "#1d4ed8"

    // Font family: system default inherited by all controls until the IDS font is chosen.
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 14
    readonly property int fontSizeLarge: 18

    readonly property int spacingSmall: 4
    readonly property int spacingNormal: 8
    readonly property int spacingLarge: 16
    readonly property int radius: 4
    readonly property int controlHeight: 32
}
