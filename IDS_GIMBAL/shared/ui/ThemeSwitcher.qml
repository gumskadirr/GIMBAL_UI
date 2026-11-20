import QtQuick
import IDS_GIMBAL

// Light / Blue / Dark selector. The choice goes to AppSettings; Main.qml binds Theme.mode to it.
SegmentedControl {
    id: root

    required property AppSettings settings
    readonly property var modes: ["light", "blue", "dark"]

    implicitWidth: 132
    model: [
        { iconPath: Icons.sun,  accessibleName: qsTr("Light theme") },
        { iconPath: Icons.drop, accessibleName: qsTr("Blue theme") },
        { iconPath: Icons.moon, accessibleName: qsTr("Dark theme") }
    ]
    currentIndex: Math.max(0, modes.indexOf(settings.theme))
    onActivated: index => root.settings.theme = root.modes[index]

    // A click breaks the currentIndex binding; the Preferences page can still change the theme.
    Connections {
        target: root.settings
        function onThemeChanged() { root.currentIndex = Math.max(0, root.modes.indexOf(root.settings.theme)) }
    }
}
