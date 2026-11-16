# Adım 3 — Cihaz sözleşmesi, oturum ve DeviceViewModel

> Yalnız bu adımı tanımlar. Arayüz ve demo hedefi Adım 4'te.

**Spec:** `../../../../gimbal-nihai-mimari-v1.0.md` (Bölüm 7, 8, 12; Bölüm 15 madde 6 ve 9)

## Kapsam

- `device/api/`: Bağlantı durumu, ölçüm (değer + geçerli) ve örnek tipleri. Sağlayıcı sınırı `IDeviceProvider` (`start(oturumKimliği)`, `stop()`, durum ve örnek sinyalleri; her sonuç oturum kimliği taşır). Alanlar yalnız örnek açı/sıcaklıktır; protokol alanı uydurulmaz.
- `device/session/DeviceSession`: Tek aktif oturum. Her bağlanmada yeni kimlik verilir; aktif olmayan kimlikle gelen sonuç sayılır ve atılır. Sağlayıcı hata/kopma bildirirse oturum kapanır.
- `device/presentation/DeviceViewModel`: QML'e açık tek model. Bağlantı metni çevrilebilir. Ölçümler geçerli/güncel bilgisiyle sunulur. Yeni oturum ve bayatlık (1 sn) ölçümleri geçersiz yapar.
- Testler `test/unit` altında; sahte sağlayıcı test dosyasının içinde.

## Bu adımda yok

QML sayfası, demo hedefi, örnek veri üreteci, kütüphaneye bölme, gerçek seri/UDP.

## Bitti sayılması

Derleme + qmllint temiz, tüm testler (çeviri testi dahil) geçer.
