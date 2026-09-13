// SPDX-License-Identifier: GPL-3.0-or-later

#include "meyuroupdatemodule.h"

#include <KLocalizedString>
#include <KPluginFactory>

#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QTimer>

namespace
{
constexpr auto BootcPath = "/usr/bin/bootc";
constexpr auto PkexecPath = "/usr/bin/pkexec";
constexpr auto SystemctlPath = "/usr/bin/systemctl";

QString displayValue(const QString &value)
{
    return value.isEmpty() ? i18nc("Unknown system version", "Unknown") : value;
}
}

MeyuroUpdateModule::MeyuroUpdateModule(QObject *parent, const KPluginMetaData &metaData)
    : KQuickConfigModule(parent, metaData)
{
    setButtons(KQuickConfigModule::NoAdditionalButton);
    m_process.setProcessChannelMode(QProcess::MergedChannels);

    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this] {
        const QByteArray output = m_process.readAllStandardOutput();
        if (m_operation == Operation::Status) {
            m_statusBuffer.append(output);
        } else {
            appendOutput(output);
        }
    });

    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            setSummary(i18n("Could not start the update command."));
            appendOutput(m_process.errorString().toUtf8());
            setBusy(false);
            m_operation = Operation::None;
        }
    });

    connect(&m_process,
            qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this,
            &MeyuroUpdateModule::handleFinished);

    QTimer::singleShot(0, this, &MeyuroUpdateModule::refresh);
}

bool MeyuroUpdateModule::busy() const
{
    return m_busy;
}

QString MeyuroUpdateModule::activity() const
{
    return m_activity;
}

QString MeyuroUpdateModule::summary() const
{
    return m_summary;
}

QString MeyuroUpdateModule::details() const
{
    return m_details;
}

QString MeyuroUpdateModule::bootedImage() const
{
    return m_bootedImage;
}

QString MeyuroUpdateModule::bootedVersion() const
{
    return m_bootedVersion;
}

QString MeyuroUpdateModule::stagedVersion() const
{
    return m_stagedVersion;
}

bool MeyuroUpdateModule::rebootRecommended() const
{
    return m_rebootRecommended;
}

void MeyuroUpdateModule::refresh()
{
    start(Operation::Status, QString::fromLatin1(BootcPath), {QStringLiteral("status"), QStringLiteral("--format=json")});
}

void MeyuroUpdateModule::checkForUpdates()
{
    start(Operation::Check,
          QString::fromLatin1(PkexecPath),
          {QString::fromLatin1(BootcPath), QStringLiteral("upgrade"), QStringLiteral("--check")});
}

void MeyuroUpdateModule::downloadUpdate()
{
    start(Operation::Upgrade, QString::fromLatin1(PkexecPath), {QString::fromLatin1(BootcPath), QStringLiteral("upgrade")});
}

void MeyuroUpdateModule::queueRollback()
{
    start(Operation::Rollback, QString::fromLatin1(PkexecPath), {QString::fromLatin1(BootcPath), QStringLiteral("rollback")});
}

void MeyuroUpdateModule::reboot()
{
    if (!QProcess::startDetached(QString::fromLatin1(SystemctlPath), {QStringLiteral("reboot")})) {
        setSummary(i18n("Could not request a restart."));
    }
}

void MeyuroUpdateModule::start(Operation operation, const QString &program, const QStringList &arguments)
{
    if (m_busy) {
        return;
    }

    m_operation = operation;
    m_statusBuffer.clear();
    setDetails({});
    setBusy(true);

    switch (operation) {
    case Operation::Status:
        setActivity(i18n("Reading system status…"));
        break;
    case Operation::Check:
        setActivity(i18n("Checking for updates…"));
        break;
    case Operation::Upgrade:
        setActivity(i18n("Downloading and preparing the update…"));
        break;
    case Operation::Rollback:
        setActivity(i18n("Preparing the previous version…"));
        break;
    case Operation::None:
        break;
    }

    m_process.start(program, arguments);
}

