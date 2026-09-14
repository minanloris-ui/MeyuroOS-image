// SPDX-License-Identifier: GPL-3.0-or-later

const panelList = panels();

for (let index = 0; index < panelList.length; index += 1) {
    const panel = panelList[index];
    panel.currentConfigGroup = ["ActionPlugins"];
    panel.writeConfig("RightButton;NoModifier", "org.meyuroos.contextmenu");
    panel.reloadConfig();
}
