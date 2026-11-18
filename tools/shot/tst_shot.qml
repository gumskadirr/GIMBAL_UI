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
            notifications: testNotifications, deviceViewModel: testDeviceViewModel, demoMode: false })
        main.visibility = Window.Windowed
        main.width = w
        main.height = h
        main.currentPageId = page
        testHelper.connectWithFullSample()
        wait(400)
        waitForRendering(main.contentItem)
        verify(testHelper.saveWindowImage(main, "build/shots/" + file))
    }

    function test_shots() {
        // 1536x786: the target screen (1080p at 125 %) minus the taskbar.
        shot(1536, 786, "gimbalSettings-1536-dark-en.png", "dark", "en", "gimbalSettings")
        shot(1536, 786, "gimbalSettings-1536-light-tr.png", "light", "tr", "gimbalSettings")
        testLocalization.setLanguage("en")
        testSettings.theme = "dark"
    }
}
