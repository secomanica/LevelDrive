/*
 * SPDX-FileCopyrightText: 2026 Level Tecnologia
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Thin-stroke line icons for the Level Drive tray panel (24x24 grid, drawn natively, any colour).
 * The design system has no icon set of its own: "prefira ícones de traço fino e cantos arredondados,
 * numa só cor".
 */

import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string name: "file"
    property color color: "black"
    property real size: 20
    property real strokeWidth: 2

    implicitWidth: size
    implicitHeight: size

    readonly property string circle: "M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0"
    readonly property var paths: ({
        "close": "M6 6L18 18M18 6L6 18",
        "clock": circle + "M12 7v5l3 2",
        "sync": "M20 12a8 8 0 0 1-14 5.3M4 12a8 8 0 0 1 14-5.3M18 3v4h-4M6 21v-4h4",
        "check": circle + "M8 12.5l2.5 2.5L16 9.5",
        "warning": "M12 3.5L21.5 20h-19zM12 10v4M12 17.3v0.2",
        "trash": "M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13",
        "edit": "M4 20h4L19 9l-4-4L4 16zM14 6l4 4",
        "bell": "M6 16v-5a6 6 0 0 1 12 0v5l2 2H4zM10 20a2 2 0 0 0 4 0",
        "file": "M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8zM14 3v5h5",
        "pause": "M9 5v14M15 5v14",
        "play": "M8 5l11 7-11 7z",
        "activity": "M3 12h4l3-7 4 14 3-7h4",
        "settings": "M15 12a3 3 0 1 0-6 0a3 3 0 1 0 6 0M12 2v3M12 19v3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1L7 17M17 7l2.1-2.1",
        "help": circle + "M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-0.6 0.3-1 0.9-1 1.6v0.6M12 17.3v0.2",
        "more": "M6 12h0.2M12 12h0.2M18 12h0.2",
        "cloud": "M7 18a5 5 0 0 1-0.6-9.96A6 6 0 0 1 18 9a4.5 4.5 0 0 1-0.5 9zM9.5 13l2 2 3.5-3.5",
        "offline": "M7 18a5 5 0 0 1-0.6-9.96A6 6 0 0 1 18 9a4.5 4.5 0 0 1-0.5 9zM4 4l16 16"
    })

    Shape {
        width: 24
        height: 24
        preferredRendererType: Shape.CurveRenderer
        transform: Scale { xScale: root.size / 24; yScale: root.size / 24 }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.strokeWidth * (root.name === "more" ? 1.3 : 1)
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.paths[root.name] !== undefined ? root.paths[root.name] : root.paths["file"] }
        }
    }
}
