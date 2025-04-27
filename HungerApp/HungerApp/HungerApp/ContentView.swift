import SwiftUI
import Charts
import Combine

struct ContentView: View {

    // Session
    @StateObject private var wc = WCSessionManager.shared
    @State private var bag = Set<AnyCancellable>()

    // UI
    @State private var modelOutput: Int? = nil      // 1 hungry / 0 not-hungry
    @State private var showPrompt  = false
    @State private var showFollow  = false
    @State private var showResults = false
    @State private var followMsg   = ""
    @State private var showLoading = true

    // Stat
    @State private var total = 0
    @State private var correct = 0
    @State private var accuracy = 0.0
    @State private var history: [AccuracyEntry] = []

    // Suggest
    @State private var suggestion = FoodSuggestion(name:"", tip:"")
    @State private var showMoreSuggestion = false

    private let foods:[FoodSuggestion] = [
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

    // 연결 배너
    private var banner: some View {
        VStack(spacing: 4){
            Text(wc.reachable ? "⌚️ Connected ✅"
                              : "⌚️ Not Connected ⛔️")
                .font(.headline.weight(.bold))
                .foregroundColor(wc.reachable ? .green : .red)
            if !wc.reachable {
                Text("Check the connection to your Apple Watch")
                    .font(.footnote).foregroundColor(.secondary)
            }
        }
        .padding(.vertical,6)
        .frame(maxWidth:.infinity)
        .background(.ultraThinMaterial)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                banner
                Text("Hunger Detection").font(.largeTitle)

                // 로딩 스피너
                if showLoading {
                    ProgressView().scaleEffect(1.5)
                    Text("⏳ Waiting for your heart-rate window…")
                        .foregroundColor(.gray)
                }
                // Yes/No 프롬프트
                if showPrompt, let out = modelOutput {
                    Text(out == 1
                         ? "It seems like you’re hungry.\n Is this correct?"
                         : "It seems like you’re NOT hungry.\n Is this correct?")
                        .font(.title2).multilineTextAlignment(.center).padding()

                    HStack {
                        Button("Yes"){ handleAnswer(true) }
                            .buttonStyle(FilledButtonStyle(color:.green))
                        Button("No"){  handleAnswer(false) }
                            .buttonStyle(FilledButtonStyle(color:.red))
                    }
                }

                // Follow-up
                if showFollow {
                    VStack(spacing:16) {
                        Text(followMsg).font(.title2).multilineTextAlignment(.center)

                        if suggestion.name != "" {
                            VStack(spacing:6){
                                Text("🍽  Try: \(suggestion.name)").font(.headline)
                                Text(suggestion.tip).font(.subheadline).foregroundColor(.gray)

                                // 👉 Always show the button
                                Button("🔄 Another option") {
                                    suggestion = foods.randomElement()!
                                }
                                .font(.subheadline)
                            }
                        }

                        HStack{
                            Button("See How AI Predicted"){ showResults = true }
                                .buttonStyle(FilledButtonStyle(color:.blue))
                            Button("Continue"){ reset() }
                                .buttonStyle(FilledButtonStyle(color:.gray))
                        }
                    }.padding()
                }

                Spacer()

                // ─── 모델 최신 상태 배지 ───
                if let out = modelOutput {
                    Text("Latest model output: \(out==1 ? "Hungry" : "Not Hungry")")
                        .font(.callout)
                        .foregroundColor(out==1 ? .green : .orange)
                        .padding(.bottom,8)
                }
            }
            .padding()
            .sheet(isPresented:$showResults){
                ResultsView(history:history, accuracy:accuracy)
            }
        }
        .onAppear {

            wc.modelPublisher
              .receive(on:RunLoop.main)
              .sink { value in
                  resetInteractionState()   // ✅ 먼저 현재 인터랙션 상태 리셋
                  
                  modelOutput = value
                  showLoading = false
                  showPrompt  = true
              }
              .store(in:&bag)
        }    }
    
    private func resetInteractionState() {
        showPrompt  = false
        showFollow  = false
        showResults = false
        suggestion  = FoodSuggestion(name:"", tip:"")
        followMsg   = ""
    }
    


    // MARK: – Logic
    private func handleAnswer(_ yes: Bool){
        guard let pred = modelOutput else { return }
        total += 1
        if (pred==1 && yes)||(pred==0 && yes) { correct += 1 }
        accuracy = Double(correct)/Double(total)*100
        history.append(.init(attempt: total, percentage: accuracy))

        if pred == 1 { // hungry
            followMsg = yes ? "✅ Let me suggest healthy meal choices!"
                            : "❌ Thanks for letting me know! \n How about a short walk to help your digestion?"
        } else {       // not-hungry
            followMsg = yes ? "✅ Great. Take a short walk to help your digestion and awaken your brain"
                            : "❌ Thanks for letting me know! \n Let me suggest healthy meal choices."
            if !yes { suggestion = foods.randomElement()! }
        }

        showPrompt = false
        showFollow = true
        showMoreSuggestion = false
    }

    private func reset(){
        modelOutput = nil
        showLoading = true
        showPrompt  = false
        showFollow  = false
        suggestion  = FoodSuggestion(name:"",tip:"")
    }
}

///
struct FoodSuggestion { let name:String; let tip:String }

struct AccuracyEntry: Identifiable {
    let id = UUID(); let attempt:Int; let percentage:Double
}

struct FilledButtonStyle: ButtonStyle {
    let color:Color
    func makeBody(configuration:Configuration)->some View{
        configuration.label
            .padding().frame(minWidth:100)
            .background(color.opacity(configuration.isPressed ? 0.6 : 0.85))
            .foregroundColor(.white).cornerRadius(10)
    }
}

struct ResultsView: View {
    let history:[AccuracyEntry]; let accuracy:Double
    @Environment(\.dismiss) private var dismiss
    var body: some View{
        NavigationStack{
            VStack(spacing:16){
                Text("📊 Prediction Accuracy").font(.largeTitle)
                Text("Accuracy \(String(format:"%.1f",accuracy)) %")
                    .font(.headline)
                Chart(history){ e in
                    LineMark(x:.value("Attempt",e.attempt), y:.value("Acc",e.percentage))
                }.frame(height:200).padding()
                Button("Close"){ dismiss() }
                    .buttonStyle(FilledButtonStyle(color:.blue))
            }.padding()
        }
    }
}

import Charts

