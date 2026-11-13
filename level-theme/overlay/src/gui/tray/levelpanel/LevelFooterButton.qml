/*
 * SPDX-FileCopyrightText: 2026 Level Tecnologia
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls

AbstractButton {
    id: root

    property var theme
    property string iconName

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    implicitHeight: 52
    implicitWidth: 64

    Accessible.role: Accessible.Button
    Accessible.name: text

    contentItem: Column {
        spacing: 4
        LevelIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.iconName
            color: root.theme.ink
            size: 20
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.width - 4
            text: root.text
            font.pixelSize: 11
            color: root.theme.ink
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    background: Rectangle {
        radius: 10
        color: root.down || root.hovered ? root.theme.hover : "transparent"
        border.width: root.visualFocus ? 2 : 0
        border.color: root.theme.focus
    }
}
