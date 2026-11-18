#include "DeviceSession.h"

#include <utility>

DeviceSession::DeviceSession(std::unique_ptr<IDeviceProvider> provider, QObject *parent)
    : QObject(parent), m_provider(std::move(provider))
{
    connect(m_provider.get(), &IDeviceProvider::stateChanged, this, &DeviceSession::onProviderState);
    connect(m_provider.get(), &IDeviceProvider::sampleReceived, this, &DeviceSession::onProviderSample);
    connect(m_provider.get(), &IDeviceProvider::boardInfoReceived, this, &DeviceSession::onProviderBoardInfo);
    connect(m_provider.get(), &IDeviceProvider::bitReportReceived, this,
            [this](quint64 sessionId, const BitReport &report) {
                if (isActive(sessionId))
                    emit bitReportAccepted(report);
            });
    connect(m_provider.get(), &IDeviceProvider::crosstalkResultReceived, this,
            [this](quint64 sessionId, const CrosstalkResult &result) {
                if (isActive(sessionId))
                    emit crosstalkResultAccepted(result);
            });
    connect(m_provider.get(), &IDeviceProvider::imuBiasReceived, this,
            [this](quint64 sessionId, const ImuBias &bias) {
                if (isActive(sessionId))
                    emit imuBiasAccepted(bias);
            });
    connect(m_provider.get(), &IDeviceProvider::commandProgress, this,
            [this](quint64 sessionId, quint64 requestId, int percent, const QString &stage) {
                const auto it = m_pending.constFind(requestId);
                if (isActive(sessionId) && it != m_pending.cend())
                    emit commandProgressed(requestId, it.value(), percent, stage);
            });
    connect(m_provider.get(), &IDeviceProvider::parametersReceived, this,
            [this](quint64 sessionId, const QVariantMap &values) {
                if (isActive(sessionId))
                    emit parametersAccepted(values);
            });
    connect(m_provider.get(), &IDeviceProvider::commandFinished, this, &DeviceSession::onProviderCommandFinished);
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
    m_provider->start(m_activeId, m_target);
}

void DeviceSession::disconnectDevice()
{
    if (m_activeId == 0)
        return;
    m_activeId = 0;
    m_provider->stop();
    cancelPending();
    setState(ConnectionState::Disconnected, {});
}

quint64 DeviceSession::send(const DeviceCommand &command)
{
    if (m_state != ConnectionState::Connected || !m_provider->supportsCommands())
        return 0;
    const quint64 requestId = m_nextRequestId++;
    m_pending.insert(requestId, command);
    emit pendingChanged();
    m_provider->send(m_activeId, requestId, command);
    return requestId;
}

void DeviceSession::cancelPending()
{
    if (m_pending.isEmpty())
        return;
    const auto pending = std::exchange(m_pending, {});
    emit pendingChanged();
    for (auto it = pending.cbegin(); it != pending.cend(); ++it)
        emit commandFinished(it.key(), it.value(), {Command::Cancelled, {}});
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
        cancelPending();
    }
    setState(state, detail);
}

void DeviceSession::onProviderSample(quint64 sessionId, const DeviceSample &sample)
{
    if (isActive(sessionId))
        emit sampleAccepted(sample);
}

void DeviceSession::onProviderBoardInfo(quint64 sessionId, const BoardInfo &info)
{
    if (isActive(sessionId))
        emit boardInfoAccepted(info);
}

void DeviceSession::onProviderCommandFinished(quint64 sessionId, quint64 requestId, const CommandResult &result)
{
    if (!isActive(sessionId))
        return;
    const auto it = m_pending.constFind(requestId);
    if (it == m_pending.cend())
        return; // already answered
    const DeviceCommand command = it.value();
    m_pending.erase(it);
    emit pendingChanged();
    emit commandFinished(requestId, command, result);
}

void DeviceSession::setState(ConnectionState state, const QString &detail)
{
    if (state == m_state && detail == m_detail)
        return;
    m_state = state;
    m_detail = detail;
    emit stateChanged();
}
