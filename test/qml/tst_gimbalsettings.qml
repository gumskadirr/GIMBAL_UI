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
        for (const control of controls) {
            if (control.objectName === "command-scriptDetails") // opens the script window: loading a file needs no device
                continue
            verify(!control.enabled, control.objectName || control.text || String(control))
        }
        verify(findChild(page, "command-safeStop"))
    }

    // The script window loads a file without a device, plays it with one and keeps playing when the page goes.
    function test_scriptWindow() {
        const page = createTemporaryObject(pageComponent, testCase)
        const runner = testMainControl.script
        const details = findChild(page, "command-scriptDetails")
        verify(details.enabled)
        verify(!findChild(page, "command-startScript").enabled)
        verify(!findChild(page, "command-safeStop").enabled)
        compare(findChild(page, "value-scriptState").text, "No script loaded")
        details.clicked()
        const dialog = findChild(page, "scriptDialog")
        tryVerify(() => dialog.opened)
        verify(runner.file.load(testHelper.makeText("play.csv", "time_ms,pan_deg,tilt_deg
0,1.5,-2
20,2.5,-3
40,3.5,-4
")))
        compare(findChild(dialog, "value-scriptRows").text, "3")
        compare(findChild(dialog, "value-scriptDuration").text, "0.06")
        compare(findChild(page, "value-scriptFile").text, "play.csv")
        compare(findChild(page, "value-scriptState").text, "Ready")
        verify(!findChild(dialog, "command-startScriptDialog").enabled) // no command support
        verify(!runner.file.load(testHelper.makeText("bad.csv", "pan,tilt
1,x
"))) // rejected, the script stays
        compare(runner.rowCount, 3)

        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        const start = findChild(dialog, "command-startScriptDialog")
        tryVerify(() => start.enabled)
        findChild(dialog, "input-scriptSampleMs").text = "5"
        findChild(dialog, "input-scriptSampleMs").editingFinished()
        compare(runner.sampleMs, 5)
        start.clicked()
        verify(runner.running)
        for (let i = 0; i < 100 && runner.running; ++i) { // the fake answers when told; the player waits for it
            wait(5)
            testHelper.answerLastCommand(Command.Accepted)
        }
        compare(runner.state, ScriptRunner.Done)
        compare(findChild(page, "value-scriptCommand").text, "Pan 3.500 · Tilt -4.000")
        testHelper.setCommandsSupported(false)
        dialog.close()
    }

    // The stream row keeps Safe stop inside the card while recording, in the longest language.
    function test_streamRowFitsWhileRecording() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        testLocalization.setLanguage("tr")
        const page = createTemporaryObject(pageComponent, testCase, { width: 1472 })
        verify(testMainControl.recorder.start(testHelper.makeFile("fit.csv", 0)))
        for (let i = 0; i < 12345; i += 1000)
            testHelper.sendSample()
        const stop = findChild(page, "command-safeStop")
        const right = stop.mapToItem(page, stop.width, 0).x
        testMainControl.recorder.stop()
        testLocalization.setLanguage("en")
        testHelper.setCommandsSupported(false)
        verify(right <= page.width - 12, "Safe stop right edge " + right)
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
        TestUtils.confirm(testCase, findChild(page, "command-crosstalk"))
        compare(testHelper.lastCommandKind(), Command.StartCrosstalkCheck)
        testHelper.reportProgress(40, "")
        verify(findChild(page, "command-crosstalk").pending)
        testHelper.sendCrosstalk(true, 0.4)
        testHelper.answerLastCommand(Command.Accepted)
        compare(findChild(page, "value-crosstalk").text, "Passed, 0.4%")
        TestUtils.confirm(testCase, findChild(page, "command-imuBias"))
        compare(testHelper.lastCommandKind(), Command.StartImuBiasCalibration)
        testHelper.sendImuBias(0.012, -0.004, 0.021)
        testHelper.answerLastCommand(Command.Accepted)
        compare(findChild(page, "value-gyroY").text, "-0.004")
        TestUtils.confirm(testCase, findChild(page, "command-electricalAngle"))
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

    // Step + / Step - are keys of the visible page; the answer fills the measurement row.
    function test_stepKeysAndMetrics() {
        const page = openWithDevice()
        compare(findChild(page, "value-rise").text, "—")
        page.forceActiveFocus()
        keyClick(Qt.Key_Plus)
        compare(testHelper.lastCommandKind(), Command.StepResponse)
        compare(testHelper.lastCommandArgs().direction, 1)
        testHelper.answerLastCommand(Command.Accepted)
        testHelper.sendStepMetrics()
        compare(findChild(page, "value-rise").text, "18 ms")
        compare(findChild(page, "value-overshoot").text, "20.5%")
        compare(findChild(page, "value-settling").text, "92 ms")
        compare(findChild(page, "value-ssError").text, "0.02 deg/s")
        compare(findChild(page, "value-latency").text, "3 ms")
        keyClick(Qt.Key_Minus)
        compare(testHelper.lastCommandArgs().direction, -1)
        testHelper.answerLastCommand(Command.Accepted)
        page.pageActive = false // hidden page: the keys do nothing
        const sent = testHelper.sentCount()
        keyClick(Qt.Key_Plus)
        compare(testHelper.sentCount(), sent)
        testHelper.disconnectDevice()
        compare(findChild(page, "value-rise").text, "—")
    }

    // The history keeps filling while the page is hidden; the chart redraws only while it is visible.
    function test_chartRedrawsOnlyWhileVisible() {
        const page = openWithDevice()
        page.pageActive = false
        const chart = findChild(page, "chart-inline")
        wait(100) // a redraw queued before the page was hidden
        const before = chart.version
        const size = testMainControl.scope.size()
        for (let i = 0; i < 5; ++i)
            testHelper.sendSample()
        wait(150)
        compare(chart.version, before)
        compare(testMainControl.scope.size(), size + 5)
        page.pageActive = true
        tryVerify(() => chart.version > before)
        verify(chart.hasData)
        compare(chart.linePaths.length, 4)
        verify(chart.linePaths[0].length >= 1 && chart.linePaths[0][0].length >= 2)
        page.pageActive = false
        const hiddenAt = chart.version
        wait(150)
        compare(chart.version, hiddenAt)
    }

    function test_viewListAndTabs() {
        const page = openWithDevice()
        const chart = findChild(page, "chart-inline")
        compare(chart.series.length, 4)
        compare(chart.series[1].name, "panRateRef")
        verify(chart.series[1].dashed && !chart.series[0].dashed)
        findChild(page, "scope-view").activated(2)
        compare(chart.series.length, 2)
        compare(chart.yMax, 10)
        findChild(page, "scope-view").activated(1)
        compare(chart.yMax, 180)
        findChild(page, "scope-tabs").activated(1)
        compare(page.tab, 1)
        compare(findChild(page, "value-scopeNoData").text, "No data")
        verify(!chart.active)
    }

    // The pop-out window draws from the same buffer while it is visible, also when the page is hidden.
    function test_popOutDrawsWhilePageHidden() {
        const page = openWithDevice()
        page.pageActive = false
        findChild(page, "command-popOut").clicked()
        const window = findChild(page, "scope-window")
        verify(window.visible)
        const chart = findChild(window.contentItem, "chart-popout")
        verify(chart)
        testHelper.sendSample()
        tryVerify(() => chart.hasData)
        const before = chart.version
        tryVerify(() => chart.version > before)
        window.visible = false
        testCase.Window.window.requestActivate() // the keyboard goes back to the test window
        verify(!findChild(window.contentItem, "chart-popout"))
    }
}
