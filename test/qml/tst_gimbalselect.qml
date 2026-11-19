import QtQuick
import QtTest
import IDS_GIMBAL

// Gimbal selection (design page 6, corrected): one consistent selection, Cancel keeps the saved one, Continue
// saves it, and the panel opens at start when no valid gimbal is saved or "Open this gimbal on start" is off.
TestCase {
    id: testCase
    name: "GimbalSelect"
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

    function openDialog(main) {
        const dialog = findChild(main, "gimbalDialog")
        mouseClick(findChild(main.contentItem, "gimbalButton"))
        tryCompare(dialog, "opened", true)
        return dialog
    }

    function init() {
        testLocalization.setLanguage("en")
        testSettings.gimbal = "g180"
        testSettings.gimbalVersion = "v2.0"
        testSettings.gimbalOnStart = true
    }

    function cleanup() {
        init() // the other tests expect a chosen gimbal
        testHelper.restoreConnection()
    }

    function test_validSavedGimbalDoesNotOpen() {
        const main = createMain(true)
        wait(50)
        verify(!findChild(main, "gimbalDialog").visible)
        compare(findChild(main.contentItem, "gimbalButton").text, "G180 · v2.0")
    }

    function test_unknownSavedGimbalOpensAtStart() {
        testSettings.gimbalVersion = "v9.0" // no longer in the list
        const main = createMain(true)
        const dialog = findChild(main, "gimbalDialog")
        tryCompare(dialog, "opened", true)
        compare(dialog.selectedId, "")
        verify(!findChild(dialog.contentItem, "gimbalContinue").enabled)
        compare(findChild(main.contentItem, "gimbalButton").text, "Select gimbal")
    }

    function test_onStartOffOpensAtStart() {
        testSettings.gimbalOnStart = false
        const main = createMain(true)
        const dialog = findChild(main, "gimbalDialog")
        tryCompare(dialog, "opened", true)
        compare(dialog.selectedId, "g180") // the saved one is preselected
        compare(dialog.selectedVersion, "v2.0")
        verify(!findChild(dialog.contentItem, "gimbalOnStart").checked)
    }

    function test_versionClickSelectsCard() {
        const main = createMain(true)
        const dialog = openDialog(main)
        mouseClick(findChild(dialog.contentItem, "version-g160-v1.0"))
        compare(dialog.selectedId, "g160")
        compare(dialog.selectedVersion, "v1.0")
        verify(findChild(dialog.contentItem, "gimbalSelected").text.includes("G160 · v1.0"))
        compare(findChild(dialog.contentItem, "version-g160-v1.0").variant, "primary")
        compare(findChild(dialog.contentItem, "version-g180-v2.0").variant, "secondary") // only the selected card highlights
        compare(findChild(dialog.contentItem, "gimbalCard-g160").border.color, Theme.acc)
    }

    function test_cardClickSelectsLastVersion() {
        const main = createMain(true)
        const dialog = openDialog(main)
        const card = findChild(dialog.contentItem, "gimbalCard-g160")
        mouseClick(card, card.width / 2, 30) // the title row
        compare(dialog.selectedId, "g160")
        compare(dialog.selectedVersion, "v2.0")
        mouseClick(findChild(dialog.contentItem, "version-g160-v1.0"))
        mouseClick(card, card.width / 2, 30) // already selected: the version stays
        compare(dialog.selectedVersion, "v1.0")
    }

    function test_continueSaves() {
        const main = createMain(true)
        const dialog = openDialog(main)
        mouseClick(findChild(dialog.contentItem, "version-kashif700-v1.0"))
        findChild(dialog.contentItem, "gimbalOnStart").checked = false
        mouseClick(findChild(dialog.contentItem, "gimbalContinue"))
        tryCompare(dialog, "visible", false)
        compare(testSettings.gimbal, "kashif700")
        compare(testSettings.gimbalVersion, "v1.0")
        verify(!testSettings.gimbalOnStart)
        compare(findChild(main.contentItem, "gimbalButton").text, "Kashif700 · v1.0")
    }

    function test_cancelKeepsSaved() {
        const main = createMain(true)
        let dialog = openDialog(main)
        mouseClick(findChild(dialog.contentItem, "version-g160-v1.0"))
        keyClick(Qt.Key_Escape)
        tryCompare(dialog, "visible", false)
        compare(testSettings.gimbal, "g180")
        dialog = openDialog(main)
        compare(dialog.selectedId, "g180") // the saved one, not the abandoned choice
        compare(dialog.selectedVersion, "v2.0")
        mouseClick(findChild(dialog.contentItem, "gimbalCancel"))
        tryCompare(dialog, "visible", false)
        compare(testSettings.gimbalVersion, "v2.0")
    }

    // Both would open at start: the gimbal selection first, the connection settings after it closes.
    function test_connectionSettingsWaitForGimbal() {
        testSettings.gimbal = ""
        testHelper.forgetConnection()
        const main = createMain(false)
        const dialog = findChild(main, "gimbalDialog")
        const popup = findChild(findChild(main.contentItem, "connectionButton"), "connectionPopup")
        tryCompare(dialog, "opened", true)
        wait(50)
        verify(!popup.visible)
        mouseClick(findChild(dialog.contentItem, "gimbalCancel"))
        tryCompare(popup, "opened", true)
        popup.close()
    }
}
