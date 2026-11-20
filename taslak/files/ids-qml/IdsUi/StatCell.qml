import QtQuick
import QtQuick.Layouts
import IdsUi

// StatCell { label: "SUPPLY VOLTAGE"; value: "24.1 V"; trailing: Badge { kind: "ok"; text: "NORMAL" } }
// StatCell { label: "PAN ANGLE"; value: "124.496°"; secondary: "2.1729 rad"; note: "REF 124.500°"
//            leading: ArcGauge { from: -180; to: 180; value: 124.5 } }
Item {
    id: root

    property string label: ""
    property string value: ""
    property string valueStatus: ""     // doluysa değerin önünde durum noktası
    property string secondary: ""
    property string note: ""
    property bool monoValue: false
    property bool showDivider: true
    property alias leading: leadingRow.data
    property alias trailing: trailingRow.data

    Layout.fillWidth: true
    Layout.preferredWidth: 200
    Layout.fillHeight: true
    implicitWidth: row.implicitWidth + 32
    implicitHeight: Math.max(52, row.implicitHeight + 20)

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Row { id: leadingRow; visible: children.length > 0 }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: root.label
                font.family: Theme.fontSans
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                font.capitalization: Font.AllUppercase
                color: Theme.label
            }
            Row {
                spacing: 8
                StatusDot {
                    visible: root.valueStatus !== ""
                    status: root.valueStatus
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: valueText
                    text: root.value
                    font.family: root.monoValue ? Theme.fontMono : Theme.fontSans
                    font.pixelSize: 14
                    font.weight: root.monoValue ? Font.Normal : Font.DemiBold
                    color: Theme.text
                }
                Text {
                    text: root.secondary
                    visible: text !== ""
                    anchors.baseline: valueText.baseline
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsSmall
                    color: Theme.label
                }
            }
            Text {
                text: root.note
                visible: text !== ""
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsOverline
                color: Theme.label
            }
        }

        Row { id: trailingRow; spacing: 6; visible: children.length > 0 }
    }

    Rectangle {
        visible: root.showDivider
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Theme.line
    }
}
