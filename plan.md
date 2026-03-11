# Font — Implementation Plan

## Overview
A native macOS SwiftUI app that previews sample text across all installed font families.

## Architecture

**Single-target SwiftUI app** using:
- `CTFontManagerCopyAvailableFontFamilyNames()` for font enumeration
- `NSFontManager` for resolving family → faces and weight mapping
- SwiftUI `LazyVGrid` + `ScrollView` for the card grid (lazy loading for performance)
- `NSFont` for rendering (via `NSViewRepresentable`) — more reliable than `Font.custom()` for weight control and avoids SwiftUI font caching issues

## Data Model

```swift
struct FontFamily: Identifiable {
    let id: String               // familyName
    let familyName: String       // e.g. "Times New Roman"
    let faceCount: Int           // number of available faces
}
```

Per-family resolved properties (depend on current weight selection, computed on demand):
- `postScriptName: String` — e.g. `TimesNewRomanPSMT`
- `fullFontName: String` — e.g. `Times New Roman Bold`
- `fileURL: URL?` — nil for some system-protected fonts

Font loading happens on a background thread. The family list is sorted alphabetically and stored in an `ObservableObject` view model.

## Font Resolution Strategy

For each family, given the user-selected weight (100–900):
1. Get all members via `NSFontManager.availableMembers(ofFontFamily:)`
2. Map each member's `NSFontManager` weight (0–15) to CSS weight (100–900)
3. Pick the face with the nearest weight to the slider value
4. Cache the resolved `NSFont` per family+weight+size combo

**NSFontManager weight → CSS weight mapping:**
| NSFontManager | CSS   |
|---------------|-------|
| 1–2           | 100   |
| 3             | 200   |
| 4             | 300   |
| 5             | 400   |
| 6             | 500   |
| 7–8           | 600   |
| 9             | 700   |
| 10–11         | 800   |
| 12–15         | 900   |

