#include <QQuickStyle>
#include <QtQml/qqmlextensionplugin.h>
#include <QtQuickTest>

#include "shared/ui/Fonts.h"

Q_IMPORT_QML_PLUGIN(IDS_GIMBALPlugin)

// Same base style and fonts as the application (AppRunner).
class Setup : public QObject
{
    Q_OBJECT

public slots:
    void applicationAvailable()
    {
        QQuickStyle::setStyle(QStringLiteral("Basic"));
        loadAppFonts();
    }
};

QUICK_TEST_MAIN_WITH_SETUP(ids_gimbal_qml, Setup)
#include "tst_qml.moc"
