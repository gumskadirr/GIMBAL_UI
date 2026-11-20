# Protokol sınırı (devralan geliştirici için sözleşme)

Bu belge, gerçek cihaz protokolünü yazacak kişi içindir. Arayüz tarafı bitmiştir: bütün komutlar, okunan veriler ve parametreler aşağıdaki sınırdan geçer. Protokol katmanı yalnız bu sınırı uygular; arayüz bayt kodlamasını hiç bilmez, protokol arayüzün sayfalarını bilmez.

**Bu belge ile kod aynı tutulur.** `tools/check_protocol_doc.py` (ctest: `protocol_doc_matches`) şunları iki yönde karşılaştırır: `Command::Kind` ve `Command::Status` değerleri, `IDeviceProvider` metotları ve sinyalleri, `DeviceTypes.h` içindeki her yapı ve alan, `ParameterKeys.h` içindeki her anahtar. Kodda yeni komut, alan ya da anahtar eklenir ya da çıkarılırsa ilgili bölümü de güncelle, yoksa test kırılır. Başlık ve tablo biçimi denetim için sabittir: komutlar `### ` + `` `Ad` `` başlığı, tablolar ilk sütunda `` `ad` ``.

Geçici değerlerin ve doğrulanacak tahminlerin listesi en sonda ("Geçici değerler"); ayrıntılı gerekçe `docs/kararlar.md` içindedir.

## Sınır

- Dosya: `device/api/IDeviceProvider.h`. Arayüzün sağlayıcıyla tüm ilişkisi: bir oturum kimliği ve `DeviceCommand` girer, sinyaller çıkar.
- Hizmet başına bir sağlayıcı ve bir oturum vardır (Main control ve IDS Image iki ayrı bağlantı). Uygulama anahtarları: `mainControl`, `idsImage`.
- Sağlayıcı `start` ya da `send` içinden eşzamanlı sinyal yayamaz; sonuçlar olay döngüsünden gelir.
- Her sonuç `start()`'a verilen oturum kimliğini taşır.

### IDeviceProvider

| Üye | Açıklama |
|---|---|
| `start` | `start(sessionId, target)`: bağlantıyı açar (`ConnectionTarget`). Sonucu `stateChanged` ile bildirir. |
| `stop` | Bağlantıyı kapatır; tekrar çağrılabilir (idempotent). |
| `supportsCommands` | `send` komut taşıyabiliyorsa true. Arayüz komut düğmelerini yalnız o zaman açar. Varsayılan false. |
| `send` | `send(sessionId, requestId, command)`: komutu cihaza yollar; **tam bir kez** `commandFinished` ile yanıtlanır. Varsayılan gerçekleme `Unsupported` döner. |
| `trafficCounted` | `(sessionId, txBytes, rxBytes)`: oturum başından beri taşınan bayt toplamları (artış değil). Protokol gerektirmez; taşıma katmanı sayar. |
| `stateChanged` | `(sessionId, ConnectionState, detail)`: Disconnected, Connecting, Connected, Error. `detail` ham metindir, çevrilmez. |
| `sampleReceived` | `DeviceSample`: Main control akış telemetrisi. |
| `imageSampleReceived` | `ImageSample`: IDS Image telemetrisi; Main control sağlayıcısı yaymaz. |
| `boardInfoReceived` | `BoardInfo`: oturumda bir kez, istendiği an. Bayatlamaz. |
| `bitReportReceived` | `BitReport`: `RunBit` sonrası ve bağlanınca. |
| `crosstalkResultReceived` | `CrosstalkResult`: `StartCrosstalkCheck` sonrası. |
| `imuBiasReceived` | `ImuBias`: `StartImuBiasCalibration` sonrası. |
| `stepMetricsReceived` | `StepMetrics`: `StepResponse` sonrası. |
| `commandProgress` | `(sessionId, requestId, percent 0-100, stage)`: uzun komutun ilerlemesi; `stage` cihaz metnidir (Erasing, Writing, Verifying). Son yanıt yine `commandFinished` ile gelir. |
| `parametersReceived` | `(sessionId, QVariantMap)`: tüm ya da bazı parametre anahtarlarının değeri (ör. `ReadParameters`, `RestoreDefaultParameters` sonrası). |
| `commandFinished` | `(sessionId, requestId, CommandResult)`: komutun sonucu (aşağıda "Sonuç durumları"). |

### TransportProvider (gerçek hedef)

- Dosya: `device/transport/TransportProvider.{h,cpp}`. Seri port ya da UDP soketini açar; "Connected" yalnız bağlantının açık olduğunu söyler.
- Şu an **komut desteklemez** (`supportsCommands()` false): düğmeler kapalı kalır, değerler "—" görünür. Gelen baytlar sayılıp atılır; hiçbir örnek ya da yapı üretilmez.
- `write(bytes)` dışarı çıkışın tek yoludur ve TX olarak sayılır; protokol bunu kullanacak.
- Otomatik yeniden bağlanma yoktur: açılamayan ya da kopan bağlantı oturumu `Error` ile bitirir.
- Protokol yazılırken: `supportsCommands()` true döner, `send` her komutu kodlayıp yazar; gelen baytlar çözülüp yukarıdaki sinyallere çevrilir.

### DeviceSession kuralları

Dosya: `device/session/DeviceSession.{h,cpp}` (protokolcü değiştirmez; sağlayıcıdan bunu bekler).

