import SwiftUI
import AppKit

struct FontTextView: NSViewRepresentable {
    let text: String
    let font: NSFont

    func makeNSView(context: Context) -> FontRenderView {
        let view = FontRenderView()
        view.text = text
        view.font = font
        return view
    }

    func updateNSView(_ view: FontRenderView, context: Context) {
        view.text = text
        view.font = font
        view.needsDisplay = true
    }
}

class FontRenderView: NSView {
    var text: String = ""
    var font: NSFont = NSFont.systemFont(ofSize: 12)

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let attrString = NSAttributedString.charWrapped(text, font: font, color: .labelColor)
        attrString.draw(with: bounds, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
}

extension NSAttributedString {
    static func charWrapped(_ text: String, font: NSFont, color: NSColor? = nil) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byCharWrapping
        var attrs: [Key: Any] = [.font: font, .paragraphStyle: style]
        if let color { attrs[.foregroundColor] = color }
        return NSAttributedString(string: text, attributes: attrs)
    }
}
