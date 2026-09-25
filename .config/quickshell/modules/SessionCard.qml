import QtQuick
import QtQuick.Layouts
import qs

Card {
    id: card
    title: "Session"

    signal ran()

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.gap

        ActionTile {
            Layout.fillWidth: true
            glyph: "󰌾"
            label: "Lock"
            accent: Theme.blue
            command: ["swaylock", "-f"]
            onActivated: card.ran()
        }

        ActionTile {
            Layout.fillWidth: true
            glyph: "󰤄"
            label: "Suspend"
            accent: Theme.cyan
            // Locked first, or the screen comes back unlocked on resume.
            command: ["sh", "-c", "swaylock -f && systemctl suspend"]
            onActivated: card.ran()
        }

        ActionTile {
            Layout.fillWidth: true
            glyph: "󰜉"
            label: "Reboot"
            accent: Theme.yellow
            command: ["systemctl", "reboot"]
            onActivated: card.ran()
        }

        ActionTile {
            Layout.fillWidth: true
            glyph: "󰐥"
            label: "Power off"
            accent: Theme.red
            command: ["systemctl", "poweroff"]
            onActivated: card.ran()
        }
    }
}
