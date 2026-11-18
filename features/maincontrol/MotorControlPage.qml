pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Motor control page of the final design (three equal columns: 3D card | Motor configuration | Control).
// Display only: parameters and commands need the device protocol (architecture §7, §13), so every input
// and command is disabled through viewModel.connection.commandsAvailable and fields stay empty.
// Not taken from the design: the "N UNSAVED CHANGES" badge (nothing can be edited), the command range and
// the torque unit (device limits), and the option lists (they come from the device).
ControlPageFrame {
    id: page

    component GainHeader: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.overlineSpacing
        color: Theme.label
    }
    component LoopLabel: Text {
        Layout.minimumWidth: 90
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsBody
        color: Theme.text2
    }
    component ValueField: IdsTextField {
        Layout.fillWidth: true
        implicitWidth: 60
        compact: true // 34 px: keeps the dense parameter grids close to the design height
        placeholderText: "—"
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12
        enabled: page.viewModel.connection.commandsAvailable // every input and command at once (Adım 10)

        // Motor configuration
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            spacing: 8

            SectionHeading {
                title: qsTr("Motor configuration")
                subtitle: qsTr("Gains, limits and wiring of the selected motor")
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    height: Theme.controlHeight
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("Configure")
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fsBody
                    color: Theme.text2
                }
                SegmentedControl { width: 160; model: [qsTr("Pan"), qsTr("Tilt")] }
                IdsButton { objectName: "command-read"; text: qsTr("Read") }
                IdsButton { objectName: "command-write"; text: qsTr("Write") }
                IdsButton { objectName: "command-saveToFlash"; variant: "primary"; text: qsTr("Save to flash") }
                IdsButton { objectName: "command-defaults"; variant: "quiet"; text: qsTr("Defaults") }
            }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Read loads from the board · Write applies until restart · Save to flash keeps after restart")
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsSmall
                color: Theme.muted
            }

            Card {
                Layout.fillWidth: true
                compact: true
                title: qsTr("PID controllers")
                subtitle: qsTr("Gains for each control loop")
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 10
                    rowSpacing: 8
                    Item { implicitWidth: 1 }
                    GainHeader { text: "KP" }
                    GainHeader { text: "KI" }
                    GainHeader { text: "KD" }
                    LoopLabel { text: qsTr("Torque") }
                    ValueField { objectName: "input-torqueKp"; Accessible.name: qsTr("Torque Kp") }
                    ValueField { Accessible.name: qsTr("Torque Ki") }
                    ValueField { Accessible.name: qsTr("Torque Kd") }
                    LoopLabel { text: qsTr("Speed") }
                    ValueField { Accessible.name: qsTr("Speed Kp") }
                    ValueField { Accessible.name: qsTr("Speed Ki") }
                    ValueField { Accessible.name: qsTr("Speed Kd") }
                    LoopLabel { text: qsTr("Position") }
                    ValueField { Accessible.name: qsTr("Position Kp") }
                    ValueField { Accessible.name: qsTr("Position Ki") }
                    ValueField { Accessible.name: qsTr("Position Kd") }
                    LoopLabel { text: qsTr("Tracker") }
                    ValueField { Accessible.name: qsTr("Tracker Kp") }
                    ValueField { Accessible.name: qsTr("Tracker Ki") }
                    ValueField { Accessible.name: qsTr("Tracker Kd") }
                }
                FormField {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 320
                    label: qsTr("Model serial number")
                    IdsTextField { compact: true; placeholderText: "—" }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                compact: true
                title: qsTr("Position")
                subtitle: qsTr("Limits, offsets and motor wiring")
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 8
                    FormField { Layout.fillWidth: true; label: qsTr("Position offset, deg"); ValueField {} }
                    FormField { Layout.fillWidth: true; label: qsTr("Electrical offset, deg"); ValueField {} }
                    FormField { Layout.fillWidth: true; label: qsTr("Forward border, deg"); ValueField {} }
                    FormField { Layout.fillWidth: true; label: qsTr("Backward border, deg"); ValueField {} }
                    FormField {
                        Layout.fillWidth: true
                        label: qsTr("Encoder rotation")
                        SegmentedControl { model: [qsTr("Forward"), qsTr("Reverse")] }
                    }
                    FormField { Layout.fillWidth: true; label: qsTr("Phase rotation"); IdsComboBox {} }
                }
                ToggleRow { Layout.fillWidth: true; text: qsTr("Slip ring") }
            }
        }

        // Control
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            spacing: 8

            SectionHeading {
                title: qsTr("Control")
                subtitle: qsTr("Drive the active motor")
            }

            Card {
                Layout.fillWidth: true
                compact: true
                title: qsTr("Control")
                subtitle: qsTr("Mode, active motor and keyboard input")
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 12
                    FormField { Layout.fillWidth: true; label: qsTr("Control mode"); IdsComboBox {} }
                    FormField { Layout.fillWidth: true; label: qsTr("Current motor"); IdsComboBox {} }
                }
                Zone {
                    Layout.fillWidth: true
                    padding: 8
                    RowLayout {
                        Layout.fillWidth: true
                        StatusLabel {
                            objectName: "latchStatus"
                            status: !page.viewModel.safeControl.valid ? "idle"
                                  : page.viewModel.safeControl.value ? "warn" : "ok"
                            text: !page.viewModel.safeControl.valid ? qsTr("State unknown")
                                : page.viewModel.safeControl.value ? qsTr("Locked · toggle latch to send")
                                : qsTr("Unlocked")
                        }
                        Item { Layout.fillWidth: true }
                        IdsButton { objectName: "command-toggleLatch"; text: qsTr("Toggle latch") }
                    }
                }
                ToggleRow { Layout.fillWidth: true; text: qsTr("Keyboard control") }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    IdsButton {
                        objectName: "command-startControl"
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.touchMin
                        variant: "primary"
                        iconPath: Icons.play
                        text: qsTr("Start control")
                    }
                    IdsButton {
                        objectName: "command-stopControl"
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.touchMin
                        iconPath: Icons.stop
                        text: qsTr("Stop control")
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                compact: true
                title: qsTr("Command")
                subtitle: qsTr("Send a reference to the active motor")
                SegmentedControl {
                    id: commandType
                    Layout.fillWidth: true
                    currentIndex: 2
                    model: [qsTr("Torque"), qsTr("Speed"), qsTr("Position")]
                }
                FormField {
                    Layout.fillWidth: true
                    label: [qsTr("Torque"), qsTr("Speed, deg/s"), qsTr("Position, deg")][commandType.currentIndex]
                    RowLayout {
                        spacing: 8
                        ValueField {}
                        IdsButton { objectName: "command-set"; text: qsTr("Set") }
                        IdsButton { objectName: "command-reset"; variant: "quiet"; text: qsTr("Reset") }
                    }
                }
                Text {
                    text: qsTr("Enter sends the value.")
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fsSmall
                    color: Theme.label
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
