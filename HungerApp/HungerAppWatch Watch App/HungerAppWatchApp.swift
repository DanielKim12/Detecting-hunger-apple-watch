import SwiftUI

@main
struct HungerAppWatchApp: App {
    private let wcSession = WCSessionManager.shared      // ✅ 변수명 부여
    private let sender = WatchHeartSender()

    init() { sender.start() }

    var body: some Scene {
        WindowGroup { Text("HR Sender ✅") }
    }
}


//import SwiftUI
//import WatchConnectivity
//
//@main
//struct HungerAppWatchApp: App {
//    private let wcSession = WCSessionManager.shared      // ✅ 변수명 부여
//    private let hrSender = WatchHeartSender()        // ← 교체
//
//    init() { hrSender.start() }
//
//
//    var body: some Scene {
//        WindowGroup { ContentView() }
//    }
//}
