# Adım 16 — Sayfa etkinliği ve hizmet bilgisi

**Hedef:** 17 Kasım bağlantı kararlarının ilk yarısı. Her sayfa hangi hizmete ait olduğunu ve görünür olup olmadığını bilsin. Görünüm değişmez.

**Dayanak:** `../gimbal-nihai-mimari-v1.1.md` Bölüm 11 ("yalnız görünen sayfa ekranı günceller") ve Bölüm 12 ("bağlantı kuralları").

## Kararlar
- **Hizmet bilgisi:**
  - Sayfa kaydına `service` alanı eklenir. Gimbal info, Motor control ve Heater için değeri `mainControl` olur. IDS Image sayfaları geldiğinde `idsImage` kullanılacak.
  - Hizmet adları kayıttaki `services` haritasındadır.
  - Üst çubuktaki yol, hizmeti olan sayfada "hizmet › sayfa", hizmeti olmayan sayfada (Tercihler, Diagnostics) yalnızca "sayfa" gösterir.
- **Sayfa etkinliği:**
  - `pageActive` özelliği olan her sayfaya `Main.qml` tek yerden "görünüyor mu" bilgisini verir. Diagnostics'e özel bağlama kalkar.
  - `ControlPageFrame` de `pageActive` taşır.
- **Kural** (çerçevede yorum olarak yazılır): Ağır işler (zamanlayıcılar, grafikler, video, yüksek hızlı yeniden çizim) `pageActive` false iken durur. Veri alımı ve bağlantı bundan etkilenmez.
- **Kapsam dışı:** Bağlantı arayüzü (Adım B), IDS Image hizmeti, sayfaların tembel yüklenmesi.

## Test
`tst_shell.qml`:
- Yalnız görünen sayfa etkindir; sayfa değişince etkinlik geçer.
- Üst çubuk yolu, hizmetli sayfada iki parça, hizmetsiz sayfada tek parçadır.
