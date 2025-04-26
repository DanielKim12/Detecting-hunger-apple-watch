import SwiftUI

struct ContentView: View {
    @State private var modelOutput: Int? = nil  // 1 = not hungry, 0 = hungry
    @State private var showPrompt: Bool = true
    @State private var showFollowUp: Bool = false
    @State private var followUpMessage: String = ""
    @State private var accuracy: Double = 0.0
    @State private var totalPredictions: Int = 0
    @State private var correctPredictions: Int = 0

    let healthyFoods = [
        "Avocado Toast 🥑",
        "Greek Yogurt with Berries 🍓",
        "Grilled Chicken Salad 🥗",
        "Hummus and Veggie Wrap 🌯",
        "Oatmeal with Nuts and Banana 🍌",
        "Tofu Stir Fry 🍜",
        "Fruit Smoothie 🥤"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Hunger Detection")
                .font(.largeTitle)
                .padding()

            Text("Accuracy: \(String(format: "%.1f", accuracy))%")
                .font(.headline)
                .foregroundColor(.gray)

            if showPrompt {
                if let output = modelOutput {
                    Group {
                        if output == 1 {
                            Text("I noticed you had a meal. Is this correct?")
                                .multilineTextAlignment(.center)
                                .font(.title2)

                            HStack {
                                Button(action: {
                                    handleResponse(userSaidYes: true)
                                }) {
                                    Text("Yes")
                                        .font(.title2)
                                        .padding()
                                        .background(Color.green.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    handleResponse(userSaidYes: false)
                                }) {
                                    Text("No")
                                        .font(.title2)
                                        .padding()
                                        .background(Color.red.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            Text("Have you eaten yet?")
                                .multilineTextAlignment(.center)
                                .font(.title2)

                            HStack {
                                Button(action: {
                                    handleResponse(userSaidYes: true)
                                }) {
                                    Text("Yes")
                                        .font(.title2)
                                        .padding()
                                        .background(Color.green.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    handleResponse(userSaidYes: false)
                                }) {
                                    Text("No")
                                        .font(.title2)
                                        .padding()
                                        .background(Color.red.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                } else {
                    Text("Loading model output...")
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.modelOutput = Int.random(in: 0...1)
                            }
                        }
                }
            } else if showFollowUp {
                Text(followUpMessage)
                    .font(.title2)
                    .multilineTextAlignment(.center)

                Button("Okay") {
                    resetToMain()
                }
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(8)
            }
        }
        .padding()
    }

    func handleResponse(userSaidYes: Bool) {
        guard let prediction = modelOutput else { return }

        let isCorrect = (prediction == 1 && userSaidYes) || (prediction == 0 && !userSaidYes)
        totalPredictions += 1
        if isCorrect { correctPredictions += 1 }
        accuracy = (Double(correctPredictions) / Double(totalPredictions)) * 100

        if prediction == 1 {
            followUpMessage = userSaidYes ? "✅ Let's go take a walk!" : "📝 Noted!"
        } else {
            followUpMessage = userSaidYes ? "🚶 Take a walk!" : "🍎 Try this: \(healthyFoods.randomElement() ?? "a healthy snack")"
        }

        appendToCSV(prediction: prediction, response: userSaidYes, correct: isCorrect)

        showPrompt = false
        showFollowUp = true
    }

    func resetToMain() {
        modelOutput = Int.random(in: 0...1)
        showPrompt = true
        showFollowUp = false
        followUpMessage = ""
    }

    func appendToCSV(prediction: Int, response: Bool, correct: Bool) {
        let fileName = "HungerLog.csv"
        let manager = FileManager.default
        let urls = manager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let docURL = urls.first else { return }
        let fileURL = docURL.appendingPathComponent(fileName)

        let row = "\(Date()),\(prediction),\(response),\(correct ? "✅" : "❌")\n"

        if !manager.fileExists(atPath: fileURL.path) {
            let headers = "Timestamp,ModelPrediction,UserResponse,Correct\n"
            try? headers.write(to: fileURL, atomically: true, encoding: .utf8)
        }

        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            if let data = row.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        }
    }
}
