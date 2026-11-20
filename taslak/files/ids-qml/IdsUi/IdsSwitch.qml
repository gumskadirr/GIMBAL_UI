import QtQuick
import QtQuick.Templates as T
import IdsUi

// 40x22 anahtar. Etiketli satır için ToggleRow kullanın.
T.Switch {
    id: control

    implicitWidth: implicitIndicatorWidth + leftPadding + rightPadding
    implicitHeight: Math.max(implicitIndicatorHeight + topPadding + bottomPadding, 22)
    padding: 0
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5
    Accessible.name: text

    indicator: Rectangle {
        implicitWidth: 40
        implicitHeight: 22
        x: control.leftPadding
        y: (control.height - height) / 2
        radius: height / 2
        color: control.checked ? Theme.acc : Theme.line2

        Rectangle {
            width: 16; height: 16; radius: 8
            y: 3
            x: control.checked ? 21 : 3
            color: "#FFFFFF"
            border.width: 1
            border.color: "#1F000000"
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
        FocusRing { visible: control.visualFocus; baseRadius: parent.radius }
    }

    contentItem: Item {}
}
