pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Gimbal info page of the final design; display only.
// No "NORMAL" badges: temperature and voltage limits are not known yet and are not invented.
// Board identity, bootloader state and commands need the device protocol: values show "—" and
// command buttons stay disabled (architecture §7) until it is integrated.
// Layout fits 1536x816 (1080p at 125 %) without scrolling: Firmware update and Built-in test sit under the
// 3D card instead of under the board cards as in the 1080p@100 % design.
ColumnLayout {
    id: page
    required property DeviceViewModel viewModel

    spacing: 14

    function degrees(m: measurement): string {
        return m.valid ? m.value.toFixed(3) + "°" : "—"
    }
    function radians(m: measurement): string {
        return m.valid ? (m.value * Math.PI / 180).toFixed(4) + " rad" : ""
    }
    function reference(m: measurement): string {
        return m.valid ? qsTr("REF %1 · %2").arg(page.degrees(m)).arg(page.radians(m)) : ""
    }
    function celsius(m: measurement): string {
        return m.valid ? m.value.toFixed(1) + " °C" : "—"
    }

    StatStrip {
        Layout.fillWidth: true

        StatCell {
            objectName: "cell-safeControl"
            label: qsTr("Safe control")
            value: !page.viewModel.safeControl.valid ? "—"
                 : page.viewModel.safeControl.value ? qsTr("Locked") : qsTr("Unlocked")
            valueStatus: !page.viewModel.safeControl.valid ? ""
                       : page.viewModel.safeControl.value ? "warn" : "idle"
        }
        StatCell {
            objectName: "cell-temperature"
            label: qsTr("Gimbal / IMU temp.")
            value: page.celsius(page.viewModel.gimbalTemp)
            secondary: page.viewModel.imuTemp.valid ? qsTr("IMU %1").arg(page.celsius(page.viewModel.imuTemp)) : ""
        }
        StatCell {
            objectName: "cell-supply"
            label: qsTr("Supply voltage")
            value: page.viewModel.supplyVoltage.valid ? page.viewModel.supplyVoltage.value.toFixed(1) + " V" : "—"
        }
        StatCell {
            objectName: "cell-pan"
            label: qsTr("Pan angle")
            value: page.degrees(page.viewModel.pan)
            monoValue: true
            secondary: page.radians(page.viewModel.pan)
            note: page.reference(page.viewModel.panRef)
            leading: ArcGauge {
                from: -180
                to: 180
                value: page.viewModel.pan.value
                fillColor: page.viewModel.pan.valid ? Theme.gauge : "transparent"
            }
        }
        StatCell {
            objectName: "cell-tilt"
            label: qsTr("Tilt angle")
            value: page.degrees(page.viewModel.tilt)
            monoValue: true
            secondary: page.radians(page.viewModel.tilt)
            note: page.reference(page.viewModel.tiltRef)
            leading: ArcGauge {
                from: -90
                to: 90
                value: page.viewModel.tilt.value
                fillColor: page.viewModel.tilt.valid ? Theme.gauge : "transparent"
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            spacing: 12

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                flush: true
                title: qsTr("Gimbal")
                subtitle: qsTr("3D model, follows live pan and tilt")

                VideoViewport {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 140 // grows into any spare height
                    topRadius: 0
                    bottomRadius: Theme.rCard - 1
                    placeholderIcon: Icons.cube
                    placeholderTitle: qsTr("3D gimbal model")
                    placeholderText: qsTr("Reserved area for the interactive 3D view")
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
                    enabled: false
                    text: qsTr("Open file")
                }
                Zone {
                    Layout.fillWidth: true
                    padding: 12
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
                        enabled: false
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
                    enabled: false
                    text: qsTr("Run BIT")
                }
                Zone {
                    Layout.fillWidth: true
                    padding: 12
                    StatusLabel { status: "idle"; text: qsTr("No result") }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 2
            spacing: 12

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
                Layout.fillHeight: false // the cards' fillHeight only evens out the row; spare height goes below
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
                        padding: 12
                        StatusLabel { status: "idle"; text: qsTr("State unknown") }
                    }
                    ColumnLayout { // stacked: the Turkish labels do not fit side by side
                        Layout.fillWidth: true
                        spacing: 8
                        IdsButton { objectName: "command-askBootloader"; Layout.fillWidth: true; enabled: false; text: qsTr("Ask bootloader") }
                        IdsButton { objectName: "command-exitBootloader"; Layout.fillWidth: true; enabled: false; variant: "quiet"; text: qsTr("Exit bootloader") }
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
                        IdsComboBox { enabled: false } // the sub-board list comes from the protocol
                    }
                    IdsButton { objectName: "command-startBootBridge"; Layout.fillWidth: true; enabled: false; text: qsTr("Start boot bridge") }
                    Hint {
                        Layout.fillWidth: true
                        text: qsTr("Forwards the bootloader link to the selected sub-board.")
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
