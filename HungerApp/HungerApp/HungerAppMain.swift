import SwiftUI

@main
struct HungerAppMain: App {
    init() {
        _ = WCSessionManager.shared      // ✅ iOS 세션 즉시 활성
    }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
