# Kararlar

Otonom uygulama sırasında verilen kararlar; en yenisi altta.

- Plan 18 Kasım 2026'da kullanıcı tarafından tek onayla kabul edildi.
- Mimari §7 ile T5 arasındaki çelişki T5 lehine çözüldü: komut sözleşmesi protokolden önce arayüz + mock olarak kurulur; bkz. inceleme §3.6.
- **T2 — Etkinlik testi sayfaları:** Test Tercihler yerine Gimbal info ↔ Motor control ile yapıldı — Tercihler sayfasında `pageActive` yok, yalnız çerçeveli sayfalar etkinlik bilgisi alır.
- **T3 — Bağlantı nesnesi adları:** `ServiceConnection` alanları kısa adlarla: `statusText`, `summary`, `configured`, `target()`, `apply()`, `changed`, `applied`. QML'de `mainControl.connection.*` — nesne zaten bağlantı olduğu için "connection" öneki tekrar olurdu.
- **T4 — Hizmet listesi:** `runApp` sağlayıcıları `ServiceProviders` (anahtar → sağlayıcı) listesiyle alır; her hizmetin oturumu ve `ServiceConnection`'ı döngüde kurulur. Görünüm modeli (`MainControlViewModel`) hizmet anahtarıyla oturumunu bulur.
- **T5 — Komut türleri:** `Command::Kind` (Q_ENUM_NS) ve `Command::Status`; QML'de `Command.RunBit`, `Command.Accepted`. Dize yerine sayı: protokolcü her türü derleme zamanında eşler, belge–kod karşılaştırması tek listeden yapılır. Yeni türler sona eklenir.
- **T5 — Komut sınırı yeri:** Komutu `ServiceConnection.send(kind, args)` gönderir (hizmet başına oturumun sahibi). Aynı tür beklerken ikinci gönderim reddedilir (düğme meşgul). Bekleyen türler `pendingCommands` ile okunur.
- **T5 — Sonuç bildirimi:** `Accepted` dışındaki her sonuç bildirime düşer: `Cancelled` uyarı, diğerleri hata. Bildirimde komut adı enum anahtarıdır (ör. "RunBit"), çevrilmez — kısa ve protokol belgesiyle aynı.
- **T5 — Demo davranışı:** Demo sağlayıcı her komutu 400 ms sonra `Accepted` ile yanıtlar. Gerçek hedef (`TransportProvider`) temel sınıfın `Unsupported` davranışını kullanır ve `supportsCommands()` false döner; düğmeler kapalı kalır.
