pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Alignment page of the final design: Camera, Camera offset and CMOS camera cards next to the video.
// Shown values are device telemetry (viewModel.sample). Settings go out as soon as the user acts on them, except
// the offset block: Image scale and the Offset X/Y buttons only change the page's own values and Write offset
// sends them together. Without command support (real target) every input is disabled and values show "—".
ImagePageFrame {
    id: page

    readonly property ServiceConnection connection: viewModel.connection
    readonly property bool settingPending: connection.pendingCommands.includes(Command.ImageSetStreamSetting)
    // Ranges the design does not give (docs/kararlar.md T18).
    readonly property int offsetLimit: 100
    readonly property real scaleFrom: 0.5
    readonly property real scaleTo: 2.5
    readonly property real maxDistance: 100000

    // Own values of the offset block: they follow the device until the user changes one.
    property bool offsetEdited: false
    property real offsetX: 0
    property real offsetY: 0
    property real imageScale: 1

    function sendSetting(name: string, value: var): bool {
        return connection.send(Command.ImageSetStreamSetting, {setting: name, value: value})
    }
    function step(axis: string, delta: int) {
        offsetEdited = true
        page[axis] = Math.max(-offsetLimit, Math.min(offsetLimit, page[axis] + delta))
    }
    function writeOffset(): bool {
        const sent = connection.send(Command.ImageWriteOffset, {x: offsetX, y: offsetY, scale: imageScale})
        offsetEdited = false // follow the device again (after the values were read)
        return sent
    }
    function distanceText(m: measurement): string {
        return !m.valid ? "" : isFinite(m.value) ? NumberFormat.fixed(m.value, 1) : qsTr("Infinity")
    }
    // A distance in metres above 0, or infinity ("inf", "∞" or the shown word); NaN when it is neither.
    function parseDistance(text: string): real {
        const t = text.trim().toLowerCase()
        if (t === "∞" || t === "inf" || t === qsTr("Infinity").toLowerCase())
            return Infinity
        const v = NumberFormat.parse(t)
        return v > 0 && v <= maxDistance ? v : NaN
    }
    // Sends the distance of a field with `send`; a bad one gets the error frame and is not sent.
    function sendDistance(field: var, send: var): bool {
        const d = parseDistance(field.text)
        field.error = isNaN(d)
        if (field.error)
            return false
        field.edited = false
        return send(d)
    }

    Binding { target: page; restoreMode: Binding.RestoreNone; property: "offsetX"; value: page.sample.offsetX.value; when: page.sample.offsetX.valid && !page.offsetEdited }
    Binding { target: page; restoreMode: Binding.RestoreNone; property: "offsetY"; value: page.sample.offsetY.value; when: page.sample.offsetY.valid && !page.offsetEdited }
    Binding { target: page; restoreMode: Binding.RestoreNone; property: "imageScale"; value: page.sample.imageScale.value; when: page.sample.imageScale.valid && !page.offsetEdited }

    component CardLabel: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsSmall
        color: Theme.muted
    }

    // Choice of the device shown as segments; sends the index.
    component DeviceSegments: SegmentedControl {
        id: seg
        required property string setting
        required property measurement reading
        enabled: page.connection.commandsAvailable && !page.settingPending
        onActivated: index => page.sendSetting(setting, index)
        Binding on currentIndex { value: seg.reading.valid ? seg.reading.value : -1; when: !page.settingPending }
    }

    component DeviceToggle: ToggleRow {
        id: toggle
        required property flag reading
        required property string setting
        Layout.fillWidth: true
        enabled: page.connection.commandsAvailable && !page.settingPending
        onToggled: page.sendSetting(setting, switchItem.checked)
        Binding on checked { value: toggle.reading.value; when: !page.settingPending }
    }

    // Distance field: shows the device value until the user types.
    component DistanceField: IdsTextField {
        id: field
        required property measurement reading
        property bool edited: false
        Layout.fillWidth: true
        implicitWidth: 60
        compact: true
        enabled: page.connection.commandsAvailable
        onTextEdited: { error = false; edited = true }
        Binding on text { value: page.distanceText(field.reading); when: !field.edited }
    }

    // Offset X / Y: minus, own value, plus. Local only, so plain buttons (no command to wait for).
    component OffsetStepper: FormField {
        id: stepper
        required property string axis
        Layout.fillWidth: true
        RowLayout {
            spacing: 6
            IdsButton {
                objectName: "offsetMinus-" + stepper.axis
                compact: true
                text: "−"
                enabled: page.connection.commandsAvailable
                Accessible.name: qsTr("Decrease %1").arg(stepper.label)
                onClicked: page.step(stepper.axis, -1)
            }
            IdsTextField {
                objectName: "offsetValue-" + stepper.axis
                Layout.preferredWidth: 56
                compact: true
                readOnly: true
                horizontalAlignment: TextInput.AlignHCenter
                leftPadding: 4
                rightPadding: 4
                enabled: page.connection.commandsAvailable
                Accessible.name: stepper.label
                text: NumberFormat.fixed(page[stepper.axis], 0)
            }
            IdsButton {
                objectName: "offsetPlus-" + stepper.axis
                compact: true
                text: "+"
                enabled: page.connection.commandsAvailable
                Accessible.name: qsTr("Increase %1").arg(stepper.label)
                onClicked: page.step(stepper.axis, 1)
            }
        }
    }

    // Gain / Iris / Shutter: step buttons and the Manual / Auto choice.
    component CameraControl: RowLayout {
        id: row
        required property string param
        required property string label
        required property measurement reading
        Layout.fillWidth: true
        spacing: 8
        CardLabel {
            Layout.fillWidth: true
            text: row.label
        }
        CommandButton {
            objectName: "step-" + row.param + "-less"
            compact: true
            connection: page.connection
            kind: Command.ImageCameraStep
            args: ({param: row.param, delta: -1})
            text: "−"
            Accessible.name: qsTr("Decrease %1").arg(row.label)
        }
        CommandButton {
            objectName: "step-" + row.param + "-more"
            compact: true
            connection: page.connection
            kind: Command.ImageCameraStep
            args: ({param: row.param, delta: 1})
            text: "+"
            Accessible.name: qsTr("Increase %1").arg(row.label)
        }
        DeviceSegments {
            objectName: "mode-" + row.param
            Layout.leftMargin: 8
            model: [qsTr("Manual"), qsTr("Auto")]
            setting: row.param + "Mode"
            reading: row.reading
        }
    }

    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("Camera")
        actions: [
            IdsComboBox {
                objectName: "combo-camera"
                compact: true
                Layout.preferredWidth: 170
                textRole: "text"
                valueRole: "value"
                model: [qsTr("CMOS sensor"), qsTr("Thermal sensor")].map((text, value) => ({text, value}))
                selectedValue: page.sample.camera.valid ? page.sample.camera.value : -1
                displayText: currentIndex < 0 ? qsTr("Select...") : currentText
                enabled: page.connection.commandsAvailable && !page.settingPending
                Accessible.name: qsTr("Camera")
                onActivated: page.sendSetting("camera", currentIndex)
            }
        ]

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            CardLabel {
                Layout.preferredWidth: 72
                text: qsTr("Zoom")
            }
            IdsSlider {
                id: zoomSlider
                objectName: "slider-zoom"
                Layout.fillWidth: true
                implicitWidth: 60
                from: 1
                to: 10
                stepSize: 0.1
                enabled: page.connection.commandsAvailable && !page.settingPending
                Accessible.name: qsTr("Zoom")
                onPressedChanged: if (!pressed) page.sendSetting("zoom", value)
                onMoved: if (!pressed) page.sendSetting("zoom", value)
                Binding on value { value: page.sample.zoom.valid ? page.sample.zoom.value : 1; when: !zoomSlider.pressed && !page.settingPending }
            }
            Text {
                objectName: "value-zoom"
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                text: page.sample.zoom.valid ? "x" + NumberFormat.fixed(page.sample.zoom.value, 1) : "—"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsBody
                color: Theme.text
            }
        }
        RowLayout {
            Layout.fillWidth: true
            CardLabel {
                Layout.fillWidth: true
                text: qsTr("Focus mode")
            }
            DeviceSegments {
                objectName: "focusMode"
                model: [qsTr("Auto"), qsTr("Manual")]
                setting: "focusMode"
                reading: page.sample.focusMode
            }
        }
        FormField {
            Layout.fillWidth: true
            label: qsTr("Focus distance, m")
            RowLayout {
                spacing: 8
                DistanceField {
                    id: focusField
                    objectName: "input-focusDistance"
                    reading: page.sample.focusDistanceM
                    Accessible.name: qsTr("Focus distance, m")
                    onAccepted: setFocus.clicked()
                }
                CommandButton {
                    objectName: "command-focusInfinity"
                    compact: true
                    connection: page.connection
                    kind: Command.ImageSetFocus
                    text: qsTr("INF")
                    Accessible.name: qsTr("Focus at infinity")
                    // "Infinity" is read as the INF button: focus at infinity (docs/kararlar.md T18).
                    perform: () => {
                        focusField.error = false
                        focusField.edited = false
                        return page.connection.send(Command.ImageSetFocus, {distance: Infinity})
                    }
                }
                CommandButton {
                    id: setFocus
                    objectName: "command-setFocus"
                    compact: true
                    connection: page.connection
                    kind: Command.ImageSetFocus
                    text: qsTr("Set")
                    perform: () => page.sendDistance(focusField, d => page.connection.send(Command.ImageSetFocus, {distance: d}))
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            DeviceToggle {
                objectName: "toggle-overlay"
                text: qsTr("Stream overlay info")
                reading: page.sample.overlay
                setting: "overlay"
            }
            DeviceToggle {
                objectName: "toggle-skyUp"
                text: qsTr("Sky up")
                reading: page.sample.skyUp
                setting: "skyUp"
            }
        }
    }

    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("Camera offset")

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            CardLabel {
                Layout.preferredWidth: 84
                text: qsTr("Image scale")
            }
            IdsSlider {
                id: scaleSlider
                objectName: "slider-imageScale"
                Layout.fillWidth: true
                implicitWidth: 60
                from: page.scaleFrom
                to: page.scaleTo
                stepSize: 0.1
                enabled: page.connection.commandsAvailable
                Accessible.name: qsTr("Image scale")
                onMoved: {
                    page.offsetEdited = true
                    page.imageScale = value
                }
                Binding on value { value: page.imageScale; when: !scaleSlider.pressed }
            }
            Text {
                objectName: "value-imageScale"
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                text: "x" + NumberFormat.fixed(page.imageScale, 1)
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsBody
                color: Theme.text
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            OffsetStepper { axis: "offsetX"; label: qsTr("Offset X") }
            OffsetStepper { axis: "offsetY"; label: qsTr("Offset Y") }
        }
        FormField {
            Layout.fillWidth: true
            label: qsTr("FOV gain")
            RowLayout {
                spacing: 8
                DistanceField {
                    id: fovField
                    objectName: "input-fovGain"
                    reading: page.sample.fovGain
                    Accessible.name: qsTr("FOV gain")
                    onAccepted: selectFov.clicked()
                }
                CommandButton {
                    id: selectFov
                    objectName: "command-selectFovGain"
                    compact: true
                    connection: page.connection
                    kind: Command.ImageSetStreamSetting
                    // "Select" is read as choosing the distance the gain applies to (docs/kararlar.md T18).
                    text: qsTr("Select")
                    perform: () => page.sendDistance(fovField, d => page.sendSetting("fovGain", d))
                }
            }
        }
        CommandButton {
            objectName: "command-writeOffset"
            Layout.fillWidth: true
            connection: page.connection
            kind: Command.ImageWriteOffset
            variant: "primary"
            text: qsTr("Write offset")
            perform: () => page.writeOffset()
        }
    }

    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("CMOS camera")

        DeviceToggle {
            objectName: "toggle-stabilization"
            text: qsTr("Sony camera stabilization")
            reading: page.sample.stabilization
            setting: "stabilization"
        }
        CameraControl { param: "gain"; label: qsTr("Gain"); reading: page.sample.gainMode }
        CameraControl { param: "iris"; label: qsTr("Iris"); reading: page.sample.irisMode }
        CameraControl { param: "shutter"; label: qsTr("Shutter"); reading: page.sample.shutterMode }
    }
    Item { Layout.fillHeight: true }
}
