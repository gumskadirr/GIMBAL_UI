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
            mainControl: testMainControl, imageViewModel: testImageViewModel,
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
        testHelper.disconnectDevice()
        testHelper.disconnectImage()
        testHelper.restoreConnection()
        testHelper.restoreImageConnection()
        testLocalization.setLanguage("en")
        testNotifications.clear()
        testSettings.theme = "dark"
        testSettings.lastPage = ""
        compare(testSettings.lastPage, "")
    }

    // Every page keeps the reference layout and shrinks uniformly to fit a maximized window, all by the same
    // scale (19 Nov: a card must not change size between pages).
    function test_referencePageScalesToFit_data() {
        return [
            { tag: "1080p@125% en", w: 1536, h: 786, lang: "en" },
            { tag: "1080p@100% en", w: 1920, h: 1050, lang: "en" },
            { tag: "1080p@150% en", w: 1280, h: 690, lang: "en" },
            { tag: "1366x768@100% en", w: 1366, h: 698, lang: "en" },
            // Turkish labels are longer and wrap earlier (Motor control toolbar).
            { tag: "1080p@125% tr", w: 1536, h: 786, lang: "tr" },
            { tag: "1080p@100% tr", w: 1920, h: 1050, lang: "tr" },
            { tag: "1080p@150% tr", w: 1280, h: 690, lang: "tr" },
            { tag: "1366x768@100% tr", w: 1366, h: 698, lang: "tr" }
        ]
    }

    function test_referencePageScalesToFit(data) {
        verify(testLocalization.setLanguage(data.lang))
        const main = createMain(true)
        testHelper.connectWithFullSample() // the fullest content: Gimbal info shows the BIT tiles
        testHelper.connectImageWithSample()
        main.visibility = Window.Windowed
        main.width = data.w
        main.height = data.h
        let framePages = 0
        waitForRendering(main.contentItem) // the scale follows the new window height on the next frame
        const scale = findChild(main.contentItem, "page-" + main.pages[0].id).scale
        verify(scale <= 1)
        for (const page of main.pages) {
            main.currentPageId = page.id
            const loader = findChild(main.contentItem, "page-" + page.id)
            tryVerify(() => loader.item !== null)
            compare(loader.scale, scale, page.id + ": all pages share one scale")
            const scroller = findChild(loader.item, "pageScroller")
            if (!scroller)
                continue // not a ControlPageFrame page
            ++framePages
            // Layouts update on the next frame after a resize; without waiting the old geometry is measured.
            waitForRendering(main.contentItem)
            const slot = loader.parent
            const area = slot.mapToItem(main.contentItem, 0, 0)
            verify(slot.width > main.width / 2 && area.y + slot.height < main.height,
                   page.id + ": slot " + slot.width + "x" + slot.height + " not laid out for window " + main.width + "x" + main.height)
            // The whole page is visible without the frame's own scroller (contentHeight is
            // max(height, natural height), so this fails exactly when the content does not fit).
            verify(scroller.contentHeight <= scroller.height + 0.5,
                   page.id + " needs " + scroller.contentHeight + ", has " + scroller.height)
        }
        verify(framePages >= 5) // includes View & control
    }

    // Esc is Safe stop of the Gimbal settings page only: another visible page must not send it (18 Nov decision).
    function test_escapeSendsSafeStopOnlyOnGimbalSettings() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        const main = createMain(true)
        main.currentPageId = "motorControl"
        main.requestActivate()
        tryVerify(() => main.active)
        const sent = testHelper.sentCount()
        keyClick(Qt.Key_Escape)
        compare(testHelper.sentCount(), sent)
        main.currentPageId = "gimbalSettings"
        tryVerify(() => pageItem(main, "gimbalSettings").pageActive)
        keyClick(Qt.Key_Escape)
        compare(testHelper.lastCommandKind(), Command.SafeStop)
        compare(testHelper.sentCount(), sent + 1)
        testHelper.setCommandsSupported(false)
    }

    function test_pageList() {
        const main = createMain(true)
        compare(main.pages.map(page => page.id), ["gimbalInfo", "motorControl", "gimbalSettings", "heater", "viewControl", "alignment", "errors", "gimbalState", "preferences"])
        compare(main.activePageId, "gimbalInfo")
    }

    function test_startsOnLastPage_data() {
        return [
            { tag: "heater", saved: "heater", shown: "heater" },
            { tag: "removedPage", saved: "diagnostics", shown: "gimbalInfo" },
            { tag: "empty", saved: "", shown: "gimbalInfo" }
        ]
    }
    function test_startsOnLastPage(data) {
        testSettings.lastPage = data.saved
        const main = createMain(true)
        compare(main.activePageId, data.shown)
    }

    function test_pageChangeWritesLastPage() {
        const main = createMain(true)
        main.currentPageId = "motorControl"
        compare(testSettings.lastPage, "motorControl")
    }

    function test_switchingKeepsPagesAndStopsInactiveWork() {
        const main = createMain(true)
        const info = pageItem(main, "gimbalInfo")
        const motor = pageItem(main, "motorControl")
        verify(info && motor)
        verify(info.pageActive) // Gimbal info is the start page
        verify(!motor.pageActive)

        mouseClick(findChild(main.contentItem, "nav-motorControl"), 20, 20)
        compare(main.activePageId, "motorControl")
        verify(motor.pageActive)
        verify(!info.pageActive)

        mouseClick(findChild(main.contentItem, "nav-gimbalInfo"), 20, 20)
        compare(main.activePageId, "gimbalInfo")
        compare(pageItem(main, "gimbalInfo"), info)
        compare(pageItem(main, "motorControl"), motor)
        verify(info.pageActive)
        verify(!motor.pageActive)
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

    // The status bar button opens the settings; Apply sets the target and connects (architecture §12).
    function test_connectionSettingsApplied() {
        const main = createMain(true)
        const button = findChild(main.contentItem, "connectionButton")
        compare(button.text, "IP/UDP · 127.0.0.1:5000")
        mouseClick(button)
        const popup = findChild(button, "connectionPopup")
        tryCompare(popup, "opened", true)
        findChild(popup.contentItem, "connection-transport").currentIndex = 1
        const host = findChild(popup.contentItem, "connection-host")
        const port = findChild(popup.contentItem, "connection-port")
        host.text = "10.0.0.7"
        port.text = "70000" // out of range: Apply stays disabled
        const apply = findChild(popup.contentItem, "connection-apply")
        verify(!apply.enabled)
        port.text = "6000"
        verify(apply.enabled)
        mouseClick(apply)
        tryCompare(popup, "opened", false)
        const target = testMainControl.connection.target()
        compare(target.transport, "udp")
        compare(target.host, "10.0.0.7")
        compare(target.port, 6000)
        compare(button.text, "IP/UDP · 10.0.0.7:6000")
        verify(testMainControl.connection.busy) // connecting
    }

    // Rule 1: the real application without saved settings opens them at startup; the demo does not.
    function test_connectionSettingsOpenWhenNotConfigured() {
        testHelper.forgetConnection()
        const demo = createMain(true)
        const demoPopup = findChild(findChild(demo.contentItem, "connectionButton"), "connectionPopup")
        wait(50)
        verify(!demoPopup.opened)
        compare(findChild(demo.contentItem, "connectionButton").text, "Not configured")

        const real = createMain(false)
        const popup = findChild(findChild(real.contentItem, "connectionButton"), "connectionPopup")
        tryCompare(popup, "opened", true)
        popup.close()
    }

    // Rule 1 for IDS Image: its connection settings open when its page becomes visible, not before.
    function test_imageSettingsOpenWhenItsPageShows() {
        testHelper.forgetImageConnection()
        const main = createMain(false)
        const popup = findChild(findChild(main.contentItem, "connectionButton"), "connectionPopup")
        wait(50)
        verify(!popup.opened) // Main control is configured
        main.currentPageId = "viewControl"
        tryCompare(popup, "opened", true)
        compare(findChild(main.contentItem, "connectionButton").text, "Not configured")
        main.currentPageId = "gimbalInfo" // back to a configured service: the popup of the other one closes
        tryCompare(popup, "opened", false)
    }

    // Only the visible page is active; switching hands the activity over (architecture §11).
    function test_onlyVisiblePageIsActive() {
        const main = createMain(true)
        const pagesWithActivity = main.pages.filter(page => {
            const item = pageItem(main, page.id)
            return item && "pageActive" in item
        })
        verify(pagesWithActivity.length >= 4) // the pages with a connection
        for (const shown of pagesWithActivity) {
            main.currentPageId = shown.id
            for (const page of pagesWithActivity)
                compare(pageItem(main, page.id).pageActive, page.id === shown.id, shown.id + " shown, " + page.id)
        }
    }

    // The breadcrumb names the service of the page; pages without a service show only their title.
    function test_breadcrumbShowsService() {
        const main = createMain(true)
        const topBar = findChild(main.contentItem, "topBar")
        main.currentPageId = "motorControl"
        compare(topBar.crumbs, ["Main control service", "Motor control"])
        main.currentPageId = "viewControl"
        compare(topBar.crumbs, ["IDS Image", "View & control"])
        main.currentPageId = "preferences"
        compare(topBar.crumbs, ["Preferences"])
    }

    // The theme switcher writes AppSettings only; Theme.mode follows through Main.qml's binding. Persistence of
    // AppSettings across instances: tst_appsettings (persistsAcrossInstances).
    function test_themeSwitcherWritesSettings() {
        const main = createMain(false)
        const switcher = findChild(main.contentItem, "themeSwitcher")
        for (const [i, mode] of [[0, "light"], [1, "blue"], [2, "dark"]]) {
            mouseClick(switcher.children[0].children[i])
            compare(testSettings.theme, mode)
            compare(Theme.mode, mode)
        }
        testSettings.theme = "light" // changed elsewhere (Preferences): the switcher follows
        compare(switcher.currentIndex, 0)
    }

    // The Realtime window draws only while it is visible.
    function test_realtimeWindowDrawsOnlyWhileOpen() {
        const main = createMain(false)
        const win = findChild(main, "realtimeWindow")
        const chart = win.chart
        verify(!win.visible)
        verify(!chart.active)
        mouseClick(findChild(main.contentItem, "realtimeButton"))
        tryCompare(win, "visible", true)
        verify(chart.active)
        testHelper.connectWithFullSample()
        tryVerify(() => chart.version > 0)
        win.close()
        tryCompare(win, "visible", false)
        verify(!chart.active)
        const version = chart.version
        wait(150)
        compare(chart.version, version)
        win.show()
        tryCompare(chart, "active", true)
        win.close()
    }

    // Everything on the top bar stays inside it, also in Turkish with the sample-data badge.
    function test_topBarFitsInTurkish_data() {
        return [{ tag: "1280", w: 1280 }, { tag: "1024", w: 1024 }]
    }
    function test_topBarFitsInTurkish(data) {
        verify(testLocalization.setLanguage("tr"))
        const main = createMain(true)
        main.visibility = Window.Windowed
        main.width = data.w
        main.height = 700
        main.currentPageId = "gimbalSettings" // longest breadcrumb
        const topBar = findChild(main.contentItem, "topBar")
        const crumbs = topBar.children[0].children[0]
        const status = findChild(topBar, "connectionStatus")
        waitForRendering(topBar)
        const crumbsRight = crumbs.mapToItem(topBar, crumbs.width, 0).x
        const buttonLeft = findChild(topBar, "realtimeButton").mapToItem(topBar, 0, 0).x
        verify(crumbsRight <= buttonLeft, "crumbs " + crumbsRight + " button " + buttonLeft)
        verify(status.mapToItem(topBar, status.width, 0).x <= topBar.width, "status")
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

    // Bell button with a count badge opens the list; errors must not stay hidden (T14).
    function test_notificationBellAndPopup() {
        const main = createMain(false)
        const badge = findChild(main.contentItem, "notificationsBadge")
        verify(!badge.visible)
        testHelper.addNotification("device.error.mainControl", "link lost")
        tryCompare(badge, "visible", true)

        const button = findChild(main.contentItem, "notificationsButton")
        compare(button.Accessible.name, "Notifications (1)")
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

    // Demo-like data: every field of the status bar is filled.
    function test_statusBarShowsAllFields() {
        const main = createMain(true)
        testHelper.connectWithFullSample()
        testHelper.sendTraffic(2500, 110000)
        const bar = findChild(main.contentItem, "statusBar")
        tryCompare(findChild(bar, "txLed"), "active", true)
        tryCompare(findChild(bar, "rxLed"), "active", true)
        verify(findChild(bar, "heartbeatLed").active)
        compare(findChild(bar, "onTime").text, "3 h 12 min")
        verify(findChild(bar, "bitBadge").visible)
        compare(findChild(bar, "bitBadge").text, "Warning")
        compare(findChild(bar, "bitMessage").text, "Pan motor: OK")
        tryVerify(() => findChild(bar, "dataRate").text !== "0.00 Mbps")
        verify(findChild(bar, "dataRate").text.endsWith(" Mbps"))
        tryCompare(findChild(bar, "txLed"), "active", false) // no new bytes
        testHelper.sendSample() // keep the heartbeat alive for the next checks
    }

    // Real target without a protocol: link open, nothing decoded; protocol fields show "—" (no invented data).
    function test_statusBarWithoutProtocolShowsDashes() {
        const main = createMain(false)
        testHelper.connectBare()
        const bar = findChild(main.contentItem, "statusBar")
        compare(findChild(bar, "onTime").text, "—")
        compare(findChild(bar, "bitMessage").text, "—")
        verify(!findChild(bar, "bitBadge").visible)
        verify(!findChild(bar, "heartbeatLed").active)
        verify(!findChild(bar, "txLed").active)
        verify(!findChild(bar, "rxLed").active)
        testHelper.sendTraffic(0, 40) // bytes arrive even without a protocol
        tryCompare(findChild(bar, "rxLed"), "active", true)
        testHelper.disconnectDevice()
        compare(findChild(bar, "dataRate").text, "—")
    }

    // The running operation shows name and percent; the section keeps its width when it ends.
    function test_statusBarOperation() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        const main = createMain(true)
        const bar = findChild(main.contentItem, "statusBar")
        const section = findChild(bar, "operationSection")
        const name = findChild(bar, "operationName")
        const width = section.width
        verify(!name.visible)
        verify(testMainControl.connection.send(Command.UpdateFirmware, { file: "x.bin" }))
        testHelper.reportProgress(40, "Writing")
        tryCompare(name, "visible", true)
        compare(name.text, "Updating firmware")
        compare(findChild(bar, "operationPercent").text, "40%")
        verify(testLocalization.setLanguage("tr"))
        compare(name.text, "Yazılım güncelleniyor")
        testHelper.answerLastCommand(Command.Accepted)
        tryCompare(name, "visible", false)
        compare(section.width, width)
        testHelper.setCommandsSupported(false)
    }

    // Debug settings: service state, sample age, dropped stale results, pending commands, byte totals.
    function test_debugSettingsPopup() {
        testHelper.setCommandsSupported(true)
        testHelper.connectWithFullSample()
        testHelper.sendTraffic(7, 90)
        const main = createMain(true)
        const button = findChild(main.contentItem, "debugButton")
        mouseClick(button)
        const popup = findChild(button, "debugPopup")
        tryCompare(popup, "opened", true)
        compare(findChild(popup.contentItem, "debugStatus-mainControl").text, "Connected")
        tryVerify(() => findChild(popup.contentItem, "debugSampleAge").value !== "—")
        compare(findChild(popup.contentItem, "debugPending").value, "—")
        verify(testMainControl.connection.send(Command.RunBit))
        compare(findChild(popup.contentItem, "debugPending").value, "RunBit")
        tryCompare(findChild(popup.contentItem, "debugTraffic"), "value", "7 B / 90 B")
        popup.close()
        testHelper.answerLastCommand(Command.Accepted)
        testHelper.setCommandsSupported(false)
    }

    // The connection button belongs to the service of the visible page; the preferences show Main control's.
    function test_connectionButtonFollowsPageService() {
        const main = createMain(true)
        const button = findChild(main.contentItem, "connectionButton")
        main.currentPageId = "preferences"
        compare(button.text, "IP/UDP · 127.0.0.1:5000")
        compare(main.activeConnection, testMainControl.connection)
    }

    // Two services, two connections: both open at once, cutting one leaves the other running.
    function test_twoConnectionsAreIndependent() {
        createMain(true)
        testHelper.connectBare()
        testHelper.connectImage()
        verify(testMainControl.connection.connected)
        verify(testImageViewModel.connection.connected)
        testHelper.disconnectImage()
        verify(!testImageViewModel.connection.connected)
        verify(testMainControl.connection.connected)
        testHelper.disconnectDevice()
        testHelper.disconnectImage()
    }

    // Debug settings lists both services; the rail shows the IDS Image logo (no page yet).
    function test_imageServiceShown() {
        const main = createMain(true)
        const button = findChild(main.contentItem, "debugButton")
        mouseClick(button)
        const popup = findChild(button, "debugPopup")
        tryCompare(popup, "opened", true)
        verify(findChild(popup.contentItem, "debugStatus-mainControl"))
        verify(findChild(popup.contentItem, "debugStatus-idsImage"))
        popup.close()
        compare(main.connections.idsImage, testImageViewModel.connection)
        verify(findChild(main.contentItem, "railBrandImage"))
    }

    // Device errors name their service.
    function test_deviceErrorNamesService() {
        testNotifications.clear()
        testHelper.failImage("no route")
        compare(testNotifications.rowCount(), 1)
        compare(testHelper.lastNotificationCode(), "device.error.idsImage")
    }
}
