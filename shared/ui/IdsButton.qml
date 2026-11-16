import QtQuick
import QtQuick.Templates as T
import IDS_GIMBAL

// variant: "primary" | "secondary" | "quiet" | "danger"
// compact: 32 px height (card header, toolbar)
// checked: selected look (tabs, page switches), same colors as the selected navigation item
T.Button {
    id: control

    property string variant: "secondary"
    property string iconPath: ""
    property string trailingIconPath: ""
    property bool compact: false

    readonly property color _bg: {
        if (checked)
            return Theme.navOn
        switch (variant) {
        case "primary": return hovered ? Theme.accHover : Theme.acc
        case "danger": return Theme.danger
        case "quiet": return hovered ? Theme.input : "transparent"
        default: return hovered ? Theme.raised : Theme.input
        }
    }
    readonly property color _border: checked ? Theme.navRing
                                   : variant === "primary" ? Theme.acc
                                   : variant === "danger" ? Theme.danger : Theme.line2
    readonly property color _fg: {
        if (checked)
            return Theme.navOnText
        switch (variant) {
        case "primary": case "danger": return "#FFFFFF"
        case "quiet": return hovered ? Theme.text2 : Theme.muted
        default: return Theme.text2
        }
    }

    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: compact ? Theme.controlHeightSm : Theme.controlHeight
    leftPadding: compact ? 12 : 16
    rightPadding: leftPadding
    spacing: 8
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : 0.5

    font.family: Theme.fontSans
    font.pixelSize: compact ? Theme.fsSmall : Theme.fsBody
    font.weight: Font.DemiBold

    Accessible.name: text

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        Row {
            id: row
            anchors.centerIn: parent
            spacing: control.spacing
            Icon {
                width: 15; height: 15
                anchors.verticalCenter: parent.verticalCenter
                path: control.iconPath
                color: control._fg
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                font: control.font
                color: control._fg
                visible: text !== ""
            }
            Icon {
                width: 15; height: 15
                anchors.verticalCenter: parent.verticalCenter
                path: control.trailingIconPath
                color: control._fg
                strokeWidth: 2.2
            }
        }
    }

    background: Rectangle {
        implicitWidth: control.compact ? 32 : 40
        radius: Theme.rBtn
        color: control._bg
        border.width: 1
        border.color: control._border
        opacity: control.down ? 0.85 : 1
        FocusRing { visible: control.visualFocus }
    }
}
