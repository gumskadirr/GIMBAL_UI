# Sample data provider: linked only by the demo target and tests, never by appIDS_GIMBAL.
qt_add_library(ids_gimbal_demo_provider STATIC DemoProvider.h DemoProvider.cpp)
target_include_directories(ids_gimbal_demo_provider PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(ids_gimbal_demo_provider PUBLIC ids_gimbal)
