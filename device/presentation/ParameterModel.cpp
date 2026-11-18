#include "ParameterModel.h"

#include "device/api/ParameterKeys.h"
#include "device/presentation/ServiceConnection.h"
#include "device/session/DeviceSession.h"

#include <QCoreApplication>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>

namespace {
const QString kFormat = QStringLiteral("ids-gimbal-parameters");
}

ParameterModel::ParameterModel(DeviceSession *session, ServiceConnection *connection, QObject *parent)
    : QObject(parent), m_session(session), m_connection(connection)
{
    connect(m_session, &DeviceSession::parametersAccepted, this, &ParameterModel::onDeviceValues);
    // Device values belong to one session; the user's edits are kept (they are not written yet).
    const auto clearDevice = [this] {
        if (m_device.isEmpty())
            return;
        m_device.clear();
        emit changed();
    };
    connect(m_session, &DeviceSession::sessionStarted, this, clearDevice);
    connect(m_session, &DeviceSession::stateChanged, this, [this, clearDevice] {
        if (m_session->state() != ConnectionState::Connected)
            clearDevice();
    });
    // A write the device accepted is what the device now holds.
    connect(m_session, &DeviceSession::commandFinished, this,
            [this](quint64, const DeviceCommand &command, const CommandResult &result) {
                if (command.kind == Command::WriteParameters && result.status == Command::Accepted)
                    onDeviceValues(command.args.value(QStringLiteral("values")).toMap());
            });
}

QVariantMap ParameterModel::values() const
{
    QVariantMap merged = m_device;
    for (auto it = m_edits.cbegin(); it != m_edits.cend(); ++it)
        merged.insert(it.key(), it.value());
    return merged;
}

bool ParameterModel::set(const QString &key, const QVariant &value)
{
    const auto spec = ParameterKeys::find(key);
    if (!spec)
        return false;
    const QVariant v = ParameterKeys::normalized(*spec, value);
    if (!v.isValid())
        return false;
    if (m_device.contains(key) && m_device.value(key) == v) {
        if (m_edits.remove(key) == 0)
            return true;
    } else {
        if (m_edits.value(key) == v)
            return true;
        m_edits.insert(key, v);
    }
    emit changed();
    return true;
}

void ParameterModel::revert(const QString &key)
{
    if (m_edits.remove(key) > 0)
        emit changed();
}

void ParameterModel::revertAll()
{
    if (m_edits.isEmpty())
        return;
    m_edits.clear();
    emit changed();
}

bool ParameterModel::read() { return m_connection->send(Command::ReadParameters); }

bool ParameterModel::write()
{
    if (m_edits.isEmpty())
        return false;
    return m_connection->send(Command::WriteParameters, {{QStringLiteral("values"), m_edits}});
}

bool ParameterModel::saveToFlash() { return m_connection->send(Command::SaveParametersToFlash); }
bool ParameterModel::restoreDefaults() { return m_connection->send(Command::RestoreDefaultParameters); }

void ParameterModel::onDeviceValues(const QVariantMap &incoming)
{
    for (auto it = incoming.cbegin(); it != incoming.cend(); ++it) {
        const auto spec = ParameterKeys::find(it.key());
        const QVariant v = spec ? ParameterKeys::normalized(*spec, it.value()) : QVariant();
        if (v.isValid())
            m_device.insert(it.key(), v); // unknown keys and bad values from the device are ignored
    }
    pruneEdits();
    emit changed();
}

void ParameterModel::pruneEdits()
{
    for (auto it = m_edits.begin(); it != m_edits.end();) {
        if (m_device.contains(it.key()) && m_device.value(it.key()) == it.value())
            it = m_edits.erase(it);
        else
            ++it;
    }
}

bool ParameterModel::fail(const QUrl &file, const QString &reason)
{
    emit profileFailed(file.toLocalFile(), reason);
    return false;
}

bool ParameterModel::saveProfile(const QUrl &file)
{
    const QVariantMap current = values();
    if (current.isEmpty())
        return fail(file, QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "No parameter values to save")));
    QJsonObject root{{QStringLiteral("format"), kFormat},
                     {QStringLiteral("version"), kProfileVersion},
                     {QStringLiteral("values"), QJsonObject::fromVariantMap(current)}};
    QSaveFile out(file.toLocalFile());
    if (!out.open(QIODevice::WriteOnly) || out.write(QJsonDocument(root).toJson()) < 0 || !out.commit())
        return fail(file, out.errorString());
    m_profileFile = file;
    emit changed();
    return true;
}

bool ParameterModel::loadProfile(const QUrl &file)
{
    QFile in(file.toLocalFile());
    if (!in.open(QIODevice::ReadOnly))
        return fail(file, in.errorString());
    QJsonParseError error;
    const QJsonDocument doc = QJsonDocument::fromJson(in.readAll(), &error);
    if (error.error != QJsonParseError::NoError || !doc.isObject())
        return fail(file, QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "Not a parameter profile")));
    const QJsonObject root = doc.object();
    if (root.value(QStringLiteral("format")).toString() != kFormat)
        return fail(file, QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "Not a parameter profile")));
    if (root.value(QStringLiteral("version")).toInt() != kProfileVersion)
        return fail(file, QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "Unsupported profile version")));

    // All or nothing: one bad entry rejects the whole file.
    const QVariantMap raw = root.value(QStringLiteral("values")).toObject().toVariantMap();
    QVariantMap loaded;
    for (auto it = raw.cbegin(); it != raw.cend(); ++it) {
        const auto spec = ParameterKeys::find(it.key());
        if (!spec)
            return fail(file, QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "Unknown parameter in the file")));
        const QVariant v = ParameterKeys::normalized(*spec, it.value());
        if (!v.isValid())
            return fail(file, QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "Value out of range or of the wrong type in the file")));
        loaded.insert(it.key(), v);
    }
    if (loaded.isEmpty())
        return fail(file, QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "No parameter values in the file")));

    m_edits.clear();
    for (auto it = loaded.cbegin(); it != loaded.cend(); ++it)
        m_edits.insert(it.key(), it.value());
    pruneEdits();
    m_profileFile = file;
    emit changed();
    return true;
}
