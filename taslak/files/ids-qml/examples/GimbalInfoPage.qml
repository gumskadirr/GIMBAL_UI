import QtQuick
import QtQuick.Layouts
import IdsUi

ColumnLayout {
    spacing: 14

    StatStrip {
        Layout.fillWidth: true
        StatCell { label: "SAFE CONTROL"; value: "Locked"; valueStatus: "warn" }
        StatCell {
            label: "GIMBAL / IMU TEMP."; value: "41.2 °C"; secondary: "IMU 38.6 °C"
            trailing: Badge { kind: "ok"; text: "NORMAL" }
        }
        StatCell { label: "SUPPLY VOLTAGE"; value: "24.1 V"; trailing: Badge { kind: "ok"; text: "NORMAL" } }
        StatCell {
            label: "PAN ANGLE"; value: "124.496°"; monoValue: true; secondary: "2.1729 rad"; note: "REF 124.500° · 2.1729 rad"
            leading: ArcGauge { from: -180; to: 180; value: 124.496 }
        }
        StatCell {
            label: "TILT ANGLE"; value: "-8.204°"; monoValue: true; secondary: "-0.1432 rad"; note: "REF -8.200° · -0.1431 rad"
            leading: ArcGauge { from: -90; to: 90; value: -8.204 }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        Card {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            flush: true
            title: qsTr("Gimbal")
            subtitle: qsTr("3D model, follows live pan and tilt")
            actions: IdsButton { variant: "quiet"; compact: true; iconPath: Icons.resetView; text: qsTr("Reset view") }

            VideoViewport {
                Layout.fillWidth: true
                Layout.fillHeight: true
                topRadius: 0
                bottomRadius: Theme.rCard - 1
                placeholderIcon: Icons.cube
                placeholderTitle: qsTr("3D gimbal model")
                placeholderText: qsTr("Reserved area for the interactive 3D view")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 2
            spacing: 12

            Column {
                spacing: 2
                Text { text: qsTr("Board info"); font.family: Theme.fontSans; font.pixelSize: Theme.fsH2; font.weight: Font.Bold; color: Theme.text }
                Text { text: qsTr("Identity, firmware and bootloader of the target board"); font.family: Theme.fontSans; font.pixelSize: Theme.fsSmall; color: Theme.muted }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 12
                KpiTile { Layout.fillWidth: true; compact: true; label: "DEVICE ID"; value: "0x1A42"; caption: qsTr("Target board") }
                KpiTile { Layout.fillWidth: true; compact: true; label: "FIRMWARE"; value: "v2.4.1"; caption: qsTr("Built 2026-10-28") }
                KpiTile { Layout.fillWidth: true; compact: true; label: "MODEL"; value: "MCB-2"; caption: qsTr("Main control board") }
                KpiTile { Layout.fillWidth: true; compact: true; label: "ON TIME"; value: "3 h 12 min"; caption: qsTr("11 520 s since power on") }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                columns: 3
                columnSpacing: 12
                Card {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                    compact: true; title: "MCU"; subtitle: qsTr("Microcontroller details")
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Device ID"); value: "0x0451" }
                        InfoRow { Layout.fillWidth: true; compact: true; label: "UID"; value: "3A00 2F14 5133 3532" }
                        InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Flash size, KB"); value: "1024" }
                        InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Bootloader version"); value: "1.3.0" }
                        InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Board ID"); value: "0x07"; showDivider: false }
                    }
                }
                Card {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                    compact: true; title: qsTr("Bootloader"); subtitle: qsTr("Enter or leave the bootloader")
                    Zone {
                        Layout.fillWidth: true
                        padding: 12
                        RowLayout {
                            Layout.fillWidth: true
                            StatusLabel { status: "ok"; text: qsTr("Application running") }
                            Item { Layout.fillWidth: true }
                            Badge { kind: "info"; text: "NO BOOTLOADER" }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        IdsButton { Layout.fillWidth: true; text: qsTr("Ask bootloader") }
                        IdsButton { Layout.fillWidth: true; variant: "quiet"; text: qsTr("Exit bootloader") }
                    }
                    Hint { Layout.fillWidth: true; text: qsTr("The board restarts into the bootloader. Motors are disabled until you exit it.") }
                }
                Card {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                    compact: true; title: qsTr("Boot bridge"); subtitle: qsTr("Program a sub-board through this board")
                    FormField {
                        Layout.fillWidth: true
                        label: qsTr("Target")
                        IdsComboBox { model: [qsTr("Pan motor driver"), qsTr("Tilt motor driver"), qsTr("Camera module")] }
                    }
                    IdsButton { Layout.fillWidth: true; text: qsTr("Start boot bridge") }
                    Hint { Layout.fillWidth: true; text: qsTr("Forwards the bootloader link to the selected sub-board.") }
                }
            }

            Card {
                Layout.fillWidth: true
                compact: true
                title: qsTr("Built-in test")
                subtitle: qsTr("Last run 14:20:05 at power-on")
                actions: [
                    Badge { kind: "ok"; text: "7 PASSED" },
                    Badge { kind: "warn"; text: "1 WARNING" },
                    IdsButton { text: qsTr("Run BIT") }
                ]
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 10
                    rowSpacing: 10
                    Repeater {
                        model: [
                            { n: "Power supply", s: "pass", d: "24.1 V, within limits" },
                            { n: "IMU",          s: "pass", d: "Gyro bias within limits" },
                            { n: "Pan motor",    s: "warn", d: "Position limit reached" },
                            { n: "Tilt motor",   s: "pass", d: "Driver and current OK" },
                            { n: "Encoders",     s: "pass", d: "Pan and tilt signals OK" },
                            { n: "Heater",       s: "pass", d: "All zones respond" },
                            { n: "LRF",          s: "pass", d: "Optical crosstalk 0.4%" },
                            { n: "Flash memory", s: "pass", d: "Checksum OK" }
                        ]
                        TestResultTile {
                            required property var modelData
                            Layout.fillWidth: true
                            name: modelData.n; status: modelData.s; detail: modelData.d
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
