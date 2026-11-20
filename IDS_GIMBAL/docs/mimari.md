# Kodun yapısı (20 Kasım 2026)

Bu belge kodun **bugünkü** yapısını anlatır. Hedefler, ilkeler ve gerekçeler [`mimari-gerekce-v1.2.md`](mimari-gerekce-v1.2.md)'dedir. Tek tek kararlar [`kararlar.md`](kararlar.md)'dedir.

## Genel resim

```text
 appIDS_GIMBAL (app/main.cpp)           appIDS_GIMBALDemo (test/app/main.cpp)
   TransportProvider × 2                  DemoProvider + ImageDemoProvider
              \                               /
               runApp() — app/AppRunner.cpp: nesneleri kurar, birbirine bağlar, QML'e verir
                                  |
  hizmet başına: IDeviceProvider → DeviceSession → ServiceConnection
                                  |
  sunum modelleri: MainControlViewModel (ParameterModel, CsvRecorder, SeriesBuffer, ScriptRunner)
                   ImageViewModel
  uygulama servisleri: AppSettings (+ GimbalLibrary), Localization, NotificationModel
                                  |
                       app/Main.qml → sayfalar (features/…)
```

- İki çalıştırma hedefi aynı kodu ve aynı QML'i kullanır. Yalnız sağlayıcı farklıdır.
- Sağlayıcıyı `main.cpp` seçer ve `runApp()`'e verir.
- QML sağlayıcıyı hiç görmez. Yalnız sunum modellerini görür.

## Katmanlar ve kurallar

| Katman | Sorumluluk | Bilmediği |
|---|---|---|
| `device/api/` | Sözleşme: `IDeviceProvider`, `Command::Kind`, okunan veri yapıları, parametre anahtarları | QML, oturum, taşıma |
| `device/transport/` | Gerçek hedefin seri/UDP bağlantısı (`TransportProvider`) | Sayfalar |
| `device/session/` | Hizmet başına tek etkin oturum, eski sonuçların atılması, bağlantı ayarları (`ConnectionStore`) | QML |
| `device/presentation/` | Cihaz durumunu QML'e sunar: `valid` bayraklı ölçümler, bayatlama, komut gönderme | Bayt kodlaması, disk |
| `features/` | Sayfalar ve özellik kodu | Birbirinin iç sınıfları |
| `shared/` | Tema, ortak kontroller, ayarlar, dil, bildirim | Gimbal'a özgü ayrıntılar |
| `app/` | Kurulum, bağlama, kabuk (`Main.qml`) | — |

**Temel kurallar:**
- **Veri yokluğu:** veri yoksa ya da bayatsa arayüz "—" yazar, sıfır göstermez. Her ölçüm `{value, valid}` taşır.
- **Uydurma veri:** yalnız `test/doubles/` sağlayıcılarında bulunur, gerçek hedefe girmez.
- **Nesnelerin ömrü:** QML'e verilen her C++ nesnesi QML motorundan önce kurulur, böylece motordan sonra yok edilir (`runApp()`).
- **Komutlar:** komut düğmeleri `ServiceConnection.commandsAvailable` false iken kapalıdır. Gerçek hedefte bu değer şu an hep false.

## Hizmetler ve bağlantılar

- **İki hizmet:** `mainControl` (UART ya da UDP) ve `idsImage` (yalnız UDP). Her birinin kendi `DeviceSession` ve `ServiceConnection` nesnesi vardır.
- **Aynı anda bağlantı:** iki hizmet aynı anda bağlı olabilir. Yalnız görünen sayfa ekranı günceller; veri alımı her iki hizmette de sürer.
- **Açılış:** bağlantı ayarları `ConnectionStore`'da hizmet başına saklanır. Ayar varsa uygulama açılışta bağlanır. Ayar yoksa, görünen sayfanın hizmeti için bağlantı penceresi açılır. Demo hep bağlanır.
- **Arayüzdeki yerleri:**
  - Durum çubuğundaki bağlantı düğmesi görünen sayfanın hizmetini gösterir.
  - Üst çubuktaki rozet iki hizmeti özetler; rengi ve metni bağlı hizmet sayısına göre değişir.
  - Rozete tıklanınca `app/ConnectionsPanel.qml` açılır. Buradan her hizmet bağlanır, kesilir ve ayarlanır.
- **Hatalar:** komut hataları ve bağlantı hataları `AppRunner`'da bildirime çevrilir (`NotificationModel`). Bildirimler durum çubuğundaki zilde görünür.

## Kabuk ve sayfalar (`app/Main.qml`)

**Sayfa kaydı:** `pages` dizisi menünün ve içeriğin tek kaynağıdır. Her kayıt şu alanları taşır:
- `id`: sayfa kimliği.
- `service`: sayfanın bağlı olduğu hizmetin anahtarı. Tercihler sayfasında yoktur.
- `group`: menüde göründüğü başlık.
- `title`: sayfa adı.
- `icon`: menü simgesi.
- `component`: sayfanın QML bileşeni.
- `designHeight`: sayfanın tasarımdaki doğal yüksekliği.
- `crumb`: üst çubuktaki yol metni. Yalnız varsayılan yol uygun değilse verilir.

**Ortak ölçek:** bütün sayfalar en uzun sayfanın `designHeight` değerine göre aynı oranla küçültülür, hiç büyütülmez. Böylece bir kart sayfa değişince boyut değiştirmez.

**`pageActive`:** yalnız görünen sayfada true olur. Grafik, video ve 3B çizim gibi ağır işler gizli sayfada durur; veri alımı sürer.

