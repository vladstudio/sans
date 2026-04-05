import SwiftUI
import AppKit

struct FontCardView: View {
    let family: FontFamily
    let sampleText: String
    let resolved: ResolvedFont?
    let textHeight: CGFloat
    static let cardPadding: CGFloat = 36
    static let footerHeight: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let resolved = resolved {
                FontTextView(text: sampleText, font: resolved.nsFont)
                    .frame(height: textHeight)
                    .clipped()
                    .padding(Self.cardPadding)
            } else {
                Text(sampleText)
                    .frame(height: textHeight, alignment: .topLeading)
                    .clipped()
                    .padding(Self.cardPadding)
            }

            HStack {
                Text(family.familyName.uppercased())
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if family.faceCount > 1 {
                    Text("\(family.faceCount) FACES")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contextMenu {
            Button("Copy Font Name") {
                copyToClipboard(family.familyName)
            }
            if let resolved = resolved {
                Button("Copy PostScript Name") {
                    copyToClipboard(resolved.postScriptName)
                }
                Button("Copy Full Name") {
                    copyToClipboard(resolved.fullName)
                }
                if let url = resolved.fileURL {
                    Divider()
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                    }
                }
            }
        }
    }

    private func copyToClipboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
