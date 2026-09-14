// SPDX-License-Identifier: GPL-3.0-or-later

#include "meyuroupdatemodule.h"

#include <KLocalizedString>
#include <KPluginFactory>

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
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

QJsonObject deploymentImageStatus(const QJsonObject &deployment)
{
    return deployment.value(QStringLiteral("image")).toObject();
}

QString deploymentImageReference(const QJsonObject &deployment)
{
    const QJsonValue image = deploymentImageStatus(deployment).value(QStringLiteral("image"));

    // bootc's v1 schema stores the reference at image.image.image. Accept the
    // older flat representation as well, so the KCM remains useful on older images.
    if (image.isObject()) {
        return image.toObject().value(QStringLiteral("image")).toString();
    }
    return image.toString();
}

QString deploymentVersion(const QJsonObject &deployment)
{
    return deploymentImageStatus(deployment).value(QStringLiteral("version")).toString();
}
}

MeyuroUpdateModule::MeyuroUpdateModule(QObject *parent, const KPluginMetaData &metaData)
    : KQuickConfigModule(parent, metaData)
{
    setButtons(KQuickConfigModule::NoAdditionalButton);
    m_process.setProcessChannelMode(QProcess::SeparateChannels);

    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this] {
        const QByteArray output = m_process.readAllStandardOutput();
        if (m_operation == Operation::Status) {
            m_statusBuffer.append(output);
        } else {
            appendOutput(output);
        }
    });

    connect(&m_process, &QProcess::readyReadStandardError, this, [this] {
        appendOutput(m_process.readAllStandardError());
    });

    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            setHasError(true);
            setSummary(i18n("Could not start the update command."));
            appendOutput(m_process.errorString().toUtf8());
            setActivity({});
            setBusy(false);
            m_operation = Operation::None;
            m_statusContext = Operation::None;
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

bool MeyuroUpdateModule::hasError() const
{
    return m_hasError;
}

void MeyuroUpdateModule::refresh()
{
    refreshStatus(Operation::None);
}

void MeyuroUpdateModule::checkForUpdates()
{
    start(Operation::Check,
          QString::fromLatin1(PkexecPath),
          {QString::fromLatin1(BootcPath), QStringLiteral("upgrade"), QStringLiteral("--check")});
}

void MeyuroUpdateModule::downloadUpdate()
{
    start(Operation::Upgrade,
          QString::fromLatin1(PkexecPath),
          {QString::fromLatin1(BootcPath), QStringLiteral("upgrade")});
}

void MeyuroUpdateModule::queueRollback()
{
    start(Operation::Rollback,
          QString::fromLatin1(PkexecPath),
          {QString::fromLatin1(BootcPath), QStringLiteral("rollback")});
}

void MeyuroUpdateModule::reboot()
{
    start(Operation::Reboot,
          QString::fromLatin1(PkexecPath),
          {QString::fromLatin1(SystemctlPath), QStringLiteral("reboot")});
}

void MeyuroUpdateModule::refreshStatus(Operation context)
{
    if (m_busy) {
        return;
    }

    m_statusContext = context;
    start(Operation::Status,
          QString::fromLatin1(PkexecPath),
          {QString::fromLatin1(BootcPath), QStringLiteral("status"), QStringLiteral("--format=json")});
}

void MeyuroUpdateModule::start(Operation operation, const QString &program, const QStringList &arguments)
{
    if (m_busy) {
        return;
    }

    m_operation = operation;
    if (operation != Operation::Status) {
        m_statusContext = Operation::None;
    }
    m_statusBuffer.clear();
    setDetails({});
    setHasError(false);
    if (operation != Operation::Status || m_statusContext == Operation::None) {
        setSummary({});
    }
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
    case Operation::Reboot:
        setActivity(i18n("Requesting a restart…"));
        break;
    case Operation::None:
        break;
    }

    m_process.start(program, arguments);
}

