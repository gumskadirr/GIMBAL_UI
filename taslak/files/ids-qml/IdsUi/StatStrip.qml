import QtQuick
import QtQuick.Layouts
import IdsUi

// Sayfa üstündeki yatay durum şeridi. İçine StatCell öğeleri konur;
// son hücrenin ayırıcısı otomatik gizlenir.
CardBackground {
    id: root
    default property alias cells: row.data

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    function _sync() {
        const n = row.children.length
        for (let i = 0; i < n; ++i)
            if (row.children[i].hasOwnProperty("showDivider"))
                row.children[i].showDivider = i < n - 1
    }
    Component.onCompleted: _sync()

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 0
        onChildrenChanged: root._sync()
    }
}
