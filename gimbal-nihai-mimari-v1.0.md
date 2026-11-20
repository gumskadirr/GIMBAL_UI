# Gimbal uygulaması — nihai başlangıç mimarisi v1.0

Tarih: 11 Kasım 2026  
Durum: Nihai tasarım belgesi. Kullanıcı kararları ile bağımsız inceleme sonrası verilen teknik kararları birleştirir. Uygulama kodu henüz oluşturulmadı; derleme ve başarım doğrulaması yapılmadı.

## 1. Amaç

Gimbal üzerinde geliştirme ve test yapan mühendisler için C++ ve Qt/QML ile yeni bir masaüstü uygulaması oluşturulacak. İlk hedef, son ekranları tasarlamak değil; tema, dil, ayarlar, cihaz erişimi ve özellik ekleme kurallarını erken belirleyerek geliştirmeyi kolaylaştırmak.

Başarı ölçüsü: Yeni bir özellik kendi C++ ve QML dosyalarıyla eklenebilmeli; tema, çeviri, bildirim ve cihaz bağlantısı yeniden yazılmamalı. Tek gimbal uygulamasının ihtiyacını aşan genel bir cihaz platformu veya dinamik eklenti sistemi kurulmayacak.

Bu belge başlangıç tasarımını tanımlar. Ayrıntılı uygulama görevleri bu belge temel alınarak ayrı bir geliştirme planında hazırlanacak.

## 2. Kullanıcıyla kesinleşen kararlar

| Konu | Karar |
|---|---|
| Kullanıcı | Gimbal geliştiren mühendisler |
| Teknoloji | C++ ve Qt/QML |
| Platformlar | Windows ve Linux |
| Kapsam | Yalnızca gimbal uygulaması |
| Mimari | Tek uygulama içinde özelliklere göre modüler düzen |
| Cihaz sayısı | Aynı anda tek gimbal |
| Komut/telemetri taşıma | Seri veya UDP; birbirinin alternatifi |
| Protokol | UART için mevcut protokol var; UDP'de aynı paket formatı kullanılacak |
| Tema | Açık ve koyu tema arasında geçiş |
| Dil | Başlangıçta Türkçe ve İngilizce |
| Donanımsız geliştirme | Örnek veri kaynağı bulunacak |
| Test kodlarının yeri | Proje kökünde ayrı `test/` klasörü |
| Örnek veri seçimi | Geliştirme ortamında ayrı çalıştırma hedefi; uygulama içi mod düğmesi yok |
| Parametre profilleri | Dosyaya kaydetme ve dosyadan yükleme |
| Parametre uygulama | Dosya açma ve cihaza uygulama ayrı işlemler |
| Telemetri kaydı | Otomatik; alınan tüm örnekler kaydedilecek |
| Telemetri hızı | 2 kHz hedefi |
| Bellek yaklaşımı | Veriler sınırlı tamponda tutulup belirli aralıklarla dosyaya yazılacak |
| Video | Projenin ilerleyen aşamasında ayrı bir sayfa |
| Video ve kontrol | Seri kontrol sırasında UDP üzerinden görüntü alınabilmeli |
| Video yaşam süresi | Sayfadan çıkınca video alımı/çözme duracak; cihaz bağlantısı devam edecek |
| Eski video uygulaması | Kaynak kodu mevcut; yeniden kullanım planlanmıyor |

PDF'deki klasör isimleri, kütüphane isimleri ve uygulama önerileri otomatik olarak kesin karar sayılmamıştır. Harita kütüphanesi, pencere çerçevesi özelleştirmesi ve açılış animasyonu ilk aşamanın zorunlu kapsamı değildir.

## 3. İlk çalışır şablonun kapsamı

Kullanıcının uygun bulduğu ilk çıktı:

- Basit bir uygulama çerçevesi ve sayfa yerleştirme düzeni.
- Açık/koyu tema değiştirme.
- Türkçe/İngilizce dil değiştirme.
- Uygulama tercihlerinin saklanması.
- Bildirim alanı.
- Örnek cihaz verisini gösteren küçük bir doğrulama sayfası.
- Aynı uygulama çerçevesini kullanan gerçek ve örnek veri çalıştırma hedefleri.

İlk aşamada gerçek hedef açılabilir, ancak cihaz oturumu bağlantısız durumda kalır. Gerçek seri/UDP taşıma ve mevcut protokolün entegrasyonu sonraki aşamadır. Doğrulama sayfası son telemetri ekranı değildir; örnek açı, sıcaklık, bağlantı durumu ve bir bildirim senaryosuyla altyapıyı sınar.

İlk aşamada yapılmayacaklar: Gerçek motor komutları, kalibrasyon, firmware güncelleme, 2 kHz kayıt motoru, nihai grafikler, harita, video, bütün eski ekranların aktarımı ve dağıtım kurucusu. Bunların mimaride yeri tanımlanır; kullanılmayan boş modüller oluşturulmaz.

## 4. Değerlendirilen yaklaşımlar

