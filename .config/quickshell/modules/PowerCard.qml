import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs

Card {
    id: card
    title: "Power Profile"

    // Spoken to over D-Bus directly, so the buttons reflect a profile changed
    // from anywhere else -- the AC hotplug unit, or the cycle keybind.
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: [
                { name: "Saver", profile: PowerProfile.PowerSaver, accent: Theme.green },
                { name: "Balanced", profile: PowerProfile.Balanced, accent: Theme.blue },
                { name: "Performance", profile: PowerProfile.Performance, accent: Theme.orange }
            ]

            Rectangle {
                id: seg
                required property var modelData

                readonly property bool active: PowerProfiles.profile === seg.modelData.profile
                readonly property bool available: seg.modelData.profile !== PowerProfile.Performance
                    || PowerProfiles.hasPerformanceProfile

                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radius - 4
                opacity: seg.available ? 1 : 0.4
                color: seg.active ? seg.modelData.accent
                    : (segMouse.containsMouse ? Theme.surfaceHi : "transparent")
                border.width: 1
                border.color: seg.active ? seg.modelData.accent : Theme.border

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.centerIn: parent
                    text: seg.modelData.name
                    color: seg.active ? Theme.bg : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: seg.active ? Font.DemiBold : Font.Normal
                }

                MouseArea {
                    id: segMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: seg.available
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PowerProfiles.profile = seg.modelData.profile
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
        text: `Throttled: ${PerformanceDegradationReason.toString(PowerProfiles.degradationReason)}`
        color: Theme.yellow
        font.family: Theme.font
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
}
