# Adım 11 — Dile göre ondalık ayıracı

**Hedef:** Arayüzdeki sayılar dile göre görünsün: Türkçede 124,496, İngilizcede 124.496. Kullanıcı kararı, 2026-11-17.

**Dayanak:** `../gimbal-nihai-mimari-v1.1.md` Bölüm 10. Dosya ve cihaz biçimleri dilden bağımsız kalır; bu adım yalnızca ekrandaki gösterimi değiştirir.

## Kararlar
- **`shared/ui/NumberFormat.qml` (singleton):**
  - `language` özelliği `Main.qml`'de `localization.language`'a bağlanır (Theme'deki gibi).
  - `fixed(value, decimals)` → `Number.toLocaleString(locale, 'f', decimals)`.
- **Uygulandığı yerler:** Özet şeridi (açı, radyan, sıcaklık, gerilim) ve Diagnostics sayfası.
- **Kapsam dışı:** Tam sayı göstergeleri (ör. "ms") dokunulmadan kalır.

## Test
- `tst_gimbalinfo`: Türkçede "124,496°", "2,1729 rad", "41,2 °C", "24,1 V".
- `tst_shell`: dil değişince `NumberFormat.language` de değişir.
