# Adım 5b — Tasarımın ortak kontrolleri

**Hedef:** Mevcut sayfaların kullandığı kontrolleri taslaktan almak, `AppButton`'u kaldırmak ve açık popup'ın temayı izlediğini test etmek.

**Dayanak:** `../gimbal-nihai-mimari-v1.1.md` Bölüm 9 ve 15.3. Kaynak: `../taslak/files/ids-qml/IdsUi/`.

## Görevler

1. **Kopyalanacaklar** (`shared/ui/`, `import IdsUi` → `import IDS_GIMBAL`):
   - `Icons.qml` (singleton, çizgi yolları)
   - `Icon.qml`: 4x MSAA katmanı yerine `Shape.CurveRenderer`
   - `FocusRing.qml`
   - `IdsButton.qml`: `checked` görünümü eklenir (`navOn` zemin, `navRing` kenar, `navOnText` yazı)
   - `IdsComboBox.qml`: delegate'te `required property` (nitelenmemiş `index`/`modelData`/`model` kalkar)
2. **Kullanım:**
   - Sekmeler `IdsButton` (`checked`).
   - Tercihler: tema ve dil için `IdsComboBox`. Değerler `valueRole: "code"` ile tutulur; `currentIndex` ayardan türetilir, `onActivated` ayara yazar.
   - Tanılama: Bağlan `primary`, Bağlantıyı kes `secondary`.
   - Bildirimler: Temizle `quiet` ve `compact`; kapatma düğmesi `Icons.close` ikonlu.
   - `AppButton.qml` silinir.
3. **Testler** (`test/qml/`):
   - `tst_theme.qml`: `AppButton` → `IdsButton`.
   - `tst_controls.qml`:
     - `IdsButton` `checked` iken zemin `navOn` olur, devre dışıyken saydamlık 0.5.
     - `IdsComboBox` açık popup'ın zemini tema değişince anında `Theme.card` olur.
     - Kullanıcı seçimi `onActivated` ile ayara yazılır; ayar dışarıdan değişince seçim izler.
     - Model yeniden atanınca (dil değişimi) seçim ayara göre korunur.
4. **Doğrulama:** derleme, `all_qmllint` uyarısız, tüm CTest'ler, iki exe açılıp hatasız kapanır.

## Sonraki aday (kesin değil)
- 6: AppShell/NavRail/TopBar/StatusBar iskeleti + gerçek sayfa kaydı; Diagnostics yalnız demo hedefinde.
