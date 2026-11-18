#pragma once

#include <QMetaType>
#include <QObject>
#include <QVariantMap>

// Commands the UI sends to a device service (protocol boundary, docs/protokol-siniri.md). The protocol
// implementation maps each kind and its args to bytes; the UI never knows the encoding.
namespace Command {
Q_NAMESPACE

// Args of each kind are listed next to it; a kind without a note takes none. Add new kinds at the end.
enum Kind {
    AskBootloader,
    ExitBootloader,
    StartBootBridge, // board: QString (sub-board name)
    RunBit,
};
Q_ENUM_NS(Kind)

enum Status {
    Accepted,    // the device carried it out (or acknowledged it)
    Rejected,    // the device refused it (detail: reason)
    Failed,      // sent but no valid answer (timeout, transport error)
    Cancelled,   // the session ended before an answer
    Unsupported, // the provider cannot send this kind (no protocol yet)
};
Q_ENUM_NS(Status)
} // namespace Command

struct DeviceCommand
{
    Command::Kind kind = Command::AskBootloader;
    QVariantMap args;
};

struct CommandResult
{
    Command::Status status = Command::Accepted;
    QString detail; // raw device / provider text, not translated
};

Q_DECLARE_METATYPE(DeviceCommand)
Q_DECLARE_METATYPE(CommandResult)
