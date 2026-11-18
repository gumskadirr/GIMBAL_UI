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

    // Without a device no value is invented (nor after the telemetry stopped).
    function test_noInventedValues() {
        const page = createTemporaryObject(pageComponent, testCase)
        compare(findChild(page, "value-packets").text, "— packets")
        compare(findChild(page, "value-scriptFile").text, "—")
        compare(findChild(page, "value-rawPosition").value, "—")
        compare(findChild(page, "value-crosstalk").text, "Not checked")
        compare(findChild(page, "value-boardMode").text, "Board mode —")
        verify(!findChild(page, "value-streamRate").visible)
        compare(findChild(page, "value-scopeEmpty").text, "No stream data")
    }

    // Demo-like device: commands supported, filter gains answered, the page visible.
    function openWithDevice() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        compare(testHelper.lastCommandKind(), Command.ReadParameters)
        compare(testHelper.lastCommandArgs().prefix, "gimbal.")
        testHelper.answerLastCommand(Command.Accepted)
        testHelper.sendParameters({"gimbal.filterKp": 1, "gimbal.filterKi": 0.01})
        return page
    }

    function test_telemetryShown() {
        const page = openWithDevice()
        compare(findChild(page, "value-packets").text, "12480 packets")
        compare(findChild(page, "value-streamRate").text, "2 kHz") // from the device, not a constant
        compare(findChild(page, "value-rawPosition").value, "18432")
        compare(findChild(page, "value-boardMode").text, "Board mode Speed")
        compare(findChild(page, "input-filterKp").text, "1.0000")
        compare(findChild(page, "input-filterKi").text, "0.0100")
        verify(findChild(page, "command-stopStream").enabled) // streaming: Start is off, Stop is on
        verify(!findChild(page, "command-startStream").enabled)
    }

    function cleanup() {
        testHelper.disconnectDevice()
        testHelper.setCommandsSupported(false)
        testMainControl.parameters.revertAll()
    }

    function test_calibrationsSendCommandsAndShowResults() {
        const page = openWithDevice()
        compare(findChild(page, "value-crosstalk").text, "Not checked")
        findChild(page, "command-crosstalk").clicked()
        compare(testHelper.lastCommandKind(), Command.StartCrosstalkCheck)
        testHelper.reportProgress(40, "")
        verify(findChild(page, "command-crosstalk").pending)
        testHelper.sendCrosstalk(true, 0.4)
        testHelper.answerLastCommand(Command.Accepted)
        compare(findChild(page, "value-crosstalk").text, "Passed, 0.4%")
        findChild(page, "command-imuBias").clicked()
        compare(testHelper.lastCommandKind(), Command.StartImuBiasCalibration)
        testHelper.sendImuBias(0.012, -0.004, 0.021)
        testHelper.answerLastCommand(Command.Accepted)
        compare(findChild(page, "value-gyroY").text, "-0.004")
        findChild(page, "command-electricalAngle").clicked()
        compare(testHelper.lastCommandKind(), Command.StartElectricalAngleCalibration)
        testHelper.disconnectDevice() // the results end with the session
        compare(findChild(page, "value-crosstalk").text, "Not checked")
        compare(findChild(page, "value-gyroY").text, "")
    }

    function test_filterGainEnterWritesGimbalParameters() {
        const page = openWithDevice()
        const field = findChild(page, "input-filterKp")
        field.forceActiveFocus()
        field.text = "abc"
        field.editingFinished()
        verify(field.error)
        field.text = "2.5"
        field.editingFinished()
        verify(!field.error)
        compare(testHelper.lastCommandKind(), Command.WriteParameters)
        compare(testHelper.lastCommandArgs().values["gimbal.filterKp"], 2.5)
        field.text = "20000" // outside the range: never sent
        const sent = testHelper.sentCount()
        field.editingFinished()
        verify(field.error)
        compare(testHelper.sentCount(), sent)
    }

    function test_safeStopAndEscape() {
        const page = openWithDevice()
        page.forceActiveFocus()
        keyClick(Qt.Key_Escape)
        compare(testHelper.lastCommandKind(), Command.SafeStop)
        testHelper.answerLastCommand(Command.Accepted)
        page.pageActive = false // hidden page: Esc does nothing
        const sent = testHelper.sentCount()
        keyClick(Qt.Key_Escape)
        compare(testHelper.sentCount(), sent)
    }
}
