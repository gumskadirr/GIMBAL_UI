# Adım 5a — Kesin tema, yazı tipleri ve inceleme düzeltmeleri

**Hedef:** Kesin tasarımın Theme'ini (light/blue/dark) ve fontlarını uygulamaya almak; Fable incelemesinin bulduğu üç hatayı düzeltmek; ilk Qt Quick Test'i kurmak.

**Dayanak:** `../gimbal-nihai-mimari-v1.1.md` Bölüm 7, 9, 10, 15.3. Tasarım kaynağı `../taslak/files/ids-qml/IdsUi/Theme.qml`.

**Kapsam dışı (Adım 5b):** IdsButton, IdsComboBox, Icons/Icon, FocusRing; AppButton'un kaldırılması; popup testi.

## Görevler

1. **Kapanış sırası (hata 1).** `Localization` QML motoru almaz; `AppRunner` onu motordan önce oluşturur ve `languageChanged` → `engine.retranslate()` bağlantısını ilk bağlantı olarak kurar. Kontrol: uygulama kapanışında stderr'de `TypeError` yok.
2. **Yapışkan QSettings durumu (hata 2).** Qt 6.12 belgesi: `status()` "ilk hatayı" döndürür. `AppSettings` her yazmada yeni `QSettings` açar. Test: `writeRecoversAfterFailure` — ilk yazma başarısız, yol düzelince sonraki yazma `writeFailed` üretmez.
3. **Çevrilmeyen metinler (hata 3).**
   - `DisconnectedProvider` metni `QT_TRANSLATE_NOOP("DeviceDetail", …)`; `DeviceViewModel::errorDetail` ve bildirim `detail` rolü gösterimde `DeviceDetail` bağlamında çevirir (cihazın ham metni için çeviri bulunmaz, olduğu gibi kalır). `NotificationModel::retranslate` `DetailRole`'ü de bildirir.
   - `settings.writeFailed` mesajı "Preferences could not be saved"; ayar anahtarı teknik ayrıntı (`detail`) olarak verilir.
4. **Theme.** `shared/ui/Theme.qml` ← taslak Theme (rol adları aynen) + mevcut sayfaların kullandığı `spacingSmall/Normal/Large` (4/8/16). `Main.qml` `Theme.mode`'u `settings.theme`'e bağlar. `AppSettings` temaları: `dark` (varsayılan), `light`, `blue`. Mevcut 5 QML dosyası yeni rol adlarına geçer; Tercihlerde üç tema düğmesi.
5. **Fontlar.** `assets/fonts/` (Inter ve JetBrains Mono; Regular/Medium/SemiBold/Bold + OFL metinleri) `:/fonts` altına gömülür. `shared/ui/Fonts.{h,cpp}`: `QStringList loadAppFonts()` yüklenemeyen dosyaları döndürür; `AppRunner` uygulama fontunu Inter yapar, başarısızlıkta `fonts.loadFailed` uyarı bildirimi. Test: `tst_fonts` — hiçbir dosya başarısız değil, `Inter` ve `JetBrains Mono` aileleri `QFontDatabase::families()` içinde.
6. **İlk Qt Quick Test.** `test/qml/` + `tst_qml` (QUICK_TEST_MAIN_WITH_SETUP; Basic stil, fontlar). `tst_theme.qml`:
   - üç paletin anahtar kümeleri aynı ve hiçbir değer boş değil;
   - `Theme.mode` değişince `bg`/`card`/`acc` beklenen tasarım değerlerine geçer;
   - bilinmeyen mod light paletine düşer;
   - bir `AppButton` ve `NotificationArea` zemini tema değişimini anında izler.
7. **Doğrulama:** derleme, `all_qmllint` uyarısız, tüm CTest'ler (çeviri dahil) geçer, iki exe ekransız açılır.

## Sonraki adaylar (kesin değil)
- 5b: Icons/Icon/FocusRing/IdsButton/IdsComboBox, Tercihler ComboBox, AppButton kalkar, açık popup tema testi.
- 6: AppShell/NavRail/TopBar/StatusBar iskeleti + gerçek sayfa kaydı.
