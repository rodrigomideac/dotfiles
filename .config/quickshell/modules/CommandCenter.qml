import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs

PanelWindow {
    id: win

    property bool opened: false
    readonly property string scripts: `${Quickshell.env("HOME")}/.config/niri/scripts`

    // Full-screen surface so the scrim can catch a click anywhere outside the
    // panel; Ignore keeps niri from reserving a strut for it.
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: true
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "command-center"

    onOpenedChanged: {
        if (win.opened) {
            win.visible = true;
            fade.to = 1;
        } else {
            fade.to = 0;
        }
        fade.restart();
    }

    NumberAnimation {
        id: fade
        target: shade
        property: "opacity"
        duration: 170
        easing.type: Easing.OutCubic
        onFinished: if (fade.to === 0) win.visible = false
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        id: shade
        anchors.fill: parent
        opacity: 0
        focus: true

        Keys.onEscapePressed: win.opened = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.45

            MouseArea {
                anchors.fill: parent
                onClicked: win.opened = false
            }
        }

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: 760
            implicitHeight: body.implicitHeight + Theme.pad * 2
            height: implicitHeight

            color: Theme.bg
            radius: Theme.radius + 6
            border.width: 1
            border.color: Theme.border

            // Tied to the fade so the panel rises into place on one animation
            // instead of two that can drift apart.
            scale: 0.97 + 0.03 * shade.opacity

            ColumnLayout {
                id: body
                anchors.fill: parent
                anchors.margins: Theme.pad
                spacing: Theme.gap

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 2

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: {
                                const h = clock.date.getHours();
                                if (h < 5) return "Still up";
                                if (h < 12) return "Good morning";
                                if (h < 18) return "Good afternoon";
                                return "Good evening";
                            }
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: Quickshell.env("USER") ?? ""
                            color: Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: 12
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: Qt.formatDateTime(clock.date, "ddd d MMM")
                            color: Theme.fgDim
                            font.family: Theme.font
                            font.pixelSize: 12
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gap

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: Theme.gap

                        SystemCard { Layout.fillWidth: true }
                        PowerCard { Layout.fillWidth: true }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: Theme.gap

                        VolumeCard { Layout.fillWidth: true }

                        Card {
                            Layout.fillWidth: true
                            title: "Actions"

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 3
                                rowSpacing: 10
                                columnSpacing: 10

                                ActionTile {
                                    Layout.fillWidth: true
                                    glyph: "󰆍"
                                    label: "Terminal"
                                    accent: Theme.green
                                    command: [`${win.scripts}/alacritty_launcher.sh`]
                                    onActivated: win.opened = false
                                }

                                ActionTile {
                                    Layout.fillWidth: true
                                    glyph: "󰀻"
                                    label: "Launcher"
                                    accent: Theme.blue
                                    command: ["fuzzel"]
                                    onActivated: win.opened = false
                                }

                                ActionTile {
                                    Layout.fillWidth: true
                                    glyph: "󰄲"
                                    label: "Todo"
                                    accent: Theme.yellow
                                    command: [`${win.scripts}/todo_scratchpad.sh`]
                                    onActivated: win.opened = false
                                }

                                ActionTile {
                                    Layout.fillWidth: true
                                    glyph: "󰭹"
                                    label: "Claude"
                                    accent: Theme.orange
                                    command: [`${win.scripts}/claude_scratchpad.sh`]
                                    onActivated: win.opened = false
                                }

                                ActionTile {
                                    Layout.fillWidth: true
                                    glyph: "󰌌"
                                    label: "Keyboard"
                                    accent: Theme.magenta
                                    command: [`${win.scripts}/switch_keyboard_layout.sh`]
                                    onActivated: win.opened = false
                                }

                                ActionTile {
                                    Layout.fillWidth: true
                                    glyph: "󰍹"
                                    label: "Stream scale"
                                    accent: Theme.cyan
                                    command: [`${win.scripts}/stream-scale.sh`]
                                    onActivated: win.opened = false
                                }
                            }
                        }
                    }
                }

                SessionCard {
                    Layout.fillWidth: true
                    onRan: win.opened = false
                }
            }
        }
    }
}
