# Gimbal seçim paneli — uygulama planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Üst çubuktaki düğmeyle açılan, yalnız görünümü değiştiren gimbal seçim paneli; IDS Image'da Roll → Pan.
**Architecture:** Gimbal listesi `Main.qml`'de (sayfa listesi gibi), seçim `AppSettings`'te, panel `shared/ui/GimbalSelectDialog.qml` (IdsPopup). Cihaz katmanına yalnız ad değişikliği dokunur.
**Tech Stack:** Qt 6.12 QML + C++, Qt Quick Test, QtTest.
**Spec:** `docs/superpowers/specs/2026-11-19-gimbal-secimi-design.md`

## Global Constraints
- Seçim yalnız görünümü değiştirir; sayfa, ayar, bağlantı değişmez.
- Metinler `qsTr`, TR çevirisi `translations/IDS_GIMBAL_tr.ts` (`tools/fill_ts.py`); TR ondalık virgül.
- qmllint 0 uyarı; yeni kontroller `Accessible.name` taşır, klavyeyle odaklanır.
- Doğrulama: `bash .superpowers/sdd/plan/verify.sh`.

## Review Focus
- Kayıtlı gimbal listede yoksa (silinmiş id ya da sürüm): seçilmemiş sayılır, panel açılışta açılır → T3 testi `test_unknownSavedGimbalOpensAtStart`.
- Cancel/Esc sonrası tekrar açılan panel kayıtlı seçimi gösterir, yarım seçimi değil → T3 `test_cancelKeepsSaved`.
- Başka kartın sürümüne tıklama kartı seçer, alt satır onu yazar → T3 `test_versionClickSelectsCard`.
- Panel ve bağlantı penceresi aynı anda açılmaz → T3 `test_connectionSettingsWaitForGimbal`.
- Uzun Türkçe metin kartlarda taşmaz → ekran görüntüsü (TR).

---

### Task 1: Roll → Pan (IDS Image)
**Files:** `device/api/DeviceTypes.h`, `device/api/DeviceCommand.h`, `test/doubles/ImageDemoProvider.cpp`, `features/idsimage/ViewControlPage.qml`, `features/idsimage/ImagePageFrame.qml`, `test/qml/tst_viewcontrol.qml`, `docs/protokol-siniri.md`, `shared/ui/VideoViewport.qml` (yorum)
- [x] `ImageSample.rollDeg/rollRateDps` → `panDeg/panRateDps`; `ImageSetPosition` argümanı `roll` → `pan`; etiketler "Pan, deg", "Pan, deg/s", görüntü etiketi `PAN %1  TILT %2`; objectName `tile-pan`, `tile-panRate`, `input-pan`; `rollLimit` → `panLimit`.
- [x] Testler: `tagAttitude` = `"PAN 0.0  TILT 0.0"` / `"PAN 0,0  TILT 0,0"`, `lastImageCommandArgs().pan === 10.5`.
- [x] Doğrula (tek commit, Task 3 ile).

### Task 2: AppSettings gimbal alanları
**Files:** `shared/settings/AppSettings.{h,cpp}`, `test/unit/tst_appsettings.cpp`
**Produces:** `Q_PROPERTY QString gimbal`, `QString gimbalVersion`, `bool gimbalOnStart` (varsayılan true); anahtarlar `gimbal/id`, `gimbal/version`, `gimbal/onStart`.
- [x] Test `gimbalPersists`: boş başlar, `gimbalOnStart` true; set sonrası yeni nesne aynı değerleri okur.
- [x] Uygula, doğrula, commit.

### Task 3: Panel, üst çubuk düğmesi, açılış
**Files:** Create `app/GimbalSelectDialog.qml`, `test/qml/tst_gimbalselect.qml`; Modify `app/Main.qml`, `shared/ui/Icons.qml` (`gimbal`, `arrowRight`), `CMakeLists.txt`, TS.
**Consumes:** Task 2 özellikleri.
**Produces:** `window.gimbals` = `[{id, name, versions, model}]`; `window.currentGimbal` (listeden bulunan ya da null); düğme objectName `gimbalButton`; panel objectName `gimbalDialog` (`gimbals`, `currentId`, `currentVersion`, `onStart`, `selectedId`, `selectedVersion`, sinyal `accepted(id, version, onStart)`); kart `gimbalCard-<id>`, sürüm `version-<id>-<v>`, `gimbalContinue`, `gimbalCancel`, `gimbalOnStart`, `gimbalSelected` (metin).
- [x] Testler: `test_versionClickSelectsCard`, `test_cardClickSelectsLastVersion`, `test_continueSaves` (ayar + düğme metni `G180 · v2.0`), `test_cancelKeepsSaved`, `test_unknownSavedGimbalOpensAtStart`, `test_onStartOffOpensAtStart`, `test_validSavedGimbalDoesNotOpen`, `test_connectionSettingsWaitForGimbal`.
- [x] Uygula; ekran görüntüsü (koyu EN, açık TR); doğrula; kararlar.md + bellek; commit, main'e birleştir.
