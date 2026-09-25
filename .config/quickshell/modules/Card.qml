import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: card

    property string title: ""
    default property alias content: inner.data

    color: Theme.surface
    radius: Theme.radius
    border.width: 1
    border.color: Theme.border

    implicitWidth: layout.implicitWidth + Theme.pad * 2
    implicitHeight: layout.implicitHeight + Theme.pad * 2

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: 12

        Text {
            Layout.fillWidth: true
            visible: card.title !== ""
            text: card.title
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1.4
            font.capitalization: Font.AllUppercase
        }

        ColumnLayout {
            id: inner
            Layout.fillWidth: true
            spacing: 10
        }
    }
}
