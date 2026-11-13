/*
 * SPDX-FileCopyrightText: 2026 Level Tecnologia
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Counter card. Tinted only when the value is above zero; neutral (raised surface) otherwise.
 */

import QtQuick

Rectangle {
    id: root

    property var theme
    property string label
    property int value: 0
    property string iconName
    property color tint
    property color iconColor

    readonly property bool active: value > 0

    implicitHeight: column.implicitHeight + 20
    radius: 12
    color: active ? tint : theme.raised
    border.width: active ? 0 : 1
    border.color: theme.line

    Accessible.role: Accessible.StaticText
    Accessible.name: label + ": " + value

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        LevelIcon {
            name: root.iconName
            color: root.active ? root.iconColor : root.theme.inkMuted
            size: 18
        }
        Text {
            width: parent.width
            text: root.label
            font.pixelSize: 12
            color: root.theme.ink
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.value.toLocaleString(Qt.locale(), "f", 0)
            font.pixelSize: 22
            font.weight: Font.ExtraBold
            color: root.theme.ink
            elide: Text.ElideRight
        }
    }
}
