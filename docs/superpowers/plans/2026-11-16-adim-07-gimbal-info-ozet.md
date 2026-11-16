# Adım 7 — Gimbal info: özet şeridi

**Hedef:** Tasarımdaki Gimbal info sayfasının yalnız üst özet şeridini demo verisiyle göstermek.

**Dayanak:** `../gimbal-nihai-mimari-v1.1.md` Bölüm 7 (protokolsüz ilerleme: yalnız gösterim alanları, geçerlilik bayrağıyla). Kullanıcı 2026-11-16'da alanların tasarımdaki ad ve birimlerle eklenmesini onayladı.

**Kapsam dışı (sonraki adaylar):** 3B görünüm alanı, Board info/MCU/bootloader/boot bridge kartları, firmware güncelleme, BIT. Bunlar kimlik verisi ve komut gerektirir.

## Kararlar
- **Yeni `DeviceSample` alanları:**
  - Açılar (derece): `panDeg`, `panRefDeg`, `tiltDeg`, `tiltRefDeg`.
  - Sıcaklık (°C): `gimbalTempC`, `imuTempC`.
  - Besleme gerilimi (V): `supplyVoltageV`.
  - `safeControlLocked` (`Flag`).
  - Eski `angleDeg` → `panDeg`, `temperatureC` → `gimbalTempC` olur.
  - **Shortcut:** Ad, birim ve ölçek tasarımdan tahmin edildi; protokol gelince yeniden doğrulanır.
- **QML'e verilişi:** `Measurement` ve `Flag`, `Q_GADGET` ile; `device/presentation/DeviceValueTypes.h` bunları QML değer tipi (`measurement`, `flag`) olarak kaydeder. Model yalnız gadget özellikleri sunar (`pan.valid`, `pan.value`); özellik başına ayrı değer/bayrak çifti tutulmaz.
- **"NORMAL" rozetleri gösterilmez:** Sıcaklık ve gerilim sınırları bilinmiyor; sınır uydurulmaz.
- **Safe control:** `true` → "Locked" (tasarımdaki gibi uyarı noktası), `false` → "Unlocked". Anlamı protokolle doğrulanacak.
- **Sayfa kaydı:** Gimbal info "Board" grubunda ilk sayfadır; iki hedefte de açılış sayfası olur.

## Görevler
1. Sözleşme ve model:
   - `DeviceTypes.h` gadget'ları ve yeni alanlar.
   - `DeviceValueTypes.h`.
   - `DeviceViewModel` özellikleri: `pan`, `panRef`, `tilt`, `tiltRef`, `gimbalTemp`, `imuTemp`, `supplyVoltage`, `safeControl`.
   - Geçersizleştirme bütün alanları kapsar.
2. `DemoProvider` bütün alanları üretir (deterministik). Sıcaklıkların 40–49 aralığındaki geçersizlik senaryosu korunur.
3. Taslaktan alınacaklar: `CardBackground`, `StatStrip`, `StatCell`, `ArcGauge` (`CurveRenderer`). Yeni sayfa `features/gimbalinfo/GimbalInfoPage.qml`. Diagnostics yeni alan adlarına geçer.
4. Testler:
   - C++: güncellenen testler; yeni oturum ve bayatlıkta **bütün** alanlar geçersiz olur; demo alanları geçerli aralıkta.
   - QML (`tst_gimbalinfo.qml`): değerler ve radyan dönüşümü görünür, bağlantı kesilince "—" olur.
   - `tst_shell.qml` yeni sayfa sırasına göre güncellenir.
5. Doğrulama: derleme, lint uyarısız, tüm CTest'ler, iki exe; ekran dışı görüntü kontrolü.