void MeyuroUpdateModule::handleFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    const Operation completedOperation = m_operation;

    if (completedOperation == Operation::Status) {
        m_statusBuffer.append(m_process.readAllStandardOutput());
        parseStatus(m_statusBuffer);
    } else {
        appendOutput(m_process.readAllStandardOutput());

        const bool succeeded = exitStatus == QProcess::NormalExit && exitCode == 0;
        if (!succeeded) {
            setSummary(i18n("The operation failed. Open the details below for the error message."));
        } else if (completedOperation == Operation::Check) {
            setSummary(i18n("The update check completed."));
        } else if (completedOperation == Operation::Upgrade) {
            setSummary(i18n("The update is ready. Restart to start the new MeyuroOS version."));
            setRebootRecommended(true);
        } else if (completedOperation == Operation::Rollback) {
            setSummary(i18n("The previous version is ready. Restart to complete the rollback."));
            setRebootRecommended(true);
        }
    }

    m_operation = Operation::None;
    setActivity({});
    setBusy(false);

    if (completedOperation == Operation::Upgrade || completedOperation == Operation::Rollback) {
        QTimer::singleShot(250, this, &MeyuroUpdateModule::refresh);
    }
}

void MeyuroUpdateModule::parseStatus(const QByteArray &json)
{
    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(json, &parseError);

    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        setSummary(i18n("Could not read the bootc system status."));
        setDetails(QString::fromUtf8(json));
        return;
    }

    const QJsonObject status = document.object().value(QStringLiteral("status")).toObject();
    const QJsonObject booted = status.value(QStringLiteral("booted")).toObject();
    const QJsonObject bootedImage = booted.value(QStringLiteral("image")).toObject();
    const QJsonObject staged = status.value(QStringLiteral("staged")).toObject();
    const QJsonObject stagedImage = staged.value(QStringLiteral("image")).toObject();

    const QString newBootedImage = bootedImage.value(QStringLiteral("image")).toString();
    const QString newBootedVersion = bootedImage.value(QStringLiteral("version")).toString();
    const QString newStagedVersion = stagedImage.value(QStringLiteral("version")).toString();

    if (m_bootedImage != newBootedImage || m_bootedVersion != newBootedVersion || m_stagedVersion != newStagedVersion) {
        m_bootedImage = newBootedImage;
        m_bootedVersion = newBootedVersion;
        m_stagedVersion = newStagedVersion;
        Q_EMIT statusChanged();
    }

    setRebootRecommended(!m_stagedVersion.isEmpty());
    if (m_rebootRecommended) {
        setSummary(i18n("Version %1 is prepared. Restart when you are ready.", displayValue(m_stagedVersion)));
    } else {
        setSummary(i18n("MeyuroOS is running version %1.", displayValue(m_bootedVersion)));
    }
}

void MeyuroUpdateModule::appendOutput(const QByteArray &output)
{
    if (output.isEmpty()) {
        return;
    }

    QString cleanOutput = QString::fromUtf8(output);
    static const QRegularExpression ansiExpression(QStringLiteral("\\x1B(?:[@-Z\\\\-_]|\\[[0-?]*[ -/]*[@-~])"));
    cleanOutput.remove(ansiExpression);

    const QString newDetails = m_details + cleanOutput;
    setDetails(newDetails.trimmed());
}

void MeyuroUpdateModule::setBusy(bool busy)
{
    if (m_busy == busy) {
        return;
    }
    m_busy = busy;
    Q_EMIT busyChanged();
}

void MeyuroUpdateModule::setActivity(const QString &activity)
{
    if (m_activity == activity) {
        return;
    }
    m_activity = activity;
    Q_EMIT activityChanged();
}

void MeyuroUpdateModule::setSummary(const QString &summary)
{
    if (m_summary == summary) {
        return;
    }
    m_summary = summary;
    Q_EMIT summaryChanged();
}

void MeyuroUpdateModule::setDetails(const QString &details)
{
    if (m_details == details) {
        return;
    }
    m_details = details;
    Q_EMIT detailsChanged();
}

void MeyuroUpdateModule::setRebootRecommended(bool rebootRecommended)
{
    if (m_rebootRecommended == rebootRecommended) {
        return;
    }
    m_rebootRecommended = rebootRecommended;
    Q_EMIT rebootRecommendedChanged();
}

K_PLUGIN_CLASS_WITH_JSON(MeyuroUpdateModule, "kcm_meyuro_update.json")

#include "meyuroupdatemodule.moc"
