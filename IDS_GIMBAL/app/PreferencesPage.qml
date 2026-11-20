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
        IdsComboBox {
            Layout.preferredWidth: 220
            Accessible.name: qsTr("Theme")
            textRole: "name"
            valueRole: "code"
            model: [
                { code: "light", name: qsTr("Light") },
                { code: "blue", name: qsTr("Blue") },
                { code: "dark", name: qsTr("Dark") }
            ]
            selectedValue: page.settings.theme
            onActivated: page.settings.theme = currentValue
        }

        Label {
            text: qsTr("Language")
            color: Theme.muted
        }
        IdsComboBox {
            Layout.preferredWidth: 220
            Accessible.name: qsTr("Language")
            textRole: "name"
            valueRole: "code"
            // Language names are endonyms and intentionally not translated.
            model: [
                { code: "tr", name: "Türkçe" },
                { code: "en", name: "English" }
            ]
            selectedValue: page.localization.language
            onActivated: page.localization.setLanguage(currentValue)
        }
    }
}
