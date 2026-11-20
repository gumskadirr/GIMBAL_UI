import QtQuick
import QtQuick.Templates as T
import IdsUi

T.Slider {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitHandleWidth + leftPadding + rightPadding, 200)
    implicitHeight: Math.max(implicitHandleHeight + topPadding + bottomPadding, 24)
    padding: 0
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        implicitHeight: 6
        height: implicitHeight
        radius: 3
        color: Theme.track
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 3
            color: Theme.acc
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        implicitWidth: 18
        implicitHeight: 18
        radius: 9
        color: "#FFFFFF"
        border.width: 2
        border.color: control.pressed || control.hovered ? Theme.accHover : Theme.acc
        FocusRing { visible: control.visualFocus; baseRadius: 9 }
    }
}
