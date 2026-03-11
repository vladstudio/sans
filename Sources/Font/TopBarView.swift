import SwiftUI

struct TopBarView: View {
    @Binding var sampleText: String
    @Binding var searchText: String
    @Binding var columns: Int
    @Binding var fontSizeIndex: Int
    @Binding var weightIndex: Int
    var onReload: () -> Void

    static let fontSizes: [CGFloat] = [10, 12, 16, 24, 36, 48, 72]
    static let weights: [Int] = [100, 200, 300, 400, 500, 600, 700, 800, 900]

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            labeledControl("Sample Text") {
                TextField("The quick brown fox", text: $sampleText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 160)
            }

            labeledControl("Search") {
                TextField("Filter fonts…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 120)
            }

            labeledControl("Columns") {
                Picker("", selection: $columns) {
                    ForEach(1...4, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 120)
            }

            labeledControl("Size: \(Int(Self.fontSizes[fontSizeIndex]))") {
                Slider(
                    value: Binding(
                        get: { Double(fontSizeIndex) },
                        set: { fontSizeIndex = Int($0.rounded()) }
                    ),
                    in: 0...Double(Self.fontSizes.count - 1),
                    step: 1
                )
                .frame(width: 100)
            }

            labeledControl("Weight: \(Self.weights[weightIndex])") {
                Slider(
                    value: Binding(
                        get: { Double(weightIndex) },
                        set: { weightIndex = Int($0.rounded()) }
                    ),
                    in: 0...Double(Self.weights.count - 1),
                    step: 1
                )
                .frame(width: 100)
            }

            Button(action: onReload) {
                Image(systemName: "arrow.clockwise")
            }
            .padding(.bottom, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func labeledControl<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            content()
        }
    }
}
