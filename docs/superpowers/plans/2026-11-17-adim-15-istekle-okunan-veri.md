# Adım 15 — Akış telemetrisi ve istekle okunan veri ayrımı

**Hedef:** Bir kez ya da istek üzerine okunan cihaz bilgisini akış telemetrisinden ayırmak. Böylece bu bilgi 1 sn sonra "bayat" sayılıp silinmez.

**Kaynak:** Fable incelemesi, gidişat önerisi 2. Kullanıcı onayı: 2026-11-17.

**Dayanak:** `../gimbal-nihai-mimari-v1.1.md` Bölüm 7 (gösterim alanları geçerlilik bayraklı, uydurma yok) ve Bölüm 12 (oturum kimliği).

## Kararlar
- **`DeviceSample`:** Yalnızca akış telemetrisi. Değişmez; `DeviceViewModel` 1 sn sonra bayat sayar.
- **Yeni `BoardInfo`:**
  - Kimlik ve MCU bilgisi: Device ID, Firmware, Model, MCU Device ID, UID, Flash size, Bootloader version, Board ID.
  - Alanların hepsi `TextValue` türünde: metin + geçerlilik bayrağı.
  - Oturum boyunca geçerli kalır; zamanla bayatlamaz.
  - Yeni oturumda, bağlantı kesilince ve hata durumunda silinir.
  - shortcut: Alanlar tasarımdan alındı, protokol gelince yeniden doğrulanacak.
- **Sözleşme:**
  - `IDeviceProvider::boardInfoReceived(sessionId, BoardInfo)` sinyali eklenir.
  - `DeviceSession`, eski oturum kimliğiyle gelen bilgiyi telemetride olduğu gibi atar.
  - İstek komutu (Read) bu adımda yok; komutlar protokolle gelecek.
- **"On time":** Sürekli değişen bir değer olduğu için `BoardInfo`'ya konmaz; "—" kalır.
- **Sağlayıcılar:**
  - Demo, bağlanınca tasarımdaki örnek değerleri bir kez gönderir.
  - Gerçek uygulama bağlantısız sağlayıcıyla çalıştığı için bu bilgiyi hiç almaz.
- **Kapsam dışı:** Parametreler (Read/Write/Save to flash, §13'ün üç durumu) ayrı modelle sonraki adımda.

## Test
- **`tst_devicesession`:** Etkin oturumun bilgisi iletilir, eski kimlikle gelen bilgi atılır.
- **`tst_deviceviewmodel`:**
  - Bilgi bayatlama süresinden sonra da geçerli kalır.
  - Yeni oturumda, bağlantı kesilince ve hata durumunda silinir.
- **`tst_demoprovider`:** Bağlanınca bilgi gönderilir.
- **`tst_gimbalinfo`:**
  - Kutucuklar ve MCU satırları gelen bilgiyi gösterir.
  - Bağlantı kesilince "—" olur.
