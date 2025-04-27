import Foundation
import Combine
import WatchConnectivity

final class WCSessionManager: NSObject, ObservableObject {

    static let shared = WCSessionManager()

    // 공개 퍼블리셔
    @Published private(set) var reachable = false
    let hrPublisher    = PassthroughSubject<[Double], Never>()
    let modelPublisher = PassthroughSubject<Int,   Never>()      // 0 / 1

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        print("📲/🤖 WCSession activate() called")
    }
}

// MARK: - WCSessionDelegate
extension WCSessionManager: WCSessionDelegate {

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        print("WCSession activationDidComplete, state =", state.rawValue)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.reachable = session.isReachable
            print(session.isReachable ? "✅ Watch reachable" : "🚫 Watch not reachable")
        }
    }

    /// 메시지 수신 (Watch → iPhone)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {

        // 두 키 모두 존재?
        guard let arr = message["hr"] as? [Double],
              let iso = message["ts"] as? String else { return }

        print("📥 iPhone received \(arr.count) HR samples @ \(iso)")
        hrPublisher.send(arr)                              // 그래프용

        // ---------- iOS 타깃에서만 서버 호출 ----------
        #if os(iOS)
        PredictionAPI.send(hr: arr, isoDate: iso) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let res):
                    print("📡 model →", res)
                    self?.modelPublisher.send(res)         // ContentView 로 전달
                case .failure(let err):
                    print("⚠️ API error:", err.localizedDescription)
                }
            }
        }
        #endif
    }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
#endif
}
