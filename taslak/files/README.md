# IdsUi — IDS Control ortak QML bileşenleri

"IDS Main control service" tasarımındaki (10 ekran) tekrar eden tüm öğelerin Qt 6 QML karşılıkları.
Renkler, yarıçaplar, yazı boyutları tasarımdaki CSS değişkenleriyle birebir aynıdır; üç tema (light / blue / dark) `Theme.mode` ile anında değişir.

Gereksinim: Qt 6.5+ (QtQuick, QtQuick.Templates, QtQuick.Layouts, QtQuick.Shapes). Efekt modülü gerekmez; gölgeler yazılım renderer'da da çalışır.

## Kurulum

İki yoldan biri:

1. **Import path**: `IdsUi` klasörünü projeye koyun, `engine.addImportPath("<IdsUi'nin üst klasörü>")` ekleyin, QML'de `import IdsUi`.
2. **CMake**: `add_subdirectory(IdsUi)` ve `IdsUiplugin`'e bağlayın (ayrıntı `IdsUi/CMakeLists.txt` içinde). Bu durumda `IdsUi/qmldir` dosyasını silin.

Yazı tipleri: Inter ve JetBrains Mono'yu uygulamaya gömün, örn. `main.qml` içinde
`FontLoader { source: "qrc:/fonts/Inter-Variable.ttf" }` ve `FontLoader { source: "qrc:/fonts/JetBrainsMono-Regular.ttf" }`.

Deneme: `qml -I . examples/main.qml` veya `qml -I . examples/Gallery.qml`

## Bileşenler

| Grup | Bileşen | Tasarımdaki karşılığı |
|---|---|---|
| Temel | `Theme` (singleton), `Icons` (singleton), `Icon`, `CardBackground`, `FocusRing`, `Shadow`, `BrandStripe` | CSS değişkenleri, SVG ikonlar, kart zemini, odak halkası, marka şeridi |
| Butonlar | `IdsButton` (`variant`: primary / secondary / quiet / danger, `compact`), `StatusBarButton` | `.btn .pri/.sec/.qui/.stop`, `.sb-btn` |
| Girişler | `IdsTextField` (`suffix`, `error`), `IdsComboBox`, `IdsSwitch`, `ToggleRow`, `IdsSlider`, `FormField` (`inline`) | `.inp`, `.sel`, `.sw`, `.tg`, range, `.irow` |
| Seçim | `SegmentedControl`, `ThemeSwitcher`, `IdsTabs`, `ChoiceChip`, `SelectableCard` | `.seg`, tema seçici, `.tabs`, `.chip`, `.gcard` |
| Durum | `Badge` (`kind`), `StatusDot`, `StatusLabel` (`framed`), `Led` (`pulse()`), `IdsProgressBar`, `ArcGauge`, `Hint`, `Kbd` | `.badge`, `.dot`, `.st`, `.led`, `.prog`, `.gtrack/.gfill`, `.hint`, `.kbd` |
| Veri | `Card` (`actions`, `flush`, `fillContent`), `KpiTile`, `InfoRow`, `StatStrip` + `StatCell`, `Zone`, `TestResultTile` | `.card`, `.kpi`, `.row`, `.stat`, `.zone`, BIT kutucukları |
| Görüntü | `VideoViewport` (`showCrosshair`, yer tutucu), `OverlayTag` | video / 3B alanı, görüntü üstü etiketler |
| İskelet | `AppShell`, `NavRail`, `NavItem`, `NavSection`, `NavDivider`, `RailBrand`, `TopBar`, `StatusBar`, `StatusBarSection`, `IdsPopup`, `ConnectionPopup` | `.rail`, `.nav`, `.ov`, `.brand`, `.top`, `.sbar`, `.pop` |

## Kısa örnekler

```qml
Card {
    title: "Bootloader"; subtitle: "Enter or leave the bootloader"
    actions: IdsButton { compact: true; variant: "quiet"; text: "Reset" }
    Zone { Layout.fillWidth: true
        RowLayout { StatusLabel { status: "ok"; text: "Application running" }
                    Item { Layout.fillWidth: true }
                    Badge { kind: "info"; text: "NO BOOTLOADER" } } }
    Hint { Layout.fillWidth: true; text: "Motors are disabled until you exit it." }
}

StatStrip {
    StatCell { label: "SUPPLY VOLTAGE"; value: "24.1 V"; trailing: Badge { kind: "ok"; text: "NORMAL" } }
    StatCell { label: "PAN ANGLE"; value: "124.496°"; monoValue: true
               leading: ArcGauge { from: -180; to: 180; value: 124.496 } }
}
```

Tam ekran örneği: `examples/main.qml` + `examples/GimbalInfoPage.qml`. Tüm kontroller: `examples/Gallery.qml`.

## Notlar

- `Card` içeriği varsayılan olarak yukarı hizalanır; içerik (ör. `VideoViewport`) kalan yüksekliği dolduracaksa `fillContent: true` verin (`flush: true` bunu otomatik açar).
- `NavRail` fareyle üzerine gelindiğinde veya klavye odağı içindeyken 64 → 248 px genişler ve içeriğin üstüne açılır; sabit açık tutmak için `pinned: true`.
- Gerçek video için `VideoViewport` içine `VideoOutput { anchors.fill: parent }`, 3B model için `View3D` koyun.
- Metinler `qsTr()` ile sarılıdır; Türkçe çeviri `.ts` dosyasıyla eklenebilir.
