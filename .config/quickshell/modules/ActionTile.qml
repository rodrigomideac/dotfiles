import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

Rectangle {
    id: tile

    property string glyph: ""
    property string label: ""
    property color accent: Theme.blue
    // Fire-and-forget: execDetached reparents to init, so the script outlives
    // the panel closing on the same click.
    property var command: []

    signal activated()

    implicitWidth: 104
    implicitHeight: 84
    radius: Theme.radius - 2
    color: mouse.containsMouse ? Theme.surfaceHi : Theme.surface
    border.width: 1
    border.color: mouse.containsMouse ? tile.accent : Theme.border
    scale: mouse.pressed ? 0.96 : 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.glyph
            color: mouse.containsMouse ? tile.accent : Theme.fg
            font.family: Theme.font
            font.pixelSize: 22
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.label
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (tile.command.length > 0) Quickshell.execDetached(tile.command);
            tile.activated();
        }
    }
}
