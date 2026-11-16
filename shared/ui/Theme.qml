pragma Singleton
import QtQuick

// IDS Control design tokens, taken unchanged from the final design (taslak/files/ids-qml/IdsUi/Theme.qml).
// Theme.mode is bound to AppSettings.theme in Main.qml; nothing else writes it.
// Palettes are untyped maps: a misspelled key yields an invalid color, so tst_theme.qml checks every mode.
QtObject {
    id: theme

    property string mode: "light"

    readonly property var _palettes: ({
        light: {
            bg: "#F4F4F5", rail: "#FFFFFF", card: "#FFFFFF", raised: "#FAFAFA", input: "#F4F4F5",
            line: "#E4E4E7", line2: "#D4D4D8", div: "#E4E4E7",
            text: "#111113", text2: "#27272A", muted: "#6B6B73", label: "#71717A",
            acc: "#3B3FB0", accHover: "#4A4FCC",
            navOn: "#EEF0FF", navRing: "#C7CAF5", navOnText: "#2B2E83",
            segOn: "#3B3FB0", segOnText: "#FFFFFF",
            gauge: "#4F55D6", track: "#E4E4E7", tx: "#2563EB", rx: "#16A34A",
            okTx: "#047857", okBg: "#D1FAE5", okBd: "#A7F3D0",
            warnTx: "#B45309", warnBg: "#FEF3C7", warnBd: "#FDE68A",
            critTx: "#B91C1C", critBg: "#FEE2E2", critBd: "#FECACA",
            infoTx: "#1D4ED8", infoBg: "#DBEAFE", infoBd: "#BFDBFE",
            idle: "#A1A1AA", cardTop: "#FFFFFF", cardBottom: "#FFFFFF",
            s2: "#9E1F63", shadow: "#24111113"
        },
        blue: {
            bg: "#10111B", rail: "#0D0E24", card: "#151623", raised: "#1A1B2A", input: "#1D2033",
            line: "#232538", line2: "#2A2D45", div: "#1E2036",
            text: "#FFFFFF", text2: "#E8EAF2", muted: "#9497B0", label: "#8487A3",
            acc: "#4F55D6", accHover: "#6268E6",
            navOn: "#22254A", navRing: "#22254A", navOnText: "#FFFFFF",
            segOn: "#2E3158", segOnText: "#FFFFFF",
            gauge: "#38BDF8", track: "#23263C", tx: "#60A5FA", rx: "#10B981",
            okTx: "#34D399", okBg: "#0E2620", okBd: "#155E4A",
            warnTx: "#FBBF24", warnBg: "#2A2010", warnBd: "#5A4214",
            critTx: "#F87171", critBg: "#2A1218", critBd: "#5C1D24",
            infoTx: "#93C5FD", infoBg: "#141E36", infoBd: "#24396B",
            idle: "#5A5D78", cardTop: "#151623", cardBottom: "#151623",
            s2: "#F472B6", shadow: "#8C000000"
        },
        dark: {
            bg: "#000000", rail: "#101010", card: "#0A0A0A", raised: "#141414", input: "#1C1C1C",
            line: "#1F1F1F", line2: "#2A2A2A", div: "#1A1A1A",
            text: "#FFFFFF", text2: "#EDEDED", muted: "#A3A3A3", label: "#8A8A8A",
            acc: "#4A4FCC", accHover: "#5A5FD8",
            navOn: "#16173A", navRing: "#2B2E6B", navOnText: "#FFFFFF",
            segOn: "#4A4FCC", segOnText: "#FFFFFF",
            gauge: "#7C80E6", track: "#1C1C1C", tx: "#7C80E6", rx: "#10B981",
            okTx: "#34D399", okBg: "#0E2620", okBd: "#155E4A",
            warnTx: "#FBBF24", warnBg: "#2A2010", warnBd: "#5A4214",
            critTx: "#F87171", critBg: "#2A1218", critBd: "#5C1D24",
            infoTx: "#B4B7F2", infoBg: "#16173A", infoBd: "#2B2E6B",
            idle: "#5C5C5C", cardTop: "#141414", cardBottom: "#0A0A0A",
            s2: "#C2477F", shadow: "#99000000"
        }
    })
    readonly property var _p: _palettes[mode] || _palettes.light

    // Yüzeyler
    readonly property color bg: _p.bg
    readonly property color rail: _p.rail
    readonly property color card: _p.card
    readonly property color cardTop: _p.cardTop        // koyu temada kart dikey gradyan
    readonly property color cardBottom: _p.cardBottom
    readonly property color raised: _p.raised
    readonly property color input: _p.input
    readonly property color line: _p.line
    readonly property color line2: _p.line2
    readonly property color div: _p.div
    readonly property color shadowColor: _p.shadow
    readonly property bool cardShadow: mode === "light"

    // Metin
    readonly property color text: _p.text
    readonly property color text2: _p.text2
    readonly property color muted: _p.muted
    readonly property color label: _p.label

    // Vurgu ve kontroller
    readonly property color acc: _p.acc
    readonly property color accHover: _p.accHover
    readonly property color navOn: _p.navOn
    readonly property color navRing: _p.navRing
    readonly property color navOnText: _p.navOnText
    readonly property color segOn: _p.segOn
    readonly property color segOnText: _p.segOnText
    readonly property color gauge: _p.gauge
    readonly property color track: _p.track
    readonly property color tx: _p.tx
    readonly property color rx: _p.rx
    readonly property color idle: _p.idle
    readonly property color series2: _p.s2

    // Durum tonları (rozet, bilgi kutusu)
    readonly property color okTx: _p.okTx
    readonly property color okBg: _p.okBg
    readonly property color okBd: _p.okBd
    readonly property color warnTx: _p.warnTx
    readonly property color warnBg: _p.warnBg
    readonly property color warnBd: _p.warnBd
    readonly property color critTx: _p.critTx
    readonly property color critBg: _p.critBg
    readonly property color critBd: _p.critBd
    readonly property color infoTx: _p.infoTx
    readonly property color infoBg: _p.infoBg
    readonly property color infoBd: _p.infoBd

    // Temadan bağımsız sabitler
    readonly property color danger: "#E4252B"
    readonly property color brandRed: "#E4252B"
    readonly property color brandMagenta: "#9E1F63"
    readonly property color brandIndigo: "#3B3FB0"
    readonly property color dotOk: "#10B981"
    readonly property color dotWarn: "#F59E0B"
    readonly property color dotCrit: "#EF4444"
    readonly property color dotInfo: "#60A5FA"
    readonly property color viewportBg: "#07070C"
    readonly property color viewportDot: "#1A1A26"

    // Köşe yarıçapları
    readonly property int rBtn: 10
    readonly property int rCard: 16
    readonly property int rInp: 10
    readonly property int rSmall: 6

    // Ölçüler
    readonly property int controlHeight: 40
    readonly property int controlHeightSm: 32
    readonly property int touchMin: 44

    // Spacing (not in the design file; used by the app's own pages)
    readonly property int spacingSmall: 4
    readonly property int spacingNormal: 8
    readonly property int spacingLarge: 16

    // Tipografi
    readonly property string fontSans: "Inter"
    readonly property string fontMono: "JetBrains Mono"
    readonly property int fsOverline: 11     // KL etiketleri (BÜYÜK HARF)
    readonly property int fsSmall: 12
    readonly property int fsBody: 13
    readonly property int fsTitle: 16        // kart başlığı
    readonly property int fsH2: 18
    readonly property int fsKpi: 26
    readonly property real overlineSpacing: 0.88   // 0.08em @ 11px

    // "ok" | "warn" | "crit" | "info" | "neutral"
    function tone(kind) {
        switch (kind) {
        case "ok": case "pass": case "success":
            return { fg: okTx, bg: okBg, border: okBd }
        case "warn": case "warning":
            return { fg: warnTx, bg: warnBg, border: warnBd }
        case "crit": case "error": case "fail":
            return { fg: critTx, bg: critBg, border: critBd }
        case "neutral": case "idle":
            return { fg: text2, bg: input, border: line2 }
        default:
            return { fg: infoTx, bg: infoBg, border: infoBd }
        }
    }

    // Durum noktası rengi
    function stateColor(status) {
        switch (status) {
        case "ok": case "pass": case "success": case "connected": return dotOk
        case "warn": case "warning": case "locked": return dotWarn
        case "crit": case "error": case "fail": return dotCrit
        case "info": return dotInfo
        default: return idle
        }
    }

    // Durum metni rengi (BIT kutucukları vb.)
    function stateTextColor(status) {
        switch (status) {
        case "ok": case "pass": case "success": return okTx
        case "warn": case "warning": return warnTx
        case "crit": case "error": case "fail": return critTx
        default: return text2
        }
    }
}
