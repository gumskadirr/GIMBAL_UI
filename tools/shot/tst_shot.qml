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
        wait(50) // telemetry turns stale after 1 s
        waitForRendering(main.contentItem)
        verify(testHelper.saveWindowImage(main, "build/shots/" + file))
    }

    function test_shots() {
        // 1536x786: the target screen (1080p at 125 %) minus the taskbar.
        shot(1536, 786, "gimbalInfo-1536-dark-en.png", "dark", "en", "gimbalInfo")
        shot(1536, 786, "gimbalInfo-1536-light-tr.png", "light", "tr", "gimbalInfo")
        testLocalization.setLanguage("en")
        testSettings.theme = "dark"
        testHelper.setCommandsSupported(false)
    }
}
