cmake_minimum_required(VERSION 3.16)

project(IDS_GIMBAL VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.12 REQUIRED COMPONENTS Quick QuickControls2 SerialPort Network Test QuickTest LinguistTools)

qt_standard_project_setup(REQUIRES 6.12)

# QML module output lands in <build>/qml/IDS_GIMBAL so tooling (qmllint) resolves the import.
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)

# Shared code of both run targets: app frame, shared services, device layer, features and QML.
# Executables link ids_gimbal + ids_gimbalplugin and call Q_IMPORT_QML_PLUGIN(IDS_GIMBALPlugin).
qt_add_library(ids_gimbal STATIC)

set_source_files_properties(shared/ui/Theme.qml shared/ui/Icons.qml shared/ui/NumberFormat.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(ids_gimbal
    URI IDS_GIMBAL
    SOURCES
        app/AppRunner.h app/AppRunner.cpp
        shared/settings/AppSettings.h shared/settings/AppSettings.cpp
        shared/localization/Localization.h shared/localization/Localization.cpp
        shared/notifications/NotificationModel.h shared/notifications/NotificationModel.cpp
        device/api/DeviceTypes.h device/api/IDeviceProvider.h
        device/session/DeviceSession.h device/session/DeviceSession.cpp
        device/presentation/DeviceViewModel.h device/presentation/DeviceViewModel.cpp
        device/presentation/DeviceValueTypes.h
        device/session/ConnectionStore.h device/session/ConnectionStore.cpp
        device/transport/TransportProvider.h device/transport/TransportProvider.cpp
        shared/ui/Fonts.h shared/ui/Fonts.cpp
    QML_FILES
        app/Main.qml
        app/PreferencesPage.qml
        shared/ui/Theme.qml
        shared/ui/Icons.qml
        shared/ui/NumberFormat.qml
        shared/ui/Icon.qml
        shared/ui/FocusRing.qml
        shared/ui/IdsButton.qml
        shared/ui/IdsComboBox.qml
        shared/ui/AppShell.qml
        shared/ui/BrandStripe.qml
        shared/ui/NavRail.qml
        shared/ui/NavItem.qml
        shared/ui/NavSection.qml
        shared/ui/RailBrand.qml
        shared/ui/Shadow.qml
        shared/ui/TopBar.qml
        shared/ui/StatusBar.qml
        shared/ui/StatusBarSection.qml
        shared/ui/StatusBarButton.qml
        shared/ui/StatusLabel.qml
        shared/ui/StatusDot.qml
        shared/ui/Badge.qml
        shared/ui/IdsPopup.qml
        shared/ui/CardBackground.qml
        shared/ui/StatStrip.qml
        shared/ui/StatCell.qml
        shared/ui/ArcGauge.qml
        shared/ui/Card.qml
        shared/ui/KpiTile.qml
        shared/ui/InfoRow.qml
        shared/ui/Zone.qml
        shared/ui/Hint.qml
        shared/ui/FormField.qml
        shared/ui/VideoViewport.qml
        shared/ui/SegmentedControl.qml
        shared/ui/IdsTextField.qml
        shared/ui/ToggleRow.qml
        shared/ui/IdsSwitch.qml
        shared/ui/IdsProgressBar.qml
        shared/ui/IdsSlider.qml
        shared/ui/ConnectionPopup.qml
        shared/ui/Kbd.qml
        shared/ui/IdsTabs.qml
        shared/notifications/NotificationArea.qml
        features/maincontrol/ControlPageFrame.qml
        features/maincontrol/SectionHeading.qml
        features/maincontrol/GimbalInfoPage.qml
        features/maincontrol/MotorControlPage.qml
        features/maincontrol/GimbalSettingsPage.qml
        features/maincontrol/HeaterPage.qml
    RESOURCES
        assets/icons/ids_logo.png
)

target_include_directories(ids_gimbal
    PUBLIC ${PROJECT_SOURCE_DIR}
    # The generated QML type registration includes headers by file name.
    PRIVATE shared/settings shared/localization shared/notifications device/presentation device/api
)

target_link_libraries(ids_gimbal PUBLIC Qt6::Quick Qt6::QuickControls2 Qt6::SerialPort Qt6::Network)
target_compile_definitions(ids_gimbal PRIVATE IDS_GIMBAL_VERSION="${PROJECT_VERSION}")

# Inter and JetBrains Mono (SIL OFL 1.1, license texts next to the files), loaded by loadAppFonts().
qt_add_resources(ids_gimbal "fonts"
    PREFIX "/fonts"
    BASE assets/fonts
    FILES
        assets/fonts/Inter-Regular.ttf assets/fonts/Inter-Medium.ttf
        assets/fonts/Inter-SemiBold.ttf assets/fonts/Inter-Bold.ttf
        assets/fonts/JetBrainsMono-Regular.ttf assets/fonts/JetBrainsMono-Medium.ttf
        assets/fonts/JetBrainsMono-SemiBold.ttf assets/fonts/JetBrainsMono-Bold.ttf
)

# Real target: opens serial (UART) or UDP through TransportProvider; it never shows sample data.
qt_add_executable(appIDS_GIMBAL
    app/main.cpp
)
target_link_libraries(appIDS_GIMBAL PRIVATE ids_gimbal ids_gimbalplugin)

set_target_properties(appIDS_GIMBAL PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

enable_testing()
add_subdirectory(test)

# .qm files are embedded under :/i18n in ids_gimbal and so reach every target that links it.
qt_add_translations(
    TARGETS ids_gimbal
    SOURCE_TARGETS ids_gimbal appIDS_GIMBAL
    TS_FILES translations/IDS_GIMBAL_tr.ts
    NO_GENERATE_PLURALS_TS_FILE
)

install(TARGETS appIDS_GIMBAL
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
