#pragma once

#include <QtQml/qqmlregistration.h>

#include "device/api/DeviceTypes.h"

// QML value types for the device API gadgets, kept here so device/api has no QML dependency.
struct MeasurementForeign
{
    Q_GADGET
    QML_FOREIGN(Measurement)
    QML_VALUE_TYPE(measurement)
};

struct TextValueForeign
{
    Q_GADGET
    QML_FOREIGN(TextValue)
    QML_VALUE_TYPE(textValue)
};

struct BoardInfoForeign
{
    Q_GADGET
    QML_FOREIGN(BoardInfo)
    QML_VALUE_TYPE(boardInfo)
};

struct FlagForeign
{
    Q_GADGET
    QML_FOREIGN(Flag)
    QML_VALUE_TYPE(flag)
};
