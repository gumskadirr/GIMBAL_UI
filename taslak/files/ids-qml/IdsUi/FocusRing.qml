import QtQuick
import IdsUi

// Klavye odağı halkası: 2 px vurgu rengi, 2 px boşluk.
Rectangle {
    property Item target: parent
    property real baseRadius: Theme.rBtn
    anchors.fill: parent
    anchors.margins: -4
    radius: baseRadius + 4
    color: "transparent"
    border.width: 2
    border.color: Theme.acc
}
