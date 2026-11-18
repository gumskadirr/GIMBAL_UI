import QtQuick
import QtTest
import IDS_GIMBAL
import "TestUtils.js" as TestUtils

// Heater page against the real MainControlViewModel (data from tst_qml.cpp's fake provider).
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
            viewModel: testMainControl
        }
    }

    function cleanup() {
        testHelper.disconnectDevice()
        testHelper.setCommandsSupported(false)
        testMainControl.parameters.revertAll()
    }

    // Demo-like device: commands supported, the heater values of the design sent, the page visible.
    function openWithDevice() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        const page = createTemporaryObject(pageComponent, testCase, {pageActive: true})
        compare(testHelper.lastCommandKind(), Command.ReadParameters)
        compare(testHelper.lastCommandArgs().prefix, "heater.")
        testHelper.answerLastCommand(Command.Accepted)
        testHelper.sendParameters({"heater.enabled": true, "heater.g1DutyPct": 35, "heater.g2DutyPct": 35,
                                   "heater.g3DutyPct": 20, "heater.tvDutyPct": 60, "heater.irDutyPct": 45})
        return page
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

    function test_dutyCyclesShown() {
        const page = openWithDevice()
        compare(findChild(page, "input-duty-TV").text, "60")
        compare(findChild(page, "zone-TV").valueText, "60%")
        compare(findChild(page, "zone-G3").valueText, "20%")
        verify(findChild(page, "input-enableHeaters").checked)
    }

    function test_setSendsOnlyHeaterKeys() {
        const page = openWithDevice()
        const set = findChild(page, "command-setHeater")
        verify(!set.enabled) // nothing edited
        testMainControl.parameters.set("pan.torqueKp", 2)
        verify(!set.enabled) // a motor edit does not count
        const field = findChild(page, "input-duty-G1")
        field.text = "50"
        field.editingFinished()
        compare(findChild(page, "zone-G1").valueText, "50%")
        verify(set.enabled)
        set.clicked()
        compare(testHelper.lastCommandKind(), Command.WriteParameters)
        compare(testHelper.lastCommandArgs().values, {"heater.g1DutyPct": 50})
    }

    function test_invalidDutyIsNotSent() {
        const page = openWithDevice()
        const field = findChild(page, "input-duty-IR")
        field.text = "150"
        field.editingFinished()
        verify(field.error)
        verify(!findChild(page, "command-setHeater").enabled)
    }
}
