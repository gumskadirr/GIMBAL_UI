# Plan — frontend'in protokolden bağımsız tamamlanması (18 Kasım 2026)

Dayanak: `docs/inceleme.md`, Mimari v1.1, kullanıcı kararları. Kararlar `docs/kararlar.md`'ye yazılır.

## Tasarım kaynağı (kesin; her sayfa görevi önce buna bakar)
`../taslak/` (Mimari §9):
- `IDS Main control service · Info, Control, Settings – IDS Image · Gimbal state.html`: 10 ekranlık paket. Tarayıcıda açıp ekran ekran incelenir. Metinler paketin `__bundler/template` bölümünden de çıkarılabilir.

  | Ekran | Görev |
  |---|---|
  | Gimbal info | T7 |
  | Motor control | T8 |
  | Gimbal settings (iki görünüm; ikincisinde Script paneli açık) | T10–T13 |
  | Heater | T9 |
  | View & control | T17 |
  | Alignment | T18 |
  | Errors | T19 |
  | Gimbal state | T20 |
  | Select a gimbal (IDS Operator) | Kapsam dışı (17 Kasım) |

  Durum çubuğu (T14) ve üst çubuk bütün ekranlarda ortaktır.
- `IDS Main control service · Info, Control, Settings.pdf` ve `ui örnek/Main Control Service(light).pdf`: Main control ekranlarının basılı hali, açık tema için başvuru.
- `files/ids-qml/IdsUi/`: Alınacak hazır QML bileşenleri. Yalnız gerekenler `shared/ui/`'ye kopyalanır; IDS Image için örneğin `OverlayTag`, `Led`, `ChoiceChip`, `TestResultTile`.
- `ui örnek/*.jpeg`: Eski uygulama ekranları; görsel için değil, işlev kapsamı için.
- **Ekran görüntüsü çıkarma:**
  - Bu bilgisayarda PDF çizici yok.
  - PDF'teki 10 sayfa gömülü JPEG'dir (5760×3240). `/Subtype /Image … /DCTDecode` akışları doğrudan `.jpg` olarak yazılır, PowerShell `System.Drawing` ile ~1800 px'e küçültülür.
  - Sayfa sırası: Gimbal info, Motor control, Gimbal settings, Heater, View & control, Select a gimbal, Gimbal settings (Script açık), Alignment, Errors, Gimbal state.
- **Bütün ekranlarda ortak çerçeve** (18 Kasım görsel incelemesi):
  - **Sol menü:**
    - Her hizmetin kendi logo/durum noktası vardır: Main control üstte, IDS Image ortada.
    - Gruplar çizgiyle ayrılır.
    - IDS Image ikonları: eye, target, warning, list.
  - **Üst çubuk:** Breadcrumb, "Realtime graph and logger" düğmesi, tema seçici (light / blue / dark), bağlantı rozeti, "GIMBAL G180 · v2.0" model düğmesi. Model düğmesi kapsam dışı (17 Kasım).
  - **Durum çubuğu:** TX/RX/HEARTBEAT ışıkları (`Led`), veri hızı, ON TIME, BIT rozeti ve son mesaj, saat, süren işlem ve ilerlemesi, bağlantı düğmesi ve en sağda böcek ikonlu "Debug settings" düğmesi.

