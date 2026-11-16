# Adım 14 — Fable incelemesinin düzeltmeleri

**Hedef:** Fable 5.2'nin bütün proje incelemesinde bulunan, karar gerektirmeyen hataları ve test boşluklarını kapatmak. Mimari öneriler (cihaz sözleşmesini bölmek, bağlantı hedefi, hizmet kimliği, tembel yükleme, ölçekli popup kuralı) kullanıcı kararına kalır.

## Düzeltmeler
1. **Sığma testi**
   - Testler Türkçe de koşar: 4 boyut × 2 dil.
   - Her zaman doğru çıkan eşitlik kaldırılır.
   - `pageScroller` içeren **her** sayfada kaydırma gerekmediği denetlenir.
   - Heater'ın etkisiz `designHeight` değeri silinir; yine de bu testle denetlenir.
   - Motor control'ün Türkçedeki taşması, `designHeight` ölçülerek kapatılır.
2. **Komut kapalılığı testleri:** Elle yazılmış kimlik listeleri yerine ortak bir yardımcı (`test/qml/TestUtils.js`) sayfadaki her görünür, odak alabilen kontrolü bulur. Hepsinin kapalı olması gerekir.
3. **Heater testi:** Sabit "—" değerini sınayan test silinir. Gerçek alan bağlanınca yerine yenisi yazılır.
4. **`NumberFormat.fixed`:**
   - Binlik ayıracı yok.
   - "-0,000" çıkmaz.
   - Test: `tst_numberformat.qml`.
5. **`ArcGauge`:** `valid` özelliği eklenir. Veri yokken dolgu çizilmez ve ekran okuyucu "—" duyar.
6. **Servis bağlantıları:** `connectServices()` (AppRunner) uygulamada ve QML test kurulumunda aynı kod. Böylece uygulamanın kendi bağlantıları (dil kaydı, hata bildirimi) testte çalışır.
7. **Mimari belge §11:** Test cümlesi düzeltilir.
