import QtQuick
import QtTest
import IDS_GIMBAL
import "TestUtils.js" as TestUtils

// Heater page against the real DeviceViewModel (data from tst_qml.cpp's fake provider).
TestCase {
    id: testCase
    name: "Heater"
    when: windowShown
    width: 1400
    height: 800

    Component {
        id: pageComponent
        HeaterPage {
            width: testCase.width
            height: testCase.height
            viewModel: testDeviceViewModel
        }
    }

    function cleanup() {
        testHelper.disconnectDevice()
    }

    readonly property list<string> zones: ["G1", "G2", "G3", "TV", "IR"]

    // No heater setting may reach the device before the protocol is integrated (architecture §7).
    function test_inputsAndCommandsDisabledWithoutProtocol() {
        const page = createTemporaryObject(pageComponent, testCase)
        testHelper.connectWithFullSample()
        const controls = TestUtils.interactiveControls(page)
        verify(controls.length >= 13) // 2 buttons, enable switch, 5 sliders, 5 duty fields
        for (const control of controls)
            verify(!control.enabled, control.objectName || control.text || String(control))
        for (const zone of testCase.zones)
            verify(findChild(page, "zone-" + zone), zone)
    }
}
