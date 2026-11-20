import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import IdsUi

// Örnek: "Gimbal info" ekranı ortak bileşenlerle.
Window {
    id: win
    width: 1920
    height: 1080
    visible: true
    title: qsTr("IDS Control · Main control service")
    color: Theme.bg

    property string page: "info"

    AppShell {
        anchors.fill: parent

        navigation: NavRail {
            RailBrand { logoSource: Qt.resolvedUrl("assets/ids_logo.png"); title: "IDS Control"; subtitle: qsTr("Main control service"); connected: true }
            NavSection { text: qsTr("Board") }
            NavItem { text: qsTr("Gimbal info");     iconPath: Icons.info;    current: win.page === "info";     onClicked: win.page = "info" }
            NavSection { text: qsTr("Control") }
            NavItem { text: qsTr("Motor control");   iconPath: Icons.motor;   current: win.page === "control";  onClicked: win.page = "control" }
            NavItem { text: qsTr("Gimbal settings"); iconPath: Icons.sliders; current: win.page === "settings"; onClicked: win.page = "settings" }
            NavSection { text: qsTr("Hardware") }
            NavItem { text: qsTr("Heater");          iconPath: Icons.heater;  current: win.page === "heater";   onClicked: win.page = "heater" }
            NavDivider {}
            RailBrand { logoSource: Qt.resolvedUrl("assets/ids_logo.png"); title: "IDS Image"; subtitle: qsTr("Linux and imaging"); connected: true }
            NavItem { text: qsTr("View & control");  iconPath: Icons.eye;     current: win.page === "live";      onClicked: win.page = "live" }
            NavItem { text: qsTr("Alignment");       iconPath: Icons.target;  current: win.page === "alignment"; onClicked: win.page = "alignment" }
            NavItem { text: qsTr("Errors");          iconPath: Icons.warning; current: win.page === "errors";    onClicked: win.page = "errors" }
            NavItem { text: qsTr("Gimbal state");    iconPath: Icons.list;    current: win.page === "state";     onClicked: win.page = "state" }
        }

        topBar: TopBar {
            crumbs: [qsTr("Main control service"), qsTr("Gimbal info")]
            IdsButton { text: qsTr("Realtime graph and logger"); iconPath: Icons.chart }
            ThemeSwitcher {}
            StatusLabel { framed: true; status: "ok"; text: qsTr("Connected") }
            IdsButton { text: "G180 · v2.0"; iconPath: Icons.gimbal; trailingIconPath: Icons.chevronDown }
        }

        statusBar: StatusBar {
            StatusBarSection {
                Led { id: txLed; kind: "tx"; text: "TX" }
                Led { id: rxLed; kind: "rx"; text: "RX" }
                Text { text: "0.09 Mbps"; font.family: Theme.fontMono; font.pixelSize: Theme.fsSmall; color: Theme.text2 }
                Led { kind: "heartbeat"; text: "HEARTBEAT" }
            }
            StatusBarSection {
                Layout.fillWidth: true
                Text { text: "BIT"; font.family: Theme.fontSans; font.pixelSize: Theme.fsOverline; font.weight: Font.DemiBold; font.letterSpacing: Theme.overlineSpacing; color: Theme.label }
                Badge { kind: "warn"; text: "WARNING" }
                Text { Layout.fillWidth: true; text: qsTr("Pan motor position limit reached"); elide: Text.ElideRight; font.family: Theme.fontSans; font.pixelSize: Theme.fsSmall; color: Theme.text2 }
                Text { text: qsTr("Reading board info"); font.family: Theme.fontSans; font.pixelSize: Theme.fsSmall; color: Theme.label }
                IdsProgressBar { value: 0.62 }
                Text { text: "62%"; font.family: Theme.fontMono; font.pixelSize: Theme.fsSmall; color: Theme.text2 }
            }
            StatusBarSection {
                spacing: 8
                StatusBarButton {
                    id: connBtn
                    text: connPopup.summary
                    trailingIconPath: Icons.chevronUp
                    expanded: connPopup.opened
                    onClicked: connPopup.opened ? connPopup.close() : connPopup.open()
                    ConnectionPopup {
                        id: connPopup
                        x: connBtn.width - width
                        y: -height - 14
                        onApplyRequested: (s) => console.log("apply", JSON.stringify(s))
                    }
                }
                StatusBarButton { iconOnly: true; iconPath: Icons.bug; Accessible.name: qsTr("Debug settings") }
            }
        }

        GimbalInfoPage { anchors.fill: parent }
    }

    // Demo: TX/RX ledlerini yanıp söndür
    Timer { interval: 400; running: true; repeat: true; onTriggered: { txLed.pulse(); rxLed.pulse() } }
}
