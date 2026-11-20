import QtQuick
import IdsUi

// Açık / Mavi / Koyu tema seçici. Theme.mode ile çift yönlü bağlı.
SegmentedControl {
    id: root
    readonly property var modes: ["light", "blue", "dark"]

    implicitWidth: 132
    model: [
        { iconPath: Icons.sun,  accessibleName: qsTr("Light theme") },
        { iconPath: Icons.drop, accessibleName: qsTr("Blue theme") },
        { iconPath: Icons.moon, accessibleName: qsTr("Dark theme") }
    ]
    currentIndex: Math.max(0, modes.indexOf(Theme.mode))
    onActivated: (index) => Theme.mode = modes[index]

    Connections {
        target: Theme
        function onModeChanged() { root.currentIndex = Math.max(0, root.modes.indexOf(Theme.mode)) }
    }
}
