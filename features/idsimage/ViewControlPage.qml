pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// View & control page of the final design: Stream, Attitude and Target control cards next to the video.
// Everything shown is device telemetry (viewModel.sample). Settings and choices go to the device as soon as the
// user lets go of the control and are not shown as changed until the device reports them; while one is
// pending the control keeps the user's position. Without command support (real target) every input is
// disabled and values show "—".
ImagePageFrame {
    id: page

    readonly property ServiceConnection connection: viewModel.connection
    readonly property bool settingPending: connection.pendingCommands.includes(Command.ImageSetStreamSetting)
    // Range of the position fields in degrees (the design gives none, docs/kararlar.md T17).
    readonly property real rollLimit: 180
    readonly property real tiltLimit: 90

    function pending(kind: int): bool {
        return connection.pendingCommands.includes(kind)
    }
    function sendSetting(name: string, value: var): bool {
        return connection.send(Command.ImageSetStreamSetting, {setting: name, value: value})
    }
    function inRange(value: real, limit: real): bool {
        return !isNaN(value) && Math.abs(value) <= limit
    }
    function sendPosition(): bool {
        const roll = NumberFormat.parse(rollField.text)
        const tilt = NumberFormat.parse(tiltField.text)
        rollField.error = !inRange(roll, rollLimit)
        tiltField.error = !inRange(tilt, tiltLimit)
        return !rollField.error && !tiltField.error && connection.send(Command.ImageSetPosition, {roll: roll, tilt: tilt})
    }

    component CardLabel: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsSmall
        color: Theme.muted
    }
    component SectionLabel: Text {
        Layout.fillWidth: true
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.overlineSpacing
        font.capitalization: Font.AllUppercase
        color: Theme.label
    }
    component MotorTile: Rectangle {
        id: tile
        property string label
        property string value
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 48
        radius: Theme.rInp
        color: Theme.input
        border.width: 1
        border.color: Theme.line
        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            Text {
                width: parent.width
                text: tile.label
                elide: Text.ElideRight
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsOverline
                color: Theme.muted
            }
            Text {
                width: parent.width
                text: tile.value
                elide: Text.ElideRight
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsBody
                color: Theme.text
            }
        }
    }

    // Slider of a stream setting: sends on release (keyboard steps count as released); shows the device value.
    component SettingSlider: RowLayout {
        id: row
        required property string setting
        required property string label
        required property measurement reading
        property real from: 0
        property real to: 255
        property real step: 1
        property int decimals: 0
        property string prefix: ""

        Layout.fillWidth: true
        spacing: 12
        CardLabel {
            Layout.preferredWidth: 72
            text: row.label
            elide: Text.ElideRight
        }
        IdsSlider {
            id: slider
            objectName: "slider-" + row.setting
            Layout.fillWidth: true
            implicitWidth: 60
            from: row.from
            to: row.to
            stepSize: row.step
            enabled: page.connection.commandsAvailable && !page.settingPending
            Accessible.name: row.label
            onPressedChanged: if (!pressed) page.sendSetting(row.setting, value)
            onMoved: if (!pressed) page.sendSetting(row.setting, value)
            Binding on value { value: row.reading.valid ? row.reading.value : row.from; when: !slider.pressed && !page.settingPending }
        }
        Text {
            objectName: "value-" + row.setting
            Layout.preferredWidth: 44
            horizontalAlignment: Text.AlignRight
            text: row.reading.valid ? row.prefix + NumberFormat.fixed(row.reading.value, row.decimals) : "—"
            font.family: Theme.fontMono
            font.pixelSize: Theme.fsBody
            color: Theme.text
        }
    }

    // Choice list of the device; the lists are fixed until the protocol document gives the real ones.
    component ModeCombo: FormField {
        id: field
        required property string setting
        required property var options
        required property measurement reading
        Layout.fillWidth: true
        IdsComboBox {
            objectName: "combo-" + field.setting
            compact: true
            textRole: "text"
            valueRole: "value"
            model: field.options.map((text, value) => ({text, value}))
            selectedValue: field.reading.valid ? field.reading.value : -1
            displayText: currentIndex < 0 ? qsTr("Select...") : currentText
            enabled: page.connection.commandsAvailable && !page.settingPending
            onActivated: page.sendSetting(field.setting, currentValue)
        }
    }

    // Switch whose state is the device's; sends the new state when toggled.
    component DeviceToggle: ToggleRow {
        id: toggle
        required property flag reading
        required property int kind
        required property var send
        Layout.fillWidth: true
        enabled: page.connection.commandsAvailable && !page.pending(kind)
        onToggled: send(switchItem.checked)
        Binding on checked { value: toggle.reading.value; when: !page.pending(toggle.kind) }
    }

    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("Stream")

        SettingSlider { setting: "zoom"; label: qsTr("Zoom"); reading: page.sample.zoom; from: 1; to: 10; step: 0.1; decimals: 1; prefix: "x" }
        SettingSlider { setting: "blend"; label: qsTr("Blend"); reading: page.sample.blend }
        SettingSlider { setting: "brightness"; label: qsTr("Brightness"); reading: page.sample.brightness }
        SettingSlider { setting: "contrast"; label: qsTr("Contrast"); reading: page.sample.contrast }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            ModeCombo {
                label: qsTr("Stream mode")
                setting: "streamMode"
                reading: page.sample.streamMode
                options: [qsTr("Visible"), qsTr("Thermal"), qsTr("Blend")]
            }
            ModeCombo {
                label: qsTr("Polarity mode")
                setting: "polarity"
                reading: page.sample.polarity
                options: [qsTr("White hot"), qsTr("Black hot")]
            }
            ModeCombo {
                label: qsTr("FFC mode")
                setting: "ffcMode"
                reading: page.sample.ffcMode
                options: [qsTr("FFC manual"), qsTr("FFC auto")]
            }
        }
        CommandButton {
            objectName: "command-nuc"
            Layout.fillWidth: true
            connection: page.connection
            kind: Command.ImageTriggerNuc
            text: qsTr("Trigger shutter (NUC)")
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            DeviceToggle {
                objectName: "toggle-overlay"
                text: qsTr("Stream overlay info")
                reading: page.sample.overlay
                kind: Command.ImageSetStreamSetting
                send: checked => page.sendSetting("overlay", checked)
            }
            DeviceToggle {
                objectName: "toggle-skyUp"
                text: qsTr("Sky up")
                reading: page.sample.skyUp
                kind: Command.ImageSetStreamSetting
                send: checked => page.sendSetting("skyUp", checked)
            }
        }
    }

    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("Attitude")
        actions: [
            // "P" is not named in the design: read as Park, the gimbal's park position (docs/kararlar.md T17).
            CommandButton {
                objectName: "command-park"
                connection: page.connection
                kind: Command.ImagePark
                text: "P"
                Accessible.name: qsTr("Park position")
            },
            CommandButton {
                objectName: "command-attitudeEnable"
                connection: page.connection
                kind: Command.ImageAttitudeEnable
                variant: "primary"
                ready: page.sample.attitudeEnabled.valid
                text: page.sample.attitudeEnabled.value ? qsTr("Disable") : qsTr("Enable")
                perform: () => page.connection.send(Command.ImageAttitudeEnable, {enabled: !page.sample.attitudeEnabled.value})
            }
        ]

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            CardLabel {
                Layout.fillWidth: true
                text: qsTr("Control device")
            }
            SegmentedControl {
                objectName: "controlDevice"
                model: [qsTr("Keyboard"), qsTr("Joystick")]
                enabled: page.connection.commandsAvailable && !page.pending(Command.ImageSetControlDevice)
                onActivated: index => page.connection.send(Command.ImageSetControlDevice, {device: index === 1 ? "joystick" : "keyboard"})
                Binding on currentIndex {
                    value: page.sample.controlDevice.valid ? page.sample.controlDevice.value : -1
                    when: !page.pending(Command.ImageSetControlDevice)
                }
            }
        }
        SectionLabel { text: qsTr("Motor status") }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            MotorTile { objectName: "tile-roll"; label: qsTr("Roll, deg"); value: page.number(page.sample.rollDeg, 1) }
            MotorTile { objectName: "tile-tilt"; label: qsTr("Tilt, deg"); value: page.number(page.sample.tiltDeg, 1) }
            MotorTile { objectName: "tile-rollRate"; label: qsTr("Roll, deg/s"); value: page.number(page.sample.rollRateDps, 0) }
            MotorTile { objectName: "tile-tiltRate"; label: qsTr("Tilt, deg/s"); value: page.number(page.sample.tiltRateDps, 0) }
        }
        SectionLabel { text: qsTr("Position control") }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            IdsTextField {
                id: rollField
                objectName: "input-roll"
                Layout.fillWidth: true
                implicitWidth: 40
                compact: true
                placeholderText: qsTr("Roll, deg")
                enabled: page.connection.commandsAvailable
                Accessible.name: qsTr("Roll, deg (%1 to %2)").arg(-page.rollLimit).arg(page.rollLimit)
                onTextEdited: error = false
                onAccepted: page.sendPosition()
            }
            IdsTextField {
                id: tiltField
                objectName: "input-tilt"
                Layout.fillWidth: true
                implicitWidth: 40
                compact: true
                placeholderText: qsTr("Tilt, deg")
                enabled: page.connection.commandsAvailable
                Accessible.name: qsTr("Tilt, deg (%1 to %2)").arg(-page.tiltLimit).arg(page.tiltLimit)
                onTextEdited: error = false
                onAccepted: page.sendPosition()
            }
            CommandButton {
                objectName: "command-resetPosition"
                compact: true
                connection: page.connection
                kind: Command.ImageResetPosition
                iconPath: Icons.resetView
                Accessible.name: qsTr("Reset position")
            }
            CommandButton {
                objectName: "command-setPosition"
                compact: true
                connection: page.connection
                kind: Command.ImageSetPosition
                text: qsTr("Set")
                perform: () => page.sendPosition()
            }
        }
    }

    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("Target control")

        DeviceToggle {
            objectName: "toggle-lrfPointer"
            text: qsTr("LRF pointer")
            reading: page.sample.lrfPointer
            kind: Command.ImageLrfPointer
            send: checked => page.connection.send(Command.ImageLrfPointer, {enabled: checked})
        }
        FormField {
            Layout.fillWidth: true
            label: qsTr("Distance, m")
            RowLayout {
                spacing: 8
                IdsTextField {
                    objectName: "lrfDistance"
                    Layout.fillWidth: true
                    implicitWidth: 60
                    compact: true
                    readOnly: true
                    enabled: page.connection.commandsAvailable
                    Accessible.name: qsTr("Distance, m")
                    text: page.number(page.sample.lrfDistanceM, 1)
                }
                IdsComboBox {
                    id: lrfMode
                    objectName: "combo-lrfMode"
                    compact: true
                    Layout.preferredWidth: 120
                    model: [qsTr("Single"), qsTr("Continuous")]
                    enabled: page.connection.commandsAvailable
                    Accessible.name: qsTr("Measurement mode")
                }
                CommandButton {
                    objectName: "command-lrfMeasure"
                    compact: true
                    connection: page.connection
                    kind: Command.ImageLrfMeasure
                    text: qsTr("Start")
                    perform: () => page.connection.send(Command.ImageLrfMeasure, {mode: lrfMode.currentIndex === 1 ? "continuous" : "single"})
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            CardLabel {
                Layout.fillWidth: true
                text: qsTr("Box size")
            }
            CommandButton {
                objectName: "command-boxSmaller"
                compact: true
                connection: page.connection
                kind: Command.ImageBoxSize
                args: ({delta: -1})
                text: "−"
                Accessible.name: qsTr("Smaller box")
            }
            CommandButton {
                objectName: "command-boxLarger"
                compact: true
                connection: page.connection
                kind: Command.ImageBoxSize
                args: ({delta: 1})
                text: "+"
                Accessible.name: qsTr("Larger box")
            }
            CommandButton {
                objectName: "command-track"
                connection: page.connection
                kind: Command.ImageTrack
                variant: "primary"
                text: qsTr("Track")
            }
        }
        DeviceToggle {
            objectName: "toggle-followTarget"
            text: qsTr("Follow tracked target")
            reading: page.sample.followTarget
            kind: Command.ImageFollowTarget
            send: checked => page.connection.send(Command.ImageFollowTarget, {enabled: checked})
        }
    }
    Item { Layout.fillHeight: true }
}
