# Adım 18 — Gimbal settings sayfası (grafikler hariç)

**Hedef:** Tasarımdaki Gimbal settings ekranını referans yerleşimle kurmak. Yalnızca gösterim amaçlı; komutlar ve girişler kapalı.

**Dayanak:**
- Tasarım HTML'i, sayfa 3: 1:2 düzen (3B | içerik). Sağ sütun yukarıdan aşağıya: Stream çubuğu, Script çubuğu, 4 kart (Electrical angle, LRF, IMU bias, Complementary filter), Scope kartı (kalan yükseklik).
- `../gimbal-nihai-mimari-v1.1.md` §7 (veri uydurulmaz) ve §11 (şablon, sığdırma).

## Kararlar
- **Sayfa:** `features/maincontrol/GimbalSettingsPage.qml`, kökü `ControlPageFrame`. Kayıtta "Control" grubunda, Motor control'den sonra; ikon `Icons.sliders` (tasarımdaki gibi).
- **Tercihler ikonu:** Aynı ikon menüde iki kez görünmesin diye Tercihler yeni `Icons.gear` ikonunu alır.
- **Stream çubuğu:**
  - Start/Stop stream, Record CSV, Save CSV.
  - Paket sayısı "—".
  - **Safe stop (Esc)**: tehlike görünümü, düğmenin içinde `Esc` kısayol ipucu.
  - "1 kHz" rozeti gösterilmez: akış hızı cihazdan gelecek, ayrıca 1 kHz / 2 kHz sorusu açık (§17).
- **Script çubuğu:**
  - Durum "No script loaded".
  - Dosya, satır, yüzde ve Pan/Tilt değerleri "—".
  - Start, Stop ve Details düğmeleri. Script paneli (Details) sonraki bir adımda gelecek.
- **Kartlar:**
  - Electrical angle: Raw position "—", kalibrasyon düğmesi ve uyarı satırı.
  - LRF: Laser pointer anahtarı, Check optical crosstalk düğmesi, durum "Not checked".
  - IMU bias: Gyro X/Y/Z alanları, kalibrasyon düğmesi ve açıklama satırı.
  - Complementary filter: Kp ve Ki alanları.
- **Scope kartı:**
  - Başlık, "Board mode —", sekmeler (Scope, 2 s | FFT | Bode sweep), görünüm listesi (tasarımdaki seçenekler), Pop out.
  - Grafik alanında "No stream data" yazar. Grafikler ayrı bir adımda gelecek; büyük olasılıkla yeni bir Qt modülü gerekecek ve bu kullanıcı onayı ister.
  - Gösterge açıklamaları ve ölçüm satırı (rise / overshoot / settling) grafiklerle birlikte gelir.
- **Kapalılık:** Bütün içerik `commandsAvailable` ile kapalı (Adım 10).
- **Taslaktan alınanlar:**
  - `Kbd` ve `IdsTabs` (lint düzeltmesiyle).
  - `IdsButton`'a `shortcutHint` eklenir: düğme içinde kısayol ipucu.
  - Yeni ikonlar: record, pause, expand, popOut, gear.

## Test
- **`tst_gimbalsettings.qml`:**
  - Bütün kontroller kapalı.
  - Değer alanları "—".
  - Scope'ta "No stream data".
- **`tst_shell`:**
  - Sığma testi bu sayfayı da kapsar; `designHeight` ölçülerek verilir.
  - Sayfa listesi güncellenir.
