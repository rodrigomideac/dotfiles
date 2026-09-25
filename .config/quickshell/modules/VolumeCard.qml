import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs

Card {
    id: card
    title: "Audio"

    readonly property var sink: Pipewire.defaultAudioSink

    // A node's volume and mute are only valid while something holds it bound.
    PwObjectTracker {
        objects: card.sink ? [card.sink] : []
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Text {
            text: {
                if (!card.sink || !card.sink.audio) return "󰖁";
                if (card.sink.audio.muted) return "󰖁";
                return card.sink.audio.volume > 0.5 ? "󰕾" : "󰖀";
            }
            color: card.sink && card.sink.audio && card.sink.audio.muted ? Theme.red : Theme.cyan
            font.family: Theme.font
            font.pixelSize: 20

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: if (card.sink && card.sink.audio) card.sink.audio.muted = !card.sink.audio.muted
            }
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Theme.surfaceHi

            readonly property real level: card.sink && card.sink.audio ? card.sink.audio.volume : 0

            Rectangle {
                id: fill
                width: track.width * Math.max(0, Math.min(1, track.level))
                height: parent.height
                radius: parent.radius
                color: card.sink && card.sink.audio && card.sink.audio.muted ? Theme.fgDim : Theme.cyan
                Behavior on color { ColorAnimation { duration: 140 } }
            }

            Rectangle {
                x: fill.width - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                radius: 7
                color: Theme.fg
                border.width: 2
                border.color: Theme.surface
                scale: slider.pressed ? 1.25 : 1
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                id: slider
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor

                function apply(mouseX) {
                    if (!card.sink || !card.sink.audio) return;
                    card.sink.audio.volume = Math.max(0, Math.min(1, mouseX / track.width));
                }

                onPressed: event => apply(event.x)
                onPositionChanged: event => { if (pressed) apply(event.x); }
            }
        }

        Text {
            Layout.minimumWidth: 40
            horizontalAlignment: Text.AlignRight
            text: `${Math.round(track.level * 100)}%`
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    Text {
        Layout.fillWidth: true
        text: card.sink ? (card.sink.description || card.sink.name) : "No output"
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: 11
        elide: Text.ElideRight
    }
}
