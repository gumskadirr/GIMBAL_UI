import QtQuick
import QtTest
import IDS_GIMBAL
import "TestUtils.js" as TestUtils

// Gimbal settings page against the real MainControlViewModel (data from tst_qml.cpp's fake provider).
TestCase {
    id: testCase
    name: "GimbalSettings"
    when: windowShown
    width: 1400
    height: 900

    Component {
        id: pageComponent
        GimbalSettingsPage {
            width: testCase.width
            height: testCase.height
            viewModel: testMainControl
        }
    }

    function cleanup() {
        testHelper.disconnectDevice()
    }

    // No stream, script, calibration or gain may reach the device before the protocol (architecture §7);
    // Safe stop included: it is a command as well.
    function test_inputsAndCommandsDisabledWithoutProtocol() {
        const page = createTemporaryObject(pageComponent, testCase)
        testHelper.connectWithFullSample()
        const controls = TestUtils.interactiveControls(page)
        verify(controls.length >= 20)
        for (const control of controls)
            verify(!control.enabled, control.objectName || control.text || String(control))
        verify(findChild(page, "command-safeStop"))
    }

    // Values that need the protocol are never invented.
    function test_noInventedValues() {
        const page = createTemporaryObject(pageComponent, testCase)
        compare(findChild(page, "value-packets").text, "— packets")
        compare(findChild(page, "value-scriptFile").text, "—")
        compare(findChild(page, "value-rawPosition").value, "—")
        compare(findChild(page, "value-crosstalk").text, "Not checked")
        compare(findChild(page, "value-scopeEmpty").text, "No stream data")
    }
}
