import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Status bar section with a divider on its right. Use Layout.fillWidth: true for the flexible one.
Item {
    id: root

    property bool showDivider: true
    property alias spacing: inner.spacing
    default property alias content: inner.data

    Layout.fillHeight: true
    implicitWidth: inner.implicitWidth + 40
    implicitHeight: Math.max(44, inner.implicitHeight)

    RowLayout {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16
    }
    Rectangle {
        visible: root.showDivider
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Theme.div
    }
}
