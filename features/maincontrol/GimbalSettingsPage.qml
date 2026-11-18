pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Gimbal settings page of the final design (3D card | settings, 1:2), without the charts (later step).
// Display only: stream, script, calibrations and gains need the device protocol (architecture §7), so values show
// "—" and every input and command is disabled through viewModel.connection.commandsAvailable.
// Not taken from the design: the "1 kHz" stream badge (rate comes from the device; 1 vs 2 kHz is open, §17).
ControlPageFrame {
    id: page

    component BarTitle: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsTitle
        font.weight: Font.DemiBold
        color: Theme.text
    }
    component ValueText: Text {
        font.family: Theme.fontMono
        font.pixelSize: Theme.fsBody
        color: Theme.text
    }
    component LabelText: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsSmall
        color: Theme.muted
    }
    component ValueField: IdsTextField {
        Layout.fillWidth: true
        implicitWidth: 60
        compact: true
        placeholderText: "—"
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8
        enabled: page.viewModel.connection.commandsAvailable // every input and command at once (Adım 10)

        // Stream
        CardBackground {
            Layout.fillWidth: true
            implicitHeight: streamRow.implicitHeight + 24
            RowLayout {
                id: streamRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                BarTitle { text: qsTr("Stream") }
                IdsButton { objectName: "command-startStream"; iconPath: Icons.play; text: qsTr("Start stream") }
                IdsButton { objectName: "command-stopStream"; variant: "quiet"; text: qsTr("Stop stream") }
                Item { implicitWidth: 8 }
                IdsButton { objectName: "command-recordCsv"; iconPath: Icons.record; text: qsTr("Record CSV") }
                IdsButton { objectName: "command-saveCsv"; variant: "quiet"; text: qsTr("Save CSV") }
                ValueText { objectName: "value-packets"; text: "— " + qsTr("packets") }
                Item { Layout.fillWidth: true }
                IdsButton {
                    objectName: "command-safeStop"
                    variant: "danger"
                    iconPath: Icons.stop
                    text: qsTr("Safe stop")
                    shortcutHint: "Esc"
                }
            }
        }

        // Script
        CardBackground {
            Layout.fillWidth: true
            implicitHeight: scriptRow.implicitHeight + 24
            RowLayout {
                id: scriptRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                BarTitle { text: qsTr("Script") }
                StatusLabel { objectName: "value-scriptState"; status: "idle"; text: qsTr("No script loaded") }
                Icon { implicitWidth: 15; implicitHeight: 15; path: Icons.file; color: Theme.muted }
                ValueText { objectName: "value-scriptFile"; text: "—" }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    LabelText { text: qsTr("Row %1 / %2").arg("—").arg("—") }
                    IdsProgressBar { Layout.fillWidth: true; value: 0 }
                    ValueText { text: "—" }
                }
                LabelText { text: qsTr("Pan %1 · Tilt %2").arg("—").arg("—") }
                IdsButton { objectName: "command-startScript"; variant: "primary"; iconPath: Icons.play; text: qsTr("Start") }
                IdsButton { objectName: "command-stopScript"; iconPath: Icons.pause; text: qsTr("Stop") }
                IdsButton { objectName: "command-scriptDetails"; variant: "quiet"; iconPath: Icons.expand; text: qsTr("Details") }
            }
        }

        // Calibrations and gains
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false // the cards' fillHeight only evens out the row
            columns: 4
            columnSpacing: 12

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                compact: true
                title: qsTr("Electrical angle")
                subtitle: qsTr("Motor commutation calibration")
                InfoRow { objectName: "value-rawPosition"; Layout.fillWidth: true; compact: true; label: qsTr("Raw position"); value: "—"; showDivider: false }
                IdsButton { objectName: "command-electricalAngle"; Layout.fillWidth: true; text: qsTr("Start electrical angle calibration") }
                Hint {
                    Layout.fillWidth: true
                    kind: "warning"
                    text: qsTr("The motor turns slowly during calibration. Clear the gimbal first.")
                }
            }
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                compact: true
                title: qsTr("LRF")
                subtitle: qsTr("Laser range finder checks")
                ToggleRow { Layout.fillWidth: true; text: qsTr("Laser pointer") }
                IdsButton { objectName: "command-crosstalk"; Layout.fillWidth: true; text: qsTr("Check optical crosstalk") }
                StatusLabel { objectName: "value-crosstalk"; status: "idle"; text: qsTr("Not checked") }
            }
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                compact: true
                title: qsTr("IMU bias")
                subtitle: qsTr("Gyro offsets, deg/s")
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 8
                    FormField { Layout.fillWidth: true; label: qsTr("Gyro X"); ValueField {} }
                    FormField { Layout.fillWidth: true; label: qsTr("Gyro Y"); ValueField {} }
                    FormField { Layout.fillWidth: true; label: qsTr("Gyro Z"); ValueField {} }
                }
                IdsButton { objectName: "command-imuBias"; Layout.fillWidth: true; text: qsTr("Start bias calibration") }
                Hint { Layout.fillWidth: true; text: qsTr("Keep the gimbal still for about 10 seconds.") }
            }
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                compact: true
                title: qsTr("Complementary filter")
                subtitle: qsTr("Attitude estimator gains")
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    FormField { Layout.fillWidth: true; label: "Kp"; ValueField {} }
                    FormField { Layout.fillWidth: true; label: "Ki"; ValueField {} }
                }
            }
        }

        // Scope: charts come in a later step; the area says honestly that there is no data.
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            compact: true
            fillContent: true
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                BarTitle { text: qsTr("Scope") }
                LabelText { text: qsTr("Board mode %1").arg("—") }
                IdsTabs { compact: true; showBaseline: false; model: [qsTr("Scope, 2 s"), qsTr("FFT"), qsTr("Bode sweep")] }
                Item { Layout.fillWidth: true }
                IdsComboBox {
                    Layout.preferredWidth: 260
                    compact: true
                    model: [qsTr("Speed loop: rate and rate ref"), qsTr("Position loop"), qsTr("Torque loop: Iq")]
                }
                IdsButton { objectName: "command-popOut"; variant: "quiet"; compact: true; iconPath: Icons.popOut; text: qsTr("Pop out") }
            }
            Zone {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 120 // grows into the spare height
                LabelText {
                    objectName: "value-scopeEmpty"
                    Layout.alignment: Qt.AlignCenter
                    text: qsTr("No stream data")
                }
            }
        }
    }
}
