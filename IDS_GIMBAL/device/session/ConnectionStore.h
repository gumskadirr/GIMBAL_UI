#pragma once

#include <QObject>
#include <optional>

#include "device/api/DeviceTypes.h"

// Last used connection settings of each service, kept on this computer (architecture §12, rule 1).
// Same store as the application preferences (organization / application name); keys connection/<service>/...
class ConnectionStore : public QObject
{
    Q_OBJECT

public:
    explicit ConnectionStore(QObject *parent = nullptr); // platform store
    explicit ConnectionStore(const QString &iniFilePath, QObject *parent = nullptr);

    // nullopt: never set, or the stored values are not a usable target.
    std::optional<ConnectionTarget> load(const QString &service) const;
    bool save(const QString &service, const ConnectionTarget &target); // false and writeFailed on error

signals:
    void writeFailed(const QString &service);

private:
    QString m_iniFilePath; // empty = platform store
};
