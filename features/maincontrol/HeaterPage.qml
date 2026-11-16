pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Heater page of the final design (3D card | heater settings, 1:2).
// Display only: duty cycles and commands need the device protocol (architecture §7), so values show "—",
// bars stay empty and every input and command is disabled through viewModel.commandsAvailable.
// Zone names (G1, G2, G3, TV, IR) are the same in the design and in the existing application.
ControlPageFrame {
    id: page

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        enabled: page.viewModel.commandsAvailable // every input and command at once (Adım 10)

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            SectionHeading {
                title: qsTr("Heater")
                subtitle: qsTr("Keep optics and electronics above their minimum temperature")
            }
            Item { Layout.fillWidth: true } // buttons on the right, as in the design
            IdsButton { objectName: "command-read"; variant: "quiet"; text: qsTr("Read") }
            IdsButton { objectName: "command-setHeater"; variant: "primary"; text: qsTr("Set heater settings") }
        }

        Card {
            Layout.fillWidth: true
            compact: true
            title: qsTr("Heater zones")
            subtitle: qsTr("Duty cycle of each zone")
            actions: ToggleRow { objectName: "input-enableHeaters"; text: qsTr("Enable heaters") }

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
                        readonly property string valueText: "—" // duty cycle comes from the device
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
                        IdsProgressBar { Layout.fillWidth: true; barHeight: 10; value: 0 }
                        IdsSlider {
                            Layout.fillWidth: true
                            implicitWidth: 60
                            from: 0
                            to: 100
                            Accessible.name: qsTr("%1 duty cycle").arg(heaterZone.modelData)
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
                                objectName: "input-duty-" + heaterZone.modelData
                                Layout.preferredWidth: 64
                                compact: true
                                placeholderText: "—"
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
