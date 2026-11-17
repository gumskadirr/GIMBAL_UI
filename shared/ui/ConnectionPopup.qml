pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Connection settings of one service, opened from the status bar (final design). UART or IP/UDP; TCP is not
// offered (decision 2026-11-17). Knows nothing about the device: call prepare() with the current settings map
// and the serial ports before opening, and handle applyRequested / disconnectRequested.
// Settings map: { transport: "serial" | "udp", serialPort, baudRate, dataBits, parity: "none" | "even" | "odd",
//                 stopBits, host, port }
IdsPopup {
    id: root

    property bool connected: false
    property bool canDisconnect: false
    signal applyRequested(var settings)
    signal disconnectRequested()

    readonly property bool udp: transportBox.currentIndex === 1
    readonly property list<string> baudRates: ["9600", "19200", "38400", "57600", "115200", "230400", "460800", "921600"]
    readonly property list<string> parityCodes: ["none", "even", "odd"]
    readonly property bool valid: udp ? hostField.text.trim().length > 0 && portField.acceptableInput
                                      : portBox.currentText.length > 0
    property list<string> serialPorts: []

    function prepare(settings: var, ports: list<string>) {
        const saved = settings.serialPort || ""
        serialPorts = saved !== "" && ports.indexOf(saved) < 0 ? ports.concat([saved]) : ports // keep an unplugged port
        transportBox.currentIndex = settings.transport === "udp" ? 1 : 0
        portBox.currentIndex = Math.max(0, serialPorts.indexOf(saved))
        baudBox.currentIndex = Math.max(0, baudRates.indexOf(String(settings.baudRate || 115200)))
        dataBox.currentIndex = settings.dataBits === 7 ? 1 : 0
        parityBox.currentIndex = Math.max(0, parityCodes.indexOf(settings.parity || "none"))
        stopBox.currentIndex = settings.stopBits === 2 ? 1 : 0
        hostField.text = settings.host || ""
        portField.text = settings.port > 0 ? String(settings.port) : ""
    }

    title: qsTr("Connection")
    headerTrailing: StatusLabel {
        status: root.connected ? "ok" : "idle"
        text: root.connected ? qsTr("Connected") : qsTr("Disconnected")
        fontSize: Theme.fsSmall
        textColor: root.connected ? Theme.okTx : Theme.muted
    }

    FormField {
        Layout.fillWidth: true
        label: qsTr("Transport")
        IdsComboBox { id: transportBox; objectName: "connection-transport"; model: ["UART", "IP/UDP"] }
    }

    GridLayout {
        Layout.fillWidth: true
        visible: !root.udp
        columns: 2
        rowSpacing: 10
        columnSpacing: 10
        FormField { Layout.fillWidth: true; label: qsTr("Port"); IdsComboBox { id: portBox; model: root.serialPorts } }
        FormField { Layout.fillWidth: true; label: qsTr("Baud rate"); IdsComboBox { id: baudBox; model: root.baudRates } }
        FormField { Layout.fillWidth: true; label: qsTr("Data bits"); IdsComboBox { id: dataBox; model: ["8", "7"] } }
        FormField {
            Layout.fillWidth: true
            label: qsTr("Parity")
            IdsComboBox { id: parityBox; model: [qsTr("None"), qsTr("Even"), qsTr("Odd")] }
        }
        FormField { Layout.fillWidth: true; label: qsTr("Stop bits"); IdsComboBox { id: stopBox; model: ["1", "2"] } }
    }
    Hint {
        Layout.fillWidth: true
        visible: !root.udp && root.serialPorts.length === 0
        kind: "warning"
        text: qsTr("No serial ports found")
    }

    GridLayout {
        Layout.fillWidth: true
        visible: root.udp
        columns: 2
        columnSpacing: 10
        FormField {
            Layout.fillWidth: true
            label: qsTr("IP address")
            IdsTextField { id: hostField; objectName: "connection-host"; placeholderText: "192.168.1.89" }
        }
        FormField {
            Layout.fillWidth: true
            label: qsTr("Port")
            IdsTextField {
                id: portField
                objectName: "connection-port"
                placeholderText: "5000"
                validator: IntValidator { bottom: 1; top: 65535 }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 8
        Item { Layout.fillWidth: true }
        IdsButton {
            objectName: "connection-disconnect"
            variant: "quiet"
            text: qsTr("Disconnect")
            enabled: root.canDisconnect
            onClicked: root.disconnectRequested()
        }
        IdsButton {
            objectName: "connection-apply"
            variant: "primary"
            text: qsTr("Apply")
            enabled: root.valid
            onClicked: {
                root.applyRequested({
                    transport: root.udp ? "udp" : "serial",
                    serialPort: portBox.currentText,
                    baudRate: Number(baudBox.currentText),
                    dataBits: Number(dataBox.currentText),
                    parity: root.parityCodes[parityBox.currentIndex],
                    stopBits: Number(stopBox.currentText),
                    host: hostField.text.trim(),
                    port: Number(portField.text)
                })
                root.close()
            }
        }
    }
}
