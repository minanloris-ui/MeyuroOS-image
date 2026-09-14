// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: root

    implicitWidth: Kirigami.Units.gridUnit * 38
    implicitHeight: Kirigami.Units.gridUnit * 32

    Kirigami.FormLayout {
        anchors.fill: parent

        Item {
            Kirigami.FormData.isSection: true
            implicitHeight: headerLayout.implicitHeight

            RowLayout {
                id: headerLayout
                anchors.fill: parent
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: "meyuro-logo"
                    implicitWidth: Kirigami.Units.iconSizes.huge
                    implicitHeight: implicitWidth
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Heading {
                        text: i18n("MeyuroOS Updates")
                        level: 1
                    }

                    Controls.Label {
                        Layout.fillWidth: true
                        text: i18n("Atomic updates are prepared in the background and activated after a restart.")
                        wrapMode: Text.WordWrap
                        opacity: 0.75
                    }
                }
            }
        }

        Kirigami.InlineMessage {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            visible: text.length > 0
            text: kcm.summary
            type: kcm.rebootRecommended ? Kirigami.MessageType.Positive : Kirigami.MessageType.Information
        }

        Controls.GroupBox {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            title: i18n("System status")

            GridLayout {
                width: parent.width
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                Controls.Label {
                    text: i18n("Image:")
                    opacity: 0.7
                }
                Controls.Label {
                    Layout.fillWidth: true
                    text: kcm.bootedImage || i18n("Unknown")
                    elide: Text.ElideMiddle
                }

                Controls.Label {
                    text: i18n("Current version:")
                    opacity: 0.7
                }
                Controls.Label {
                    Layout.fillWidth: true
                    text: kcm.bootedVersion || i18n("Unknown")
                }

                Controls.Label {
                    text: i18n("Prepared version:")
                    opacity: 0.7
                }
                Controls.Label {
                    Layout.fillWidth: true
                    text: kcm.stagedVersion || i18n("None")
                }
            }
        }

        RowLayout {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Controls.Button {
                text: i18n("Check for updates")
                icon.name: "view-refresh"
                enabled: !kcm.busy
                onClicked: kcm.checkForUpdates()
            }

            Controls.Button {
                text: i18n("Download and prepare")
                icon.name: "download"
                enabled: !kcm.busy
                onClicked: kcm.downloadUpdate()
            }

            Controls.Button {
                text: i18n("Restart")
                icon.name: "system-reboot"
                enabled: !kcm.busy && kcm.rebootRecommended
                highlighted: kcm.rebootRecommended
                onClicked: restartDialog.open()
            }

            Item {
                Layout.fillWidth: true
            }

            Controls.ToolButton {
                icon.name: "view-refresh"
                enabled: !kcm.busy
                onClicked: kcm.refresh()
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: i18n("Refresh status")
            }
        }

        RowLayout {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            visible: kcm.busy

            Controls.BusyIndicator {
                running: parent.visible
            }

            Controls.Label {
                Layout.fillWidth: true
                text: kcm.activity
            }
        }

        Controls.GroupBox {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            visible: kcm.details.length > 0
            title: i18n("Details")

            Controls.ScrollView {
                width: parent.width
                implicitHeight: Kirigami.Units.gridUnit * 8

                Controls.TextArea {
                    text: kcm.details
                    readOnly: true
                    selectByMouse: true
                    wrapMode: Text.WrapAnywhere
                    font.family: "monospace"
                }
            }
        }

        RowLayout {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true

            Controls.Label {
                Layout.fillWidth: true
                text: i18n("If a new version causes a problem, prepare the previous deployment and restart.")
                wrapMode: Text.WordWrap
                opacity: 0.7
            }

            Controls.Button {
                text: i18n("Roll back")
                icon.name: "edit-undo"
                enabled: !kcm.busy
                onClicked: rollbackDialog.open()
            }
        }
    }

    Controls.Dialog {
        id: restartDialog
        anchors.centerIn: parent
        modal: true
        title: i18n("Restart MeyuroOS?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        onAccepted: kcm.reboot()

        Controls.Label {
            text: i18n("Save your work before restarting.")
        }
    }

    Controls.Dialog {
        id: rollbackDialog
        anchors.centerIn: parent
        modal: true
        title: i18n("Prepare the previous version?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        onAccepted: kcm.queueRollback()

        Controls.Label {
            text: i18n("The current version remains active until you restart.")
        }
    }
}
