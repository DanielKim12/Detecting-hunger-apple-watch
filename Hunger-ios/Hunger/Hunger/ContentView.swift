import SwiftUI
import Charts

struct ContentView: View {
    @State private var modelOutput: Int? = nil
    @State private var showPrompt = true
    @State private var showFollowUp = false
    @State private var showResultsPage = false
    @State private var followUpMessage = ""
    @State private var showLoading = true
    @State private var accuracy = 0.0
    @State private var totalPredictions = 0
    @State private var correctPredictions = 0
    @State private var accuracyHistory: [AccuracyEntry] = []

    @State private var currentSuggestion: FoodSuggestion = FoodSuggestion(name: "", tip: "")
    @State private var showMoreSuggestion = false

    let foodSuggestions: [FoodSuggestion] = [
        .init(name: "Avocado Toast 🥑", tip: "Rich in healthy fats and fiber, good for heart and digestion."),
        .init(name: "Greek Yogurt with Berries 🍓", tip: "High in protein and antioxidants for muscle repair."),
        .init(name: "Grilled Chicken Salad 🥗", tip: "Packed with lean protein and leafy greens for recovery."),
        .init(name: "Hummus and Veggie Wrap 🌯", tip: "A balanced combo of fiber and plant protein."),
        .init(name: "Oatmeal with Nuts and Banana 🍌", tip: "Great source of energy and potassium."),
        .init(name: "Tofu Stir Fry 🍜", tip: "High in plant protein, great for muscle and bones."),
        .init(name: "Fruit Smoothie 🥤", tip: "Hydrating and rich in vitamins A, C and natural sugars."),
        .init(name: "Hard-boiled Eggs 🥚", tip: "Loaded with high-quality protein and vitamin D."),
        .init(name: "Cottage Cheese with Pineapple 🍍", tip: "Good mix of casein protein and vitamin C."),
        .init(name: "Edamame 🌱", tip: "High in protein and iron—great pre/post workout snack.")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Hunger Detection")
                    .font(.largeTitle)
                    .padding(.top)

                if showLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                        Text("⏳ Checking in with your body… Are you due for a snack?")
                            .multilineTextAlignment(.center)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            modelOutput = Int.random(in: 0...1)
                            showLoading = false
                        }
                    }
                }

                if showPrompt && !showLoading {
                    if let output = modelOutput {
                        Text(output == 1
                             ? "Based on your heart rate, you seem to have eaten recently. Is this correct?"
                             : "Based on your heart rate, it seems like you haven’t eaten. Have you eaten yet?")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding()

                        HStack {
                            Button("Yes") { handleResponse(userSaidYes: true) }
                                .buttonStyle(FilledButtonStyle(color: .green))
                            Button("No") { handleResponse(userSaidYes: false) }
                                .buttonStyle(FilledButtonStyle(color: .red))
                        }
                    }
                } else if showFollowUp {
                    VStack(spacing: 16) {
                        Text(followUpMessage)
                            .font(.title2)
                            .multilineTextAlignment(.center)

                        if currentSuggestion.name != "" {
                            VStack(spacing: 8) {
                                Text("🍽️ You should try: \(currentSuggestion.name)")
                                    .font(.title2)
                                Text(currentSuggestion.tip)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                if !showMoreSuggestion {
                                    Button("🔄 Show Another Option") {
                                        currentSuggestion = foodSuggestions.randomElement()!
                                        showMoreSuggestion = true
                                    }
                                    .font(.subheadline)
                                    .padding(.top, 4)
                                }
                            }
                        }

                        HStack {
                            Button("See My Results") { showResultsPage = true }
                                .buttonStyle(FilledButtonStyle(color: .blue))

                            Button("Continue") { resetToMain() }
                                .buttonStyle(FilledButtonStyle(color: .gray))
                        }
                    }
                    .padding()
                }
            }
            .padding()
            .sheet(isPresented: $showResultsPage) {
                ResultsView(accuracyHistory: accuracyHistory, accuracy: accuracy)
            }
        }
    }

    func handleResponse(userSaidYes: Bool) {
        guard let prediction = modelOutput else { return }

        let isCorrect = (prediction == 1 && userSaidYes) || (prediction == 0 && !userSaidYes)
        totalPredictions += 1
        if isCorrect { correctPredictions += 1 }
        accuracy = (Double(correctPredictions) / Double(totalPredictions)) * 100
        accuracyHistory.append(AccuracyEntry(attempt: totalPredictions, percentage: accuracy))

        if prediction == 1 {
            followUpMessage = userSaidYes
                ? "✅ Great! Let's go take a walk!"
                : "📝 Got it! Thanks for letting us know!"
        } else {
            followUpMessage = userSaidYes
                ? "🚶 Maybe move a bit to refresh."
                : "👨‍🍳 Let me help with some food ideas!"
            currentSuggestion = foodSuggestions.randomElement()!
        }

        showPrompt = false
        showFollowUp = true
        showMoreSuggestion = false
    }

    func resetToMain() {
        modelOutput = nil
        showPrompt = true
        showFollowUp = false
        currentSuggestion = FoodSuggestion(name: "", tip: "")
        showLoading = true
    }
}

struct FoodSuggestion {
    let name: String
    let tip: String
}

struct AccuracyEntry: Identifiable {
    let id = UUID()
    let attempt: Int
    let percentage: Double
}

struct ResultsView: View {
    var accuracyHistory: [AccuracyEntry]
    var accuracy: Double
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("📊 Your Results")
                    .font(.largeTitle)
                Text("Accuracy: \(String(format: "%.1f", accuracy))%")
                    .font(.headline)

                Chart(accuracyHistory) { entry in
                    LineMark(x: .value("Attempt", entry.attempt),
                             y: .value("Accuracy", entry.percentage))
                }
                .frame(height: 200)
                .padding()

                Button("Go Back") { dismiss() }
                    .buttonStyle(FilledButtonStyle(color: .blue))
            }
            .padding()
        }
    }
}

struct FilledButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(minWidth: 100)
            .background(color.opacity(configuration.isPressed ? 0.6 : 0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}