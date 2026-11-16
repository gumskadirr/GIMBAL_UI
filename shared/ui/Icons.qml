pragma Singleton
import QtQuick

// Stroke icons in a 24x24 viewBox, from the final design. Usage: Icon { path: Icons.info }
QtObject {
    readonly property string info: "M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0M12 8v.01M11 12h1v5h1"
    readonly property string warning: "M12 3l9 16H3zM12 10v4M12 17v.01"
    readonly property string motor: "M4 12a8 8 0 1 0 16 0a8 8 0 1 0 -16 0M12 12l4-3"
    readonly property string sliders: "M5 4v16M12 4v16M19 4v16M3 9a2 2 0 1 0 4 0a2 2 0 1 0 -4 0M10 15a2 2 0 1 0 4 0a2 2 0 1 0 -4 0M17 7a2 2 0 1 0 4 0a2 2 0 1 0 -4 0"
    readonly property string heater: "M12 3v11M8.5 17a3.5 3.5 0 1 0 7 0a3.5 3.5 0 1 0 -7 0"
    readonly property string eye: "M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12zM9 12a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"
    readonly property string target: "M5 12a7 7 0 1 0 14 0a7 7 0 1 0 -14 0M10 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0M12 2v3M12 19v3M2 12h3M19 12h3"
    readonly property string list: "M8 6h12M8 12h12M8 18h12M3 6a1 1 0 1 0 2 0a1 1 0 1 0 -2 0M3 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0M3 18a1 1 0 1 0 2 0a1 1 0 1 0 -2 0"
    readonly property string chart: "M3 3v18h18M7 15l4-4 3 3 5-6"
    readonly property string sun: "M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"
    readonly property string drop: "M12 3c4 5 6 8 6 11a6 6 0 0 1-12 0c0-3 2-6 6-11z"
    readonly property string moon: "M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"
    readonly property string gimbal: "M8 3h8a1 1 0 0 1 1 1v3a1 1 0 0 1 -1 1h-8a1 1 0 0 1 -1 -1v-3a1 1 0 0 1 1 -1zM12 8v3M7 16a5 5 0 1 0 10 0a5 5 0 1 0 -10 0M10 16a2 2 0 1 0 4 0a2 2 0 1 0 -4 0"
    readonly property string chevronDown: "M6 9l6 6 6-6"
    readonly property string chevronUp: "M6 15l6-6 6 6"
    readonly property string resetView: "M4 4v6h6M20 12a8 8 0 0 0-14.9-4L4 10M4 12a8 8 0 0 0 14.9 4"
    readonly property string cube: "M12 3l8 4.5v9L12 21l-8-4.5v-9zM12 12l8-4.5M12 12v9M12 12L4 7.5"
    readonly property string file: "M6 3h8l4 4v14H6zM14 3v4h4"
    readonly property string bug: "M8 9a4 4 0 0 1 8 0v5a4 4 0 0 1-8 0zM12 9v9M4 13h4M16 13h4M5 7l3 2M19 7l-3 2M5 19l3-2M19 19l-3-2"
    readonly property string check: "M5 12l5 5L20 7"
    readonly property string close: "M6 6l12 12M18 6L6 18"
}
