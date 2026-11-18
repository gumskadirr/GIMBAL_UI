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
- **T6 — Parametre anahtarları:** Düz `anahtar → değer` haritası; motor parametreleri `pan.` / `tilt.` önekli (Motor control tasarımındaki 20 alan × 2 motor). Tasarım aralık vermediği için geçici aralıklar: kazançlar 0–10000, ofset/sınırlar −180–180°, faz sırası 0–5, seri no ≤ 32 karakter. Protokol belgesi gelince doğrulanacak (`ParameterKeys.h` içinde `shortcut:` notu).
- **T6 — Üç durum:** Cihazdaki değerler, kullanıcı düzenlemeleri ve düzenlemelerin geldiği profil dosyası (`profileFile`). Dosyanın içeriği ayrıca saklanmaz: yüklenen dosya cihazdan farklı değerleri "unsaved" düzenleme olarak gösterir, hiçbir şey göndermez.
- **T6 — Write sonucu:** Cihaz Write'ı kabul edince yazılan değerler cihazdaki değer sayılır ve düzenlemeler sıfırlanır. Reddedilen Write düzenlemeleri korur. Oturum bitince cihaz değerleri silinir, düzenlemeler kalır (T23 çıkış uyarısı bunlara bakar).
- **T6 — Profil dosyası:** JSON `{"format":"ids-gimbal-parameters","version":1,"values":{...}}`. Bilinmeyen anahtar, aralık dışı/yanlış türde değer, başka biçim veya sürüm dosyanın tamamını reddeder; hata bildirime düşer. Metinden sayı ayrıştırılmaz (TR/EN ondalık ayıracı sayfada çözülür).
- **T6 — Kapsam:** Heater (T9) ve Gimbal settings kazançları (T10) parametre modelini kullanacaksa anahtarlarını `ParameterKeys::all()` sonuna ekler.
