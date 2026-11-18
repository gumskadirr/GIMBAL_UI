# İnceleme — 18 Kasım 2026

Kapsam: `main` (98b1ae3), Mimari v1.1, 11–18 Kasım kararları, `taslak/` tasarımı (10 ekran).
Başlangıç durumu: derleme temiz, qmllint 0 uyarı, 11/11 CTest geçiyor.

## 1. Tamamlananlar

| Alan | Durum |
|---|---|
| Çerçeve | Sol menü, üst çubuk, durum çubuğu, sayfa kaydı (`Main.qml`), ekrana sığdırma (`designHeight`), sayfa etkinliği (`pageActive`) |
| Tema / font / dil | Üç tema, Inter + JetBrains Mono, TR/EN anında geçiş, TR ondalık virgül (`NumberFormat`) |
| Tercihler / bildirim | `AppSettings` (tema, dil), `NotificationModel` (sınırlı, birleştiren, yeniden çevrilen) |
| Cihaz katmanı | `IDeviceProvider` sözleşmesi, `DeviceSession` (oturum kimliği, eski sonuç süzme), `DeviceViewModel`, `DemoProvider` |
| Bağlantı | `ConnectionTarget`, `ConnectionStore` (hizmet başına), `TransportProvider` (seri/UDP açma, protokolsüz), `ConnectionPopup`, açılışta otomatik bağlanma |
| Sayfalar | Gimbal info, Motor control, Gimbal settings (grafiksiz), Heater, Tercihler; Diagnostics (yalnız demo) |
| Test | 9 birim testi, 6 QML test dosyası, çeviri bütünlüğü testi; sığma testi 4 boyut × 2 dil |

## 2. Eksikler

**Main control (tasarıma göre):**
- Sayfalardaki değerlerin çoğu "—" ve modele bağlı değil: on time, BIT listesi, önyükleyici durumu, motor parametreleri, akış/paket sayısı, script durumu, kalibrasyon sonuçları, IMU bias, filtre kazançları, ısıtıcı bölgeleri.
- Komutların hiçbiri bağlı değil (`commandsAvailable` her zaman false). Demo hedefinde de düğmeler kapalı.
- Parametre modeli yok: Read / Write / Save to flash / Defaults, "N UNSAVED CHANGES", dosyaya kaydet/yükle (§13).
- Scope grafiği, ölçüm satırı (rise / overshoot / settling…), Script ayrıntı paneli, Safe stop `Esc` kısayolu.
- Elle CSV kaydı ve CSV yükleme (18 Kasım kararı).
- Firmware güncelleme dosya seçimi ve ilerlemesi.

**Çerçeve:**
- Durum çubuğu: TX/RX etkinliği, veri hızı, heartbeat, on time, BIT özeti, süren işlem ve ilerlemesi, saat.
- Açılışta son açık sayfaya dönme (§12 kural 2).
- Üst çubuktaki "Realtime graph and logger" düğmesi (işlevi tanımlı değil).

**IDS Image hizmeti (tamamı):** İkinci bağlantı, sayfa şablonu, View & control, Alignment, Errors, Gimbal state.

**Kapsam dışı / sonraya:** 3B görünüm (Quick3D yeni modül, onay ister), video (protokol/codec belirsiz), 2 kHz otomatik kayıt motoru (§14), harita, Linux doğrulaması.

## 3. Mimari ve kararlarla çelişen yerler

