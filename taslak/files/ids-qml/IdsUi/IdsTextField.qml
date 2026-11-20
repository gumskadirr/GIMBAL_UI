import QtQuick
import QtQuick.Templates as T
import IdsUi

// Sayısal / teknik değerler için varsayılan olarak monospace giriş alanı.
T.TextField {
    id: control

    property bool mono: true
    property bool compact: false
    property bool error: false
    property string suffix: ""          // örn. "°", "%", "ms"

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset, 160)
    implicitHeight: compact ? 34 : Theme.controlHeight
    leftPadding: 12
    rightPadding: suffix !== "" ? 12 + suffixText.implicitWidth + 6 : 12
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true
    hoverEnabled: true

    font.family: mono ? Theme.fontMono : Theme.fontSans
    font.pixelSize: Theme.fsBody
    color: readOnly ? Theme.muted : Theme.text
    selectionColor: Theme.acc
    selectedTextColor: "#FFFFFF"
    placeholderTextColor: Theme.label
    opacity: enabled ? 1 : 0.5

    Text {
        x: control.leftPadding
        width: control.width - control.leftPadding - control.rightPadding
        height: control.height
        verticalAlignment: Text.AlignVCenter
        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        elide: Text.ElideRight
        visible: !control.length && !control.preeditText
    }

    Text {
        id: suffixText
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: control.suffix
        font: control.font
        color: Theme.label
        visible: text !== ""
    }

    background: Rectangle {
        radius: Theme.rInp
        color: Theme.input
        border.width: 1
        border.color: control.error ? Theme.critTx
                    : control.activeFocus ? Theme.acc
                    : control.hovered ? Theme.muted : Theme.line2
    }
}
