#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QTemporaryDir>
#include <QtQml/qqmlextensionplugin.h>
#include <QtQuickTest>
#include <memory>

#include "../unit/FakeProvider.h"
#include "app/AppRunner.h"
#include "device/presentation/DeviceViewModel.h"
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
    }
    Q_INVOKABLE void disconnectDevice() { m_session->disconnectDevice(); }

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
        m_viewModel = std::make_unique<DeviceViewModel>(m_session.get());
        // The application's own service wiring (AppRunner), not a copy of it.
        connectServices(*m_settings, *m_notifications, *m_localization, *m_session, *m_viewModel);
    }

    void qmlEngineAvailable(QQmlEngine *engine)
    {
        for (QObject *o : std::initializer_list<QObject *>{m_settings.get(), m_notifications.get(),
                                                           m_localization.get(), m_viewModel.get(), this})
            QJSEngine::setObjectOwnership(o, QJSEngine::CppOwnership);
        QQmlContext *context = engine->rootContext();
        context->setContextProperty(QStringLiteral("testSettings"), m_settings.get());
        context->setContextProperty(QStringLiteral("testNotifications"), m_notifications.get());
        context->setContextProperty(QStringLiteral("testLocalization"), m_localization.get());
        context->setContextProperty(QStringLiteral("testDeviceViewModel"), m_viewModel.get());
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
    std::unique_ptr<DeviceViewModel> m_viewModel;
};

QUICK_TEST_MAIN_WITH_SETUP(ids_gimbal_qml, Setup)
#include "tst_qml.moc"
