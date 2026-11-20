pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Gimbal state page of the final design: the device's state flags and values. The lists, the raw flag word and
// whether the stream runs are device telemetry (viewModel.sample); names are device text. Start / Stop and the
// rate (1, 5, 10 Hz) go in one command; without command support (real target) they are disabled and the lists
// show no values.
ImagePageFrame {
    id: page

    readonly property ServiceConnection connection: viewModel.connection
    readonly property var rates: [1, 5, 10]
    readonly property bool streaming: sample.stateStreaming.valid && sample.stateStreaming.value
    // Rebuilt only when the lists change, not with every sample, so the rows stay.
    readonly property string flagsKey: JSON.stringify(sample.stateValid ? sample.stateFlags : [])
    readonly property var flags: JSON.parse(flagsKey)
    readonly property string valuesKey: JSON.stringify(sample.stateValid ? sample.stateValues : [])
    readonly property var values: JSON.parse(valuesKey)

    // Up to 3 decimals, none for a whole number (the design shows 0).
    function shown(value: real): string {
        return NumberFormat.fixed(value, 3).replace(/[.,]?0+$/, "")
    }

    component Overline: Text {
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.overlineSpacing
        font.capitalization: Font.AllUppercase
        color: Theme.label
    }

    Card {
        Layout.fillWidth: true
        Layout.fillHeight: true
        compact: true
        title: qsTr("Gimbal state")
        actions: [
            IdsComboBox {
                id: rateBox
                objectName: "combo-rate"
                compact: true
                currentIndex: 1
                model: page.rates.map(rate => rate + " Hz")
                enabled: page.connection.commandsAvailable
                Accessible.name: qsTr("Rate")
                // Running: the new rate goes to the device at once.
                onActivated: if (page.streaming) page.connection.send(Command.ImageGimbalState, {running: true, rateHz: page.rates[currentIndex]})
            },
            CommandButton {
                objectName: "command-gimbalState"
                compact: true
                connection: page.connection
                kind: Command.ImageGimbalState
                variant: "primary"
                iconPath: page.streaming ? "" : Icons.play
                text: page.streaming ? qsTr("Stop") : qsTr("Start")
                perform: () => connection.send(kind, {running: !page.streaming, rateHz: page.rates[rateBox.currentIndex]})
            }
        ]

        RowLayout {
            Layout.fillWidth: true
            Overline {
                Layout.fillWidth: true
                text: qsTr("Flags")
            }
            Text {
                objectName: "flagsRaw"
                text: page.sample.stateValid ? "0x" + page.sample.stateFlagsRaw.toString(16) : "—"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSmall
                color: Theme.text
            }
        }
        Repeater {
            model: page.flags
            Rectangle {
                id: flagRow
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 30
                radius: Theme.rSmall
                color: Theme.card
                border.width: 1
                border.color: Theme.line
                Accessible.role: Accessible.StaticText
                Accessible.name: modelData.name + ": " + flagBadge.text

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        text: flagRow.modelData.name
                        elide: Text.ElideRight
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSmall
                        color: Theme.text
                    }
                    Badge {
                        id: flagBadge
                        objectName: "flag-" + flagRow.modelData.name
                        kind: flagRow.modelData.value ? "ok" : "neutral"
                        text: flagRow.modelData.value ? qsTr("TRUE") : qsTr("FALSE")
                    }
                }
            }
        }
        Text {
            visible: page.flags.length === 0
            text: "—"
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsBody
            color: Theme.muted
        }

        Overline {
            Layout.topMargin: 6
            text: qsTr("Values")
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 0
            columnSpacing: 24
            Repeater {
                model: page.values
                Item {
                    id: cell
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1 // equal columns
                    implicitHeight: 28
                    Accessible.role: Accessible.StaticText
                    Accessible.name: modelData.name + ": " + valueText.text

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: cell.modelData.name
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSmall
                        color: Theme.muted
                    }
                    Text {
                        id: valueText
                        objectName: "value-" + cell.modelData.name
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.shown(cell.modelData.value)
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fsSmall
                        color: Theme.text
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Theme.line
                    }
                }
            }
        }
        Text {
            visible: page.values.length === 0
            text: "—"
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsBody
            color: Theme.muted
        }
    }
}
