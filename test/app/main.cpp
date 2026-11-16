#include <QGuiApplication>
#include <QtQml/qqmlextensionplugin.h>

#include "DemoProvider.h"
#include "app/AppRunner.h"

Q_IMPORT_QML_PLUGIN(IDS_GIMBALPlugin)

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    return runApp(app, {QStringLiteral("IDS_GIMBAL_Demo"), true}, std::make_unique<DemoProvider>());
}
