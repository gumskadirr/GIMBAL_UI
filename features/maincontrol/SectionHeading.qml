import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Column heading of the Main control pages ("Board info", "Motor configuration", "Heater", ...).
ColumnLayout {
    id: heading
    property string title
    property string subtitle
    spacing: 2

    Text {
        text: heading.title
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsH2
        font.weight: Font.Bold
        color: Theme.text
    }
    Text {
        text: heading.subtitle
        visible: text !== ""
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsSmall
        color: Theme.muted
    }
}
