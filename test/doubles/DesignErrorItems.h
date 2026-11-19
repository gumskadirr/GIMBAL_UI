#pragma once

#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

// The 21 items of the Errors design, all OK; `failing` (a name) is reported as Fail. Names are device text. The
// four the design cuts off with "…" are completed by guess.
inline QVariantList designErrorItems(const QString &failing = {})
{
    const QList<QPair<QString, QStringList>> groups = {
        {"PMCB", {"connection", "encoder", "overcurrent"}},
        {"TMCB", {"connection", "encoder", "overcurrent"}},
        {"BMACB", {"connection", "external_pressure", "temperature_sensor", "VN200"}},
        {"MACB", {"core_temperature", "LRF", "IMU", "IR_lens", "humidity_sensor", "connection"}},
        {"MINIPC", {"TV_camera", "TV_control", "TV_lens", "IR_camera", "IR_control"}},
    };
    QVariantList items;
    for (const auto &[group, names] : groups)
        for (const QString &n : names) {
            const QString name = group + '_' + n;
            items.append(QVariantMap{{"group", group}, {"name", name}, {"state", name == failing ? "fail" : "ok"}});
        }
    return items;
}