void MeyuroUpdateModule::handleFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    const Operation completedOperation = m_operation;
    const bool succeeded = exitStatus == QProcess::NormalExit && exitCode == 0;

    if (completedOperation == Operation::Status) {
        m_statusBuffer.append(m_process.readAllStandardOutput());
        appendOutput(m_process.readAllStandardError());

        if (succeeded) {
            parseStatus(m_statusBuffer);
        } else {
            setHasError(true);
            if (exitCode == 126) {
                setSummary(i18n("Administrator authentication was cancelled. The system status was not read."));
            } else if (exitCode == 127) {
                setSummary(i18n("Administrator authentication failed. The system status was not read."));
            } else {
                setSummary(i18n("Could not read the bootc system status."));
            }
            m_statusContext = Operation::None;
        }
    } else {
        appendOutput(m_process.readAllStandardOutput());
        appendOutput(m_process.readAllStandardError());

        if (!succeeded) {
            setHasError(true);
            if (exitCode == 126) {
                setSummary(i18n("Administrator authentication was cancelled. No changes were made."));
            } else if (exitCode == 127) {
                setSummary(i18n("Administrator authentication failed. No changes were made."));
            } else if (completedOperation == Operation::Check) {
                setSummary(i18n("Could not check for updates. Open the details below for the error message."));
            } else if (completedOperation == Operation::Upgrade) {
                setSummary(
                    i18n("Could not download and prepare the update. Open the details below for the error message."));
            } else if (completedOperation == Operation::Rollback) {
                setSummary(
                    i18n("Could not prepare the previous version. Open the details below for the error message."));
            } else if (completedOperation == Operation::Reboot) {
                setSummary(i18n("Could not restart MeyuroOS. Open the details below for the error message."));
            } else {
                setSummary(i18n("The operation failed. Open the details below for the error message."));
            }
        } else if (completedOperation == Operation::Check) {
            setSummary(
                i18n("The update check completed. If a newer version is available, select Download and prepare."));
        } else if (completedOperation == Operation::Upgrade) {
            setSummary(i18n("The download finished. Verifying the prepared version…"));
            setRebootRecommended(true);
        } else if (completedOperation == Operation::Rollback) {
            setSummary(i18n("The rollback command finished. Verifying the prepared version…"));
            setRebootRecommended(true);
        } else if (completedOperation == Operation::Reboot) {
            setSummary(i18n("Restart requested."));
        }
    }

    m_operation = Operation::None;
    setActivity({});
    setBusy(false);

    if (succeeded && (completedOperation == Operation::Upgrade || completedOperation == Operation::Rollback)) {
        QTimer::singleShot(250, this, [this, completedOperation] {
            refreshStatus(completedOperation);
        });
    }
}

void MeyuroUpdateModule::parseStatus(const QByteArray &json)
{
    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(json, &parseError);

    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        setHasError(true);
        setSummary(i18n("Could not read the bootc system status."));
        appendOutput(json);
        m_statusContext = Operation::None;
        return;
    }

    const QJsonObject root = document.object();
    const QJsonObject status = root.value(QStringLiteral("status")).toObject();
    const QJsonObject booted = status.value(QStringLiteral("booted")).toObject();
    const QJsonObject staged = status.value(QStringLiteral("staged")).toObject();
    const QJsonObject rollback = status.value(QStringLiteral("rollback")).toObject();

    if (status.isEmpty() || booted.isEmpty()) {
        setHasError(true);
        setSummary(i18n("This system does not have a readable bootc deployment."));
        appendOutput(json);
        m_statusContext = Operation::None;
        return;
    }

    const QString bootOrder = root.value(QStringLiteral("spec"))
                                  .toObject()
                                  .value(QStringLiteral("bootOrder"))
                                  .toString();
    const bool rollbackQueued = status.value(QStringLiteral("rollbackQueued")).toBool()
        || bootOrder.compare(QStringLiteral("rollback"), Qt::CaseInsensitive) == 0;
    const QJsonObject prepared = rollbackQueued ? rollback : staged;
    const bool hasPreparedDeployment = !prepared.isEmpty();

    const QString newBootedImage = deploymentImageReference(booted);
    const QString newBootedVersion = deploymentVersion(booted);
    const QString newStagedVersion = deploymentVersion(prepared);

    if (m_bootedImage != newBootedImage || m_bootedVersion != newBootedVersion || m_stagedVersion != newStagedVersion) {
        m_bootedImage = newBootedImage;
        m_bootedVersion = newBootedVersion;
        m_stagedVersion = newStagedVersion;
        Q_EMIT statusChanged();
    }

    setRebootRecommended(hasPreparedDeployment);

    const Operation context = m_statusContext;
    m_statusContext = Operation::None;
    if (context == Operation::Upgrade && hasPreparedDeployment) {
        setSummary(i18n("The update was downloaded and prepared. Version %1 will start after restart.",
                        displayValue(m_stagedVersion)));
    } else if (context == Operation::Upgrade) {
        setSummary(i18n("No newer update was found. MeyuroOS remains on version %1.", displayValue(m_bootedVersion)));
    } else if (context == Operation::Rollback && hasPreparedDeployment) {
        setSummary(i18n("The previous version %1 is prepared. Restart to complete the rollback.",
                        displayValue(m_stagedVersion)));
    } else if (context == Operation::Rollback) {
        setHasError(true);
        setSummary(i18n("The rollback finished, but no previous version is available to start."));
    } else if (rollbackQueued) {
        setSummary(i18n("The previous version %1 is selected for the next start. Restart when you are ready.",
                        displayValue(m_stagedVersion)));
    } else if (m_rebootRecommended) {
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

    setDetails(m_details + cleanOutput);
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

void MeyuroUpdateModule::setHasError(bool hasError)
{
    if (m_hasError == hasError) {
        return;
    }
    m_hasError = hasError;
    Q_EMIT hasErrorChanged();
}

K_PLUGIN_CLASS_WITH_JSON(MeyuroUpdateModule, "kcm_meyuro_update.json")

#include "meyuroupdatemodule.moc"
