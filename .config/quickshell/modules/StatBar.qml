import QtQuick
import QtQuick.Layouts
import qs

ColumnLayout {
    id: stat

    property string label: ""
    property string value: ""
    property real fraction: 0
    property color accent: Theme.blue

    spacing: 6

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: stat.label
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
        }

        Item { Layout.fillWidth: true }

        Text {
            text: stat.value
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 6
        radius: 3
        color: Theme.surfaceHi

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, stat.fraction))
            height: parent.height
            radius: parent.radius
            color: stat.accent

            Behavior on width {
                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
            }
        }
    }
}
