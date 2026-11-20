import QtQuick
import QtTest
import IDS_GIMBAL

// Top-bar connection chip: sums up both services (red when none is connected) and opens the panel of both
// connections, which connects, disconnects and configures any service whatever page is visible.
TestCase {
    id: testCase
    name: "Connections"
    when: windowShown

    function createMain() {
        const component = Qt.createComponent("IDS_GIMBAL", "Main")
        verify(component.status === Component.Ready, component.errorString())
        const main = createTemporaryObject(component, testCase, {
            settings: testSettings,
            localization: testLocalization,
            notifications: testNotifications,
            mainControl: testMainControl, imageViewModel: testImageViewModel,
            demoMode: true
        })
        verify(main)
        return main
    }

    function chipStatus(chip) { return chip.background.status }

    function openPanel(main) {
        const panel = findChild(main, "connectionsPanel")
        mouseClick(findChild(main.contentItem, "connectionStatus"))
        tryCompare(panel, "opened", true)
        return panel
    }

    function init() { testLocalization.setLanguage("en") }

    function cleanup() {
        testMainControl.connection.disconnectDevice()
        testImageViewModel.connection.disconnectDevice()
        testHelper.restoreConnection()
        testHelper.restoreImageConnection()
    }

    function test_chipSumsUpBothServices() {
        const main = createMain()
        const chip = findChild(main.contentItem, "connectionStatus")
        compare(chip.text, "Not connected")
        compare(chipStatus(chip), "crit")

        testHelper.connectBare()
        tryCompare(chip, "text", "1/2 connected")
        compare(chipStatus(chip), "warn")

        testHelper.connectImage()
        tryCompare(chip, "text", "Connected")
        compare(chipStatus(chip), "ok")

        testHelper.failImage("link lost")
        tryCompare(chip, "text", "1/2 connected")
        compare(chipStatus(chip), "crit") // an error is red even when the other service is up
    }

    function test_chipInTurkish() {
        const main = createMain()
        const chip = findChild(main.contentItem, "connectionStatus")
        verify(testLocalization.setLanguage("tr"))
        compare(chip.text, "Bağlı değil")
        testHelper.connectBare()
        tryCompare(chip, "text", "1/2 bağlı")
    }

    function test_panelConnectsAndDisconnectsEitherService() {
        const main = createMain()
        main.currentPageId = "gimbalInfo" // a Main control page: the IDS Image service is not visible
        const panel = openPanel(main)
        const imageToggle = findChild(panel.contentItem, "connectionToggle-idsImage")
        compare(imageToggle.text, "Connect")
        mouseClick(imageToggle)
        verify(testImageViewModel.connection.busy || testImageViewModel.connection.connected)
        compare(imageToggle.text, "Disconnect")
        mouseClick(imageToggle)
        verify(!testImageViewModel.connection.busy && !testImageViewModel.connection.connected)

        testHelper.connectBare()
        const mainToggle = findChild(panel.contentItem, "connectionToggle-mainControl")
        tryCompare(mainToggle, "text", "Disconnect")
        mouseClick(mainToggle)
        verify(!testMainControl.connection.connected)
    }

    function test_connectNeedsSettings() {
        testHelper.forgetImageConnection()
        const main = createMain()
        const panel = openPanel(main)
        verify(!findChild(panel.contentItem, "connectionToggle-idsImage").enabled)
        verify(findChild(panel.contentItem, "connectionState-idsImage").text.endsWith(" · Not configured"))
        verify(findChild(panel.contentItem, "connectionSettings-idsImage").enabled)
    }

    function test_settingsOfTheOtherService() {
        const main = createMain()
        main.currentPageId = "gimbalInfo"
        const panel = openPanel(main)
        mouseClick(findChild(panel.contentItem, "connectionSettings-idsImage"))
        const settings = panel.settingsPopup
        tryCompare(settings, "opened", true)
        verify(!panel.visible)
        compare(settings.title, "IDS Image service")
        verify(settings.udpOnly)
        compare(findChild(settings.contentItem, "connection-host").text, "127.0.0.1")

        findChild(settings.contentItem, "connection-port").text = "5001"
        mouseClick(findChild(settings.contentItem, "connection-apply"))
        compare(testImageViewModel.connection.summary, "IP/UDP · 127.0.0.1:5001")
        compare(testMainControl.connection.summary, "IP/UDP · 127.0.0.1:5000") // the visible service is untouched
    }
}
