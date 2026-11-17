#pragma once

#include <QSerialPort>
#include <QUdpSocket>

#include "device/api/IDeviceProvider.h"

// Opens the serial port or the UDP socket of a service (architecture §2, §12).
// No protocol yet: "Connected" only means the link is open; incoming bytes are not decoded and no samples
// are produced. No automatic retry (§12 rules 3-4): a failed open or a lost port ends the session with Error.
// shortcut: close() is synchronous for both transports, so stop() needs no "closed" notification; add one if
// a transport ever closes in the background.
class TransportProvider : public IDeviceProvider
{
    Q_OBJECT

public:
    explicit TransportProvider(QObject *parent = nullptr);
    ~TransportProvider() override;

    void start(quint64 sessionId, const ConnectionTarget &target) override;
    void stop() override;

private:
    QString openSerial(const ConnectionTarget &target); // error text, empty on success
    QString openUdp(const ConnectionTarget &target);

    quint64 m_sessionId = 0;
    bool m_open = false; // set only after a successful open, so open errors are not reported twice
    QSerialPort m_serial;
    QUdpSocket m_udp;
};
