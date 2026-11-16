import QtQuick
import IDS_GIMBAL

// Common background of cards, KPI tiles and the stat strip (vertical gradient in the dark theme).
Rectangle {
    radius: Theme.rCard
    border.width: 1
    border.color: Theme.line
    gradient: Gradient {
        GradientStop { position: 0; color: Theme.cardTop }
        GradientStop { position: 1; color: Theme.cardBottom }
    }
}
