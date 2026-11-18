import QtQuick
import QtTest
import IDS_GIMBAL
import "TestUtils.js" as TestUtils

// Gimbal info summary strip against the real MainControlViewModel (data from tst_qml.cpp's fake provider).
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
            viewModel: testMainControl
        }
    }

    function cell(page, id) {
        return findChild(page, "cell-" + id)
    }

    function cleanup() {
        testHelper.disconnectDevice()
        NumberFormat.language = "en"
    }

    // The command contract (device/api/DeviceCommand.h) is reachable from QML.
    function test_commandEnumsInQml() {
        compare(Command.RunBit, 3)
        compare(Command.Cancelled, 3)
        verify(!testMainControl.connection.commandsAvailable) // the test provider has no commands
    }

    // Decimal separator follows the UI language (user decision 2026-11-17).
    function test_turkishDecimalComma() {
        const page = createTemporaryObject(pageComponent, testCase)
        NumberFormat.language = "tr"
        testHelper.connectWithFullSample()
        compare(cell(page, "pan").value, "124,496°")
        compare(cell(page, "pan").secondary, "2,1729 rad")
        compare(cell(page, "tilt").value, "-8,204°")
        compare(cell(page, "temperature").value, "41,2 °C")
        compare(cell(page, "supply").value, "24,1 V")
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
        const controls = TestUtils.interactiveControls(page)
        verify(controls.length >= 7) // 6 command buttons + boot bridge target list
        for (const control of controls)
            verify(!control.enabled, control.objectName || control.text || String(control))
    }

    // Read-once board data is shown and cleared with the session; "On time" is telemetry and stays "—".
    function test_boardInfoShownForTheSession() {
        const page = createTemporaryObject(pageComponent, testCase)
        compare(findChild(page, "kpi-deviceId").value, "—")
        testHelper.connectWithFullSample()
        compare(findChild(page, "kpi-deviceId").value, "0x1A42")
        compare(findChild(page, "kpi-firmware").value, "v2.4.1")
        compare(findChild(page, "kpi-model").value, "MCB-2")
        compare(findChild(page, "mcu-deviceId").value, "0x0451")
        compare(findChild(page, "mcu-uid").value, "3A00 2F14 5133 3532")
        compare(findChild(page, "mcu-boardId").value, "0x07")
        testHelper.disconnectDevice()
        compare(findChild(page, "kpi-deviceId").value, "—")
        compare(findChild(page, "mcu-uid").value, "—")
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
