# Adım 17a — Bağlantı altyapısı (hizmetten bağımsız; şimdilik yalnız Main control)

**Hedef:** Gerçek seri port ve UDP taşıması, hizmet başına saklanan bağlantı ayarları ve açılışta otomatik bağlanma. Arayüz (bağlantı penceresi) Adım 17b'de gelecek.

**Dayanak:**
- `../gimbal-nihai-mimari-v1.1.md` §2: Main control UART **ya da** UDP ile bağlanır, paket biçimi aynıdır.
- §12 bağlantı kuralları 1–5 (17 Kasım).

## Kararlar
- **`ConnectionTarget`** (`device/api`):
  - Taşıma: Serial | Udp.
  - Seri: port, baud, data bits, parity, stop bits.
  - UDP: cihazın IP adresi ve portu.
  - Düz değerlerden oluşur; API'ye QtSerialPort veya QtNetwork türü girmez.
- **`IDeviceProvider::start(sessionId, target)`:**
  - Hedef artık bağlanırken verilir.
  - `DeviceSession::setTarget()` hedefi tutar; `connectDevice()` bu hedefle başlatır.
- **`ConnectionStore`** (`device/session`):
  - Hizmet başına son ayarı saklar; anahtar `connection/<hizmet>/...`.
  - Kayıtlı değer geçersizse ayar yok sayılır.
  - Yazma hatasında bildirim gösterilir.
- **`TransportProvider`** (`device/transport`):
  - Seri portu ya da UDP soketini açar.
  - Protokol yok: "Connected" yalnızca bağlantının açık olduğu anlamına gelir. Gelen baytlar çözülmez, örnek üretilmez.
  - Port açılamazsa ya da adres geçersizse hata verir. Sonuç hiçbir zaman `start()` içinden eşzamanlı bildirilmez.
  - Çalışırken port kaybolursa (ör. kablo çıkarsa) hata verir.
  - Otomatik yeniden deneme yoktur (kural 3–4).
- **Gerçek uygulama:** `DisconnectedProvider` yerine `TransportProvider` kullanır.
- **Açılış** (kural 2):
  - Kayıtlı ayar varsa otomatik bağlanılır.
  - Demo uygulaması ayar gerektirmez, her zaman bağlanır.
- **"Bağlantı kapandı" bildirimi:** Bugün gerekmiyor. Seri port ve UDP soketi eşzamanlı kapanıyor.
  - shortcut: Arka planda kapanan bir taşıma gelirse eklenecek.
- **Kapsam dışı:** Bağlantı penceresi ve elle bağlan/kes arayüzü (17b), IDS Image hizmeti.

## Test
- **`tst_transportprovider`:**
  - Port seçilmemiş veya olmayan bir port: hata.
  - Geçersiz UDP adresi: hata.
  - Loopback UDP: bağlı.
  - Sonuç hiçbir zaman eşzamanlı gelmez.
  - `stop` tekrar çağrılabilir.
- **`tst_connectionstore`:**
  - Seri ve UDP ayarları kaydedilip geri okunur.
  - Geçersiz kayıt yok sayılır.
  - Hiç ayarı olmayan hizmet için sonuç boş.
  - Yazma hatası bildirilir.
- **`tst_devicesession`:** Hedef sağlayıcıya iletilir.