| Yaklaşım | Değerlendirme |
|---|---|
| Katmanlara göre klasörleme | Başlangıcı basittir; özellik büyüdükçe sayfaları, modelleri ve servisleri farklı klasörlere dağılır. |
| Özelliklere göre modüler düzen | Bir özelliğin C++ ve QML kodları birlikte tutulur. Ortak hizmetler tekrar kullanılabilir. Kullanıcı bu yaklaşımı seçti. |
| Dinamik eklenti sistemi | Bağımsız yükleme ve dağıtım sağlar; mevcut tek uygulama ihtiyacı için ek karmaşıklık getirir. Seçilmedi. |

Seçilen yaklaşımda “modül”, açık bir sorumluluk ve bağımlılık sınırıdır. Her klasörün ayrı dinamik kütüphane olması gerekmez. İç modüller uygulamayla birlikte derlenir; yeni üçüncü taraf kütüphane eklemek ayrıca kullanıcı onayı gerektirir.

## 5. Geliştirme ortamı ve seçilen teknik temel

Windows bilgisayarda doğrulanan kurulum: Qt 6.12.0 MinGW 64-bit, Qt Creator 20.0.2, MinGW GCC 13.1.0, CMake 3.30.5 ve Ninja 1.12.1. Qt Creator'ın varsayılan masaüstü kiti Qt 6.12.0 MinGW'dir.

QML, Quick, Quick Controls, Network, SerialPort, LinguistTools, Test ve QuickTest modülleri mevcut. İncelenen MinGW kurulumunda Location ve Positioning görülmedi. Linux kurulumu incelenmedi.

Nihai belge için seçilen teknik temel (kullanıcının ayrı ayrı seçtiği tercihler değil, mimari çalışma kapsamında verilen teknik kararlardır):

- Başlangıçta mevcut Qt 6.12.0 ortamını kullanmak; Linux için aynı Qt sürümünü hedeflemek.
- CMake ile derlemek, QML modüllerini `qt_add_qml_module` üzerinden tanımlamak.
- Başlangıç C++ standardını C++17 olarak açıkça belirlemek; yeni ihtiyaç yoksa yükseltmemek.
- Qt Quick Controls Basic tabanlı küçük bir ortak bileşen seti oluşturmak.
- Qt Creator'a özgü yerel ayar dosyalarını ortak proje yapılandırması saymamak; kaynakta kullanıcıya özgü mutlak yol tutmamak.
- Windows ve Linux için ayrı derleme dizinleri kullanmak. Linux doğrulanana kadar iki platformun da çalıştığı iddia edilmemeli.

QML için ayrı bir sürüm ürünü seçilmeyecek; kullanılan Qt paketinin modülleri temel alınacak. QML importlarında sürüm numarası yazmama, desteklenen Qt sürümünü CMake tarafında tanımlama yaklaşımı kullanılır.

## 6. Klasör ve sorumluluk düzeni

```text
GimbalApp/
├── CMakeLists.txt
├── app/                       # Başlatma, bileşenleri bağlama, uygulama çerçevesi
├── shared/
│   ├── ui/                    # Tema, tasarım değerleri, ortak QML kontrolleri
│   ├── localization/          # Dil yükleme/değiştirme
│   ├── settings/              # Kalıcı uygulama tercihleri
│   ├── notifications/         # Bildirim modeli ve sunumu
│   └── logging/               # Uygulama olay kayıtları; ihtiyaç aşamasında
├── device/
│   ├── api/                   # Uygulamanın gördüğü cihaz durumları ve işlemler
│   ├── session/               # Tek aktif cihaz oturumu
│   ├── presentation/          # QML için ortak, GUI iş parçacığındaki model
│   ├── protocol/              # Ortak paket oluşturma/çözme; sonraki aşama
│   └── transport/             # Seri/UDP taşıma; sonraki aşama
├── features/
│   └── diagnostics/           # İlk altyapı doğrulama sayfası
├── assets/
│   ├── fonts/
│   └── icons/
├── translations/
├── test/
│   ├── app/                   # Örnek hedefin başlangıç kodu
│   ├── doubles/               # Örnek cihaz veri kaynağı
│   ├── data/                  # Tekrarlanabilir senaryo verileri
│   ├── unit/
│   └── qml/
└── docs/                      # Kurulum, mimari ve özellik ekleme açıklamaları
```

Bu ağaç sorumluluk haritasıdır; sonraki aşamaya ait klasörler şimdiden boş olarak açılmayacak. Özellikler gerektiğinde `features/parameters/`, `features/telemetry/`, `features/video/` ve `features/map/` olarak eklenecek.

Bir özellik büyüdüğünde kendi altında `cpp/` ve `qml/` kullanabilir. Küçük bir özellik için bu alt klasörler zorunlu değildir. QML modül adları, kaynak yolları ve CMake hedefleri tutarlı bir kuralla eşleştirilecek; ayrıntılı adlandırma uygulama planında seçilecek. Test uygulaması başlangıcı `test/app/` altında yer alır. Bu dizin, ortak uygulama kodunu çağırır; ortak uygulama test kodunu çağırmaz.

