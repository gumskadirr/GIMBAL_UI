#pragma once

#include <QString>
#include <memory>

class QGuiApplication;
class IDeviceProvider;

struct AppConfig
{
    QString applicationName; // also the settings identity; real and demo targets differ
    bool demoMode = false;
};

// Shared start-up for both targets: each target only chooses its device provider.
int runApp(QGuiApplication &app, const AppConfig &config, std::unique_ptr<IDeviceProvider> provider);
