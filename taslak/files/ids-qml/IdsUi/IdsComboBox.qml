import QtQuick
import QtQuick.Templates as T
import IdsUi

T.ComboBox {
    id: control

    property bool compact: false
    property bool mono: false

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
        width: ListView.view ? ListView.view.width : implicitWidth
        implicitHeight: 34
        leftPadding: 10
        rightPadding: 10
        hoverEnabled: true
        highlighted: control.highlightedIndex === index
        text: control.textRole
              ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole])
              : modelData
        font: control.font
        contentItem: Text {
            text: item.text
            font: item.font
            color: control.currentIndex === index ? Theme.text : Theme.text2
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
