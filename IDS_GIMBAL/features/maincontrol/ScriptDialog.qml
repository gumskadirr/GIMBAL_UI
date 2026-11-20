pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Dialogs
import IDS_GIMBAL

// Script window of the final design (opened by Details of the Gimbal settings Script row): file, axes, motor
// mode and sample time on the left, progress and live commands on the right. The player is viewModel.script, so
// closing the window or leaving the page does not stop it.
IdsPopup {
    id: dialog

    required property MainControlViewModel viewModel
    readonly property ScriptRunner runner: viewModel.script
    readonly property ScriptFile file: runner.file
    readonly property ServiceConnection connection: viewModel.connection
    readonly property var units: ["%", "deg/s", "deg"]
    readonly property string unit: units[runner.motorMode]
    readonly property string fileName: file.loaded ? file.path.split(/[\\/]/).pop() : "—"
    // The state of the player in words, also used by the Script row of the page.
    readonly property string stateText: runner.state === ScriptRunner.Running ? qsTr("Running")
        : runner.state === ScriptRunner.Done ? qsTr("Finished")
        : runner.state === ScriptRunner.Stopped ? qsTr("Stopped")
        : runner.state === ScriptRunner.Failed ? qsTr("Failed")
        : file.loaded ? qsTr("Ready") : qsTr("No script loaded")
    readonly property string stateTone: runner.state === ScriptRunner.Running ? "ok"
        : runner.state === ScriptRunner.Stopped ? "warn"
        : runner.state === ScriptRunner.Failed ? "crit" : "idle"

    function seconds(ms: real): string { return NumberFormat.fixed(ms / 1000, 2) }

    parent: T.Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: 740
    padding: 24

    FileDialog {
        id: openDialog
        title: qsTr("Open script")
        nameFilters: [qsTr("CSV file (*.csv)"), qsTr("All files (*)")]
        onAccepted: dialog.file.load(selectedFile)
    }
    FileDialog {
        id: saveDialog
        title: qsTr("Save script")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "csv"
        nameFilters: [qsTr("CSV file (*.csv)")]
        onAccepted: dialog.file.save(selectedFile)
    }

    component Overline: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
        color: Theme.muted
    }
    component LabelText: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsSmall
        color: Theme.muted
    }
    component ValueText: Text {
        font.family: Theme.fontMono
        font.pixelSize: Theme.fsBody
        color: Theme.text
    }
    // Number field of the runner or the file: Enter or focus loss sets it; a refused text marks the field.
    component NumberField: IdsTextField {
        id: field
        property real stored: 0
        property int decimals: 3
        property real min: -1e9
        property real max: 1e9
        property var apply: (value) => {}
        property string shown
        function show() {
            shown = NumberFormat.fixed(stored, decimals)
            text = shown
            error = false
        }
        function commit() {
            if (text === shown)
                return
            const value = NumberFormat.parse(text)
            if (isNaN(value) || value < min || value > max || (decimals === 0 && !Number.isInteger(value))) {
                error = true
                return
            }
            apply(value)
            show()
        }
        implicitWidth: 60
        onStoredChanged: if (text === shown) show()
        onEditingFinished: commit()
        Component.onCompleted: show()
        Connections {
            target: NumberFormat
            function onLanguageChanged() { field.show() }
        }
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            RowLayout {
                spacing: 16
                Text {
                    text: qsTr("Script")
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fsH2
                    font.weight: Font.DemiBold
                    color: Theme.text
                    Accessible.role: Accessible.Heading
                    Accessible.name: text
                }
                StatusLabel { objectName: "dialog-scriptState"; status: dialog.stateTone; text: dialog.stateText; fontSize: Theme.fsSmall }
            }
            LabelText { text: qsTr("Play a CSV trajectory on the Pan and Tilt motors") }
        }
        IdsButton {
            objectName: "command-closeScript"
            variant: "quiet"
            iconPath: Icons.close
            Accessible.name: qsTr("Close")
            onClicked: dialog.close()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 20

        // File, axes, motor mode and sample time
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 3
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Overline { text: qsTr("FILE") }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                IdsTextField {
                    objectName: "value-scriptPath"
                    Layout.fillWidth: true
                    implicitWidth: 60
                    readOnly: true
                    text: dialog.file.loaded ? dialog.file.path : ""
                    placeholderText: "—"
                    onTextChanged: cursorPosition = 0 // show the start of a long path
                    Accessible.name: qsTr("Script file")
                }
                IdsButton {
                    objectName: "command-openCsv"
                    enabled: !dialog.runner.running
                    text: qsTr("Open CSV")
                    onClicked: openDialog.open()
                }
                IdsButton {
                    objectName: "command-saveScriptCsv"
                    enabled: dialog.file.loaded
                    text: qsTr("Save CSV")
                    onClicked: saveDialog.open()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 2
                    LabelText { text: qsTr("Total rows") }
                    ValueText { objectName: "value-scriptRows"; text: dialog.file.loaded ? NumberFormat.fixed(dialog.file.rowCount, 0) : "—" }
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 2
                    LabelText { text: qsTr("Sample time, ms") }
                    ValueText { text: dialog.file.loaded ? NumberFormat.fixed(dialog.runner.sampleMs, 0) : "—" }
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 2
                    LabelText { text: qsTr("Duration, s") }
                    ValueText { objectName: "value-scriptDuration"; text: dialog.file.loaded ? dialog.seconds(dialog.runner.durationMs) : "—" }
                }
            }

            Overline { Layout.topMargin: 4; text: qsTr("AXES") }
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 12
                rowSpacing: 8
                Item { implicitWidth: 1 }
                Overline { text: qsTr("COLUMN") }
                Overline { text: qsTr("OFFSET, %1").arg(dialog.unit.toUpperCase()) }

                RowLayout {
                    spacing: 8
                    IdsSwitch {
                        objectName: "switch-scriptPan"
                        enabled: !dialog.runner.running
                        checked: dialog.runner.panEnabled
                        Accessible.name: qsTr("Pan")
                        onToggled: dialog.runner.panEnabled = checked
                    }
                    Text { text: qsTr("Pan"); font.family: Theme.fontSans; font.pixelSize: Theme.fsBody; color: Theme.text }
                }
                IdsComboBox {
                    objectName: "input-scriptPanColumn"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    mono: true
                    enabled: dialog.file.loaded && !dialog.runner.running
                    model: dialog.file.columns
                    currentIndex: dialog.file.panColumn
                    Accessible.name: qsTr("Pan column")
                    onActivated: index => dialog.file.panColumn = index
                }
                NumberField {
                    objectName: "input-scriptPanOffset"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    enabled: dialog.file.loaded && !dialog.runner.running
                    stored: dialog.file.panOffset
                    apply: (value) => dialog.file.panOffset = value
                    Accessible.name: qsTr("Pan offset")
                }

                RowLayout {
                    spacing: 8
                    IdsSwitch {
                        objectName: "switch-scriptTilt"
                        enabled: !dialog.runner.running
                        checked: dialog.runner.tiltEnabled
                        Accessible.name: qsTr("Tilt")
                        onToggled: dialog.runner.tiltEnabled = checked
                    }
                    Text { text: qsTr("Tilt"); font.family: Theme.fontSans; font.pixelSize: Theme.fsBody; color: Theme.text }
                }
                IdsComboBox {
                    objectName: "input-scriptTiltColumn"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    mono: true
                    enabled: dialog.file.loaded && !dialog.runner.running
                    model: dialog.file.columns
                    currentIndex: dialog.file.tiltColumn
                    Accessible.name: qsTr("Tilt column")
                    onActivated: index => dialog.file.tiltColumn = index
                }
                NumberField {
                    objectName: "input-scriptTiltOffset"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    enabled: dialog.file.loaded && !dialog.runner.running
                    stored: dialog.file.tiltOffset
                    apply: (value) => dialog.file.tiltOffset = value
                    Accessible.name: qsTr("Tilt offset")
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                FormField {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: qsTr("Motor mode")
                    IdsComboBox {
                        objectName: "input-scriptMotorMode"
                        enabled: !dialog.runner.running
                        model: [qsTr("Torque"), qsTr("Speed"), qsTr("Position")]
                        currentIndex: dialog.runner.motorMode
                        onActivated: index => dialog.runner.motorMode = index
                    }
                }
                FormField {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    label: qsTr("Sample time, ms")
                    NumberField {
                        objectName: "input-scriptSampleMs"
                        enabled: !dialog.runner.running
                        decimals: 0
                        min: 1
                        max: 10000
                        stored: dialog.runner.sampleMs
                        apply: (value) => dialog.runner.sampleMs = value
                    }
                }
            }
        }

        Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.line2 }

        // Progress and live commands
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 2
            Layout.alignment: Qt.AlignTop
            spacing: 8

            Overline { text: qsTr("PROGRESS") }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    objectName: "value-scriptRow"
                    text: NumberFormat.fixed(dialog.runner.row, 0)
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fsH2
                    font.weight: Font.DemiBold
                    color: Theme.text
                }
                ValueText { color: Theme.muted; text: "/ " + (dialog.file.loaded ? qsTr("%1 rows").arg(NumberFormat.fixed(dialog.file.rowCount, 0)) : "—") }
                Item { Layout.fillWidth: true }
                ValueText { objectName: "value-scriptPercent"; text: NumberFormat.fixed(dialog.runner.percent, 0) + "%" }
            }
            IdsProgressBar { Layout.fillWidth: true; value: dialog.runner.percent / 100 }
            RowLayout {
                Layout.fillWidth: true
                LabelText { text: qsTr("Elapsed %1 s").arg(dialog.seconds(dialog.runner.elapsedMs)) }
                Item { Layout.fillWidth: true }
                LabelText { text: qsTr("Remaining %1 s").arg(dialog.file.loaded ? dialog.seconds(dialog.runner.remainingMs) : "—") }
            }

            Overline { Layout.topMargin: 8; text: qsTr("LIVE COMMANDS") }
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 12
                rowSpacing: 8
                Item { implicitWidth: 1 }
                Overline { Layout.alignment: Qt.AlignRight; text: qsTr("COMMAND") }
                Overline { Layout.alignment: Qt.AlignRight; text: qsTr("ACTUAL") }

                LabelText { Layout.fillWidth: true; text: qsTr("Pan, %1").arg(dialog.unit) }
                ValueText { objectName: "value-scriptCommandPan"; Layout.alignment: Qt.AlignRight; text: dialog.runner.commandPan.valid ? NumberFormat.fixed(dialog.runner.commandPan.value, 3) : "—" }
                ValueText { objectName: "value-scriptActualPan"; Layout.alignment: Qt.AlignRight; color: Theme.muted; text: dialog.actual(dialog.viewModel.pan) }
                LabelText { Layout.fillWidth: true; text: qsTr("Tilt, %1").arg(dialog.unit) }
                ValueText { objectName: "value-scriptCommandTilt"; Layout.alignment: Qt.AlignRight; text: dialog.runner.commandTilt.valid ? NumberFormat.fixed(dialog.runner.commandTilt.value, 3) : "—" }
                ValueText { objectName: "value-scriptActualTilt"; Layout.alignment: Qt.AlignRight; color: Theme.muted; text: dialog.actual(dialog.viewModel.tilt) }
            }
        }
    }

    // The measured angle is the position; speed and torque have no measured value to compare with a command.
    function actual(measurement): string {
        return runner.motorMode === 2 && measurement.valid ? NumberFormat.fixed(measurement.value, 3) : "—"
    }

    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.line2 }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        CommandButton {
            objectName: "command-setMotor"
            connection: dialog.connection
            kind: Command.SetControlMode
            args: ({mode: dialog.runner.motorMode})
            ready: !dialog.runner.running
            text: qsTr("Set motor")
        }
        CommandButton {
            objectName: "command-closeMotor"
            connection: dialog.connection
            kind: Command.StopControl
            ready: !dialog.runner.running
            variant: "quiet"
            text: qsTr("Close motor")
        }
        Item { Layout.fillWidth: true }
        IdsButton {
            objectName: "command-stopScriptDialog"
            iconPath: Icons.pause
            enabled: dialog.runner.running
            text: qsTr("Stop script")
            onClicked: dialog.runner.stop()
        }
        IdsButton {
            objectName: "command-startScriptDialog"
            variant: "primary"
            iconPath: Icons.play
            enabled: dialog.runner.canStart
            text: qsTr("Start script")
            onClicked: dialog.runner.start()
        }
    }
}
