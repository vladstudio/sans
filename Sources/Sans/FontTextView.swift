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
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle,
        ]

        let attrString = NSAttributedString(string: text, attributes: attrs)
        attrString.draw(with: bounds, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
}
