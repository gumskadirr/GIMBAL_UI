import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// KpiTile { label: "FIRMWARE"; value: "v2.4.1"; caption: "Built 2026-10-28" }
CardBackground {
    id: root

    property string label: ""
    property string value: ""
    property string caption: ""
    property bool compact: false
    property bool monoValue: false
    property alias trailing: trailingRow.data

    readonly property int _hp: 16 + (compact ? 0 : 4)
    readonly property int _vp: compact ? 12 : 18

    implicitWidth: Math.max(140, col.implicitWidth + 2 * _hp)
    implicitHeight: col.implicitHeight + 2 * _vp

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.leftMargin: root._hp
        anchors.rightMargin: root._hp
        anchors.topMargin: root._vp
        anchors.bottomMargin: root._vp
        spacing: root.compact ? 2 : 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsOverline
                font.weight: Font.DemiBold
                font.letterSpacing: Theme.overlineSpacing
                font.capitalization: Font.AllUppercase
                color: Theme.label
            }
            Row { id: trailingRow; spacing: 6 }
        }
        Text {
            Layout.fillWidth: true
            text: root.value
            elide: Text.ElideRight
            font.family: root.monoValue ? Theme.fontMono : Theme.fontSans
            font.pixelSize: root.compact ? 22 : Theme.fsKpi
            font.weight: Font.Bold
            lineHeight: root.compact ? 28 : 32
            lineHeightMode: Text.FixedHeight
            color: Theme.text
        }
        Text {
            Layout.fillWidth: true
            text: root.caption
            visible: text !== ""
            elide: Text.ElideRight
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsSmall
            color: Theme.muted
        }
    }
}
