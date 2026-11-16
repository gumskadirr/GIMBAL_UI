#include "AppRunner.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#include "device/presentation/DeviceViewModel.h"
#include "device/session/DeviceSession.h"
#include "shared/localization/Localization.h"
#include "shared/notifications/NotificationModel.h"
#include "shared/settings/AppSettings.h"

int runApp(QGuiApplication &app, const AppConfig &config, std::unique_ptr<IDeviceProvider> provider)
{
    QCoreApplication::setOrganizationName(QStringLiteral("IDS"));
    QCoreApplication::setApplicationName(config.applicationName);

    // Basic is the fixed base style; light/dark is handled by Theme, never by switching styles.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    // Services are declared before the engine so the engine is destroyed first.
    AppSettings settings;
    NotificationModel notifications;
    DeviceSession session(std::move(provider));
    DeviceViewModel deviceViewModel(&session);
    QQmlApplicationEngine engine;
    Localization localization(&engine);

    QObject::connect(&settings, &AppSettings::writeFailed, &notifications, [&](const QString &key) {
        notifications.add(QStringLiteral("settings.writeFailed"), {key}, NotificationModel::Error);
    });
    QObject::connect(&localization, &Localization::languageLoadFailed, &notifications,
                     [&](const QString &code) {
                         notifications.add(QStringLiteral("language.loadFailed"), {code},
                                           NotificationModel::Warning);
                     });
    QObject::connect(&localization, &Localization::languageChanged, &app, [&] {
        notifications.retranslate();
        deviceViewModel.retranslate();
        settings.setLanguage(localization.language());
    });
    QObject::connect(&session, &DeviceSession::stateChanged, &notifications, [&] {
        if (session.state() == ConnectionState::Error)
            notifications.add(QStringLiteral("device.error"), {}, NotificationModel::Error, session.detail());
    });
    // Stop data production before services and engine go away.
    QObject::connect(&app, &QCoreApplication::aboutToQuit, &session, &DeviceSession::disconnectDevice);

    localization.setLanguage(settings.language());

    for (QObject *o : std::initializer_list<QObject *>{&settings, &notifications, &localization, &deviceViewModel})
        QJSEngine::setObjectOwnership(o, QJSEngine::CppOwnership);

    engine.setInitialProperties({
        {QStringLiteral("settings"), QVariant::fromValue(&settings)},
        {QStringLiteral("localization"), QVariant::fromValue(&localization)},
        {QStringLiteral("notifications"), QVariant::fromValue(&notifications)},
        {QStringLiteral("deviceViewModel"), QVariant::fromValue(&deviceViewModel)},
        {QStringLiteral("demoMode"), config.demoMode},
    });
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("IDS_GIMBAL", "Main");

    return QGuiApplication::exec();
}
