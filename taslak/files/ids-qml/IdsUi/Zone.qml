import QtQuick
import QtQuick.Layouts
import IdsUi

// Kart içinde yükseltilmiş alt bölge (ısıtıcı bölgeleri, bootloader durumu).
Rectangle {
    id: root

    property int padding: 16
    property alias spacing: col.spacing
    default property alias content: col.data

    implicitWidth: col.implicitWidth + 2 * padding
    implicitHeight: col.implicitHeight + 2 * padding
    radius: Theme.rCard
    color: Theme.raised
    border.width: 1
    border.color: Theme.line

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 12
    }
}
