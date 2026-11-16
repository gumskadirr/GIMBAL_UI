#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

// Stores message codes, not text: text is translated on every read so shown entries follow language changes.
class NotificationModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the application")

public:
    enum Severity { Info, Warning, Error };
    Q_ENUM(Severity)

    enum Role { CodeRole = Qt::UserRole + 1, TextRole, DetailRole, SeverityRole, TimestampRole, CountRole };

    static constexpr int kCapacity = 50;

    explicit NotificationModel(QObject *parent = nullptr);

    // Same code + args + detail as an existing entry increments its count and moves it to the top.
    void add(const QString &code, const QStringList &args, Severity severity, const QString &detail = {});
    Q_INVOKABLE void dismiss(int row);
    Q_INVOKABLE void clear();

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

public slots:
    void retranslate();

private:
    struct Entry {
        QString code;
        QStringList args;
        Severity severity;
        QString detail; // raw, never translated
        QDateTime time;
        int count = 1;
    };
    QString text(const Entry &e) const;

    QList<Entry> m_entries; // newest first
};
