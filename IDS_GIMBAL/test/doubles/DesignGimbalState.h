#pragma once

#include <QVariantList>
#include <QVariantMap>

// FLAGS of the Gimbal state design (device text); all set in the design. `value` sets every flag.
inline QVariantList designStateFlags(bool value = true)
{
    QVariantList flags;
    for (const char *name : {"MECHANICAL_STAB", "PAN_MOTOR_ENABLED", "TILT_MOTOR_ENABLED", "LASER_POINTER_ENABLED",
                             "LRF_POINTER_ENABLED", "TV_CAMERA_ACTIVE", "IR_CAMERA_ACTIVE", "IMAGE_TRACKING_ENABLED",
                             "FOLLOWING_ENABLED"})
        flags.append(QVariantMap{{"name", name}, {"value", value}});
    return flags;
}

// VALUES of the design (all 0); `yaw` lets a test see a changed value.
inline QVariantList designStateValues(double yaw = 0.0)
{
    QVariantList values;
    for (const char *name : {"yaw", "pitch", "latitude", "longitude", "altitude", "zoom", "lrf_distance",
                             "fov_horizontal", "fov_vertical", "gnss_status"})
        values.append(QVariantMap{{"name", name}, {"value", values.isEmpty() ? yaw : 0.0}});
    return values;
}
