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

    function shot(w, h, file, theme, lang, page, dialog, realtime) {
        testSettings.theme = theme
        testLocalization.setLanguage(lang)
        const c = Qt.createComponent("IDS_GIMBAL", "Main")
        const main = createTemporaryObject(c, testCase, { settings: testSettings, localization: testLocalization,
            notifications: testNotifications, mainControl: testMainControl, imageViewModel: testImageViewModel, demoMode: false })
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
        if (page === "gimbalSettings") { // values of the design
            testHelper.sendParameters({"gimbal.filterKp": 1, "gimbal.filterKi": 0.01})
            testHelper.sendCrosstalk(true, 0.4)
            testHelper.sendImuBias(0.012, -0.004, 0.021)
            testMainControl.recorder.start(testHelper.makeFile("record.csv", 0)) // recording in progress
            testHelper.sendStepMetrics()
            for (let i = 0; i < 25; ++i) { // 2 s of scope history
                testHelper.sendScopeSample(i)
                wait(80)
            }
        }
        if (page === "gimbalSettings" && dialog !== undefined) { // 742 of 1200 rows played, as in the design
            let csv = "time_ms,pan_deg,tilt_deg
"
            for (let i = 0; i < 1200; ++i)
                csv += i * 10 + "," + (31.42 + i * 0.001).toFixed(3) + "," + (-4.81 - i * 0.001).toFixed(3) + "
"
            const script = testMainControl.script
            script.file.load(testHelper.makeText("scan_pattern_01.csv", csv))
            script.start()
            for (let i = 0; i < 2000 && script.row < 742; ++i) {
                wait(5)
                testHelper.answerLastCommand(Command.Accepted)
            }
            if (dialog)
                findChild(main.contentItem, "command-scriptDetails").clicked()
        }
        testHelper.sendTraffic(250, 11000) // ~0.09 Mbps over the 1 s window, as in the design
        wait(dialog ? 300 : 50) // telemetry turns stale after 1 s; the window fades in
        waitForRendering(main.contentItem)
        verify(testHelper.saveWindowImage(main, "build/shots/" + file))
        if (realtime) { // the Realtime graph and logger window, with scope history and a notification
            testHelper.addNotification("device.error.mainControl", "link lost")
            const win = findChild(main, "realtimeWindow")
            win.show()
            for (let i = 0; i < 25; ++i) {
                testHelper.sendScopeSample(i)
                wait(80)
            }
            waitForRendering(win.contentItem)
            verify(testHelper.saveWindowImage(win, "build/shots/" + file.replace(".png", "-realtime.png")))
            win.close()
            testNotifications.clear()
        }
    }

    function test_shots() {
        // 1536x786: the target screen (1080p at 125 %) minus the taskbar.
        shot(1536, 786, "gimbalInfo-1536-dark-en.png", "dark", "en", "gimbalInfo", undefined, true)
        shot(1536, 786, "gimbalInfo-1536-light-tr.png", "light", "tr", "gimbalInfo", undefined, true)
        shot(1536, 786, "motorControl-1536-dark-en.png", "dark", "en", "motorControl")
        shot(1536, 786, "motorControl-1536-light-tr.png", "light", "tr", "motorControl")
        shot(1536, 786, "heater-1536-dark-en.png", "dark", "en", "heater")
        shot(1536, 786, "heater-1536-light-tr.png", "light", "tr", "heater")
        shot(1536, 786, "gimbalSettings-1536-dark-en.png", "dark", "en", "gimbalSettings")
        shot(1536, 786, "gimbalSettings-1536-light-tr.png", "light", "tr", "gimbalSettings")
        shot(1536, 786, "script-1536-dark-en.png", "dark", "en", "gimbalSettings", true)
        testMainControl.script.stop()
        shot(1536, 786, "scriptRow-1536-light-tr.png", "light", "tr", "gimbalSettings", false)
        testMainControl.script.stop()
        shot(1536, 786, "script-1536-light-tr.png", "light", "tr", "gimbalSettings", true)
        testMainControl.script.stop()
        testLocalization.setLanguage("en")
        testSettings.theme = "dark"
        testHelper.setCommandsSupported(false)
    }
}
