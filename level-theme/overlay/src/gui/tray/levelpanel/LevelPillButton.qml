/*
 * SPDX-FileCopyrightText: 2026 Level Tecnologia
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Pill button of the Level design system (Button: primary = accent with on-accent text, never white
 * on the green; secondary = outline in ink).
 */

import QtQuick
import QtQuick.Controls

AbstractButton {
    id: root

    property var theme
    property bool primary: true
    property bool small: false

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: small ? 30 : 40
    implicitWidth: label.implicitWidth + (small ? 28 : 40)
    opacity: enabled ? 1 : 0.45

    Accessible.role: Accessible.Button
    Accessible.name: text

    contentItem: Text {
        id: label
        text: root.text
        font.pixelSize: root.small ? 13 : 14
        font.bold: true
        color: root.primary ? root.theme.accentText : root.theme.ink
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: height / 2
        color: root.primary
               ? (root.down ? Qt.darker(root.theme.accent, 1.08) : root.hovered ? root.theme.accentHover : root.theme.accent)
               : (root.down || root.hovered ? root.theme.hover : "transparent")
        border.width: root.primary ? 0 : 1.5
        border.color: root.theme.ink

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: height / 2
            color: "transparent"
            border.width: 2
            border.color: root.theme.focus
            visible: root.visualFocus
        }
    }
}
