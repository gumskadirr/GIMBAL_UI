#pragma once

#include <QObject>
#include <QTimer>

#include "DeviceCommand.h"
#include "DeviceTypes.h"

// Boundary between the session and a data source (real transport or sample data).
// Every result carries the session id given to start(); the session drops results of old ids.
class IDeviceProvider : public QObject
{
    Q_OBJECT

public:
    using QObject::QObject;

    // Must not emit synchronously from inside start() or send(); report results from the event loop.
    virtual void start(quint64 sessionId, const ConnectionTarget &target) = 0;
    virtual void stop() = 0; // idempotent

    // True when send() can carry out commands; the UI enables command buttons only then.
    virtual bool supportsCommands() const { return false; }
    // Answer with commandFinished(sessionId, requestId, ...) exactly once. The default has no protocol.
    virtual void send(quint64 sessionId, quint64 requestId, const DeviceCommand &command)
    {
        Q_UNUSED(command)
        QTimer::singleShot(0, this, [this, sessionId, requestId] {
            emit commandFinished(sessionId, requestId, {Command::Unsupported, {}});
        });
    }

signals:
    void stateChanged(quint64 sessionId, ConnectionState state, const QString &detail);
    void sampleReceived(quint64 sessionId, const DeviceSample &sample); // streamed telemetry
    void boardInfoReceived(quint64 sessionId, const BoardInfo &info);   // read-once data, any time in a session
    void bitReportReceived(quint64 sessionId, const BitReport &report); // after RunBit and on connect
    void crosstalkResultReceived(quint64 sessionId, const CrosstalkResult &result); // after StartCrosstalkCheck
    void imuBiasReceived(quint64 sessionId, const ImuBias &bias);                   // after StartImuBiasCalibration
    // Progress of a long command (e.g. UpdateFirmware): percent 0-100 and a raw stage text; the final
    // answer still comes with commandFinished.
    void commandProgress(quint64 sessionId, quint64 requestId, int percent, const QString &stage);
    // Parameter values (all or some keys of device/api/ParameterKeys.h), e.g. after ReadParameters.
    void parametersReceived(quint64 sessionId, const QVariantMap &values);
    void commandFinished(quint64 sessionId, quint64 requestId, const CommandResult &result);
};
