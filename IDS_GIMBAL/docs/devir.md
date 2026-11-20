# Devir belgesi (20 Kasım 2026)

Projeyi devralan kişi için başlangıç noktası. Önce bunu, sonra [`gelistirme.md`](gelistirme.md) ve [`mimari.md`](mimari.md)'yi okuyun.

## 1. Proje nedir

IDS Gimbal, pan-tilt gimbal'ları ayarlamak, izlemek ve sınamak için bir masaüstü uygulamasıdır. Qt 6.12 ile yazıldı (QML + C++) ve Windows'ta geliştirildi; Linux hedefi henüz konuşulmadı. İki cihaz hizmetine aynı anda bağlanır: Main control (UART ya da UDP) ve IDS Image (UDP).

Görsel tasarım kesindir. Kaynağı depo dışında: `../taslak/` ve `../ui_notlar.pdf`. Kart yerleşimi tasarıma bağlıdır; değiştirmeden önce proje sahibine sorulur.

## 2. Bugünkü durum

| Alan | Durum |
|---|---|
| Uygulama çerçevesi | Bitti. Sol menü, üst çubuk, durum çubuğu (TX/RX, veri hızı, heartbeat, çalışma süresi, BIT, süren işlem, bağlantı, bildirim, Debug), ortak sayfa ölçeği |
| Tema, dil | Bitti. Koyu, açık ve mavi tema; Türkçe/İngilizce anında geçiş; Türkçede ondalık virgül |
| Main control sayfaları | Arayüz bitti: Gimbal info, Motor control, Gimbal settings (scope grafiği, script, kalibrasyonlar), Heater |
| IDS Image sayfaları | Arayüz bitti: View & control, Alignment, Errors, Gimbal state. Video yalnız yer tutucu |
| Parametreler | Bitti (arayüz + demo): okuma, yazma, flash'a kaydetme, varsayılanlar, profil dosyası |
| Kayıt ve grafik | Elle CSV kaydı, 2 sn'lik grafik tamponu, gerçek zamanlı grafik penceresi bitti. 2 kHz otomatik kayıt yapılmadı |
| Bağlantılar | Bitti. Seri/UDP açma, hizmet başına ayar saklama, açılışta bağlanma, üst çubukta iki hizmetin bağlantı paneli |
| Gimbal seçimi ve 3B | Bitti. Gimbal kütüphanesi (ekle, düzenle, sil), `.glb` dosyalarından 3B model, telemetriyle dönen pan/tilt. Hazır model yalnız ZR10 |
| **Cihaz protokolü** | **Yapılmadı.** Gerçek uygulama bağlantıyı açar ama baytları çözmez, komut göndermez: değerler "—", düğmeler kapalı |
| Paketleme / kurulum | Yapılmadı |
| Testler | 20 ctest kaydı (C++ birim testleri, QML testleri, çeviri ve belge denetimi); QML tarafında 189 alt test. Hepsi geçiyor, qmllint 0 uyarı |

Demo uygulaması (`appIDS_GIMBALDemo`) bütün özellikleri örnek veriyle gösterir. Ekranda "Örnek veri" rozeti görünür.

## 3. İlk gün

1. Qt 6.12.0 MinGW 64-bit'i kurun. Qt Quick 3D ve Qt Serial Port modülleri de seçilmeli. Ardından [`README.md`](../README.md)'deki "Hızlı başlangıç" adımlarını izleyin.
2. `bash tools/verify.sh` çalıştırın. Beklenen çıktı:
   ```text
   build rc=0
   lint=0
   100% tests passed, 0 tests failed out of 20
   appIDS_GIMBAL.exe alive3s=True exit=0 stderr=[]
   appIDS_GIMBALDemo.exe alive3s=True exit=0 stderr=[]
   ```
3. Demoyu açın, sayfaları gezin. Üst çubuktaki gimbal düğmesinden ZR10'u seçin; 3B model telemetriyle döner.

## 4. Kalan işler (önerilen sıra)

1. **Gerçek protokol.** En büyük ve en önemli iş.
   - Sözleşme hazır: [`protokol-siniri.md`](protokol-siniri.md). Her komut, her okunan alan, her parametre anahtarı ve beklenen testler orada.
   - Protokol `device/transport/TransportProvider` içine (ya da onun kullandığı yeni bir katmana) yazılır. `supportsCommands()` true döndüğünde komut düğmeleri kendiliğinden açılır.
   - QML sayfaları değişmez.
   - Parçalı, bozuk ve sıra dışı paket testleri gerekir; demo sağlayıcıları protokolü sınamaz.
2. **Geçici değerlerin doğrulanması.** Protokol belgesi gelince tasarımdan alınan alan adları, birimler, ölçekler, aralıklar ve seçenek listeleri denetlenir. Liste: `protokol-siniri.md`'nin sonu ve `kararlar.md`. Kodda `shortcut:` ile işaretli yerler de bunlardandır (aşağıda 6. bölüm).
3. **Paketleme.**
   - `windeployqt` ile dağıtım klasörü hazırlanır. Qt Quick 3D ve `QtQuick3D.AssetUtils` eklentileri, Serial Port ve Inter / JetBrains Mono fontları pakete girmeli (fontlar kaynakta gömülü).
   - Demo uygulaması üretim paketine girmez.
   - CMake'te `install(TARGETS appIDS_GIMBAL)` var, dağıtım betiği yok.
4. **2 kHz otomatik telemetri kaydı.** Sözleşme mimari belgede (`mimari-gerekce-v1.2.md` §14); gerçek veri akışına bağlı.
5. **Gerçek gimbal modelleri.** G160, G180 ve Kashif700 için taban, pan ve tilt parçaları `.glb` olarak dışa aktarılıp uygulamanın gimbal penceresinden eklenir. ZR10'un tilt yönü (aşağı negatif) gerçek cihazla doğrulanmalı. Ters çıkarsa düzenleme penceresinden tilt yönü çevrilir.
6. **Video.** RTSP adresi saklanıyor ama video çözülmüyor. Codec ve protokol konuşulacak.
7. **Linux.** Hedef dağıtım ve ortam henüz konuşulmadı.