## 7. Bağımlılıklar, sunum modeli ve sahiplik

Değişmeyen sınır: QML gerçek veya örnek sağlayıcıyı doğrudan görmez. Her iki çalıştırma hedefi aynı `DeviceViewModel` C++ tipini ve aynı QML sayfalarını kullanır. Sağlayıcı değişimi bu modelin arkasında gerçekleşir.

```text
Gerçek cihaz sağlayıcısı                 Örnek cihaz sağlayıcısı
  seri/UDP + protokol                     test/doubles/
                 \                        /
                  ortak cihaz erişim sözleşmesi
                              |
                     cihaz oturumu / veri akışı
                         /                 \
           tam örnek akışı                 sunum için güncel durum
          kayıt hizmetine                  DeviceViewModel -> QML
          (sonraki aşama)                   (GUI iş parçacığı)
```

Şema mantıksal akışı gösterir; her kutu ayrı bir iş parçacığı veya kütüphane değildir. Tam örnek akışı GUI modelinden geçmez. İş parçacığı sayısı gerçek haberleşme/kayıt aşamasında belirlenir.

- `app/` bileşenleri oluşturur ve bağımlılıklarını açıkça verir. Tema, tercihler, çeviri, cihaz oturumu yöneticisi ve sunum modelinin sahibi uygulamadır.
- `DeviceViewModel`, `device/presentation/` altında yer alır; QML'e kayıtlı bir QObject tipidir ve GUI iş parçacığında yaşar. Sayfa gerekli modeli tipli `required property` üzerinden alır. Model sayfaya parent edilmez; bir sayfa modeli yok edemez.
- QML motorunun kullandığı C++ nesneleri, motorun bu nesnelere erişimi sona erene kadar yaşar. Kapanışta önce kullanıcı işlemleri ve veri üretimi sonlandırılır; ardından model/servis sahipliği güvenli sırayla bırakılır.
- `device/api/`, QML bağımlılığı taşımayan tipli durum/veri sözleşmesini ve sağlayıcı sınırını tanımlar. Qt Core kullanımı mümkündür; bütün kodu Qt'den bağımsız hale getirme hedefi yoktur.
- `device/session/` ve gerçek sağlayıcı QML sayfalarını bilmez. `device/presentation/` cihaz durumunu sunuma dönüştürür; protokol çözmez, disk yazmaz.
- `shared/` gimbalın PID, protokol veya kalibrasyon ayrıntılarını bilmez; özelliklere bağımlı olmaz.
- Özellikler birbirinin özel sınıflarına erişmez. Paylaşılan cihaz durumu ve tanımlı işlemler üzerinden çalışır. Gerekli yeni işlemler sözleşmeye açıkça eklenir.
- QML sunum ve kullanıcı etkileşiminden sorumludur. İş kuralları, paket çözme ve dosya işlemleri C++ tarafındadır.
- Tema merkezi erişilebilir olabilir. Bütün uygulama hizmetlerini toplayan büyük bir global nesne veya gizli context-property ağı kurulmaz.

İlk sunum sözleşmesi küçük tutulur: bağlantı durumu, örnek açı/sıcaklık ve hata durumu. Her ölçümün geçerli/güncel olup olmadığı ayrıca ifade edilir; veri yokluğu sıfır ölçüm olarak gösterilmez. Yeni oturum, eski ölçümleri güncelmiş gibi devralmaz. Protokolün henüz bilinmeyen alanları uydurulmaz.

Derleme bağımlılıkları bu kuralları destekler: ortak uygulama, cihaz API'si ve ortak sunum gerçek/örnek sağlayıcı uygulamalarına bağımlı olmaz. Seçilen sağlayıcıyı ilgili çalıştırma hedefi bağlar. Ortak başlıklarda `test/` include yolu bulunmaz.

## 8. Gerçek ve örnek veri hedefleri

Hedef adları `GimbalApp` ve `GimbalAppDemo`dur. İkisi aynı uygulama çerçevesini, `DeviceViewModel` tipini ve özellik kodunu kullanır. Gerçek hedefin başlangıcı `app/`, örnek hedefin başlangıcı `test/app/` altında yer alır; her ikisi ortak başlatma koduna seçtiği sağlayıcıyı verir.

Ortak sözleşme `device/api/`, örnek sağlayıcı `test/doubles/` içindedir. İlk aşamada gerçek hedef için cihaz erişimi yapmayan bağlantısız sağlayıcı kullanılır; bu hedefte sahte telemetri gösterilmez. Sonraki aşamada gerçek sağlayıcı bağlandığında QML sayfaları ve sunum sözleşmesi değiştirilmez; yeni özelliklerin gerektirdiği alanlar kontrollü genişletilebilir.

Örnek hedef:

- Ekranda belirgin şekilde “Örnek veri” gösterir; gerçek seri port veya ağ bağlantısı açmaz.
- Gerçek hedefin ayar/kayıt konumlarını kullanmaz.
- Üretim paketine dahil edilmez. Üretim hedefi örnek sağlayıcıya doğrudan veya dolaylı bağlanmaz.
- Tekrarlanabilir veri, bağlantı kesilmesi ve gecikmiş sonuç senaryoları sunar.
- QML modelini özel bir yoldan doldurmaz; gerçek sağlayıcıyla ortak oturum/sunum yolunu kullanır.

