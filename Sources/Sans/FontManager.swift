import AppKit
import CoreText

struct FontFamily: Identifiable, Hashable {
    let id: String
    let familyName: String
    let faceCount: Int
}

struct ResolvedFont {
    let nsFont: NSFont
    let postScriptName: String
    let fullName: String
    let fileURL: URL?
}

@MainActor
final class FontManager: ObservableObject {
    @Published var families: [FontFamily] = []

    private var cache: [String: ResolvedFont] = [:]

    func loadFonts() {
        let mgr = NSFontManager.shared
        let familyNames = mgr.availableFontFamilies.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }

        let result = familyNames.map { name -> FontFamily in
            let count = mgr.availableMembers(ofFontFamily: name)?.count ?? 0
            return FontFamily(id: name, familyName: name, faceCount: count)
        }

        cache.removeAll()
        families = result
    }

    func resolve(family: String, weight: Int, size: CGFloat) -> ResolvedFont? {
        let key = "\(family)-\(weight)-\(size)"
        if let cached = cache[key] { return cached }

        let mgr = NSFontManager.shared
        guard let members = mgr.availableMembers(ofFontFamily: family) else { return nil }

        var bestMember: [Any]?
        var bestDistance = Int.max

        for member in members {
            guard member.count >= 3, let nsFontWeight = member[2] as? Int else { continue }
            let cssWeight = nsFontManagerWeightToCSS(nsFontWeight)
            let distance = abs(cssWeight - weight)
            if distance < bestDistance {
                bestDistance = distance
                bestMember = member
            }
        }

        guard let chosen = bestMember,
              let psName = chosen[0] as? String else { return nil }

        guard let font = NSFont(name: psName, size: size) else { return nil }

        let fullName = font.displayName ?? psName

        var fileURL: URL?
        let desc = CTFontDescriptorCreateWithNameAndSize(psName as CFString, size)
        if let url = CTFontDescriptorCopyAttribute(desc, kCTFontURLAttribute) {
            fileURL = url as? URL
        }

        let resolved = ResolvedFont(nsFont: font, postScriptName: psName, fullName: fullName, fileURL: fileURL)
        cache[key] = resolved
        return resolved
    }

    func invalidateCache() {
        cache.removeAll()
    }

    private func nsFontManagerWeightToCSS(_ w: Int) -> Int {
        switch w {
        case 0...2: return 100
        case 3: return 200
        case 4: return 300
        case 5: return 400
        case 6: return 500
        case 7...8: return 600
        case 9: return 700
        case 10...11: return 800
        default: return 900
        }
    }
}
