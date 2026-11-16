import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Bottom status bar; holds StatusBarSection items.
Rectangle {
    id: root
    default property alias sections: row.data

    implicitHeight: Math.max(44, row.implicitHeight) + 1
    color: Theme.rail

    function _sync() {
        const n = row.children.length
        for (let i = 0; i < n; ++i)
            if (row.children[i].hasOwnProperty("showDivider"))
                row.children[i].showDivider = i < n - 1
    }
    Component.onCompleted: _sync()

    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 1
        color: Theme.div
    }
    RowLayout {
        id: row
        anchors.fill: parent
        anchors.topMargin: 1
        spacing: 0
        onChildrenChanged: root._sync()
    }
}
