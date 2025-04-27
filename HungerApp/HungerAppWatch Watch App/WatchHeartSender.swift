import Foundation
import HealthKit
import WatchConnectivity
import Combine

final class WatchHeartSender: NSObject {

    private let store  = HKHealthStore()
    private let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    private var timerC: AnyCancellable?

    func start() {
        store.requestAuthorization(toShare: nil, read: [hrType]) { ok, _ in
            guard ok else { return }
            DispatchQueue.main.async { [weak self] in
                self?.timerC = Timer.publish(every: 30, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in self?.sendLastMinute() }
            }
        }
    }

    private func sendLastMinute() {
        let end   = Date()
        let start = end.addingTimeInterval(-60)

        let query = HKSampleQuery(
            sampleType: hrType,
            predicate: HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            let values = (samples as? [HKQuantitySample])?
                .map { $0.quantity.doubleValue(for: .count().unitDivided(by: .minute())) } ?? []

            guard !values.isEmpty else { print("🔸 no HR"); return }
            self.postMessage(hr: values, date: end)
        }
        store.execute(query)
    }

    private func postMessage(hr: [Double], date: Date) {
        guard WCSession.default.isReachable else { return }
        let iso = ISO8601DateFormatter().string(from: date)
        WCSession.default.sendMessage(["hr": hr, "ts": iso], replyHandler: nil)
        print("🤖 sent HR \(hr.count) samples @ \(iso)")
    }
}
