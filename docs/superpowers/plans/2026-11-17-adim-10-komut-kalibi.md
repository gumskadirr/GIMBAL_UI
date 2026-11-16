# Adım 10 — Komut kalıbı

**Hedef:** Cihaza komut gönderen bütün düğmeleri tek bir "komut gönderilebilir mi" bilgisine bağlamak.

**Dayanak:**
- `../gimbal-nihai-mimari-v1.1.md` Bölüm 7: protokol yokken komut yok.
- Bölüm 12: bağlantı kapanınca komut kabulü durur.

## Kararlar
- `DeviceViewModel.commandsAvailable` (bool, `connectionChanged` ile bildirilir).
  - Şimdilik her zaman `false`.
  - Protokol/taşıma eklendiğinde "bağlı + protokol hazır" olur. Kodda `shortcut:` notu var.
- Gimbal info'daki komut düğmeleri ve Boot bridge hedef listesi `enabled: page.viewModel.commandsAvailable` ile bağlanır.
- Tehlikeli komutlar için onay penceresi bu adımda **yapılmaz**: açılabilen bir komut yok, pencere test edilemez. İlk komutla birlikte gelir.

## Test
- `tst_deviceviewmodel`: bağlıyken bile `commandsAvailable == false`.
- `tst_gimbalinfo`: komut düğmeleri kapalı (mevcut test).
