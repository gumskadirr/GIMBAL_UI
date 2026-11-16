#pragma once

#include <QObject>

#include "DeviceTypes.h"

// Boundary between the session and a data source (real transport or sample data).
// Every result carries the session id given to start(); the session drops results of old ids.
class IDeviceProvider : public QObject
{
    Q_OBJECT

public:
    using QObject::QObject;

    // Must not emit synchronously from inside start(); report results from the event loop.
    virtual void start(quint64 sessionId) = 0;
    virtual void stop() = 0; // idempotent

signals:
    void stateChanged(quint64 sessionId, ConnectionState state, const QString &detail);
    void sampleReceived(quint64 sessionId, const DeviceSample &sample);
};
