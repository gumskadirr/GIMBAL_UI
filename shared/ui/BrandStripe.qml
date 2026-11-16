import QtQuick
import IDS_GIMBAL

// 3 px brand stripe at the top and bottom of the window.
Rectangle {
    implicitHeight: 3
    implicitWidth: 100
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Theme.brandRed }
        GradientStop { position: 0.5; color: Theme.brandMagenta }
        GradientStop { position: 1.0; color: Theme.brandIndigo }
    }
}
