// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <Plasma/ContainmentActions>

class QAction;

class TaskbarContextMenu final : public Plasma::ContainmentActions
{
    Q_OBJECT

public:
    explicit TaskbarContextMenu(QObject *parent, const QVariantList &args);

    QList<QAction *> contextualActions() override;

private:
    QAction *m_taskManagerAction = nullptr;
    QAction *m_separator = nullptr;
};
