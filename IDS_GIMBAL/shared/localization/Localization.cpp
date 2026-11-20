#include "Localization.h"

#include <QCoreApplication>

Localization::Localization(const QString &qmDirectory, QObject *parent)
    : QObject(parent), m_qmDirectory(qmDirectory)
{
}

Localization::~Localization()
{
    if (m_translator)
        QCoreApplication::removeTranslator(m_translator.get());
}

bool Localization::setLanguage(const QString &code)
{
    if (code == m_language)
        return true;

    std::unique_ptr<QTranslator> next;
    if (code == QLatin1String("tr")) {
        next = std::make_unique<QTranslator>();
        if (!next->load(QStringLiteral("IDS_GIMBAL_tr"), m_qmDirectory)) {
            emit languageLoadFailed(code);
            return false;
        }
    } else if (code != QLatin1String("en")) {
        emit languageLoadFailed(code);
        return false;
    }

    if (m_translator)
        QCoreApplication::removeTranslator(m_translator.get());
    m_translator = std::move(next);
    if (m_translator)
        QCoreApplication::installTranslator(m_translator.get());

    m_language = code;
    emit languageChanged();
    return true;
}
