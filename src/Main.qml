import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1040; height: 820
    minimumWidth: 720; minimumHeight: 640
    visible: true
    title: "omsnake"
    color: theme.background
    Material.theme: theme.light ? Material.Light : Material.Dark
    Material.accent: theme.accent
    Material.background: theme.background
    Material.foreground: theme.foreground
    font.family: "Inter"
    onActiveChanged: { if (!active) backend.pause() }
    property bool playing: backend.state === "running"
    property real flash: 0
    function number(value) { let language = translator.language; return value.toLocaleString(Qt.locale(), 'f', 0) }
    function showHelp() { backend.pause(); help.open() }
    function requestRestart() { if (playing || backend.state === "paused") { backend.pause(); confirmRestart.open() } else backend.restart() }
    Shortcut { sequence: "Space"; enabled: !help.visible && !confirmRestart.visible; onActivated: backend.primaryAction() }
    Shortcut { sequence: "Up"; onActivated: backend.turn(3) }
    Shortcut { sequence: "Down"; onActivated: backend.turn(1) }
    Shortcut { sequence: "Left"; onActivated: backend.turn(2) }
    Shortcut { sequence: "Right"; onActivated: backend.turn(0) }
    Shortcut { sequence: "W"; onActivated: backend.turn(3) }
    Shortcut { sequence: "S"; onActivated: backend.turn(1) }
    Shortcut { sequence: "A"; onActivated: backend.turn(2) }
    Shortcut { sequence: "D"; onActivated: backend.turn(0) }
    Shortcut { sequence: "R"; onActivated: window.requestRestart() }
    Shortcut { sequence: "Q"; onActivated: window.close() }
    Shortcut { sequence: "Escape"; enabled: !help.visible && !confirmRestart.visible; onActivated: backend.pause() }
    Shortcut { sequence: "?"; onActivated: window.showHelp() }
    Shortcut { sequence: "F1"; onActivated: window.showHelp() }
    Shortcut { sequence: "F11"; onActivated: window.visibility = window.visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen }
    ListModel { id: snakeModel }
    function syncSnake() {
        let segments = backend.segments
        while (snakeModel.count > segments.length) snakeModel.remove(snakeModel.count - 1)
        for (let i=0; i<segments.length; ++i) {
            let p=segments[i]
            let snap = backend.state !== "running" || i >= snakeModel.count
            if (!snap) { let old=snakeModel.get(i); snap=Math.abs(old.cx-p.x)>1 || Math.abs(old.cy-p.y)>1 }
            if (i >= snakeModel.count) snakeModel.append({cx:p.x, cy:p.y, snap:true})
            else { snakeModel.setProperty(i,"snap",snap); snakeModel.setProperty(i,"cx",p.x); snakeModel.setProperty(i,"cy",p.y) }
        }
    }
    Component.onCompleted: syncSnake()
    Connections { target: backend; function onChanged() { window.syncSnake() } }
    Connections { target: backend; function onAte() { window.flash=0.18; flashAnimation.restart() } }
    NumberAnimation { id: flashAnimation; target: window; property: "flash"; to: 0; duration: 450 }

    component Caption: Label { color: theme.colors.muted; font.pixelSize: 11; font.letterSpacing: 1.8; font.weight: Font.DemiBold }
    component Action: Button {
        id: control
        background: Rectangle { implicitWidth: 110; implicitHeight: 42; radius: theme.radius; color: control.highlighted ? theme.accent : control.down ? Qt.alpha(theme.foreground,0.15) : control.hovered ? Qt.alpha(theme.foreground,0.08) : "transparent" }
        Material.roundedScale: theme.radius
        focusPolicy: Qt.NoFocus
        contentItem: Text { text: parent.text; font: parent.font; color: parent.highlighted ? theme.accentForeground : theme.foreground; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }
    Item {
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 32; spacing: 20
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout { spacing: 2
                    Caption { text: qsTr("THE CLASSIC, RECHARGED") }
                    Label { text: 'om<span style="color:' + theme.accent + '">snake</span>'; textFormat: Text.RichText; font.pixelSize: 34; font.weight: Font.Bold; LayoutMirroring.enabled: false }
                }
                Item { Layout.fillWidth: true }
                ColumnLayout { spacing: 2; Label { text: window.number(backend.score); font.pixelSize: 32; font.weight: Font.Bold; Layout.alignment: Qt.AlignRight } Caption { text: qsTr("SCORE") } }
                Rectangle { width: 1; height: 42; color: theme.colors.selection; Layout.leftMargin: 16; Layout.rightMargin: 16 }
                ColumnLayout { spacing: 2; Label { text: window.number(backend.best); font.pixelSize: 32; font.weight: Font.Bold; color: theme.accent; Layout.alignment: Qt.AlignRight } Caption { text: qsTr("PERSONAL BEST") } }
            }
            RowLayout { Layout.fillWidth: true; spacing: 12
                ComboBox { id: difficulty; model: [qsTr("Chill"),qsTr("Classic"),qsTr("Blitz")]; currentIndex: backend.difficulty; onActivated: backend.difficulty=currentIndex; enabled: backend.state !== "running" && backend.state !== "paused"; Material.roundedScale: theme.radius; focusPolicy: Qt.NoFocus; implicitWidth: 140 }
                Switch { text: qsTr("Wrap edges"); checked: backend.wrap; onToggled: backend.wrap=checked; enabled: backend.state !== "running" && backend.state !== "paused"; focusPolicy: Qt.NoFocus }
                Item { Layout.fillWidth: true }
                Caption { text: qsTr("LEVEL %1").arg(window.number(backend.level)) }
                Rectangle { width: 6; height: 6; radius: 3; color: window.playing ? theme.colors.green : theme.colors.muted }
                Label { text: window.playing ? qsTr("LIVE") : qsTr("STANDBY"); color: theme.colors.muted; font.pixelSize: 11; font.letterSpacing: 1 }
            }
            Rectangle {
                id: frame
                Layout.fillWidth: true; Layout.fillHeight: true
                color: theme.light ? Qt.darker(theme.background,1.035) : Qt.lighter(theme.background,1.3)
                border.color: Qt.alpha(theme.accent,0.25 + window.flash); radius: theme.radius
                Item {
                    id: board
                    width: Math.floor(Math.min((parent.width-28)/30,(parent.height-28)/24))*30
                    height: width/30*24
                    anchors.centerIn: parent
                    property real cell: width/30
                    // The board stays left-to-right so arrow keys always match screen directions.
                    LayoutMirroring.enabled: false
                    Canvas {
                        id: grid
                        anchors.fill: parent
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        Connections { target: theme; function onChanged() { grid.requestPaint() } }
                        onPaint: {
                            let ctx=getContext("2d"); ctx.reset(); ctx.strokeStyle=Qt.alpha(theme.foreground,0.045); ctx.lineWidth=1
                            for(let x=0; x<=30; x++) {ctx.beginPath();ctx.moveTo(x*board.cell,0);ctx.lineTo(x*board.cell,height);ctx.stroke()}
                            for(let y=0; y<=24; y++) {ctx.beginPath();ctx.moveTo(0,y*board.cell);ctx.lineTo(width,y*board.cell);ctx.stroke()}
                        }
                    }
                    Rectangle {
                        x: backend.food.x*board.cell-4; y: backend.food.y*board.cell-4
                        width: board.cell+8; height: width; radius: width/2
                        color: Qt.alpha(theme.colors.red,0.10)
                        SequentialAnimation on scale { running: window.playing; loops: Animation.Infinite; NumberAnimation { to: 1.3; duration: 700; easing.type: Easing.InOutSine } NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine } }
                    }
                    Rectangle { x: (backend.food.x+0.22)*board.cell; y: (backend.food.y+0.22)*board.cell; width: board.cell*0.56; height: width; radius: width/2; color: theme.colors.red }
                    Repeater {
                        model: snakeModel
                        delegate: Rectangle {
                            required property int cx
                            required property int cy
                            required property bool snap
                            required property int index
                            x: cx*board.cell+1; y: cy*board.cell+1
                            Behavior on x { enabled: window.playing && !snap; NumberAnimation { duration: backend.interval*0.85; easing.type: Easing.Linear } }
                            Behavior on y { enabled: window.playing && !snap; NumberAnimation { duration: backend.interval*0.85; easing.type: Easing.Linear } }
                            width: board.cell-2; height: board.cell-2; radius: Math.min(4,theme.radius)
                            color: index===0 ? theme.accent : Qt.alpha(theme.accent,Math.max(0.35,1-index*0.018))
                            Item {
                                anchors.fill: parent; rotation: backend.direction*90; visible: index===0
                                Rectangle { x: parent.width*0.58; y: parent.height*0.24; width: Math.max(2,board.cell*0.15); height: width; radius: width/2; color: theme.accentForeground }
                                Rectangle { x: parent.width*0.58; y: parent.height*0.63; width: Math.max(2,board.cell*0.15); height: width; radius: width/2; color: theme.accentForeground }
                            }
                        }
                    }
                }
                Rectangle {
                    anchors.fill: parent; radius: theme.radius; visible: !window.playing
                    color: Qt.alpha(theme.background,0.88)
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 14
                        Caption { Layout.alignment: Qt.AlignHCenter; text: backend.state === "over" ? qsTr("ONE MORE ROUND?") : qsTr("STAY HUNGRY") }
                        Label { Layout.alignment: Qt.AlignHCenter; font.pixelSize: 40; font.weight: Font.Bold; text: backend.state === "paused" ? qsTr("Take a breather.") : backend.state === "over" ? qsTr("Game over.") : backend.state === "won" ? qsTr("Perfect run!") : qsTr("Small snake. Big plans.") }
                        Label { Layout.alignment: Qt.AlignHCenter; text: backend.state === "over" || backend.state === "won" ? qsTr("Final score: %1").arg(window.number(backend.score)) : qsTr("Eat. Grow. Find your flow."); color: theme.colors.muted; font.pixelSize: 15 }
                        Action { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; highlighted: true; text: backend.state === "paused" ? qsTr("Resume  ·  Space") : backend.state === "over" || backend.state === "won" ? qsTr("Play again  ·  Space") : qsTr("Let's play  ·  Space"); onClicked: backend.primaryAction(); implicitWidth: 220 }
                    }
                }
            }
            RowLayout { Layout.fillWidth: true
                Label { text: qsTr("↑ ↓ ← →  /  WASD   Move"); color: theme.colors.muted; font.pixelSize: 12 }
                Label { text: qsTr("Space   Pause"); color: theme.colors.muted; font.pixelSize: 12; Layout.leftMargin: 12 }
                Item { Layout.fillWidth: true }
                Action { text: qsTr("Restart"); onClicked: window.requestRestart(); flat: true }
                Action { text: qsTr("Shortcuts  ?"); onClicked: window.showHelp(); flat: true }
            }
            Label { visible: backend.error.length>0; text: backend.error; color: theme.colors.red; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        }
    }
    Dialog {
        width: Math.min(window.width-48, 520)
        id: help; objectName: "help"; anchors.centerIn: parent; modal: true; focus: true
        title: qsTr("Find your flow")
        Material.roundedScale: theme.radius
        background: Rectangle { color: theme.background; radius: theme.radius; border.color: theme.colors.selection }
        footer: DialogButtonBox {
            LayoutMirroring.enabled: Qt.application.layoutDirection===Qt.RightToLeft
            LayoutMirroring.childrenInherit: true
            Action { text: qsTr("Close"); DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
        }
        contentItem: Label { text: qsTr("Arrows / WASD    Steer\nSpace    Play / pause\nEscape    Pause\nR    Restart\nF11    Fullscreen\n? / F1    Shortcuts\nQ    Quit\n\nEvery five bites, the pace picks up.\nWrap edges lets you travel through walls."); font.pixelSize: 15; lineHeight: 1.5; wrapMode: Text.WordWrap; LayoutMirroring.enabled: Qt.application.layoutDirection===Qt.RightToLeft }
    }
    Dialog {
        width: Math.min(window.width-48, 460)
        id: confirmRestart; anchors.centerIn: parent; title: qsTr("Start a fresh run?"); modal: true; focus: true
        Material.roundedScale: theme.radius
        background: Rectangle { color: theme.background; radius: theme.radius; border.color: theme.colors.selection }
        footer: DialogButtonBox {
            LayoutMirroring.enabled: Qt.application.layoutDirection===Qt.RightToLeft
            LayoutMirroring.childrenInherit: true
            Action { text: qsTr("Cancel"); DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
            Action { text: qsTr("Restart"); highlighted: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole }
        }
        contentItem: Label { text: qsTr("Your current run will end. Your best score is saved."); wrapMode: Text.WordWrap; LayoutMirroring.enabled: Qt.application.layoutDirection===Qt.RightToLeft }
        onAccepted: { backend.restart(); backend.primaryAction() }
    }
}
