import Quickshell
import Quickshell.Io
import qs.modules

ShellRoot {
    CommandCenter {
        id: center
    }

    // IPC rather than a socket of our own: the niri bind is then a plain spawn
    // and the panel keeps its state between presses.
    IpcHandler {
        target: "commandCenter"

        function toggle(): void {
            center.opened = !center.opened;
        }

        // Not show/hide: those collide with `qs ipc` subcommand names and the
        // CLI swallows them before they reach the function positional.
        function open(): void {
            center.opened = true;
        }

        function close(): void {
            center.opened = false;
        }
    }
}
