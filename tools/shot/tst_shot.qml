import QtQuick
import QtTest
import IDS_GIMBAL

// Screenshots of the real Main window for comparing with the design (docs/gelistirme.md). Not a test: it lives
// outside test/qml so tst_qml does not run it by default. Edit test_shots() for the page under work.
// Run from the project root:
//   QT_QPA_PLATFORM=offscreen ./build/cli-debug/tst_qml.exe -input tools/shot/tst_shot.qml
// Images land in build/shots/ (ignored by git).
TestCase {
    id: testCase
    name: "Shot"
    when: windowShown

    function shot(w, h, file, theme, lang, page) {
        testSettings.theme = theme
        testLocalization.setLanguage(lang)
        const c = Qt.createComponent("IDS_GIMBAL", "Main")
        const main = createTemporaryObject(c, testCase, { settings: testSettings, localization: testLocalization,
            notifications: testNotifications, mainControl: testMainControl, demoMode: false })
        main.visibility = Window.Windowed
        main.width = w
        main.height = h
        main.currentPageId = page
        testHelper.setCommandsSupported(true) // buttons enabled, as with a device that has a protocol
        testHelper.connectWithFullSample()
        let item = findChild(main.contentItem, "firmware-name") // Gimbal info: the file of the design
        while (item && item.firmwareSource === undefined)
            item = item.parent
        if (item)
            item.firmwareSource = testHelper.makeFile("mcb_firmware_v2.5.0.bin", 1258291)
        if (page === "motorControl") { // values of the design, three of them edited
            testHelper.sendParameters({"pan.torqueKp": 0.85, "pan.torqueKi": 12, "pan.torqueKd": 0, "pan.speedKp": 0.42,
                "pan.speedKi": 3.5, "pan.speedKd": 0.001, "pan.positionKp": 6, "pan.positionKi": 0.2, "pan.positionKd": 0.05,
                "pan.trackerKp": 2.5, "pan.trackerKi": 0.08, "pan.trackerKd": 0.02, "pan.modelSerial": "MCB2-24-00142",
                "pan.positionOffsetDeg": 0, "pan.electricalOffsetDeg": 12.4, "pan.forwardBorderDeg": 170,
                "pan.backwardBorderDeg": -170, "pan.encoderReverse": false, "pan.phaseRotation": 0, "pan.slipRing": false})
            testMainControl.parameters.set("pan.torqueKp", 0.9)
            testMainControl.parameters.set("pan.speedKi", 3.6)
            testMainControl.parameters.set("pan.slipRing", true)
        }
        if (page === "heater") // values of the design
            testHelper.sendParameters({"heater.enabled": true, "heater.g1DutyPct": 35, "heater.g2DutyPct": 35,
                "heater.g3DutyPct": 20, "heater.tvDutyPct": 60, "heater.irDutyPct": 45})
        wait(50) // telemetry turns stale after 1 s
        waitForRendering(main.contentItem)
        verify(testHelper.saveWindowImage(main, "build/shots/" + file))
    }

    function test_shots() {
        // 1536x786: the target screen (1080p at 125 %) minus the taskbar.
        shot(1536, 786, "gimbalInfo-1536-dark-en.png", "dark", "en", "gimbalInfo")
        shot(1536, 786, "gimbalInfo-1536-light-tr.png", "light", "tr", "gimbalInfo")
        shot(1536, 786, "motorControl-1536-dark-en.png", "dark", "en", "motorControl")
        shot(1536, 786, "motorControl-1536-light-tr.png", "light", "tr", "motorControl")
        shot(1536, 786, "heater-1536-dark-en.png", "dark", "en", "heater")
        shot(1536, 786, "heater-1536-light-tr.png", "light", "tr", "heater")
        testLocalization.setLanguage("en")
        testSettings.theme = "dark"
        testHelper.setCommandsSupported(false)
    }
}
