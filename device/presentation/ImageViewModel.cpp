#include "ImageViewModel.h"

#include "device/session/DeviceSession.h"

ImageViewModel::ImageViewModel(DeviceSession *session, ServiceConnection *connection, QObject *parent)
    : QObject(parent), m_connection(connection)
{
    connect(session, &DeviceSession::stateChanged, this, [this, session] {
        if (session->state() != ConnectionState::Connected)
            clear();
    });
    connect(session, &DeviceSession::sessionStarted, this, &ImageViewModel::clear);
    connect(session, &DeviceSession::imageSampleAccepted, this, [this](const ImageSample &sample) {
        m_sample = sample;
        m_hasSample = true;
        m_sinceSample.start();
        m_staleCheck.start();
        emit sampleChanged();
    });
    m_staleCheck.setInterval(kStaleAfterMs / 4);
    connect(&m_staleCheck, &QTimer::timeout, this, [this] {
        if (m_sinceSample.elapsed() > kStaleAfterMs)
            clear();
    });
}

void ImageViewModel::clear()
{
    m_staleCheck.stop();
    if (!m_hasSample)
        return;
    m_sample = ImageSample{};
    m_hasSample = false;
    emit sampleChanged();
}
