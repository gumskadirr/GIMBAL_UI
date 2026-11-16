# Adım 7b — Gimbal info orta bölümü

**Hedef:** Tasarımdaki 3B alanı ile Board info, MCU, Bootloader ve Boot bridge bölümlerini, cihaz sözleşmesine alan eklemeden göstermek.

**Dayanak:** `../gimbal-nihai-mimari-v1.1.md` Bölüm 7. Kimlik ve durum verisi uydurulmaz; protokol yokken komut gönderilmez.

## Kararlar
- Değerler "—" olarak görünür. Kimlik alanları büyük olasılıkla ayrı bir okuma komutuyla gelecek; bu yüzden `DeviceSample`'a eklenmez.
- Komut düğmeleri devre dışıdır. Sayfada tek bir açıklama satırı neden kapalı olduklarını söyler.
- Tasarımdan alınmayanlar:
  - "Reset view": sıfırlanacak 3B görünüm yok.
  - Boot bridge hedef listesi: alt kart listesi protokolden gelecek.
- Önyükleyici düğmeleri alt alta dizilir; Türkçe etiketler yan yana sığmıyor.

## Yapılanlar
- Taslaktan alınan bileşenler: `Card`, `KpiTile`, `InfoRow`, `Zone`, `Hint`, `FormField`, `VideoViewport`.
- Test: `tst_gimbalinfo.qml` içinde `test_commandsDisabledWithoutProtocol`.
- Doğrulama: derleme, lint uyarısız, 9/9 CTest, iki uygulama, 1280 px'de ekran dışı görüntü (koyu/İngilizce ve açık/Türkçe).

## Sonraki aday (kesin değil)
- 7c: Firmware update ve Built-in test (BIT) kartları; komutlar devre dışı.
