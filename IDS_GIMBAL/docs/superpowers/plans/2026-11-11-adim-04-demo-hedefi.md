# Adım 4 — Demo hedefi, örnek veri kaynağı, doğrulama sayfası

> Yalnız bu adımı tanımlar. Görsel tasarım kullanıcıda.

**Spec:** `../../../../gimbal-nihai-mimari-v1.0.md` (Bölüm 8, 11; Bölüm 15 madde 1, 2, 6, 8, 9)

## Kapsam

- Ortak kod (shared, device, app çerçevesi, QML) tek statik kütüphane + QML modülü `ids_gimbal` (URI `IDS_GIMBAL`). Testler artık bu kütüphaneye bağlanır.
- `app/AppRunner`: `runApp(app, config, provider)` — servislerin sahibi, iki hedefin ortak başlangıcı.
- `appIDS_GIMBAL` (`app/main.cpp`): `DisconnectedProvider`; bağlan → hata bildirimi, sahte veri yok. Ayar adı `IDS_GIMBAL`.
- `appIDS_GIMBALDemo` (`test/app/main.cpp`): `test/doubles/DemoProvider`; "Örnek veri" şeridi. Ayar adı `IDS_GIMBAL_Demo`.
- `DemoProvider`: deterministik açı/sıcaklık, periyodik geçersiz sıcaklık, bir süre sonra bağlantı kopması, kapatılınca eski oturum kimliğiyle gecikmiş sonuç.
- Doğrulama sayfası (`features/diagnostics`) ve tercihler sayfası arasında geçiş; sayfa değişimi modeli/oturumu yeniden oluşturmaz, sayfanın zamanlayıcısı yalnız sayfa görünürken çalışır.

## Bu adımda yok

Görsel tasarım, her özellik için ayrı QML modülü, gerçek seri/UDP, kayıt.

## Bitti sayılması

Derleme + qmllint temiz, tüm testler geçer. Gerçek hedefin ikilisinde `DemoProvider` yok. İki hedef açılır.