Bu sağlayıcı fiziksel gimbal simülatörü değildir. İlk aşamada düşük hızlı doğrulama yeterlidir. Sonraki yük testinde 2 kHz örnek akışı aynı kayıt girişine verilir; masaüstü zamanlayıcısının her 0,5 ms'de kesin uyanacağı varsayılmaz. Kontrollü örnek sayısı/zaman bilgisiyle toplu üretim yapılabilir.

Örnek sağlayıcı protokol ayrıştırıcısını test etmiş sayılmaz. Gerçek protokol eklendiğinde ayrı parçalı paket, bozuk paket ve datagram testleri gerekir.

## 9. Tema, font ve ortak kontroller

Temel kontrol stili **Qt Quick Controls Basic** olarak sabitlenmiştir. İlk ortak QML kontrollerinde Basic açıkça kullanılır; varsayılan işletim sistemi stiline güvenilmez. QML tipleri yüklenmeden stil seçimi tamamlanır. Açık/koyu tema değişimi `QQuickStyle` değiştirerek yapılmaz.

Görsel altyapı iki parçadan oluşur:

- Tasarım değerleri: Anlamlı renk rolleri, font ailesi/boyutları, boşluklar, köşe yarıçapları ve kontrol boyutları.
- Ortak kontroller: İlk sayfanın gerektirdiği kadar düğme, alan, durum göstergesi ve bildirim sunumu.

`background`, `surface`, `textPrimary`, `textSecondary`, `accent`, `warning`, `error`, `border`, `disabled` ve `focus` gibi rollerin açık/koyu karşılıkları merkezi Theme nesnesinde bulunur. Sayfalara sabit renk kopyalanmaz. Tema değişimi bu değerleri günceller; açık sayfa, kontrol ve popup aynı anda değişir, yeniden başlatma gerekmez.

Tema tercihi C++ ayar hizmetinde saklanır. QML Theme nesnesi paleti sunar; sayfalar kendi tema durumunu tutmaz. Tema merkezi erişimi uygulama hizmetlerinin tamamını global hale getirme gerekçesi değildir.

Font, ikon ve nihai IDS paleti henüz seçilmedi. İlk aşamada nötr bir geçici palet ve merkezi tanımlı sistem fontu kullanılacak. Platformlarda font ölçüleri değişebileceğinden sabit metin genişliklerine güvenilmez. Dağıtılacak özel font/ikonların izinleri ve paketlemesi seçildiklerinde doğrulanır; yeni kütüphane kurulmaz.

Bütün Qt kontrollerini baştan saran katalog yapılmaz. Ortak davranış veya tekrar ortaya çıktıkça bileşen eklenir. Kontrollerin devre dışı, odak, basılı ve hata durumları ortak değerleri kullanır.

## 10. Dil, bildirim metinleri ve uygulama tercihleri

Başlangıç dilleri Türkçe ve İngilizcedir. Qt çeviri dosyaları kullanılır; QML ve C++ kullanıcı metinleri ilk günden çeviriye uygun yazılır. Protokol anahtarları, hata kodları ve serileştirilen alan adları dilden bağımsızdır.

Dil değiştirme tek Localization hizmeti üzerinden yürür:

1. İstenen çeviri yüklenir; yükleme başarısızsa mevcut çalışan dil korunur ve kullanıcı bilgilendirilir.
2. Başarılı değişimde QML çeviri bağlamaları yenilenir.
3. C++ modellerindeki canlı durumlar ve sayfa başlıkları yeniden hesaplanır; ilgili özellik/model değişim bildirimleri üretilir.
4. Başarılı seçim tercihlere kaydedilir.

`QQmlEngine::retranslate()` çağrısının bütün C++ metinlerini otomatik değiştirdiği varsayılmaz. Sayfa kayıtları sabit sayfa kimliği ve çeviri bilgisi taşır; yalnız başlangıçta çevrilmiş QString saklanmaz.

Bildirim politikası: Bildirim modeli mesaj kodu, biçimlendirme girdileri, önem, zaman ve varsa teknik ayrıntıları saklar. Ekranda tutulan önceki bildirimler de yeni dilde sunulur. Ham cihaz hata metni gibi çevirilemeyen içerik korunur ve çevrilebilir açıklamayla gösterilir. Diskteki geçmiş loglar dil değişiminde yeniden yazılmaz; olay kodu/verileri dil değişiminden bağımsızdır.

Arayüzdeki sayı gösterimiyle protokol/dosya serileştirmesi ayrılır. Dil değişikliği dosya biçimini veya mühendislik birim sistemini değiştirmez. Türkçe/İngilizce metin uzunlukları yerleşimde karşılanır.

