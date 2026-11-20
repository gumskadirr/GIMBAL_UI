import QtQuick
import QtQuick.Layouts
import IdsUi

// Seri port / ağ bağlantı ayarları paneli (her sayfanın durum çubuğunda ortak).
// summary → durum çubuğu butonunda gösterilecek kısa metin.
IdsPopup {
    id: root

    property bool connected: true
    property var protocols: ["UART", "IP/UDP", "TCP"]
    property var ports: ["COM3", "COM4", "/dev/ttyUSB0"]
    property var baudRates: ["115200", "57600", "921600"]
    property var dataBitsOptions: ["8", "7"]
    property var parities: ["None", "Even", "Odd"]
    property var stopBitsOptions: ["1", "2"]

    readonly property var settings: ({
        protocol: protocolBox.currentText, port: portBox.currentText,
        baudRate: Number(baudBox.currentText), dataBits: Number(dataBox.currentText),
        parity: parityBox.currentText, stopBits: Number(stopBox.currentText)
    })
    readonly property string summary: protocolBox.currentText + " · " + portBox.currentText + " · "
                                      + baudBox.currentText + " " + dataBox.currentText
                                      + parityBox.currentText.charAt(0) + stopBox.currentText

    signal applyRequested(var settings)
    signal disconnectRequested()

    title: qsTr("Connection")
    headerTrailing: StatusLabel {
        status: root.connected ? "ok" : "idle"
        text: root.connected ? qsTr("Connected") : qsTr("Disconnected")
        fontSize: Theme.fsSmall
        textColor: root.connected ? Theme.okTx : Theme.muted
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 10
        columnSpacing: 10
        FormField { Layout.fillWidth: true; label: qsTr("Protocol");  IdsComboBox { id: protocolBox; model: root.protocols } }
        FormField { Layout.fillWidth: true; label: qsTr("Port");      IdsComboBox { id: portBox; model: root.ports } }
        FormField { Layout.fillWidth: true; label: qsTr("Baud rate"); IdsComboBox { id: baudBox; model: root.baudRates } }
        FormField { Layout.fillWidth: true; label: qsTr("Data bits"); IdsComboBox { id: dataBox; model: root.dataBitsOptions } }
        FormField { Layout.fillWidth: true; label: qsTr("Parity");    IdsComboBox { id: parityBox; model: root.parities } }
        FormField { Layout.fillWidth: true; label: qsTr("Stop bits"); IdsComboBox { id: stopBox; model: root.stopBitsOptions } }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 8
        Item { Layout.fillWidth: true }
        IdsButton {
            variant: "quiet"
            text: qsTr("Disconnect")
            enabled: root.connected
            onClicked: root.disconnectRequested()
        }
        IdsButton {
            variant: "primary"
            text: qsTr("Apply")
            onClicked: { root.applyRequested(root.settings); root.close() }
        }
    }
}
