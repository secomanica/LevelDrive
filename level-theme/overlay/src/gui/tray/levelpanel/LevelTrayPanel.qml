/*
 * SPDX-FileCopyrightText: 2026 Level Tecnologia
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Level Drive tray panel (window shown when the tray icon is clicked). Data and actions come from
 * OCC::LevelTrayPanel (src/gui/tray/leveltraypanel.cpp), passed in as "panel".
 * Approved mock-up: "Painel da bandeja Level Drive" (claro, com pendências, escuro).
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Style

Window {
    id: root

    property var panel

    // panel states (OCC::LevelTrayPanel::State)
    readonly property int stateAllSynced: 0
    readonly property int stateSyncing: 1
    readonly property int stateNeedsAttention: 2
    readonly property int statePaused: 3
    readonly property int stateOffline: 4

    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    title: panel ? panel.appName : ""
    width: 400
    height: Math.min(card.implicitHeight, Screen.desktopAvailableHeight - 24)

    // Level design system tokens (light / dark); contrast >= 4.5:1 for every text pair
    QtObject {
        id: lv
        readonly property bool dark: Style.darkMode
        readonly property color surface: dark ? "#222323" : "#EFEFEF"
        readonly property color raised: dark ? "#2F3030" : "#FFFFFF"
        readonly property color ink: dark ? "#EFEFEF" : "#222323"
        readonly property color inkMuted: dark ? "#B6B6B6" : "#5B5C5C"
        readonly property color heading: dark ? "#83C8B4" : "#103B40"
        readonly property color accent: "#53AE93"
        readonly property color accentHover: "#6FBDA5"
        readonly property color accentText: "#103B40"
        readonly property color focus: dark ? "#83C8B4" : "#103B40"
        readonly property color line: dark ? Qt.rgba(0.937, 0.937, 0.937, 0.18) : Qt.rgba(0.133, 0.137, 0.137, 0.16)
        readonly property color hover: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
        readonly property color danger: dark ? "#F08A82" : "#B3362F"
        readonly property color dangerBorder: dark ? "#7A3A36" : "#E8B4AF"
        readonly property color soft: dark ? "#103B40" : "#83C8B4"
        readonly property color softInk: dark ? "#EFEFEF" : "#222323"
        readonly property color avatar: dark ? "#83C8B4" : "#103B40"
        readonly property color avatarText: dark ? "#103B40" : "#EFEFEF"
        readonly property color queueTint: dark ? "#3A3220" : "#FBF1DC"
        readonly property color queueIcon: dark ? "#E0A526" : "#8A5A00"
        readonly property color syncTint: dark ? "#1C3A3C" : "#DCEFE9"
        readonly property color syncIcon: dark ? "#83C8B4" : "#103B40"
        readonly property color doneTint: dark ? "#1F3A31" : "#E3F2EC"
        readonly property color doneIcon: dark ? "#53AE93" : "#2E7D66"
        readonly property color failTint: dark ? "#3D2423" : "#FBE4E2"
        readonly property color deep: "#103B40"
        readonly property color deepText: "#EFEFEF"
        readonly property color deepTextMuted: "#C9DDD7"
    }

    Shortcut {
        sequences: [StandardKey.Close, "Esc"]
        onActivated: root.panel.close()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        implicitHeight: content.implicitHeight + 30
        radius: 16
        color: lv.surface
        border.width: 1
        border.color: lv.line
        clip: true

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 18
            spacing: 12

            // ---------------------------------------------------------- header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Image {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 2
                    // official symbol files, unchanged (level-brand); only scaled
                    source: lv.dark ? "level-simbolo-cor-negativo.svg" : "level-simbolo-cor.svg"
                    sourceSize.width: 36
                    sourceSize.height: 41
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 41
                    fillMode: Image.PreserveAspectFit
                    Accessible.ignored: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8
                        Text {
                            text: root.panel ? root.panel.appName : ""
                            font.pixelSize: 21
                            font.bold: true
                            font.letterSpacing: -0.2
                            color: lv.heading
                            Accessible.role: Accessible.Heading
                        }
                        Text {
                            text: root.panel ? root.panel.version : ""
                            font.pixelSize: 11
                            color: lv.inkMuted
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.panel ? root.panel.statusText : ""
                        font.pixelSize: 13
                        font.bold: root.panel && root.panel.state === root.stateNeedsAttention
                        color: root.panel && root.panel.state === root.stateNeedsAttention ? lv.danger : lv.inkMuted
                        elide: Text.ElideRight
                    }
                }

                AbstractButton {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 32
                    implicitHeight: 32
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Close")
                    onClicked: root.panel.close()
                    contentItem: Item {
                        LevelIcon { anchors.centerIn: parent; name: "close"; size: 16; color: lv.inkMuted }
                    }
                    background: Rectangle {
                        radius: 8
                        color: parent.hovered ? lv.hover : "transparent"
                        border.width: parent.visualFocus ? 2 : 0
                        border.color: lv.focus
                    }
                }
            }

            // ---------------------------------------------------------- account
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: accountRow.implicitHeight + 20
                radius: 12
                color: lv.raised
                border.width: 1
                border.color: lv.line

                RowLayout {
                    id: accountRow
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 16
                        color: lv.avatar
                        Text {
                            anchors.centerIn: parent
                            text: root.panel ? root.panel.userInitials : ""
                            font.pixelSize: 13
                            font.bold: true
                            color: lv.avatarText
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: root.panel ? root.panel.userName : ""
                            font.pixelSize: 14
                            font.bold: true
                            color: lv.ink
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.panel ? root.panel.userDetail : ""
                            font.pixelSize: 12
                            color: lv.inkMuted
                            elide: Text.ElideMiddle
                        }
                    }
                    Rectangle {
                        visible: serverLabel.text.length > 0
                        implicitWidth: serverLabel.implicitWidth + 20
                        implicitHeight: 20
                        radius: 10
                        color: lv.soft
                        Text {
                            id: serverLabel
                            anchors.centerIn: parent
                            text: root.panel ? root.panel.serverName : ""
                            font.pixelSize: 12
                            color: lv.softInk
                        }
                    }
                }
            }

            // ---------------------------------------------------------- main actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                LevelPillButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 16
                    theme: lv
                    primary: true
                    enabled: root.panel && root.panel.hasLocalFolder
                    text: qsTr("Open %1 folder").arg(root.panel ? root.panel.appName : "")
                    onClicked: root.panel.openFolder()
                }
                LevelPillButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 10
                    theme: lv
                    primary: false
                    text: qsTr("In browser")
                    onClicked: root.panel.openInBrowser()
                }
            }

            // ---------------------------------------------------------- counters
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 8

                LevelStatCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    theme: lv
                    label: qsTr("Queued")
                    value: root.panel ? root.panel.queued : 0
                    iconName: "clock"
                    tint: lv.queueTint
                    iconColor: lv.queueIcon
                }
                LevelStatCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    theme: lv
                    label: qsTr("In progress")
                    value: root.panel ? root.panel.inProgress : 0
                    iconName: "sync"
                    tint: lv.syncTint
                    iconColor: lv.syncIcon
                }
                LevelStatCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    theme: lv
                    label: qsTr("Today")
                    value: root.panel ? root.panel.completedToday : 0
                    iconName: "check"
                    tint: lv.doneTint
                    iconColor: lv.doneIcon
                }
                LevelStatCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    theme: lv
                    label: qsTr("Failures")
                    value: root.panel ? root.panel.failures : 0
                    iconName: "warning"
                    tint: lv.failTint
                    iconColor: lv.danger
                }
            }

            // ---------------------------------------------------------- progress
            Rectangle {
                Layout.fillWidth: true
                visible: root.panel && root.panel.showProgress
                implicitHeight: progressColumn.implicitHeight + 24
                radius: 12
                color: lv.raised
                border.width: 1
                border.color: lv.line

                ColumnLayout {
                    id: progressColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Sync progress")
                            font.pixelSize: 15
                            font.bold: true
                            color: lv.heading
                            elide: Text.ElideRight
                        }
                        Text {
                            text: root.panel ? qsTr("%1 of %2").arg(root.panel.progressDone.toLocaleString(Qt.locale(), "f", 0))
                                                                .arg(root.panel.progressTotal.toLocaleString(Qt.locale(), "f", 0)) : ""
                            font.pixelSize: 13
                            color: lv.inkMuted
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: 4
                        color: lv.line
                        Rectangle {
                            width: root.panel && root.panel.progressTotal > 0
                                   ? parent.width * Math.min(1, root.panel.progressDone / root.panel.progressTotal) : 0
                            height: parent.height
                            radius: 4
                            color: lv.accent
                            Behavior on width { NumberAnimation { duration: 200 } }
                        }
                        Accessible.role: Accessible.ProgressBar
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: root.panel ? root.panel.currentItemText : ""
                        font.pixelSize: 12
                        color: lv.inkMuted
                        elide: Text.ElideMiddle
                    }
                }
            }

            // ---------------------------------------------------------- all good banner
            Rectangle {
                Layout.fillWidth: true
                visible: root.panel && root.panel.state === root.stateAllSynced
                implicitHeight: 52
                radius: 12
                color: lv.deep

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12
                    LevelIcon { name: "cloud"; size: 22; color: "#83C8B4" }
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Your files are up to date")
                        font.pixelSize: 14
                        font.bold: true
                        color: lv.deepText
                        elide: Text.ElideRight
                    }
                }
            }

            // ---------------------------------------------------------- issues
            Rectangle {
                Layout.fillWidth: true
                visible: root.panel && root.panel.issues.length > 0
                implicitHeight: issuesColumn.implicitHeight + 24
                radius: 12
                color: lv.raised
                border.width: 1
                border.color: lv.dangerBorder

                ColumnLayout {
                    id: issuesColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 4
                        text: qsTr("Needs your attention (%1)").arg(root.panel ? root.panel.issues.length : 0)
                        font.pixelSize: 15
                        font.bold: true
                        color: lv.heading
                        elide: Text.ElideRight
                        Accessible.role: Accessible.Heading
                    }

                    Repeater {
                        model: root.panel ? root.panel.issues.slice(0, 3) : []
                        delegate: RowLayout {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spacing: 10

                            LevelIcon { name: "file"; size: 20; strokeWidth: 1.8; color: lv.inkMuted }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.file
                                    font.pixelSize: 13
                                    color: lv.ink
                                    elide: Text.ElideMiddle
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.reason
                                    font.pixelSize: 12
                                    color: lv.danger
                                    elide: Text.ElideRight
                                    ToolTip.visible: reasonArea.containsMouse && truncated
                                    ToolTip.text: modelData.reason
                                    MouseArea { id: reasonArea; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                                }
                            }
                            LevelPillButton {
                                theme: lv
                                small: true
                                primary: modelData.conflict
                                text: modelData.conflict ? qsTr("Resolve") : qsTr("Details")
                                onClicked: modelData.conflict ? root.panel.resolveConflicts() : root.panel.openActivities()
                            }
                        }
                    }

                    LevelPillButton {
                        visible: root.panel && root.panel.issues.length > 3
                        Layout.alignment: Qt.AlignRight
                        theme: lv
                        small: true
                        primary: false
                        text: qsTr("See all")
                        onClicked: root.panel.openActivities()
                    }
                }
            }

            // ---------------------------------------------------------- recent events
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: eventsColumn.implicitHeight + 24
                radius: 12
                color: lv.raised
                border.width: 1
                border.color: lv.line

                ColumnLayout {
                    id: eventsColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 6
                        text: qsTr("Recent events")
                        font.pixelSize: 15
                        font.bold: true
                        color: lv.heading
                        Accessible.role: Accessible.Heading
                    }

                    Text {
                        visible: !root.panel || root.panel.events.length === 0
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        text: qsTr("No recent events")
                        font.pixelSize: 13
                        color: lv.inkMuted
                    }

                    Repeater {
                        model: root.panel ? root.panel.events : []
                        delegate: AbstractButton {
                            id: eventRow
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: eventLayout.implicitHeight + 12
                            hoverEnabled: true
                            focusPolicy: Qt.StrongFocus
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.title + " " + modelData.subtitle + " " + modelData.time
                            onClicked: root.panel.openActivities()

                            background: Rectangle {
                                color: eventRow.hovered ? lv.hover : "transparent"
                                radius: 6
                                border.width: eventRow.visualFocus ? 2 : 0
                                border.color: lv.focus
                                Rectangle {
                                    visible: eventRow.index < (root.panel ? root.panel.events.length - 1 : 0)
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 1
                                    color: lv.line
                                }
                            }

                            contentItem: RowLayout {
                                id: eventLayout
                                spacing: 10
                                LevelIcon {
                                    Layout.alignment: Qt.AlignVCenter
                                    name: eventRow.modelData.kind
                                    size: 18
                                    color: eventRow.modelData.kind === "warning" ? lv.danger
                                         : eventRow.modelData.kind === "trash" ? lv.inkMuted
                                         : lv.doneIcon
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        Layout.fillWidth: true
                                        text: eventRow.modelData.title
                                        font.pixelSize: 13
                                        color: lv.ink
                                        elide: Text.ElideMiddle
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                        text: eventRow.modelData.subtitle
                                        font.pixelSize: 12
                                        color: lv.inkMuted
                                        elide: Text.ElideRight
                                    }
                                }
                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: eventRow.modelData.time
                                    font.pixelSize: 12
                                    color: lv.inkMuted
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------------- footer
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: lv.line
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                LevelFooterButton {
                    Layout.fillWidth: true
                    theme: lv
                    visible: root.panel && root.panel.canPause
                    iconName: root.panel && root.panel.paused ? "play" : "pause"
                    text: root.panel && root.panel.paused ? qsTr("Resume") : qsTr("Pause")
                    onClicked: root.panel.togglePause()
                }
                LevelFooterButton {
                    Layout.fillWidth: true
                    theme: lv
                    iconName: "activity"
                    text: qsTr("Activity")
                    onClicked: root.panel.openActivities()
                }
                LevelFooterButton {
                    Layout.fillWidth: true
                    theme: lv
                    iconName: "settings"
                    text: qsTr("Settings")
                    onClicked: root.panel.openSettings()
                }
                LevelFooterButton {
                    Layout.fillWidth: true
                    theme: lv
                    iconName: "help"
                    text: qsTr("Help")
                    onClicked: root.panel.openHelp()
                }
                LevelFooterButton {
                    id: moreButton
                    Layout.fillWidth: true
                    theme: lv
                    iconName: "more"
                    text: qsTr("More")
                    onClicked: root.panel.showMoreMenu(moreButton.mapToGlobal(0, 0))
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.panel ? root.panel.lastUploadText : ""
                font.pixelSize: 12
                color: lv.inkMuted
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }
}
