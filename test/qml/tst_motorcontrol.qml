import QtQuick
import QtTest
import IDS_GIMBAL

// Motor control page against the real DeviceViewModel (data from tst_qml.cpp's fake provider).
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
            viewModel: testDeviceViewModel
        }
    }

    function cleanup() {
        testHelper.disconnectDevice()
    }

    // No parameter or command may reach the device before the protocol is integrated (architecture §7).
    function test_inputsAndCommandsDisabledWithoutProtocol() {
        const page = createTemporaryObject(pageComponent, testCase)
        testHelper.connectWithFullSample()
        for (const id of ["command-read", "command-write", "command-saveToFlash", "command-defaults",
                          "command-toggleLatch", "command-startControl", "command-stopControl",
                          "command-set", "command-reset", "input-torqueKp"]) {
            const item = findChild(page, id)
            verify(item, id)
            verify(!item.enabled, id)
        }
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
}
