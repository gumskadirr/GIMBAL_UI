#pragma once

#include <QObject>
#include <QTranslator>
#include <QtQml/qqmlregistration.h>
#include <memory>

// Source language is English ("en" = no translator). Failed loads keep the current language.
// The owner refreshes QML bindings (QQmlEngine::retranslate) on languageChanged.
class Localization : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")
    Q_PROPERTY(QString language READ language NOTIFY languageChanged)

public:
    explicit Localization(const QString &qmDirectory = QStringLiteral(":/i18n"),
                          QObject *parent = nullptr);
    ~Localization() override;

    QString language() const { return m_language; }
    Q_INVOKABLE bool setLanguage(const QString &code);

signals:
    void languageChanged();
    void languageLoadFailed(const QString &code);

private:
    QString m_qmDirectory;
    QString m_language = QStringLiteral("en");
    std::unique_ptr<QTranslator> m_translator;
};
