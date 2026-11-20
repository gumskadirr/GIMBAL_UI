import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import IdsUi

// Radyo davranışlı büyük seçim kartı (başlangıç ekranında gimbal seçimi).
//   SelectableCard { title: "G180"; imageSource: "qrc:/img/g180.png"; checked: true
//                    trailing: Badge { text: "LAST USED" }
//                    Row { spacing: 8; ChoiceChip { text: "v1.0" } ChoiceChip { text: "v2.0" } } }
T.RadioButton {
    id: control

    property string title: text
    property url imageSource: ""
    property string imagePlaceholder: title + " image"
    property alias trailing: trailingRow.data
    default property alias extra: extraCol.data

    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: implicitContentHeight + topPadding + bottomPadding
    padding: 20
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Accessible.name: title

    indicator: null

    contentItem: ColumnLayout {
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: control.title
                elide: Text.ElideRight
                font.family: Theme.fontSans
                font.pixelSize: 24
                font.weight: Font.Bold
                color: Theme.text
            }
            Row { id: trailingRow; spacing: 10 }
            Rectangle {      // radyo göstergesi
                width: 18; height: 18; radius: 9
                color: "transparent"
                border.width: 2
                border.color: control.checked ? Theme.acc : Theme.line2
                Rectangle {
                    anchors.centerIn: parent
                    width: 8; height: 8; radius: 4
                    color: Theme.acc
                    visible: control.checked
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: width * 3 / 4
            radius: Theme.rInp
            color: Theme.raised
            border.width: 1
            border.color: Theme.line2
            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: control.imageSource
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: control.imageSource.toString() === ""
                Icon { anchors.horizontalCenter: parent.horizontalCenter; path: Icons.gimbal; color: Theme.muted; width: 28; height: 28 }
                Text { text: control.imagePlaceholder; font.family: Theme.fontSans; font.pixelSize: Theme.fsSmall; color: Theme.muted }
            }
        }
        ColumnLayout { id: extraCol; Layout.fillWidth: true; spacing: 8 }
    }

    background: CardBackground {
        border.width: control.checked ? 2 : 1
        border.color: control.checked ? Theme.acc : (control.hovered ? Theme.line2 : Theme.line)
        FocusRing { visible: control.visualFocus; baseRadius: Theme.rCard }
    }
}
