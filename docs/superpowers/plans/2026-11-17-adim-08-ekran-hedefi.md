# Adım 8 — Ekran hedefi ve ölçekleme yapısı

**Hedef:** Uygulama farklı ekran/ölçeklerde düzgün açılsın. Kaydırmasız hedef: **1536×816** (1080p, %125). Kaydırmayla kullanılabilir en küçük ekran: **1280×720** (1080p, %150).

**Kullanıcı kararları (2026-11-16):**
- İşletim sisteminin ölçeğine uyulur.
- Ölçeği kapatmak yok; yerleşim sıkılaştırılabilir.

## Kararlar
- **Ölçekleme:** Qt'nin varsayılanı korunur (ölçek katsayısı yuvarlanmaz). Bunun için kod yazılmaz.
- **Pencere:**
  - Tam ekran açılır.
  - En küçük boyut 1024×600 olur; bu, desteklenen en küçük ekranın altında kalan bir alt sınırdır.
- **Ortak sayfa kabı:**
  - Kaydırma Gimbal info'dan alınıp `Main.qml`'deki sayfa alanına taşınır.
  - Her sayfa, kendi içeriğinden yüksekse kendiliğinden kaydırılır.
  - Kural: sayfa kökü `implicitHeight` bildirir (Layout kök bunu kendiliğinden yapar).
- **Gimbal info yerleşimi:**
  - Firmware update ve Built-in test kartları sol sütunda, 3B alanın altına taşınır.
  - 3B alanın tercih edilen yüksekliği küçülür ve boş yer olduğunda büyür.
  - Tasarımdaki öğelerin hiçbiri çıkarılmaz.
- **Ertelenenler** (yapılmadı, istenirse sonra):
  - Pencere konumunu hatırlama.
  - Uygulamaya özel arayüz ölçeği tercihi.
  - Logonun 2x sürümü.

## Test
`tst_shell.qml`:
- Hedef pencere boyutunda (1536×786, tam ekran pencerenin iç alanı) her kayıtlı sayfa kaydırmasız sığar.
- 1280×690'da (%150) sayfalar yatayda taşmaz.

## Doğrulama
- Derleme, lint uyarısız, tüm CTest'ler.
- İki uygulama açılıp kapanır.
- Hedef boyutta ekran dışı görüntü alınır.
