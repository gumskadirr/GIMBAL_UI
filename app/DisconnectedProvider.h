#pragma once

#include <QTimer>

#include "device/api/IDeviceProvider.h"

// Real target until the serial/UDP transport exists: every connect attempt fails, no data is faked.
class DisconnectedProvider : public IDeviceProvider
{
    Q_OBJECT

public:
    using IDeviceProvider::IDeviceProvider;

    void start(quint64 sessionId) override
    {
        QTimer::singleShot(0, this, [this, sessionId] {
            // Translated where it is shown (context "Detail"), so it follows language changes.
            emit stateChanged(sessionId, ConnectionState::Error,
                              QString::fromUtf8(QT_TRANSLATE_NOOP("Detail", "No device transport in this build")));
        });
    }
    void stop() override {}
};
