# Adım 7c — Firmware update ve Built-in test kartları

**Hedef:** Gimbal info sayfasını tasarımdaki son iki kartla tamamlamak; komut göndermeden, veri uydurmadan.

**Dayanak:** `../gimbal-nihai-mimari-v1.1.md` Bölüm 7. Kaynak: tasarım PDF'indeki Gimbal info ekranı.

## Kararlar
- **Firmware update kartı:**
  - Başlık altında "Board firmware —" ile "GUI version" bilgisi bulunur. GUI version gerçek bir değerdir: CMake `PROJECT_VERSION` → `QCoreApplication::applicationVersion`.
  - "Open file" ve "Update firmware" devre dışıdır; dosya durumu "No file selected" olarak görünür.
  - Çalışan güncelleme olmadığından ilerleme çubuğu ve Cancel eklenmez.
- **Built-in test kartı:**
  - "Run BIT" devre dışıdır; kart "No result" durumunu gösterir.
  - Tasarımdaki test listesi cihazın BIT raporundan gelecek; kutucuklar ve sayaç rozetleri eklenmez (`TestResultTile` alınmaz).
- **Kaydırma:** İçerik 800 px yüksekliğe sığmayacağı için sayfa bir `Flickable` içine alınır ve dikey kaydırma çubuğu eklenir. Yer varsa 3B alan yine kalan yüksekliği doldurur.

## Görevler
1. `GimbalInfoPage.qml`: kaydırma ve iki kart. Komut düğmelerinin `objectName` değerleri `command-openFirmware`, `command-updateFirmware`, `command-runBit`.
2. `CMakeLists.txt` + `AppRunner.cpp`: uygulama sürümü.
3. Test: `test_commandsDisabledWithoutProtocol` yeni düğmeleri de kapsar.
4. Doğrulama: derleme, lint uyarısız, tüm CTest'ler, iki uygulama, 1280×800'de ekran dışı görüntü (en üst ve en alt kaydırma konumu).
