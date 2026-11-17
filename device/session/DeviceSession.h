#pragma once

#include <QObject>
#include <memory>

#include "device/api/IDeviceProvider.h"

// The single active device session. Each connect gets a new id; results carrying any other id
// are counted and dropped, so a late result of an old session can never change the current one.
class DeviceSession : public QObject
{
    Q_OBJECT

public:
    explicit DeviceSession(std::unique_ptr<IDeviceProvider> provider, QObject *parent = nullptr);
    ~DeviceSession() override;

    void connectDevice();    // closes an open session first
    void disconnectDevice();

    ConnectionState state() const { return m_state; }
    QString detail() const { return m_detail; }
    quint64 activeSessionId() const { return m_activeId; } // 0 = none
    quint64 staleDropped() const { return m_staleDropped; }

signals:
    void stateChanged();
    void sessionStarted(quint64 sessionId);
    void sampleAccepted(const DeviceSample &sample);
    void boardInfoAccepted(const BoardInfo &info);

private:
    void onProviderState(quint64 sessionId, ConnectionState state, const QString &detail);
    void onProviderSample(quint64 sessionId, const DeviceSample &sample);
    void onProviderBoardInfo(quint64 sessionId, const BoardInfo &info);
    void setState(ConnectionState state, const QString &detail);
    bool isActive(quint64 sessionId);

    std::unique_ptr<IDeviceProvider> m_provider;
    ConnectionState m_state = ConnectionState::Disconnected;
    QString m_detail; // raw provider text, not translated
    quint64 m_activeId = 0;
    quint64 m_nextId = 1;
    quint64 m_staleDropped = 0;
};
