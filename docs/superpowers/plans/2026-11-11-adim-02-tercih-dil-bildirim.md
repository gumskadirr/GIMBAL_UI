# Adım 2 — Kalıcı tercihler, Türkçe/İngilizce, bildirim alanı

> Yalnız bu adımı tanımlar. Görsel düzen kullanıcıya bırakıldı; burada yalnız işlev var.

**Spec:** `../../../../gimbal-nihai-mimari-v1.0.md` (Bölüm 10, 15 madde 4, 5, 7)

## Kapsam

- `shared/settings/AppSettings`: QSettings ile tema (`dark`/`light`) ve dil (`tr`/`en`). İlk açılış Türkçe + koyu. Geçersiz kayıt varsayılana döner. Yazma hatası `writeFailed` sinyaliyle bildirime gider.
- `shared/localization/Localization`: Kaynak dil İngilizce, Türkçe `translations/IDS_GIMBAL_tr.ts`. Yükleme başarısızsa çalışan dil korunur ve bildirim verilir. Başarıda `QQmlEngine::retranslate()` çağrılır, C++ metinleri yenilenir, seçim kaydedilir.
- `shared/notifications/NotificationModel` + `NotificationArea.qml`: Kod + argüman + önem + zaman + ham ayrıntı saklanır. Metin her gösterimde çevrilir. En fazla 50 satır tutulur, aynı bildirim tek satırda sayaçla birleşir.
- `main.cpp` servislerin sahibi; QML'e tipli `required property` olarak verir.
- `test/unit` altında üç Qt Test.

## Bu adımda yok

Görsel tasarım, sayfa düzeni, cihaz katmanı, demo hedefi, ayrı kütüphanelere bölme.

## Bitti sayılması

Derleme + qmllint temiz, üç test geçer. Dil ve tema değişir, yeniden açılışta korunur. Dil değişince ekrandaki bildirim de yeni dile geçer.
