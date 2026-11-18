#pragma once

#include <QHash>
#include <QObject>
#include <memory>

#include "device/api/IDeviceProvider.h"

// The single active device session of one service. Each connect gets a new id; results carrying any other id
// are counted and dropped, so a late result of an old session can never change the current one.
// Commands sent in a session are pending until answered; when the session ends they finish as Cancelled.
class DeviceSession : public QObject
{
    Q_OBJECT

public:
    explicit DeviceSession(std::unique_ptr<IDeviceProvider> provider, QObject *parent = nullptr);
    ~DeviceSession() override;

    // Where the next connectDevice() connects; the provider validates it and reports Error if unusable.
    void setTarget(const ConnectionTarget &target) { m_target = target; }
    ConnectionTarget target() const { return m_target; }
    void connectDevice();    // closes an open session first
    void disconnectDevice();

    ConnectionState state() const { return m_state; }
    QString detail() const { return m_detail; }
    quint64 activeSessionId() const { return m_activeId; } // 0 = none
    quint64 staleDropped() const { return m_staleDropped; }
    quint64 txBytes() const { return m_txBytes; } // of the current or last session
    quint64 rxBytes() const { return m_rxBytes; }

    bool supportsCommands() const { return m_provider->supportsCommands(); }
    // Request id (> 0) of the sent command; 0 when not connected or the provider has no commands.
    quint64 send(const DeviceCommand &command);
    QList<DeviceCommand> pendingCommands() const { return m_pending.values(); }

signals:
    void stateChanged();
    void sessionStarted(quint64 sessionId);
    void sampleAccepted(const DeviceSample &sample);
    void imageSampleAccepted(const ImageSample &sample);
    void boardInfoAccepted(const BoardInfo &info);
    void bitReportAccepted(const BitReport &report);
    void crosstalkResultAccepted(const CrosstalkResult &result);
    void imuBiasAccepted(const ImuBias &bias);
    void stepMetricsAccepted(const StepMetrics &metrics);
    // A pending command made progress (progress of a finished or stale request is dropped).
    void commandProgressed(quint64 requestId, const DeviceCommand &command, int percent, const QString &stage);
    void parametersAccepted(const QVariantMap &values);
    void commandFinished(quint64 requestId, const DeviceCommand &command, const CommandResult &result);
    void pendingChanged();
    void trafficAccepted();

private:
    void onProviderState(quint64 sessionId, ConnectionState state, const QString &detail);
    void onProviderSample(quint64 sessionId, const DeviceSample &sample);
    void onProviderBoardInfo(quint64 sessionId, const BoardInfo &info);
    void onProviderCommandFinished(quint64 sessionId, quint64 requestId, const CommandResult &result);
    void cancelPending();
    void setState(ConnectionState state, const QString &detail);
    bool isActive(quint64 sessionId);

    std::unique_ptr<IDeviceProvider> m_provider;
    ConnectionState m_state = ConnectionState::Disconnected;
    QString m_detail; // raw provider text, not translated
    quint64 m_activeId = 0;
    quint64 m_nextId = 1;
    quint64 m_staleDropped = 0;
    quint64 m_txBytes = 0;
    quint64 m_rxBytes = 0;
    ConnectionTarget m_target;
    QHash<quint64, DeviceCommand> m_pending; // request id -> command, current session only
    quint64 m_nextRequestId = 1;
};
