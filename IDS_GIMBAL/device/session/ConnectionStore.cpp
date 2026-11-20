#include "ConnectionStore.h"

#include <QSettings>
#include <memory>

namespace {
std::unique_ptr<QSettings> open(const QString &iniFilePath)
{
    return iniFilePath.isEmpty() ? std::make_unique<QSettings>()
                                 : std::make_unique<QSettings>(iniFilePath, QSettings::IniFormat);
}
} // namespace

ConnectionStore::ConnectionStore(QObject *parent) : QObject(parent) {}

ConnectionStore::ConnectionStore(const QString &iniFilePath, QObject *parent)
    : QObject(parent), m_iniFilePath(iniFilePath)
{
}

std::optional<ConnectionTarget> ConnectionStore::load(const QString &service) const
{
    const auto settings = open(m_iniFilePath);
    settings->beginGroup(QStringLiteral("connection/") + service);
    const QString transport = settings->value(QStringLiteral("transport")).toString();
    ConnectionTarget t;
    if (transport == QLatin1String("serial")) {
        t.transport = ConnectionTarget::Transport::Serial;
        t.serialPort = settings->value(QStringLiteral("serialPort")).toString();
        t.baudRate = settings->value(QStringLiteral("baudRate")).toInt();
        t.dataBits = settings->value(QStringLiteral("dataBits")).toInt();
        t.stopBits = settings->value(QStringLiteral("stopBits")).toInt();
        const auto parity = parityFromName(settings->value(QStringLiteral("parity")).toString());
        if (!parity)
            return std::nullopt;
        t.parity = *parity;
        if (t.serialPort.isEmpty() || t.baudRate <= 0 || (t.dataBits != 7 && t.dataBits != 8)
            || (t.stopBits != 1 && t.stopBits != 2))
            return std::nullopt;
    } else if (transport == QLatin1String("udp")) {
        t.transport = ConnectionTarget::Transport::Udp;
        t.host = settings->value(QStringLiteral("host")).toString();
        const int port = settings->value(QStringLiteral("port")).toInt();
        if (t.host.isEmpty() || port <= 0 || port > 65535)
            return std::nullopt;
        t.port = quint16(port);
    } else {
        return std::nullopt; // never set or unknown transport
    }
    return t;
}

bool ConnectionStore::save(const QString &service, const ConnectionTarget &target)
{
    const auto settings = open(m_iniFilePath); // fresh object: QSettings::status() keeps its first error
    settings->beginGroup(QStringLiteral("connection/") + service);
    settings->remove(QString()); // no leftovers of the other transport
    if (target.transport == ConnectionTarget::Transport::Serial) {
        settings->setValue(QStringLiteral("transport"), QStringLiteral("serial"));
        settings->setValue(QStringLiteral("serialPort"), target.serialPort);
        settings->setValue(QStringLiteral("baudRate"), target.baudRate);
        settings->setValue(QStringLiteral("dataBits"), target.dataBits);
        settings->setValue(QStringLiteral("parity"), parityName(target.parity));
        settings->setValue(QStringLiteral("stopBits"), target.stopBits);
    } else {
        settings->setValue(QStringLiteral("transport"), QStringLiteral("udp"));
        settings->setValue(QStringLiteral("host"), target.host);
        settings->setValue(QStringLiteral("port"), int(target.port));
    }
    settings->endGroup();
    settings->sync();
    if (settings->status() == QSettings::NoError)
        return true;
    emit writeFailed(service);
    return false;
}
