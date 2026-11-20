cmake_minimum_required(VERSION 3.21)
project(GimbalUI LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Quick Quick3D QuickControls2)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(appGimbalUI main.cpp)

qt_add_qml_module(appGimbalUI
    URI GimbalUI
    QML_FILES
        qml/Main.qml
        qml/GimbalModel.qml
        qml/GimbalZR10.qml
    RESOURCES
        qml/meshes/zr10_base.mesh
        qml/meshes/zr10_yaw.mesh
        qml/meshes/zr10_pitch.mesh
)

target_link_libraries(appGimbalUI PRIVATE Qt6::Quick Qt6::Quick3D Qt6::QuickControls2)
