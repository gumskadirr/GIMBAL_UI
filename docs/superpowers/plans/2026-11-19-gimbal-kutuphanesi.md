# Gimbal kütüphanesi — uygulama planı

**Goal:** Seçim penceresinden gimbal ekle/düzenle/sil; 3B model `.glb` dosyalarından, uygulama klasörüne kopyalanarak.
**Architecture:** C++ `GimbalLibrary` (AppSettings'in sahip olduğu) listeyi ve dosyaları yönetir; QML `GimbalModel` RuntimeLoader ile yükler; `GimbalEditDialog` düzenler.
**Spec:** `docs/superpowers/specs/2026-11-19-gimbal-kutuphanesi-design.md`

## Global Constraints
- Metinler `qsTr`/`tr`, TR çevirisi `tools/fill_ts.py`; qmllint 0; yeni kontroller `Accessible.name`.
- Seçim yalnız görünümü değiştirir. Yalnız `.glb`.
- Doğrulama: `bash .superpowers/sdd/plan/verify.sh`; 3B görüntü `QT_QPA_PLATFORM=windows`.

## Review Focus
- Bozuk `gimbals.json` ezilmez, `.bad` olarak saklanır → T1 `corruptFileIsKept`.
- Düzenlemede dosya seçilmezse eski model dosyaları kalır → T1 `editKeepsFiles`.
- Aynı ad (büyük/küçük harf) reddedilir → T1 `duplicateNameRejected`.
- Kayıtlı gimbal silinince üst çubuk "Select gimbal" → T3 `test_deleteSavedGimbal`.
- Kaynak dosya sonradan silinse de model yüklenir (kopya) → T1 `filesAreCopied`.

### Task 1: GimbalLibrary
**Files:** Create `shared/settings/GimbalLibrary.{h,cpp}`, `test/unit/tst_gimballibrary.cpp`, `features/gimbal3d/zr10/{base,pan,tilt}.glb`; Modify `shared/settings/AppSettings.{h,cpp}`, `CMakeLists.txt`, `test/CMakeLists.txt`.
**Produces:** `GimbalLibrary(dir)`; `Q_PROPERTY QVariantList gimbals NOTIFY changed` (model: `{ base, pan, tilt: file URL, panAxis, panSign, panPivot, tiltAxis, tiltSign, tiltPivot, inPlace }` ya da null); `Q_INVOKABLE QString save(QVariantMap gimbal, QVariantMap files)`; `Q_INVOKABLE QString remove(QString id)`; `void reload()`; sinyal `problem(QString message)`; `AppSettings::gimbalLibrary()`.
- [x] Testler: `seedsDefaults` (4 kayıt, zr10 dosyaları var), `addCopiesFilesAndPersists`, `filesAreCopied`, `editKeepsFiles`, `editReplacesFile`, `removeDeletesFolder`, `duplicateNameRejected`, `modelNeedsAllThreeFiles`, `corruptFileIsKept`, `idFromName`.
- [x] Uygula, doğrula, commit.

### Task 2: Dosyadan 3B model
**Files:** Modify `features/gimbal3d/{GimbalModel,GimbalView}.qml`, `app/Main.qml` (`gimbals` = `settings.gimbalLibrary.gimbals`), `test/qml/tst_gimbal3d.qml`, `test/qml/tst_qml.cpp` (kütüphane sıfırlama yardımcısı); Delete `GimbalZR10.qml`, `meshes/`.
**Consumes:** T1 model nesnesi.
- [x] Testler: eksen dönüşü ve `inPlace` kaydırması (`test_axesFollowAngles`, `test_inPlaceOffsetsParts`), mevcut tst_gimbal3d.
- [x] Uygula; 3B ekran görüntüsü (windows); doğrula; commit.

### Task 3: Ekle / düzenle / sil arayüzü
**Files:** Create `app/GimbalEditDialog.qml`, `test/qml/tst_gimbaledit.qml`; Modify `app/GimbalSelectDialog.qml`, `app/Main.qml`, `CMakeLists.txt`, TS, `tools/shot/tst_shot.qml`, `docs/kararlar.md`.
- [x] Testler: `test_addGimbal`, `test_editName`, `test_cancelChangesNothing`, `test_validationMessages`, `test_deleteAsksAndRemoves`, `test_deleteSavedGimbal`.
- [x] Uygula; ekran görüntüleri; doğrula; kararlar.md; commit; main'e birleştir.
