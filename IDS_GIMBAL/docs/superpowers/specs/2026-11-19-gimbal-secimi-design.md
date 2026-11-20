# Gimbal seçim paneli — kısa tasarım (19 Kasım 2026, onaylandı)

## Amaç
Kullanıcı birden fazla pan-tilt gimbal ile çalışır. Hangi gimballe çalıştığını seçer; seçim **yalnız görünümü** değiştirir: üst çubuktaki ad ve ileride 3D model. Sayfalar, ayarlar, bağlantılar ve cihaz davranışı değişmez. Kaynak: tasarım PDF'i sayfa 6 ("Select a gimbal") ve üst çubuktaki `GIMBAL G180 · v2.0 ⌄` düğmesi.

## Kapsam dışı
- Gimbale göre sayfa, parametre ya da sınır değiştirmek.
- 3D görünümün kendisi (ayrı iş; panel kartı 3D model varsa onu gösterecek şekilde yer tutar).
- Seçim ekranındaki tema düğmeleri (üst çubukta var).

## Yaklaşımlar
- **A. Uygulamanın üstünde modal pencere (seçilen).** Üst çubuktaki düğme ve gerektiğinde açılış açar. Sol menü ve durum çubuğu arkada kalır, ayrı bir ekran akışı gerekmez.
- B. Tasarımdaki gibi uygulamadan önce tam ekran açılış ekranı. Açılışta tasarıma daha yakın, ama üst çubuktan dönüş ayrı bir ekran geçişi ister; daha çok kod.

## Tasarım
- **Gimbal listesi** tek yerde (`Main.qml`, sayfa listesi gibi): `{ id, name, versions, model }`. Başlangıç: G160 (v1.0, v2.0), G180 (v1.0, v2.0, v3.0), Kashif700 (v1.0); hiçbirinin 3D modeli yok (`model: null`).
- **Ayarlar** (`AppSettings`): `gimbal` (id), `gimbalVersion`, `gimbalOnStart` (bool, varsayılan true). Bilinmeyen id/sürüm kabuk tarafından "seçilmemiş" sayılır.
- **Üst çubuk düğmesi:** gimbal simgesi + `GIMBAL` etiketi + `ad · sürüm` + aşağı ok; seçim yoksa "Select gimbal".
- **Panel** (`GimbalSelectDialog`, `IdsPopup` tabanlı, modal, ortada):
  - Başlık "Select a gimbal", açıklama yalnız 3D görüntünün değiştiğini söyler.
  - Her gimbal bir kart: ad, seçim düğmesi, görsel alanı (3D model yoksa küp + "No 3D model"), VERSION düğmeleri.
  - **Tek seçim:** çerçeve, seçim düğmesi, vurgulanan sürüm ve alt satırdaki "Selected X · v" hep aynı (gimbal, sürüm) çiftidir. Yalnız seçili kartın sürümü vurgulanır; başka kartın sürümüne tıklamak o kartı seçer; karta tıklamak o kartın son sürümünü seçer.
  - "CURRENT" etiketi kayıtlı gimbalin kartında (tasarımdaki "LAST USED").
  - Alt satır: "Open this gimbal on start" anahtarı, "Selected …", Cancel, Continue →.
  - Cancel / Esc hiçbir şeyi değiştirmez. Continue seçimi ve anahtarı kaydeder.
- **Açılış:** kayıtlı geçerli gimbal yoksa ya da `gimbalOnStart` kapalıysa panel açılışta açılır. Bağlantı penceresi de gerekiyorsa panel kapandıktan sonra açılır.
- **Pan/Tilt adları:** IDS Image'daki "Roll" yazıları ve kod adları (`rollDeg`, `rollRateDps`, `ImageSetPosition.roll`) Pan olur (`panDeg`, `panRateDps`, `pan`). Gimbal state'teki yaw/pitch cihaz metnidir, değişmez.

## Kurucuya kalanlar
Kart ölçüleri, boşluklar ve renkler tasarım takımındaki (`Card`, `SegmentedControl`/`IdsButton`, `IdsSwitch`, `Badge`) mevcut bileşenlerle.
