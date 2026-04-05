# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
swift build              # Debug build
swift build -c release   # Release build
swift run                # Build and run the app
```

No tests, linting, or formatting tools are configured.

## Architecture

Sans is a native macOS SwiftUI app (macOS 14+) that previews sample text across all installed font families in a grid. Zero external dependencies — Swift Package Manager with only system frameworks (SwiftUI, AppKit, CoreText).

**Source files** (all in `Sources/Sans/`):

- **FontApp.swift** — `@main` entry point, WindowGroup (1024×600 default)
- **ContentView.swift** — Main view: state management, search filtering, row grouping for the LazyVStack grid, dynamic height computation per row
- **TopBarView.swift** — Control bar: sample text, search, column count picker, font size slider, weight slider, reload button
- **FontCardView.swift** — Individual font card: text preview + footer + context menu (copy names, reveal in Finder)
- **FontTextView.swift** — NSViewRepresentable wrapping a custom NSView (`FontRenderView`) for character-wrapping text rendering, used instead of SwiftUI Text for performance
- **FontManager.swift** — @MainActor ObservableObject: enumerates system fonts, resolves fonts by CSS weight (maps NSFontManager 0-15 → CSS 100-900), caches resolved fonts keyed by `{family}-{weight}-{size}`

**Key patterns:**
- Grid layout uses `LazyVStack` of `HStack` rows; all cards in a row share the max computed text height
- Font resolution picks the member with minimum distance from target CSS weight
- Text height computed via `NSAttributedString.boundingRect()` with character wrapping
