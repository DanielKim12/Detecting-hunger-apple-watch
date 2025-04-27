#if os(iOS)
import Foundation


enum PredictionAPI {

    private static let base = URL(string: "https://api-server-floral-cherry-861.fly.dev")!

    /// hr: 1-minute window, iso8601: now
    static func send(hr values: [Double],
                     isoDate: String,
                     completion: @escaping (Result<Int, Error>) -> Void)
    {
        var req = URLRequest(url: base.appendingPathComponent("/predict"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["hr": values, "timestamp": isoDate]
        let data = try! JSONSerialization.data(withJSONObject: body)
        req.httpBody = data

        print("📤 POST body:", String(data: data, encoding: .utf8) ?? "")

        URLSession.shared.dataTask(with: req) { data, _, err in
            if let err { return completion(.failure(err)) }

            guard
                let data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let res  = json["hungry"] as? Int
            else { return completion(.failure(NSError(domain: "parse", code: -1))) }

            completion(.success(res))
        }
        .resume()
    }
}
#endif
