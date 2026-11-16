#include "Fonts.h"

#include <QFontDatabase>

QStringList loadAppFonts()
{
    // Static weights, not the variable font: its family name ("Inter Variable") would not match Theme.fontSans.
    static const QStringList kFiles{
        QStringLiteral("Inter-Regular.ttf"),         QStringLiteral("Inter-Medium.ttf"),
        QStringLiteral("Inter-SemiBold.ttf"),        QStringLiteral("Inter-Bold.ttf"),
        QStringLiteral("JetBrainsMono-Regular.ttf"), QStringLiteral("JetBrainsMono-Medium.ttf"),
        QStringLiteral("JetBrainsMono-SemiBold.ttf"), QStringLiteral("JetBrainsMono-Bold.ttf"),
    };
    QStringList failed;
    for (const QString &file : kFiles) {
        if (QFontDatabase::addApplicationFont(QStringLiteral(":/fonts/") + file) < 0)
            failed << file;
    }
    return failed;
}
