import QtQuick
import QtTest
import IDS_GIMBAL
import "TestUtils.js" as TestUtils

// CommandButton with a confirmation (ConfirmDialog): only Confirm sends, once, with the arguments.
TestCase {
    id: testCase
    name: "Confirm"
    when: windowShown
    width: 400
    height: 300

    Component {
        id: askComponent
        CommandButton {
            connection: testMainControl.connection
            kind: Command.RunBit
            args: ({mode: 3})
            text: "Ask"
            confirmTitle: "Title"
            confirmText: "What happens"
            confirmWarning: "Cannot be undone"
        }
    }
    Component {
        id: plainComponent
        CommandButton { connection: testMainControl.connection; kind: Command.RunBit; text: "Plain" }
    }

    function cleanup() {
        testHelper.disconnectDevice()
        testHelper.setCommandsSupported(false)
    }

    function openWithDevice() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        const button = createTemporaryObject(askComponent, testCase)
        return [button, findChild(button, "confirmDialog"), testHelper.sentCount()]
    }

    function test_clickOpensDialogAndDoesNotSend() {
        const [button, dialog, sent] = openWithDevice()
        button.clicked()
        tryVerify(() => dialog.opened)
        compare(testHelper.sentCount(), sent)
        compare(dialog.title, "Title")
        verify(findChild(dialog, "confirm-cancel").activeFocus)
    }

    function test_cancelDoesNotSend() {
        const [button, dialog, sent] = openWithDevice()
        button.clicked()
        tryVerify(() => dialog.opened)
        findChild(dialog, "confirm-cancel").clicked()
        tryVerify(() => !dialog.visible)
        compare(testHelper.sentCount(), sent)
    }

    function test_confirmSendsOnceWithArgs() {
        const [button, dialog, sent] = openWithDevice()
        TestUtils.confirm(testCase, button)
        compare(testHelper.sentCount(), sent + 1)
        compare(testHelper.lastCommandKind(), Command.RunBit)
        compare(testHelper.lastCommandArgs().mode, 3)
        tryVerify(() => !dialog.visible)
    }

    function test_withoutCommandsConfirmDoesNotSend() {
        const [button, dialog, sent] = openWithDevice()
        button.clicked()
        tryVerify(() => dialog.opened)
        testHelper.setCommandsSupported(false)
        testHelper.disconnectDevice() // the command became unavailable while the dialog was open
        verify(!button.enabled)
        findChild(dialog, "confirm-accept").clicked()
        compare(testHelper.sentCount(), sent)
        tryVerify(() => !dialog.visible)
    }

    // Safe stop and the other buttons have no confirmText: the click sends at once.
    function test_buttonWithoutConfirmSendsDirectly() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        const button = createTemporaryObject(plainComponent, testCase)
        const sent = testHelper.sentCount()
        button.clicked()
        compare(testHelper.sentCount(), sent + 1)
    }
}
