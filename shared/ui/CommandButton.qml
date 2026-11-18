import QtQuick
import IDS_GIMBAL

// Button that sends a device command (Command.Kind). Disabled without command support; while its command is
// pending it keeps its text, shows a turning arrow and cannot be pressed again. Failed results become
// notifications elsewhere (AppRunner).
//   CommandButton { connection: vm.connection; kind: Command.RunBit; text: qsTr("Run BIT") }
// ready: extra condition of the page (e.g. a file is chosen).
IdsButton {
    id: control

    required property ServiceConnection connection
    property int kind: 0
    property var args: ({})
    property bool ready: true
    readonly property bool pending: connection.pendingCommands.includes(kind)

    enabled: connection.commandsAvailable && !pending && ready
    busy: pending
    onClicked: connection.send(kind, args)
}
