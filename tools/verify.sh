#!/usr/bin/env bash
# Full check before merging to main: build, qmllint (must print lint=0), every ctest test, and both apps start
# and quit cleanly (exit=0, empty stderr). Run from the project root in Git Bash.
# QT_ROOT: Qt installation root (default C:/Qt, Qt 6.12.0 MinGW 64-bit).
QT_ROOT="${QT_ROOT:-/c/Qt}"
export PATH="$QT_ROOT/6.12.0/mingw_64/bin:$QT_ROOT/Tools/mingw1310_64/bin:$QT_ROOT/Tools/CMake_64/bin:$QT_ROOT/Tools/Ninja:$PATH"
# -j 2: more parallel jobs ran the development machine out of memory.
cmake --build build/cli-debug -j 2 2>&1 | grep -E "error|FAILED|warning:" | head -20; echo "build rc=${PIPESTATUS[0]}"
# qmllint exits with 0 on warnings too, so the warning lines are counted.
cmake --build build/cli-debug --target all_qmllint > build/lint.txt 2>&1; echo "lint=$(grep -cE '^(Warning|Error)' build/lint.txt)"
QT_QPA_PLATFORM=offscreen ctest --test-dir build/cli-debug --output-on-failure 2>&1 | grep -E "tests passed|Failed|FAIL!" | head -20
powershell -NoProfile -ExecutionPolicy Bypass -File tools/appcheck.ps1
