pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Errors page of the final design: the device's error list in groups with an "N OK" summary, and the IP settings
// at the bottom of the column. The list and the shown IP settings are device telemetry (viewModel.sample); item
// names are device text. Set sends the IP settings; without command support (real target) it and the inputs
// are disabled and the list shows no values.
ImagePageFrame {
    id: page

    readonly property ServiceConnection connection: viewModel.connection
    // Rebuilt only when the list changes, not with every sample, so the tiles stay.
    readonly property string itemsKey: JSON.stringify(sample.errorsValid ? sample.errors : [])
    readonly property var items: JSON.parse(itemsKey)
    readonly property int failed: items.filter(item => item.state === "fail").length
    readonly property int unknown: items.filter(item => item.state === "unknown").length
    // [{name, items}] in the order the device lists them.
    readonly property var groups: {
        const found = []
        for (const item of items) {
            let group = found.find(g => g.name === item.group)
            if (!group)
                found.push(group = {name: item.group, items: []})
            group.items.push(item)
        }
        return found
    }

    // IP block: follows the device until the user changes it; Set sends it and goes back to following.
    property bool ipEdited: false
    property bool dhcp: false
    property string address: ""
    readonly property bool addressValid: /^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$/.test(address.trim())

    function setIp(): bool {
        const sent = connection.send(Command.ImageSetIp, {dhcp: dhcp, address: dhcp ? "" : address.trim()})
        ipEdited = false
        return sent
    }

    Binding { target: page; restoreMode: Binding.RestoreNone; property: "dhcp"; value: page.sample.dhcp.value; when: page.sample.dhcp.valid && !page.ipEdited }
    Binding { target: page; restoreMode: Binding.RestoreNone; property: "address"; value: page.sample.ipAddress.value; when: page.sample.ipAddress.valid && !page.ipEdited }

    component Overline: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.overlineSpacing
        color: Theme.label
    }

    // One item: name (cut with "…" when long) and its state.
    component ErrorTile: Rectangle {
        id: tile
        required property var modelData
        readonly property string tone: modelData.state === "ok" ? "ok" : modelData.state === "fail" ? "crit" : "idle"
        Layout.fillWidth: true
        Layout.preferredWidth: 1 // equal columns: the name never widens one
        implicitHeight: 26
        radius: Theme.rSmall
        color: Theme.card
        border.width: 1
        border.color: modelData.state === "fail" ? Theme.critBd : Theme.line
        Accessible.role: Accessible.StaticText
        Accessible.name: modelData.name + ": " + stateText.text

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 6
            Text {
                Layout.fillWidth: true
                text: tile.modelData.name
                elide: Text.ElideRight
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSmall
                color: tile.modelData.state === "fail" ? Theme.critTx : Theme.text
            }
            StatusDot { status: tile.tone }
            Text {
                id: stateText
                text: tile.modelData.state === "ok" ? qsTr("OK") : tile.modelData.state === "fail" ? qsTr("Fail") : qsTr("Unknown")
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsSmall
                font.weight: Font.Medium
                color: Theme.stateTextColor(tile.tone)
            }
        }
    }

    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true
        compact: true
        title: qsTr("Errors")
        actions: [
            Badge {
                objectName: "errorsSummary"
                visible: page.sample.errorsValid
                kind: page.failed > 0 ? "crit" : page.unknown > 0 ? "warn" : "ok"
                text: page.failed > 0 ? qsTr("%1 FAIL").arg(page.failed)
                    : page.unknown > 0 ? qsTr("%1 UNKNOWN").arg(page.unknown)
                    : qsTr("%1 OK").arg(page.items.length)
            }
        ]

        Text {
            visible: page.groups.length === 0
            text: "—"
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsBody
            color: Theme.muted
        }
        Repeater {
            model: page.groups
            ColumnLayout {
                id: group
                required property var modelData
                Layout.fillWidth: true
                spacing: 4
                Overline { text: group.modelData.name }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 4
                    columnSpacing: 8
                    Repeater {
                        model: group.modelData.items
                        ErrorTile { objectName: "error-" + modelData.name }
                    }
                }
            }
        }
    }

    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("IP settings")

        ToggleRow {
            id: dhcpRow
            objectName: "toggle-dhcp"
            Layout.fillWidth: true
            text: qsTr("Dynamic IP (DHCP)")
            enabled: page.connection.commandsAvailable
            onToggled: { page.ipEdited = true; page.dhcp = switchItem.checked }
            Binding on checked { value: page.dhcp }
        }
        FormField {
            Layout.fillWidth: true
            label: qsTr("IP address")
            RowLayout {
                spacing: 8
                IdsTextField {
                    id: addressField
                    objectName: "input-ipAddress"
                    Layout.fillWidth: true
                    implicitWidth: 60
                    enabled: page.connection.commandsAvailable && !page.dhcp
                    error: page.ipEdited && !page.dhcp && !page.addressValid
                    Accessible.name: qsTr("IP address")
                    onTextEdited: { page.ipEdited = true; page.address = text }
                    onAccepted: if (setButton.enabled) setButton.clicked()
                    Binding on text { value: page.address }
                }
                CommandButton {
                    id: setButton
                    objectName: "command-setIp"
                    connection: page.connection
                    kind: Command.ImageSetIp
                    variant: "primary"
                    text: qsTr("Set")
                    ready: page.dhcp || page.addressValid
                    perform: () => page.setIp()
                }
            }
        }
    }
}
