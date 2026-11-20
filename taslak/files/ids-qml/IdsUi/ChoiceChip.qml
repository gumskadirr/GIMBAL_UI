import QtQuick
import QtQuick.Templates as T
import IdsUi

// Radyo davranışlı küçük seçim çipi (örn. sürüm seçimi "v2.0").
// Aynı ebeveyn altındaki çipler birbirini dışlar (autoExclusive).
T.RadioButton {
    id: control

    implicitWidth: Math.max(64, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: 36
    leftPadding: 14
    rightPadding: 14
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    font.family: Theme.fontMono
    font.pixelSize: Theme.fsBody
    Accessible.name: text

    indicator: null

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.checked ? Theme.segOnText : Theme.text2
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: Theme.rBtn
        color: control.checked ? Theme.segOn : Theme.input
        border.width: 1
        border.color: control.checked ? Theme.segOn : (control.hovered ? Theme.muted : Theme.line2)
        FocusRing { visible: control.visualFocus }
    }
}
