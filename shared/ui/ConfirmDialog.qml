import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import IDS_GIMBAL

// Modal confirmation before an action that is hard to undo (CommandButton opens it through confirmText).
// "Cancel" has the focus and Esc; "Confirm" emits confirmed() and closes. danger: red Confirm.
IdsPopup {
    id: dialog

    property string text: ""
    property string warning: ""
    property bool danger: false
    signal confirmed()

    parent: T.Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: 420
    onOpened: cancelButton.forceActiveFocus()

    Text {
        Layout.fillWidth: true
        text: dialog.text
        wrapMode: Text.WordWrap
        font.family: Theme.fontSans
        font.pixelSize: 13
        color: Theme.text
    }
    Hint {
        Layout.fillWidth: true
        visible: dialog.warning !== ""
        kind: "warning"
        text: dialog.warning
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 8
        Item { Layout.fillWidth: true }
        IdsButton {
            id: cancelButton
            objectName: "confirm-cancel"
            variant: "quiet"
            text: qsTr("Cancel")
            onClicked: dialog.close()
        }
        IdsButton {
            objectName: "confirm-accept"
            variant: dialog.danger ? "danger" : "primary"
            text: qsTr("Confirm")
            onClicked: { dialog.close(); dialog.confirmed() }
        }
    }
}
