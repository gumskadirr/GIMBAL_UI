import QtQuick
import QtTest
import IDS_GIMBAL

TestCase {
    id: testCase
    name: "Theme"

    readonly property list<string> modes: ["light", "blue", "dark"]

    Component {
        id: buttonComponent
        AppButton { text: "x" }
    }
    Component {
        id: notificationAreaComponent
        NotificationArea {}
    }

    function cleanup() {
        Theme.mode = "dark"
    }

    // Palettes are untyped maps; a missing or misspelled key would silently give an invalid color.
    function test_palettesComplete() {
        const keys = Object.keys(Theme._palettes.light).sort()
        for (const mode of testCase.modes) {
            compare(Object.keys(Theme._palettes[mode]).sort(), keys, mode)
            for (const key of keys)
                verify(/^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/.test(Theme._palettes[mode][key]), mode + "." + key)
        }
    }

    function test_modeSwitchesColors_data() {
        return [
            { tag: "light", bg: "#F4F4F5", card: "#FFFFFF", acc: "#3B3FB0" },
            { tag: "blue", bg: "#10111B", card: "#151623", acc: "#4F55D6" },
            { tag: "dark", bg: "#000000", card: "#0A0A0A", acc: "#4A4FCC" }
        ]
    }

    function test_modeSwitchesColors(data) {
        Theme.mode = data.tag
        verify(Qt.colorEqual(Theme.bg, data.bg), "bg " + Theme.bg)
        verify(Qt.colorEqual(Theme.card, data.card), "card " + Theme.card)
        verify(Qt.colorEqual(Theme.acc, data.acc), "acc " + Theme.acc)
    }

    function test_unknownModeFallsBackToLight() {
        Theme.mode = "purple"
        verify(Qt.colorEqual(Theme.bg, "#F4F4F5"))
    }

    function test_controlsFollowThemeLive() {
        const button = createTemporaryObject(buttonComponent, testCase)
        const area = createTemporaryObject(notificationAreaComponent, testCase, { model: null })
        verify(button && area)
        for (const mode of testCase.modes) {
            Theme.mode = mode
            verify(Qt.colorEqual(button.background.color, Theme.acc), mode + " button")
            verify(Qt.colorEqual(area.color, Theme.card), mode + " notification area")
        }
    }

    function test_fontFamiliesAvailable() {
        verify(Qt.fontFamilies().indexOf(Theme.fontSans) >= 0, Theme.fontSans)
        verify(Qt.fontFamilies().indexOf(Theme.fontMono) >= 0, Theme.fontMono)
    }
}
