import SwiftUI
import AppKit

enum FontConfig {
    static let sizes: [CGFloat] = [10, 12, 16, 24, 36, 48, 72]
    static let weights: [Int] = [100, 200, 300, 400, 500, 600, 700, 800, 900]
}

struct ContentView: View {
    @StateObject private var fontManager = FontManager()

    @State private var sampleText = "The quick brown fox"
    @State private var searchText = ""
    @State private var columns = 3
    @State private var fontSizeIndex = 4 // index into fontSizes → 36
    @State private var weightIndex = 3   // index into weights → 400

    private var fontSize: CGFloat { FontConfig.sizes[fontSizeIndex] }
    private var weight: Int { FontConfig.weights[weightIndex] }

    private var filteredFamilies: [FontFamily] {
        if searchText.isEmpty { return fontManager.families }
        let query = searchText.lowercased()
        return fontManager.families.filter {
            $0.familyName.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBarView(
                sampleText: $sampleText,
                searchText: $searchText,
                columns: $columns,
                fontSizeIndex: $fontSizeIndex,
                weightIndex: $weightIndex,
                onReload: {
                    fontManager.invalidateCache()
                    fontManager.loadFonts()
                }
            )

            Divider()

            GeometryReader { geo in
                let spacing: CGFloat = 12
                let horizontalPadding: CGFloat = 16
                let totalSpacing = spacing * CGFloat(columns - 1) + horizontalPadding * 2
                let cardWidth = max(100, (geo.size.width - totalSpacing) / CGFloat(columns))

                ScrollView {
                    let rows = buildRows(from: filteredFamilies, columns: columns)

                    LazyVStack(spacing: spacing) {
                        ForEach(rows, id: \.id) { row in
                            CardRow(
                                families: row.families,
                                columns: columns,
                                cardWidth: cardWidth,
                                spacing: spacing,
                                sampleText: sampleText,
                                fontSize: fontSize,
                                weight: weight,
                                fontManager: fontManager
                            )
                        }
                    }
                    .padding(horizontalPadding)
                }
            }
        }
        .onAppear {
            fontManager.loadFonts()
        }
        .onChange(of: fontSizeIndex) { fontManager.invalidateCache() }
        .onChange(of: weightIndex) { fontManager.invalidateCache() }
    }

    private func buildRows(from families: [FontFamily], columns: Int) -> [RowData] {
        stride(from: 0, to: families.count, by: columns).map { start in
            let end = min(start + columns, families.count)
            return RowData(id: families[start].id, families: Array(families[start..<end]))
        }
    }
}

private struct RowData: Identifiable {
    let id: String
    let families: [FontFamily]
}

private struct CardRow: View {
    let families: [FontFamily]
    let columns: Int
    let cardWidth: CGFloat
    let spacing: CGFloat
    let sampleText: String
    let fontSize: CGFloat
    let weight: Int
    let fontManager: FontManager

    @State private var maxTextHeight: CGFloat = 20

    private var heightInputs: [AnyHashable] {
        [AnyHashable(families), AnyHashable(sampleText), AnyHashable(fontSize), AnyHashable(weight), AnyHashable(cardWidth)]
    }

    private var rowHeight: CGFloat {
        maxTextHeight + 2 * FontCardView.cardPadding + FontCardView.footerHeight
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(families) { family in
                let resolved = fontManager.resolve(family: family.familyName, weight: weight, size: fontSize)
                FontCardView(
                    family: family,
                    sampleText: sampleText,
                    resolved: resolved,
                    textHeight: maxTextHeight
                )
                .frame(width: cardWidth, height: rowHeight)
            }
            if families.count < columns {
                ForEach(0..<(columns - families.count), id: \.self) { _ in
                    Color.clear.frame(width: cardWidth)
                }
            }
        }
        .onAppear { computeMaxTextHeight() }
        .onChange(of: heightInputs) { computeMaxTextHeight() }
    }

    private func computeMaxTextHeight() {
        let textWidth = max(10, cardWidth - 2 * FontCardView.cardPadding)
        var result: CGFloat = 20

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping

        for family in families {
            if let resolved = fontManager.resolve(family: family.familyName, weight: weight, size: fontSize) {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: resolved.nsFont,
                    .paragraphStyle: paragraphStyle,
                ]
                let attrString = NSAttributedString(string: sampleText, attributes: attrs)
                let rect = attrString.boundingRect(
                    with: NSSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading]
                )
                result = max(result, ceil(rect.height))
            }
        }

        maxTextHeight = result
    }
}
