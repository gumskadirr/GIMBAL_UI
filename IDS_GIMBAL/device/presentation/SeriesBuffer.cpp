#include "SeriesBuffer.h"

#include <QPolygonF>
#include <algorithm>
#include <cmath>

#include "device/session/DeviceSession.h"

namespace {
constexpr double kNaN = std::numeric_limits<double>::quiet_NaN();
double value(const Measurement &m) { return m.valid ? m.value : kNaN; }

// Keeps the minimum and maximum of each bucket, in time order.
QPolygonF thin(const QPolygonF &run, int maxPoints)
{
    const int n = run.size();
    const int buckets = std::max(1, maxPoints / 2);
    if (n <= maxPoints || n <= 2 * buckets)
        return run;
    QPolygonF out;
    for (int b = 0; b < buckets; ++b) {
        const int from = b * n / buckets;
        const int to = (b + 1) * n / buckets;
        int lo = from, hi = from;
        for (int i = from; i < to; ++i) {
            if (run[i].y() < run[lo].y())
                lo = i;
            if (run[i].y() > run[hi].y())
                hi = i;
        }
        out << run[std::min(lo, hi)];
        if (lo != hi)
            out << run[std::max(lo, hi)];
    }
    return out;
}
} // namespace

SeriesBuffer::SeriesBuffer(DeviceSession *session, QObject *parent) : QObject(parent), m_rows(kCapacity)
{
    m_clock.start();
    if (!session)
        return;
    connect(session, &DeviceSession::sampleAccepted, this,
            [this](const DeviceSample &sample) { append(m_clock.nsecsElapsed() * 1e-9, sample); });
    connect(session, &DeviceSession::sessionStarted, this, &SeriesBuffer::clear);
    connect(session, &DeviceSession::stateChanged, this, [this, session] {
        if (session->state() != ConnectionState::Connected)
            clear();
    });
}

void SeriesBuffer::append(double timeS, const DeviceSample &s)
{
    Row &row = m_rows[(m_head + m_size) % kCapacity];
    row.t = timeS;
    row.v = {value(s.panRateDps), value(s.panRateRefDps), value(s.tiltRateDps), value(s.tiltRateRefDps),
             value(s.panDeg), value(s.panRefDeg), value(s.tiltDeg), value(s.tiltRefDeg),
             value(s.panTorqueA), value(s.tiltTorqueA)};
    if (m_size < kCapacity)
        ++m_size;
    else
        m_head = (m_head + 1) % kCapacity;
}

void SeriesBuffer::clear()
{
    m_head = 0;
    m_size = 0;
}

QVariantList SeriesBuffer::points(int series, int maxPoints) const
{
    QVariantList segments;
    if (series < 0 || series >= SeriesCount || m_size == 0)
        return segments;
    const double newest = at(m_size - 1).t;
    QPolygonF run;
    const auto flush = [&] {
        if (!run.isEmpty())
            segments.append(QVariant::fromValue(QList<QPointF>(thin(run, maxPoints))));
        run.clear();
    };
    for (int i = 0; i < m_size; ++i) {
        const Row &row = at(i);
        if (row.t < newest - kWindowS)
            continue;
        if (std::isnan(row.v[series]))
            flush();
        else
            run << QPointF(row.t - newest, row.v[series]);
    }
    flush();
    return segments;
}
