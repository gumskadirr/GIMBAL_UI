#include "AppRunner.h"

#include <QFont>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#include "device/presentation/DeviceViewModel.h"
#include "device/session/DeviceSession.h"
#include "shared/localization/Localization.h"
#include "shared/notifications/NotificationModel.h"
#include "shared/settings/AppSettings.h"
#include "shared/ui/Fonts.h"

void connectServices(AppSettings &settings, NotificationModel &notifications, Localization &localization,
                     DeviceSession &session, DeviceViewModel &deviceViewModel)
{
    QObject::connect(&settings, &AppSettings::writeFailed, &notifications, [&](const QString &key) {
        notifications.add(QStringLiteral("settings.writeFailed"), {}, NotificationModel::Error, key);
    });
    QObject::connect(&localization, &Localization::languageLoadFailed, &notifications,
                     [&](const QString &code) {
                         notifications.add(QStringLiteral("language.loadFailed"), {code},
                                           NotificationModel::Warning);
                     });
    QObject::connect(&localization, &Localization::languageChanged, &settings, [&] {
        notifications.retranslate();
        deviceViewModel.retranslate();
        settings.setLanguage(localization.language());
    });
    QObject::connect(&session, &DeviceSession::stateChanged, &notifications, [&] {
        if (session.state() == ConnectionState::Error)
            notifications.add(QStringLiteral("device.error"), {}, NotificationModel::Error, session.detail());
    });
}

int runApp(QGuiApplication &app, const AppConfig &config, std::unique_ptr<IDeviceProvider> provider)
{
    QCoreApplication::setOrganizationName(QStringLiteral("IDS"));
    QCoreApplication::setApplicationName(config.applicationName);
    QCoreApplication::setApplicationVersion(QStringLiteral(IDS_GIMBAL_VERSION)); // shown as GUI version

    // Basic is the fixed base style; light/blue/dark is handled by Theme, never by switching styles.
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    const QStringList missingFonts = loadAppFonts();
    QGuiApplication::setFont(QFont(QStringLiteral("Inter"))); // same family as Theme.fontSans

    // Every object QML can reach is declared before the engine, so the engine is destroyed first.
    AppSettings settings;
    NotificationModel notifications;
    Localization localization;
    DeviceSession session(std::move(provider));
    DeviceViewModel deviceViewModel(&session);
    QQmlApplicationEngine engine;

    // First languageChanged handler: QML bindings are refreshed before the C++ models.
    QObject::connect(&localization, &Localization::languageChanged, &engine, &QQmlEngine::retranslate);

    connectServices(settings, notifications, localization, session, deviceViewModel);
    if (!missingFonts.isEmpty())
        notifications.add(QStringLiteral("fonts.loadFailed"), {missingFonts.join(QStringLiteral(", "))},
                          NotificationModel::Warning);
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
