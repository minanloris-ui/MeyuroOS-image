// SPDX-License-Identifier: GPL-3.0-or-later

var launcherTypes = [
    "org.kde.plasma.kickoff",
    "org.kde.plasma.kicker",
    "org.kde.plasma.dashboard"
];

var allPanels = panels();
for (var panelIndex = 0; panelIndex < allPanels.length; panelIndex++) {
    var panelWidgets = allPanels[panelIndex].widgets();

    for (var widgetIndex = 0; widgetIndex < panelWidgets.length; widgetIndex++) {
        var widget = panelWidgets[widgetIndex];
        if (launcherTypes.indexOf(widget.type) === -1) {
            continue;
        }

        widget.currentConfigGroup = ["General"];
        widget.writeConfig("icon", "meyuro-logo");
        widget.reloadConfig();
    }
}
