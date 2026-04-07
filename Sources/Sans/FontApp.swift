import AppKit
import SwiftUI

@main
struct SansApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1024, height: 600)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Sans") {
                    NSWorkspace.shared.open(URL(string: "https://apps.vlad.studio/sans")!)
                }
            }
        }
    }
}
