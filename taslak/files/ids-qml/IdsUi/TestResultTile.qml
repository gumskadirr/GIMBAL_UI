import QtQuick
import QtQuick.Layouts
import IdsUi

// Built-in test (BIT) sonuç kutucuğu. status: "pass" | "warn" | "fail" | "idle"
Rectangle {
    id: root

    property string name: ""
    property string status: "pass"
    property string detail: ""
    property string statusText: status === "pass" ? qsTr("Pass")
                              : status === "warn" ? qsTr("Warning")
                              : status === "fail" ? qsTr("Fail") : qsTr("Not run")

    implicitWidth: 180
    implicitHeight: col.implicitHeight + 20
    radius: Theme.rInp
    color: Theme.raised
    border.width: 1
    border.color: Theme.line
    Accessible.role: Accessible.StaticText
    Accessible.name: name + ": " + statusText + ". " + detail

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: root.name
                elide: Text.ElideRight
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsBody
                font.weight: Font.DemiBold
                color: Theme.text
            }
            StatusLabel {
                status: root.status
                text: root.statusText
                fontSize: Theme.fsSmall
                fontWeight: Font.DemiBold
                textColor: Theme.stateTextColor(root.status)
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.detail
            elide: Text.ElideRight
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsSmall
            color: Theme.muted
        }
    }
}
