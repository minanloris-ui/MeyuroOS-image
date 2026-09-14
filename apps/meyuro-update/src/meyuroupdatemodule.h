// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <KQuickConfigModule>

#include <QProcess>
#include <QString>

class MeyuroUpdateModule final : public KQuickConfigModule
{
    Q_OBJECT

    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString activity READ activity NOTIFY activityChanged)
    Q_PROPERTY(QString summary READ summary NOTIFY summaryChanged)
    Q_PROPERTY(QString details READ details NOTIFY detailsChanged)
    Q_PROPERTY(QString bootedImage READ bootedImage NOTIFY statusChanged)
    Q_PROPERTY(QString bootedVersion READ bootedVersion NOTIFY statusChanged)
    Q_PROPERTY(QString stagedVersion READ stagedVersion NOTIFY statusChanged)
    Q_PROPERTY(bool rebootRecommended READ rebootRecommended NOTIFY rebootRecommendedChanged)
    Q_PROPERTY(bool hasError READ hasError NOTIFY hasErrorChanged)

public:
    explicit MeyuroUpdateModule(QObject *parent, const KPluginMetaData &metaData);

    [[nodiscard]] bool busy() const;
    [[nodiscard]] QString activity() const;
    [[nodiscard]] QString summary() const;
    [[nodiscard]] QString details() const;
    [[nodiscard]] QString bootedImage() const;
    [[nodiscard]] QString bootedVersion() const;
    [[nodiscard]] QString stagedVersion() const;
    [[nodiscard]] bool rebootRecommended() const;
    [[nodiscard]] bool hasError() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void checkForUpdates();
    Q_INVOKABLE void downloadUpdate();
    Q_INVOKABLE void queueRollback();
    Q_INVOKABLE void reboot();

Q_SIGNALS:
    void busyChanged();
    void activityChanged();
    void summaryChanged();
    void detailsChanged();
    void statusChanged();
    void rebootRecommendedChanged();
    void hasErrorChanged();

private:
    enum class Operation {
        None,
        Status,
        Check,
        Upgrade,
        Rollback,
        Reboot,
    };

    void refreshStatus(Operation context);
    void start(Operation operation, const QString &program, const QStringList &arguments);
    void handleFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void parseStatus(const QByteArray &json);
    void appendOutput(const QByteArray &output);
    void setBusy(bool busy);
    void setActivity(const QString &activity);
    void setSummary(const QString &summary);
    void setDetails(const QString &details);
    void setRebootRecommended(bool rebootRecommended);
    void setHasError(bool hasError);

    QProcess m_process;
    Operation m_operation = Operation::None;
    Operation m_statusContext = Operation::None;
    bool m_busy = false;
    bool m_rebootRecommended = false;
    bool m_hasError = false;
    QString m_activity;
    QString m_summary;
    QString m_details;
    QString m_bootedImage;
    QString m_bootedVersion;
    QString m_stagedVersion;
    QByteArray m_statusBuffer;
};