**Sayfa eklemek:**
1. `features/…` altına QML dosyası eklenir. Gerekli model tipli `required property` ile alınır.
2. Dosya `CMakeLists.txt` içindeki `QML_FILES` listesine eklenir.
3. `Main.qml` içinde bir `Component` tanımlanır ve `pages` dizisine kayıt eklenir.
4. `designHeight` ölçülür. `tst_shell` testindeki sığma denetimi içerik bu yüksekliği aşarsa kırılır.
5. Metinler çevrilir (`gelistirme.md`).

**Main control sayfalarının ortak çerçevesi:** `features/maincontrol/ControlPageFrame.qml`. Üstte özet çubuğu, solda 3B gimbal kartı, sağda sayfanın kendi içeriği bulunur.

## Gimbal seçimi, kütüphane ve 3B görünüm

- **Seçim yalnız görünümü değiştirir:** üst çubuktaki gimbal adı ve 3B model değişir. Sayfalar, ayarlar ve bağlantılar değişmez.
- **Seçimin saklanması:** `AppSettings` içinde `gimbal/id`, `gimbal/version` ve `gimbal/onStart` anahtarlarıyla.
- **Kütüphane (`shared/settings/GimbalLibrary`):** `AppSettings.gimbalLibrary` üzerinden erişilir.
  - Liste `gimbals/gimbals.json` dosyasında tutulur.
  - Model dosyaları `gimbals/<id>/` klasörüne kopyalanır: taban, pan ve tilt için birer `.glb`.
  - İlk açılışta varsayılan liste yazılır: G160, G180, Kashif700 ve ZR10. ZR10'un `.glb` dosyaları uygulamayla birlikte gelir (`features/gimbal3d/zr10/`).
  - Okunamayan liste dosyası ezilmez: `gimbals.json.bad` olarak saklanır, kullanıcıya bildirim gider.
- **Pencereler:**
  - `app/GimbalSelectDialog.qml`: gimbal seçimi; her kartta düzenle ve sil, sonda yeni gimbal kartı.
  - `app/GimbalEditDialog.qml`: ad, sürümler, dosyalar ve eksenler; yanında canlı önizleme.
- **3B görünüm:**
  - `features/gimbal3d/GimbalModel.qml` üç `.glb` dosyasını `RuntimeLoader` ile yükler. Pan düğümü tilt düğümünü taşır; dönüş ekseni, yönü ve merkezi model kaydından gelir.
  - `GimbalView.qml` bu modeli bir `View3D` içinde gösterir. Fareyle döndürme ve yakınlaştırma vardır; "Görünümü sıfırla" kamerayı başa alır.
  - Kamera modelin ölçülerine göre bir kez yerleşir. Aynı modeli gösteren görünümler bu yerleşimi `framing.js` ile paylaşır.
  - `View3D` yalnız görünüm görünürken kurulur.
  - Yazılım çiziciyle (offscreen testler, bazı uzak masaüstleri) çalışılıyorsa 3B kurulmaz; alanda nedeni yazar.
- **Eksen kuralı (`inPlace`):**
  - `inPlace` kapalıyken her parça kendi ekseninde ortalanmıştır. Pan merkezi tabana, tilt merkezi pan parçasına göre girilir. ZR10 bu türdendir.
  - `inPlace` açıkken parçalar CAD montajından yerinde dışa aktarılmıştır. Merkezler montajdaki noktalardır; her parça kendi merkezinin tersi kadar kaydırılır.

## Ayar ve veri konumları (Windows)

| Ne | Gerçek uygulama | Demo |
|---|---|---|
| Tercihler, seçili gimbal, bağlantı ayarları | Kayıt defteri `HKCU\Software\IDS\IDS_GIMBAL` | `HKCU\Software\IDS\IDS_GIMBAL_Demo` |
| Gimbal listesi ve modelleri | `%APPDATA%\IDS\IDS_GIMBAL\gimbals\` | `%APPDATA%\IDS\IDS_GIMBAL_Demo\gimbals\` |

Testler bunlara dokunmaz: `tst_qml` geçici bir klasörde INI dosyası ve ayrı bir kütüphane kullanır.

## Testler

| Tür | Yer | Not |
|---|---|---|
| Birim (C++) | `test/unit/tst_*.cpp` | Her biri ayrı çalıştırılabilir ve bir ctest kaydıdır. Sahte sağlayıcı: `FakeProvider.h` |
| QML | `test/qml/tst_*.qml` | Tek çalıştırılabilir (`tst_qml`). `tst_qml.cpp` test nesnelerini ve `testHelper` yardımcısını kurar. QML dosyaları kaynaktan okunur; uygulama modülündeki QML ise derlenir, değişince yeniden derleme gerekir |
| Çeviri bütünlüğü | ctest `translations_complete` | Eksik Türkçe çeviri kalırsa kırılır |
| Belge–kod denetimi | ctest `protocol_doc_matches` | `docs/protokol-siniri.md` ile `device/api/` adlarını karşılaştırır (Python gerekir) |
| Ekran görüntüsü | `tools/shot/tst_shot.qml` | Test değil, karşılaştırma aracı (`gelistirme.md`) |

Demo sağlayıcıları (`test/doubles/`) tekrarlanabilir veri üretir. Test kurulumunda benzetilmiş bağlantı kopması ve geç gelen sonuç da vardır. Demo uygulaması kopmayı kapatır, kapatılana kadar veri gönderir.
