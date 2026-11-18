#pragma once

#include <QString>
#include <memory>
#include <utility>
#include <vector>

class QGuiApplication;
class IDeviceProvider;

// Each service's key in ConnectionStore and in the page registry (Main.qml `services`).
inline constexpr const char *kMainControlService = "mainControl";

struct AppConfig
{
    QString applicationName; // also the settings identity; real and demo targets differ
    bool demoMode = false;
};

// Device provider of each service, keyed like kMainControlService. Each target only chooses its providers.
using ServiceProviders = std::vector<std::pair<QString, std::unique_ptr<IDeviceProvider>>>;

class AppSettings;
class NotificationModel;
class Localization;
class DeviceSession;
class ServiceConnection;

// Connections between the application services (architecture §10: language choice is saved and C++ texts
// are retranslated; settings errors become notifications). connectDeviceService does the same for one device
// service (its errors become notifications). Used by runApp and by the QML test setup, so the tests run the
// application's own wiring. QML retranslation is connected separately.
void connectServices(AppSettings &settings, NotificationModel &notifications, Localization &localization);
void connectDeviceService(NotificationModel &notifications, Localization &localization, DeviceSession &session,
                          ServiceConnection &connection);

int runApp(QGuiApplication &app, const AppConfig &config, ServiceProviders providers);