Uygulama tercihleri küçük, tipli bir C++ hizmeti üzerinden QSettings ile saklanır. İlk aşamada tema ve dil; sonrasında bağlantı tercihi ve kayıt konumu eklenebilir. Eksik/geçersiz alanlar varsayılanlara döner. Tercih yazma başarısızlığı sessizce başarılı sayılmaz; uygulama kullanılabilir kalır ve bildirim verir.

İlk açılış varsayılanı Türkçe ve koyu temadır. Gerçek/örnek hedefin ayar kimlikleri ayrıdır. Dosya konumları işletim sisteminin uygun yollarından alınır; kullanıcı adı ve mutlak bilgisayar yolu kaynakta bulunmaz. Gimbal parametreleri uygulama tercihleriyle aynı veri yapısında tutulmaz.

## 11. Sayfa ekleme ve sayfa yaşam süresi

Başlangıçta basit bir sayfa kayıt listesi ve sayfa gösterici yeterlidir. Sayfaya ait başlık çevirisi, ikon ve oluşturma bilgisi tek noktadan kaydedilir. Sayfaların dosya yollarını uygulamanın farklı yerlerine dağıtan yönlendirme kodu kullanılmaz.

Bir sayfanın etkinleştirilmesi ve devre dışı bırakılması açık işlemler olmalıdır. Sayfanın bellekte önbelleklenmesi, arka plan işinin çalışmaya devam etmesi anlamına gelmez.

Sonraki video sayfası bu kurala uyar: çıkışta video alımı/çözme sonlandırılır ve video kaynakları serbest bırakılır. Komut/telemetri oturumu ve otomatik telemetri kaydı uygulama düzeyinde sürdüğü için etkilenmez. Video açılışının otomatik mi kullanıcı komutuyla mı olacağı video aşamasında belirlenecek.

Kullanıcının sonradan harita ekleme akışı örneği:

1. `features/map/` altında özelliğin C++ ve QML dosyalarını ekler.
2. Özelliğin CMake/QML tanımını uygulamaya bağlar ve sayfa listesine kaydeder.
3. Ortak tema, bildirim ve dil düzenini kullanır.
4. Cihaz verisine veya işlemlerine ihtiyacı varsa tanımlı cihaz arayüzünü kullanır; mevcut arayüz yetmiyorsa bu sözleşmeyi açıkça genişletir.
5. Gereken örnek senaryoyu ve anlamlı testi `test/` altında ekler.

Harita sağlayıcısı, çevrimdışı kullanım ve koordinat/yönelim dönüşümleri şimdi seçilmeyecek.

## 12. Haberleşme için korunacak sınırlar

Seri ve UDP aynı paket kodlayıcı/çözücüyü kullanır. Ancak seri hattın parçalı/birleşik byte akışı ile UDP datagramlarının sınırları aynı kabul edilmez. Ortak çözücüye veri sunulmadan önce taşıma türünün gerektirdiği paketleme kuralları uygulanır.

Gerçek haberleşme aşamasından önce mevcut protokol belgesi veya kodu okunmalı. Paket boyu, byte sırası, doğrulama alanı, komut yanıtları, zaman aşımı ve varsa örnek sıra numarası/zaman damgası varsayılmamalı.

Komut/telemetri için aynı anda yalnızca bir taşıma etkin olur. Uygulama ömürlü oturum yöneticisiyle her bağlantıya ait oturum kimliği farklı kavramlardır. Her bağlantı girişiminde yeni kimlik kullanılır; eski sonuçlar yeni kimlikle yeniden etiketlenmez. Video bağlantısı bu seçimden bağımsızdır.

Oturum yaşam süresi kuralları:

1. Bağlantı kapatılırken o oturuma yeni komut ve yeni telemetri kabulü sonlandırılır; sağlayıcı durdurulur.
2. Bekleyen komutlar belirsiz/iptal durumuyla tamamlanır. Tekrar bağlantı eski komutu otomatik yeniden göndermez.
3. Kayıt kuyruğuna önceden alınmış örnekler kendi oturum dosyasında boşaltılır ve dosya sonlandırılır. Geç gelen komut sonuçlarının reddi, önceden kabul edilmiş telemetrinin atılması anlamına gelmez.
4. Yeni taşıma eski oturum kapanışı tamamlandıktan sonra başlatılır. Kapanış başarısızsa başarılı geçiş gösterilmez; otomatik yeni bağlantı başlatılmaz.
5. Arayüzde eski sonuçların uygulanması oturum kimliğiyle engellenir. Yalnız signal/slot bağlantısını kesmek yeterli kabul edilmez.
6. Kaynakları kullanan iş tamamlanmadan nesneler yok edilmez. Kapanış son tarihi aşılırsa eksik kapanış ve kalan örnek sayısı raporlanır; çalışan iş parçacığı zorla sonlandırılmaz. Arayüz yanıt vermeye devam eder, kapanış tamamlanana kadar servis sahipliği korunur. Kullanıcının işletim sistemi üzerinden zorla kapatması eksik kayıt bırakabilir.

