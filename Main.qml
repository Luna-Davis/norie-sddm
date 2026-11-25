import QtQuick

// Norie SDDM greeter: lock screen -> login card.
// Context properties provided by SDDM: sddm, config, userModel, sessionModel.

Rectangle {
    id: root

    width: 1366
    height: 768
    color: bgColor
    focus: true

    // ───────── theme.conf (with fallbacks) ─────────
    readonly property color bgColor: config.bg || "#121018"
    readonly property color fgColor: config.fg || "#DEDCE5"
    readonly property color brightColor: config.bright || "#EFEEF1"
    readonly property color accent: config.accent || "#7B5CF0"
    readonly property color surface: config.surface || "#252130"
    readonly property color surfaceHigh: config.surfaceHigh || "#2D293D"
    readonly property color softColor: config.soft || "#C8C6D2"
    readonly property color errorColor: config.error || "#EA8985"
    readonly property string fontFamily: config.font || "JetBrainsMono Nerd Font"
    readonly property bool hasBg: !!config.background

    // everything scales off the 1366x768 design
    readonly property real u: Math.min(width / 1366, height / 768)

    // ───────── state ─────────
    property bool locked: true
    property bool sessionOpen: false
    property bool showPassword: false
    property bool busy: false
    property string errorText: ""
    property int sessionIndex: 0
    property string sessionName: ""
    property date now: new Date()
    readonly property string userName: userModel.lastUser || "user"

    function unlock() {
        locked = false
        passwordInput.forceActiveFocus()
    }

    function lock() {
        locked = true
        sessionOpen = false
        showPassword = false
        errorText = ""
        passwordInput.text = ""
        root.forceActiveFocus()
    }

    function doLogin() {
        if (busy || passwordInput.text.length === 0)
            return
        errorText = ""
        busy = true
        sddm.login(userName, passwordInput.text, sessionIndex)
    }

    onSessionIndexChanged: {
        const it = sessionRepeater.itemAt(sessionIndex)
        if (it)
            sessionName = it.label
    }

    Component.onCompleted: {
        sessionIndex = Math.max(0, sessionModel.lastIndex)
        forceActiveFocus()
    }

    Keys.onPressed: event => {
        if (locked) {
            unlock()
            event.accepted = true
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.busy = false
            root.errorText = "Wrong password, try again"
            passwordInput.text = ""
            shakeAnim.restart()
            passwordInput.forceActiveFocus()
        }

        function onLoginSucceeded() {
            root.errorText = ""
        }
    }

    // ───────── background ─────────
    Image {
        anchors.fill: parent
        visible: root.hasBg
        source: root.hasBg ? Qt.resolvedUrl(config.background) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: root.bgColor
        opacity: root.hasBg ? 0.62 : 0
    }

    // fallback artwork: skewed bars, echoing the wallpaper carousel
    Item {
        anchors.fill: parent
        visible: !root.hasBg
        opacity: root.locked ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Repeater {
            model: [
                { x: 700, w: 110, y: 90, h: 588, c: "surface", o: 1.0 },
                { x: 830, w: 150, y: 60, h: 648, c: "high", o: 0.8 },
                { x: 1000, w: 280, y: 30, h: 708, c: "accent", o: 0.35 }
            ]

            delegate: Rectangle {
                required property var modelData

                x: modelData.x * root.u
                y: modelData.y * root.u
                width: modelData.w * root.u
                height: modelData.h * root.u
                opacity: modelData.o
                color: modelData.c === "accent" ? root.accent
                     : modelData.c === "high" ? root.surfaceHigh : root.surface

                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -0.25, 0, 0.25 * height / 2,
                                         0, 1, 0, 0,
                                         0, 0, 1, 0,
                                         0, 0, 0, 1)
                }
            }
        }
    }

    // ───────── lock screen ─────────
    Item {
        id: lockLayer
        anchors.fill: parent
        opacity: root.locked ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.unlock()
        }

        Row {
            x: 96 * root.u
            y: 72 * root.u
            spacing: 12 * root.u

            Rectangle {
                width: 14 * root.u
                height: 14 * root.u
                anchors.verticalCenter: parent.verticalCenter
                color: root.accent
            }

            Text {
                text: sddm.hostName || ""
                color: root.softColor
                font.family: root.fontFamily
                font.pixelSize: 18 * root.u
            }
        }

        Column {
            x: 96 * root.u
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -20 * root.u
            spacing: 14 * root.u

            Text {
                text: Qt.formatTime(root.now, "HH:mm")
                color: root.brightColor
                font.family: root.fontFamily
                font.pixelSize: 176 * root.u
                font.bold: true
                font.letterSpacing: -4 * root.u
            }

            Text {
                text: Qt.formatDate(root.now, "dddd, d MMMM")
                color: root.softColor
                font.family: root.fontFamily
                font.pixelSize: 28 * root.u
            }
        }

        Rectangle {
            x: 96 * root.u
            y: root.height - height - 88 * root.u
            width: hintRow.width + 56 * root.u
            height: 54 * root.u
            radius: height / 2
            color: root.surface

            Row {
                id: hintRow
                anchors.centerIn: parent
                spacing: 14 * root.u

                Rectangle {
                    width: 10 * root.u
                    height: 10 * root.u
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.accent
                }

                Text {
                    text: "Press any key to unlock"
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 18 * root.u
                }
            }
        }
    }

    // ───────── login screen ─────────
    Item {
        id: loginLayer
        anchors.fill: parent
        opacity: root.locked ? 0 : 1
        visible: opacity > 0
        enabled: !root.locked
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // click outside to close the session list
        MouseArea {
            anchors.fill: parent
            onClicked: root.sessionOpen = false
        }

        Rectangle {
            id: card

            property real shake: 0

            width: 440 * root.u
            height: cardColumn.implicitHeight + 80 * root.u
            radius: 28 * root.u
            color: root.surface
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: shake
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -10 * root.u

            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: card; property: "shake"; to: 14; duration: 50 }
                NumberAnimation { target: card; property: "shake"; to: -14; duration: 80 }
                NumberAnimation { target: card; property: "shake"; to: 8; duration: 70 }
                NumberAnimation { target: card; property: "shake"; to: 0; duration: 60 }
            }

            Column {
                id: cardColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 40 * root.u
                spacing: 20 * root.u

                // avatar
                Rectangle {
                    width: 104 * root.u
                    height: 104 * root.u
                    radius: width / 2
                    color: root.surfaceHigh
                    border.color: root.accent
                    border.width: 3 * root.u
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: root.userName.charAt(0).toUpperCase()
                        color: root.brightColor
                        font.family: root.fontFamily
                        font.pixelSize: 44 * root.u
                        font.bold: true
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4 * root.u

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.userName
                        color: root.brightColor
                        font.family: root.fontFamily
                        font.pixelSize: 26 * root.u
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: sddm.hostName || ""
                        color: root.softColor
                        font.family: root.fontFamily
                        font.pixelSize: 15 * root.u
                    }
                }

                // password field + submit
                Item {
                    width: parent.width
                    height: 60 * root.u

                    Rectangle {
                        id: field
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: submit.left
                        anchors.rightMargin: 12 * root.u
                        radius: 12 * root.u
                        color: root.surfaceHigh

                        // squares off the bottom corners (filled-field look)
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 12 * root.u
                            color: parent.color
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2 * root.u
                            color: root.accent
                        }

                        Text {
                            x: 16 * root.u
                            y: 8 * root.u
                            text: "Password"
                            color: root.softColor
                            font.family: root.fontFamily
                            font.pixelSize: 12 * root.u
                        }

                        TextInput {
                            id: passwordInput
                            x: 16 * root.u
                            y: 26 * root.u
                            width: parent.width - 16 * root.u - 52 * root.u
                            clip: true
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"
                            color: root.brightColor
                            selectionColor: root.accent
                            font.family: root.fontFamily
                            font.pixelSize: 20 * root.u
                            enabled: !root.busy

                            onAccepted: root.doLogin()
                            Keys.onEscapePressed: root.lock()
                        }

                        Item {
                            width: 40 * root.u
                            height: 40 * root.u
                            anchors.right: parent.right
                            anchors.rightMargin: 6 * root.u
                            anchors.verticalCenter: parent.verticalCenter

                            Icon {
                                anchors.centerIn: parent
                                size: 22 * root.u
                                color: root.showPassword ? root.brightColor : root.softColor
                                path: "M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z M9 12a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.showPassword = !root.showPassword
                            }
                        }
                    }

                    Rectangle {
                        id: submit
                        width: 56 * root.u
                        height: 56 * root.u
                        radius: width / 2
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.accent
                        opacity: root.busy ? 0.5 : (submitArea.containsMouse ? 0.88 : 1)

                        Icon {
                            anchors.centerIn: parent
                            size: 26 * root.u
                            strokeWidth: 2.4
                            color: root.bgColor
                            path: "M5 12h14M13 6l6 6-6 6"
                        }

                        MouseArea {
                            id: submitArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.doLogin()
                        }
                    }
                }

                Text {
                    visible: root.errorText !== ""
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.errorText
                    color: root.errorColor
                    font.family: root.fontFamily
                    font.pixelSize: 14 * root.u
                }
            }
        }

        // session picker (bottom-left)
        Rectangle {
            id: sessionPill
            x: 96 * root.u
            y: root.height - height - 72 * root.u
            height: 48 * root.u
            width: sessionRow.width + 40 * root.u
            radius: height / 2
            color: sessionArea.containsMouse ? root.surfaceHigh : root.surface

            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 10 * root.u

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.sessionName
                    color: root.fgColor
                    font.family: root.fontFamily
                    font.pixelSize: 16 * root.u
                }

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 18 * root.u
                    color: root.fgColor
                    path: "M6 9l6 6 6-6"
                }
            }

            MouseArea {
                id: sessionArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.sessionOpen = !root.sessionOpen
            }
        }

        Rectangle {
            visible: root.sessionOpen
            x: sessionPill.x
            y: sessionPill.y - height - 10 * root.u
            width: Math.max(220 * root.u, sessionPill.width)
            height: sessionList.height + 16 * root.u
            radius: 16 * root.u
            color: root.surface
            border.color: root.surfaceHigh
            border.width: 1

            Column {
                id: sessionList
                x: 8 * root.u
                y: 8 * root.u
                width: parent.width - 16 * root.u

                Repeater {
                    id: sessionRepeater
                    model: sessionModel

                    delegate: Rectangle {
                        id: sessionItem

                        readonly property string label: model.name

                        width: sessionList.width
                        height: 44 * root.u
                        radius: 10 * root.u
                        color: index === root.sessionIndex ? root.surfaceHigh
                             : (itemArea.containsMouse ? root.surfaceHigh : "transparent")

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 14 * root.u
                            text: sessionItem.label
                            color: root.fgColor
                            font.family: root.fontFamily
                            font.pixelSize: 16 * root.u
                        }

                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.sessionIndex = index
                                root.sessionOpen = false
                            }
                        }
                    }

                    onItemAdded: (i, item) => {
                        if (i === root.sessionIndex)
                            root.sessionName = item.label
                    }
                }
            }
        }

        // power buttons (bottom-right)
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 96 * root.u
            y: root.height - 48 * root.u - 72 * root.u
            spacing: 12 * root.u

            Repeater {
                model: [
                    { act: 0, d: "M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z" },
                    { act: 1, d: "M20 12a8 8 0 1 1-2.5-5.8M20 4v5h-5" },
                    { act: 2, d: "M12 3v9M6.3 6.8a8 8 0 1 0 11.4 0" }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: 48 * root.u
                    height: 48 * root.u
                    radius: width / 2
                    color: powerArea.containsMouse ? root.surfaceHigh : root.surface

                    Icon {
                        anchors.centerIn: parent
                        size: 22 * root.u
                        color: root.fgColor
                        path: modelData.d
                    }

                    MouseArea {
                        id: powerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (modelData.act === 0) sddm.suspend()
                            else if (modelData.act === 1) sddm.reboot()
                            else sddm.powerOff()
                        }
                    }
                }
            }
        }
    }
}
