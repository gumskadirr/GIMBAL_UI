# Adım 9 — Main control sayfa şablonu

**Hedef:** Main control service sayfalarının ortak çerçevesini (özet şeridi + soldaki 3B kartı + sağdaki içerik sütunu) tek bileşene çıkarmak. Böylece Motor control, Gimbal settings ve Heater aynı çerçeveyi ve aynı sığdırma kuralını hazır alır.

**Dayanak:**
- Tasarım PDF'inin 1–4. ve 7. sayfaları: aynı şerit ve aynı 3B kartı her ekranda var.
- `../gimbal-nihai-mimari-v1.1.md` Bölüm 11.

## Kararlar
- **`features/maincontrol/ControlPageFrame.qml`:**
  - Özet şeridi, 3B kartı ve taşma için kaydırma bu bileşende.
  - Sayfa içeriği varsayılan `content` özelliğiyle sağ sütuna yerleşir.
  - `viewModel` gerektirir.
- **Gimbal info** `features/maincontrol/GimbalInfoPage.qml` olur. Kökü `ControlPageFrame`'dir ve yalnız sağ taraf içeriğini tanımlar.
- **Görünüm değişmez:** yerleşim ve `designHeight` (768) aynı kalır.
- **Konum:** Çerçeve cihaz verisine (`DeviceViewModel`) bağlı olduğu için `shared/ui` altına değil, Main control özellik grubuna konur.

## Test
Mevcut testler yeterli:
- `tst_gimbalinfo`: şerit değerleri ve kapalı komutlar.
- `tst_shell`: dört ekran boyutunda sığma.

## Doğrulama
- Derleme, lint uyarısız, tüm CTest'ler.
- 1536×786'da ekran dışı görüntü, Adım 8b ile aynı olmalı.
