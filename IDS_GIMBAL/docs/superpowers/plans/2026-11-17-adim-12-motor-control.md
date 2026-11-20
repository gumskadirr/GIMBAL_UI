# Adım 12 — Motor control sayfası

**Hedef:** Tasarımdaki Motor control ekranını referans yerleşimle kurmak. Yalnız gösterim amaçlı; protokol yokken bütün giriş ve komutlar kapalı.

**Dayanak:**
- Tasarım HTML'i, sayfa 2 (paketten çıkarıldı):
  - Üç eşit sütun: 3B kartı | Motor configuration | Control.
- `../gimbal-nihai-mimari-v1.1.md`:
  - Bölüm 7: veri uydurulmaz.
  - Bölüm 11: `ControlPageFrame`.
  - Bölüm 13: parametre yönetimi sonraki aşamada.

## Kararlar
- **Sayfa:** `features/maincontrol/MotorControlPage.qml`, kökü `ControlPageFrame`.
  - Kayıtta "Control" grubunda, Gimbal info'dan sonra yer alır.
  - `designHeight` ölçülerek verilir.
- **Motor configuration sütunu:**
  - Başlık.
  - Configure [Pan|Tilt], Read, Write, Save to flash, Defaults.
  - Açıklama satırı.
  - **PID controllers** kartı: Torque/Speed/Position/Tracker × KP/KI/KD ve Model serial number.
  - **Position** kartı: Position offset, Electrical offset, Forward/Backward border, Encoder rotation [Forward|Reverse], Phase rotation, Slip ring.
- **Control sütunu:**
  - Başlık.
  - **Control** kartı: Control mode, Current motor, kilit durumu + Toggle latch, Keyboard control, Start/Stop control.
  - **Command** kartı: [Torque|Speed|Position], değer + Set + Reset, "Enter sends the value."
- **Veri:**
  - Giriş alanları boş, yer tutucu "—".
  - Açılır listeler boş.
  - Kilit durumu mevcut `safeControl` verisinden gelir:
    - Locked → "Locked · toggle latch to send"
    - Unlocked → "Unlocked"
    - Veri yok → "State unknown"
- **Kapalılık:** Sayfa içeriği tek satırla `enabled: viewModel.commandsAvailable` (Adım 10); bütün kontroller birlikte kapanır.
- **Tasarımdan alınmayanlar:**
  - "N UNSAVED CHANGES" rozeti: düzenleme yok.
  - "Range -180.000 to 180.000": cihaz sınırı, protokolden gelecek.
  - Torque birimi: bilinmiyor.
  - Liste seçenekleri (Control mode, Current motor, Phase rotation): cihazdan gelecek.
- **Yeni bileşenler** (taslaktan): `SegmentedControl` (kapalıyken soluk görünür), `IdsTextField`, `ToggleRow`, `IdsSwitch`.
- **Yeni ikonlar:** `Icons.play`, `Icons.stop` (tasarımdaki yollar).

## Test
- `tst_motorcontrol.qml`:
  - Bütün komut ve girişler kapalı.
  - Kilit durumu metni safeControl'e göre değişir.
- `tst_shell`:
  - Sığma testi `designHeight`'ı olan **her** sayfayı denetler.
  - Sayfa listesi güncellenir.
