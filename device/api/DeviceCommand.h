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
    // Parameters (architecture §13, device/api/ParameterKeys.h). The device answers reads and defaults
    // with parametersReceived; an accepted write means the device now holds the written values.
    ReadParameters,  // prefix: QString (optional; only the keys starting with it, e.g. "heater."; none = all)
    WriteParameters, // values: QVariantMap (key -> value, only the changed keys)
    SaveParametersToFlash,
    RestoreDefaultParameters,
    // Firmware update (progress through IDeviceProvider::commandProgress; answered when it ends).
    UpdateFirmware, // file: QString (local path of the firmware file)
    CancelFirmwareUpdate,
    // Motor control
    SetControlMode, // mode: int (index of the control mode list: Torque, Speed, Position)
    SelectMotor,    // motor: QString ("pan" | "tilt"), the motor the control commands drive
    ToggleLatch,    // the safe-control latch
    StartControl,
    StopControl,
    SetReference,   // type: QString ("torque" | "speed" | "position"), value: double (%, deg/s, deg)
    ResetReference, // type: QString (as SetReference)
    // Gimbal settings. The calibrations are long: progress through IDeviceProvider::commandProgress, the answer
    // comes when they end; their results arrive as crosstalkResultReceived / imuBiasReceived.
    StartStream,
    StopStream,
    SafeStop, // no confirmation: it must always be one press away
    StartElectricalAngleCalibration,
    StartCrosstalkCheck,
    StartImuBiasCalibration,
    StepResponse, // direction: int (+1 or -1); the result arrives as stepMetricsReceived
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
