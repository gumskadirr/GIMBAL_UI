# IdsUi QML modülü (Qt 6.5+)
# Ana CMakeLists.txt içinde:
#   find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 QuickShapes)
#   add_subdirectory(IdsUi)
#   target_link_libraries(app PRIVATE IdsUiplugin)
# Not: Bu yolu kullanıyorsanız elle yazılmış qmldir dosyasını silin; CMake kendisi üretir.

qt_add_library(IdsUi STATIC)

set_source_files_properties(Theme.qml Icons.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(IdsUi
    URI IdsUi
    VERSION 1.0
    QML_FILES
        Theme.qml
        Icons.qml
        AppShell.qml
        ArcGauge.qml
        Badge.qml
        BrandStripe.qml
        Card.qml
        CardBackground.qml
        ChoiceChip.qml
        ConnectionPopup.qml
        FocusRing.qml
        FormField.qml
        Hint.qml
        Icon.qml
        IdsButton.qml
        IdsComboBox.qml
        IdsPopup.qml
        IdsProgressBar.qml
        IdsSlider.qml
        IdsSwitch.qml
        IdsTabs.qml
        IdsTextField.qml
        InfoRow.qml
        Kbd.qml
        KpiTile.qml
        Led.qml
        NavDivider.qml
        NavItem.qml
        NavRail.qml
        NavSection.qml
        OverlayTag.qml
        RailBrand.qml
        SegmentedControl.qml
        SelectableCard.qml
        Shadow.qml
        StatCell.qml
        StatStrip.qml
        StatusBar.qml
        StatusBarButton.qml
        StatusBarSection.qml
        StatusDot.qml
        StatusLabel.qml
        TestResultTile.qml
        ThemeSwitcher.qml
        ToggleRow.qml
        TopBar.qml
        VideoViewport.qml
        Zone.qml
)

target_link_libraries(IdsUi PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::QuickShapes)