Kesin zaman aşımı değerleri protokol ve kayıt performansı öğrenilince seçilir. İlk aşamada gecikmiş örnek sonucu üzerinden kimlik kontrolü doğrulanır; gerçek worker/yazıcı uygulaması gerekmez.

Uygulama çalışmaları kapsamında MCU pinleri, çevre birimi ayarları veya `.ioc` dosyası değiştirilmeyecek. İleride firmware değişikliği gerekirse ayrı iş olarak ele alınır.

## 13. Parametre yönetimi — sonraki aşama

Üç ayrı durum tutulacak: cihazdan okunan değerler, kullanıcı tarafından düzenlenen/yüklenen değerler ve dosyadaki profil.

Dosya açılması cihaza komut göndermez. Yüklenen değerler doğrulanır, farklar gösterilir, kullanıcı ayrı olarak uygulamayı başlatır. Gönderilmiş değerler cihaz tarafından kabul edilmiş sayılmaz; protokolün sağladığı yanıt veya geri okuma mekanizmasına göre sonuç belirlenir. Kısmi başarısızlık ayrıca gösterilir.

Profil biçimi sürümlendirilebilir olmalı; cihaz/model uyumluluk alanları protokol bilgisi alındıktan sonra seçilir. Dosya biçimi, parametre listesi ve kalıcı cihaz hafızasına yazma davranışı başlangıç şablonunun açık tasarım kararı değildir; bu özellik başlamadan netleştirilir.

## 14. Otomatik telemetri kaydı — sözleşme şimdi, uygulama sonraki aşamada

Hedef 2 kHz hızındaki, doğrulama sonrası gözlenen tüm geçerli telemetri örneklerini kaydetmektir. Otomatik kayıt sayfa açılmasına bağlı değildir. Video kaydı bu kapsamda değildir.

```text
Taşıma -> çerçeve/protokol doğrulama -> geçerli örnek sayımı
    ├── kayıt hattı -> sınırlı örnek kuyruğu -> toplu dosya yazımı
    └── sunum hattı -> güncel durum/sınırlı grafik geçmişi -> GUI modeli -> QML
```

### Bellek ve aktarım

Sınır yalnız kayıt tamponuna uygulanmaz: seri okuma, çerçeve birleştirme, bekleyen komutlar, kayıt kuyruğu, grafik geçmişi ve iş parçacıkları arası bekleyen veri için kapasite ve taşma davranışı belirlenir. İşletim sistemi tamponları da kapasite/kayıp riski açısından hesaba katılır. İş parçacıkları arası sinyaller sınırsız sayıda örnek taşıyan gizli ikinci bir kuyruk oluşturamaz.

Kayıt örnekleri sahipliği belirli değer nesneleri/toplulukları olarak aktarılır; üretici, tüketicinin kullandığı belleği yeniden yazamaz. İlk uygulamada basit, sınırlandırılmış ve senkronizasyonu açık bir kuyruk yeterlidir; lock-free yapı veya yeni kütüphane şart değildir.

GUI'ye aktarılacak güncellemeler GUI olay kuyruğuna girmeden birleştirilir. Güncel değerlerin tutulması ve sınırlı grafik geçmişi, tam örnek kaydından ayrıdır. GUI'nin kısa süre duraksaması kayıt/alımı durdurmamalıdır.

### Yazım ve hata politikası

Süre veya doluluk eşiğinde toplu yazılır; her örnek ayrı disk çağrısı üretmez. Yazım arka planda yürür. Kısmi yazılan topluluğun yazılmayan kısmı bekleyen olarak kalır; tüm topluluk erken serbest bırakılmaz.

Kuyruk kapasitesi dolduğunda yeni gelen kayıt örnekleri kuyruğa alınmaz; bunlar önceden yapılmış geçerli örnek sayımından düşülmez, nedeni ile kayıp sayılır. Daha önce kabul edilen örneklerin üzerine sessizce yazılmaz. Kontrol/alım iş parçacığı disk beklemesine sokulmaz. Kayıt durumu belirgin biçimde eksik/hatalı gösterilir; tekrarlayan aynı hatalar bildirim yağmuruna dönüşmez.

Kalıcı yazma hatasında sınırsız yeniden deneme veya RAM birikmesi yoktur. Hata sonrası kaydedilemeyen örnekler kayıp olarak hesaplanır. Yeni bir dosyayla kurtarma yapılırsa ayrı kayıt bölümü ve kayıp aralığı görünür olur; eski oturum eksiksizmiş gibi sunulmaz. Varsayılan davranış otomatik dosya silmek değildir. Disk saklama/döndürme politikası ayrıca kararlaştırılana kadar alan yetersizliği hata olarak raporlanır.

### Sayım, zaman ve dosya bütünlüğü

Geçerli örnekler kayıt kuyruğuna eklenmeden önce sayılır. Her örnek uygulama oturum kimliği, uygulama içi artan sıra kimliği ve monoton alınma zamanı taşır. Oturum başlangıcındaki takvim zamanı ayrıca kaydedilir. Cihaz sıra/zaman bilgisi varsa ayrıca korunur; sağlanmadığında uydurulmaz. Alınma zamanı cihazın örnekleme zamanı olarak sunulmaz.

