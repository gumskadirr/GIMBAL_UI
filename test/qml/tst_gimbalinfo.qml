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
        testHelper.setCommandsSupported(false)
        NumberFormat.language = "en"
    }

    function connectWithCommands() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
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

    // Read-once board data is shown and cleared with the session.
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

    // On time is telemetry; firmware build and the BIT report arrive with the session and leave with it.
    function test_onTimeAndBitReport() {
        const page = createTemporaryObject(pageComponent, testCase)
        compare(findChild(page, "kpi-onTime").value, "—")
        compare(findChild(page, "bit-Pan motor"), null)
        testHelper.connectWithFullSample()
        compare(findChild(page, "kpi-onTime").value, "3 h 12 min")
        compare(findChild(page, "kpi-onTime").caption, "11520 s since power on")
        compare(findChild(page, "kpi-firmware").caption, "Built 2026-10-28")
        compare(findChild(page, "bootloader-state").text, "Application running")
        verify(findChild(page, "bit-Pan motor"))
        compare(page.bitPassed, 7)
        compare(page.bitWarnings, 1)
        testHelper.disconnectDevice()
        compare(findChild(page, "kpi-onTime").value, "—")
        compare(findChild(page, "bootloader-state").text, "State unknown")
        compare(findChild(page, "bit-Pan motor"), null)
    }

    // A command button sends its kind, looks busy while pending and is free again after the answer.
    function test_runBitSendsAndShowsBusy() {
        const page = createTemporaryObject(pageComponent, testCase)
        connectWithCommands()
        const button = findChild(page, "command-runBit")
        verify(button.enabled)
        verify(!button.busy)
        const before = testHelper.sentCount()
        button.clicked()
        compare(testHelper.sentCount(), before + 1)
        compare(testHelper.lastCommandKind(), Command.RunBit)
        verify(button.busy)
        verify(!button.enabled)
        button.clicked() // pending: nothing more is sent
        compare(testHelper.sentCount(), before + 1)
        testHelper.answerLastCommand(Command.Accepted)
        verify(!button.busy)
        verify(button.enabled)
    }

    // Firmware update: needs a file, shows the file box and the progress, ends with the answer.
    function test_firmwareUpdateProgress() {
        const page = createTemporaryObject(pageComponent, testCase)
        connectWithCommands()
        const update = findChild(page, "command-updateFirmware")
        const cancel = findChild(page, "command-cancelFirmware")
        verify(!update.enabled) // no file yet
        verify(!cancel.enabled)
        const url = testHelper.makeFile("mcb_firmware_v2.5.0.bin", 1258291)
        findChild(page, "firmwareFile").source = url
        compare(findChild(page, "firmware-name").text, "mcb_firmware_v2.5.0.bin")
        verify(findChild(page, "firmware-detail").text.startsWith("1.2 MB · "))
        verify(update.enabled)
        TestUtils.confirm(testCase, update)
        compare(testHelper.lastCommandKind(), Command.UpdateFirmware)
        verify(String(testHelper.lastCommandArgs().file).endsWith("mcb_firmware_v2.5.0.bin"))
        testHelper.reportProgress(40, "Writing")
        compare(testMainControl.connection.progressKind, Command.UpdateFirmware)
        compare(findChild(page, "firmware-progress").value, 40)
        compare(findChild(page, "firmware-status").text, "Writing")
        verify(cancel.enabled)
        testHelper.answerLastCommand(Command.Accepted)
        compare(testMainControl.connection.progressKind, -1)
        compare(findChild(page, "firmware-status").text, "Update complete")
        compare(findChild(page, "firmware-progress").value, 100)
    }
}
