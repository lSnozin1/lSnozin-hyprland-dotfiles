import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "./themes/pinkpink" as RetroTheme

PanelWindow {
    id: overview
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-workspace-overview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    // State handed over by workspace-overview.sh through environment variables
    readonly property string stateDir: Quickshell.env("WORKSPACE_OVERVIEW_STATE_DIR") ?? ""
    readonly property string wallpaperPath: Quickshell.env("WORKSPACE_OVERVIEW_WALLPAPER") ?? ""

    property bool showEmpty: Quickshell.env("WORKSPACE_OVERVIEW_SHOW_EMPTY") === "1"
    property int refreshTick: 0
    // Addresses (without 0x) of windows that have no_screen_share, filled by blockedProcess
    property var blockedAddresses: ({})
    // Workspace ids currently shown. Only reassigned when the set of ids really changes,
    // so closing or moving a window never rebuilds the cards (no reload, no scroll jump)
    property var workspaceIds: []
    readonly property string workspaceKey: buildWorkspaceIds().join(",")
    readonly property var layoutInfo: computeLayout()
    property bool initialRevealDone: false
    property int selectedId: Hyprland.focusedWorkspace?.id ?? 1

    // Drag and drop state (a window thumbnail being dragged onto a workspace card)
    property var dragWindow: null
    property int dragTargetId: -1
    property real dragX: 0
    property real dragY: 0

    function buildWorkspaceIds() {
        // Read so the binding is re-evaluated whenever refreshTick changes
        var tick = refreshTick;
        var found = {};
        Hyprland.toplevels.values.forEach(function(window) {
            var workspaceId = window.workspace?.id ?? -1;
            if (workspaceId > 0)
                found[workspaceId] = true;
        });
        if (showEmpty) {
            for (var id = 1; id <= 10; id++)
                found[id] = true;
        }
        return Object.keys(found).map(Number).sort(function(a, b) { return a - b; });
    }

    // Keeps the card list in step with the ids by inserting/removing only what changed
    function syncWorkspaces() {
        var ids = buildWorkspaceIds();
        workspaceIds = ids;
        for (var i = workspaceListModel.count - 1; i >= 0; i--) {
            if (ids.indexOf(workspaceListModel.get(i).workspaceId) < 0)
                workspaceListModel.remove(i);
        }
        for (var j = 0; j < ids.length; j++) {
            if (j >= workspaceListModel.count || workspaceListModel.get(j).workspaceId !== ids[j])
                workspaceListModel.insert(j, { workspaceId: ids[j] });
        }
        // Scroll once so the initially selected workspace starts centered
        if (!initialRevealDone && ids.length > 0) {
            initialRevealDone = true;
            Qt.callLater(function() { revealSelection(true); });
        }
    }

    function workspaceColumns() { return panel.vertical ? 3 : 2; }
    function workspaceCardHeight(windowCount) { return Math.min(panel.vertical ? 620 : 560, 190 + Math.ceil(Math.max(1, windowCount) / workspaceColumns()) * 158); }
    function gridColumns() { return panel.vertical ? 1 : 2; }

    function windowCountFor(workspaceId) {
        var workspace = Hyprland.workspaces.values.find(function(item) { return item.id === workspaceId; });
        return workspace ? workspace.toplevels.values.length : 0;
    }

    // Each row is as tall as its tallest card, so rows never leave dead space
    function computeLayout() {
        var columns = gridColumns();
        var rowGap = 18;
        var ids = workspaceIds;
        var tops = [];
        var heights = [];
        var y = 0;
        for (var start = 0; start < ids.length; start += columns) {
            var rowHeight = 0;
            for (var i = start; i < Math.min(start + columns, ids.length); i++) {
                heights[i] = workspaceCardHeight(windowCountFor(ids[i]));
                tops[i] = y;
                rowHeight = Math.max(rowHeight, heights[i]);
            }
            y += rowHeight + rowGap;
        }
        return { tops: tops, heights: heights, total: Math.max(0, y - rowGap) };
    }

    function indexOfSelected() {
        return workspaceIds.indexOf(selectedId);
    }

    function scrollToIndex(index, center) {
        var info = layoutInfo;
        if (index < 0 || index >= info.tops.length)
            return;
        var top = info.tops[index];
        var bottom = top + info.heights[index];
        var viewHeight = workspaceGrid.height;
        var target = workspaceGrid.contentY;
        if (center)
            target = top + (bottom - top) / 2 - viewHeight / 2;
        else if (top < target)
            target = top;
        else if (bottom > target + viewHeight)
            target = bottom - viewHeight;
        workspaceGrid.contentY = Math.max(0, Math.min(target, Math.max(0, workspaceGrid.contentHeight - viewHeight)));
    }

    function selectIndex(index) {
        selectedId = workspaceIds[index];
        scrollToIndex(index, false);
    }

    function revealSelection(center) {
        var index = indexOfSelected();
        if (index >= 0)
            scrollToIndex(index, center);
    }

    function moveSelection(rowDelta, columnDelta) {
        var count = workspaceIds.length;
        if (count === 0)
            return;
        var current = indexOfSelected();
        if (current < 0) {
            selectIndex(0);
            return;
        }
        var next = current + columnDelta + rowDelta * gridColumns();
        if (next >= 0 && next < count)
            selectIndex(next);
    }

    function cycleSelection(step) {
        var count = workspaceIds.length;
        if (count === 0)
            return;
        var current = indexOfSelected();
        selectIndex(current < 0 ? (step > 0 ? 0 : count - 1) : (current + step + count) % count);
    }

    function activateSelection() {
        if (indexOfSelected() >= 0)
            focusWorkspace(selectedId);
    }

    function setShowEmpty(value) {
        showEmpty = value;
        if (stateDir !== "") {
            persistProcess.command = ["sh", "-c", "printf '%s\\n' \"$1\" > \"$2/show-empty\"", "sh", value ? "1" : "0", stateDir];
            persistProcess.running = true;
        }
        Qt.callLater(function() {
            var visibleIds = workspaceIds;
            if (visibleIds.length > 0 && visibleIds.indexOf(selectedId) < 0) {
                var focusedId = Hyprland.focusedWorkspace?.id ?? -1;
                selectedId = visibleIds.indexOf(focusedId) >= 0 ? focusedId : visibleIds[0];
            }
            revealSelection(true);
        });
    }

    function appIdOf(window) {
        if (window?.wayland?.appId)
            return window.wayland.appId;
        var ipcObject = window?.lastIpcObject;
        return ipcObject ? (ipcObject["class"] || "") : "";
    }

    // True when a Hyprland no_screen_share rule applies to the window
    function isScreenShareBlocked(window) {
        var address = String(window?.address ?? "").replace(/^0x/, "");
        return address !== "" && blockedAddresses[address] === true;
    }

    function refreshBlocked() {
        if (!blockedProcess.running)
            blockedProcess.running = true;
    }

    function iconFor(appId) {
        if (!appId)
            return "";
        var entry = DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(entry?.icon || appId.toLowerCase(), true);
    }

    function beginDrag(window) {
        dragTargetId = -1;
        dragWindow = window;
    }

    // Coordinates are relative to the panel item
    function updateDrag(panelX, panelY) {
        dragX = panelX;
        dragY = panelY;
        var local = panel.mapToItem(gridContent, panelX, panelY);
        var item = gridContent.childAt(local.x, local.y);
        dragTargetId = item?.workspaceId ?? -1;
    }

    function endDrag() {
        var window = dragWindow;
        var targetId = dragTargetId;
        cancelDrag();
        if (window && targetId > 0 && targetId !== (window.workspace?.id ?? -1))
            moveWindowToWorkspace(window, targetId);
    }

    function cancelDrag() {
        dragWindow = null;
        dragTargetId = -1;
    }

    // Moves the window without following it, so the overview stays on the current workspace
    function moveWindowToWorkspace(window, workspaceId) {
        var address = String(window.address);
        if (address.indexOf("0x") !== 0)
            address = "0x" + address;
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + workspaceId + ", follow = false, window = \"address:" + address + "\" })");
        refreshTimer.restart();
    }

    function focusWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
        closeAnimation.start();
    }

    function focusWindow(window) {
        if (window.workspace)
            window.workspace.activate();
        closeAnimation.start();
    }

    function closeWindow(window) {
        if (window?.wayland)
            window.wayland.close();
        refreshTimer.restart();
    }

    function removeWorkspace(workspace) {
        if (!workspace)
            return;
        workspace.toplevels.values.slice().forEach(function(window) {
            if (window.wayland)
                window.wayland.close();
        });
        refreshTimer.restart();
    }

    // Lets a second Alt+Tab press cycle the selection (see workspace-overview.sh)
    IpcHandler {
        target: "workspaceOverview"
        function cycle(): void { overview.cycleSelection(1); }
    }

    Process { id: persistProcess }

    // hyprctl clients -j has no no_screen_share field, so ask each window with getprop
    Process {
        id: blockedProcess
        command: ["sh", "-c", "for a in $(hyprctl clients -j | grep -o '\"address\": \"0x[0-9a-f]*\"' | cut -d'\"' -f4); do [ \"$(hyprctl getprop address:$a no_screen_share 2>/dev/null)\" = \"true\" ] && echo \"$a\"; done; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var found = {};
                text.split("\n").forEach(function(line) {
                    var address = line.trim().replace(/^0x/, "");
                    if (address !== "")
                        found[address] = true;
                });
                overview.blockedAddresses = found;
            }
        }
    }
    onRefreshTickChanged: refreshBlocked()

    ListModel { id: workspaceListModel }
    onWorkspaceKeyChanged: syncWorkspaces()
    Component.onCompleted: {
        syncWorkspaces();
        refreshBlocked();
    }

    Timer { id: refreshTimer; interval: 500; onTriggered: overview.refreshTick++ }

    MouseArea {
        anchors.fill: parent
        z: -10
        acceptedButtons: Qt.LeftButton
        onClicked: closeAnimation.start()
    }

    Item {
        id: panel
        width: Math.min(1180, parent.width - 96)
        height: Math.min(720, parent.height - 112)
        anchors.centerIn: parent
        readonly property bool vertical: height > width
        clip: true
        scale: 0.82
        y: 42
        opacity: 0
        Rectangle {
            anchors.fill: parent
            z: -2
            color: RetroTheme.Theme.background
            border.color: RetroTheme.Theme.border
            border.width: 1
            radius: 8
        }
        Component.onCompleted: openAnimation.start()
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        SequentialAnimation {
            id: openAnimation
            ParallelAnimation {
                NumberAnimation { target: panel; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: panel; property: "scale"; to: 1; duration: 520; easing.type: Easing.OutBack }
                NumberAnimation { target: panel; property: "y"; to: 0; duration: 420; easing.type: Easing.OutElastic }
            }
        }

        SequentialAnimation {
            id: closeAnimation
            ParallelAnimation {
                NumberAnimation { target: panel; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                NumberAnimation { target: panel; property: "scale"; to: 0.88; duration: 260; easing.type: Easing.InBack }
                NumberAnimation { target: panel; property: "y"; to: 28; duration: 220; easing.type: Easing.InCubic }
            }
            onFinished: Qt.quit()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                z: 5
                spacing: 12
                Text { text: "// WORKSPACE CAST"; color: RetroTheme.Theme.accent; font.family: "JetBrains Mono"; font.pixelSize: 21; font.bold: true }
                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: "ALT+TAB NEXT  ESC CLOSE"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 11 }
                Rectangle {
                    Layout.preferredWidth: emptyToggleText.implicitWidth + 24
                    Layout.preferredHeight: 26
                    radius: 13
                    color: emptyToggleMouse.containsMouse ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.surface
                    border.color: overview.showEmpty ? RetroTheme.Theme.accent : RetroTheme.Theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Text { id: emptyToggleText; anchors.centerIn: parent; text: overview.showEmpty ? "EMPTY: SHOWN" : "EMPTY: HIDDEN"; color: overview.showEmpty ? RetroTheme.Theme.accent : RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 10; font.bold: true }
                    MouseArea { id: emptyToggleMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton; onClicked: overview.setShowEmpty(!overview.showEmpty) }
                }
            }
            Text { z: 5; text: "CLICK OR ENTER TO GO  //  TAB / ARROWS / 1-0 SELECT  //  DRAG A WINDOW TO MOVE IT  //  × CLOSES"; color: RetroTheme.Theme.green; font.family: "JetBrains Mono"; font.pixelSize: 11 }

            Flickable {
                id: workspaceGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                z: 1
                contentWidth: width
                contentHeight: overview.layoutInfo.total
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                readonly property real cellWidth: width / overview.gridColumns()
                onContentHeightChanged: returnToBounds()

                Item {
                    id: gridContent
                    width: workspaceGrid.contentWidth
                    height: workspaceGrid.contentHeight

                    Repeater {
                        model: workspaceListModel
                        delegate: Rectangle {
                            id: card
                            required property int index
                            required property int workspaceId
                            readonly property QtObject workspaceObject: Hyprland.workspaces.values.find(function(item) { return item.id === workspaceId; }) ?? null
                            readonly property int windowCount: overview.windowCountFor(workspaceId)
                            property bool hovered: workspaceMouse.containsMouse
                            property bool selected: workspaceId === overview.selectedId
                            readonly property bool dropTarget: overview.dragWindow !== null && workspaceId === overview.dragTargetId
                            readonly property bool isEmpty: windowCount === 0
                            readonly property string monitorName: workspaceObject?.monitor?.name ?? ""
                            width: workspaceGrid.cellWidth - 14
                            height: overview.workspaceCardHeight(card.windowCount)
                            border.width: (selected || dropTarget) ? 2 : 1
                            radius: 5
                            clip: true
                            opacity: 0
                            rotation: index % 2 === 0 ? -0.45 : 0.45
                            x: (index % overview.gridColumns()) * workspaceGrid.cellWidth
                            y: overview.layoutInfo.tops[index] ?? 0
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 3
                                z: -1
                                color: "transparent"
                                border.color: workspaceId === (Hyprland.focusedWorkspace?.id ?? 1) ? RetroTheme.Theme.accent : RetroTheme.Theme.accentAlt
                                border.width: 1
                                radius: 4
                                opacity: card.opacity * 0.38
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.12; duration: 720 + index * 55; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 0.38; duration: 720 + index * 55; easing.type: Easing.InOutSine }
                                }
                            }
                            // Still wallpaper behind empty workspaces (path comes from workspace-overview.sh)
                            Image {
                                anchors.fill: parent
                                visible: card.isEmpty && status === Image.Ready
                                source: overview.wallpaperPath !== "" ? "file://" + encodeURI(overview.wallpaperPath) : ""
                                sourceSize: Qt.size(640, 360)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Rectangle { anchors.fill: parent; visible: card.isEmpty; color: RetroTheme.Theme.background; opacity: 0.45 }
                            Text { anchors.centerIn: parent; visible: card.isEmpty; text: "// EMPTY"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true }
                            Component.onCompleted: enter.start()
                            color: (hovered || selected || dropTarget) ? RetroTheme.Theme.surfaceAlt : RetroTheme.Theme.surface
                            border.color: dropTarget ? RetroTheme.Theme.green : selected ? RetroTheme.Theme.accent : hovered ? RetroTheme.Theme.accentAlt : workspaceId === (Hyprland.focusedWorkspace?.id ?? 1) ? RetroTheme.Theme.accent : RetroTheme.Theme.border
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                            scale: (hovered || selected || dropTarget) ? 1.015 : 1
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            SequentialAnimation {
                                id: enter
                                PauseAnimation { duration: index * 72 }
                                ParallelAnimation {
                                    NumberAnimation { target: card; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: card; property: "scale"; to: 1; duration: 480; easing.type: Easing.OutBack }
                                    NumberAnimation { target: card; property: "rotation"; to: 0; duration: 420; easing.type: Easing.OutElastic }
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12
                                z: 1
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text { text: "WS " + String(workspaceId).padStart(2, "0"); color: workspaceId === (Hyprland.focusedWorkspace?.id ?? 1) ? RetroTheme.Theme.accent : RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 16; font.bold: true }
                                    Rectangle { visible: card.monitorName !== ""; Layout.preferredWidth: monitorBadgeText.implicitWidth + 12; Layout.preferredHeight: 16; radius: 8; color: "transparent"; border.color: RetroTheme.Theme.accentAlt; border.width: 1; Text { id: monitorBadgeText; anchors.centerIn: parent; text: card.monitorName; color: RetroTheme.Theme.accentAlt; font.family: "JetBrains Mono"; font.pixelSize: 9 } }
                                    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: windowCount + " WINDOWS"; color: RetroTheme.Theme.muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                                    Rectangle { visible: !card.isEmpty; z: 10; width: 28; height: 28; radius: 14; color: removeWorkspaceMouse.containsMouse ? RetroTheme.Theme.red : RetroTheme.Theme.background; border.color: RetroTheme.Theme.border; Text { anchors.centerIn: parent; text: "×"; color: RetroTheme.Theme.foreground; font.pixelSize: 16 } MouseArea { id: removeWorkspaceMouse; anchors.fill: parent; acceptedButtons: Qt.LeftButton; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: overview.removeWorkspace(card.workspaceObject) } }
                                }
                                Flow {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 6
                                    Repeater {
                                        model: card.workspaceObject ? card.workspaceObject.toplevels : null
                                        delegate: Rectangle {
                                            id: windowCard
                                            required property var modelData
                                            readonly property string appId: overview.appIdOf(modelData)
                                            readonly property string iconPath: overview.iconFor(appId)
                                            readonly property bool noScreenShare: overview.isScreenShareBlocked(modelData)
                                            width: Math.min(300, (workspaceGrid.cellWidth - (panel.vertical ? 76 : 62)) / overview.workspaceColumns())
                                            height: 146
                                            color: RetroTheme.Theme.background
                                            border.color: RetroTheme.Theme.border
                                            border.width: 1
                                            radius: 3
                                            clip: true
                                            opacity: overview.dragWindow === modelData ? 0.45 : 1
                                            ScreencopyView { anchors.fill: parent; anchors.margins: 4; visible: !windowCard.noScreenShare; captureSource: modelData.wayland; live: !windowCard.noScreenShare; constraintSize: Qt.size(parent.width - 8, parent.height - 8) }
                                            // Placeholder for windows hidden from screen sharing
                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: 4
                                                visible: windowCard.noScreenShare
                                                color: "black"
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    anchors.verticalCenterOffset: -10
                                                    width: 48
                                                    height: 48
                                                    radius: 24
                                                    color: "transparent"
                                                    border.color: RetroTheme.Theme.red
                                                    border.width: 4
                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        width: parent.width - 6
                                                        height: 4
                                                        rotation: -45
                                                        color: RetroTheme.Theme.red
                                                    }
                                                }
                                            }
                                            Rectangle { anchors.fill: parent; anchors.margins: 2; color: "transparent"; border.color: RetroTheme.Theme.accentAlt; border.width: 1; radius: 2 }
                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.bottom: parent.bottom
                                                height: 24
                                                color: RetroTheme.Theme.background
                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 5
                                                    anchors.rightMargin: 5
                                                    spacing: 5
                                                    Image { visible: windowCard.iconPath !== ""; source: windowCard.iconPath; sourceSize: Qt.size(28, 28); fillMode: Image.PreserveAspectFit; Layout.preferredWidth: 14; Layout.preferredHeight: 14 }
                                                    Text { visible: windowCard.iconPath === "" && windowCard.appId !== ""; Layout.maximumWidth: 90; text: windowCard.appId.toUpperCase(); color: RetroTheme.Theme.accentAlt; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true; elide: Text.ElideRight }
                                                    Text { Layout.fillWidth: true; text: modelData.title || "WINDOW"; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 9; elide: Text.ElideRight }
                                                }
                                            }
                                            // Click goes to the workspace; pressing and dragging moves the window to another card
                                            MouseArea {
                                                id: dragArea
                                                anchors.fill: parent
                                                acceptedButtons: Qt.LeftButton
                                                cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                                preventStealing: true
                                                property bool dragging: false
                                                property point pressPoint: Qt.point(0, 0)
                                                onPressed: function(mouse) {
                                                    pressPoint = Qt.point(mouse.x, mouse.y);
                                                    dragging = false;
                                                }
                                                onPositionChanged: function(mouse) {
                                                    if (!pressed)
                                                        return;
                                                    if (!dragging && Math.abs(mouse.x - pressPoint.x) + Math.abs(mouse.y - pressPoint.y) > 12) {
                                                        dragging = true;
                                                        overview.beginDrag(windowCard.modelData);
                                                    }
                                                    if (dragging) {
                                                        var panelPoint = mapToItem(panel, mouse.x, mouse.y);
                                                        overview.updateDrag(panelPoint.x, panelPoint.y);
                                                    }
                                                }
                                                onReleased: {
                                                    if (dragging)
                                                        overview.endDrag();
                                                }
                                                onCanceled: overview.cancelDrag()
                                                onClicked: {
                                                    if (!dragging)
                                                        overview.focusWorkspace(card.workspaceId);
                                                }
                                            }
                                            Rectangle { anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 5; width: 28; height: 28; radius: 14; color: closeMouse.containsMouse ? RetroTheme.Theme.red : "#cc1d2021"; border.color: RetroTheme.Theme.border; border.width: 1; z: 10; Text { anchors.centerIn: parent; text: "×"; color: RetroTheme.Theme.foreground; font.pixelSize: 15 } MouseArea { id: closeMouse; anchors.fill: parent; acceptedButtons: Qt.LeftButton; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: overview.closeWindow(modelData) } }
                                        }
                                    }
                                }
                            }
                            MouseArea { id: workspaceMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: -1; onClicked: overview.focusWorkspace(workspaceId) }
                        }
                    }
                }
            }
        }

        // Follows the cursor while a window is being dragged
        Rectangle {
            visible: overview.dragWindow !== null
            z: 50
            width: 200
            height: 32
            radius: 4
            x: overview.dragX - width / 2
            y: overview.dragY - height / 2
            color: RetroTheme.Theme.surfaceAlt
            border.color: RetroTheme.Theme.green
            border.width: 1
            opacity: 0.92
            Text { anchors.fill: parent; anchors.margins: 8; verticalAlignment: Text.AlignVCenter; text: overview.dragWindow?.title || "WINDOW"; color: RetroTheme.Theme.foreground; font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight }
        }

        Shortcut { sequence: "Escape"; onActivated: closeAnimation.start() }

        focus: true
        Keys.onPressed: function(event) {
            if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                overview.focusWorkspace(event.key === Qt.Key_0 ? 10 : event.key - Qt.Key_0);
                event.accepted = true;
                return;
            }
            switch (event.key) {
            case Qt.Key_Left: overview.moveSelection(0, -1); break;
            case Qt.Key_Right: overview.moveSelection(0, 1); break;
            case Qt.Key_Up: overview.moveSelection(-1, 0); break;
            case Qt.Key_Down: overview.moveSelection(1, 0); break;
            case Qt.Key_Tab: overview.cycleSelection(1); break;
            case Qt.Key_Backtab: overview.cycleSelection(-1); break;
            case Qt.Key_Return:
            case Qt.Key_Enter: overview.activateSelection(); break;
            default: return;
            }
            event.accepted = true;
        }
    }
}
