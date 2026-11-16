pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import IDS_GIMBAL

Item {
    id: page
    required property AppSettings settings
    required property Localization localization

    ColumnLayout {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: Theme.spacingLarge

        Label {
            text: qsTr("Theme")
            color: Theme.muted
        }
        RowLayout {
            spacing: Theme.spacingNormal
            Repeater {
                model: [
                    { code: "light", name: qsTr("Light") },
                    { code: "blue", name: qsTr("Blue") },
                    { code: "dark", name: qsTr("Dark") }
                ]
                AppButton {
                    required property var modelData
                    text: modelData.name
                    checked: page.settings.theme === modelData.code
                    onClicked: page.settings.theme = modelData.code
                }
            }
        }

        Label {
            text: qsTr("Language")
            color: Theme.muted
        }
        RowLayout {
            spacing: Theme.spacingNormal
            // Language names are endonyms and intentionally not translated.
            AppButton {
                text: "Türkçe"
                checked: page.localization.language === "tr"
                onClicked: page.localization.setLanguage("tr")
            }
            AppButton {
                text: "English"
                checked: page.localization.language === "en"
                onClicked: page.localization.setLanguage("en")
            }
        }
    }
}
