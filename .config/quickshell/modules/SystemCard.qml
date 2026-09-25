import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import qs

Card {
    id: card
    title: "System"

    property real cpu: 0
    property real memUsed: 0
    property real memTotal: 1
    property string uptime: ""

    // /proc/stat counts ticks since boot, so a sample on its own says nothing;
    // only the delta against the previous one is a usage figure.
    property var lastSample: null

    FileView {
        id: statFile
        path: "/proc/stat"
        blockLoading: true
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        blockLoading: true
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        blockLoading: true
    }

    Timer {
        interval: 2000
        running: card.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            uptimeFile.reload();

            const fields = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = fields[3] + fields[4];
            const total = fields.reduce((a, b) => a + b, 0);

            if (card.lastSample) {
                const dTotal = total - card.lastSample.total;
                const dIdle = idle - card.lastSample.idle;
                if (dTotal > 0) card.cpu = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
            }
            card.lastSample = { total: total, idle: idle };

            const mem = memFile.text();
            const kbTotal = Number(/MemTotal:\s+(\d+)/.exec(mem)[1]);
            const kbAvail = Number(/MemAvailable:\s+(\d+)/.exec(mem)[1]);
            card.memTotal = kbTotal / 1048576;
            card.memUsed = (kbTotal - kbAvail) / 1048576;

            const secs = Math.floor(Number(uptimeFile.text().split(" ")[0]));
            const d = Math.floor(secs / 86400);
            const h = Math.floor((secs % 86400) / 3600);
            const m = Math.floor((secs % 3600) / 60);
            card.uptime = d > 0 ? `${d}d ${h}h` : (h > 0 ? `${h}h ${m}m` : `${m}m`);
        }
    }

    StatBar {
        Layout.fillWidth: true
        label: "CPU"
        value: `${Math.round(card.cpu * 100)}%`
        fraction: card.cpu
        accent: card.cpu > 0.85 ? Theme.red : Theme.green
    }

    StatBar {
        Layout.fillWidth: true
        label: "Memory"
        value: `${card.memUsed.toFixed(1)} / ${card.memTotal.toFixed(1)} GiB`
        fraction: card.memUsed / card.memTotal
        accent: Theme.magenta
    }

    StatBar {
        Layout.fillWidth: true
        visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
        label: UPower.onBattery ? "Battery" : "Battery (charging)"
        value: UPower.displayDevice ? `${Math.round(UPower.displayDevice.percentage * 100)}%` : ""
        fraction: UPower.displayDevice ? UPower.displayDevice.percentage : 0
        accent: {
            if (!UPower.displayDevice) return Theme.blue;
            const p = UPower.displayDevice.percentage;
            return p < 0.15 ? Theme.red : (p < 0.35 ? Theme.yellow : Theme.green);
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Uptime"
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: 13
        }

        Item { Layout.fillWidth: true }

        Text {
            text: card.uptime
            color: Theme.fgDim
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
