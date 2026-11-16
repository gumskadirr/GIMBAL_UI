# Adım 8 — Referans yerleşimi ekrana sığdırma (seçenek 2)

**Hedef:** Gimbal info, referans tasarımdaki yerleşimiyle birebir (kartların yeri ve sırası aynı) ekrana kaydırmasız sığsın.

**Kullanıcı kararı (2026-11-17):**
- Seçenek 2: Sayfa bütünüyle, aynı oranda küçülerek sığar.
- Yerleşim değişmez. İlk deneme (kartları 3B alanın altına taşımak) geri alındı.

## Kararlar
- **Referans yükseklik:** Sayfa kaydına `designHeight` alanı eklenir. Gimbal info için değer **937**: 1080'lik çizimden marka şeritleri (2×3), üst çubuk (60), durum çubuğu (45) ve kenar boşlukları (2×16) düşülür.
- **Küçültme kuralı:** `designHeight` verilmiş bir sayfa her zaman en az bu yükseklikte çizilir.
  - Sayfaya ayrılan alan daha kısaysa sayfa `scale` ile aynı oranda küçülür.
  - Sayfa hiç büyütülmez.
  - Genişlik alanı doldurur; ölçek yalnızca yükseklikten hesaplanır. Böylece genişlik ↔ yükseklik arasında geri besleme döngüsü olmaz.
- **`designHeight` olmayan sayfalar** (Tercihler, Diagnostics) küçültülmez.
- **Pencere:** Tam ekran açılır, çünkü 1280×800 pencere %125 ölçekli 1080p ekrana sığmıyor. En küçük boyut 800×560 olarak kalır.
- **Kaydırma:** Gimbal info'nun kendi kaydırması kalır. Yalnızca içerik bir gün 937'yi aşarsa devreye girer.

## Test
`tst_shell.qml` iki boyutta denetler: 1536×786 (%125 tam ekran) ve 1920×1050 (%100 tam ekran).
- Gimbal info'nun en alt kartı görünür alanın içinde kalır.
- Sayfanın kendi kaydırması gerekmez.
- Ölçek 1'i geçmez.
- Tercihler sayfası küçültülmez.

## Doğrulama
- Derleme, lint uyarısız, tüm CTest'ler.
- İki uygulama açılıp kapanır.
- 1536×786 ve 1920×1050'de ekran dışı görüntü alınır.