1. **`CMakeLists.txt`:** "Real target: no device transport yet, so it stays disconnected" yorumu eski. Gerçek hedef artık `TransportProvider` kullanıyor.
2. **Mimari §8 ve §15.1:** "Gerçek hedef bağlantısız sağlayıcı kullanır" ifadesi eski (Adım 17a'dan beri seri/UDP açılıyor).
3. **Mimari §6:** Ağaçta `device/transport` "sonraki aşama" olarak duruyor; uygulandı. `docs/` altında kurulum ve "özellik ekleme" belgesi yok.
4. **Mimari §2 ve §12:** Main control'ü yalnız "UART" diye geçiriyor. 17 Kasım kararı ve uygulama, Main control için UART ya da UDP sunuyor.
5. **Mimari §1 ve §16 (artımlı, tek adımlık plan):** 18 Kasım'da kullanıcı bütün plan için tek onay istedi. Bu, kurallardan bilinçli bir sapmadır.
6. **Mimari §7 (komutlar protokol gelmeden sözleşmeye girmez):** Yeni hedefle çelişiyor. Arayüzün protokolden bağımsız ilerleyebilmesi için komut sınırının arayüz + mock olarak tanımlanması gerekiyor. Planda T5 bunu karara bağlıyor.
7. **Mimari §12 kural 2 (son açık sayfa açılır):** Uygulanmamış; uygulama hep Gimbal info ile açılıyor.

## 4. Dağınık, tekrar eden ve ölü kod

- **`features/diagnostics/DiagnosticsPage.qml`:**
  - 1. aşamanın doğrulama sayfası. Gösterdiği değerler artık Gimbal info'da, Bağlan/Kes düğmeleri durum çubuğunda var.
  - Yalnız `tst_shell`'deki sayfa etkinliği testi bu sayfayı kullanıyor.
- **`DeviceViewModel`:** İki ayrı sorumluluğu bir arada taşıyor: bağlantı (durum, özet, uygula, portlar) ve Main control verisi.
  - IDS Image eklendiğinde bağlantı kısmı kopyalanmak zorunda kalır.
  - Ad da artık belirsiz: "Device" iki hizmetten hangisi?
- **`AppRunner.cpp`:** `kMainControlService` sabit kodlu. Bağlantı yükleme, kaydetme ve açılışta bağlanma tek hizmet için yazılmış; ikinci hizmet bu kodun kopyalanmasını gerektirir.
- **`Icons.qml`:** 9 ikon kullanılmıyor (eye, target, list, chart, drop, moon, gimbal, resetView, check). Bir kısmı IDS Image sayfalarında kullanılacak.
- **Tekrar eden sayfa yardımcıları:**
  - `GimbalSettingsPage`'deki `BarTitle`, `ValueText` ve `LabelText` satır içi bileşenleri, Heater ve Motor control'deki benzer metin stilleriyle örtüşüyor.
  - Küçük; sayfalar bağlanırken ortaklaştırılabilir.
- **`DeviceViewModel::availableSerialPorts()`:** Sunum katmanı `QSerialPortInfo`'ya bağımlı. Küçük bir sınır sızıntısı; zararsız, not edildi.

## 5. Frontend ↔ protokol sınırı (öneri)

Sınırın tamamı `device/api/` içindedir. Protokolü devralacak kişi yalnız bu sözleşmeyi uygular; QML'e, sunum modellerine ve oturuma dokunmaz.

```text
QML sayfaları ──► sunum modelleri (device/presentation)  ◄── frontend'in alanı
                        │
                 DeviceSession (oturum kimliği, bekleyen komutlar, iptal)
                        │
        ┌───────── IDeviceProvider (device/api) ─────────┐   ◄── SINIR
        │                                                │
  DemoProvider / FakeProvider (mock, test/)    Gerçek sağlayıcı (device/protocol)  ◄── protokolcünün alanı
                                               TransportProvider'ı (bayt taşıma) kullanır
```

**Sözleşmede olanlar (bugün):**
- `start/stop`.
- `stateChanged`.
- `sampleReceived(DeviceSample)`: akış verisi.
- `boardInfoReceived(BoardInfo)`: bir kez okunan veri.
- Her değer `valid` bayrağı taşır.

**Eklenecekler (plan T5–T6):**
- **Komutlar:**
  - `DeviceCommand { Kind kind; QVariantMap args; }`, `CommandResult { Status; detail }`.
  - `IDeviceProvider::send(sessionId, requestId, command)` ve `commandFinished(...)` sinyali.
  - `supportsCommands()`: komutları gerçekten işleyebilen sağlayıcı true döner.
  - Gerçek hedef protokol gelene kadar false döner, bu yüzden düğmeler kapalı kalır. Demo true döner, düğmeler mock yanıtla çalışır.
- **Parametreler:** Anahtar → değer haritası (`parametersReceived`) ve okuma/yazma/kaydetme komutları. Anahtar listesi tek başlıkta durur.
- **Durum ve telemetri alanları:** Tasarımdaki her gösterim alanı tipli yapılarda `valid` bayrağıyla tanımlanır. Ad, birim ve ölçek protokol gelince doğrulanır (§7).

**Mock noktaları:**
- `test/doubles/DemoProvider`: demo hedefi; her komutu gecikmeli kabul eder ve değerleri üretir.
- `test/unit/FakeProvider`: testler.
- IDS Image için ayrı demo sağlayıcı.

**Teslim belgesi:** `docs/protokol-siniri.md` (plan T21). İçeriği:
- Her komut türü ve argümanları.
- Her alanın tasarımdaki adı ve birimi.
- Uygulanacak sınıf, bağlanacak yer (`app/main.cpp`).
- Beklenen testler (§8 sonu: parçalı paket, bozuk paket, datagram).
