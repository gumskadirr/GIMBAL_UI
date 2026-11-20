import QtQuick
import QtTest
import IDS_GIMBAL
import "TestUtils.js" as TestUtils

// Motor control page against the real MainControlViewModel (data from tst_qml.cpp's fake provider).
TestCase {
    id: testCase
    name: "MotorControl"
    when: windowShown
    width: 1400
    height: 800

    Component {
        id: pageComponent
        MotorControlPage {
            width: testCase.width
            height: testCase.height
            viewModel: testMainControl
        }
    }

    function cleanup() {
        testHelper.disconnectDevice()
        testHelper.setCommandsSupported(false)
        NumberFormat.language = "en"
        testMainControl.parameters.revertAll()
    }

    // Demo-like device: commands supported, parameters sent, the page visible (so it reads once).
    function openWithDevice() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        compare(testHelper.lastCommandKind(), Command.ReadParameters)
        testHelper.answerLastCommand(Command.Accepted)
        testHelper.sendParameters({"pan.torqueKp": 0.85, "pan.positionOffsetDeg": 0, "tilt.torqueKp": 2.5})
        return page
    }

    // No parameter or command may reach the device before the protocol is integrated (architecture §7).
    function test_inputsAndCommandsDisabledWithoutProtocol() {
        const page = createTemporaryObject(pageComponent, testCase)
        testHelper.connectWithFullSample()
        const controls = TestUtils.interactiveControls(page)
        verify(controls.length >= 30) // buttons, gain/offset fields, lists, switches, segments
        for (const control of controls)
            verify(!control.enabled, control.objectName || control.text || String(control))
    }

    // The latch line shows the real safe-control state; no data is never shown as a state.
    function test_latchStatusFollowsSafeControl() {
        const page = createTemporaryObject(pageComponent, testCase)
        const latch = findChild(page, "latchStatus")
        compare(latch.text, "State unknown")
        testHelper.connectWithFullSample() // makeFullSample(): safe control locked
        compare(latch.text, "Locked · toggle latch to send")
        compare(latch.status, "warn")
        testHelper.disconnectDevice()
        compare(latch.text, "State unknown")
    }

    function test_editWriteClearsCounter() {
        const page = openWithDevice()
        const field = findChild(page, "input-torqueKp")
        const badge = findChild(page, "unsavedBadge")
        const write = findChild(page, "command-write")
        compare(field.text, "0.8500")
        verify(!write.enabled) // nothing edited
        verify(!badge.visible)
        field.text = "1.5"
        field.commit()
        compare(testMainControl.parameters.unsavedCount, 1)
        compare(badge.text, "1 unsaved changes")
        verify(write.enabled)
        write.clicked()
        compare(testHelper.lastCommandKind(), Command.WriteParameters)
        compare(testHelper.lastCommandArgs().values["pan.torqueKp"], 1.5)
        testHelper.answerLastCommand(Command.Accepted)
        compare(testMainControl.parameters.unsavedCount, 0)
        verify(!badge.visible)
    }

    function test_invalidInputIsNotSet() {
        const page = openWithDevice()
        const field = findChild(page, "input-torqueKp")
        for (const bad of ["abc", "20000", "1,5", ""]) {
            field.text = bad
            field.commit()
            verify(field.error, bad)
            compare(testMainControl.parameters.unsavedCount, 0)
        }
        field.text = "2"
        field.commit()
        verify(!field.error)
        compare(testMainControl.parameters.unsavedCount, 1)
    }

    function test_turkishComma() {
        const page = openWithDevice()
        const field = findChild(page, "input-torqueKp")
        NumberFormat.language = "tr"
        compare(field.text, "0,8500")
        field.text = "1,5"
        field.commit()
        compare(testMainControl.parameters.values["pan.torqueKp"], 1.5)
        compare(field.text, "1,5000")
        field.text = "1.5"
        field.commit()
        verify(field.error)
    }

    function test_motorSelectChangesKeys() {
        const page = openWithDevice()
        const field = findChild(page, "input-torqueKp")
        const sent = testHelper.sentCount()
        findChild(page, "motorSelect").children[0].children[1].clicked() // Tilt segment
        compare(page.motor, "tilt")
        compare(field.text, "2.5000")
        compare(testHelper.sentCount(), sent) // the choice is not sent
    }

    function test_keyboardControlNudgesReference() {
        const page = openWithDevice()
        const sent = testHelper.sentCount()
        page.nudge(1)
        compare(testHelper.sentCount(), sent) // keyboard control is off
        findChild(page, "input-keyboardControl").checked = true
        page.nudge(1)
        compare(testHelper.lastCommandKind(), Command.SetReference)
        compare(testHelper.lastCommandArgs().type, "position")
        compare(testHelper.lastCommandArgs().value, 1)
        testHelper.answerLastCommand(Command.Accepted)
        page.nudge(-1)
        page.pageActive = false
        compare(testHelper.sentCount(), sent + 2)
        page.nudge(1) // hidden page: no key reaches it
        compare(testHelper.sentCount(), sent + 2)
    }
}
