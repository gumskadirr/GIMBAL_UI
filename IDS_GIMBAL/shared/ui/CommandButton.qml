import QtQuick
import IDS_GIMBAL

// Button that sends a device command (Command.Kind). Disabled without command support; while its command is
// pending it keeps its text, shows a turning arrow and cannot be pressed again. Failed results become
// notifications elsewhere (AppRunner).
//   CommandButton { connection: vm.connection; kind: Command.RunBit; text: qsTr("Run BIT") }
// perform: builds and sends the command itself (e.g. `perform: () => parameters.write()`); the busy and enabled
// rules stay the same, `kind` is still the command it waits for.
// ready: extra condition of the page (e.g. a file is chosen).
// confirmTitle / confirmText / confirmWarning / confirmDanger: when confirmText is set, a click opens a modal
// ConfirmDialog first and only "Confirm" sends. It does not send if the command became unavailable meanwhile.
IdsButton {
    id: control

    required property ServiceConnection connection
    property int kind: 0
    property var args: ({})
    property bool ready: true
    property var perform: null
    readonly property bool pending: connection.pendingCommands.includes(kind)

    enabled: connection.commandsAvailable && !pending && ready
    busy: pending
    property string confirmTitle: ""
    property string confirmText: ""
    property string confirmWarning: ""
    property bool confirmDanger: false

    function run() { return perform ? perform() : connection.send(kind, args) }

    onClicked: confirmText !== "" ? confirmDialog.open() : run()
    onEnabledChanged: if (!enabled) confirmDialog.close()

    ConfirmDialog {
        id: confirmDialog
        objectName: "confirmDialog"
        title: control.confirmTitle
        text: control.confirmText
        warning: control.confirmWarning
        danger: control.confirmDanger
        onConfirmed: if (control.enabled) control.run()
    }
}
