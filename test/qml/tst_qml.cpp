#include <QDir>
#include <QFileInfo>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QTemporaryDir>
#include <QtQml/qqmlextensionplugin.h>
#include <QtQuickTest>
#include <memory>

#include "../unit/FakeProvider.h"
#include "app/AppRunner.h"
#include "device/presentation/MainControlViewModel.h"
#include "device/session/DeviceSession.h"
#include "shared/localization/Localization.h"
#include "shared/notifications/NotificationModel.h"
#include "shared/settings/AppSettings.h"
#include "shared/ui/Fonts.h"

Q_IMPORT_QML_PLUGIN(IDS_GIMBALPlugin)

// Same base style and fonts as the application (AppRunner). Tests that create Main get real services
// through the test* context properties (test only; the application passes them as required properties).
class Setup : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE void addNotification(const QString &code, const QString &detail)
    {
        m_notifications->add(code, {}, NotificationModel::Error, detail);
    }

    // Connects through the fake provider and delivers makeFullSample() to the real session/view model.
    Q_INVOKABLE void connectWithFullSample()
    {
        m_session->connectDevice();
        const quint64 id = m_session->activeSessionId();
        emit m_fake->stateChanged(id, ConnectionState::Connected, {});
        emit m_fake->sampleReceived(id, makeFullSample());
        emit m_fake->boardInfoReceived(id, makeBoardInfo());
    }
    Q_INVOKABLE void disconnectDevice() { m_session->disconnectDevice(); }
    // Design comparison screenshots (tools/shot/tst_shot.qml, docs/gelistirme.md); not used by the tests.
    Q_INVOKABLE bool saveWindowImage(QQuickWindow *window, const QString &path)
    {
        QDir().mkpath(QFileInfo(path).absolutePath());
        return window && window->grabWindow().save(path);
    }
    // Tests start with saved settings (so Main does not open the connection settings by itself); this
    // brings back the "never configured" state for the test of rule 1.
    Q_INVOKABLE void forgetConnection() { m_session->setTarget({}); }
    Q_INVOKABLE void restoreConnection() { m_session->setTarget(loopbackTarget()); }
    static ConnectionTarget loopbackTarget()
    {
        ConnectionTarget t;
        t.transport = ConnectionTarget::Transport::Udp;
        t.host = QStringLiteral("127.0.0.1");
        t.port = 5000;
        return t;
    }

public slots:
    void applicationAvailable()
    {
        QQuickStyle::setStyle(QStringLiteral("Basic"));
        loadAppFonts();
        m_settings = std::make_unique<AppSettings>(m_dir.filePath(QStringLiteral("settings.ini")));
        m_notifications = std::make_unique<NotificationModel>();
        m_localization = std::make_unique<Localization>();
        auto fake = std::make_unique<FakeProvider>();
        m_fake = fake.get();
        m_session = std::make_unique<DeviceSession>(std::move(fake));
        m_session->setTarget(loopbackTarget());
        m_connection = std::make_unique<ServiceConnection>(m_session.get());
        m_mainControl = std::make_unique<MainControlViewModel>(m_session.get(), m_connection.get());
        // The application's own service wiring (AppRunner), not a copy of it.
        connectServices(*m_settings, *m_notifications, *m_localization);
        connectDeviceService(*m_notifications, *m_localization, *m_session, *m_connection);
    }

    void qmlEngineAvailable(QQmlEngine *engine)
    {
        for (QObject *o : std::initializer_list<QObject *>{m_settings.get(), m_notifications.get(),
                                                           m_localization.get(), m_connection.get(),
                                                           m_mainControl.get(), this})
            QJSEngine::setObjectOwnership(o, QJSEngine::CppOwnership);
        QQmlContext *context = engine->rootContext();
        context->setContextProperty(QStringLiteral("testSettings"), m_settings.get());
        context->setContextProperty(QStringLiteral("testNotifications"), m_notifications.get());
        context->setContextProperty(QStringLiteral("testLocalization"), m_localization.get());
        context->setContextProperty(QStringLiteral("testMainControl"), m_mainControl.get());
        context->setContextProperty(QStringLiteral("testHelper"), this);
        QObject::connect(m_localization.get(), &Localization::languageChanged, engine, &QQmlEngine::retranslate);
    }

private:
    QTemporaryDir m_dir;
    std::unique_ptr<AppSettings> m_settings;
    std::unique_ptr<NotificationModel> m_notifications;
    std::unique_ptr<Localization> m_localization;
    FakeProvider *m_fake = nullptr; // owned by m_session
    std::unique_ptr<DeviceSession> m_session;
    std::unique_ptr<ServiceConnection> m_connection;
    std::unique_ptr<MainControlViewModel> m_mainControl;
};

QUICK_TEST_MAIN_WITH_SETUP(ids_gimbal_qml, Setup)
#include "tst_qml.moc"
