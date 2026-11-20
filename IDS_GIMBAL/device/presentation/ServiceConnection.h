#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class DeviceSession;

// One service's connection as QML sees it (architecture §12): state, settings summary, connect/disconnect.
// One instance per service; the service's data lives in its own view model.
class ServiceConnection : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
    Q_PROPERTY(bool connected READ connected NOTIFY changed)
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(bool hasError READ hasError NOTIFY changed)
    // Every button that sends a command to the device binds its enabled state to this.
    Q_PROPERTY(bool commandsAvailable READ commandsAvailable NOTIFY changed)
    Q_PROPERTY(QString errorDetail READ errorDetail NOTIFY changed)
    // Status bar text of the connection settings, e.g. "UART · COM3 · 115200 8N1".
    Q_PROPERTY(QString summary READ summary NOTIFY changed)
    Q_PROPERTY(bool configured READ configured NOTIFY changed)
    // Command kinds (Command.Kind) waiting for an answer; their buttons look busy and cannot be pressed again.
    Q_PROPERTY(QList<int> pendingCommands READ pendingCommands NOTIFY pendingChanged)
    // Progress of the running long command (e.g. UpdateFirmware); the status bar shows it on every page.
    // progressKind is its Command.Kind, -1 when none; all three reset when it finishes or is cancelled.
    Q_PROPERTY(int progressKind READ progressKind NOTIFY progressChanged)
    Q_PROPERTY(int progressPercent READ progressPercent NOTIFY progressChanged)
    Q_PROPERTY(QString progressStage READ progressStage NOTIFY progressChanged)
    // Traffic counted by the transport (no protocol needed). Active = bytes seen in the last kActiveMs; the rate
    // is bits per second of TX + RX over the last kRateWindowMs, 0 when nothing flows.
    Q_PROPERTY(bool txActive READ txActive NOTIFY trafficChanged)
    Q_PROPERTY(bool rxActive READ rxActive NOTIFY trafficChanged)
    Q_PROPERTY(double dataRateBps READ dataRateBps NOTIFY trafficChanged)
    Q_PROPERTY(double txBytes READ txBytes NOTIFY trafficChanged)
    Q_PROPERTY(double rxBytes READ rxBytes NOTIFY trafficChanged)
    // Results of old sessions dropped so far (Debug settings).
    Q_PROPERTY(int staleDropped READ staleDropped NOTIFY trafficChanged)
    // Raw Command.Kind names of pendingCommands, for the Debug settings window (not translated).
    Q_PROPERTY(QStringList pendingCommandNames READ pendingCommandNames NOTIFY pendingChanged)

public:
    static constexpr int kActiveMs = 200;
    static constexpr int kRateWindowMs = 1000;

    explicit ServiceConnection(DeviceSession *session, QObject *parent = nullptr);

    QString statusText() const;
    bool connected() const;
    bool busy() const;
    bool hasError() const;
    // The real target has no protocol yet, so its provider reports no command support (architecture §7).
    bool commandsAvailable() const;
    QString errorDetail() const;
    QString summary() const;
    bool configured() const;
    QList<int> pendingCommands() const;
    QStringList pendingCommandNames() const;
    bool txActive() const { return m_txActive; }
    bool rxActive() const { return m_rxActive; }
    double dataRateBps() const { return m_rateBps; }
    double txBytes() const;
    double rxBytes() const;
    int staleDropped() const;
    int progressKind() const { return m_progressKind; }
    int progressPercent() const { return m_progressPercent; }
    QString progressStage() const { return m_progressStage; }

    Q_INVOKABLE void connectDevice();
    Q_INVOKABLE void disconnectDevice();
    // Settings map of ConnectionPopup.qml: transport ("serial" | "udp"), serialPort, baudRate, dataBits,
    // parity ("none" | "even" | "odd"), stopBits, host, port.
    Q_INVOKABLE QVariantMap target() const;
    // Sets the target, asks the owner to save it (applied) and connects (architecture §12, rule 5).
    Q_INVOKABLE void apply(const QVariantMap &settings);
    Q_INVOKABLE QStringList availableSerialPorts() const;
    // kind: Command.Kind. False (nothing sent) when commands are unavailable or the same kind is pending.
    Q_INVOKABLE bool send(int kind, const QVariantMap &args = {});

public slots:
    void retranslate(); // C++ texts are not refreshed by QQmlEngine::retranslate()

signals:
    void changed();
    void applied(); // the session target changed from the UI; the owner saves it
    void pendingChanged();
    void trafficChanged();
    void progressChanged();
    // kind: Command.Kind, status: Command.Status. Failures also become notifications (AppRunner).
    void commandFinished(int kind, int status, const QString &detail);

private:
    void updateTraffic();

    DeviceSession *m_session;
    QTimer m_tick; // 100 ms: activity decays and the rate moves even when no byte arrives
    QElapsedTimer m_clock;
    qint64 m_lastTxMs = -kActiveMs - 1;
    qint64 m_lastRxMs = -kActiveMs - 1;
    quint64 m_seenTx = 0;
    quint64 m_seenRx = 0;
    QList<std::pair<qint64, quint64>> m_window; // (ms, tx + rx) per tick
    bool m_txActive = false;
    bool m_rxActive = false;
    double m_rateBps = 0;
    int m_seenStale = 0;
    quint64 m_shownTx = 0;
    quint64 m_shownRx = 0;
    int m_progressKind = -1;
    int m_progressPercent = 0;
    QString m_progressStage; // raw provider text
};
