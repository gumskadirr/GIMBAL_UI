#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

#include "device/api/DeviceTypes.h"

class DeviceSession;

// The only device object QML sees. Lives in the GUI thread and is owned by the application.
// Every measurement has a valid flag: no data, stale data and a new session are never shown as values.
class DeviceViewModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    Q_PROPERTY(QString connectionText READ connectionText NOTIFY connectionChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY connectionChanged)
    Q_PROPERTY(bool hasError READ hasError NOTIFY connectionChanged)
    Q_PROPERTY(QString errorDetail READ errorDetail NOTIFY connectionChanged)
    Q_PROPERTY(double angleDeg READ angleDeg NOTIFY measurementsChanged)
    Q_PROPERTY(bool angleValid READ angleValid NOTIFY measurementsChanged)
    Q_PROPERTY(double temperatureC READ temperatureC NOTIFY measurementsChanged)
    Q_PROPERTY(bool temperatureValid READ temperatureValid NOTIFY measurementsChanged)

public:
    static constexpr int kStaleAfterMs = 1000;

    explicit DeviceViewModel(DeviceSession *session, QObject *parent = nullptr);

    QString connectionText() const;
    bool connected() const;
    bool busy() const;
    bool hasError() const;
    QString errorDetail() const;
    double angleDeg() const { return m_sample.angleDeg.value; }
    bool angleValid() const { return m_sample.angleDeg.valid; }
    double temperatureC() const { return m_sample.temperatureC.value; }
    bool temperatureValid() const { return m_sample.temperatureC.valid; }

    Q_INVOKABLE void connectDevice();
    Q_INVOKABLE void disconnectDevice();
    // -1 when there is no current (non-stale) sample.
    Q_INVOKABLE qint64 msSinceLastSample() const { return m_sinceSample.isValid() ? m_sinceSample.elapsed() : -1; }

public slots:
    void retranslate(); // C++ texts are not refreshed by QQmlEngine::retranslate()

signals:
    void connectionChanged();
    void measurementsChanged();

private:
    void invalidate();
    void onSample(const DeviceSample &sample);
    void onSessionState();

    DeviceSession *m_session;
    DeviceSample m_sample; // default-constructed = all invalid
    QElapsedTimer m_sinceSample;
    QTimer m_staleCheck;
};
