import QtQuick
import Quickshell.Io

Item {
    id: ctl
    anchors.fill: parent

    property bool locked: true
    property color accentColor: "#ff79c6"
    property color panelColor: "#1a1025"
    property real panelOpacity: 0.95
    property string name: "terminal"

    // Geometry in pixels: startup defaults, changed live by dragging
    property int termX: 900
    property int termY: 420
    property int termW: 800
    property int termH: 450

    property string monitorName: "DP-1"
    property int screenW: 1920
    property int screenH: 1080
    property string socket: "/tmp/fetch-panel"
    property string fetchConfig: ""

    readonly property int gripSize: 22
    readonly property int cornerInset: 3
    property bool movePending: false
    property bool sizePending: false
    readonly property bool dirty: movePending || sizePending

    property alias editFrame: editFrame

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v))
    }

    function logState() {
        console.log(name + " -> x:", Math.round(termX), "y:", Math.round(termY),
                    "w:", Math.round(termW), "h:", Math.round(termH))
    }

    function marginArgs() {
        return [
            "margin-left=" + Math.round(termX + cornerInset),
            "margin-top=" + Math.round(termY + cornerInset),
            "margin-right=" + Math.round(screenW - termX - termW + cornerInset),
            "margin-bottom=" + Math.round(screenH - termY - termH + cornerInset)
        ]
    }

    function apply() {
        if (mover.running || !dirty) return
        let args = [
            "kitten", "@", "--to=unix:" + socket,
            "resize-os-window", "--action=os-panel", "--incremental"
        ]
        args = args.concat(marginArgs())
        if (sizePending) {
            args.push(
                "columns=" + Math.round(termW - cornerInset * 2) + "px",
                "lines=" + Math.round(termH - cornerInset * 2) + "px"
            )
        }
        movePending = false
        sizePending = false
        mover.command = args
        mover.running = true
    }

    Process {
        id: term
    }

    Process {
        id: mover
    }

    Component.onCompleted: {
        term.command = [
            "kitten", "panel",
            "--edge=none", "--layer=background",
            "--output-name=" + monitorName,
            "--lines=" + (termH - cornerInset * 2) + "px",
            "--columns=" + (termW - cornerInset * 2) + "px",
            "--margin-left=" + (termX + cornerInset),
            "--margin-top=" + (termY + cornerInset),
            "--margin-right=" + (screenW - termX - termW + cornerInset),
            "--margin-bottom=" + (screenH - termY - termH + cornerInset),
            "--focus-policy=on-demand",
            "-o", "background_opacity=" + panelOpacity,
            "-o", "background=" + panelColor,
            "-o", "allow_remote_control=socket-only",
            "--listen-on=unix:" + socket,
            "fish", "-C", [
                "functions -e __dualfetch_resize __dualfetch_mark_dirty __switch_to_narrow_fetch",
                "set -g __panel_safe 1",
                "function __panel_fetch",
                "printf '\\033_Ga=d\\033%s\\033[H\\033[2J\\033[3J' \\\\",
                "command fastfetch -c " + fetchConfig,
                "echo -e 'Welcome ~home! (˶˃ ᵕ ˂˶) .ᐟ.ᐟ'",
                "end",
                "function __panel_resize --on-signal WINCH",
                "test $__panel_safe = 1; and __panel_fetch; and commandline -f repaint",
                "end",
                "function __panel_mark_dirty --on-event fish_preexec",
                "set -g __panel_safe 0",
                "end",
                "function fish_greeting",
                "__panel_fetch",
                "end"
            ].join("; ")
        ]
        term.running = true
    }

    Timer {
        interval: 40
        repeat: true
        running: ctl.dirty
        onTriggered: ctl.apply()
    }

    Rectangle {
        id: borderFrame
        x: ctl.termX
        y: ctl.termY
        width: ctl.termW
        height: ctl.termH
        radius: 8
        color: "transparent"
        border.width: 3
        border.color: ctl.accentColor
    }

    Rectangle {
        id: editFrame
        visible: !ctl.locked
        x: ctl.termX
        y: ctl.termY
        width: ctl.termW
        height: ctl.termH
        radius: 8
        color: Qt.alpha(ctl.accentColor, 0.15)
        border.width: 3
        border.color: Qt.alpha(ctl.accentColor, 0.8)

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeAllCursor
            property real startMouseX: 0
            property real startMouseY: 0
            property real startX: 0
            property real startY: 0
            onPressed: mouse => {
                const p = mapToItem(ctl, mouse.x, mouse.y)
                startMouseX = p.x
                startMouseY = p.y
                startX = ctl.termX
                startY = ctl.termY
            }
            onPositionChanged: mouse => {
                if (!pressed) return
                const p = mapToItem(ctl, mouse.x, mouse.y)
                ctl.termX = ctl.clamp(startX + p.x - startMouseX, 0, ctl.width - ctl.termW)
                ctl.termY = ctl.clamp(startY + p.y - startMouseY, 0, ctl.height - ctl.termH)
                ctl.movePending = true
            }
            onReleased: ctl.logState()
        }
    }

    Repeater {
        model: [
            { left: true, top: true },
            { left: false, top: true },
            { left: true, top: false },
            { left: false, top: false }
        ]

        Rectangle {
            id: handle
            required property var modelData
            visible: !ctl.locked
            x: modelData.left ? ctl.termX : ctl.termX + ctl.termW - ctl.gripSize
            y: modelData.top ? ctl.termY : ctl.termY + ctl.termH - ctl.gripSize
            width: ctl.gripSize
            height: ctl.gripSize
            radius: 6
            color: Qt.alpha(ctl.accentColor, 0.6)

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: handle.modelData.left === handle.modelData.top
                    ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                property real startMouseX: 0
                property real startMouseY: 0
                property real startX: 0
                property real startY: 0
                property real startW: 0
                property real startH: 0
                onPressed: mouse => {
                    const p = mapToItem(ctl, mouse.x, mouse.y)
                    startMouseX = p.x
                    startMouseY = p.y
                    startX = ctl.termX
                    startY = ctl.termY
                    startW = ctl.termW
                    startH = ctl.termH
                }
                onPositionChanged: mouse => {
                    if (!pressed) return
                    const p = mapToItem(ctl, mouse.x, mouse.y)
                    const dx = p.x - startMouseX
                    const dy = p.y - startMouseY
                    if (handle.modelData.left) {
                        const w = ctl.clamp(startW - dx, 60, startX + startW)
                        ctl.termX = startX + startW - w
                        ctl.termW = w
                    } else {
                        ctl.termW = ctl.clamp(startW + dx, 60, ctl.width - startX)
                    }
                    if (handle.modelData.top) {
                        const h = ctl.clamp(startH - dy, 40, startY + startH)
                        ctl.termY = startY + startH - h
                        ctl.termH = h
                    } else {
                        ctl.termH = ctl.clamp(startH + dy, 40, ctl.height - startY)
                    }
                    ctl.movePending = true
                    ctl.sizePending = true
                }
                onReleased: ctl.logState()
            }
        }
    }
}