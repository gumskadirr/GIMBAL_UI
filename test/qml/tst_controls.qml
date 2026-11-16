import QtQuick
import QtTest
import IDS_GIMBAL

TestCase {
    id: testCase
    name: "Controls"
    when: windowShown
    width: 400
    height: 400

    // Stands in for AppSettings, which QML cannot create.
    QtObject {
        id: backend
        property string theme: "dark"
    }

    // Same pattern as PreferencesPage: selection follows the setting, user choice written back.
    Component {
        id: comboComponent
        IdsComboBox {
            textRole: "name"
            valueRole: "code"
            model: [
                { code: "light", name: "Light" },
                { code: "blue", name: "Blue" },
                { code: "dark", name: "Dark" }
            ]
            selectedValue: backend.theme
            onActivated: backend.theme = currentValue
        }
    }
    Component {
        id: fixedComboComponent
        IdsComboBox {
            textRole: "name"
            valueRole: "code"
            model: [
                { code: "light", name: "Light" },
                { code: "blue", name: "Blue" },
                { code: "dark", name: "Dark" }
            ]
            selectedValue: "dark"
        }
    }
    Component {
        id: buttonComponent
        IdsButton { text: "x" }
    }

    function init() {
        backend.theme = "dark"
        Theme.mode = "dark"
    }

    function test_checkedButtonUsesSelectedColors() {
        const button = createTemporaryObject(buttonComponent, testCase)
        button.checked = true
        verify(Qt.colorEqual(button.background.color, Theme.navOn))
        verify(Qt.colorEqual(button.background.border.color, Theme.navRing))
        button.checked = false
        verify(!Qt.colorEqual(button.background.color, Theme.navOn))
        button.enabled = false
        compare(button.opacity, 0.5)
    }

    function test_openPopupFollowsTheme() {
        const combo = createTemporaryObject(comboComponent, testCase)
        combo.popup.open()
        tryCompare(combo.popup, "opened", true)
        for (const mode of ["light", "blue", "dark"]) {
            Theme.mode = mode
            verify(Qt.colorEqual(combo.popup.background.color, Theme.card), mode)
        }
        combo.popup.close()
    }

    function test_popupListsItems() {
        const combo = createTemporaryObject(comboComponent, testCase)
        combo.popup.open()
        tryCompare(combo.popup, "opened", true)
        const list = combo.popup.contentItem
        compare(list.count, 3)
        tryVerify(() => list.itemAtIndex(2) !== null, 1000, "all rows are created")
        compare(list.itemAtIndex(1).text, "Blue")
        verify(combo.popup.height >= 3 * 34, "popup shows every row: " + combo.popup.height)
        combo.popup.close()
    }

    function test_userSelectionWritesSettingAndFollowsIt() {
        const combo = createTemporaryObject(comboComponent, testCase)
        compare(combo.currentIndex, 2)
        combo.forceActiveFocus()
        keyClick(Qt.Key_Up)
        compare(backend.theme, "blue")
        backend.theme = "light" // changed elsewhere after a user selection
        compare(combo.currentIndex, 0)
    }

    function test_selectionSurvivesModelRebuild() {
        const combo = createTemporaryObject(comboComponent, testCase)
        backend.theme = "blue"
        compare(combo.currentIndex, 1)
        // What a language change does to a qsTr model.
        combo.model = [
            { code: "light", name: "Açık" },
            { code: "blue", name: "Mavi" },
            { code: "dark", name: "Koyu" }
        ]
        tryCompare(combo, "currentIndex", 1)
        compare(combo.currentText, "Mavi")
    }

    // The owner does not accept the choice (e.g. an invalid setting), so the box must not lie.
    function test_rejectedChoiceSnapsBack() {
        const combo = createTemporaryObject(fixedComboComponent, testCase)
        compare(combo.currentIndex, 2)
        combo.forceActiveFocus()
        keyClick(Qt.Key_Up)
        tryCompare(combo, "currentIndex", 2)
    }
}
