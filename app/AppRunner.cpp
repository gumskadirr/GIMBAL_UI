#include "AppRunner.h"

#include <QFont>
#include <QHash>
#include <QMetaEnum>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#include "device/presentation/ImageViewModel.h"
#include "device/presentation/MainControlViewModel.h"
#include "device/session/ConnectionStore.h"
#include "device/session/DeviceSession.h"
#include "shared/localization/Localization.h"
#include "shared/notifications/NotificationModel.h"
#include "shared/settings/AppSettings.h"
#include "shared/ui/Fonts.h"

void connectServices(AppSettings &settings, NotificationModel &notifications, Localization &localization)
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
        settings.setLanguage(localization.language());
    });
}

void connectDeviceService(NotificationModel &notifications, Localization &localization, DeviceSession &session,
                          ServiceConnection &connection, const QString &service)
{
    QObject::connect(&localization, &Localization::languageChanged, &connection, &ServiceConnection::retranslate);
    QObject::connect(&session, &DeviceSession::commandFinished, &notifications,
                     [&](quint64, const DeviceCommand &command, const CommandResult &result) {
                         if (result.status == Command::Accepted)
                             return;
                         const QString kind = QString::fromLatin1(QMetaEnum::fromType<Command::Kind>().valueToKey(command.kind));
                         if (result.status == Command::Cancelled)
                             notifications.add(QStringLiteral("command.cancelled"), {kind}, NotificationModel::Warning);
                         else
                             notifications.add(QStringLiteral("command.failed"), {kind}, NotificationModel::Error,
                                               result.detail);
                     });
    QObject::connect(&session, &DeviceSession::stateChanged, &notifications, [&, service] {
        if (session.state() == ConnectionState::Error)
            notifications.add(QStringLiteral("device.error.") + service, {}, NotificationModel::Error, session.detail());
    });
}

int runApp(QGuiApplication &app, const AppConfig &config, ServiceProviders providers)
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
    ConnectionStore connections;
    // One session and connection per service (architecture §12); each service's view model reads its own.
    struct Service
    {
        QString key;
        std::unique_ptr<DeviceSession> session;
        std::unique_ptr<ServiceConnection> connection;
    };
    std::vector<Service> services;
    services.reserve(providers.size()); // byKey keeps pointers into it
    QHash<QString, Service *> byKey;
    for (auto &[key, provider] : providers) {
        auto session = std::make_unique<DeviceSession>(std::move(provider));
        auto connection = std::make_unique<ServiceConnection>(session.get());
        services.push_back({key, std::move(session), std::move(connection)});
        byKey.insert(key, &services.back());
    }
    Service *main = byKey.value(QString::fromLatin1(kMainControlService));
    Q_ASSERT(main); // every target provides the main control service
    MainControlViewModel mainControl(main->session.get(), main->connection.get());
    Service *image = byKey.value(QString::fromLatin1(kIdsImageService));
    Q_ASSERT(image); // so does IDS Image
    ImageViewModel imageViewModel(image->connection.get());
    QObject::connect(mainControl.parameters(), &ParameterModel::profileFailed, &notifications,
                     [&](const QString &file, const QString &reason) {
                         notifications.add(QStringLiteral("parameters.fileFailed"), {file}, NotificationModel::Error,
                                           reason);
                     });
    QObject::connect(mainControl.recorder(), &CsvRecorder::failed, &notifications,
                     [&](const QString &file, const QString &reason) {
                         notifications.add(QStringLiteral("recording.failed"), {file}, NotificationModel::Error,
                                           reason);
                     });
    QObject::connect(mainControl.script()->file(), &ScriptFile::failed, &notifications,
                     [&](const QString &file, const QString &reason) {
                         notifications.add(QStringLiteral("script.fileFailed"), {file}, NotificationModel::Error, reason);
                     });
    QObject::connect(mainControl.script(), &ScriptRunner::connectionLost, &notifications,
                     [&] { notifications.add(QStringLiteral("script.connectionLost"), {}, NotificationModel::Warning); });
    QQmlApplicationEngine engine;

    // First languageChanged handler: QML bindings are refreshed before the C++ models.
    QObject::connect(&localization, &Localization::languageChanged, &engine, &QQmlEngine::retranslate);

    connectServices(settings, notifications, localization);
    if (!missingFonts.isEmpty())
        notifications.add(QStringLiteral("fonts.loadFailed"), {missingFonts.join(QStringLiteral(", "))},
                          NotificationModel::Warning);

    localization.setLanguage(settings.language());

    QObject::connect(&connections, &ConnectionStore::writeFailed, &notifications, [&](const QString &service) {
        notifications.add(QStringLiteral("settings.writeFailed"), {}, NotificationModel::Error,
                          QStringLiteral("connection/") + service);
    });
    for (Service &s : services) {
        DeviceSession *session = s.session.get();
        connectDeviceService(notifications, localization, *session, *s.connection, s.key);
        // Stop data production before services and engine go away.
        QObject::connect(&app, &QCoreApplication::aboutToQuit, session, &DeviceSession::disconnectDevice);
        QObject::connect(s.connection.get(), &ServiceConnection::applied, &connections,
                         [&connections, key = s.key, session] { connections.save(key, session->target()); });
        // Startup (architecture §12, rule 2): connect when settings were saved; the demo needs none.
        if (const auto target = connections.load(s.key)) {
            session->setTarget(*target);
            session->connectDevice();
        } else if (config.demoMode) {
            session->connectDevice();
        }
        QJSEngine::setObjectOwnership(s.connection.get(), QJSEngine::CppOwnership);
    }

    for (QObject *o : std::initializer_list<QObject *>{&settings, &notifications, &localization, &mainControl, &imageViewModel})
        QJSEngine::setObjectOwnership(o, QJSEngine::CppOwnership);

    engine.setInitialProperties({
        {QStringLiteral("settings"), QVariant::fromValue(&settings)},
        {QStringLiteral("localization"), QVariant::fromValue(&localization)},
        {QStringLiteral("notifications"), QVariant::fromValue(&notifications)},
        {QStringLiteral("mainControl"), QVariant::fromValue(&mainControl)},
        {QStringLiteral("imageViewModel"), QVariant::fromValue(&imageViewModel)},
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