## UI Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ TOP BAR (horizontal stack, each control has a label above it)        │
│                                                                      │
│  Sample Text       Search        Columns   Size      Weight     [↻] │
│  [____________]  [__________]    [1|2|3|4]  [slider]  [slider]       │
├──────────────────────────────────────────────────────────────────────┤
│ SCROLLABLE GRID                                                      │
│ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐            │
│ │                │ │                │ │                │            │
│ │  The quick     │ │  The quick     │ │  The quick     │            │
│ │  brown fox     │ │  brown fox     │ │  brown fox     │            │
│ │                │ │                │ │                │            │
│ │ ARIAL    4F    │ │ BASKERVILLE 2F │ │ COURIER   1F   │            │
│ └────────────────┘ └────────────────┘ └────────────────┘            │
│ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐            │
│ │  ...           │ │  ...           │ │  ...           │            │
│ └────────────────┘ └────────────────┘ └────────────────┘            │
└──────────────────────────────────────────────────────────────────────┘
```

## Window

- Default size: 1024×600
- Resizable. Card widths reflow based on window width and column count.

## Top Bar Controls (each with a label above)

| Control | Label | Type | Details |
|---------|-------|------|---------|
| Sample text | "Sample Text" | `TextField` | Default: "The quick brown fox" |
| Search | "Search" | `TextField` | Filters families by name (case-insensitive substring match) |
| Columns | "Columns" | Segmented picker | Values: 1, 2, 3, 4. Default: 3 |
| Font size | "Size" | Discrete slider | Steps: 10, 12, 16, 24, 36, 48, 72. Default: 36 |
| Weight | "Weight" | Discrete slider | Steps: 100, 200, ..., 900. Default: 400 |
| Reload | — | Icon button (↻) | Re-enumerates all fonts |

## Card Component

### Layout
- Card width = (available grid width − gaps) / columnCount
- 48px padding on all sides between text and card edges
- Footer sits below the padded text area

### Row height calculation
All cards in a single row share the same height. For each row:
1. For each card in the row, measure the height of the sample text rendered with that card's font at the current size, within the available text width (card width − 2×48px padding), with word-break: break-all behavior.
2. The row height = max(measured text heights in the row) + 2×48px vertical padding + footer height.

This ensures text fits without cropping or overflow, and all cards in a row are the same height.

**Implementation**: Use `NSAttributedString.boundingRect(with:options:)` with `.usesLineFragmentOrigin` to measure text height for a given width. Since `LazyVGrid` doesn't natively support per-row dynamic heights, we'll use a custom layout approach:
- Pre-compute heights for all visible cards
- Group cards into rows of N (column count)
- Use `LazyVStack` + `HStack` instead of `LazyVGrid`, so each row's height is independently controlled

### Text rendering
- Sample text uses the font family at the selected weight/size
- Text wraps with break-all behavior (characters can break at any point) — achieved via `NSAttributedString` with `NSLineBreakMode.byCharWrapping` or a custom `NSParagraphStyle`
- Text is vertically centered within the padded area

### Footer
- Font name: uppercased, 10px system font, secondary color, left-aligned
- Face count: `N FACES`, same style, right-aligned (or spaced after name)

### Right-click context menu
- "Copy Font Name" → family name to clipboard (e.g. `Times New Roman`)
- "Copy PostScript Name" → PostScript name of the resolved face to clipboard
- "Copy Full Name" → full font name of the resolved face to clipboard
- "Reveal in Finder" → `NSWorkspace.shared.selectFile(at:)` — disabled if fileURL is nil

### Reveal in Finder
Use `CTFontDescriptor` with `kCTFontURLAttribute` to get the font file URL. If the URL is nil (some system-protected fonts), the menu item is disabled.

## Performance Plan

1. **Font enumeration**: Background thread, publish sorted list to main thread.
2. **Lazy loading**: `LazyVStack` ensures only visible rows are rendered.
3. **NSViewRepresentable for text rendering**: Use `NSTextField` (non-editable, non-selectable) instead of SwiftUI `Text` — avoids SwiftUI's font resolution overhead and gives direct `NSFont` control.
4. **Debounce search**: 150ms debounce on the search field to avoid re-filtering on every keystroke.
5. **Font caching**: Cache resolved `NSFont` objects per (family, weight, size) tuple. Invalidate on size/weight change.
6. **Height pre-computation**: Batch-compute text heights on a background thread when sample text, font size, weight, or card width changes. Use cached heights to avoid redundant measurement.
7. **Equatable conformance**: Card views conform to `Equatable` so SwiftUI skips re-rendering unchanged cards.

## File Structure

```
Font/
├── Font.xcodeproj/
├── Font/
│   ├── FontApp.swift              # App entry, window configuration (1024×600)
│   ├── ContentView.swift          # Main view: top bar + scrollable grid
│   ├── TopBarView.swift           # Top bar with labeled controls
│   ├── FontCardView.swift         # Individual card (preview + footer + context menu)
│   ├── FontTextView.swift         # NSViewRepresentable for rendering font preview
│   ├── FontManager.swift          # Font enumeration, weight resolution, file path lookup, caching
│   └── Assets.xcassets/
└── plan.md
```

## Implementation Steps

1. **Create Xcode project** — SwiftUI macOS app, deployment target macOS 13+
   → verify: project builds, empty window appears at 1024×600

2. **FontManager** — enumerate families, resolve faces by weight, file path lookup, caching
   → verify: print all families with face counts to console

3. **TopBarView** — all controls with labels above, bound to `@Published` properties on a shared view model
   → verify: controls render, changing values updates published state

4. **FontTextView** — `NSViewRepresentable` wrapping `NSTextField` with break-all text, configurable font
   → verify: renders sample text in a given font, wraps at character boundaries

5. **FontCardView** — card layout with padded text area + footer + context menu
   → verify: single card renders correctly, context menu copies to clipboard

6. **ContentView** — wire up grid with `LazyVStack` + row grouping, search filtering, height calculation
   → verify: full grid scrolls smoothly, search filters live, all cards in a row have equal height

7. **Polish** — reload button, window title, default values, edge cases (empty search, no matching fonts)
   → verify: app launches cleanly, reload works, empty states handled
