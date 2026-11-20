pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Both services' connections, opened from the top-bar status chip. Each row: status, address, Connect or
// Disconnect, and the service's connection settings (ConnectionPopup, opened in the same place). Any service can
// be connected from here, whatever page is visible.
IdsPopup {
    id: root

    required property var services    // key -> display name
    required property var connections // key -> ServiceConnection
    property list<string> udpOnlyServices: []
    property list<string> order: Object.keys(services) // the map does not keep its order
    readonly property ConnectionPopup settingsPopup: settings

    function openSettings(key: string) {
        const link = connections[key]
        settings.service = key
        settings.prepare(link.target(), link.availableSerialPorts())
        close()
        settings.open()
    }

    width: 440
    title: qsTr("Connections")

    Repeater {
        model: root.order
        ColumnLayout {
            id: row
            required property string modelData
            required property int index
            readonly property ServiceConnection link: root.connections[modelData]
            readonly property bool active: link.connected || link.busy
            objectName: "connectionRow-" + modelData
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                visible: row.index > 0
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                implicitHeight: 1
                color: Theme.line
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                StatusDot {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 5
                    status: row.link.hasError ? "crit" : row.link.connected ? "ok" : row.link.busy ? "warn" : "crit"
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: root.services[row.modelData]
                        elide: Text.ElideRight
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsBody
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }
                    Text {
                        objectName: "connectionState-" + row.modelData
                        Layout.fillWidth: true
                        text: row.link.statusText + " · " + row.link.summary
                        elide: Text.ElideRight
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsSmall
                        color: Theme.muted
                    }
                }
                IdsButton {
                    objectName: "connectionToggle-" + row.modelData
                    compact: true
                    variant: row.active ? "secondary" : "primary"
                    text: row.active ? qsTr("Disconnect") : qsTr("Connect")
                    enabled: row.active || row.link.configured
                    Accessible.name: text + " " + root.services[row.modelData]
                    onClicked: row.active ? row.link.disconnectDevice() : row.link.connectDevice()
                }
                IdsButton {
                    objectName: "connectionSettings-" + row.modelData
                    compact: true
                    iconPath: Icons.gear
                    Accessible.name: qsTr("%1 connection settings").arg(root.services[row.modelData])
                    onClicked: root.openSettings(row.modelData)
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                visible: row.link.hasError && row.link.errorDetail !== ""
                text: row.link.errorDetail
                wrapMode: Text.WordWrap
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsSmall
                color: Theme.critTx
            }
        }
    }

    ConnectionPopup {
        id: settings
        property string service: ""
        readonly property ServiceConnection link: root.connections[service] ?? null
        objectName: "chipConnectionPopup"
        parent: root.parent
        x: root.x + root.width - width
        y: root.y
        width: 400
        title: root.services[service] ?? ""
        udpOnly: root.udpOnlyServices.includes(service)
        connected: link?.connected ?? false
        canDisconnect: link ? link.connected || link.busy : false
        onApplyRequested: values => link.apply(values)
        onDisconnectRequested: link.disconnectDevice()
    }
}
