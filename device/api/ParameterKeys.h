#pragma once

#include <QList>
#include <QString>
#include <QVariant>
#include <cmath>
#include <optional>

// Device parameters (architecture §13): one flat key -> value map, the same for the device, the UI and the
// profile file. Each motor's parameters are prefixed with "pan." or "tilt.". The protocol maps each key to
// its register / field; the UI never knows the encoding.
// shortcut: names, types and ranges follow the Motor control design (it gives no limits); recheck every key
// and range against the protocol document when it arrives (architecture §7).
enum class ParameterType { Number, Integer, Bool, Text };

struct ParameterSpec
{
    QString key;
    ParameterType type = ParameterType::Number;
    double min = 0; // Number / Integer: inclusive range; Text: max length in max
    double max = 0;
};

namespace ParameterKeys {

inline const QList<ParameterSpec> &all()
{
    static const QList<ParameterSpec> specs = [] {
        struct Field { const char *name; ParameterType type; double min; double max; };
        const Field fields[] = {
            {"torqueKp", ParameterType::Number, 0, 10000}, {"torqueKi", ParameterType::Number, 0, 10000},
            {"torqueKd", ParameterType::Number, 0, 10000}, {"speedKp", ParameterType::Number, 0, 10000},
            {"speedKi", ParameterType::Number, 0, 10000}, {"speedKd", ParameterType::Number, 0, 10000},
            {"positionKp", ParameterType::Number, 0, 10000}, {"positionKi", ParameterType::Number, 0, 10000},
            {"positionKd", ParameterType::Number, 0, 10000}, {"trackerKp", ParameterType::Number, 0, 10000},
            {"trackerKi", ParameterType::Number, 0, 10000}, {"trackerKd", ParameterType::Number, 0, 10000},
            {"modelSerial", ParameterType::Text, 0, 32},
            {"positionOffsetDeg", ParameterType::Number, -180, 180},
            {"electricalOffsetDeg", ParameterType::Number, -180, 180},
            {"forwardBorderDeg", ParameterType::Number, -180, 180},
            {"backwardBorderDeg", ParameterType::Number, -180, 180},
            {"encoderReverse", ParameterType::Bool, 0, 0},
            {"phaseRotation", ParameterType::Integer, 0, 5}, // index of the phase order list (6 orders)
            {"slipRing", ParameterType::Bool, 0, 0},
        };
        QList<ParameterSpec> list;
        for (const char *motor : {"pan.", "tilt."}) {
            for (const Field &f : fields)
                list.append({QLatin1String(motor) + QLatin1String(f.name), f.type, f.min, f.max});
        }
        return list;
    }();
    return specs;
}

inline std::optional<ParameterSpec> find(const QString &key)
{
    for (const ParameterSpec &s : all()) {
        if (s.key == key)
            return s;
    }
    return std::nullopt;
}

// The value in its canonical type (double / int / bool / QString), or an invalid QVariant when it does not
// fit the key's type or range. Numbers must be numbers: text is never parsed here (UI decimal separators
// differ by language).
inline QVariant normalized(const ParameterSpec &spec, const QVariant &value)
{
    const auto isNumber = [&] {
        switch (value.typeId()) {
        case QMetaType::Double: case QMetaType::Float: case QMetaType::Int: case QMetaType::UInt:
        case QMetaType::LongLong: case QMetaType::ULongLong:
            return true;
        default:
            return false;
        }
    };
    switch (spec.type) {
    case ParameterType::Number: {
        if (!isNumber())
            return {};
        const double v = value.toDouble();
        return std::isfinite(v) && v >= spec.min && v <= spec.max ? QVariant(v) : QVariant();
    }
    case ParameterType::Integer: {
        if (!isNumber())
            return {};
        const double v = value.toDouble();
        return v == std::floor(v) && v >= spec.min && v <= spec.max ? QVariant(int(v)) : QVariant();
    }
    case ParameterType::Bool:
        return value.typeId() == QMetaType::Bool ? value : QVariant();
    case ParameterType::Text:
        return value.typeId() == QMetaType::QString && value.toString().size() <= spec.max ? value : QVariant();
    }
    return {};
}

} // namespace ParameterKeys
