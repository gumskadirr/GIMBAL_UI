import QtQuick
import IDS_GIMBAL

// Left navigation: 64 px collapsed, 248 px on hover or keyboard focus (drawn over the content).
// Holds RailBrand, NavSection and NavItem; children with a `rail` property get it set automatically.
Item {
    id: root

    property bool pinned: false
    property real collapsedWidth: 64
    property real expandedWidth: 248
    property bool focusWithin: false
    readonly property bool expanded: pinned || hover.hovered || focusWithin
    default property alias items: column.data

    implicitWidth: collapsedWidth   // the space reserved in the layout
    // Clicks only reached items inside the root's bounds (verified on Qt 6.12), so the root grows with the
    // panel; otherwise the expanded part of every NavItem ignored the mouse.
    width: panel.width
    z: 20
    Accessible.role: Accessible.Pane
    Accessible.name: qsTr("Main navigation")

    function _bind() {
        for (let i = 0; i < column.children.length; ++i) {
            const c = column.children[i]
            if (c.hasOwnProperty("rail")) c.rail = root
        }
    }
    Component.onCompleted: _bind()

    Shadow {
        anchors.fill: panel
        radius: 0
        offsetY: 0
        offsetX: 4
        opacity: panel.width > root.collapsedWidth + 1 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Rectangle {
        id: panel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.expanded ? root.expandedWidth : root.collapsedWidth
        color: Theme.rail
        clip: true
        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        HoverHandler { id: hover }

        Column {
            id: column
            x: 12
            y: 16
            width: root.expandedWidth - 24
            spacing: 2
            onChildrenChanged: root._bind()
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Theme.div
        }
    }
}
