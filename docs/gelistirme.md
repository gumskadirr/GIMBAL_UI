# Geliştirme notları

Ortam: Windows, Qt 6.12.0 MinGW 64-bit, CMake + Ninja, derleme klasörü `build/cli-debug`. Komutlar Git Bash'te, proje kökünden (`IDS_GIMBAL/`) çalıştırılır.

```bash
export PATH="/c/Qt/6.12.0/mingw_64/bin:/c/Qt/Tools/mingw1310_64/bin:/c/Qt/Tools/CMake_64/bin:/c/Qt/Tools/Ninja:$PATH"
```

## Derleme, lint, test

```bash
cmake --build build/cli-debug
cmake --build build/cli-debug --target all_qmllint > build/lint.txt; grep -cE '^(Warning|Error)' build/lint.txt   # 0 olmalı
QT_QPA_PLATFORM=offscreen ctest --test-dir build/cli-debug --output-on-failure
QT_QPA_PLATFORM=offscreen ./build/cli-debug/tst_qml.exe -o build/q.txt,txt   # QML alt testlerinin ayrıntısı
```

- **Lint uyarıda da 0 çıkış koduyla biter.** Bu yüzden uyarılar satır sayısıyla kontrol edilir.
- **Derleme klasörü yoksa:** `cmake -S . -B build/cli-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug`.
- **Uygulama denetimi (PowerShell):**
  1. `appIDS_GIMBAL.exe` ve `appIDS_GIMBALDemo.exe` başlatılır.
  2. 3 saniye beklenir, `CloseMainWindow()` ile kapatılır.
  3. Çıkış kodu 0 olmalı, stderr boş olmalı.

## Çeviri

1. `cmake --build build/cli-debug --target update_translations`. Yeni metinler `.ts` dosyasına "unfinished" olarak eklenir. Bağlamı değişen metinlerin eski çevirisi lupdate tarafından önceden doldurulur; bunları kontrol edin.
2. Yeni metinler için `{"English": "Türkçe"}` biçiminde bir JSON yazılır, ardından `python tools/fill_ts.py yeni.json` çalıştırılır. Betik "unfinished" kayıtları doldurur, "vanished" kayıtları siler.
3. `translations_complete` testi eksik çeviri kalmadığını doğrular.

**Kurallar:**
- Türkçe metin düğmeye sığmalı. Sığmıyorsa kısa bir karşılık seçilir; ör. "Kalibrasyonu başlat".
- Sayılar `NumberFormat` ile gösterilir; Türkçede ondalık virgül kullanılır.

## Tasarımla karşılaştırma (ekran görüntüsü)

1. `tools/shot/tst_shot.qml` içindeki `test_shots()` üzerinde çalışılan sayfaya göre düzenlenir: boyut, tema, dil, sayfa kimliği.
2. `QT_QPA_PLATFORM=offscreen ./build/cli-debug/tst_qml.exe -input tools/shot/tst_shot.qml` çalıştırılır.
3. Görüntüler `build/shots/` klasörüne yazılır ve tasarımdaki ekranla yan yana karşılaştırılır.

Önerilen boyutlar: 1536×786 (hedef ekran) koyu/en ve açık/tr; 1920×1050.

**Tasarım ekranları:**
- `../taslak/IDS Main control service · Info, Control, Settings.pdf` içinde 10 gömülü JPEG var. `/DCTDecode` akışları `.jpg` olarak yazılır, PowerShell `System.Drawing` ile ~1800 px'e küçültülür.
- Sıra `docs/plan.md` "Tasarım kaynağı" bölümünde.

## Çalışma kuralları (kullanıcı kararları)

- **Tasarım yerleşimi kesindir.** Kartların yeri ve sırası onaysız değiştirilmez. Bütün sayfalar en uzun sayfanın `designHeight` değerine göre aynı oranla küçültülür, hiç büyütülmez.
- **Protokolsüz ilerleme:** Değerler `valid` bayrağı taşır; veri yoksa "—" gösterilir. Uydurma veri yalnız demo ve test sağlayıcısında bulunur.
- **İki hizmet:** Main control (UART ya da UDP) ve IDS Image (UDP) aynı anda bağlı olabilir. Yalnız görünen sayfa ekranı günceller. Model seçimi ve TCP yok.
- **Git akışı:** Her iş kendi dalında yapılır, `main`'e fast-forward birleştirilir. Kayıt mesajları Türkçedir.
- **Yanıt dili:** Türkçe.
