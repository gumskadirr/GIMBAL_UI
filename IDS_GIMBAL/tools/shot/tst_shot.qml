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
        testHelper.setImageCommandsSupported(true)
        testHelper.connectImageWithSample() // values of the View & control design
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
        // The first frame can take over a second (telemetry stale): send again; Errors with `dialog` shows a failed item.
        testHelper.sendImageErrors(page === "errors" && dialog ? "MACB_LRF" : "")
        if (page === "gimbalState") // stream started, values on screen
            testHelper.sendImageGimbalState(true, 0)
        if (dialog === "confirm") // the confirmation of Save to flash
            findChild(main.contentItem, "command-saveToFlash").clicked()
        if (dialog === "exit") // the exit guard (the edited parameters of the page are unsaved)
            main.close()
        if (dialog === "gimbal") { // the gimbal selection: G180 v2.0 saved, G160 v2.0 being chosen
            const gimbalDialog = findChild(main, "gimbalDialog")
            findChild(main.contentItem, "gimbalButton").clicked()
            tryCompare(gimbalDialog, "opened", true)
            findChild(gimbalDialog.contentItem, "version-g160-v2.0").clicked()
        }
        if (dialog === "gimbalEdit") { // the editor of ZR10 over the selection window
            const gimbalDialog = findChild(main, "gimbalDialog")
            findChild(main.contentItem, "gimbalButton").clicked()
            tryCompare(gimbalDialog, "opened", true)
            findChild(gimbalDialog.contentItem, "gimbalEdit-zr10").clicked()
            const edit = findChild(gimbalDialog.contentItem, "gimbalEditDialog")
            tryCompare(edit, "opened", true)
            wait(500) // the preview loads its files
        }
        if (dialog === "connections" || dialog === "offline") // IDS Image down: the chip says 1/2 and the panel lists both
            testImageViewModel.connection.disconnectDevice()
        if (dialog === "offline") // nothing connected: the red chip
            testMainControl.connection.disconnectDevice()
        if (dialog === "connections") {
            const panel = findChild(main, "connectionsPanel")
            findChild(main.contentItem, "connectionStatus").clicked()
            tryCompare(panel, "opened", true)
        }
        mouseMove(main.contentItem, main.width / 2, main.height / 2) // off the nav rail: hover expands it
        wait(100)
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

    // Run with QT_QPA_PLATFORM=windows: the offscreen platform renders in software, without Qt Quick 3D.
    function test_gimbal3dShots() {
        testSettings.gimbal = "zr10"
        testSettings.gimbalVersion = "v1.0"
        shot(1536, 786, "gimbal3d-1536-dark-en.png", "dark", "en", "gimbalInfo")
        shot(1536, 786, "gimbal3d-1536-light-tr.png", "light", "tr", "motorControl")
        shot(1536, 786, "gimbal3d-select-1536-dark-en.png", "dark", "en", "gimbalInfo", "gimbal")
        shot(1536, 786, "gimbal3d-edit-1536-dark-en.png", "dark", "en", "gimbalInfo", "gimbalEdit")
        shot(1536, 786, "gimbal3d-edit-1536-light-tr.png", "light", "tr", "gimbalInfo", "gimbalEdit")
        testSettings.gimbal = "g180"
        testSettings.gimbalVersion = "v2.0"
        testLocalization.setLanguage("en")
        testSettings.theme = "dark"
    }

    function test_gimbalShots() {
        shot(1536, 786, "gimbal-1536-dark-en.png", "dark", "en", "gimbalInfo", "gimbal")
        shot(1536, 786, "gimbal-1536-light-tr.png", "light", "tr", "gimbalInfo", "gimbal")
        shot(1536, 786, "viewControl-1536-dark-en.png", "dark", "en", "viewControl")
        shot(1536, 786, "connections-1536-dark-en.png", "dark", "en", "gimbalInfo", "connections")
        shot(1536, 786, "connections-1536-light-tr.png", "light", "tr", "gimbalInfo", "connections")
        shot(1536, 786, "offline-1536-dark-tr.png", "dark", "tr", "gimbalInfo", "offline")
        testLocalization.setLanguage("en")
        testSettings.theme = "dark"
        testHelper.setCommandsSupported(false)
        testHelper.setImageCommandsSupported(false)
    }

    function test_shots() {
        // 1536x786: the target screen (1080p at 125 %) minus the taskbar.
        shot(1536, 786, "gimbalInfo-1536-dark-en.png", "dark", "en", "gimbalInfo", undefined, true)
        shot(1536, 786, "gimbalInfo-1536-light-tr.png", "light", "tr", "gimbalInfo", undefined, true)
        shot(1536, 786, "motorControl-1536-dark-en.png", "dark", "en", "motorControl")
        shot(1536, 786, "motorControl-1536-light-tr.png", "light", "tr", "motorControl")
        shot(1536, 786, "confirm-1536-dark-en.png", "dark", "en", "motorControl", "confirm")
        shot(1536, 786, "confirm-1536-light-tr.png", "light", "tr", "motorControl", "confirm")
        shot(1536, 786, "exit-1536-dark-en.png", "dark", "en", "motorControl", "exit")
        shot(1536, 786, "exit-1536-light-tr.png", "light", "tr", "motorControl", "exit")
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
        shot(1536, 786, "viewControl-1536-dark-en.png", "dark", "en", "viewControl")
        shot(1536, 786, "viewControl-1536-light-tr.png", "light", "tr", "viewControl")
        shot(1536, 786, "alignment-1536-dark-en.png", "dark", "en", "alignment")
        shot(1536, 786, "alignment-1536-light-tr.png", "light", "tr", "alignment")
        shot(1536, 786, "errors-1536-dark-en.png", "dark", "en", "errors")
        shot(1536, 786, "errors-1536-light-tr.png", "light", "tr", "errors")
        shot(1536, 786, "errorsFail-1536-dark-en.png", "dark", "en", "errors", true)
        shot(1536, 786, "gimbalState-1536-dark-en.png", "dark", "en", "gimbalState")
        shot(1536, 786, "gimbalState-1536-light-tr.png", "light", "tr", "gimbalState")
        testLocalization.setLanguage("en")
        testSettings.theme = "dark"
        testHelper.setCommandsSupported(false)
        testHelper.setImageCommandsSupported(false)
    }
}
