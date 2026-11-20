# Adım 6 — Uygulama iskeleti ve sayfa kaydı

**Hedef:** Sekmeli düzeni tasarımdaki iskeletle (marka şeridi, sol menü, üst çubuk, durum çubuğu) değiştirmek ve sayfaları tek noktadan kaydetmek.

**Dayanak:** `../gimbal-nihai-mimari-v1.1.md` Bölüm 8, 9, 11, 15.1, 15.8. Kaynak: `../taslak/files/ids-qml/IdsUi/`, `examples/main.qml`.

## Kararlar (kullanıcı itiraz ederse değişir)
- **Menü:** Yalnız var olan sayfalar listelenir. "Geliştirici" grubunda Diagnostics yalnızca demo hedefinde görünür; "Uygulama" grubunda Tercihler. Tasarımdaki diğer sayfalar için boş sayfa açılmaz.
- **Bildirimler:**
  - Sağdaki sabit panel kalkar.
  - Durum çubuğunda en son bildirim önem etiketiyle (`Badge`) görünür.
  - "Bildirimler (N)" düğmesi tam listeyi `IdsPopup` içinde açar.
- **Örnek veri işareti:** Tam genişlikteki şerit kalkar; üst çubukta uyarı etiketi (`Badge`) "SAMPLE DATA" olur.
- **Bağlantı durumu:** Üst çubukta çerçeveli `StatusLabel` ve menü logosundaki nokta olarak gösterilir. TX/RX, hız, heartbeat ve port bilgisi protokol gelene dek yok.

## Görevler
1. **Kopyalanacaklar** (`shared/ui/`, lint düzeltmeleriyle): `AppShell`, `BrandStripe`, `NavRail`, `NavItem`, `NavSection`, `RailBrand`, `Shadow`, `TopBar`, `StatusBar`, `StatusBarSection`, `StatusBarButton`, `StatusLabel`, `StatusDot`, `Badge`, `IdsPopup`. Logo `assets/icons/ids_logo.png` modül kaynağı olur.
2. **Sayfa kaydı (`Main.qml`):**
   - `pages` dizisinin her girdisi `id`, `group`, `title`, `icon`, `component` ve isteğe bağlı `demoOnly` alanlarını taşır.
   - Menü ve içerik bu tek listeden üretilir; `Repeater` modeli sayı olduğu için dil değişince sayfalar yeniden oluşturulmaz.
   - Seçili sayfa kimlikle (`currentPageId`) tutulur.
   - Sayfanın etkinliği `activePageId` üzerinden belirlenir.
3. **Bildirim alanı:** `NotificationArea` popup içinde çerçevesiz kullanılabilir hale gelir. Durum çubuğundaki son bildirim, tek satır yüksekliğinde bir `ListView` ile gösterilir.
4. **Test (`test/qml/tst_shell.qml`):** Gerçek `Main`, test kurulumunun verdiği gerçek servislerle (`FakeProvider`) oluşturulur. Doğrulananlar:
   - Demo olmayan hedefte Diagnostics menüde yok, demoda var.
   - Sayfa değiştirmek sayfa nesnelerini yeniden oluşturmaz; Diagnostics yalnız seçiliyken etkin (`pageActive`).
   - Dil değişince menü başlığı ve üst çubuk değişir, sayfa nesneleri aynı kalır.
   - Yeni bildirim durum çubuğunda görünür; popup açılır ve temayı izler.
5. **Doğrulama:** Derleme, `all_qmllint` uyarısız, tüm CTest'ler (çeviri dahil), iki exe açılıp hatasız kapanır.

## Sonraki aday (kesin değil)
- 7: Gimbal info sayfası. Demo verisiyle yalnız gösterim alanları; komut düğmeleri devre dışı.
