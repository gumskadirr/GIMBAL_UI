# Adım 1 — Uygulama iskeleti ve açık/koyu tema

> Yalnız bu adımı tanımlar. Sonraki adım bu adım bitince birlikte seçilir.

**Spec:** `../../../../gimbal-nihai-mimari-v1.0.md` (Bölüm 5, 9)

**Amaç:** "Hello World" şablonunun yerine, renkleri merkezi bir `Theme` nesnesinden alan ve açık/koyu tema arasında geçebilen boş bir uygulama penceresi.

## Kapsam

- `CMakeLists.txt`: C++17 açıkça, Qt 6.12 (`find_package(Qt6 6.12 ...)`, `qt_standard_project_setup(REQUIRES 6.12)`), `Quick` + `QuickControls2`.
- `main.cpp`: motor yüklenmeden önce `QQuickStyle::setStyle("Basic")`.
- `shared/ui/Theme.qml`: QML singleton; `property bool dark: true` ve belgedeki renk rolleri (`background`, `surface`, `textPrimary`, `textSecondary`, `accent`, `warning`, `error`, `border`, `disabled`, `focus`) için geçici nötr açık/koyu değerler.
- `shared/ui/AppButton.qml`: Basic `Button`; normal / basılı / devre dışı / odak durumları Theme'den.
- `Main.qml`: sabit renk yok; arka plan Theme'den, bir `AppButton` temayı değiştirir.

Hepsi şimdilik mevcut tek hedef `appIDS_GIMBAL` ve tek QML modülü içinde kalır. Ayrı kütüphanelere bölme, ikinci (demo) hedef gelince yapılır.

## Bu adımda yok

Tercih saklama, dil, bildirim, cihaz katmanı, demo hedefi, test altyapısı. (Tema yalnız veri olduğu için test gerektirmez; ilk C++ mantığıyla birlikte `test/` kurulur.)

## Bitti sayılması

1. Komut satırından derleme hatasız:
   ```bash
   export PATH="/c/Qt/6.12.0/mingw_64/bin:/c/Qt/Tools/mingw1310_64/bin:/c/Qt/Tools/CMake_64/bin:/c/Qt/Tools/Ninja:$PATH"
   cmake -S . -B build/cli-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=C:/Qt/6.12.0/mingw_64
   cmake --build build/cli-debug
   ```
2. Uygulama koyu temada açılır; düğme açık temaya geçirir ve geri alır. Devre dışı ve klavye odağı (Tab) durumları iki temada da görünür.
3. `grep -rn "#[0-9a-fA-F]\{6\}" Main.qml` → çıktı yok (renkler yalnız Theme'de).

## Sonraki adım adayları (karar değil)

Tema tercihini kalıcı saklama · Türkçe/İngilizce · bildirim alanı · cihaz sözleşmesi + demo hedefi.
