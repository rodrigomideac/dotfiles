pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Gruvbox dark. style.css stacks four schemes and the last one defined
    // wins, so this is what the bar is actually painting right now -- keep the
    // two in step if that file is reordered.
    readonly property color bg: "#282828"
    readonly property color surface: "#32302f"
    readonly property color surfaceHi: "#3c3836"
    readonly property color fg: "#ebdbb2"
    readonly property color fgDim: "#a89984"
    readonly property color border: "#504945"

    readonly property color red: "#cc241d"
    readonly property color green: "#98971a"
    readonly property color yellow: "#d79921"
    readonly property color blue: "#458588"
    readonly property color magenta: "#b16286"
    readonly property color cyan: "#689d6a"
    readonly property color orange: "#d65d0e"

    readonly property string font: "Iosevka Nerd Font"

    readonly property int radius: 14
    readonly property int gap: 14
    readonly property int pad: 18
}
