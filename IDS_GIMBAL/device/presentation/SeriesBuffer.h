#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QVariantList>
#include <QVector>
#include <QtQml/qqmlregistration.h>
#include <array>
#include <limits>

#include "device/api/DeviceTypes.h"

class DeviceSession;

// Bounded history of the scope series: a ring of kCapacity samples (the oldest is dropped when it is full), fed
// from DeviceSession::sampleAccepted whether or not the page is visible. A value the device did not report
// (valid = false) is stored as NaN and becomes a gap: the drawn line breaks there. Lives in the GUI thread.
// shortcut: samples carry no device time, so they are stamped with the arrival time; use device time when the
// protocol provides it.
class SeriesBuffer : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Owned by the main control view model")
    Q_PROPERTY(double windowSeconds READ windowSeconds CONSTANT)

public:
    enum Series {
        PanRate, PanRateRef, TiltRate, TiltRateRef,                 // deg/s
        PanPosition, PanPositionRef, TiltPosition, TiltPositionRef, // deg
        PanTorque, TiltTorque,                                      // Iq, A
        SeriesCount
    };
    Q_ENUM(Series)

    static constexpr int kCapacity = 4000; // 2 s at 2 kHz
    static constexpr double kWindowS = 2.0;

    explicit SeriesBuffer(DeviceSession *session = nullptr, QObject *parent = nullptr);

    void append(double timeS, const DeviceSample &sample);
    void clear();
    Q_INVOKABLE int size() const { return m_size; }
    double windowSeconds() const { return kWindowS; }

    // The last kWindowS seconds of one series, reduced for a screen about maxPoints wide: a list of line segments
    // (a list of points, x = seconds before the newest sample, y = value), one per run without gaps. A run longer than
    // maxPoints keeps the minimum and maximum of each bucket, so peaks survive.
    Q_INVOKABLE QVariantList points(int series, int maxPoints) const;

private:
    struct Row
    {
        double t = 0.0;
        std::array<double, SeriesCount> v{};
    };
    const Row &at(int i) const { return m_rows[(m_head + i) % kCapacity]; } // 0 = oldest

    QVector<Row> m_rows;
    int m_head = 0;
    int m_size = 0;
    QElapsedTimer m_clock;
};
