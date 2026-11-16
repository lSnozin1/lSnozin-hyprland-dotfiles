import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // ---- Shared settings ----
    property string monitorName: "DP-1"
    property bool locked: true
    property bool showAscii: false
    property color accent: "#ff79c6"
    property string home: Quickshell.env("HOME")
    // -------------------------

    IpcHandler {
        target: "widgets"
        function toggleLock(): void {
            root.locked = !root.locked
        }
    }

    Variants {
        model: Quickshell.screens.filter(s => s.name === root.monitorName)

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: root.locked ? emptyMask : panelMask
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "desktop-widgets"

            Item {
                id: editArea
                anchors.fill: parent
            }

            Region { id: emptyMask }
            Region {
                id: panelMask
                Region { item: editArea }
            }

            // ---- Widget 1: ASCII art ----
            AsciiWidget {
                id: asciiPanel
                visible: root.showAscii
                name: "ascii"
                locked: root.locked
                accentColor: root.accent
                x: 40
                y: 420
                zoom: 1.0
                artPath: root.home + "/.config/fastfetch/miku.txt"
                fontSize: 10
                trimLeft: 0
                trimRight: 0
            }

            // ---- Widget 2: PNG ----
            ImageWidget {
                id: imagePanel
                name: "image"
                locked: root.locked
                accentColor: root.accent
                x: 40
                y: 40
                zoom: 1.0
                imagePath: Qt.resolvedUrl("WidgetGirl.webp").toString().replace(/^file:\/\//, "")
                baseWidth: 300
            }

            // ---- Widget 3: fetch terminal (kitty panel) ----
            TerminalPanel {
                id: termPanel
                locked: root.locked
                accentColor: root.accent
                panelOpacity: 1.0
                monitorName: root.monitorName
                screenW: modelData.width
                screenH: modelData.height
                termX: 1410
                termY: 635
                termW: 500
                termH: 400
                fetchConfig: root.home + "/.config/fastfetch/mini-fetch.jsonc"
            }
        }
    }
}