## Her görev için geçerli kurallar
- Görev kendi dalında (`gorev/Tnn-...`) yapılır, `main`'e fast-forward birleştirilir ve burada `[x]` ile işaretlenir.
- **Bitti için ortak ölçüt:**
  - Derleme hatasız.
  - qmllint 0 uyarı.
  - Bütün CTest testleri geçer; çeviri bütünlüğü testi de dahil (yeni metinler TR'ye çevrilir).
  - İki uygulama açılıp hatasız kapanır.
- **Protokol mantığı yazılmaz.** Gerçek sağlayıcı bayt çözmez ve komut kodlamaz. Bütün davranış arayüz, demo veya sahte sağlayıcı üzerinden gelir.
- **Tasarım yerleşimi değişmez** (kartların yeri ve sırası). Sığmayan sayfa `designHeight` ile ölçeklenir.
- **Takılınırsa** görev atlanır, nedeni bu dosyada görevin altına yazılır ve sıradakine geçilir.
- **Tasarımla karşılaştırma:** Her sayfa görevinin sonunda sayfa ekran dışında çizdirilir (`grabWindow`) ve tasarımdaki ekranla yan yana karşılaştırılır. Farklar düzeltilir ya da gerekçesiyle `kararlar.md`'ye yazılır.
- **Her giriş alanında:**
  - Birimi ve aralığı doğrulanır; tasarımda yazan aralıklar kullanılır, ör. "Range -180.000 to 180.000".
  - Geçersiz değer gönderilemez.
  - Tasarım öyle diyorsa Enter değeri gönderir.
- **Her komut düğmesi:**
  - Komut beklerken meşgul görünür ve tekrar basılamaz.
  - Başarısız sonuç bildirime düşer.
- **Yeni kontroller** erişilebilir ad (`Accessible.name`) taşır ve klavyeyle odaklanır.

---

## A. Toparlama

- [x] **T1 — Eski yorum ve belgelerin güncellenmesi**
  - **Amaç:** Koddaki ve mimarideki eskimiş ifadeleri gidermek; karar günlüğünü açmak.
  - **Dosyalar:**
    - `CMakeLists.txt`: gerçek hedef yorumu.
    - `../gimbal-nihai-mimari-v1.1.md`: §2, §6, §8, §12 ve §15.1'de eski taşıma ve "UART" ifadeleri; §1 ve §16'ya "18 Kasım: tek onaylı plan" notu.
    - `docs/kararlar.md` (yeni).
  - **Bitti:** "no device transport yet" ve "bağlantısız sağlayıcı" ifadeleri koddan ve belgeden kalkmış.

- [x] **T2 — Diagnostics sayfasının kaldırılması**
  - **Amaç:** 1. aşamanın doğrulama sayfasını menüden kaldırmak. Oturum ayrıntıları (son örnek yaşı, düşen eski sonuç sayısı, hata ayrıntısı) T14'te durum çubuğundaki "Debug settings" penceresine taşınır.
  - **Dosyalar:**
    - `features/diagnostics/` (silinir).
    - `app/Main.qml`, `CMakeLists.txt`, `translations/IDS_GIMBAL_tr.ts`.
    - `test/qml/tst_shell.qml`: sayfa etkinliği testi Tercihler ↔ Gimbal info ile yapılır.
  - **Bitti:**
    - Demo menüsünde Diagnostics yok.
    - Sayfa etkinliği testi başka sayfayla geçiyor.

- [x] **T3 — Bağlantının sunum modelinden ayrılması**
  - **Amaç:** `DeviceViewModel` ikiye bölünür. Davranış değişmez.
    - `ServiceConnection`: hizmet başına; durum, özet, uygula, bağlan/kes, portlar, `commandsAvailable`.
    - `MainControlViewModel`: Main control verisi.
  - **Dosyalar:**
    - `device/presentation/ServiceConnection.{h,cpp}` (yeni).
    - `device/presentation/DeviceViewModel.*` → `MainControlViewModel.*`.
    - `app/AppRunner.*`, `app/Main.qml`, `features/maincontrol/*.qml`, `test/unit/tst_deviceviewmodel.cpp` (bölünür), `test/qml/*`.
  - **Bitti:** Bütün testler yeni adlarla geçiyor; QML'de bağlantı alanları `connection.*` üzerinden okunuyor.

- [x] **T4 — Hizmetlerin AppRunner'da listeyle kurulması**
  - **Amaç:** Oturum, bağlantı, kayıt ve açılışta bağlanma her hizmet için tek döngüde kurulur. İkinci hizmet kopya kod gerektirmez.
  - **Dosyalar:** `app/AppRunner.*`, `app/main.cpp`, `test/app/main.cpp`, `test/qml/tst_qml.cpp`.
  - **Bitti:** Main control davranışı ve testleri aynı; sağlayıcılar hizmet anahtarıyla veriliyor.

## B. Protokol sınırı (arayüz + mock)

- [x] **T5 — Komut sözleşmesi**
  - **Amaç:** Arayüzün komut gönderebileceği, protokolden bağımsız bir sınır kurmak.
  - **Sözleşme:**
    - `DeviceCommand { Kind; QVariantMap args }` ve `CommandResult { Accepted | Rejected | Failed | Cancelled | Unsupported; detail }`.
    - `IDeviceProvider::send()`, `supportsCommands()` ve `commandFinished` sinyali.
  - **Oturum ve bağlantı:**
    - `DeviceSession` bekleyen komutları tutar; bağlantı kapanınca bunları `Cancelled` ile bitirir (§12 kural 2).
    - `ServiceConnection.commandsAvailable = connected && supportsCommands`.
    - Başarısız sonuç bildirime düşer.
  - **Sağlayıcılar:**
    - `DemoProvider` her komutu gecikmeli kabul eder (mock).
    - `TransportProvider` değişmez; temel sınıfın `Unsupported` davranışını kullanır.
  - **Dosyalar:** `device/api/DeviceCommand.h` (yeni), `IDeviceProvider.h`, `DeviceSession.*`, `ServiceConnection.*`, `test/doubles/DemoProvider.*`, `test/unit/FakeProvider.h`, testler.
  - **Bitti:**
    - Testler şunları kanıtlıyor: bekleyen komut kopmada iptal ediliyor; eski oturumun sonucu düşüyor; demo hedefinde komutlar açık; gerçek hedefte kapalı.

- [x] **T6 — Parametre sözleşmesi ve modeli (§13)**
  - **Amaç:** Parametreler için protokolden bağımsız sözleşme ve model.
  - **Sözleşme:** Anahtar listesi (`device/api/ParameterKeys.h`), `parametersReceived(sessionId, QVariantMap)`, Read / Write / Save to flash / Defaults komutları.
  - **`ParameterModel`:** Üç durumu tutar (cihazdaki, düzenlenen, dosyadaki) ve "N unsaved changes" sayısını verir.
  - **Profil dosyası:** Sürüm alanlı JSON; kaydet ve yükle. Yükleme cihaza göndermez.
  - **Dosyalar:** `device/api/ParameterKeys.h`, `device/presentation/ParameterModel.{h,cpp}`, `DemoProvider`, testler.
  - **Bitti:** Testler düzenleme sayısını, geri almayı, dosya gidiş-dönüşünü ve bozuk dosyanın reddini doğruluyor.

## C. Main control — eksik frontend

- [x] **T7 — Gimbal info bağlantıları**
  - **Amaç:** Gimbal info'daki eksik değer ve komutları bağlamak.
    - On time (telemetri).
    - BIT listesi ve özeti (istekle okunan `BitReport`).
    - Önyükleyici durumu.
    - Ask/Exit bootloader, Boot bridge, Run BIT komutları.
    - Firmware update kartı:
      - "Current vX · GUI version Y" satırı; GUI sürümü uygulamadan gelir.
      - Dosya kutusu: ad, boyut, klasör.
      - Open file (`QtQuick.Dialogs`).
      - Durum metni, ilerleme yüzdesi.
      - Cancel ve Update firmware; güncelleme mock.
    - BIT kartı: "N PASSED / N WARNING" rozetleri, "Last run …" satırı, 8 kutucuk (ad, Pass/Warning/Fail, açıklama).
    - FIRMWARE ve ON TIME kutucuklarının alt satırları: "Built …", "N s since power on".
  - **Dosyalar:** `DeviceTypes.h`, `MainControlViewModel.*`, `GimbalInfoPage.qml`, `DemoProvider`, testler.
  - **Bitti:** Demo'da tasarımdaki değerler görünüyor; gerçek hedefte "—" ve kapalı düğmeler.

- [x] **T8 — Motor control bağlantıları**
  - **Amaç:** Motor control'ü parametre modeline ve komutlara bağlamak.
    - Pan/Tilt parametreleri `ParameterModel`'e bağlanır; "N UNSAVED CHANGES" gösterilir.
    - Read / Write / Save to flash / Defaults.
    - Kontrol modu, latch, Start/Stop control ve referans gönderimi (Set/Reset) komutları.
    - Command kartı:
      - Torque / Speed / Position seçimine göre etiket, birim ve aralık değişir.
      - Enter değeri gönderir.
    - Keyboard control anahtarı; klavye eşlemesi `kararlar.md`'ye yazılır.
    - **Tasarımda yok ama gerekli (§2, §13):** Parametre profilini dosyaya kaydetme ve dosyadan yükleme.
      - İki düğme, Defaults'un yanında aynı satıra eklenir; kartların yeri değişmez.
      - Yükleme cihaza göndermez; farklar "unsaved" olarak görünür.
  - **Dosyalar:** `MotorControlPage.qml`, `MainControlViewModel.*`, `DemoProvider`, testler.
  - **Bitti:** Demo'da bir değer değişince sayaç artıyor, Write sonrası sıfırlanıyor.

- [x] **T9 — Heater bağlantıları**
  - **Amaç:** Heater'ı modele ve komutlara bağlamak.
    - Enable ve G1/G2/G3/TV/IR doluluk değerleri (okuma ve düzenleme).
    - Read ve Set heater settings komutları.
  - **Dosyalar:** `HeaterPage.qml`, model, `DemoProvider`, testler.
  - **Bitti:** Demo'da tasarımdaki yüzdeler görünüyor; Set komutu gidiyor.

- [x] **T10 — Gimbal settings değerleri ve komutları**
  - **Amaç:** Gimbal settings'in değer ve komutlarını bağlamak.
    - Akış durumu ve hızı (sabit "1 kHz" değil, cihazdan), paket sayısı.
    - Start/Stop stream.
    - Raw position, crosstalk sonucu, IMU bias, Kp/Ki ve kalibrasyon komutları.
    - Board mode.
    - Safe stop ve `Esc` kısayolu; kısayol yalnız bu sayfa görünürken çalışır (18 Kasım).
  - **Dosyalar:** `GimbalSettingsPage.qml`, `DeviceTypes.h`, model, `DemoProvider`, testler.
  - **Bitti:** Testler şunları doğruluyor: `Esc` bu sayfada Safe stop gönderiyor, başka sayfada göndermiyor; demo değerleri görünüyor.

- [x] **T11 — Elle CSV kaydı**
  - **Amaç:** Kullanıcının istediği an kayıt alabilmesi (18 Kasım).
    - Record CSV: akış örneklerini seçilen dosyaya tamponlu yazar.
    - Save CSV: kaydı kapatır.
    - Paket sayısı ve kayıt durumu görünür. Yazma hatası bildirime düşer.
    - §14'teki otomatik kayıt bu görevin kapsamında değildir.
  - **Dosyalar:** `features/telemetry/CsvRecorder.{h,cpp}` (yeni), sayfa, testler.
  - **Bitti:** Test, yazılan satır sayısını gönderilen örnek sayısıyla karşılaştırıyor; yazma hatası görünür.

- [x] **T12 — Scope grafiği**
  - **Amaç:** Scope grafiğini mevcut Qt Quick Shapes ile çizmek; yeni modül eklenmez.
    - Sınırlı geçmiş tamponu (C++, ekrana inceltme) ve `LineChart` bileşeni.
    - Seriler: panRate, panRateRef, tiltRate, tiltRateRef.
    - Gösterge açıklaması: düz çizgi ölçüm, kesik çizgi referans.
    - Y ekseni değerleri ve ızgara.
    - Görünüm listesi (Speed / Position / Torque loop) gösterilen serileri değiştirir.
    - Ölçüm satırı: Rise, Overshoot, Settling, SS error, Latency. Step + / Step − tuşlarıyla ölçüm başlar; yanıt mock.
    - Pop out: grafik ayrı pencerede açılır.
    - Yalnız sayfa görünürken güncellenir.
    - FFT ve Bode sekmeleri "No data" gösterir.
  - **Dosyalar:** `shared/ui/LineChart.qml`, `device/presentation/SeriesBuffer.{h,cpp}`, sayfa, testler.
  - **Bitti:**
    - Test, tamponun sınırını ve inceltmeyi doğruluyor.
    - Gizli sayfada güncelleme olmuyor.
    - Demo'da çizgiler görünüyor.

- [x] **T13 — Script paneli ve CSV yükleme**
  - **Amaç:** Script penceresi ve dışarıdan CSV yükleme. Tasarımda Details ile açılan **ortada bir pencere**dir.
    - **Sol taraf:**
      - FILE: yol, Open CSV, Save CSV; Total rows, Sample time, Duration.
      - AXES: Pan/Tilt anahtarı, sütun seçimi, ofset.
      - Motor mode, Sample time.
    - **Sağ taraf:**
      - PROGRESS: satır, yüzde, Elapsed/Remaining.
      - LIVE COMMANDS: Command ve Actual sütunları.
    - **Alt düğmeler:** Set motor, Close motor, Stop script, Start script.
    - **Open CSV:** Dosyayı ayrıştırır. Hatalı dosya bildirime düşer.
    - **Basit oynatıcı:** Satırları örnekleme süresinde konum komutu olarak gönderir. Sayfa değişince durmaz (§11).
  - **Dosyalar:** `features/maincontrol/ScriptDialog.qml`, `features/telemetry/ScriptFile.{h,cpp}`, `ScriptRunner.{h,cpp}`, testler.
  - **Bitti:** Testler ayrıştırmayı, bozuk dosyayı ve oynatıcının komut sayısıyla zamanlamasını doğruluyor.

## D. Çerçeve

- [x] **T14 — Durum çubuğu**
  - **Amaç:** Durum çubuğunu tasarımdaki gibi tamamlamak.
    - TX/RX ışıkları (`Led`, taslaktan) ve veri hızı. Bayt sayımı taşıma katmanında yapılır; protokol gerekmez.
    - Heartbeat ve ON TIME (protokol alanı; gerçek hedefte "—").
    - BIT rozeti, son BIT mesajı ve saati.
    - Süren işlem ve ilerlemesi; komut ve işlemlerden beslenir.
    - Görünen sayfanın hizmetine ait bağlantı düğmesi.
    - "Debug settings" düğmesi: oturum ayrıntılarını içeren pencere (T2'den).
  - **Dosyalar:** `app/Main.qml`, `shared/ui/Led.qml`, `ServiceConnection.*`, `TransportProvider.*` (yalnız sayaç), `DemoProvider`, testler.
  - **Bitti:** Demo'da bütün alanlar dolu; gerçek hedefte protokol alanları "—".

- [x] **T14b — Üst çubuk**
  - **Amaç:** Üst çubuğu tasarımdaki gibi tamamlamak.
    - **Tema seçici** (`ThemeSwitcher`, taslaktan): `AppSettings`'e yazar, `Theme.mode`'a yazmaz (§9). Tercihler sayfası da kalır.
    - **"Realtime graph and logger":** Ayrı pencere açar.
      - İçerik: T12'nin `LineChart`'ı (seçilebilir seriler), elle CSV kaydı (T11) ve bildirim/olay listesi.
      - Tasarımda içeriği olmadığı için bu yorum `kararlar.md`'ye yazılır.
    - **Model düğmesi** (G180 · v2.0) gösterilmez (17 Kasım).
  - **Dosyalar:** `app/Main.qml`, `shared/ui/ThemeSwitcher.qml`, `features/telemetry/RealtimeWindow.qml`, testler.
  - **Bitti:** Tema seçici ayarı değiştiriyor ve yeniden açılışta korunuyor (test).

- [x] **T15 — Açılışta son sayfa (§12 kural 2)**
  - **Amaç:** Uygulamanın son açık sayfayla açılması.
  - **Dosyalar:** `AppSettings.*` (`lastPage`), `Main.qml`, testler.
  - **Bitti:** Test, yeniden açılışta son sayfanın geldiğini ve geçersiz kimliğin ilk sayfaya döndüğünü doğruluyor.

## E. IDS Image hizmeti

- [x] **T16 — İkinci hizmet ve bağlantı**
  - **Amaç:** IDS Image hizmetini ve bağlantısını kurmak.
    - `idsImage` hizmeti; oturumu, bağlantı kaydı, durum çubuğunda ikinci bağlantı düğmesi.
    - Sol menüde IDS Image'ın kendi logosu ve bağlantı noktası.
    - `ImageViewModel` iskeleti.
    - Gerçek hedefte `TransportProvider`, demoda `ImageDemoProvider`.
  - **Dosyalar:** `app/*`, `device/presentation/ImageViewModel.*`, `test/doubles/ImageDemoProvider.*`, testler.
  - **Bitti:** İki bağlantı aynı anda açık; biri kesilince diğeri sürüyor (test).

- [x] **T17 — IDS Image şablonu ve View & control sayfası**
  - **Amaç:** IDS Image sayfa şablonunu ve ilk sayfasını kurmak.
    - **`ImagePageFrame`** (§11):
      - Üstte video kaynağı satırı: RTSP seçimi, URL, Open. URL ayarlarda saklanır. Video çözme yok (ertelendi), Open durumu "video not available" olarak bildirir.
      - Video alanında görüntü üstü etiketler (`OverlayTag`: ROLL/TILT ve FPS · zoom) ile artı işareti.
      - Sağda STATUS/MODE kartı ve sayfanın kartları.
    - **View & control:**
      - Stream kartı: zoom, blend, brightness, contrast; stream/polarity/FFC modu; NUC; overlay/sky up.
      - Attitude kartı: P, Enable, Keyboard/Joystick, motor durumu, konum kontrolü.
      - Target control kartı: LRF pointer, mesafe, Single/Continuous, Start, box size, Track, follow.
  - **Dosyalar:** `features/idsimage/ImagePageFrame.qml`, `ViewControlPage.qml`, model, `ImageDemoProvider`, testler, sayfa kaydı.
  - **Bitti:** Sığma testi sayfayı kapsıyor; demo değerleri görünüyor.

- [x] **T18 — Alignment sayfası**
  - **Amaç:** Kamera, odak, ofset ve CMOS ayarları; Write offset komutu.
  - **Dosyalar:** `features/idsimage/AlignmentPage.qml`, model, testler.
  - **Bitti:** Ortak ölçütler.

- [x] **T19 — Errors sayfası**
  - **Amaç:** Hata listesi ve IP ayarları.
    - Gruplu liste (PMCB, TMCB, BMACB, MACB, MINIPC) ve "N OK" özeti.
    - IP ayarları (DHCP, adres, Set).
  - **Dosyalar:** `features/idsimage/ErrorsPage.qml`, liste modeli, testler.
  - **Bitti:** Hatalı kalem demoda vurgulanıyor.

- [x] **T20 — Gimbal state sayfası**
  - **Amaç:** FLAGS ve VALUES listeleri; hız seçimi (1 / 5 / 10 Hz) ve Start.
  - **Dosyalar:** `features/idsimage/GimbalStatePage.qml`, model, testler.
  - **Bitti:** Ortak ölçütler.

## F. Tasarımda olmayan ama gerekli

- [x] **T22 — Onay pencereleri**
  - **Amaç:** Geri dönüşü zor işlemlerden önce kullanıcıdan onay almak.
    - Kapsam: firmware güncelleme, bootloader'a girme, boot bridge, kalibrasyonlar (motor döner), Save to flash, Defaults, IP ayarını değiştirme.
    - Ortak `ConfirmDialog` kullanılır. Pencerede ne olacağı ve geri alınamayacağı yazar.
    - Safe stop onay **istemez**.
  - **Dosyalar:** `shared/ui/ConfirmDialog.qml`, ilgili sayfalar, testler.
  - **Bitti:** Test, Vazgeç'in komut göndermediğini, Onayla'nın gönderdiğini doğruluyor.

- [x] **T23 — Çıkış ve kopma korumaları**
  - **Amaç:** Veri ve işlem kaybını önlemek.
    - **Uygulama kapanırken uyarı.** Şu durumlarda kullanıcıya sorulur:
      - Kaydedilmemiş parametre değişikliği var.
      - Firmware güncellemesi, script ya da CSV kaydı sürüyor.
    - **Bağlantı kesilirken:**
      - Süren işlem iptal edilir ve bu bildirime düşer.
      - CSV kaydı dosyası düzgün kapatılır.
  - **Dosyalar:** `app/Main.qml`, ilgili modeller, testler.
  - **Bitti:** Testler kapanış uyarısını ve kopmada CSV dosyasının kapandığını doğruluyor.

## G. Bitiş

- [x] **T21 — Teslim belgesi ve temizlik**
  - **Amaç:** Teslimi ve son temizliği yapmak.
    - `docs/protokol-siniri.md`: devralan kişi için sözleşme, her komut ve alan, mock noktaları, beklenen testler.
    - Kullanılmayan ikon ve bileşenler silinir.
    - Mimari §6, §7, §16, §17 ve §18 güncellenir.
    - `docs/sabah-raporu.md` yazılır.
  - **Bitti:** Belgedeki her komut ve alan kodda var; koddaki her komut belgede var.
