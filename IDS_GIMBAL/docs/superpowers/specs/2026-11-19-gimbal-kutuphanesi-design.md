# Gimbal kütüphanesi: ekle, düzenle, sil — tasarım (19 Kasım 2026)

## Amaç
Ekip yeni gimballeri kod değiştirmeden tanımlar: seçim penceresinden gimbal ekler, düzenler, siler; 3B modeli kendi `.glb` dosyalarından yükler. Seçim yine yalnız görünümü değiştirir (üst çubuk, 3B görünüm). Kullanıcı: gimballeri tanımlayan ekip (operatör yalnız seçer).

## Hedefler / hedef dışı
- Hedef: ad, sürümler ve 3B model (taban, pan, tilt parçaları + eksenler) arayüzden; liste ve dosyalar kalıcı ve kaynak dosyalar taşınsa da bozulmaz.
- Hedef dışı: `.gltf` (dış `.bin`/doku dosyalarıyla) ve `.obj`; gimbale göre sayfa ya da ayar değiştirmek; liste dışa/içe aktarma; "varsayılanlara dön".
- Anti-hedef: bozuk ya da okunamayan liste dosyası sessizce varsayılanlarla ezilip kullanıcının gimballeri kaybolmamalı.

## Yaklaşımlar
- **A. Dosyalar uygulamanın veri klasörüne kopyalanır (seçilen).** `gimbals/<id>/` içinde `base.glb`, `pan.glb`, `tilt.glb`; liste `gimbals/gimbals.json`. Kaynak taşınsa da çalışır.
- B. Yalnız dosya yolları kaydedilir: daha az kod, dosya taşınınca model kaybolur.
- C. Elle hazırlanmış paket içe aktarılır: arayüz küçük, ama eksen konumu metin dosyasında deneme yanılma.

## Tasarım
### Depolama (`GimbalLibrary`, C++)
- `AppSettings`'in sahip olduğu nesne (`AppSettings.gimbalLibrary`); klasör ayar dosyasının yanında `gimbals/` (ini yolu verilmişse) ya da `QStandardPaths::AppDataLocation/gimbals`.
- `gimbals.json`: `[{ id, name, versions: [..], model: null | { panAxis: "x|y|z", panSign: ±1, panPivot: [x,y,z], tiltAxis, tiltSign, tiltPivot: [x,y,z], inPlace: bool } }]`. Model dosyaları her zaman `<id>/base.glb`, `pan.glb`, `tilt.glb`.
- QML'e `gimbals` (liste; model varsa dosyaların `file:` URL'leriyle). `save(gimbal, files)` ekler ya da günceller: `files` = `{ base, pan, tilt }` yeni seçilen yerel dosyalar (boş = eskisi kalır); `remove(id)` kaydı ve klasörü siler. İkisi de hata metni döndürür (boş = başarılı).
- id addan üretilir (küçük harf, harf-rakam, çakışırsa `-2`), düzenlemede değişmez.
- İlk açılışta (dosya yoksa) varsayılanlar yazılır: G160 (v1.0, v2.0), G180 (v1.0–v3.0), Kashif700 (v1.0) modelsiz; ZR10 (v1.0) uygulamayla gelen `.glb` dosyaları klasöre kopyalanarak. Mevcut kayıtlı seçim (örn. g180 / v2.0) böylece geçerli kalır.
- Dosya okunamaz ya da bozuksa: varsayılanlar bellekte kullanılır, bozuk dosya `gimbals.json.bad` olarak saklanır, kullanıcıya bildirim gider. Yazma başarısızsa bildirim (`writeFailed` gibi), değişiklik bellekte kalır.
- Doğrulama (C++'ta, arayüz de gösterir): ad boş değil ve benzersiz (büyük/küçük harf duyarsız); en az bir sürüm, sürümler benzersiz; model ya üç dosyanın hepsiyle ya hiç (yeni gimbalde); dosyalar `.glb`.

### 3B görünüm
- `GimbalModel` mesh yerine `RuntimeLoader` ile üç `.glb` yükler; malzemeler dosyadaki gibi. ZR10'un `.mesh` dosyaları ve `GimbalZR10.qml` kaldırılır, ZR10 `.glb` olarak gelir.
- Eksen: pan düğümü `panPivot`'ta (tabana göre), tilt düğümü `tiltPivot`'ta (pan parçasına göre); dönüş `axis × sign × açı`.
- **`inPlace`:** parçalar CAD montajından yerinde dışa aktarıldıysa (hepsi aynı koordinatlarda) parça, düğümün içinde pivotun tersi kadar kaydırılır; böylece kullanıcı yalnız eksen noktalarını girer. ZR10'un dosyaları eksen merkezli olduğundan ZR10 `inPlace: false`. Yeni gimbalde varsayılan açık.
- Kamera modelin sınırlarına göre otomatik yerleşir (merkez ve uzaklık; birimden bağımsız), elle girilmez. "Görünümü sıfırla" aynı yere döner.
- Yükleme hatasında (bozuk dosya) alanda "3B model yüklenemedi" ve hata metni.

### Seçim penceresi
- Her kartta ✎ Düzenle ve 🗑 Sil; sonda "+ Yeni gimbal" kartı. Kartlar kayan bir alanda (satırda 4).
- Sil: onay penceresi ("G180 ve 3B model dosyaları silinsin mi?", kırmızı Sil). Silinen gimbal seçiliyse seçim temizlenir; kayıtlı gimbal silinirse üst çubuk "Select gimbal" olur (mevcut davranış).

### Düzenleme penceresi (`GimbalEditDialog`)
- Ad, sürümler (virgülle: "v1.0, v2.0"), üç dosya alanı (Seç… → `.glb` dosya penceresi; düzenlemede mevcut dosyanın adı), pan ekseni X/Y/Z + yön, tilt ekseni + yön, pan ve tilt merkezi (x, y, z; model birimi), "Parçalar montaj konumunda" anahtarı.
- Sağda canlı önizleme ve iki kaydırıcı (pan −180…180, tilt −90…90), yalnız önizlemeyi döndürür.
- Kaydet hatalı alanları gösterir, `save()` hata döndürürse pencere açık kalır ve hatayı yazar. Vazgeç/Esc hiçbir şeyi değiştirmez.

## Kurucuya kalanlar
Pencere ölçüleri ve boşluklar mevcut bileşenlerle (IdsTextField, IdsComboBox, SegmentedControl, IdsSlider, ToggleRow, FormField, ConfirmDialog). Bildirim metinleri.

## Benim kararlarım (kullanıcı onaylı yaklaşım A'nın içinde)
Kütüphanenin `AppSettings`'e bağlı olması (testlerde ayrı geçici klasör, kabuğa yeni bağımlılık yok); yalnız `.glb`; `inPlace` anahtarı; ZR10'un `.glb`'ye geçmesi; bozuk dosyanın `.bad` olarak saklanması.
