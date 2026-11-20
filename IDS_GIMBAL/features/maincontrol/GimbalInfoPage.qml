pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Dialogs
import IDS_GIMBAL

// Gimbal info page of the final design. Board identity, bootloader state, BIT report and every command come
// from the device layer; without command support (real target) values show "—" and the buttons stay disabled.
ControlPageFrame {
    id: page

    readonly property ServiceConnection connection: viewModel.connection
    readonly property bool updating: connection.progressKind === Command.UpdateFirmware
    property string updateResult: "" // "done" | "cancelled" | "failed": outcome of the last update, until the next starts
    property alias firmwareSource: firmwareFile.source // set by the screenshot tool
    property string bridgeBoard: "pan"
    // BitItem.Status (the enum of a QML value type is not reachable from QML)
    readonly property int pass: 0
    readonly property int warn: 1
    readonly property int fail: 2
    readonly property int bitPassed: bitCount(pass)
    readonly property int bitWarnings: bitCount(warn)
    readonly property int bitFailed: bitCount(fail)
    readonly property int updatePercent: updating ? connection.progressPercent : updateResult === "done" ? 100 : 0

    function text(t: textValue): string {
        return t.valid ? t.value : "—"
    }
    function bitCount(status: int): int {
        return viewModel.bitReport.items.filter(item => item.status === status).length
    }
    function onTimeText(m: measurement): string {
        if (!m.valid)
            return "—"
        const minutes = Math.floor(m.value / 60)
        return qsTr("%1 h %2 min").arg(Math.floor(minutes / 60)).arg(minutes % 60)
    }
    function sizeText(bytes: real): string {
        return bytes < 1048576 ? qsTr("%1 KB").arg(NumberFormat.fixed(bytes / 1024, 1))
                               : qsTr("%1 MB").arg(NumberFormat.fixed(bytes / 1048576, 1))
    }
    function bitTone(status: int): string {
        return status === pass ? "ok" : status === warn ? "warn" : "crit"
    }
    function bitLabel(status: int): string {
        return status === pass ? qsTr("Pass") : status === warn ? qsTr("Warning") : qsTr("Fail")
    }

    FileInfo { id: firmwareFile; objectName: "firmwareFile" }
    FileDialog {
        id: fileDialog
        title: qsTr("Open firmware file")
        nameFilters: [qsTr("Firmware files (*.bin *.hex)"), qsTr("All files (*)")]
        onAccepted: {
            firmwareFile.source = selectedFile
            page.updateResult = ""
        }
    }
    Connections {
        target: page.connection
        function onCommandFinished(kind: int, status: int, detail: string) {
            if (kind === Command.UpdateFirmware)
                page.updateResult = status === Command.Accepted ? "done" : status === Command.Cancelled ? "cancelled" : "failed"
        }
        function onProgressChanged() {
            if (page.updating)
                page.updateResult = ""
        }
    }

    SectionHeading {
        title: qsTr("Board info")
        subtitle: qsTr("Identity, firmware and bootloader of the target board")
    }
    Hint {
        Layout.fillWidth: true
        visible: !page.connection.commandsAvailable
        kind: "warning"
        text: qsTr("Board identity and commands become available once the device protocol is integrated.")
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 12
        KpiTile { objectName: "kpi-deviceId"; Layout.fillWidth: true; compact: true; label: qsTr("Device ID"); value: page.text(page.viewModel.boardInfo.deviceId); caption: qsTr("Target board") }
        KpiTile {
            objectName: "kpi-firmware"
            Layout.fillWidth: true
            compact: true
            label: qsTr("Firmware")
            value: page.text(page.viewModel.boardInfo.firmware)
            caption: page.viewModel.boardInfo.firmwareBuilt.valid ? qsTr("Built %1").arg(page.viewModel.boardInfo.firmwareBuilt.value) : ""
        }
        KpiTile { objectName: "kpi-model"; Layout.fillWidth: true; compact: true; label: qsTr("Model"); value: page.text(page.viewModel.boardInfo.model); caption: qsTr("Main control board") }
        KpiTile {
            objectName: "kpi-onTime"
            Layout.fillWidth: true
            compact: true
            label: qsTr("On time")
            value: page.onTimeText(page.viewModel.onTime)
            caption: page.viewModel.onTime.valid ? qsTr("%1 s since power on").arg(NumberFormat.fixed(page.viewModel.onTime.value, 0)) : ""
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 12

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            compact: true
            title: "MCU"
            subtitle: qsTr("Microcontroller details")
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                InfoRow { objectName: "mcu-deviceId"; Layout.fillWidth: true; compact: true; label: qsTr("Device ID"); value: page.text(page.viewModel.boardInfo.mcuDeviceId) }
                InfoRow { objectName: "mcu-uid"; Layout.fillWidth: true; compact: true; label: "UID"; value: page.text(page.viewModel.boardInfo.uid) }
                InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Flash size, KB"); value: page.text(page.viewModel.boardInfo.flashSizeKb) }
                InfoRow { Layout.fillWidth: true; compact: true; label: qsTr("Bootloader version"); value: page.text(page.viewModel.boardInfo.bootloaderVersion) }
                InfoRow { objectName: "mcu-boardId"; Layout.fillWidth: true; compact: true; label: qsTr("Board ID"); value: page.text(page.viewModel.boardInfo.boardId); showDivider: false }
            }
        }
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            compact: true
            title: qsTr("Bootloader")
            subtitle: qsTr("Enter or leave the bootloader")
            Zone {
                Layout.fillWidth: true
                padding: 8
                RowLayout {
                    Layout.fillWidth: true
                    StatusLabel {
                        objectName: "bootloader-state"
                        Layout.fillWidth: true
                        status: !page.viewModel.inBootloader.valid ? "idle" : page.viewModel.inBootloader.value ? "warn" : "ok"
                        text: !page.viewModel.inBootloader.valid ? qsTr("State unknown")
                            : page.viewModel.inBootloader.value ? qsTr("In bootloader") : qsTr("Application running")
                    }
                    Badge {
                        visible: page.viewModel.inBootloader.valid
                        kind: page.viewModel.inBootloader.value ? "warn" : "info"
                        text: page.viewModel.inBootloader.value ? qsTr("Bootloader") : qsTr("No bootloader")
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                CommandButton { objectName: "command-askBootloader"; Layout.fillWidth: true; connection: page.connection; kind: Command.AskBootloader; text: qsTr("Ask bootloader")
                    confirmTitle: qsTr("Ask bootloader"); confirmText: qsTr("The board will be asked to enter its bootloader."); confirmWarning: qsTr("Normal operation is interrupted until you exit the bootloader.") }
                CommandButton { objectName: "command-exitBootloader"; Layout.fillWidth: true; connection: page.connection; kind: Command.ExitBootloader; variant: "quiet"; text: qsTr("Exit bootloader") }
            }
            Hint {
                Layout.fillWidth: true
                text: qsTr("The board restarts into the bootloader. Motors are disabled until you exit it.")
            }
        }
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            compact: true
            title: qsTr("Boot bridge")
            subtitle: qsTr("Program a sub-board through this board")
            FormField {
                Layout.fillWidth: true
                label: qsTr("Target")
                IdsComboBox {
                    enabled: page.connection.commandsAvailable
                    textRole: "text"
                    valueRole: "value"
                    model: [{ text: qsTr("Pan motor driver"), value: "pan" }, { text: qsTr("Tilt motor driver"), value: "tilt" }]
                    selectedValue: page.bridgeBoard
                    onActivated: page.bridgeBoard = currentValue
                }
            }
            CommandButton { objectName: "command-startBootBridge"; Layout.fillWidth: true; connection: page.connection; kind: Command.StartBootBridge; args: ({ board: page.bridgeBoard }); text: qsTr("Start boot bridge")
                confirmTitle: qsTr("Start boot bridge"); confirmText: qsTr("A boot bridge will be started for the selected board."); confirmWarning: qsTr("Normal operation is interrupted while the bridge is open.") }
            Hint {
                Layout.fillWidth: true
                text: qsTr("Forwards the bootloader link to the selected sub-board.")
            }
        }
    }
    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("Firmware update")
        subtitle: qsTr("Current %1 · GUI version %2").arg(page.text(page.viewModel.boardInfo.firmware)).arg(Qt.application.version)
        Item {
            id: dropBox
            Layout.fillWidth: true
            implicitHeight: fileRow.implicitHeight + 24
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.line2
                    strokeWidth: 1
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [4, 3]
                    fillColor: "transparent"
                    PathRectangle { x: 0.5; y: 0.5; width: dropBox.width - 1; height: dropBox.height - 1; radius: Theme.rCard }
                }
            }
            RowLayout {
                id: fileRow
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                Icon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; path: Icons.file; color: Theme.muted }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        objectName: "firmware-name"
                        Layout.fillWidth: true
                        text: firmwareFile.exists ? firmwareFile.name : qsTr("No file selected")
                        elide: Text.ElideMiddle
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsBody
                        font.weight: Font.DemiBold
                        color: Theme.text
                    }
                    Text {
                        objectName: "firmware-detail"
                        Layout.fillWidth: true
                        visible: firmwareFile.exists
                        text: firmwareFile.exists ? page.sizeText(firmwareFile.size) + " · " + firmwareFile.folder : ""
                        elide: Text.ElideMiddle
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsSmall
                        color: Theme.muted
                    }
                }
                IdsButton {
                    objectName: "command-openFirmware"
                    compact: true
                    enabled: page.connection.commandsAvailable && !page.updating
                    text: qsTr("Open file")
                    onClicked: fileDialog.open()
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                objectName: "firmware-status"
                text: page.updating ? page.connection.progressStage
                    : page.updateResult === "done" ? qsTr("Update complete")
                    : page.updateResult === "cancelled" ? qsTr("Cancelled")
                    : page.updateResult === "failed" ? qsTr("Failed") : qsTr("Ready")
                font.family: Theme.fontSans
                font.pixelSize: Theme.fsSmall
                color: Theme.muted
            }
            IdsProgressBar {
                objectName: "firmware-progress"
                Layout.fillWidth: true
                Layout.preferredWidth: 420
                from: 0
                to: 100
                value: page.updatePercent
                Accessible.name: qsTr("Firmware update progress")
            }
            Text {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: page.updatePercent + "%"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fsSmall
                color: Theme.text2
            }
            Hint {
                Layout.fillWidth: true
                Layout.preferredWidth: 380
                kind: "warning"
                text: qsTr("Keep the board powered and connected until the update finishes.")
            }
            CommandButton {
                objectName: "command-cancelFirmware"
                connection: page.connection
                kind: Command.CancelFirmwareUpdate
                ready: page.updating
                text: qsTr("Cancel")
            }
            CommandButton {
                objectName: "command-updateFirmware"
                connection: page.connection
                kind: Command.UpdateFirmware
                args: ({ file: firmwareFile.path })
                ready: firmwareFile.exists
                variant: "primary"
                text: qsTr("Update firmware")
                confirmTitle: qsTr("Update firmware"); confirmDanger: true
                confirmText: qsTr("The firmware file will be written to the board.")
                confirmWarning: qsTr("This cannot be undone. Do not power off during the update.")
            }
        }
    }

    Card {
        Layout.fillWidth: true
        compact: true
        title: qsTr("Built-in test")
        subtitle: page.viewModel.bitReport.valid ? qsTr("Last run %1").arg(page.viewModel.bitReport.lastRun)
                                                 : qsTr("Results come from the BIT report of the board")
        actions: [
            Badge { Layout.alignment: Qt.AlignVCenter; visible: page.viewModel.bitReport.valid; kind: "ok"; text: qsTr("%1 passed").arg(page.bitPassed) },
            Badge { Layout.alignment: Qt.AlignVCenter; visible: page.bitWarnings > 0; kind: "warn"; text: qsTr("%1 warning").arg(page.bitWarnings) },
            Badge { Layout.alignment: Qt.AlignVCenter; visible: page.bitFailed > 0; kind: "crit"; text: qsTr("%1 failed").arg(page.bitFailed) },
            CommandButton {
                objectName: "command-runBit"
                compact: true
                connection: page.connection
                kind: Command.RunBit
                text: qsTr("Run BIT")
            }
        ]
        Zone {
            Layout.fillWidth: true
            visible: !page.viewModel.bitReport.valid
            padding: 8
            StatusLabel { status: "idle"; text: qsTr("No result") }
        }
        GridLayout {
            Layout.fillWidth: true
            visible: page.viewModel.bitReport.valid
            columns: 4
            columnSpacing: 10
            rowSpacing: 10
            Repeater {
                model: page.viewModel.bitReport.items
                delegate: Zone {
                    id: tile
                    required property var modelData
                    objectName: "bit-" + tile.modelData.name
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    padding: 10
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: tile.modelData.name
                            elide: Text.ElideRight
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fsBody
                            font.weight: Font.DemiBold
                            color: Theme.text
                        }
                        StatusLabel {
                            status: page.bitTone(tile.modelData.status)
                            text: page.bitLabel(tile.modelData.status)
                            fontSize: Theme.fsSmall
                            textColor: Theme.stateTextColor(status)
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: tile.modelData.description
                        elide: Text.ElideRight
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsSmall
                        color: Theme.muted
                    }
                }
            }
        }
    }
    Item { Layout.fillHeight: true }
}
