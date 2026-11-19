import QtQuick
import QtTest
import IDS_GIMBAL

// Adding, editing and deleting gimbals from the selection window (GimbalLibrary underneath). The file dialog is
// not driven: tests put the chosen files into the editor's `files`.
TestCase {
    id: testCase
    name: "GimbalEdit"
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
    function openSelect(main) {
        const dialog = findChild(main, "gimbalDialog")
        mouseClick(findChild(main.contentItem, "gimbalButton"))
        tryCompare(dialog, "opened", true)
        return dialog
    }
    function child(popup, name) { return findChild(popup.contentItem, name) }
    function library() { return testSettings.gimbalLibrary }
    function names() { return library().gimbals.map(g => g.name) }
    function zr10Files() {
        const m = library().gimbals.find(g => g.id === "zr10").model
        return { base: m.base, pan: m.pan, tilt: m.tilt }
    }

    function init() {
        testLocalization.setLanguage("en")
        testSettings.gimbal = "g180"
        testSettings.gimbalVersion = "v2.0"
    }
    function cleanup() {
        testHelper.resetGimbalLibrary()
        init()
    }

    function test_addGimbal() {
        const select = openSelect(createMain())
        mouseClick(child(select, "gimbalAdd"))
        const edit = child(select, "gimbalEditDialog")
        tryCompare(edit, "opened", true)
        compare(edit.gimbal, null)
        child(edit, "edit-name").text = "G200"
        child(edit, "edit-versions").text = "v1.0, v1.1"
        edit.files = zr10Files()
        child(edit, "edit-tiltPivot").fieldY.text = "-53,1" // English: comma is not a decimal separator
        mouseClick(child(edit, "edit-save"))
        compare(child(edit, "edit-error").text, "Enter the axis positions as numbers.")
        child(edit, "edit-tiltPivot").fieldY.text = "-53.1"
        mouseClick(child(edit, "edit-save"))
        tryCompare(edit, "opened", false)

        const added = library().gimbals.find(g => g.name === "G200")
        verify(added)
        compare(added.versions, ["v1.0", "v1.1"])
        compare(added.model.tiltPivot[1], -53.1)
        verify(added.model.base.indexOf("/g200/") > 0) // copied into the library
        compare(select.selectedId, "g200") // the new gimbal is selected, its last version
        compare(select.selectedVersion, "v1.1")
        verify(findChild(select.contentItem, "gimbalCard-g200"))
    }

    function test_addWithoutModel() {
        const select = openSelect(createMain())
        mouseClick(child(select, "gimbalAdd"))
        const edit = child(select, "gimbalEditDialog")
        tryCompare(edit, "opened", true)
        child(edit, "edit-name").text = "Bare"
        child(edit, "edit-hasModel").checked = false
        mouseClick(child(edit, "edit-save"))
        tryCompare(edit, "opened", false)
        compare(library().gimbals.find(g => g.name === "Bare").model, null)
    }

    function test_modelNeedsFiles() {
        const select = openSelect(createMain())
        mouseClick(child(select, "gimbalAdd"))
        const edit = child(select, "gimbalEditDialog")
        tryCompare(edit, "opened", true)
        child(edit, "edit-name").text = "G200"
        compare(child(edit, "edit-fileName-tilt").text, "No file")
        mouseClick(child(edit, "edit-save"))
        verify(child(edit, "edit-error").text !== "")
        verify(edit.opened)
        compare(names().length, 4)
    }

    function test_editName() {
        const main = createMain()
        const select = openSelect(main)
        mouseClick(child(select, "gimbalEdit-zr10"))
        const edit = child(select, "gimbalEditDialog")
        tryCompare(edit, "opened", true)
        compare(child(edit, "edit-name").text, "ZR10")
        compare(child(edit, "edit-fileName-pan").text, "Current file")
        compare(edit.model.tiltSign, -1)
        compare(edit.model.inPlace, false)
        const oldTilt = library().gimbals.find(g => g.id === "zr10").model.tilt
        child(edit, "edit-name").text = "ZR10 Pro"
        mouseClick(child(edit, "edit-save"))
        tryCompare(edit, "opened", false)
        const edited = library().gimbals.find(g => g.id === "zr10")
        compare(edited.name, "ZR10 Pro")
        compare(edited.model.tilt, oldTilt) // no new file chosen: the stored one stays
        compare(edited.model.tiltPivot, [-4.1, -53.1, 13.94])
    }

    function test_duplicateNameShowsError() {
        const select = openSelect(createMain())
        mouseClick(child(select, "gimbalEdit-g160"))
        const edit = child(select, "gimbalEditDialog")
        tryCompare(edit, "opened", true)
        child(edit, "edit-name").text = "g180"
        mouseClick(child(edit, "edit-save"))
        compare(child(edit, "edit-error").text, "A gimbal named g180 already exists.")
        verify(edit.opened)
    }

    function test_cancelChangesNothing() {
        const select = openSelect(createMain())
        const before = JSON.stringify(library().gimbals)
        mouseClick(child(select, "gimbalEdit-g180"))
        const edit = child(select, "gimbalEditDialog")
        tryCompare(edit, "opened", true)
        child(edit, "edit-name").text = "Changed"
        mouseClick(child(edit, "edit-cancel"))
        tryCompare(edit, "opened", false)
        compare(JSON.stringify(library().gimbals), before)
        verify(select.opened) // back in the selection window
    }

    function test_deleteAsksAndRemoves() {
        const select = openSelect(createMain())
        select.select("zr10", "v1.0")
        mouseClick(child(select, "gimbalDelete-zr10"))
        const confirm = child(select, "gimbalDeleteDialog")
        tryCompare(confirm, "opened", true)
        compare(names().length, 4) // nothing deleted before the confirmation
        mouseClick(findChild(confirm.contentItem, "confirm-accept"))
        tryCompare(confirm, "opened", false)
        compare(names(), ["G160", "G180", "Kashif700"])
        compare(select.selectedId, "")
    }

    function test_deleteSavedGimbal() {
        const main = createMain()
        const select = openSelect(main)
        mouseClick(child(select, "gimbalDelete-g180"))
        const confirm = child(select, "gimbalDeleteDialog")
        tryCompare(confirm, "opened", true)
        mouseClick(findChild(confirm.contentItem, "confirm-accept"))
        compare(findChild(main.contentItem, "gimbalButton").text, "Select gimbal")
        verify(!findChild(select.contentItem, "gimbalContinue").enabled)
    }
}
