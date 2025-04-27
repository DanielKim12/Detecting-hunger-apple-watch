import SwiftUI
import Charts
import Combine

struct ContentView: View {

    // 세션
    @StateObject private var wc = WCSessionManager.shared
    @State private var bag = Set<AnyCancellable>()

    // UI 상태
    @State private var modelOutput: Int? = nil      // 0 hungry / 1 not-hungry
    @State private var showPrompt  = false
    @State private var showFollow  = false
    @State private var showResults = false
    @State private var followMsg   = ""
    @State private var showLoading = true

    // 통계
    @State private var total = 0
    @State private var correct = 0
    @State private var accuracy = 0.0
    @State private var history: [AccuracyEntry] = []

    // 제안
    @State private var suggestion = FoodSuggestion(name:"", tip:"")
    @State private var showMoreSuggestion = false

    private let foods:[FoodSuggestion] = [
        .init(name:"Avocado Toast 🥑",tip:"Healthy fats & fiber."),
        .init(name:"Greek Yogurt 🍓", tip:"Protein & antioxidants."),
        .init(name:"Chicken Salad 🥗",tip:"Lean protein & greens."),
        .init(name:"Oatmeal 🍌",      tip:"Slow carbs + potassium.")
    ]

    // 연결 배너
    private var banner: some View {
        VStack(spacing: 4){
            Text(wc.reachable ? "Connected ✅"
                              : "Not Connected")
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
                         ? "You seem to have eaten recently.\nIs that correct?"
                         : "It looks like you haven’t eaten.\nHave you?")
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

                                if !showMoreSuggestion {
                                    Button("🔄 Another option"){
                                        suggestion = foods.randomElement()!
                                        showMoreSuggestion = true
                                    }.font(.subheadline)
                                }
                            }
                        }

                        HStack{
                            Button("See Results"){ showResults = true }
                                .buttonStyle(FilledButtonStyle(color:.blue))
                            Button("Continue"){ reset() }
                                .buttonStyle(FilledButtonStyle(color:.gray))
                        }
                    }.padding()
                }

                Spacer()

                // ─── 모델 최신 상태 배지 ───
                if let out = modelOutput {
                    Text("Latest model output: \(out==1 ? "Not Hungry" : "Hungry")")
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
            // 모델 결과 구독
            wc.modelPublisher
              .receive(on:RunLoop.main)
              .sink { value in
                  modelOutput = value
                  showLoading = false
                  showPrompt  = true
              }
              .store(in:&bag)
        }
    }

    // MARK: – Logic
    private func handleAnswer(_ yes: Bool){
        guard let pred = modelOutput else { return }
        total += 1
        if (pred==1 && yes)||(pred==0 && !yes) { correct += 1 }
        accuracy = Double(correct)/Double(total)*100
        history.append(.init(attempt: total, percentage: accuracy))

        if pred == 1 { // not-hungry
            followMsg = yes ? "✅ Great! Let's take a walk."
                            : "📝 Thanks for letting us know!"
        } else {       // hungry
            followMsg = yes ? "🚶 Maybe move a bit."
                            : "👨‍🍳 Let me suggest a snack!"
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

///////////////////////////////////////////////////////////////
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
                Text("📊 Your Results").font(.largeTitle)
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

//import SwiftUI
//import Combine
//
///// iPhone-side main screen
//struct ContentView: View {
//    @StateObject private var wc = WCSessionManager.shared          // WCSession status + publisher
//
//    // UI-state
//    @State private var lastValues: [Double] = []                   // 최근 60 s BPM 배열
//    @State private var averageBPM: Double?
//    @State private var sampleCount = 0
//
//    // Combine token
//    @State private var cancellable: AnyCancellable?
//
//    var body: some View {
//        VStack(spacing: 24) {
//
//            // ▪ Watch Status + Refresh ▪
//            HStack(spacing: 12) {
//                Label {
//                    Text(wc.reachable ? "Connected" : "Not Connected")
//                } icon: {
//                    Image(systemName: wc.reachable
//                                    ? "checkmark.circle.fill"
//                                    : "xmark.circle.fill")
//                        .foregroundColor(wc.reachable ? .green : .red)
//                }
//                .font(.title2)
//
//                Button {
//                    wc.refreshStatus()                                 // 수동 연결 확인
//                } label: {
//                    Image(systemName: "arrow.clockwise")
//                }
//                .buttonStyle(.bordered)
//            }
//
//            Text("Heart-rate window auto-updates every 60 s")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//
//            // ▪ Latest window summary ▪
//            if let avg = averageBPM {
//                VStack {
//                    Text("Latest Window").font(.headline)
//                    Text("Avg BPM: \(avg, specifier: "%.1f")")
//                    Text("Count : \(sampleCount) samples")
//                        .foregroundColor(.secondary)
//                }
//            }
//
//            // ▪ Sample list ▪
//            if !lastValues.isEmpty {
//                List(lastValues.indices, id: \.self) { idx in
//                    Text(String(format: "%.1f bpm", lastValues[idx]))
//                }
//                .frame(height: 160)
//            }
//        }
//        .padding()
//        .onAppear {
//            // 구독 – 60 s마다 Watch → iPhone 윈도우 수신
//            cancellable = wc.hrvPublisher
//                .receive(on: RunLoop.main)
//                .sink { arr in
//                    lastValues  = arr
//                    sampleCount = arr.count
//                    averageBPM  = arr.average
//                }
//        }
//    }
//}
//
//private extension Array where Element == Double {
//    var average: Double { isEmpty ? .nan : reduce(0, +) / Double(count) }
//}
