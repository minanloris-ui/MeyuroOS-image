// SPDX-License-Identifier: GPL-3.0-or-later

#include "taskbarcontextmenu.h"

#include <KLocalizedString>
#include <KPluginFactory>

#include <Plasma/Containment>

#include <QAction>
#include <QIcon>
#include <QLocale>
#include <QProcess>
#include <QStandardPaths>
#include <QStringList>

namespace
{
QString taskManagerActionText()
{
    const QString language = QLocale::system().name().left(2);
    if (language == QStringLiteral("ru")) {
        return QStringLiteral("Открыть диспетчер задач");
    }
    if (language == QStringLiteral("uk")) {
        return QStringLiteral("Відкрити диспетчер завдань");
    }
    return i18nc("@action:inmenu", "Open Task Manager");
}
}

TaskbarContextMenu::TaskbarContextMenu(QObject *parent, const QVariantList &args)
    : Plasma::ContainmentActions(parent, args)
    , m_taskManagerAction(new QAction(QIcon::fromTheme(QStringLiteral("utilities-system-monitor")),
                                      taskManagerActionText(),
                                      this))
    , m_separator(new QAction(this))
{
    m_separator->setSeparator(true);

    connect(m_taskManagerAction, &QAction::triggered, this, [] {
        const QString executable = QStandardPaths::findExecutable(QStringLiteral("plasma-systemmonitor"));
        if (!executable.isEmpty()) {
            QProcess::startDetached(executable,
                                    QStringList{QStringLiteral("--page-id"), QStringLiteral("overview.page")});
        }
    });
}

QList<QAction *> TaskbarContextMenu::contextualActions()
{
    QList<QAction *> result{m_taskManagerAction, m_separator};
    Plasma::Containment *panel = containment();

    if (!panel) {
        return result;
    }

    // Preserve Plasma's standard panel actions after the MeyuroOS entry.
    const auto panelActions = panel->actions();
    const QStringList standardActions{
        QStringLiteral("add widgets"),
        QStringLiteral("_context"),
        QStringLiteral("configure"),
        QStringLiteral("remove"),
    };

    for (const QString &name : standardActions) {
        QAction *action = panelActions.value(name);
        if (action && !action->text().isEmpty()) {
            result.append(action);
        }
    }

    return result;
}

K_PLUGIN_CLASS_WITH_JSON(TaskbarContextMenu, "meyuro-task-manager-contextmenu.json")

#include "taskbarcontextmenu.moc"
