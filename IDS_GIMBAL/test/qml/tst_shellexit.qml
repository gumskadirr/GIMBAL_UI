import QtQuick
import QtTest
import IDS_GIMBAL

// Exit guard of the real Main window: closing asks only when work would be lost (T23).
// Named after tst_gimbalsettings alphabetically: it leaves a script loaded, which that test expects to be absent.
TestCase {
    id: testCase
    name: "ExitGuard"
    when: windowShown

    function createMain() {
        const component = Qt.createComponent("IDS_GIMBAL", "Main")
        verify(component.status === Component.Ready, component.errorString())
        const main = createTemporaryObject(component, testCase, {
            settings: testSettings, localization: testLocalization, notifications: testNotifications,
            mainControl: testMainControl, imageViewModel: testImageViewModel, demoMode: false
        })
        verify(main)
        main.visible = true
        verify(main.visible)
        return main
    }

    function cleanup() {
        testMainControl.script.stop()
        testMainControl.recorder.stop()
        testMainControl.parameters.revertAll()
        testHelper.disconnectDevice()
        testHelper.setCommandsSupported(false)
    }

    function test_nothingToLoseCloses() {
        const main = createMain()
        main.close()
        verify(!main.visible)
        verify(!findChild(main, "exitDialog").opened)
    }

    function test_unsavedChangeAsksAndStays() {
        const main = createMain()
        testHelper.connectWithFullSample()
        testHelper.sendParameters({"pan.torqueKp": 0.85})
        verify(testMainControl.parameters.set("pan.torqueKp", 0.9))
        main.close()
        verify(main.visible)
        const dialog = findChild(main, "exitDialog")
        tryVerify(() => dialog.opened)
        verify(dialog.text.indexOf("1 unsaved parameter") >= 0)
        verify(dialog.text.indexOf("CSV") < 0)
        findChild(dialog, "confirm-cancel").clicked()
        tryVerify(() => !dialog.visible)
        verify(main.visible)
        verify(!main.exitConfirmed)
    }

    function test_confirmExitClosesWithoutAskingAgain() {
        const main = createMain()
        testHelper.connectWithFullSample()
        testHelper.sendParameters({"pan.torqueKp": 0.85})
        verify(testMainControl.parameters.set("pan.torqueKp", 0.9))
        main.close()
        const dialog = findChild(main, "exitDialog")
        tryVerify(() => dialog.opened)
        findChild(dialog, "confirm-accept").clicked()
        verify(main.exitConfirmed)
        tryVerify(() => !main.visible) // closed for real, not asked again
        tryVerify(() => !dialog.visible)
    }

    function test_listsEveryRunningJob() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        const main = createMain()
        verify(testMainControl.connection.send(Command.UpdateFirmware, {file: testHelper.makeFile("fw.bin", 1000)}))
        verify(testMainControl.script.file.load(testHelper.makeText("play.csv", "time_ms,pan_deg,tilt_deg\n0,1,1\n20,2,2\n40,3,3\n")))
        verify(testMainControl.script.start())
        verify(testMainControl.recorder.start(testHelper.makeText("rec.csv", "")))
        main.close()
        verify(main.visible)
        const text = findChild(main, "exitDialog").text
        verify(text.indexOf("firmware update") >= 0)
        verify(text.indexOf("script") >= 0)
        verify(text.indexOf("CSV recording") >= 0)
        verify(text.indexOf("unsaved") < 0)
    }

    // The link drops during a firmware update: the update ends Cancelled and lands in the notifications.
    function test_linkDropCancelsFirmwareUpdateWithNotification() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        testNotifications.clear()
        verify(testMainControl.connection.send(Command.UpdateFirmware, {file: testHelper.makeFile("fw.bin", 1000)}))
        testHelper.disconnectDevice()
        compare(testMainControl.connection.pendingCommands.length, 0)
        verify(testHelper.lastNotificationCode().indexOf("command.cancelled") >= 0, testHelper.lastNotificationCode())
    }
}
