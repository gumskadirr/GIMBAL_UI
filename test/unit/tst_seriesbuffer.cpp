#include <QPolygonF>
#include <QTest>
#include <cmath>

#include "device/presentation/SeriesBuffer.h"

namespace {
DeviceSample sampleOf(double panRate)
{
    DeviceSample s;
    s.panRateDps = {panRate, true};
    return s;
}
QList<QPointF> segment(const QVariantList &segments, int i) { return segments.at(i).value<QList<QPointF>>(); }
} // namespace

class tst_SeriesBuffer : public QObject
{
    Q_OBJECT

private slots:
    void fullBufferDropsTheOldest()
    {
        SeriesBuffer b;
        const int extra = 10;
        for (int i = 0; i < SeriesBuffer::kCapacity + extra; ++i)
            b.append(i * 0.0001, sampleOf(i)); // 0.5 s in total: all inside the window
        QCOMPARE(b.size(), SeriesBuffer::kCapacity);
        const QVariantList segments = b.points(SeriesBuffer::PanRate, SeriesBuffer::kCapacity);
        QCOMPARE(segments.size(), 1);
        const auto line = segment(segments, 0);
        QCOMPARE(line.size(), SeriesBuffer::kCapacity);
        QCOMPARE(line.first().y(), double(extra));                                   // 0..9 are gone
        QCOMPARE(line.last().y(), double(SeriesBuffer::kCapacity + extra - 1));
        QCOMPARE(line.last().x(), 0.0);                                              // newest at x = 0
    }

    void thinningKeepsPeaks()
    {
        SeriesBuffer b;
        for (int i = 0; i < SeriesBuffer::kCapacity; ++i)
            b.append(i * 0.0004, sampleOf(i == 1234 ? 99.0 : i == 3001 ? -99.0 : std::sin(i * 0.01)));
        const auto line = segment(b.points(SeriesBuffer::PanRate, 100), 0);
        QVERIFY(line.size() <= 100);
        double lo = 0, hi = 0;
        for (const QPointF &p : line) {
            lo = std::min(lo, p.y());
            hi = std::max(hi, p.y());
        }
        QCOMPARE(hi, 99.0);
        QCOMPARE(lo, -99.0);
        for (int i = 1; i < line.size(); ++i)
            QVERIFY(line[i].x() >= line[i - 1].x()); // still in time order
    }

    void invalidValueIsAGap()
    {
        SeriesBuffer b;
        b.append(0.0, sampleOf(1));
        b.append(0.1, sampleOf(2));
        b.append(0.2, DeviceSample{}); // nothing valid
        b.append(0.3, sampleOf(4));
        const QVariantList segments = b.points(SeriesBuffer::PanRate, 100);
        QCOMPARE(segments.size(), 2);
        QCOMPARE(segment(segments, 0).size(), 2);
        QCOMPARE(segment(segments, 1).size(), 1);
        QCOMPARE(segment(segments, 1).first().y(), 4.0);
        QVERIFY(b.points(SeriesBuffer::TiltRate, 100).isEmpty()); // never valid: no line at all
    }

    void onlyTheWindowIsReturned()
    {
        SeriesBuffer b;
        b.append(0.0, sampleOf(1));
        b.append(1.0, sampleOf(2));
        b.append(2.5, sampleOf(3));
        QCOMPARE(segment(b.points(SeriesBuffer::PanRate, 100), 0).size(), 2); // 0.0 is older than 2 s
        b.clear();
        QVERIFY(b.points(SeriesBuffer::PanRate, 100).isEmpty());
    }
};

QTEST_GUILESS_MAIN(tst_SeriesBuffer)
#include "tst_seriesbuffer.moc"
