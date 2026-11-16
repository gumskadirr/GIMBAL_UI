pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import IDS_GIMBAL

ApplicationWindow {
    id: window
    required property AppSettings settings
    required property Localization localization
    required property NotificationModel notifications
    required property DeviceViewModel deviceViewModel
    required property bool demoMode

    // Page registry: titles are bindings, so they follow language changes. Order matches the StackLayout.
    readonly property list<string> pageTitles: [qsTr("Diagnostics"), qsTr("Preferences")]
    property int currentPage: 0

    width: 1024
    height: 700
    minimumWidth: 480
    minimumHeight: 320
    visible: true
    title: qsTr("IDS Gimbal")
    color: Theme.background

    Binding {
        target: Theme
        property: "dark"
        value: window.settings.theme === "dark"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            visible: window.demoMode
            color: Theme.warning
            Layout.fillWidth: true
            implicitHeight: bannerText.implicitHeight + 2 * Theme.spacingNormal
            Label {
                id: bannerText
                anchors.centerIn: parent
                text: qsTr("Sample data — no real device connection")
                color: Theme.background
                font.pixelSize: Theme.fontSizeNormal
                font.bold: true
            }
        }

        RowLayout {
            spacing: Theme.spacingNormal
            Layout.margins: Theme.spacingLarge
            Layout.bottomMargin: 0
            Repeater {
                // An int model keeps the buttons when only the titles change.
                model: window.pageTitles.length
                AppButton {
                    required property int index
                    text: window.pageTitles[index]
                    checked: window.currentPage === index
                    onClicked: window.currentPage = index
                }
            }
        }

        RowLayout {
            spacing: Theme.spacingLarge
            Layout.margins: Theme.spacingLarge
            Layout.fillWidth: true
            Layout.fillHeight: true

            StackLayout {
                currentIndex: window.currentPage
                Layout.fillWidth: true
                Layout.fillHeight: true

                DiagnosticsPage {
                    viewModel: window.deviceViewModel
                    pageActive: StackLayout.isCurrentItem
                }
                PreferencesPage {
                    settings: window.settings
                    localization: window.localization
                }
            }

            NotificationArea {
                model: window.notifications
                Layout.preferredWidth: 340
                Layout.fillHeight: true
            }
        }
    }
}
