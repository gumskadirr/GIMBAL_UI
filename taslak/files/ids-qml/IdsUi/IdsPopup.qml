import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import IdsUi

// Gölgeli açılır panel (bağlantı ayarları vb.). İçerik dikey yerleşir.
T.Popup {
    id: control

    property string title: ""
    property alias headerTrailing: trailingRow.data
    default property alias content: body.data

    implicitWidth: 340
    implicitHeight: implicitContentHeight + topPadding + bottomPadding
    padding: 18
    focus: true
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 90 } }

    contentItem: ColumnLayout {
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            visible: control.title !== "" || trailingRow.children.length > 0
            Text {
                Layout.fillWidth: true
                text: control.title
                font.family: Theme.fontSans
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.text
                Accessible.role: Accessible.Heading
                Accessible.name: text
            }
            Row { id: trailingRow; spacing: 8 }
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 12
        }
    }

    background: Rectangle {
        radius: Theme.rCard
        color: Theme.card
        border.width: 1
        border.color: Theme.line2
        Shadow { anchors.fill: parent; radius: parent.radius; z: -1 }
    }
}