Tutarlı ölçüm anında veya sonlandırılmış oturumda şu eşitlik sağlanır:

`gözlenen geçerli örnek = bekleyen/yazılmakta + başarıyla yazılmış + nedeni belirli kayıp`

Bir örnek aynı anda iki sınıfta sayılamaz. Başarıyla yazılmış sayacı, örneğe ait dosya yazımı tam olarak kabul edildikten sonra ilerler; final dosya denetimiyle ayrıca doğrulanır. Bu sayaç tek başına güç kesintisine karşı kalıcı depolama garantisi değildir.

Normal kapanışta bekleyen sıfır olmalıdır. Kuyruğa hiç giremeyen örnekler kayıpsızlık hesabından saklanmaz. Oturum dosyası kapanışında final sayımlar ve eksik/tamamlanmış durumu korunur; kapanış belirteci olmayan kayıt eksiksiz sayılmaz. Taşıma öncesindeki kayıpların tespiti mevcut protokol desteğine bağlıdır.

Kapanış Bölüm 12 sırasına uyar: yeni kabul durur, kabul edilmiş kayıtlar boşaltılır, dosya sonlandırılır, ardından kaynaklar bırakılır. Zaman aşımı başarılı kapanış olarak sunulmaz.

### Kayıt aşamasında belirlenecekler

Paket/örnek boyu, seri baud ve paket başına örnek sayısı öğrenilmeden 2 kHz taşıma yeterliliği kabul edilmez. Kuyruk kapasitesi gerçek veri boyu ve karşılanacak disk gecikmesine göre hesaplanır. Kayıt formatı, yazma eşikleri, dosya döndürme, dışa aktarma ve test süresi kayıt aşamasında belirlenir.

Kayıt hizmeti `features/telemetry/` içinde arayüzden bağımsız C++ hedefi olarak tutulabilir; QML sayfasını import etmez. Başlatma ve ömrü uygulama/oturum tarafından yönetilir. Bunu `shared/` altında genel bir veri platformuna dönüştürmek gerekmez.

Normal koşullarda bütün örnekler hedeflenir; sınırlı bellek ve süresiz disk kesintisinde kayıpsızlık garanti edilmez. Hata senaryolarındaki başarı ölçütü kaybın görünür ve sayılabilir olması, kontrolün çalışabilir kalmasıdır.

## 15. Kabul ölçütleri

### İlk çalışır şablon

1. İki hedef aynı QML sayfasını ve DeviceViewModel tipini kullanır. Örnek hedef belirgin işaretlidir, gerçek cihaz erişimi yapmaz; gerçek hedef ilk aşamada bağlantısızdır.
2. Üretim hedefinin doğrudan/dolaylı bağımlılıklarında örnek sağlayıcı bulunmaz. İki hedefin ayar kimlikleri ayrıdır.
3. Tema geçişi Basic taban stili değişmeden arka plan, düğme, alan, odak/devre dışı durumları ve açık bildirim/popup'a yansır.
4. Dil geçişi QML etiketi, C++ canlı durum, sayfa başlığı ve ekranda tutulan önceki bildirime yansır. Çeviri yükleme hatası mevcut dili bozmaz.
5. Tema/dil tercihi yeniden açılışta korunur. Geçersiz ayar varsayılana döner; yazma hatası görünürdür.
6. Geçersiz/bayat örnek sıfır veya güncel değer gibi sunulmaz. Bağlantı kesilmesi ve hata senaryosu gösterilir.
7. Bildirim listesi sınırlıdır; tekrarlayan hata birleştirilir.
8. Doğrulama sayfasıyla basit tercihler görünümü arasında geçiş, ortak modeli ve cihaz oturumu yöneticisini yeniden oluşturmaz. Sayfaya ait etkinlik durdurulabilir.
9. Örnek kaynağın gecikmiş eski oturum sonucu yeni oturum durumunu değiştiremez. Bu testte gerçek disk yazıcısı gerekmez.
10. Windows derleme/çalıştırması doğrulanır. Linux hedef ortamında da temel şablon doğrulanmadan çapraz platform desteği tamamlandı denmez. Ortam erişimi yoksa açık doğrulama kalemi olarak raporlanır.
11. Derleyici ve QML araçlarının anlamlı hataları giderilir. Sahiplik, sağlayıcı seçimi, ayar/çeviri ve sayfa yaşam süresi için davranış testleri yapılır; klasör yapısını tekrar eden testler yazılmaz.

### Haberleşme ve kayıt aşaması

- Gerçek seri/UDP çerçeveleme ve protokol davranışı belgelere/örneklere karşı test edilir.
- 2 kHz örnek akışında üretilen, gözlenen, bekleyen, yazılan ve kayıp sayıları dosya içeriğiyle karşılaştırılır.
- Uzun çalışmada toplam bellek ve bütün kuyruklar izlenir; büyümenin sınırlı olduğu gösterilir.
- GUI duraksaması, disk yavaşlaması/dolması, kısmi yazım, bağlantı değişimi ve kapanış zaman aşımı sınanır.
- Normal tamamlanmış kayıtta bekleyen ve kayıp sıfırdır. Hatalı senaryoda eksik kayıt başarı olarak sunulmaz.

