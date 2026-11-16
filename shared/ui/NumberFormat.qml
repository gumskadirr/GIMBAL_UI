pragma Singleton
import QtQuick

// Number display in the UI language: Turkish 124,496 / English 124.496 (architecture §10).
// Only for the screen; files and device messages keep a language independent format.
QtObject {
    property string language: "en" // bound to Localization.language in Main.qml
    readonly property var _locale: Qt.locale(language === "tr" ? "tr_TR" : "en_US")

    function fixed(value: real, decimals: int): string {
        return value.toLocaleString(_locale, "f", decimals)
    }
}
