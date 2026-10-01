import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    readonly property real maxZoom: Plasmoid.configuration.maxZoom
    readonly property real bottomGap: Math.round(height * 0.12)
    // Icon at rest, as large as the panel allows while the zoomed icon still fits above bottomGap.
    readonly property real base: Math.floor(Math.min(height * 0.7, (height - bottomGap - 2) / maxZoom))
    // Fixed slots: zooming scales icons in place, nothing reflows.
    readonly property real slot: Math.round(base * 1.28)
    readonly property real range: slot * 2

    property bool hovering: false
    property real mouseX: 0

    Layout.minimumWidth: tasksModel.count * slot
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.fillHeight: true

    function zoomFor(i) {
        if (!hovering) return 1;
        const d = Math.abs(mouseX - (row.x + (i + 0.5) * slot));
        return 1 + (maxZoom - 1) * Math.max(0, 1 - d / range);
    }

    function activate(index, isGroup, childCount, isActive) {
        const idx = tasksModel.makeModelIndex(index);
        if (!isGroup) {
            if (isActive) tasksModel.requestToggleMinimized(idx);
            else tasksModel.requestActivate(idx);
            return;
        }
        // Group: cycle to the window after the active one, else focus the first.
        let next = 0;
        for (let c = 0; c < childCount; ++c) {
            if (tasksModel.data(tasksModel.makeModelIndex(index, c), TaskManager.AbstractTasksModel.IsActive)) {
                next = (c + 1) % childCount;
                break;
            }
        }
        tasksModel.requestActivate(tasksModel.makeModelIndex(index, next));
    }

    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortManual
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        separateLaunchers: false
        launchInPlace: true
        filterByScreen: true
        screenGeometry: Plasmoid.containment.screenGeometry
        filterByActivity: true
        activity: activityInfo.currentActivity
        filterByVirtualDesktop: false

        onLauncherListChanged: Plasmoid.configuration.launchers = launcherList
        Component.onCompleted: launcherList = Plasmoid.configuration.launchers
    }

    HoverHandler {
        onHoveredChanged: root.hovering = hovered
        onPointChanged: root.mouseX = point.position.x
    }

    Row {
        id: row
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        height: parent.height

        Repeater {
            model: tasksModel

            delegate: Item {
                id: task
                required property int index
                required property var model

                readonly property bool running: !model.IsLauncher
                readonly property bool group: model.IsGroupParent === true

                width: root.slot
                height: row.height
                z: drag.active ? 2 : (hover.hovered ? 1 : 0)

                Kirigami.Icon {
                    id: icon
                    source: task.model.decoration
                    width: root.base
                    height: root.base
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.bottomGap
                    transformOrigin: Item.Bottom
                    scale: drag.active ? root.maxZoom : root.zoomFor(task.index)
                    opacity: drag.active ? 0.75 : (task.model.IsStartup ? 0.6 : 1)
                    Behavior on scale { NumberAnimation { duration: root.hovering ? 90 : 180; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    visible: task.running
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Kirigami.Theme.highlightColor
                    opacity: task.model.IsActive ? 1 : 0.6
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.round(root.bottomGap / 2 - 2.5)
                }

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    mainText: task.model.display
                    location: Plasmoid.location
                    active: !drag.active
                }

                HoverHandler { id: hover }

                // Drag left/right to reorder; the launcher order is saved when the drag ends.
                DragHandler {
                    id: drag
                    target: null
                    yAxis.enabled: false
                    onCentroidChanged: {
                        if (!active) return;
                        const x = task.mapToItem(row, centroid.position.x, 0).x;
                        const to = Math.max(0, Math.min(tasksModel.count - 1, Math.floor(x / root.slot)));
                        if (to !== task.index) tasksModel.move(task.index, to);
                    }
                    onActiveChanged: if (!active) tasksModel.syncLaunchers()
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: {
                        if (task.model.IsLauncher) tasksModel.requestNewInstance(tasksModel.makeModelIndex(task.index));
                        else root.activate(task.index, task.group, task.model.ChildCount || 0, task.model.IsActive);
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.MiddleButton
                    onTapped: tasksModel.requestNewInstance(tasksModel.makeModelIndex(task.index))
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: menu.openRelative()
                }

                PlasmaExtras.Menu {
                    id: menu
                    visualParent: task
                    placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup

                    PlasmaExtras.MenuItem {
                        text: i18n("New Window")
                        icon: "window-new"
                        onClicked: tasksModel.requestNewInstance(tasksModel.makeModelIndex(task.index))
                    }
                    PlasmaExtras.MenuItem {
                        readonly property bool pinned: tasksModel.launcherPosition(task.model.LauncherUrlWithoutIcon) !== -1
                        text: pinned ? i18n("Unpin from Dock") : i18n("Pin to Dock")
                        icon: pinned ? "window-unpin" : "window-pin"
                        onClicked: pinned ? tasksModel.requestRemoveLauncher(task.model.LauncherUrlWithoutIcon)
                                          : tasksModel.requestAddLauncher(task.model.LauncherUrlWithoutIcon)
                    }
                    PlasmaExtras.MenuItem {
                        visible: task.running
                        text: task.group ? i18n("Close All Windows") : i18n("Close")
                        icon: "window-close"
                        onClicked: tasksModel.requestClose(tasksModel.makeModelIndex(task.index))
                    }
                }
            }
        }
    }
}
