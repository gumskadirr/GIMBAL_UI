import QtQuick
import QtTest
import IDS_GIMBAL

// Gimbal info summary strip against the real DeviceViewModel (data from tst_qml.cpp's fake provider).
TestCase {
    id: testCase
    name: "GimbalInfo"
    when: windowShown
    width: 1200
    height: 300

    Component {
        id: pageComponent
        GimbalInfoPage {
            width: testCase.width
            height: testCase.height
            viewModel: testDeviceViewModel
        }
    }

    function cell(page, id) {
        return findChild(page, "cell-" + id)
    }

    function cleanup() {
        testHelper.disconnectDevice()
    }

    function test_showsSampleValues() {
        const page = createTemporaryObject(pageComponent, testCase)
        testHelper.connectWithFullSample()
        compare(cell(page, "safeControl").value, "Locked")
        compare(cell(page, "safeControl").valueStatus, "warn")
        compare(cell(page, "temperature").value, "41.2 °C")
        compare(cell(page, "temperature").secondary, "IMU 38.6 °C")
        compare(cell(page, "supply").value, "24.1 V")
        compare(cell(page, "pan").value, "124.496°")
        compare(cell(page, "pan").secondary, "2.1729 rad")
        compare(cell(page, "pan").note, "REF 124.500° · 2.1729 rad")
        compare(cell(page, "tilt").value, "-8.204°")
        compare(cell(page, "tilt").secondary, "-0.1432 rad")
        compare(cell(page, "tilt").note, "REF -8.200° · -0.1431 rad")
    }

    // No command may reach the device before the protocol is integrated (architecture §7).
    function test_commandsDisabledWithoutProtocol() {
        const page = createTemporaryObject(pageComponent, testCase)
        testHelper.connectWithFullSample()
        for (const id of ["askBootloader", "exitBootloader", "startBootBridge", "openFirmware",
                          "updateFirmware", "runBit"]) {
            const button = findChild(page, "command-" + id)
            verify(button, id)
            verify(!button.enabled, id)
        }
    }

    // No data is never shown as a value (architecture §7).
    function test_disconnectShowsNoValues() {
        const page = createTemporaryObject(pageComponent, testCase)
        testHelper.connectWithFullSample()
        testHelper.disconnectDevice()
        for (const id of ["safeControl", "temperature", "supply", "pan", "tilt"])
            compare(cell(page, id).value, "—", id)
        compare(cell(page, "temperature").secondary, "")
        compare(cell(page, "pan").secondary, "")
        compare(cell(page, "pan").note, "")
        compare(cell(page, "safeControl").valueStatus, "")
    }
}
