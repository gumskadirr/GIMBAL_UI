# 3B gimbal görünümü — kısa tasarım (19 Kasım 2026, onaylandı)

## Amaç
Main control sayfalarındaki "3B gimbal modeli" alanında seçilen gimbalin 3B modeli görünür; pan ve tilt eksenleri telemetriyle döner. Yalnız gösterim: fareyle döndürmek kamerayı döndürür, gimbale komut gitmez. Kaynak: `../ZR10_3D` örneği (`GimbalModel` + `GimbalZR10`, mesh dosyaları).

## Yaklaşım (A, kullanıcı seçti)
Her gimbal küçük bir QML dosyasıdır (`GimbalModel`'i ayarlar: mesh'ler, eksen konumu ve yönü, işaret, kamera çerçevesi); `Main.qml`'deki gimbal listesinin `model` alanı bu dosyanın Component'idir. Yeni gimbal = mesh + bir QML dosyası + listeye bir satır.

## Kararlar
- **ZR10 dördüncü gimbal** (kullanıcı: seçenek a): `{ id: "zr10", name: "ZR10", versions: ["v1.0"], model }`. G160, G180, Kashif700 modelleri gelene kadar küp.
- **Eksenler:** iki eksen, pan (dikey eksen) ve tilt (yatay eksen); örnekteki üçüncü eksen, sınır ve ofset alanları alınmadı (gimbal pan-tilt). Pan/tilt işareti gimbal dosyasında (`panSign`, `tiltSign`).
- **Görünüm (`GimbalView`):** saydam arka planlı View3D (alanın noktalı zemini görünür), örnekteki ışıklar ve kamera; sol sürükle döndürür, tekerlek yakınlaştırır (`OrbitCameraController`); "Görünümü sıfırla" düğmesi. Telemetri geçersizken model son açısında kalır, "Veri yok" etiketi görünür.
- **3B desteklemeyen çizici** (yazılım çizici, pencere açmayan testler): View3D kurulmaz, alanda "3B görünüm bu grafik sürücüsünde kullanılamıyor" yazar.
- **Seçim penceresi:** kartın görsel alanı aynı `GimbalView`'u etkileşimsiz ve 0°/0° gösterir. Dört kart tek satıra sığsın diye satırda 4 kart.
- **Sayfa görünmezken** StackLayout sayfayı gizlediğinden çizim zaten durur; ek iş yok.

## Kapsam dışı
Eksen göstergesi (gizmo), fareyle komut verme, IDS Image sayfalarında 3B.
