import QtQuick
import IdsUi

// Efekt modülü gerektirmeyen yumuşak gölge (yazılım renderer'da da çalışır).
// Gölge verilecek öğenin arkasına, aynı boyutta yerleştirin:
//   Shadow { anchors.fill: panel; radius: Theme.rCard; z: -1 }
Item {
    id: root

    property real radius: Theme.rCard
    property real spread: 20
    property real offsetX: 0
    property real offsetY: 12
    property color color: Theme.shadowColor
    property int steps: 10

    Repeater {
        model: root.steps
        Rectangle {
            required property int index
            readonly property real grow: (index + 1) * root.spread / root.steps
            x: -grow + root.offsetX
            y: -grow + root.offsetY
            width: root.width + 2 * grow
            height: root.height + 2 * grow
            radius: root.radius + grow
            color: Qt.rgba(root.color.r, root.color.g, root.color.b, root.color.a * 1.6 / root.steps)
            antialiasing: true
        }
    }
}
