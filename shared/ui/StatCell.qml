import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// StatCell { label: "SUPPLY VOLTAGE"; value: "24.1 V"; trailing: Badge { kind: "ok"; text: "NORMAL" } }
// StatCell { label: "PAN ANGLE"; value: "124.496°"; secondary: "2.1729 rad"; note: "REF 124.500°"
//            leading: ArcGauge { from: -180; to: 180; value: 124.5 } }
Item {
    id: root

    property string label: ""
    property string value: ""
    property string valueStatus: ""     // when set, a status dot precedes the value
    property string secondary: ""
    property string note: ""
    property bool monoValue: false
    property bool showDivider: true
    property int share: 1               // fixed share of the strip's width, so changing values never move cells
    property string valueSample: ""     // the widest value expected: the value keeps this width (no jumping text)
    property alias leading: leadingRow.data
    property alias trailing: trailingRow.data

    // Width = strip × share / Σ shares, never the text: a width that followed the content moved the cells with
    // every sample (the layout's own sharing equalises cells instead of keeping proportions).
    readonly property real _shareSum: parent ? Array.from(parent.children).reduce((sum, c) => sum + (c.share ?? 0), 0) : 0
    Layout.preferredWidth: _shareSum > 0 ? parent.width * share / _shareSum : 0
    Layout.minimumWidth: Layout.preferredWidth
    Layout.maximumWidth: Layout.preferredWidth
    // shortcut: below ~1100 px the five-cell strip does not fit and cells are clipped; a wrapping
    // layout for narrow windows belongs to the later visual pass.
    clip: true
    Layout.fillHeight: true
    implicitWidth: row.implicitWidth + 32
    implicitHeight: Math.max(52, row.implicitHeight + 20)

    TextMetrics {
        id: sampleMetrics
        text: root.valueSample
        font: valueText.font
    }

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
                Layout.fillWidth: true
                elide: Text.ElideRight
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
                    width: Math.max(implicitWidth, sampleMetrics.advanceWidth)
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
                Layout.fillWidth: true
                elide: Text.ElideRight
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
