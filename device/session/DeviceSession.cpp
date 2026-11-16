#include "DeviceSession.h"

DeviceSession::DeviceSession(std::unique_ptr<IDeviceProvider> provider, QObject *parent)
    : QObject(parent), m_provider(std::move(provider))
{
    connect(m_provider.get(), &IDeviceProvider::stateChanged, this, &DeviceSession::onProviderState);
    connect(m_provider.get(), &IDeviceProvider::sampleReceived, this, &DeviceSession::onProviderSample);
}

DeviceSession::~DeviceSession()
{
    // Stop data production before the provider is destroyed.
    m_provider->disconnect(this);
    m_provider->stop();
}

void DeviceSession::connectDevice()
{
    disconnectDevice();
    m_activeId = m_nextId++;
    setState(ConnectionState::Connecting, {});
    emit sessionStarted(m_activeId);
    m_provider->start(m_activeId);
}

void DeviceSession::disconnectDevice()
{
    if (m_activeId == 0)
        return;
    m_activeId = 0;
    m_provider->stop();
    setState(ConnectionState::Disconnected, {});
}

bool DeviceSession::isActive(quint64 sessionId)
{
    if (sessionId != 0 && sessionId == m_activeId)
        return true;
    ++m_staleDropped;
    return false;
}

void DeviceSession::onProviderState(quint64 sessionId, ConnectionState state, const QString &detail)
{
    if (!isActive(sessionId))
        return;
    if (state == ConnectionState::Error || state == ConnectionState::Disconnected) {
        m_activeId = 0; // the provider ended this session; later results of it are stale
        m_provider->stop();
    }
    setState(state, detail);
}

void DeviceSession::onProviderSample(quint64 sessionId, const DeviceSample &sample)
{
    if (isActive(sessionId))
        emit sampleAccepted(sample);
}

void DeviceSession::setState(ConnectionState state, const QString &detail)
{
    if (state == m_state && detail == m_detail)
        return;
    m_state = state;
    m_detail = detail;
    emit stateChanged();
}
