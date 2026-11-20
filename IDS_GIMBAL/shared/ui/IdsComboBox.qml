pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import IDS_GIMBAL

T.ComboBox {
    id: control

    property bool compact: false
    property bool mono: false
    // When set, the selection follows this value (matched via valueRole), also after the model is
    // rebuilt (e.g. a retranslated model) and after a user choice the owner did not accept.
    // A plain `currentIndex: indexOfValue(x)` binding is evaluated before the model is populated.
    property var selectedValue

    function _syncSelection() {
        if (selectedValue !== undefined)
            currentIndex = indexOfValue(selectedValue)
    }
    onSelectedValueChanged: _syncSelection()
    onCountChanged: _syncSelection()
    onModelChanged: Qt.callLater(_syncSelection)
    onActivated: Qt.callLater(_syncSelection)
    Component.onCompleted: _syncSelection()

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: compact ? 34 : Theme.controlHeight
    leftPadding: 12
    rightPadding: 12 + 16 + 8
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5

    font.family: mono ? Theme.fontMono : Theme.fontSans
    font.pixelSize: Theme.fsBody

    delegate: T.ItemDelegate {
        id: item
        required property int index
        required property var model

        width: ListView.view ? ListView.view.width : implicitWidth
        implicitHeight: 34
        leftPadding: 10
        rightPadding: 10
        hoverEnabled: true
        highlighted: control.highlightedIndex === index
        // JS arrays expose each element as modelData; item models expose roles directly.
        text: !control.textRole ? item.model.modelData
              : Array.isArray(control.model) ? item.model.modelData[control.textRole]
              : item.model[control.textRole]
        font: control.font
        contentItem: Text {
            text: item.text
            font: item.font
            color: control.currentIndex === item.index ? Theme.text : Theme.text2
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: Theme.rSmall
            color: item.highlighted || item.hovered ? Theme.input : "transparent"
        }
    }

    indicator: Icon {
        x: control.width - width - 12
        y: (control.height - height) / 2
        width: 16; height: 16
        path: Icons.chevronDown
        color: Theme.muted
        strokeWidth: 2.2
    }

    contentItem: Text {
        text: control.displayText
        font: control.font
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: Theme.rInp
        color: Theme.input
        border.width: 1
        border.color: control.visualFocus || control.popup.visible ? Theme.acc
                    : control.hovered ? Theme.muted : Theme.line2
    }

    popup: T.Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, 320)
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
        }

        background: Rectangle {
            radius: Theme.rInp
            color: Theme.card
            border.width: 1
            border.color: Theme.line2
        }
    }
}
