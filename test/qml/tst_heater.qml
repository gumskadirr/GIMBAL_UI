import QtQuick
import QtTest
import IDS_GIMBAL

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
        const ids = ["command-read", "command-setHeater", "input-enableHeaters"]
        for (const zone of testCase.zones)
            ids.push("input-duty-" + zone)
        for (const id of ids) {
            const item = findChild(page, id)
            verify(item, id)
            verify(!item.enabled, id)
        }
    }

    // Duty cycles come from the device: without data no value is shown.
    function test_zonesShowNoValueWithoutData() {
        const page = createTemporaryObject(pageComponent, testCase)
        for (const zone of testCase.zones) {
            const item = findChild(page, "zone-" + zone)
            verify(item, zone)
            compare(item.valueText, "—", zone)
        }
    }
}
