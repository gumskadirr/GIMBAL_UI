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
- **`-j 2`:** geliştirme bilgisayarında daha fazla paralel derleme belleği bitirdi.
- **Tek bir QML test dosyası:** `QT_QPA_PLATFORM=offscreen ./build/cli-debug/tst_qml.exe -input test/qml/tst_gimbal3d.qml`.
- **QML testleri ve derleme:** test dosyaları (`test/qml`) kaynaktan okunur. Uygulama modülündeki QML ise (`app/`, `features/`, `shared/`) derlenir. Bu yüzden onlarda yapılan değişiklikten sonra yeniden derlemeden test etmek eski kodu sınar.

### Birleştirmeden önce: `tools/verify.sh`

`bash tools/verify.sh` sırayla şunları yapar ve sonucu yazar:
1. Derler (`build rc=0`).
2. Lint uyarılarını sayar (`lint=0` olmalı).
3. Bütün ctest testlerini çalıştırır.
4. İki uygulamayı açıp 3 saniye sonra kapatır (`tools/appcheck.ps1`). Beklenen: `alive3s=True exit=0 stderr=[]`.

Qt başka bir yerdeyse: `QT_ROOT=/d/Qt bash tools/verify.sh`.

## Demo uygulaması

`appIDS_GIMBALDemo.exe`, cihaz yerine `test/doubles/` sağlayıcılarıyla çalışır ve kapatılana kadar örnek telemetri gönderir.
- Pan ±150° arasında yaklaşık 5 saniyede bir gidip gelir; tilt daha yavaş salınır.
- Komutlar kısa bir gecikmeyle kabul edilir.
- Demonun ayarları ve gimbal listesi gerçek uygulamadan ayrıdır (`mimari.md` "Ayar ve veri konumları").

## Çeviri

1. `cmake --build build/cli-debug --target update_translations`. Yeni metinler `.ts` dosyasına "unfinished" olarak eklenir. Bağlamı değişen metinlerin eski çevirisi lupdate tarafından önceden doldurulur; bunları kontrol edin.
2. Yeni metinler için `{"English": "Türkçe"}` biçiminde bir JSON yazılır, ardından `python tools/fill_ts.py yeni.json` çalıştırılır. Betik "unfinished" kayıtları doldurur, "vanished" kayıtları siler.
3. `translations_complete` testi eksik çeviri kalmadığını doğrular.

**Kurallar:**
- Türkçe metin düğmeye sığmalı. Sığmıyorsa kısa bir karşılık seçilir; ör. "Kalibrasyonu başlat".
- Sayılar `NumberFormat` ile gösterilir; Türkçede ondalık virgül kullanılır.

## Tasarımla karşılaştırma (ekran görüntüsü)

1. `tools/shot/tst_shot.qml` içindeki işlevler düzenlenir. Her `shot()` çağrısı bir boyut, tema, dil, sayfa ve isteğe bağlı açık pencere alır.
   - `test_shots()`: bütün sayfalar.
   - `test_gimbalShots()`: gimbal seçimi ve bağlantı paneli.
   - `test_gimbal3dShots()`: 3B görünüm ve gimbal düzenleme penceresi.
2. Araç çalıştırılır, örneğin `QT_QPA_PLATFORM=offscreen ./build/cli-debug/tst_qml.exe -input tools/shot/tst_shot.qml Shot::test_shots`.
3. **3B görüntüler için `QT_QPA_PLATFORM=windows` gerekir.** Offscreen ortam yazılım çizicidir ve Qt Quick 3D orada çizmez. Bu çalıştırmada ekranda kısa süre pencereler açılıp kapanır.
4. Görüntüler `build/shots/` klasörüne yazılır ve tasarımdaki ekranla yan yana karşılaştırılır.

Önerilen boyutlar: 1536×786 (hedef ekran) koyu/en ve açık/tr; 1920×1050.

**Tasarım ekranları:**
- `../taslak/IDS Main control service · Info, Control, Settings.pdf` içinde 10 gömülü JPEG var. `/DCTDecode` akışları `.jpg` olarak yazılır, PowerShell `System.Drawing` ile ~1800 px'e küçültülür.
- Sıra `docs/plan.md` "Tasarım kaynağı" bölümünde.

## Yeni gimbal modeli

Kod değişikliği gerekmez:
1. CAD'den üç parça `.glb` olarak dışa aktarılır: taban (sabit), pan parçası ve tilt parçası.
2. Uygulamada üst çubuktaki gimbal düğmesi → "+ Yeni gimbal" (ya da var olan kartta ✎).
3. Ad, sürümler ve üç dosya girilir. Ardından pan ve tilt ekseni (X/Y/Z), yönü ve merkezi girilir.
   - Parçalar montajdaki yerlerinde dışa aktarıldıysa "Parçalar montaj konumunda" açık kalır; merkezler montajdaki eksen noktalarıdır.
   - Önizlemedeki kaydırıcılarla eksenlerin doğru döndüğü denetlenir.
4. Dosyalar uygulamanın veri klasörüne kopyalanır. Kaynak sonradan taşınabilir.

Uygulamayla gelen varsayılan listeyi değiştirmek için `shared/settings/GimbalLibrary.cpp` içindeki `seedDefaults()` düzenlenir. Varsayılan liste yalnız `gimbals.json` dosyası olmayan kurulumlarda yazılır. Hazır gelen model dosyaları `features/gimbal3d/<id>/` altına konur ve `CMakeLists.txt` içindeki `RESOURCES` listesine eklenir.

## Çalışma kuralları (kullanıcı kararları)

- **Tasarım yerleşimi kesindir.** Kartların yeri ve sırası onaysız değiştirilmez. Bütün sayfalar en uzun sayfanın `designHeight` değerine göre aynı oranla küçültülür, hiç büyütülmez.
- **Protokolsüz ilerleme:** Değerler `valid` bayrağı taşır; veri yoksa "—" gösterilir. Uydurma veri yalnız demo ve test sağlayıcısında bulunur.
- **İki hizmet:** Main control (UART ya da UDP) ve IDS Image (UDP) aynı anda bağlı olabilir. Yalnız görünen sayfa ekranı günceller. Model seçimi ve TCP yok.
- **Git akışı:** Her iş kendi dalında (`gorev/…`) yapılır. `tools/verify.sh` temiz çıktıktan sonra `main`'e fast-forward ile birleştirilir. Kayıt mesajları Türkçedir.
- **Kararlar:** her karar tarihiyle `docs/kararlar.md`'ye yazılır.
- **Yanıt dili:** Türkçe.
