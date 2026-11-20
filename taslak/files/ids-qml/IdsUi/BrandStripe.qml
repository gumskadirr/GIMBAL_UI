import QtQuick
import IdsUi

// Ekranın üstü ve altındaki 3 px marka şeridi.
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
