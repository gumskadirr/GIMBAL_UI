#pragma once

#include <QObject>
#include <QUrl>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class DeviceSession;
class ServiceConnection;

// Device parameters as the UI edits them (architecture §13). Keeps what the device reported, the user's
// edits on top of it, and the profile file the edits came from. Keys and checks: device/api/ParameterKeys.h.
// Loading a profile never sends anything: its differences show as unsaved edits until Write.
class ParameterModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    // What the page shows: device values with the edits applied. A key without a value is missing.
    Q_PROPERTY(QVariantMap values READ values NOTIFY changed)
    Q_PROPERTY(QVariantMap deviceValues READ deviceValues NOTIFY changed)
    Q_PROPERTY(QStringList modifiedKeys READ modifiedKeys NOTIFY changed)
    // "N UNSAVED CHANGES": edits not yet written to the device.
    Q_PROPERTY(int unsavedCount READ unsavedCount NOTIFY changed)
    Q_PROPERTY(QUrl profileFile READ profileFile NOTIFY changed)

public:
    static constexpr int kProfileVersion = 1;

    ParameterModel(DeviceSession *session, ServiceConnection *connection, QObject *parent = nullptr);

    QVariantMap values() const;
    QVariantMap deviceValues() const { return m_device; }
    QStringList modifiedKeys() const { return m_edits.keys(); }
    int unsavedCount() const { return int(m_edits.size()); }
    QUrl profileFile() const { return m_profileFile; }

    // False (nothing changes) for an unknown key or a value outside its type / range.
    Q_INVOKABLE bool set(const QString &key, const QVariant &value);
    Q_INVOKABLE void revert(const QString &key);
    Q_INVOKABLE void revertAll();

    // Device commands; false when nothing was sent (no commands, already pending, nothing to write).
    // An optional key prefix (e.g. "heater.") limits a read to those keys and a write to those edits; the
    // other edits stay unsaved.
    Q_INVOKABLE bool read(const QString &prefix = {});
    Q_INVOKABLE bool write(const QString &prefix = {});
    Q_INVOKABLE bool saveToFlash();
    Q_INVOKABLE bool restoreDefaults();

    // Profile file: JSON {"format": "ids-gimbal-parameters", "version": 1, "values": {...}}.
    // On failure nothing changes and profileFailed reports why.
    Q_INVOKABLE bool saveProfile(const QUrl &file);
    Q_INVOKABLE bool loadProfile(const QUrl &file);

signals:
    void changed();
    void profileFailed(const QString &file, const QString &reason);

private:
    void onDeviceValues(const QVariantMap &incoming);
    void pruneEdits(); // drop edits equal to the device value
    bool fail(const QUrl &file, const QString &reason);

    DeviceSession *m_session;
    ServiceConnection *m_connection;
    QVariantMap m_device;
    QVariantMap m_edits;
    QUrl m_profileFile;
};
