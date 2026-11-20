pragma Singleton
import QtQuick

// Number display in the UI language: Turkish 124,496 / English 124.496 (architecture §10).
// Only for the screen; files and device messages keep a language independent format.
// No thousands separator: in Turkish "1.234" would read as a decimal in English and vice versa.
QtObject {
    property string language: "en" // bound to Localization.language in Main.qml

    function fixed(value: real, decimals: int): string {
        let rounded = Number(value.toFixed(decimals))
        if (rounded === 0)
            rounded = 0 // -0.0001 shows as 0.000, never -0.000
        const text = rounded.toFixed(decimals)
        return language === "tr" ? text.replace(".", ",") : text
    }

    // Reads what fixed() shows: only the language's own decimal separator is accepted. NaN when it is not a number.
    function parse(text: string): real {
        const t = text.trim()
        const wrongSeparator = language === "tr" ? "." : ","
        if (t.includes(wrongSeparator))
            return NaN
        return /^[+-]?(\d+[.,]?\d*|[.,]\d+)$/.test(t) ? Number(t.replace(",", ".")) : NaN
    }
}
