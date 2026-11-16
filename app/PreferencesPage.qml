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
            color: Theme.textSecondary
        }
        AppButton {
            text: Theme.dark ? qsTr("Switch to light theme") : qsTr("Switch to dark theme")
            onClicked: page.settings.theme = Theme.dark ? "light" : "dark"
        }

        Label {
            text: qsTr("Language")
            color: Theme.textSecondary
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