## 5. Onay bekleyen kararlar

- **Yazı boyutu / sayfa ölçeği.** Bütün sayfalar en uzun sayfaya göre aynı oranla küçülüyor: 1536×786 ekranda ~%70, 1366×768'de ~%61. Bu yüzden yazılar küçük. Büyütmek için en uzun sayfaların (View & control, Motor control, Gimbal info) sıkıştırılması gerekir; bu da kart yerleşimini değiştirir.
- **Tasarımdan sapmalar.** Proje sahibinin onayı alınmalı:
  - Durum çubuğundaki bildirim zili. Tasarımda yok; hataların görünür kalması için eklendi.
  - Üst çubuktaki bağlantı rozeti iki hizmeti özetliyor ve tıklanınca bağlantı paneli açıyor. Tasarımda yalnız "Connected" yazısı var.
  - Gimbal seçim penceresinde düzenle, sil ve yeni gimbal eklendi. Tasarımda yok; kullanıcı isteğiyle eklendi.
- **Onay penceresi kapsamı.** Planın listesine ek olarak Write offset ve IP Set de onay istiyor. Safe stop onaysız.

## 6. Bilinen eksikler ve sınırlar

**Arayüz:**
- Modal pencerelerin arkasında karartma yok; projenin hiçbir yerinde yok.
- Dosya seçme pencereleri (`FileDialog`) otomatik testlerde açılamıyor; testler dosyayı doğrudan veriyor. Elle de az denendi.
- Pencere ~1100 px'ten darsa üstteki özet çubuğunun hücreleri kırpılıyor.
- Türkçe yazı tipinde rakamlar eşit genişlikte değil: sıcaklık ve gerilim gibi değerler değişince hücre içindeki yazı bir iki piksel oynar.
- Ayrıntılı küçük görsel farklar için bkz. `sabah-raporu.md` "Bilinen küçük eksikler".

**3B görünüm:**
- Telemetri saniyede 10 örnekle geldiğinde (demo) hızlı pan hareketi kesik kesik görünür. Açılar örnekler arasında yumuşatılmıyor.
- `RuntimeLoader` parça ölçülerini değiştiğinde bildirmiyor. Bu yüzden kamera, ölçüler gelene kadar 100 ms aralıkla kontrol ediyor; 2 sn içinde gelmezse eldeki parçalarla yerleşiyor.
- Gizliyken kurulan `View3D` modeli sonradan bozuk çiziyordu. Bu yüzden görünüm yalnız görünürken kuruluyor.
- Penceresiz (offscreen) testlerde 3B çizilemiyor. Açılar ve model seçimi testli; 3B'nin görüntüsü yalnız `QT_QPA_PLATFORM=windows` ile alınan ekran görüntülerinde denetleniyor.
- Yalnız `.glb` dosyası kabul ediliyor. `.gltf` ayrı dosyalarıyla kopyalanamıyor.
- Montaj konumunda dışa aktarılmış (`inPlace`) gerçek bir CAD modeliyle henüz denenmedi.

**Testler:**
- `tst_shellexit` testi `tst_gimbalsettings`'ten sonra çalışmak zorunda; testin içinde not var.

**Kodda `shortcut:` ile işaretli bilinçli kısayollar** (`grep -rn "shortcut:"` ile listelenir):
- `device/api/DeviceTypes.h`, `ParameterKeys.h`: alan adları, birimler ve aralıklar tasarımdan alındı.
- `features/maincontrol/GimbalSettingsPage.qml`: grafik Y aralıkları sabit.
- `device/presentation/SeriesBuffer.h`: örneklerde cihaz zamanı yok, varış zamanı kullanılıyor.
- `features/telemetry/ScriptFile.h`, `ScriptRunner.cpp`: dosya bütünüyle bellekte tutuluyor; oynatıcı 1 ms aralıkla yokluyor.
- `device/transport/TransportProvider.h`: kapatma eşzamanlı.
- `shared/ui/StatCell.qml`: dar pencerede hücreler kırpılıyor.

## 7. Çalışma biçimi

- Her iş kendi dalında (`gorev/…`) yapılır. `tools/verify.sh` temiz çıktıktan sonra `main`'e fast-forward ile birleştirilir.
- Her karar tarihiyle `docs/kararlar.md`'ye yazılır.
- Arayüz metinleri İngilizce kaynak + Türkçe çeviridir (`gelistirme.md` "Çeviri"). Kod yorumları İngilizce, belgeler ve commit mesajları Türkçe.
- Tasarımda olmayan bir değer uydurulmaz: veri yoksa "—". Tahmin gerekiyorsa `kararlar.md`'ye geçici olarak yazılır.

## 8. Depo dışındaki dosyalar

`IDS_GIMBAL_UI/` klasöründe, deponun yanında:
- `taslak/`: tasarım (PDF ve HTML ekranlar).
- `ui_notlar.pdf`: arayüz notları.
- `3D/`: ZR10'un SolidWorks montajı ve dışa aktarılmış `.glb` / `.mesh` dosyaları.
- `ZR10_3D/`: 3B görünümün ilk örnek projesi.
- `gimbal-nihai-mimari-v1.0…v1.2.md`: mimari belgenin sürümleri. v1.2 depoya `docs/mimari-gerekce-v1.2.md` olarak kopyalandı.

Devrederken bu klasör de verilmeli. En azından `taslak/` ve `3D/` gerekli.
