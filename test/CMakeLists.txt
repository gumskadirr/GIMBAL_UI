function(ids_add_test name)
    qt_add_executable(${name} unit/${name}.cpp ${ARGN})
    target_link_libraries(${name} PRIVATE Qt6::Test ids_gimbal)
    add_test(NAME ${name} COMMAND ${name})
endfunction()

add_subdirectory(doubles)
add_subdirectory(app)

ids_add_test(tst_appsettings)
ids_add_test(tst_gimballibrary)
ids_add_test(tst_notificationmodel)
ids_add_test(tst_localization)
ids_add_test(tst_devicesession unit/FakeProvider.h)
ids_add_test(tst_serviceconnection unit/FakeProvider.h)
ids_add_test(tst_maincontrolviewmodel unit/FakeProvider.h)
ids_add_test(tst_imageviewmodel unit/FakeProvider.h)
ids_add_test(tst_parametermodel unit/FakeProvider.h)
ids_add_test(tst_csvrecorder unit/FakeProvider.h)
ids_add_test(tst_seriesbuffer)
ids_add_test(tst_scriptfile)
ids_add_test(tst_scriptrunner unit/FakeProvider.h)
ids_add_test(tst_demoprovider)
ids_add_test(tst_fonts)
ids_add_test(tst_connectionstore)
ids_add_test(tst_transportprovider)
target_link_libraries(tst_demoprovider PRIVATE ids_gimbal_demo_provider)
target_link_libraries(tst_serviceconnection PRIVATE ids_gimbal_demo_provider)
target_link_libraries(tst_parametermodel PRIVATE ids_gimbal_demo_provider)

# Qt Quick Test: every test/qml/tst_*.qml runs against the real IDS_GIMBAL module.
qt_add_executable(tst_qml qml/tst_qml.cpp unit/FakeProvider.h)
target_link_libraries(tst_qml PRIVATE Qt6::QuickTest ids_gimbal ids_gimbalplugin)
target_compile_definitions(tst_qml PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml")
add_test(NAME tst_qml COMMAND tst_qml)

# Runs lupdate, so the .ts file in the source tree is updated as a side effect (that is the intended workflow).
add_test(NAME translations_complete
    COMMAND ${CMAKE_COMMAND}
        -DBUILD_DIR=${CMAKE_BINARY_DIR}
        -DTS_FILE=${PROJECT_SOURCE_DIR}/translations/IDS_GIMBAL_tr.ts
        -P ${CMAKE_CURRENT_SOURCE_DIR}/check_translations.cmake)

# docs/protokol-siniri.md must name every command, field and key of the protocol boundary (and nothing else).
find_package(Python3 QUIET COMPONENTS Interpreter)
if(Python3_Interpreter_FOUND)
    add_test(NAME protocol_doc_matches
        COMMAND ${Python3_EXECUTABLE} ${PROJECT_SOURCE_DIR}/tools/check_protocol_doc.py ${PROJECT_SOURCE_DIR})
endif()
