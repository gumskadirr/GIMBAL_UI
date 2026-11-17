#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>
#include <QVariantMap>
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
    // Every button that sends a command to the device binds its enabled state to this.
    Q_PROPERTY(bool commandsAvailable READ commandsAvailable NOTIFY connectionChanged)
    Q_PROPERTY(QString errorDetail READ errorDetail NOTIFY connectionChanged)
    // Status bar text of the connection settings, e.g. "UART · COM3 · 115200 8N1" (architecture §12).
    Q_PROPERTY(QString connectionSummary READ connectionSummary NOTIFY connectionChanged)
    Q_PROPERTY(bool connectionConfigured READ connectionConfigured NOTIFY connectionChanged)
    // Units: angles in degrees, temperatures in °C, voltage in V (see DeviceSample).
    Q_PROPERTY(Measurement pan READ pan NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement panRef READ panRef NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement tilt READ tilt NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement tiltRef READ tiltRef NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement gimbalTemp READ gimbalTemp NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement imuTemp READ imuTemp NOTIFY measurementsChanged)
    Q_PROPERTY(Measurement supplyVoltage READ supplyVoltage NOTIFY measurementsChanged)
    Q_PROPERTY(Flag safeControl READ safeControl NOTIFY measurementsChanged)
    // Read once per session; not affected by the telemetry stale timeout.
    Q_PROPERTY(BoardInfo boardInfo READ boardInfo NOTIFY boardInfoChanged)

public:
    static constexpr int kStaleAfterMs = 1000;

    explicit DeviceViewModel(DeviceSession *session, QObject *parent = nullptr);

    QString connectionText() const;
    bool connected() const;
    bool busy() const;
    bool hasError() const;
    // shortcut: always false (architecture §7, no protocol yet); make it connected() && protocol ready
    // when the transport/protocol layer lands.
    bool commandsAvailable() const { return false; }
    QString errorDetail() const;
    QString connectionSummary() const;
    bool connectionConfigured() const;
    Measurement pan() const { return m_sample.panDeg; }
    Measurement panRef() const { return m_sample.panRefDeg; }
    Measurement tilt() const { return m_sample.tiltDeg; }
    Measurement tiltRef() const { return m_sample.tiltRefDeg; }
    Measurement gimbalTemp() const { return m_sample.gimbalTempC; }
    Measurement imuTemp() const { return m_sample.imuTempC; }
    Measurement supplyVoltage() const { return m_sample.supplyVoltageV; }
    Flag safeControl() const { return m_sample.safeControlLocked; }
    BoardInfo boardInfo() const { return m_boardInfo; }

    Q_INVOKABLE void connectDevice();
    Q_INVOKABLE void disconnectDevice();
    // Settings map of ConnectionPopup.qml: transport ("serial" | "udp"), serialPort, baudRate, dataBits,
    // parity ("none" | "even" | "odd"), stopBits, host, port.
    Q_INVOKABLE QVariantMap connectionTarget() const;
    // Sets the target, asks the owner to save it (connectionApplied) and connects (architecture §12, rule 5).
    Q_INVOKABLE void applyConnection(const QVariantMap &settings);
    Q_INVOKABLE QStringList availableSerialPorts() const;
    // -1 when there is no current (non-stale) sample.
    Q_INVOKABLE qint64 msSinceLastSample() const { return m_sinceSample.isValid() ? m_sinceSample.elapsed() : -1; }

public slots:
    void retranslate(); // C++ texts are not refreshed by QQmlEngine::retranslate()

signals:
    void connectionChanged();
    void measurementsChanged();
    void boardInfoChanged();
    void connectionApplied(); // the session target changed from the UI; the owner saves it

private:
    void invalidate();       // telemetry only (also on stale timeout)
    void clearSessionData(); // telemetry and read-once data (new session, disconnect, error)
    void onSample(const DeviceSample &sample);
    void onSessionState();

    DeviceSession *m_session;
    DeviceSample m_sample; // default-constructed = all invalid
    QElapsedTimer m_sinceSample;
    QTimer m_staleCheck;
    BoardInfo m_boardInfo; // default-constructed = all invalid
    bool m_hasBoardInfo = false;
};
