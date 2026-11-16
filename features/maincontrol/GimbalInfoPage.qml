pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Gimbal info page of the final design; display only.
// Board identity, bootloader state and commands need the device protocol: values show "—" and
// command buttons stay disabled (architecture §7) until it is integrated.
ControlPageFrame {
    id: page
    ColumnLayout {
        spacing: 2
        Text {
            text: qsTr("Board info")
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsH2
            font.weight: Font.Bold
            color: Theme.text
        }
        Text {
            text: qsTr("Identity, firmware and bootloader of the target board")
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsSmall
            color: Theme.muted
        }
    }
    Hint {
        Layout.fillWidth: true
        kind: "warning"
        text: qsTr("Board identity and commands become available once the device protocol is integrated.")
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 12
        KpiTile { Layout.fillWidth: true; compact: true; label: qsTr("Device ID"); value: "—" }
        KpiTile { Layout.fillWidth: true; compact: true; label: qsTr("Firmware"); value: "—" }
        KpiTile { Layout.fillWidth: true; compact: true; label: qsTr("Model"); value: "—" }
        KpiTile { Layout.fillWidth: true; compact: true; label: qsTr("On time"); value: "—" }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 12

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            compact: true
            title: "MCU"
            subtitle: qsTr("Microcontroller details")
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Device ID"); value: "—" }
                InfoRow { Layout.fillWidth: true; compact: true; label: "UID"; value: "—" }
                InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Flash size, KB"); value: "—" }
                InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Bootloader version"); value: "—" }
                InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Board ID"); value: "—"; showDivider: false }
            }
        }
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            compact: true
            title: qsTr("Bootloader")
            subtitle: qsTr("Enter or leave the bootloader")
            Zone {
                Layout.fillWidth: true
                padding: 8
                StatusLabel { status: "idle"; text: qsTr("State unknown") }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                IdsButton { objectName: "command-askBootloader"; Layout.fillWidth: true; enabled: page.viewModel.commandsAvailable; text: qsTr("Ask bootloader") }
                IdsButton { objectName: "command-exitBootloader"; Layout.fillWidth: true; enabled: page.viewModel.commandsAvailable; variant: "quiet"; text: qsTr("Exit bootloader") }
            }
            Hint {
                Layout.fillWidth: true
                text: qsTr("The board restarts into the bootloader. Motors are disabled until you exit it.")
            }
        }
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            compact: true
            title: qsTr("Boot bridge")
            subtitle: qsTr("Program a sub-board through this board")
            FormField {
                Layout.fillWidth: true
                label: qsTr("Target")
                IdsComboBox { enabled: page.viewModel.commandsAvailable } // the sub-board list comes from the protocol
            }
            IdsButton { objectName: "command-startBootBridge"; Layout.fillWidth: true; enabled: page.viewModel.commandsAvailable; text: qsTr("Start boot bridge") }
            Hint {
                Layout.fillWidth: true
                text: qsTr("Forwards the bootloader link to the selected sub-board.")
            }
        }
    }
    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("Firmware update")
        subtitle: qsTr("Board firmware — · GUI version %1").arg(Qt.application.version)
        actions: IdsButton {
            objectName: "command-openFirmware"
            compact: true
            enabled: page.viewModel.commandsAvailable
            text: qsTr("Open file")
        }
        Zone {
            Layout.fillWidth: true
            padding: 8
            StatusLabel { status: "idle"; text: qsTr("No file selected") }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Hint {
                Layout.fillWidth: true
                text: qsTr("Keep the board powered and connected until the update finishes.")
            }
            IdsButton {
                objectName: "command-updateFirmware"
                variant: "primary"
                enabled: page.viewModel.commandsAvailable
                text: qsTr("Update firmware")
            }
        }
    }

    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("Built-in test")
        subtitle: qsTr("Results come from the BIT report of the board")
        actions: IdsButton {
            objectName: "command-runBit"
            compact: true
            enabled: page.viewModel.commandsAvailable
            text: qsTr("Run BIT")
        }
        Zone {
            Layout.fillWidth: true
            padding: 8
            StatusLabel { status: "idle"; text: qsTr("No result") }
        }
    }
    Item { Layout.fillHeight: true }
}