1. **Oturum kimliği:** her `connectDevice()` yeni bir kimlik (1'den artan) verir ve `start`'a iletir. Etkin kimlik dışındaki her sonuç sayılır (`staleDropped`) ve **düşürülür**: eski oturumun geç gelen örneği, durumu, yanıtı ya da ilerlemesi yeni oturumu değiştiremez.
2. Sağlayıcı kimliği olduğu gibi geri vermelidir; kimlik 0 geçerli değildir.
3. **Bekleyen komutlar:** `send` yalnız bağlıyken ve sağlayıcı komut destekliyorsa istek kimliği (> 0) verir; yoksa 0 döner. Her komut yanıtlanana dek bekleyendir. Aynı istek ikinci kez yanıtlanırsa ikincisi yok sayılır.
4. **Oturum sonu:** bağlantı kesilince, sağlayıcı `Error`/`Disconnected` bildirince ya da yeniden bağlanınca bütün bekleyen komutlar `Cancelled` ile biter. Bundan sonra gelen yanıtlar eski kimlikli olduğundan düşer.
5. **Aynı tür tek:** `ServiceConnection.send(kind, args)` aynı türden bir komut beklerken ikinciyi reddeder (false). `ImageSetStreamSetting` tek tür olduğundan akış ayarları birbirini bekler.
6. Okunan veriler (`BoardInfo`, `BitReport`, sonuçlar) yalnız etkin oturumdan kabul edilir ve oturum bitince arayüzde temizlenir. Telemetri (`DeviceSample`, `ImageSample`) 1 sn gelmezse bayat sayılıp temizlenir.
7. `Accepted` dışındaki her sonuç bildirime düşer (`Cancelled` uyarı, diğerleri hata); bildirimde komut adı bu belgedeki enum adıdır.

### Sonuç durumları

`CommandResult { status, detail }`; `detail` ham cihaz/sağlayıcı metnidir ve çevrilmez.

| Durum | Anlam |
|---|---|
| `Accepted` | Cihaz komutu yaptı ya da onayladı. |
| `Rejected` | Cihaz reddetti; `detail` neden. |
| `Failed` | Gönderildi ama geçerli yanıt gelmedi (zaman aşımı, taşıma hatası). |
| `Cancelled` | Yanıttan önce oturum bitti (oturum üretir; sağlayıcı da yayabilir). |
| `Unsupported` | Sağlayıcı bu türü gönderemez (protokol yok). |

## Komutlar

Her komut `DeviceCommand { kind, args }`. Aksi yazılmadıkça yanıt tek `commandFinished`'dır; arayüz başarı için `Accepted` bekler. "Onay" T22'dir: onay penceresi arayüzde açılır, protokol bilmez. "Gönderen" arayüzdeki sayfa ve düğmedir. QML'de `Command.<Ad>`.

### `AskBootloader`
- Ne yapar: karttan önyükleyiciye girmesini ister.
- Argüman: yok.
- Yanıt: sonuç. Ardından telemetride `DeviceSample.inBootloader` true olmalıdır.
- Gönderen: Gimbal info, "Ask bootloader". Onay: evet (uyarı: normal çalışma kesilir).

### `ExitBootloader`
- Ne yapar: önyükleyiciden uygulamaya döner.
- Argüman: yok.
- Yanıt: sonuç; sonra `inBootloader` false.
- Gönderen: Gimbal info, "Exit bootloader". Onay: hayır.

### `StartBootBridge`
- Ne yapar: seçilen alt kart için önyükleme köprüsü açar.
- Argüman: `board`: QString ("pan" | "tilt", alt kartın adı; liste şimdilik sayfada sabit).
- Yanıt: sonuç.
- Gönderen: Gimbal info, "Start boot bridge". Onay: evet (uyarı: köprü açıkken normal çalışma kesilir).

### `RunBit`
- Ne yapar: yerleşik testi (BIT) çalıştırır.
- Argüman: yok.
- Yanıt: sonuç, ardından `bitReportReceived(BitReport)`. Bağlanınca da bir rapor gelmelidir.
- Gönderen: Gimbal info, "Run BIT". Onay: hayır.

### `ReadParameters`
- Ne yapar: parametreleri cihazdan okur.
- Argüman: `prefix`: QString, isteğe bağlı (yalnız bu önekle başlayan anahtarlar, ör. "heater."; yok = hepsi).
- Yanıt: `parametersReceived(QVariantMap)` (istenen anahtarlar), sonra sonuç.
- Gönderen: Motor control "Read"; Motor control, Heater ve Gimbal settings sayfa açılışında bağlantı başına bir kez (`prefix` yok / "heater." / "gimbal."). Onay: hayır.

### `WriteParameters`
- Ne yapar: değişen parametreleri cihaza yazar.
- Argüman: `values`: QVariantMap (anahtar → değer; yalnız değişenler; türler `ParameterKeys` ile aynı).
- Yanıt: sonuç. `Accepted` = cihaz artık yazılan değerleri tutuyor (arayüz düzenlemeleri sıfırlar); `Rejected` düzenlemeleri korur.
- Gönderen: Motor control "Write" (tümü), Heater "Set" (yalnız "heater."), Gimbal settings Kp/Ki (Enter ya da odak kaybı, "gimbal."). Onay: hayır.

### `SaveParametersToFlash`
- Ne yapar: cihazdaki geçerli parametreleri kalıcı belleğe yazar.
- Argüman: yok.
- Yanıt: sonuç.
- Gönderen: Motor control "Save to flash". Onay: evet (geri alınamaz uyarısı).

### `RestoreDefaultParameters`
- Ne yapar: fabrika değerlerini yükler.
- Argüman: yok.
- Yanıt: `parametersReceived` (yeni değerler), sonra sonuç.
- Gönderen: Motor control "Defaults". Onay: evet (kırmızı, geri alınamaz).

### `UpdateFirmware`
- Ne yapar: yazılım dosyasını karta yazar.
- Argüman: `file`: QString (yerel dosya yolu; protokol dosyayı okuyup yollar).
- Yanıt: `commandProgress` (%0-100; aşama metni cihazdan: Erasing/Writing/Verifying), bitince sonuç.
- Gönderen: Gimbal info "Update firmware" (dosya seçiliyken). Onay: evet (kırmızı). Çıkışta bekleyen güncelleme uyarısı vardır (T23).

### `CancelFirmwareUpdate`
- Ne yapar: süren güncellemeyi iptal eder.
- Argüman: yok.
- Yanıt: sonuç; iptal edilen `UpdateFirmware` kendi sonucunu `Cancelled` (ya da cihaz yanıtı) ile bitirir.
- Gönderen: Gimbal info "Cancel" (yalnız güncelleme sürerken). Onay: hayır.

### `SetControlMode`
- Ne yapar: kontrol modunu seçer.
- Argüman: `mode`: int (0 Torque, 1 Speed, 2 Position; liste şimdilik sabit, cihazdan okunmaz).
- Yanıt: sonuç.
- Gönderen: Motor control "Control mode" listesi; Script penceresi "Set motor". Onay: hayır.

### `SelectMotor`
- Ne yapar: kontrol komutlarının süreceği motoru seçer.
- Argüman: `motor`: QString ("pan" | "tilt").
- Yanıt: sonuç.
- Gönderen: Motor control "Current motor" listesi. Onay: hayır.

### `ToggleLatch`
- Ne yapar: güvenli kontrol mandalının durumunu değiştirir.
- Argüman: yok.
- Yanıt: sonuç; durum telemetriden gelir (`DeviceSample.safeControlLocked`).
- Gönderen: Motor control "Toggle latch". Onay: hayır.

### `StartControl`
- Ne yapar: seçili motorda kontrolü başlatır.
- Argüman: yok.
- Yanıt: sonuç.
- Gönderen: Motor control "Start control". Onay: hayır.

### `StopControl`
- Ne yapar: kontrolü durdurur.
- Argüman: yok.
- Yanıt: sonuç.
- Gönderen: Motor control "Stop control"; Script penceresi "Close motor". Onay: hayır.

### `SetReference`
- Ne yapar: seçili motorun referansını ayarlar.
- Argüman: `type`: QString ("torque" | "speed" | "position"), `value`: double (sırasıyla %, deg/s, deg).
- Yanıt: sonuç.
- Gönderen: Motor control "Set" ve "Keyboard control" (her tuş basışı, adım 1). Onay: hayır. Aralıklar geçici: Torque ±100, Speed ±360, Position ±180.

### `ResetReference`
- Ne yapar: referansı sıfırlar.
- Argüman: `type`: QString (`SetReference` ile aynı).
- Yanıt: sonuç.
- Gönderen: Motor control "Reset". Onay: hayır.

### `StartStream`
- Ne yapar: cihazın akış verisini (scope) başlatır.
- Argüman: yok.
- Yanıt: sonuç; durum `DeviceSample.streaming` ile gelir.
- Gönderen: Gimbal settings "Start stream". Onay: hayır.

### `StopStream`
- Ne yapar: akışı durdurur.
- Argüman: yok.
- Yanıt: sonuç; `streaming` false.
- Gönderen: Gimbal settings "Stop stream". Onay: hayır.

### `SafeStop`
- Ne yapar: güvenli durdurma.
- Argüman: yok.
- Yanıt: sonuç. **Onay istenmez**, her zaman bir basış uzakta olmalıdır; Esc kısayolu aynı yoldan gider.
- Gönderen: Gimbal settings "Safe stop". Onay: hayır.

### `StartElectricalAngleCalibration`
- Ne yapar: elektriksel açı kalibrasyonu (motorlar döner).
- Argüman: yok.
- Yanıt: `commandProgress` (%0-100), bitince sonuç. `DeviceSample.rawPosition` akışla gelmeye devam eder.
- Gönderen: Gimbal settings, kalibrasyon düğmesi. Onay: evet.

### `StartCrosstalkCheck`
- Ne yapar: optik çapraz konuşma denetimi.
- Argüman: yok.
- Yanıt: `commandProgress`, `crosstalkResultReceived(CrosstalkResult)`, sonuç.
- Gönderen: Gimbal settings, crosstalk düğmesi. Onay: evet.

### `StartImuBiasCalibration`
- Ne yapar: IMU jiroskop ofsetini ölçer.
- Argüman: yok.
- Yanıt: `commandProgress`, `imuBiasReceived(ImuBias)`, sonuç.
- Gönderen: Gimbal settings, bias düğmesi. Onay: evet.

### `StepResponse`
- Ne yapar: basamak yanıtı ölçümü başlatır.
- Argüman: `direction`: int (+1 ya da -1).
- Yanıt: sonuç, `stepMetricsReceived(StepMetrics)`.
- Gönderen: Gimbal settings, `+` / `-` tuşları ya da ipuçları. Onay: hayır.

### `ScriptPoint`
- Ne yapar: oynatılan script'in bir satırını sürer.
- Argüman: `type`: QString (`SetReference` ile aynı), `pan`: double ve/veya `tilt`: double (hareket eden eksenler; %, deg/s, deg). Kapalı eksen komutta yer almaz.
- Yanıt: sonuç. **Saniyede birçok gelir**, cihaz hızlı yanıtlamalıdır; önceki nokta yanıtsızken yeni nokta reddedilir ve yeniden denenir. `Rejected`/`Failed` script'i durdurur.
- Gönderen: Script oynatıcı (`ScriptRunner`; Gimbal settings, Script penceresi "Start"). Onay: hayır.

### `ImageSetStreamSetting`
- Ne yapar: IDS Image akış ayarlarının tamamı için tek tür.
- Argüman: `setting`: QString, `value` türü ayara göre. View & control: "zoom", "blend", "brightness", "contrast" (double), "streamMode", "polarity", "ffcMode" (int, seçenek indeksi), "overlay", "skyUp" (bool). Alignment: "camera" (0 CMOS, 1 Thermal), "focusMode" (0 Auto, 1 Manual), "imageScale" (double), "fovGain" (double, +inf = sonsuz), "stabilization" (bool), "gainMode", "irisMode", "shutterMode" (0 Manual, 1 Auto).
- Yanıt: sonuç; cihazın tuttuğu değer sonraki `ImageSample` ile gelir (sayfa hep telemetriyi gösterir).
- Gönderen: View & control ve Alignment kaydırıcı/seçim/anahtarları; bırakınca gider. Biri beklerken diğer akış ayarları kapalıdır. Onay: hayır.

### `ImageTriggerNuc`
- Ne yapar: düzgünsüzlük düzeltmesi (shutter) tetikler.
- Argüman: yok.
- Yanıt: sonuç.
- Gönderen: View & control "NUC". Onay: hayır.

### `ImageAttitudeEnable`
- Ne yapar: duruş (attitude) kontrolünü açar/kapatır.
- Argüman: `enabled`: bool (cihazın `attitudeEnabled` durumunun tersi).
- Yanıt: sonuç; durum telemetriden.
- Gönderen: View & control Attitude "Enable/Disable". Onay: hayır.

### `ImageSetControlDevice`
- Ne yapar: kontrol aygıtını seçer.
- Argüman: `device`: QString ("keyboard" | "joystick").
- Yanıt: sonuç; durum `controlDevice`.
- Gönderen: View & control kontrol aygıtı seçimi. Onay: hayır.

### `ImagePark`
- Ne yapar: gimbalı park konumuna alır ("P" düğmesi; tasarım okuması, doğrulanacak).
- Argüman: yok.
- Yanıt: sonuç.
- Gönderen: View & control "P" (erişilebilir ad "Park position"). Onay: hayır.

### `ImageSetPosition`
- Ne yapar: gimbal konumunu ayarlar.
- Argüman: `pan`: double, `tilt`: double (deg; geçici aralık pan ±180, tilt ±90).
- Yanıt: sonuç.
- Gönderen: View & control konum kutuları (Enter / Set). Onay: hayır.

### `ImageResetPosition`
- Ne yapar: konumu sıfırlar.
- Argüman: yok.
- Yanıt: sonuç.
- Gönderen: View & control "Reset". Onay: hayır.

### `ImageLrfPointer`
- Ne yapar: lazer mesafe ölçer (LRF) işaretçisini açar/kapatır.
- Argüman: `enabled`: bool.
- Yanıt: sonuç; durum `lrfPointer`.
- Gönderen: View & control LRF anahtarı. Onay: hayır.

### `ImageLrfMeasure`
- Ne yapar: LRF ölçümü başlatır.
- Argüman: `mode`: QString ("single" | "continuous").
- Yanıt: sonuç; mesafe `lrfDistanceM` ile gelir.
- Gönderen: View & control LRF "Start". Onay: hayır.

### `ImageBoxSize`
- Ne yapar: izleme kutusunu büyütür/küçültür.
- Argüman: `delta`: int (+1 büyük, -1 küçük).
- Yanıt: sonuç.
- Gönderen: View & control Box +/-. Onay: hayır.

### `ImageTrack`
- Ne yapar: hedef izlemeyi başlatır.
- Argüman: yok.
- Yanıt: sonuç.
- Gönderen: View & control "Track". Onay: hayır.

### `ImageFollowTarget`
- Ne yapar: hedefi takip etmeyi açar/kapatır.
- Argüman: `enabled`: bool.
- Yanıt: sonuç; durum `followTarget`.
- Gönderen: View & control "Follow" anahtarı. Onay: hayır.

### `ImageSetFocus`
- Ne yapar: odak mesafesini ayarlar.
- Argüman: `distance`: double (m; +inf = "INF" düğmesi, sonsuz odak; geçici aralık 0 < d <= 100000).
- Yanıt: sonuç; değer `focusDistanceM`.
- Gönderen: Alignment odak "Set" ve "INF". Onay: hayır.

### `ImageWriteOffset`
- Ne yapar: görüntü ofsetini ve ölçeğini cihaza yazar.
- Argüman: `x`: int, `y`: int (piksel; geçici ±100), `scale`: double (geçici 0,5-2,5).
- Yanıt: sonuç; değerler `offsetX`, `offsetY`, `imageScale`.
- Gönderen: Alignment "Write offset". Onay: evet.

### `ImageCameraStep`
- Ne yapar: kamera kazancı, iris ya da deklanşörü bir adım değiştirir.
- Argüman: `param`: QString ("gain" | "iris" | "shutter"), `delta`: int (+1, -1).
- Yanıt: sonuç.
- Gönderen: Alignment kamera -/+ düğmeleri. Onay: hayır.

### `ImageSetIp`
- Ne yapar: cihazın IP ayarını değiştirir.
- Argüman: `dhcp`: bool, `address`: QString (IPv4; DHCP açıkken boş).
- Yanıt: sonuç; durum `dhcp`, `ipAddress`.
- Gönderen: Errors, IP settings "Set" (alanda Enter de aynı yoldan). Onay: evet.

### `ImageGimbalState`
- Ne yapar: Gimbal state akışını başlatır, durdurur ya da hızını değiştirir.
- Argüman: `running`: bool, `rateHz`: int (1, 5 ya da 10).
- Yanıt: sonuç; çalışıp çalışmadığı yalnız `stateStreaming` telemetrisinden okunur.
- Gönderen: Gimbal state "Start/Stop" ve hız seçimi (akış çalışırken hız değişirse yeni hızla `running: true`). Onay: hayır.

## Okunan veri yapıları

Dosya: `device/api/DeviceTypes.h`. Kural: **veri yoksa `valid` false'tur** ve arayüz "—" gösterir; 0 değeri "okuma yok" anlamına gelmez. Cihaz metinleri (kimlik, sürüm, hata adı) olduğu gibi gelir, çevrilmez. Alan adları, birimleri ve ölçekleri tasarımdan alınmıştır; protokol belgesi gelince yeniden doğrulanacaktır (kodda `shortcut:` notu).

### `Measurement`

| Alan | Tür | Birim / not |
|---|---|---|
| `value` | double | Alanın kendi birimi |
| `valid` | bool | false = okuma yok |

### `Flag`

| Alan | Tür | Birim / not |
|---|---|---|
| `value` | bool | |
| `valid` | bool | false = bilinmiyor |

### `TextValue`

| Alan | Tür | Birim / not |
|---|---|---|
| `value` | QString | Cihazın bildirdiği metin |
| `valid` | bool | false = yok |

### `DeviceSample`

Main control akış telemetrisi (`sampleReceived`; demo 100 ms'de bir). Her alan kendi `valid` bayrağını taşır. Gelmesi 1 sn kesilirse arayüz bayat sayar.

| Alan | Tür | Birim / not |
|---|---|---|
| `panDeg` | Measurement | deg, pan ölçülen açı |
| `panRefDeg` | Measurement | deg, pan referansı |
| `tiltDeg` | Measurement | deg |
| `tiltRefDeg` | Measurement | deg |
| `gimbalTempC` | Measurement | °C |
| `imuTempC` | Measurement | °C |
| `supplyVoltageV` | Measurement | V |
| `safeControlLocked` | Flag | güvenli kontrol mandalı kilitli |
| `onTimeS` | Measurement | s, güç açıldığından beri |
| `inBootloader` | Flag | true: önyükleyici; false: uygulama çalışıyor |
| `streaming` | Flag | cihaz scope verisini akıtıyor |
| `streamRateHz` | Measurement | Hz, cihaz bildirir (1 kHz ya da 2 kHz) |
| `packetCount` | Measurement | adet |
| `rawPosition` | Measurement | enkoder sayımı (elektriksel açı kalibrasyonu) |
| `boardMode` | TextValue | ham metin, ör. "Speed" |
| `panRateDps` | Measurement | deg/s |
| `panRateRefDps` | Measurement | deg/s |
| `tiltRateDps` | Measurement | deg/s |
| `tiltRateRefDps` | Measurement | deg/s |
| `panTorqueA` | Measurement | A (Iq) |
| `tiltTorqueA` | Measurement | A (Iq) |

### `BoardInfo`

Oturumda bir kez okunur (`boardInfoReceived`), bayatlamaz, oturumla silinir. Hepsi TextValue (cihaz metni).

| Alan | Tür | Birim / not |
|---|---|---|
| `deviceId` | TextValue | ör. "0x1A42" |
| `firmware` | TextValue | sürüm, ör. "v2.4.1" |
| `firmwareBuilt` | TextValue | derleme tarihi, cihazın yazdığı biçim |
| `model` | TextValue | kart modeli |
| `mcuDeviceId` | TextValue | MCU kimliği |
| `uid` | TextValue | MCU benzersiz kimliği |
| `flashSizeKb` | TextValue | KB (metin) |
| `bootloaderVersion` | TextValue | önyükleyici sürümü |
| `boardId` | TextValue | kart kimliği |

### `ImageSample`

IDS Image telemetrisi (`imageSampleReceived`). Ayarlar, cihazın şu an tuttuğu değerlerdir; sayfa hiçbir zaman kullanıcının son istediğini göstermez. Seçenek ayarları indekstir.

| Alan | Tür | Birim / not |
|---|---|---|
| `panDeg` | Measurement | deg |
| `tiltDeg` | Measurement | deg |
| `panRateDps` | Measurement | deg/s |
| `tiltRateDps` | Measurement | deg/s |
| `fps` | Measurement | kare/s |
| `zoom` | Measurement | x (1-10) |
| `blend` | Measurement | 0-255 |
| `brightness` | Measurement | 0-255 |
| `contrast` | Measurement | 0-255 |
| `streamMode` | Measurement | indeks: 0 Visible, 1 Thermal, 2 Blend |
| `polarity` | Measurement | indeks: 0 White hot, 1 Black hot |
| `ffcMode` | Measurement | indeks: 0 FFC manual, 1 FFC auto |
| `overlay` | Flag | akış bindirmesi açık |
| `skyUp` | Flag | gökyüzü yukarıda |
| `attitudeEnabled` | Flag | duruş kontrolü açık |
| `controlDevice` | Measurement | 0 klavye, 1 joystick |
| `lrfPointer` | Flag | LRF işaretçisi açık |
| `lrfDistanceM` | Measurement | m |
| `followTarget` | Flag | hedef takibi açık |
| `status` | TextValue | ham metin ("OK"); sayfa renklendirir |
| `mode` | TextValue | ham metin ("Locked") |
| `camera` | Measurement | indeks: 0 CMOS sensor, 1 Thermal sensor (ikincisi tahmin) |
| `focusMode` | Measurement | indeks: 0 Auto, 1 Manual |
| `focusDistanceM` | Measurement | m; sonsuz = +inf |
| `offsetX` | Measurement | piksel |
| `offsetY` | Measurement | piksel |
| `imageScale` | Measurement | x (0,5-2,5) |
| `fovGain` | Measurement | m (ofsetin kalibre edildiği mesafe); +inf = sonsuz |
| `stabilization` | Flag | Sony kamera stabilizasyonu |
| `gainMode` | Measurement | indeks: 0 Manual, 1 Auto |
| `irisMode` | Measurement | indeks: 0 Manual, 1 Auto |
| `shutterMode` | Measurement | indeks: 0 Manual, 1 Auto |
| `errors` | QVariantList | kalem başına `{group, name, state}`; `state` "ok" \| "fail" \| "unknown"; ad cihaz metni |
| `errorsValid` | bool | geçerlilik bayrağı; false = liste okunmadı |
| `dhcp` | Flag | IP'yi DHCP ile alıyor |
| `ipAddress` | TextValue | şu an tuttuğu adres |
| `stateFlags` | QVariantList | Gimbal state bayrakları `{name, value: bool}`; ad cihaz metni |
| `stateValues` | QVariantList | Gimbal state değerleri `{name, value: double}`; birim yok |
| `stateFlagsRaw` | int | ham bayrak sözcüğü (sayfa "0x" onaltılık gösterir) |
| `stateValid` | bool | geçerlilik bayrağı; false = durum okunmadı |
| `stateStreaming` | Flag | cihaz durum akışını şu an gönderiyor |

### `BitItem`

| Alan | Tür | Birim / not |
|---|---|---|
| `name` | QString | cihaz metni (ör. "Power supply") |
| `status` | int | `BitItem::Status`: 0 Pass, 1 Warning, 2 Fail |
| `description` | QString | cihaz metni |

### `BitReport`

`RunBit` sonrası ve bağlanınca gelir; oturumla silinir.

| Alan | Tür | Birim / not |
|---|---|---|
| `items` | QList<BitItem> | tasarımda 8 kalem |
| `lastRun` | QString | cihaz metni, ör. "14:20:05 at power-on"; durum çubuğu ilk sözcüğü (saati) alır |
| `valid` | bool | false = bu oturumda rapor yok |

### `CrosstalkResult`

| Alan | Tür | Birim / not |
|---|---|---|
| `passed` | bool | geçti / kaldı |
| `percent` | double | % |
| `valid` | bool | false = bu oturumda denetlenmedi |

### `ImuBias`

| Alan | Tür | Birim / not |
|---|---|---|
| `x` | double | deg/s |
| `y` | double | deg/s |
| `z` | double | deg/s |
| `valid` | bool | false = ölçülmedi |

### `StepMetrics`

| Alan | Tür | Birim / not |
|---|---|---|
| `riseMs` | double | ms |
| `overshootPct` | double | % |
| `settlingMs` | double | ms |
| `ssErrorDps` | double | deg/s, kalıcı durum hatası |
| `latencyMs` | double | ms |
| `valid` | bool | false = ölçüm yok |

### `ConnectionTarget`

Bağlantının nereye kurulacağı (saf değerler; sağlayıcıya `start` ile verilir). Cihaz verisi değildir ama sınırın parçasıdır.

| Alan | Tür | Birim / not |
|---|---|---|
| `transport` | enum | Serial ya da Udp |
| `serialPort` | QString | ör. "COM3" |
| `baudRate` | qint32 | baud, varsayılan 115200 |
| `dataBits` | int | 7 ya da 8 |
| `parity` | enum | None, Even, Odd (kayıtta "none"/"even"/"odd") |
| `stopBits` | int | 1 ya da 2 |
| `host` | QString | UDP: cihaz adresi |
| `port` | quint16 | UDP: cihaz portu |

## Parametre anahtarları

Dosya: `device/api/ParameterKeys.h`. Düz anahtar → değer haritası; cihaz, arayüz ve profil dosyası (JSON, `{"format":"ids-gimbal-parameters","version":1,"values":{...}}`) aynı anahtarları kullanır. Arayüz tür ya da aralık dışı değeri göndermez; protokol de kendi aralık denetimini yapmalıdır. **Aralıkların çoğu geçicidir** (tasarım aralık vermez); protokol belgesi gelince `ParameterKeys.h` ve bu tablo birlikte düzeltilir. Yeni anahtar listenin sonuna eklenir.

`{pan,tilt}.` her motor için iki anahtardır (`pan.torqueKp` ve `tilt.torqueKp` gibi).

| Anahtar | Tür | Aralık / not |
|---|---|---|
| `{pan,tilt}.torqueKp` | Number | 0-10000 (geçici) |
| `{pan,tilt}.torqueKi` | Number | 0-10000 (geçici) |
| `{pan,tilt}.torqueKd` | Number | 0-10000 (geçici) |
| `{pan,tilt}.speedKp` | Number | 0-10000 (geçici) |
| `{pan,tilt}.speedKi` | Number | 0-10000 (geçici) |
| `{pan,tilt}.speedKd` | Number | 0-10000 (geçici) |
| `{pan,tilt}.positionKp` | Number | 0-10000 (geçici) |
| `{pan,tilt}.positionKi` | Number | 0-10000 (geçici) |
| `{pan,tilt}.positionKd` | Number | 0-10000 (geçici) |
| `{pan,tilt}.trackerKp` | Number | 0-10000 (geçici) |
| `{pan,tilt}.trackerKi` | Number | 0-10000 (geçici) |
| `{pan,tilt}.trackerKd` | Number | 0-10000 (geçici) |
| `{pan,tilt}.modelSerial` | Text | en çok 32 karakter (geçici) |
| `{pan,tilt}.positionOffsetDeg` | Number | deg, -180 ile 180 (geçici) |
| `{pan,tilt}.electricalOffsetDeg` | Number | deg, -180 ile 180 (geçici) |
| `{pan,tilt}.forwardBorderDeg` | Number | deg, -180 ile 180 (geçici) |
| `{pan,tilt}.backwardBorderDeg` | Number | deg, -180 ile 180 (geçici) |
| `{pan,tilt}.encoderReverse` | Bool | |
| `{pan,tilt}.phaseRotation` | Integer | 0-5: faz sırası listesi (A-B-C ... C-B-A, 6 sıra; geçici) |
| `{pan,tilt}.slipRing` | Bool | |
| `heater.enabled` | Bool | ısıtıcı açık |
| `heater.g1DutyPct` | Number | %, 0-100 (tasarım) |
| `heater.g2DutyPct` | Number | %, 0-100 |
| `heater.g3DutyPct` | Number | %, 0-100 |
| `heater.tvDutyPct` | Number | %, 0-100 |
| `heater.irDutyPct` | Number | %, 0-100 |
| `gimbal.filterKp` | Number | tamamlayıcı süzgeç kazancı, 0-10000 (geçici) |
| `gimbal.filterKi` | Number | tamamlayıcı süzgeç kazancı, 0-10000 (geçici) |

Sayılar sayı olarak taşınır; metinden ayrıştırma sınırda yapılmaz (TR/EN ondalık ayracı sayfada çözülür).

## Mock noktaları

Gerçek sağlayıcı yazılana dek her şey bunlarla çalışır; protokolcü beklentiyi buradan okur.

- `test/doubles/DemoProvider` (Main control demo hedefi): 100 ms'de bir deterministik `DeviceSample`; bağlanınca `BoardInfo` ve `BitReport`; her komutu 400 ms sonra `Accepted` yanıtlar (`ScriptPoint` gecikmesiz); parametreleri cihaz gibi tutar (Read döndürür, Write değiştirir, Defaults sıfırlar; önek destekler); `UpdateFirmware` ve üç kalibrasyon ~5 sn sürer ve %0-100 ilerleme yollar (aynı anda tek uzun komut, ikincisi `Rejected`; `CancelFirmwareUpdate` `Cancelled` bitirir); `StepResponse` sonrası `StepMetrics`; `StartStream`/`StopStream` akış bayrağını değiştirir. Senaryolar: periyodik geçersiz sıcaklık, belli örnekten sonra bağlantı kopması, eski oturum kimlikli geç sonuç. Uydurma trafik üretir. **Protokolü sınamaz**; gimbal benzetimi değildir.
- `test/doubles/ImageDemoProvider` (IDS Image demo hedefi): View & control tasarım değerlerini, Errors listesini (her 30 sn'nin son 5 sn'sinde `MACB_LRF` Fail) ve Gimbal state akışını üretir; akış ayarları ve konum komutları anında uygulanır, her komut 400 ms sonra kabul edilir.
- `test/doubles/DesignErrorItems.h`, `test/doubles/DesignGimbalState.h`: Errors ve Gimbal state tasarım verisi; demo ile sahte sağlayıcı paylaşır.
- `test/unit/FakeProvider.h`: çağrıları kaydeder (`starts`, `stops`, `sent`, `lastRequestId`, `commands`); sonuçları testler doğrudan `emit provider->...` ile yayar. Oturum, düşürme, iptal ve ilerleme testlerinin temelidir. `makeFullSample()`, `makeImageSample()`, `makeBoardInfo()`, `makeBitReport()` tasarım değerli örnekler üretir.
- Gerçek hedef (`TransportProvider`) bunların hiçbirini yapmaz; bkz. yukarıda.

## Gerçek sağlayıcı için beklenen testler

Sağlayıcı yazılınca (örnek kalıplar: `tst_devicesession`, `tst_serviceconnection`, `tst_transportprovider`; bayt akışı sahte taşımayla verilir):

- **Çözme:** her komutun kodlanışı beklenen baytlara eşit; her okunan yapının alanları doğru birimde ve `valid` bayrağıyla çıkar; eksik alan `valid=false` olur (0 değil).
- **Oturum düşürme:** yeniden bağlanınca eski kimlikli örnek, yanıt, ilerleme ve durum `staleDropped`'a sayılır ve yeni oturumu değiştirmez.
- **İptal:** komut bekleyenken bağlantı kesilince ya da kopunca `Cancelled`; kopmadan sonra gelen yanıt yok sayılır.
- **Yanıt kuralı:** her `send` için tam bir `commandFinished`; zaman aşımı `Failed`; cihaz reddi `Rejected` ve `detail` dolu; iki kez yanıt yok.
- **Aralık ve tür:** `WriteParameters` aralık dışı ya da yanlış türde değeri göndermez/reddeder; `ReadParameters` önekle yalnız o anahtarları döndürür.
- **İlerleme:** `UpdateFirmware` ve kalibrasyonlarda %0-100 artan ilerleme, sonra tek sonuç; `CancelFirmwareUpdate` ile `Cancelled`.
- **Sonuç yapıları:** `RunBit` sonrası `BitReport`; kalibrasyon ve `StepResponse` sonrası ilgili sonuç yapısı.
- **Hız:** `ScriptPoint` yüksek hızda yanıt gecikmesi script saatini aşmaz.
- **Sonsuz değerler:** `ImageSetFocus` ve `fovGain` +inf'i doğru kodlar/çözer.
- **Taşıma:** TX/RX sayacı `write` ve okumayla artar; bağlanamayan port `Error` verir.
- **Belge uyumu:** yeni komut/alan eklenince `protocol_doc_matches` geçmelidir.

## Geçici değerler ve doğrulanacak tahminler

Aşağıdakiler tasarımdan ya da makul tahminden gelir; protokol belgesi gelince doğrulanıp koddan ve bu belgeden düzeltilir (ayrıntı: `docs/kararlar.md`).

- **Parametre aralıkları:** kazançlar 0-10000, ofset ve sınırlar ±180 deg, faz sırası 0-5 (6 sıra), seri no ≤ 32 karakter, süzgeç Kp/Ki 0-10000. Heater doluluk 0-100 tasarımdandır.
- **Referans aralıkları:** Position ±180 deg (tasarım), Speed ±360 deg/s, Torque ±100 %.
- **Grafik Y ekseni:** Speed ±10 deg/s (tasarım), Position ±180 deg, Torque ±10 A (geçici).
- **IDS Image aralıkları:** zoom 1-10; blend/brightness/contrast 0-255; konum pan ±180, tilt ±90 deg; ofset ±100 piksel; image scale 0,5-2,5; odak/FOV gain mesafesi 0 < m <= 100000 ya da sonsuz.
- **Sabit listeler:** kontrol modu (Torque/Speed/Position, cihazdan okunmaz), motor (Pan/Tilt), boot bridge hedefleri ("pan", "tilt"), faz sırası adları, stream mode (Visible, Thermal, Blend), polarity (White hot, Black hot), FFC (manual, auto), kamera ("CMOS sensor"; "Thermal sensor" tahmin).
- **Kesik hata adları:** Errors tasarımında kesilmiş dört ad tahminle tamamlandı: `external_pressure`, `temperature_sensor`, `core_temperature`, `humidity_sensor` (BMACB_ ön ekli). Gerçek adlar cihaz metni olarak gelmelidir.
- **Bootloader uyarı metinleri:** "Normal operation is interrupted until you exit the bootloader" ve "...while the bridge is open" tasarımda yoktur, arayüzce yazıldı; cihaz davranışıyla doğrulanmalıdır. Diğer onay penceresi metinleri de T22'de arayüzce yazıldı.
- **INF / Select yorumu:** "INF" = odağı sonsuza al (`ImageSetFocus`, +inf); "Select" = yazılan mesafeyi FOV gain olarak seç (`ImageSetStreamSetting` "fovGain"). Tasarım anlam vermiyor.
- **"P" düğmesi:** Park okuması (`ImagePark`); başka anlam çıkarsa yalnız komut adı değişir.
- **Set motor / Close motor (Script penceresi):** `SetControlMode` ve `StopControl` olarak yorumlandı; yeni komut eklenmedi.
- **Heartbeat:** protokol alanı değil, telemetri örneğinin yaşından türetilir; cihazın kendi heartbeat'i varsa değiştirilebilir.
- **Zaman damgası:** örneklerde cihaz zamanı yoktur, arayüz varış zamanıyla damgalar (grafik tamponu); cihaz zamanı gelirse değişir.
- **Akış hızı:** 1 kHz ya da 2 kHz, cihaz bildirir; arayüz 1 kHz varsaymaz.
- **Alan kaynakları:** `DeviceSample` ve `ImageSample` adları, birimleri ve ölçeği protokolden değil tasarımdan alındı; her alan yeniden denetlenmelidir. Heater çubukları ayar değerini gösterir; ölçülen güç protokolde ayrı alan gerektirebilir.
- **Gimbal state değerleri:** birim ve aralık tasarımda yok; birim yazılmaz.
- **Kapsam:** model seçimi ve TCP yoktur; IDS Image yalnız UDP.
