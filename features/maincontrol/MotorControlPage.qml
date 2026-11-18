pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import IDS_GIMBAL

// Motor control page of the final design (three equal columns: 3D card | Motor configuration | Control).
// Fields show viewModel.parameters (pan. / tilt. keys), edits wait there as "unsaved" until Write. Without
// command support (real target) every input and command is disabled through
// viewModel.connection.commandsAvailable and fields stay empty.
// Not taken from the design: the profile buttons. The option lists and the command ranges are fixed lists
// until the protocol document arrives (docs/kararlar.md, T8).
ControlPageFrame {
    id: page

    readonly property ServiceConnection connection: viewModel.connection
    readonly property ParameterModel parameters: viewModel.parameters
    property string motor: "pan" // motor whose parameters the Configure card shows (page state, not sent)
    property bool readDone: false
    readonly property var referenceTypes: ["torque", "speed", "position"]
    readonly property var referenceRanges: [[-100, 100], [-360, 360], [-180, 180]]
    readonly property var referenceLabels: [qsTr("Torque, %"), qsTr("Speed, deg/s"), qsTr("Position, deg")]
    property var referenceValues: [0, 0, 0]
    readonly property real keyboardStep: 1 // one arrow key press changes the reference by this much

    function range(type: int): string {
        return qsTr("Range %1 to %2.").arg(NumberFormat.fixed(referenceRanges[type][0], 3)).arg(NumberFormat.fixed(referenceRanges[type][1], 3))
    }
    // True when the reference was sent.
    function sendReference(value: real): bool {
        const type = commandType.currentIndex
        if (isNaN(value) || value < referenceRanges[type][0] || value > referenceRanges[type][1]) {
            referenceField.error = true
            return false
        }
        referenceField.error = false
        const values = referenceValues.slice()
        values[type] = value
        referenceValues = values
        referenceField.text = NumberFormat.fixed(value, 3)
        return connection.send(Command.SetReference, {type: referenceTypes[type], value: value})
    }
    // Arrow key of Keyboard control: direction +1 / -1.
    function nudge(direction: int) {
        if (!keyboardControl.checked || !pageActive)
            return
        const current = NumberFormat.parse(referenceField.text)
        sendReference((isNaN(current) ? referenceValues[commandType.currentIndex] : current) + direction * keyboardStep)
    }
    // The parameters are read once per connection, when the page is visible.
    function readOnce() {
        if (pageActive && connection.commandsAvailable && !readDone)
            readDone = parameters.read()
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

    FileDialog {
        id: saveDialog
        title: qsTr("Save parameter profile")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: [qsTr("Parameter profile (*.json)")]
        onAccepted: page.parameters.saveProfile(selectedFile)
    }
    FileDialog {
        id: loadDialog
        title: qsTr("Load parameter profile")
        nameFilters: [qsTr("Parameter profile (*.json)"), qsTr("All files (*)")]
        onAccepted: page.parameters.loadProfile(selectedFile)
    }
    component Arrow: Shortcut {
        property int direction
        enabled: page.pageActive && keyboardControl.checked && page.connection.commandsAvailable
        onActivated: page.nudge(direction)
    }
    Arrow { sequence: "Left"; direction: -1 }
    Arrow { sequence: "Down"; direction: -1 }
    Arrow { sequence: "Right"; direction: 1 }
    Arrow { sequence: "Up"; direction: 1 }

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
        id: field
        // Parameter name without the motor prefix, e.g. "torqueKp".
        property string name
        property int decimals: 4
        property bool numeric: true
        readonly property string key: page.motor + "." + name
        readonly property var stored: page.parameters.values[key]
        property string shown // what show() put in the field; differs while the user is typing

        function show() {
            shown = stored === undefined ? "" : numeric ? NumberFormat.fixed(stored, decimals) : stored
            text = shown
            error = false
        }
        // Enter or focus loss: a value the model refuses (not a number, out of range) is never sent.
        function commit() {
            if (text === shown)
                return
            const value = numeric ? NumberFormat.parse(text) : text
            if ((numeric && isNaN(value)) || !page.parameters.set(key, value))
                error = true
            else
                show()
        }

        Layout.fillWidth: true
        implicitWidth: 60
        compact: true // 34 px: keeps the dense parameter grids close to the design height
        placeholderText: "—"
        onStoredChanged: if (text === shown) show()
        onKeyChanged: show()
        onEditingFinished: commit()
        Component.onCompleted: show()
        Connections {
            target: NumberFormat
            function onLanguageChanged() { field.show() }
        }
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

            RowLayout {
                Layout.fillWidth: true
                SectionHeading {
                    title: qsTr("Motor configuration")
                    subtitle: qsTr("Gains, limits and wiring of the selected motor")
                }
                Item { Layout.fillWidth: true }
                Badge {
                    objectName: "unsavedBadge"
                    Layout.alignment: Qt.AlignTop
                    visible: page.parameters.unsavedCount > 0
                    kind: "warn"
                    text: qsTr("%1 unsaved changes").arg(page.parameters.unsavedCount)
                }
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
                SegmentedControl {
                    objectName: "motorSelect"
                    width: 160
                    model: [qsTr("Pan"), qsTr("Tilt")]
                    onActivated: index => page.motor = index === 0 ? "pan" : "tilt"
                }
                CommandButton {
                    objectName: "command-read"
                    connection: page.connection
                    kind: Command.ReadParameters
                    perform: () => page.parameters.read()
                    text: qsTr("Read")
                }
                CommandButton {
                    objectName: "command-write"
                    connection: page.connection
                    kind: Command.WriteParameters
                    ready: page.parameters.unsavedCount > 0
                    perform: () => page.parameters.write()
                    text: qsTr("Write")
                }
                CommandButton {
                    objectName: "command-saveToFlash"
                    connection: page.connection
                    kind: Command.SaveParametersToFlash
                    perform: () => page.parameters.saveToFlash()
                    variant: "primary"
                    text: qsTr("Save to flash")
                }
                CommandButton {
                    objectName: "command-defaults"
                    connection: page.connection
                    kind: Command.RestoreDefaultParameters
                    perform: () => page.parameters.restoreDefaults()
                    variant: "quiet"
                    text: qsTr("Defaults")
                }
                IdsButton { objectName: "command-saveProfile"; variant: "quiet"; text: qsTr("Save profile…"); onClicked: saveDialog.open() }
                IdsButton { objectName: "command-loadProfile"; variant: "quiet"; text: qsTr("Load profile…"); onClicked: loadDialog.open() }
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
                    ValueField { objectName: "input-torqueKp"; name: "torqueKp"; Accessible.name: qsTr("Torque Kp") }
                    ValueField { objectName: "input-torqueKi"; name: "torqueKi"; Accessible.name: qsTr("Torque Ki") }
                    ValueField { objectName: "input-torqueKd"; name: "torqueKd"; Accessible.name: qsTr("Torque Kd") }
                    LoopLabel { text: qsTr("Speed") }
                    ValueField { objectName: "input-speedKp"; name: "speedKp"; Accessible.name: qsTr("Speed Kp") }
                    ValueField { objectName: "input-speedKi"; name: "speedKi"; Accessible.name: qsTr("Speed Ki") }
                    ValueField { objectName: "input-speedKd"; name: "speedKd"; Accessible.name: qsTr("Speed Kd") }
                    LoopLabel { text: qsTr("Position") }
                    ValueField { objectName: "input-positionKp"; name: "positionKp"; Accessible.name: qsTr("Position Kp") }
                    ValueField { objectName: "input-positionKi"; name: "positionKi"; Accessible.name: qsTr("Position Ki") }
                    ValueField { objectName: "input-positionKd"; name: "positionKd"; Accessible.name: qsTr("Position Kd") }
                    LoopLabel { text: qsTr("Tracker") }
                    ValueField { objectName: "input-trackerKp"; name: "trackerKp"; Accessible.name: qsTr("Tracker Kp") }
                    ValueField { objectName: "input-trackerKi"; name: "trackerKi"; Accessible.name: qsTr("Tracker Ki") }
                    ValueField { objectName: "input-trackerKd"; name: "trackerKd"; Accessible.name: qsTr("Tracker Kd") }
                }
                FormField {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 320
                    label: qsTr("Model serial number")
                    ValueField { objectName: "input-modelSerial"; name: "modelSerial"; numeric: false }
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
                    FormField { Layout.fillWidth: true; label: qsTr("Position offset, deg"); ValueField { objectName: "input-positionOffsetDeg"; name: "positionOffsetDeg"; decimals: 3 } }
                    FormField { Layout.fillWidth: true; label: qsTr("Electrical offset, deg"); ValueField { objectName: "input-electricalOffsetDeg"; name: "electricalOffsetDeg"; decimals: 3 } }
                    FormField { Layout.fillWidth: true; label: qsTr("Forward border, deg"); ValueField { objectName: "input-forwardBorderDeg"; name: "forwardBorderDeg"; decimals: 3 } }
                    FormField { Layout.fillWidth: true; label: qsTr("Backward border, deg"); ValueField { objectName: "input-backwardBorderDeg"; name: "backwardBorderDeg"; decimals: 3 } }
                    FormField {
                        Layout.fillWidth: true
                        label: qsTr("Encoder rotation")
                        SegmentedControl {
                            objectName: "input-encoderReverse"
                            model: [qsTr("Forward"), qsTr("Reverse")]
                            onActivated: index => page.parameters.set(page.motor + ".encoderReverse", index === 1)
                            Binding on currentIndex { value: page.parameters.values[page.motor + ".encoderReverse"] ? 1 : 0 }
                        }
                    }
                    FormField {
                        Layout.fillWidth: true
                        label: qsTr("Phase rotation")
                        IdsComboBox {
                            objectName: "input-phaseRotation"
                            textRole: "text"
                            valueRole: "value"
                            model: ["A-B-C", "A-C-B", "B-A-C", "B-C-A", "C-A-B", "C-B-A"].map((text, value) => ({text, value}))
                            selectedValue: page.parameters.values[page.motor + ".phaseRotation"] ?? -1
                            onActivated: page.parameters.set(page.motor + ".phaseRotation", currentValue)
                        }
                    }
                }
                ToggleRow {
                    objectName: "input-slipRing"
                    Layout.fillWidth: true
                    text: qsTr("Slip ring")
                    onToggled: page.parameters.set(page.motor + ".slipRing", switchItem.checked)
                    Binding on checked { value: !!page.parameters.values[page.motor + ".slipRing"] }
                }
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
                    FormField {
                        Layout.fillWidth: true
                        label: qsTr("Control mode")
                        IdsComboBox {
                            objectName: "input-controlMode"
                            currentIndex: 2 // the device does not report it yet
                            model: [qsTr("Torque"), qsTr("Speed"), qsTr("Position")]
                            onActivated: index => page.connection.send(Command.SetControlMode, {mode: index})
                        }
                    }
                    FormField {
                        Layout.fillWidth: true
                        label: qsTr("Current motor")
                        IdsComboBox {
                            objectName: "input-currentMotor"
                            model: [qsTr("Pan"), qsTr("Tilt")]
                            onActivated: index => page.connection.send(Command.SelectMotor, {motor: index === 0 ? "pan" : "tilt"})
                        }
                    }
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
                        CommandButton { objectName: "command-toggleLatch"; connection: page.connection; kind: Command.ToggleLatch; text: qsTr("Toggle latch") }
                    }
                }
                ToggleRow { id: keyboardControl; objectName: "input-keyboardControl"; Layout.fillWidth: true; text: qsTr("Keyboard control") }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    CommandButton {
                        objectName: "command-startControl"
                        connection: page.connection
                        kind: Command.StartControl
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.touchMin
                        variant: "primary"
                        iconPath: Icons.play
                        text: qsTr("Start control")
                    }
                    CommandButton {
                        objectName: "command-stopControl"
                        connection: page.connection
                        kind: Command.StopControl
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
                    objectName: "referenceType"
                    Layout.fillWidth: true
                    currentIndex: 2
                    model: [qsTr("Torque"), qsTr("Speed"), qsTr("Position")]
                }
                FormField {
                    Layout.fillWidth: true
                    label: page.referenceLabels[commandType.currentIndex]
                    RowLayout {
                        spacing: 8
                        IdsTextField {
                            id: referenceField
                            objectName: "input-reference"
                            Layout.fillWidth: true
                            implicitWidth: 60
                            compact: true
                            Accessible.name: page.referenceLabels[commandType.currentIndex]
                            text: NumberFormat.fixed(page.referenceValues[commandType.currentIndex], 3)
                            onTextEdited: error = false
                            onAccepted: page.sendReference(NumberFormat.parse(text))
                        }
                        CommandButton {
                            objectName: "command-set"
                            connection: page.connection
                            kind: Command.SetReference
                            perform: () => page.sendReference(NumberFormat.parse(referenceField.text))
                            text: qsTr("Set")
                        }
                        CommandButton {
                            objectName: "command-reset"
                            connection: page.connection
                            kind: Command.ResetReference
                            args: ({type: page.referenceTypes[commandType.currentIndex]})
                            variant: "quiet"
                            text: qsTr("Reset")
                        }
                    }
                }
                Text {
                    text: qsTr("%1 Enter sends the value.").arg(page.range(commandType.currentIndex))
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fsSmall
                    color: Theme.label
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
