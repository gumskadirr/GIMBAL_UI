import QtQuick
import QtTest
import IDS_GIMBAL

// Integration test of the real Main window with real services (see tst_qml.cpp).
TestCase {
    id: testCase
    name: "Shell"
    when: windowShown

    function createMain(demoMode) {
        const component = Qt.createComponent("IDS_GIMBAL", "Main")
        verify(component.status === Component.Ready, component.errorString())
        const main = createTemporaryObject(component, testCase, {
            settings: testSettings,
            localization: testLocalization,
            notifications: testNotifications,
            deviceViewModel: testDeviceViewModel,
            demoMode: demoMode
        })
        verify(main)
        return main
    }

    function pageItem(main, id) {
        const loader = findChild(main.contentItem, "page-" + id)
        return loader ? loader.item : null
    }

    function cleanup() {
        testLocalization.setLanguage("en")
        testNotifications.clear()
        testSettings.theme = "dark"
    }

    // Option 2 (plan adim-08): Gimbal info keeps the reference layout and shrinks uniformly to fit a maximized
    // window; small pages are not scaled.
    function test_referencePageScalesToFit_data() {
        return [
            { tag: "1080p@125%", w: 1536, h: 786 },
            { tag: "1080p@100%", w: 1920, h: 1050 },
            { tag: "1080p@150%", w: 1280, h: 690 },
            { tag: "1366x768@100%", w: 1366, h: 698 }
        ]
    }

    function test_referencePageScalesToFit(data) {
        const main = createMain(true)
        main.visibility = Window.Windowed
        main.width = data.w
        main.height = data.h
        const referencePages = main.pages.filter(page => page.designHeight)
        verify(referencePages.length >= 2)
        for (const page of referencePages) {
            main.currentPageId = page.id
            const loader = findChild(main.contentItem, "page-" + page.id)
            tryVerify(() => loader.item !== null)
            // Layouts update on the next frame after a resize; without waiting the old geometry is measured.
            waitForRendering(main.contentItem)
            const slot = loader.parent
            const area = slot.mapToItem(main.contentItem, 0, 0)
            verify(slot.width > main.width / 2 && area.y + slot.height < main.height,
                   page.id + ": slot " + slot.width + "x" + slot.height + " not laid out for window " + main.width + "x" + main.height)
            verify(loader.scale <= 1, page.id)
            compare(loader.height * loader.scale, loader.parent.height, page.id) // whole page in the area
            // the frame's own scroller is not needed: the content fits designHeight
            const scroller = findChild(loader.item, "pageScroller")
            verify(scroller.contentHeight <= scroller.height + 0.5,
                   page.id + " needs " + scroller.contentHeight + ", has " + scroller.height)
        }
        compare(findChild(main.contentItem, "page-preferences").scale, 1)
    }

    function test_demoOnlyPageHiddenInRealTarget() {
        const real = createMain(false)
        compare(real.pages.map(page => page.id), ["gimbalInfo", "motorControl", "heater", "preferences"])
        compare(findChild(real.contentItem, "nav-diagnostics"), null)
        compare(real.activePageId, "gimbalInfo")

        const demo = createMain(true)
        compare(demo.pages.map(page => page.id), ["gimbalInfo", "motorControl", "heater", "diagnostics", "preferences"])
        verify(findChild(demo.contentItem, "nav-diagnostics"))
    }

    function test_switchingKeepsPagesAndStopsInactiveWork() {
        const main = createMain(true)
        const diagnostics = pageItem(main, "diagnostics")
        const preferences = pageItem(main, "preferences")
        verify(diagnostics && preferences)
        verify(!diagnostics.pageActive) // Gimbal info is the start page

        mouseClick(findChild(main.contentItem, "nav-diagnostics"), 20, 20)
        verify(diagnostics.pageActive)
        mouseClick(findChild(main.contentItem, "nav-preferences"), 20, 20)
        compare(main.activePageId, "preferences")
        verify(!diagnostics.pageActive)

        mouseClick(findChild(main.contentItem, "nav-diagnostics"), 20, 20)
        compare(main.activePageId, "diagnostics")
        compare(pageItem(main, "diagnostics"), diagnostics)
        compare(pageItem(main, "preferences"), preferences)
        verify(diagnostics.pageActive)
    }

    // A mouse click must not keep the rail open: it would cover the page that was just selected.
    function test_railClosesAfterMouseSelection() {
        const main = createMain(false)
        const navItem = findChild(main.contentItem, "nav-preferences")
        const rail = navItem.rail
        mouseMove(navItem, 100, 20)
        tryCompare(rail, "expanded", true)
        wait(300) // expand animation (160 ms); the user clicks the fully opened rail
        mouseClick(navItem, 100, 20)
        compare(main.activePageId, "preferences")
        mouseMove(main.contentItem, 900, 400)
        tryCompare(rail, "expanded", false)
    }

    // Keyboard users still get the expanded rail while focus is inside it.
    function test_railStaysOpenForKeyboardFocus() {
        const main = createMain(false)
        const navItem = findChild(main.contentItem, "nav-preferences")
        mouseMove(main.contentItem, 900, 400)
        navItem.forceActiveFocus(Qt.TabFocusReason)
        tryCompare(navItem.rail, "expanded", true)
    }

    function test_languageChangeKeepsPagesAndUpdatesTitles() {
        const main = createMain(true)
        main.currentPageId = "preferences"
        const preferences = pageItem(main, "preferences")
        const navItem = findChild(main.contentItem, "nav-preferences")
        const connection = findChild(main.contentItem, "connectionStatus")
        compare(navItem.text, "Preferences")
        compare(connection.text, "Disconnected")

        verify(testLocalization.setLanguage("tr"))
        compare(NumberFormat.language, "tr") // numbers follow the language too
        compare(navItem.text, "Tercihler")
        compare(connection.text, "Bağlantı yok") // live C++ state, not only qsTr bindings
        compare(main.pages[main.currentIndex].title, "Tercihler")
        compare(pageItem(main, "preferences"), preferences)
        compare(findChild(main.contentItem, "nav-preferences"), navItem)
        compare(main.activePageId, "preferences")
    }

    function test_notificationInStatusBarAndPopup() {
        const main = createMain(false)
        const latest = findChild(main.contentItem, "latestNotification")
        compare(latest.count, 0)
        testHelper.addNotification("device.error", "link lost")
        tryCompare(latest, "count", 1)

        const button = findChild(main.contentItem, "notificationsButton")
        tryCompare(button, "text", "Notifications (1)")
        mouseClick(button)
        const popup = findChild(button, "notificationsPopup")
        tryCompare(popup, "opened", true)
        for (const mode of ["light", "blue", "dark"]) {
            testSettings.theme = mode
            verify(Qt.colorEqual(popup.background.color, Theme.card), mode)
        }
        popup.close()
        tryCompare(popup, "visible", false)
    }
}
