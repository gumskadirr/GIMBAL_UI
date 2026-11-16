#pragma once

#include <QStringList>

// Registers the embedded Inter and JetBrains Mono files (:/fonts). Returns the files that failed to load.
// Call after the QGuiApplication exists.
QStringList loadAppFonts();
