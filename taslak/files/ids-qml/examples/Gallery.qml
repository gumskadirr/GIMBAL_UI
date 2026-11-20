import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import IdsUi

// Tüm temel kontrollerin tek sayfada görünümü (tema denemesi için).
Window {
    width: 1280; height: 860; visible: true
    color: Theme.bg
    title: "IdsUi gallery"

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 48
        ColumnLayout {
            id: col
            x: 24; y: 24
            width: parent.width - 48
            spacing: 16

            RowLayout {
                spacing: 12
                ThemeSwitcher {}
                IdsButton { variant: "primary"; text: "Update firmware" }
                IdsButton { text: "Open file"; iconPath: Icons.file }
                IdsButton { variant: "quiet"; text: "Cancel" }
                IdsButton { variant: "danger"; text: "Stop" }
                IdsButton { compact: true; variant: "quiet"; iconPath: Icons.resetView; text: "Reset view" }
                Badge { kind: "ok"; text: "NORMAL" }
                Badge { kind: "warn"; text: "WARNING" }
                Badge { kind: "crit"; text: "FAULT" }
                Badge { kind: "info"; text: "NO BOOTLOADER" }
                StatusLabel { framed: true; status: "ok"; text: "Connected" }
                Kbd { text: "Esc" }
            }

            RowLayout {
                spacing: 16
                Card {
                    Layout.preferredWidth: 380; Layout.alignment: Qt.AlignTop
                    title: "Inputs"; subtitle: "Text, select, switch, slider"
                    FormField { Layout.fillWidth: true; label: "Model serial number"; IdsTextField { text: "MCB2-24-00142" } }
                    FormField { Layout.fillWidth: true; label: "Target position"; inline: true; IdsTextField { text: "124.500"; suffix: "°" } }
                    FormField { Layout.fillWidth: true; label: "Protocol"; IdsComboBox { model: ["UART", "IP/UDP", "TCP"] } }
                    ToggleRow { Layout.fillWidth: true; text: "Stabilization"; checked: true }
                    IdsSlider { Layout.fillWidth: true; from: 0; to: 100; value: 35 }
                    IdsProgressBar { Layout.fillWidth: true; value: 0.4; barHeight: 8 }
                    Hint { Layout.fillWidth: true; kind: "warning"; text: "Keep the board powered and connected until the update finishes." }
                }
                Card {
                    Layout.preferredWidth: 380; Layout.alignment: Qt.AlignTop
                    title: "Selection"
                    SegmentedControl { Layout.fillWidth: true; model: ["Position", "Speed", "Torque"] }
                    IdsTabs { Layout.fillWidth: true; model: ["Scope, 2 s", "FFT", "Bode sweep"] }
                    Row { spacing: 8; ChoiceChip { text: "v1.0" } ChoiceChip { text: "v2.0"; checked: true } ChoiceChip { text: "v3.0" } }
                    Zone {
                        Layout.fillWidth: true
                        RowLayout {
                            Text { text: "G1"; font.pixelSize: 20; font.weight: Font.Bold; color: Theme.text }
                            Item { Layout.fillWidth: true }
                            Text { text: "35%"; font.family: Theme.fontMono; font.pixelSize: 22; color: Theme.text }
                        }
                        IdsSlider { Layout.fillWidth: true; from: 0; to: 100; value: 35 }
                    }
                }
                Card {
                    Layout.preferredWidth: 380; Layout.alignment: Qt.AlignTop
                    flush: true; title: "Live view"
                    VideoViewport {
                        Layout.fillWidth: true; Layout.preferredHeight: 240
                        topRadius: 0; bottomRadius: Theme.rCard - 1
                        showCrosshair: true
                        OverlayTag { x: 12; y: 12; mono: true; text: "ROLL 0.0  TILT 0.0" }
                        OverlayTag { anchors.right: parent.right; anchors.rightMargin: 12; y: 12; text: "30 FPS · x1.0" }
                    }
                }
            }
            RowLayout {
                spacing: 16
                SelectableCard { Layout.preferredWidth: 300; title: "G160"
                    Row { spacing: 8; ChoiceChip { text: "v1.0" } ChoiceChip { text: "v2.0"; checked: true } } }
                SelectableCard { Layout.preferredWidth: 300; title: "G180"; checked: true
                    trailing: Badge { kind: "info"; text: "LAST USED" }
                    Row { spacing: 8; ChoiceChip { text: "v1.0" } ChoiceChip { text: "v2.0"; checked: true } ChoiceChip { text: "v3.0" } } }
            }
        }
    }
}
