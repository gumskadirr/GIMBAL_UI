pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Heater page of the final design (3D card | heater settings, 1:2).
// Enable and duty cycles are the "heater." parameters of viewModel.parameters; edits wait there until Set
// heater settings. Without command support (real target) values show "—", bars stay empty and every input
// and command is disabled through viewModel.connection.commandsAvailable. The design shows no measured
// value apart from the setting, so the bars show the setting (docs/kararlar.md, T9).
// Zone names (G1, G2, G3, TV, IR) are the same in the design and in the existing application.
ControlPageFrame {
    id: page

    readonly property ServiceConnection connection: viewModel.connection
    readonly property ParameterModel parameters: viewModel.parameters
    readonly property bool heaterEdited: parameters.modifiedKeys.some(key => key.startsWith("heater."))
    property bool readDone: false

    // The heater parameters are read once per connection, when the page is visible.
    function readOnce() {
        if (pageActive && connection.commandsAvailable && !readDone)
            readDone = parameters.read("heater.")
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

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        enabled: page.viewModel.connection.commandsAvailable // every input and command at once (Adım 10)

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            SectionHeading {
                title: qsTr("Heater")
                subtitle: qsTr("Keep optics and electronics above their minimum temperature")
            }
            Item { Layout.fillWidth: true } // buttons on the right, as in the design
            CommandButton {
                objectName: "command-read"
                connection: page.connection
                kind: Command.ReadParameters
                variant: "quiet"
                text: qsTr("Read")
                perform: () => page.parameters.read("heater.")
            }
            CommandButton {
                objectName: "command-setHeater"
                connection: page.connection
                kind: Command.WriteParameters
                variant: "primary"
                text: qsTr("Set heater settings")
                ready: page.heaterEdited
                perform: () => page.parameters.write("heater.")
            }
        }

        Card {
            Layout.fillWidth: true
            compact: true
            title: qsTr("Heater zones")
            subtitle: qsTr("Duty cycle of each zone")
            actions: ToggleRow {
                objectName: "input-enableHeaters"
                text: qsTr("Enable heaters")
                onToggled: page.parameters.set("heater.enabled", switchItem.checked)
                Binding on checked { value: !!page.parameters.values["heater.enabled"] }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 5
                columnSpacing: 12

                Repeater {
                    model: ["G1", "G2", "G3", "TV", "IR"]

                    Zone {
                        id: heaterZone
                        required property string modelData
                        objectName: "zone-" + modelData
                        readonly property string key: "heater." + modelData.toLowerCase() + "DutyPct"
                        readonly property var stored: page.parameters.values[key]
                        readonly property string valueText: stored === undefined ? "—" : NumberFormat.fixed(stored, 0) + "%"
                        property string shown // what show() put in the field; differs while the user is typing

                        function show() {
                            shown = stored === undefined ? "" : NumberFormat.fixed(stored, 0)
                            dutyField.text = shown
                            dutyField.error = false
                        }
                        // Enter or focus loss: a value the model refuses (not a number, outside 0-100) is never sent.
                        function commit() {
                            if (dutyField.text === shown)
                                return
                            const value = NumberFormat.parse(dutyField.text)
                            if (isNaN(value) || !page.parameters.set(key, Math.round(value)))
                                dutyField.error = true
                            else
                                show()
                        }
                        onStoredChanged: if (dutyField.text === shown) show()
                        Component.onCompleted: show()
                        Connections {
                            target: NumberFormat
                            function onLanguageChanged() { heaterZone.show() }
                        }
                        Layout.fillWidth: true
                        padding: 12
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: heaterZone.modelData
                                font.family: Theme.fontSans
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                color: Theme.text
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: heaterZone.valueText
                                font.family: Theme.fontMono
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                color: Theme.text
                            }
                        }
                        IdsProgressBar { Layout.fillWidth: true; barHeight: 10; from: 0; to: 100; value: heaterZone.stored ?? 0 }
                        IdsSlider {
                            Layout.fillWidth: true
                            implicitWidth: 60
                            from: 0
                            to: 100
                            stepSize: 1
                            Accessible.name: qsTr("%1 duty cycle").arg(heaterZone.modelData)
                            onMoved: page.parameters.set(heaterZone.key, value)
                            Binding on value { value: heaterZone.stored ?? 0 }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Duty cycle, %")
                                wrapMode: Text.WordWrap // narrow zones on 1080p at 125 %: wrap, never cut
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fsSmall
                                color: Theme.muted
                            }
                            IdsTextField {
                                id: dutyField
                                objectName: "input-duty-" + heaterZone.modelData
                                Layout.preferredWidth: 64
                                compact: true
                                placeholderText: "—"
                                onEditingFinished: heaterZone.commit()
                                Accessible.name: qsTr("%1 duty cycle value").arg(heaterZone.modelData)
                            }
                        }
                    }
                }
            }
            Hint {
                Layout.fillWidth: true
                text: qsTr("Changes apply when you press Set heater settings. Total heater power is limited by the board.")
            }
        }
    }
    Item { Layout.fillHeight: true }
}
