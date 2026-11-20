#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

#include "device/api/DeviceTypes.h"
#include "device/presentation/ServiceConnection.h"

class DeviceSession;

// IDS Image service data as QML sees it; its connection is `connection`. Like MainControlViewModel, every value
// carries a valid flag: no data, stale data and a new session are never shown as values.
class ImageViewModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    Q_PROPERTY(ServiceConnection *connection READ connection CONSTANT)
    // Latest telemetry; every field is invalid when there is none or it went stale.
    Q_PROPERTY(ImageSample sample READ sample NOTIFY sampleChanged)

public:
    static constexpr int kStaleAfterMs = 1000;

    ImageViewModel(DeviceSession *session, ServiceConnection *connection, QObject *parent = nullptr);

    ServiceConnection *connection() const { return m_connection; }
    ImageSample sample() const { return m_sample; }

signals:
    void sampleChanged();

private:
    void clear();

    ServiceConnection *m_connection;
    ImageSample m_sample; // default-constructed = all invalid
    bool m_hasSample = false;
    QElapsedTimer m_sinceSample;
    QTimer m_staleCheck;
};
