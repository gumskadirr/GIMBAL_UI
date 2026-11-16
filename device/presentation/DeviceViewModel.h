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
    // Units: angles in degrees, temperatures in °C, voltage in V (see DeviceSample).
    Q_PROPERTY(Measurement pan READ pan NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement panRef READ panRef NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement tilt READ tilt NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement tiltRef READ tiltRef NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement gimbalTemp READ gimbalTemp NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement imuTemp READ imuTemp NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement supplyVoltage READ supplyVoltage NOTIFY measurementsChanged)
    Q_PROPERTY(Flag safeControl READ safeControl NOTIFY measurementsChanged)

public:
    static constexpr int kStaleAfterMs = 1000;

    explicit DeviceViewModel(DeviceSession *session, QObject *parent = nullptr);

    QString connectionText() const;
    bool connected() const;
    bool busy() const;
    bool hasError() const;
    QString errorDetail() const;
    Measurement pan() const { return m_sample.panDeg; }
    Measurement panRef() const { return m_sample.panRefDeg; }
    Measurement tilt() const { return m_sample.tiltDeg; }
    Measurement tiltRef() const { return m_sample.tiltRefDeg; }
    Measurement gimbalTemp() const { return m_sample.gimbalTempC; }
    Measurement imuTemp() const { return m_sample.imuTempC; }
    Measurement supplyVoltage() const { return m_sample.supplyVoltageV; }
    Flag safeControl() const { return m_sample.safeControlLocked; }

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
