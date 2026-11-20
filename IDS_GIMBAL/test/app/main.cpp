#include <QGuiApplication>
#include <limits>
#include <QtQml/qqmlextensionplugin.h>

#include "DemoProvider.h"
#include "ImageDemoProvider.h"
#include "app/AppRunner.h"

Q_IMPORT_QML_PLUGIN(IDS_GIMBALPlugin)

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    ServiceProviders providers;
    // The demo runs until closed: no simulated link loss (that one is for the tests).
    providers.emplace_back(QString::fromLatin1(kMainControlService),
                           std::make_unique<DemoProvider>(100, std::numeric_limits<int>::max()));
    providers.emplace_back(QString::fromLatin1(kIdsImageService), std::make_unique<ImageDemoProvider>());
    return runApp(app, {QStringLiteral("IDS_GIMBAL_Demo"), true}, std::move(providers));
}
