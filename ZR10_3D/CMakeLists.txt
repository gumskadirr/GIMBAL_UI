cmake_minimum_required(VERSION 3.16)

project(ZR10_3D VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Quick3D QuickControls2)

qt_standard_project_setup(REQUIRES 6.10)

# Content of downloaded design from Figma to Qt or similar
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

qt_add_executable(appZR10_3D
    main.cpp
)

qt_add_qml_module(appZR10_3D
    URI ZR10_3D
    QML_FILES
        Main.qml
        GimbalModel.qml
        GimbalZR10.qml
    RESOURCES
        meshes/zr10_base.mesh
        meshes/zr10_yaw.mesh
        meshes/zr10_pitch.mesh
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appZR10_3D PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appZR10_3D
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appZR10_3D
    PRIVATE Qt6::Quick Qt6::Quick3D Qt6::QuickControls2
)

install(TARGETS appZR10_3D
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
