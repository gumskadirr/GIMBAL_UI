import QtQuick
import IdsUi

// Kart, KPI ve durum şeridi için ortak zemin (koyu temada dikey gradyan).
Rectangle {
    radius: Theme.rCard
    border.width: 1
    border.color: Theme.line
    gradient: Gradient {
        GradientStop { position: 0; color: Theme.cardTop }
        GradientStop { position: 1; color: Theme.cardBottom }
    }
}
