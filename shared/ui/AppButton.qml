import QtQuick
import QtQuick.Controls.Basic
import IDS_GIMBAL

Button {
    id: control

    font.pixelSize: Theme.fsBody
    padding: Theme.spacingNormal
    leftPadding: Theme.spacingLarge
    rightPadding: Theme.spacingLarge

    contentItem: Text {
        text: control.text
        font: control.font
        color: Theme.segOnText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitHeight: Theme.controlHeight
        implicitWidth: 100
        radius: Theme.rBtn
        color: !control.enabled ? Theme.idle
             : (control.down || control.checked) ? Qt.darker(Theme.acc, 1.25)
             : control.hovered ? Qt.lighter(Theme.acc, 1.1)
             : Theme.acc
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.text
    }
}
