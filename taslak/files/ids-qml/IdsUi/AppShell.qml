import QtQuick
import QtQuick.Layouts
import IdsUi

// Tüm ekranların ortak iskeleti:
//   marka şeridi / [NavRail | TopBar + içerik + StatusBar] / marka şeridi
//   AppShell { navigation: NavRail {...}; topBar: TopBar {...}; statusBar: StatusBar {...}
//              GimbalInfoPage { anchors.fill: parent } }
Rectangle {
    id: root

    property Item navigation: null
    property Item topBar: null
    property Item statusBar: null
    property int contentHPadding: 20
    property int contentVPadding: 16
    default property alias content: contentHost.data

    color: Theme.bg

    function _place(item, host) {
        if (!item) return
        item.parent = host
        item.anchors.fill = host
    }
    onNavigationChanged: _place(navigation, navHost)
    onTopBarChanged: _place(topBar, topHost)
    onStatusBarChanged: _place(statusBar, statusHost)
    Component.onCompleted: {
        _place(navigation, navHost); _place(topBar, topHost); _place(statusBar, statusHost)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        BrandStripe { Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Item {
                id: navHost
                z: 2
                Layout.fillHeight: true
                Layout.preferredWidth: root.navigation ? root.navigation.implicitWidth : 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Item {
                    id: topHost
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.topBar ? root.topBar.implicitHeight : 0
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Item {
                        id: contentHost
                        anchors.fill: parent
                        anchors.leftMargin: root.contentHPadding
                        anchors.rightMargin: root.contentHPadding
                        anchors.topMargin: root.contentVPadding
                        anchors.bottomMargin: root.contentVPadding
                    }
                }
                Item {
                    id: statusHost
                    z: 1
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.statusBar ? root.statusBar.implicitHeight : 0
                }
            }
        }

        BrandStripe { Layout.fillWidth: true }
    }
}