İlk şablonun tamamlanması 2 kHz performansın kanıtlandığı anlamına gelmez. Test süresi, veri boyu ve hedef bilgisayar kayıt aşamasında raporlanır.

## 16. Aşama sınırları

1. Başlangıç şablonu: Uygulama çerçevesi, tema, dil, tercihler, bildirimler, cihaz erişim sözleşmesi ve örnek veri doğrulaması.
2. Cihaz temeli: Mevcut protokolü inceleme, seri/UDP taşıma, oturum ve gerçek telemetri entegrasyonu.
3. Kayıt ve yük doğrulaması: 2 kHz otomatik kayıt, tamponlar, disk davranışı ve grafik sunum ayrımı.
4. Mühendislik özellikleri: İhtiyaç önceliğine göre parametreler, kontrol, kalibrasyon, analiz ve diğer sayfalar.
5. İleri özellikler: Harita ve projenin sonlarına yakın video sayfası.

Bu sıra süre taahhüdü veya ayrıntılı uygulama planı değildir. İlk aşamanın görevleri bu tasarım temel alınarak ayrı planlanır.

## 17. Açık kararlar ve uygulayıcıya bırakılanlar

İlk aşamada yeni kullanıcı kararı gerektirmeyen teknik seçimler bu belgede yapıldı: sabit Basic stili, ortak GUI sunum modeli, tipli sayfa bağımlılıkları, ekrandaki bildirimleri yeniden çevirme, sınırlı aktarım, kuyruk dolunca yeni örneği kayıp sayma ve oturum kapanış sırası.

Sonraki aşamalarda bilgi alınacak konular: Linux dağıtımı/ortamı, gerçek protokol, 2 kHz örnek boyu ve taşıma kapasitesi, parametre profili biçimi, kayıt formatı/saklama/döndürme, video protokolü/codec ve sayfa açılışında başlatma davranışı, harita sağlayıcısı, son font/palet/ikonlar. Bunlar seçilmiş veya uygulanmış kabul edilmez.

Uygulayıcı küçük sınıf adlarını, QML modül adlarını, CMake hedef ayrımını ve geçici görsel değerleri bu kurallar içinde seçebilir. Yeni kütüphane kuramaz, gerçek motor kontrolünü ilk şablona dahil edemez veya kullanıcının mevcut projelerini değiştiremez.

Önceki taslak ve bağımsız inceleme ayrı dosyalar olarak korunur. İleride tasarım değişirse bu belgenin sürümü ve değişiklik özeti güncellenir. Bu belge v1.0 için tek başvuru kaynağıdır.

## 18. Teknik dayanaklar ve v1.0 değişiklik özeti

- [Qt QML importları](https://doc.qt.io/qt-6/qtqml-syntax-imports.html)
- [Qt QML modülleri ve CMake](https://doc.qt.io/qt-6/qtqml-modules-cmake-integration.html)
- [Tipli C++ nesnelerini QML'e açma](https://doc.qt.io/qt-6/qtqml-cppintegration-exposecppattributes.html)
- [Kontrol özelleştirme ve taban stil](https://doc.qt.io/qt-6/qtquickcontrols-customize.html)
- [QQuickStyle seçim zamanı](https://doc.qt.io/qt-6/qquickstyle.html)
- [QML çeviri bağlamalarının yenilenmesi](https://doc.qt.io/qt-6/qqmlengine.html#retranslate)
- [Qt nesneleri ve iş parçacıkları](https://doc.qt.io/qt-6/threads-qobject.html)
- [Seri port tamponu](https://doc.qt.io/qt-6/qserialport.html#setReadBufferSize)
- [Kuyruklu bağlantıları kesmenin sınırı](https://doc.qt.io/qt-6/qobject.html#disconnect)

Bağımsız incelemedeki altı konu şu bölümlerde kapatıldı:

| İnceleme bulgusu | Nihai kararın yeri |
|---|---|
| Gerçek/örnek kaynak ile QML modelinin ayrımı | Bölüm 7–8 |
| Sabit kontrol stili ile açık/koyu tema ayrımı | Bölüm 9 |
| Dil değişiminin C++ modellerine yayılması | Bölüm 10 |
| Uçtan uca sınırlı bellek | Bölüm 14 |
| Geçerli örneklerin kuyruktan önce sayımı | Bölüm 14 |
| Oturum ve kayıt kapanış sırası | Bölüm 12 ve 14 |

Doğrulama ölçütleri Bölüm 15'e eklendi. Bu kapanış bir tasarım incelemesi sonucudur; uygulama veya performans testi sonucu değildir.

Son bağımsız tutarlılık incelemesinde ilk aşamanın planlanmasını engelleyen çelişki veya eksik politika bulunmadı. İnceleme, belgenin kendi başına kullanılabilirliği ve altı bulgunun kapatılmasıyla sınırlıdır.

