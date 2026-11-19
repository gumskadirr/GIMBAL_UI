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
    // Script playback: one row of the script. Several arrive per second, so the device must answer quickly.
    ScriptPoint, // type: QString (as SetReference), pan: double and/or tilt: double (the axes that move; %, deg/s, deg)
    // IDS Image (View & control). Settings and choices are sent as soon as the user lets go of the control.
    // One kind for every stream setting: while one is pending the others wait (ServiceConnection rule).
    ImageSetStreamSetting, // setting: QString ("zoom"|"blend"|"brightness"|"contrast"|"streamMode"|"polarity"|
                           // "ffcMode"|"overlay"|"skyUp"), value: double (zoom, blend, brightness, contrast),
                           // int (option index) or bool (overlay, skyUp)
    ImageTriggerNuc,       // non-uniformity correction (shutter)
    ImageAttitudeEnable,   // enabled: bool
    ImageSetControlDevice, // device: QString ("keyboard" | "joystick")
    ImagePark,             // "P": move the gimbal to its park position (reading of the design, see docs/kararlar.md)
    ImageSetPosition,      // roll: double, tilt: double (deg)
    ImageResetPosition,
    ImageLrfPointer,       // enabled: bool
    ImageLrfMeasure,       // mode: QString ("single" | "continuous")
    ImageBoxSize,          // delta: int (+1 larger, -1 smaller)
    ImageTrack,
    ImageFollowTarget,     // enabled: bool
    // IDS Image (Alignment). Camera, focus mode, zoom, image scale, FOV gain, stabilization and the Manual/Auto
    // choices go as ImageSetStreamSetting: "camera"|"focusMode"|"imageScale"|"fovGain" (double, +inf = infinity)|
    // "stabilization" (bool)|"gainMode"|"irisMode"|"shutterMode" (0 Manual, 1 Auto; indices as in ImageSample).
    ImageSetFocus,         // distance: double (m; +inf = INF button)
    ImageWriteOffset,      // x: int, y: int (pixels), scale: double
    ImageCameraStep,       // param: QString ("gain"|"iris"|"shutter"), delta: int (+1, -1)
    // IDS Image (Errors).
    ImageSetIp,            // dhcp: bool, address: QString (IPv4; empty when dhcp)
    // IDS Image (Gimbal state).
    ImageGimbalState,      // running: bool (start / stop the state stream), rateHz: int (1, 5 or 10)
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
