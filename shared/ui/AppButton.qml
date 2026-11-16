import QtQuick
import QtQuick.Controls.Basic
import IDS_GIMBAL

Button {
    id: control

    font.pixelSize: Theme.fontSizeNormal
    padding: Theme.spacingNormal
    leftPadding: Theme.spacingLarge
    rightPadding: Theme.spacingLarge

    contentItem: Text {
        text: control.text
        font: control.font
        color: Theme.textOnAccent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitHeight: Theme.controlHeight
        implicitWidth: 100
        radius: Theme.radius
        color: !control.enabled ? Theme.disabled
             : (control.down || control.checked) ? Qt.darker(Theme.accent, 1.25)
             : control.hovered ? Qt.lighter(Theme.accent, 1.1)
             : Theme.accent
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.focus
    }
}
