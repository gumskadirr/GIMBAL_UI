# Adım 17b — Bağlantı arayüzü

**Hedef:** Durum çubuğundan bağlantı ayarlarının girilmesi, kaydedilmesi, bağlanma ve bağlantıyı kesme. Kayıtlı ayar yoksa pencere açılışta kendiliğinden açılır.

**Dayanak:**
- `../gimbal-nihai-mimari-v1.1.md` §12, bağlantı kuralları 1, 2 ve 5.
- Tasarımdaki `ConnectionPopup` ve durum çubuğundaki bağlantı düğmesi ("UART · COM3 · 115200 8N1").

## Kararlar
- **`shared/ui/ConnectionPopup.qml`:** Taslaktan uyarlanır.
  - Seçim UART | IP/UDP; TCP yok (17 Kasım kararı).
  - UART alanları: port, baud, data bits, parity, stop bits. Port listesi bilgisayardaki gerçek portlardan gelir; kayıtlı port takılı değilse de listede kalır. Port bulunamazsa açıklama satırı gösterilir.
  - IP/UDP alanları: IP adresi ve port (1–65535).
  - Düğmeler: Bağlantıyı kes ve Uygula. Form geçersizse Uygula kapalıdır.
  - Cihaz verisini bilmez; ayarlar dışarıdan bir harita olarak verilir.
- **`DeviceViewModel`** eklemeleri:
  - `connectionSummary`: düğmedeki kısa metin; ayar yoksa "Not configured".
  - `connectionConfigured`.
  - `connectionTarget()` → harita; `applyConnection(harita)` → hedefi ayarla, kaydet, bağlan.
  - `availableSerialPorts()`.
- **Kaydetme:** `connectionApplied` sinyalini `AppRunner` dinler ve `ConnectionStore`'a yazar.
- **Parity:** Ad ↔ değer çevirisi `DeviceTypes.h`'deki ortak yardımcılara taşınır (`ConnectionStore` ile paylaşılır).
- **Açılış:** Gerçek uygulamada ayar yoksa pencere kendiliğinden açılır. Demo uygulaması ayarsız bağlandığı için açılmaz.
- **Kapsam dışı:**
  - IDS Image düğmesi; aynı bileşenle ikinci hizmet olarak gelecek.
  - Durum çubuğundaki TX/RX ve veri hızı göstergeleri (protokol gerekiyor).

## Test
- **`tst_deviceviewmodel`:**
  - Ayarın uygulanması hedefi değiştirir ve bağlantıyı başlatır.
  - Kısa metin UART ve UDP için doğru; ayar yokken "Not configured".
  - Harita gidiş-dönüşü kayıpsız.
- **`tst_shell`:**
  - Pencerede UDP ayarı girilip Uygula'ya basılınca hedef ve düğme metni değişir.
  - Ayar yoksa gerçek uygulamada pencere açılışta açılır; demoda açılmaz.
