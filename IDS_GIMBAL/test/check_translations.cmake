# Fails when a user-visible string has no Turkish translation.
# Runs lupdate first so new or changed strings in the code are picked up.
# Inputs: BUILD_DIR, TS_FILE
execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${BUILD_DIR} --target update_translations
    RESULT_VARIABLE result
    OUTPUT_QUIET
)
if(NOT result EQUAL 0)
    message(FATAL_ERROR "update_translations failed (${result})")
endif()

file(READ ${TS_FILE} ts)
string(REGEX MATCHALL "<source>[^<]*</source>[^<]*(<[^/][^>]*>[^<]*</[^>]*>[^<]*)*<translation type=\"unfinished\"" missing "${ts}")
list(LENGTH missing count)
if(count GREATER 0)
    set(texts "")
    foreach(entry IN LISTS missing)
        string(REGEX MATCH "<source>([^<]*)</source>" _ "${entry}")
        string(APPEND texts "\n  - ${CMAKE_MATCH_1}")
    endforeach()
    message(FATAL_ERROR "${count} untranslated string(s) in ${TS_FILE}:${texts}")
endif()
message(STATUS "All strings translated: ${TS_FILE}")
