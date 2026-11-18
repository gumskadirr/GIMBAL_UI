#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

#include "device/api/DeviceTypes.h"
#include "device/presentation/ParameterModel.h"
#include "device/presentation/ServiceConnection.h"

class DeviceSession;

// Main control service data as QML sees it; its connection is `connection`. Lives in the GUI thread and is
// owned by the application. Every measurement has a valid flag: no data, stale data and a new session are
// never shown as values.
class MainControlViewModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    Q_PROPERTY(ServiceConnection *connection READ connection CONSTANT)
    Q_PROPERTY(ParameterModel *parameters READ parameters CONSTANT)
    // Units: angles in degrees, temperatures in °C, voltage in V (see DeviceSample).
    Q_PROPERTY(Measurement pan READ pan NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement panRef READ panRef NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement tilt READ tilt NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement tiltRef READ tiltRef NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement gimbalTemp READ gimbalTemp NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement imuTemp READ imuTemp NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement supplyVoltage READ supplyVoltage NOTIFY measurementsChanged)
    Q_PROPERTY(Flag safeControl READ safeControl NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement onTime READ onTime NOTIFY measurementsChanged) // seconds since power on
    Q_PROPERTY(Flag inBootloader READ inBootloader NOTIFY measurementsChanged)
    // Read once per session; not affected by the telemetry stale timeout.
    Q_PROPERTY(BoardInfo boardInfo READ boardInfo NOTIFY boardInfoChanged)
    Q_PROPERTY(BitReport bitReport READ bitReport NOTIFY bitReportChanged) // valid is false without a report

public:
    static constexpr int kStaleAfterMs = 1000;

    MainControlViewModel(DeviceSession *session, ServiceConnection *connection, QObject *parent = nullptr);

    ServiceConnection *connection() const { return m_connection; }
    ParameterModel *parameters() { return &m_parameters; }
    Measurement pan() const { return m_sample.panDeg; }
    Measurement panRef() const { return m_sample.panRefDeg; }
    Measurement tilt() const { return m_sample.tiltDeg; }
    Measurement tiltRef() const { return m_sample.tiltRefDeg; }
    Measurement gimbalTemp() const { return m_sample.gimbalTempC; }
    Measurement imuTemp() const { return m_sample.imuTempC; }
    Measurement supplyVoltage() const { return m_sample.supplyVoltageV; }
    Flag safeControl() const { return m_sample.safeControlLocked; }
    Measurement onTime() const { return m_sample.onTimeS; }
    Flag inBootloader() const { return m_sample.inBootloader; }
    BoardInfo boardInfo() const { return m_boardInfo; }
    BitReport bitReport() const { return m_bitReport; }

    // -1 when there is no current (non-stale) sample.
    Q_INVOKABLE qint64 msSinceLastSample() const { return m_sinceSample.isValid() ? m_sinceSample.elapsed() : -1; }

signals:
    void measurementsChanged();
    void boardInfoChanged();
    void bitReportChanged();

private:
    void invalidate();       // telemetry only (also on stale timeout)
    void clearSessionData(); // telemetry and read-once data (new session, disconnect, error)
    void onSample(const DeviceSample &sample);

    DeviceSession *m_session;
    ServiceConnection *m_connection;
    ParameterModel m_parameters;
    DeviceSample m_sample; // default-constructed = all invalid
    QElapsedTimer m_sinceSample;
    QTimer m_staleCheck;
    BoardInfo m_boardInfo; // default-constructed = all invalid
    bool m_hasBoardInfo = false;
    BitReport m_bitReport; // valid = false until a report arrives
};
