pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import IDS_GIMBAL

// Gimbal settings page of the final design (3D card | settings, 1:2). Stream, CSV recording, calibrations, filter gains,
// board mode and Safe stop are connected; charts (T12) and Script (T13) are not yet.
// Without command support (real target) values show "—" and every input and command is disabled through
// viewModel.connection.commandsAvailable. The stream rate badge shows what the device reports (1 vs 2 kHz is
// open, §17). Calibration results are read on request and shown until the session ends.
ControlPageFrame {
    id: page

    readonly property ServiceConnection connection: viewModel.connection
    readonly property ParameterModel parameters: viewModel.parameters
    readonly property bool streaming: viewModel.streaming.valid && viewModel.streaming.value
    readonly property CsvRecorder recorder: viewModel.recorder
    property bool readDone: false

    FileDialog {
        id: csvDialog
        title: qsTr("Record CSV")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "csv"
        nameFilters: [qsTr("CSV file (*.csv)")]
        onAccepted: page.recorder.start(selectedFile)
    }

    // The filter gains are read once per connection, when the page is visible.
    function readOnce() {
        if (pageActive && connection.commandsAvailable && !readDone)
            readDone = parameters.read("gimbal.")
    }
    onPageActiveChanged: readOnce()
    Connections {
        target: page.connection
        function onChanged() {
            if (!page.connection.commandsAvailable)
                page.readDone = false
            page.readOnce()
        }
    }
    Component.onCompleted: readOnce()

    // Esc is Safe stop, but only while this page is visible and the button could send it.
    Shortcut {
        sequence: "Esc"
        enabled: page.pageActive && safeStop.enabled
        onActivated: safeStop.clicked()
    }

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
    // Filter gain: Enter or focus loss sets the value and writes the "gimbal." parameters; a value the model
    // refuses (not a number, outside the range) is never sent.
    component GainField: ValueField {
        id: gain
        required property string key
        readonly property var stored: page.parameters.values[key]
        property string shown // what show() put in the field; differs while the user is typing

        function show() {
            shown = stored === undefined ? "" : NumberFormat.fixed(stored, 4)
            text = shown
            error = false
        }
        function commit() {
            if (text === shown)
                return
            const value = NumberFormat.parse(text)
            if (isNaN(value) || !page.parameters.set(key, value)) {
                error = true
                return
            }
            show()
            page.parameters.write("gimbal.")
        }
        onStoredChanged: if (text === shown) show()
        onEditingFinished: commit()
        Component.onCompleted: show()
        Connections {
            target: NumberFormat
            function onLanguageChanged() { gain.show() }
        }
    }
    component CalibrationProgress: IdsProgressBar {
        required property int kind
        Layout.fillWidth: true
        visible: page.connection.progressKind === kind
        from: 0
        to: 100
        value: page.connection.progressPercent
        Accessible.name: qsTr("Calibration progress")
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
                Badge {
                    objectName: "value-streamRate"
                    visible: page.viewModel.streamRate.valid
                    kind: page.streaming ? "ok" : "neutral"
                    text: !page.streaming ? qsTr("Stopped")
                        : page.viewModel.streamRate.value % 1000 === 0 ? NumberFormat.fixed(page.viewModel.streamRate.value / 1000, 0) + " kHz"
                        : NumberFormat.fixed(page.viewModel.streamRate.value, 0) + " Hz"
                }
                CommandButton {
                    objectName: "command-startStream"
                    connection: page.connection
                    kind: Command.StartStream
                    iconPath: Icons.play
                    text: qsTr("Start stream")
                    ready: !page.streaming
                }
                CommandButton {
                    objectName: "command-stopStream"
                    connection: page.connection
                    kind: Command.StopStream
                    variant: "quiet"
                    text: qsTr("Stop stream")
                    ready: page.streaming
                }
                Item { implicitWidth: 8 }
                IdsButton {
                    objectName: "command-recordCsv"
                    iconPath: Icons.record
                    busy: page.recorder.recording
                    enabled: page.connection.connected && !page.recorder.recording
                    text: page.recorder.recording ? qsTr("Recording…") : qsTr("Record CSV")
                    onClicked: csvDialog.open()
                }
                IdsButton {
                    objectName: "command-saveCsv"
                    variant: "quiet"
                    enabled: page.recorder.recording
                    text: qsTr("Save CSV")
                    onClicked: page.recorder.stop()
                }
                ValueText { objectName: "value-packets"; text: (page.viewModel.packetCount.valid ? NumberFormat.fixed(page.viewModel.packetCount.value, 0) : "—") + " " + qsTr("packets") }
                ValueText {
                    objectName: "value-csvRows"
                    visible: page.recorder.recording
                    text: qsTr("%1 rows").arg(NumberFormat.fixed(page.recorder.rowCount, 0))
                }
                Item { Layout.fillWidth: true }
                CommandButton {
                    id: safeStop
                    objectName: "command-safeStop"
                    connection: page.connection
                    kind: Command.SafeStop
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
                InfoRow { objectName: "value-rawPosition"; Layout.fillWidth: true; compact: true; label: qsTr("Raw position"); value: page.viewModel.rawPosition.valid ? NumberFormat.fixed(page.viewModel.rawPosition.value, 0) : "—"; showDivider: false }
                CommandButton {
                    objectName: "command-electricalAngle"
                    connection: page.connection
                    kind: Command.StartElectricalAngleCalibration
                    Layout.fillWidth: true
                    text: qsTr("Start electrical angle calibration")
                }
                CalibrationProgress { kind: Command.StartElectricalAngleCalibration }
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
                CommandButton {
                    objectName: "command-crosstalk"
                    connection: page.connection
                    kind: Command.StartCrosstalkCheck
                    Layout.fillWidth: true
                    text: qsTr("Check optical crosstalk")
                }
                CalibrationProgress { kind: Command.StartCrosstalkCheck }
                StatusLabel {
                    objectName: "value-crosstalk"
                    readonly property crosstalkResult result: page.viewModel.crosstalk
                    status: !result.valid ? "idle" : result.passed ? "ok" : "crit"
                    text: !result.valid ? qsTr("Not checked")
                        : (result.passed ? qsTr("Passed, %1%") : qsTr("Failed, %1%")).arg(NumberFormat.fixed(result.percent, 1))
                }
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
                    FormField {
                        Layout.fillWidth: true
                        label: qsTr("Gyro X")
                        ValueField { objectName: "value-gyroX"; readOnly: true; text: page.viewModel.imuBias.valid ? NumberFormat.fixed(page.viewModel.imuBias.x, 3) : ""; Accessible.name: qsTr("Gyro X bias") }
                    }
                    FormField {
                        Layout.fillWidth: true
                        label: qsTr("Gyro Y")
                        ValueField { objectName: "value-gyroY"; readOnly: true; text: page.viewModel.imuBias.valid ? NumberFormat.fixed(page.viewModel.imuBias.y, 3) : ""; Accessible.name: qsTr("Gyro Y bias") }
                    }
                    FormField {
                        Layout.fillWidth: true
                        label: qsTr("Gyro Z")
                        ValueField { objectName: "value-gyroZ"; readOnly: true; text: page.viewModel.imuBias.valid ? NumberFormat.fixed(page.viewModel.imuBias.z, 3) : ""; Accessible.name: qsTr("Gyro Z bias") }
                    }
                }
                CommandButton {
                    objectName: "command-imuBias"
                    connection: page.connection
                    kind: Command.StartImuBiasCalibration
                    Layout.fillWidth: true
                    text: qsTr("Start bias calibration")
                }
                CalibrationProgress { kind: Command.StartImuBiasCalibration }
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
                    FormField { Layout.fillWidth: true; label: "Kp"; GainField { objectName: "input-filterKp"; key: "gimbal.filterKp"; Accessible.name: qsTr("Filter Kp") } }
                    FormField { Layout.fillWidth: true; label: "Ki"; GainField { objectName: "input-filterKi"; key: "gimbal.filterKi"; Accessible.name: qsTr("Filter Ki") } }
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
                LabelText { objectName: "value-boardMode"; text: qsTr("Board mode %1").arg(page.viewModel.boardMode.valid ? page.viewModel.boardMode.value : "—") }
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
