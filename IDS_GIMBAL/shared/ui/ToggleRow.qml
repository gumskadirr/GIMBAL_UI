import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Label on the left, switch on the right; tapping the label toggles the switch too.
Item {
    id: root

    property alias text: label.text
    property alias checked: sw.checked
    property alias switchItem: sw
    signal toggled()

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(34, row.implicitHeight)

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 12
        Text {
            id: label
            Layout.fillWidth: true
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsBody
            color: Theme.text2
            elide: Text.ElideRight
            TapHandler { onTapped: { sw.toggle(); root.toggled() } }
        }
        IdsSwitch {
            id: sw
            text: label.text
            onToggled: root.toggled()
        }
    }
}
