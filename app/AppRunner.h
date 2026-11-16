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
class AppSettings;
class NotificationModel;
class Localization;
class DeviceSession;
class DeviceViewModel;

// Connections between the application services (architecture §10: language choice is saved and C++ texts
// are retranslated; device and settings errors become notifications). Used by runApp and by the QML test
// setup, so the tests run the application's own wiring. QML retranslation is connected separately.
void connectServices(AppSettings &settings, NotificationModel &notifications, Localization &localization,
                     DeviceSession &session, DeviceViewModel &deviceViewModel);

int runApp(QGuiApplication &app, const AppConfig &config, std::unique_ptr<IDeviceProvider> provider);
