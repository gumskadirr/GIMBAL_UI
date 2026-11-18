#include "NotificationModel.h"

#include <QCoreApplication>
#include <QHash>

namespace {
// Message codes are language independent; the source text is translated at display time.
const QHash<QString, const char *> kMessages{
    {QStringLiteral("device.error"), QT_TRANSLATE_NOOP("NotificationModel", "Device error")},
    {QStringLiteral("settings.writeFailed"),
     QT_TRANSLATE_NOOP("NotificationModel", "Preferences could not be saved")},
    {QStringLiteral("language.loadFailed"),
     QT_TRANSLATE_NOOP("NotificationModel", "Language could not be loaded: %1")},
    {QStringLiteral("command.failed"), QT_TRANSLATE_NOOP("NotificationModel", "Command failed: %1")},
    {QStringLiteral("command.cancelled"),
     QT_TRANSLATE_NOOP("NotificationModel", "Command cancelled (connection closed): %1")},
    {QStringLiteral("fonts.loadFailed"),
     QT_TRANSLATE_NOOP("NotificationModel", "Fonts could not be loaded: %1")},
};
} // namespace

NotificationModel::NotificationModel(QObject *parent) : QAbstractListModel(parent) {}

void NotificationModel::add(const QString &code, const QStringList &args, Severity severity,
                            const QString &detail)
{
    const QDateTime now = QDateTime::currentDateTime();
    for (int i = 0; i < m_entries.size(); ++i) {
        Entry &e = m_entries[i];
        if (e.code != code || e.args != args || e.detail != detail)
            continue;
        ++e.count;
        e.time = now;
        e.severity = severity;
        if (i > 0) {
            beginMoveRows({}, i, i, {}, 0);
            m_entries.move(i, 0);
            endMoveRows();
        }
        emit dataChanged(index(0), index(0), {SeverityRole, TimestampRole, CountRole});
        return;
    }

    if (m_entries.size() >= kCapacity) {
        const int last = int(m_entries.size()) - 1;
        beginRemoveRows({}, last, last);
        m_entries.removeLast();
        endRemoveRows();
    }
    beginInsertRows({}, 0, 0);
    m_entries.prepend({code, args, severity, detail, now, 1});
    endInsertRows();
}

void NotificationModel::dismiss(int row)
{
    if (row < 0 || row >= m_entries.size())
        return;
    beginRemoveRows({}, row, row);
    m_entries.removeAt(row);
    endRemoveRows();
}

void NotificationModel::clear()
{
    beginResetModel();
    m_entries.clear();
    endResetModel();
}

void NotificationModel::retranslate()
{
    if (!m_entries.isEmpty())
        emit dataChanged(index(0), index(int(m_entries.size()) - 1), {TextRole, DetailRole});
}

int NotificationModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_entries.size());
}

QString NotificationModel::text(const Entry &e) const
{
    const char *source = kMessages.value(e.code, nullptr);
    if (!source)
        return e.code;
    QString result = tr(source);
    for (const QString &arg : e.args)
        result = result.arg(arg);
    return result;
}

QVariant NotificationModel::data(const QModelIndex &index, int role) const
{
    if (!checkIndex(index, CheckIndexOption::IndexIsValid | CheckIndexOption::ParentIsInvalid))
        return {};
    const Entry &e = m_entries.at(index.row());
    switch (role) {
    case CodeRole: return e.code;
    case TextRole: return text(e);
    // Details are raw technical text; only app-generated ones have a "Detail" translation.
    case DetailRole: return QCoreApplication::translate("Detail", e.detail.toUtf8().constData());
    case SeverityRole: return e.severity;
    case TimestampRole: return e.time;
    case CountRole: return e.count;
    default: return {};
    }
}

QHash<int, QByteArray> NotificationModel::roleNames() const
{
    return {{CodeRole, "code"},         {TextRole, "text"},           {DetailRole, "detail"},
            {SeverityRole, "severity"}, {TimestampRole, "timestamp"}, {CountRole, "count"}};
}
