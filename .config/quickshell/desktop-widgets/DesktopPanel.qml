import QtQuick

Rectangle {
    id: panel

    // Used in the log line printed after a drag or resize
    property string name: "panel"

// Shared state and style
    property bool locked: true
    property real zoom: 1.0
    property int padding: 16
    property int borderWidth: 2
    property color accentColor: "#ff79c6"
    property color borderColor: accentColor
    property color panelColor: "#1a1025"
    property real panelOpacity: 0.95

    // Set by each widget: content size at zoom 1.0
    property real contentWidth: 100
    property real contentHeight: 100

    default property alias content: holder.data

    function logState() {
        console.log(name + " -> x:", Math.round(x), "y:", Math.round(y), "zoom:", zoom.toFixed(2))
    }

    width: contentWidth * zoom + padding * 2
    height: contentHeight * zoom + padding * 2
    radius: 12
    color: Qt.alpha(panelColor, panelOpacity)
    border.width: borderWidth
    border.color: borderColor
    clip: true

    Item {
        id: holder
        x: panel.padding
        y: panel.padding
        width: panel.contentWidth
        height: panel.contentHeight
        scale: panel.zoom
        transformOrigin: Item.TopLeft
        clip: true
    }

    MouseArea {
        anchors.fill: parent
        enabled: !panel.locked
        cursorShape: Qt.SizeAllCursor
        drag.target: panel
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: panel.parent.width - panel.width
        drag.maximumY: panel.parent.height - panel.height
        onReleased: panel.logState()
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
            visible: !panel.locked
            width: 18
            height: 18
            radius: 4
            x: modelData.left ? 4 : panel.width - width - 4
            y: modelData.top ? 4 : panel.height - height - 4
            color: Qt.alpha(panel.accentColor, 0.6)

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: handle.modelData.left === handle.modelData.top
                    ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                property real startZoom: 1
                property real startX: 0
                property real startY: 0
                property real startWidth: 1
                property real startHeight: 1
                property real startMouseX: 0
                property real startMouseY: 0
                onPressed: mouse => {
                    const p = mapToItem(panel.parent, mouse.x, mouse.y)
                    startZoom = panel.zoom
                    startX = panel.x
                    startY = panel.y
                    startWidth = panel.width
                    startHeight = panel.height
                    startMouseX = p.x
                    startMouseY = p.y
                }
                onPositionChanged: mouse => {
                    if (!pressed) return
                    const p = mapToItem(panel.parent, mouse.x, mouse.y)
                    const dx = handle.modelData.left ? startMouseX - p.x : p.x - startMouseX
                    const dy = handle.modelData.top ? startMouseY - p.y : p.y - startMouseY
                    const aspect = startWidth / startHeight
                    const wanted = Math.max(60, startWidth + (dx + dy * aspect) / 2)

                    const maxWidth = handle.modelData.left ? startX + startWidth : panel.parent.width - startX
                    const maxHeight = handle.modelData.top ? startY + startHeight : panel.parent.height - startY
                    const maxZoom = Math.min(5,
                        (maxWidth - panel.padding * 2) / panel.contentWidth,
                        (maxHeight - panel.padding * 2) / panel.contentHeight)

                    panel.zoom = Math.max(0.2, Math.min(maxZoom, startZoom * wanted / startWidth))
                    if (handle.modelData.left) panel.x = startX + startWidth - panel.width
                    if (handle.modelData.top) panel.y = startY + startHeight - panel.height
                }
                onReleased: panel.logState()
            }
        }
    }
}