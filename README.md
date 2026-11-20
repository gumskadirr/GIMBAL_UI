# IDS Gimbal

Pan-tilt gimbal'ları ayarlamak, izlemek ve sınamak için masaüstü uygulaması (Qt 6.12, QML + C++). İki cihaz hizmetine aynı anda bağlanır:

- **Main control:** UART ya da IP/UDP. Gimbal bilgisi, motor kontrolü, gimbal ayarları ve ısıtıcı sayfaları.
- **IDS Image:** yalnız IP/UDP. Görüntü ve kontrol, hizalama, hatalar ve gimbal durumu sayfaları.

Arayüz tamamlandı. **Gerçek cihaz protokolü henüz yazılmadı:** gerçek uygulama bağlantıyı açar ama veri çözmez, komut göndermez. Bütün özellikler demo uygulamasında örnek veriyle çalışır. Devralan için başlangıç noktası [`docs/devir.md`](docs/devir.md).

## Hızlı başlangıç (Windows)

Gerekenler: Qt 6.12.0 MinGW 64-bit, Qt'nin CMake ve Ninja'sı (Qt Maintenance Tool ile kurulur), Git Bash, Python 3 (çeviri ve belge denetimi için). Qt Quick 3D modülü kurulu olmalı.

```bash
export PATH="/c/Qt/6.12.0/mingw_64/bin:/c/Qt/Tools/mingw1310_64/bin:/c/Qt/Tools/CMake_64/bin:/c/Qt/Tools/Ninja:$PATH"
cmake -S . -B build/cli-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build/cli-debug -j 2
./build/cli-debug/appIDS_GIMBALDemo.exe     # örnek veriyle demo
./build/cli-debug/appIDS_GIMBAL.exe         # gerçek hedef (protokolsüz)
bash tools/verify.sh                        # birleştirmeden önce tam denetim
```

Qt başka bir klasördeyse `QT_ROOT` ortam değişkeniyle verilir (`tools/verify.sh`, `tools/appcheck.ps1`). Qt Creator ile de açılabilir: `CMakeLists.txt`.

## Klasörler

| Klasör | İçerik |
|---|---|
| `app/` | Uygulama çerçevesi: `Main.qml` (sayfa kaydı, üst çubuk, gimbal ve bağlantı pencereleri), `AppRunner` (nesneleri kurar ve bağlar), durum çubuğu, tercihler |
| `device/api/` | Cihaz sözleşmesi: `IDeviceProvider`, komutlar (`DeviceCommand.h`), okunan veriler (`DeviceTypes.h`), parametre anahtarları |
| `device/session/` | Hizmet başına oturum (`DeviceSession`), bağlantı ayarlarının saklanması (`ConnectionStore`) |
| `device/transport/` | Gerçek hedefin seri/UDP taşıması (`TransportProvider`); protokol buraya yazılacak |
| `device/presentation/` | QML'e verilen sunum modelleri: `ServiceConnection`, `MainControlViewModel`, `ImageViewModel`, `ParameterModel`, `SeriesBuffer` |
| `features/maincontrol/`, `features/idsimage/` | Sayfalar |
| `features/telemetry/` | Elle CSV kaydı, script dosyası ve oynatıcı, gerçek zamanlı grafik penceresi |
| `features/gimbal3d/` | 3B gimbal görünümü ve uygulamayla gelen ZR10 modeli |
| `shared/` | Tema ve ortak kontroller (`shared/ui`), ayarlar ve gimbal kütüphanesi (`shared/settings`), dil, bildirimler |
| `test/` | Birim testleri (`unit/`), QML testleri (`qml/`), demo ve test sağlayıcıları (`doubles/`), demo uygulaması (`app/`) |
| `tools/` | Doğrulama betikleri, çeviri doldurma, protokol belgesi denetimi, ekran görüntüsü aracı |
| `translations/` | Türkçe çeviri (`IDS_GIMBAL_tr.ts`) |
| `docs/` | Belgeler (aşağıda) |

## Belgeler

| Belge | Ne için |
|---|---|
| [`docs/devir.md`](docs/devir.md) | **Buradan başlayın.** Durum, kalan işler, bilinen sorunlar, onay bekleyen kararlar |
| [`docs/mimari.md`](docs/mimari.md) | Kodun bugünkü yapısı: katmanlar, veri akışı, sayfa ekleme, gimbal kütüphanesi ve 3B |
| [`docs/gelistirme.md`](docs/gelistirme.md) | Günlük iş: derleme, test, lint, çeviri, ekran görüntüsü, çalışma kuralları |
| [`docs/protokol-siniri.md`](docs/protokol-siniri.md) | Protokolü yazacak kişi için sözleşme: her komut, alan ve beklenen test |
| [`docs/kararlar.md`](docs/kararlar.md) | Tarihli bütün kararlar ve gerekçeleri |
| [`docs/mimari-gerekce-v1.2.md`](docs/mimari-gerekce-v1.2.md) | Mimari belge v1.2: hedefler, ilkeler, aşamalar, açık konular |
| `docs/plan.md`, `docs/inceleme.md`, `docs/sabah-raporu.md`, `docs/superpowers/` | Geçmiş planlar ve raporlar (tarihî kayıt) |

Tasarım kaynağı depo dışında: `../taslak/` (PDF ve HTML ekranlar), `../ui_notlar.pdf`. ZR10 modelinin kaynak dosyaları `../3D/`.
