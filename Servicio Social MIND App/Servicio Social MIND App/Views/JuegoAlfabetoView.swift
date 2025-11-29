import SwiftUI
import AVFoundation
import Combine

// MARK: - MODELO DE DATOS
struct LetterItem: Identifiable, Equatable {
    let id = UUID()
    let character: String
    let word: String
    let icon: String
    let color: Color
    
    static let allLetters: [LetterItem] = [
        LetterItem(character: "A", word: "Avión", icon: "airplane", color: Color(hex: "#EF9A9A")),
        LetterItem(character: "B", word: "Bici", icon: "bicycle", color: Color(hex: "#90CAF9")),
        LetterItem(character: "C", word: "Casa", icon: "house.fill", color: Color(hex: "#A5D6A7")),
        LetterItem(character: "E", word: "Estrella", icon: "star.fill", color: Color(hex: "#FFF59D")),
        LetterItem(character: "F", word: "Flor", icon: "camera.macro", color: Color(hex: "#F48FB1")),
        LetterItem(character: "G", word: "Gato", icon: "cat.fill", color: Color(hex: "#CE93D8")),
        LetterItem(character: "L", word: "Luna", icon: "moon.stars.fill", color: Color(hex: "#B0BEC5")),
        LetterItem(character: "M", word: "Mano", icon: "hand.raised.fill", color: Color(hex: "#FFCC80")),
        LetterItem(character: "R", word: "Reloj", icon: "clock.fill", color: Color(hex: "#80CBC4")),
        LetterItem(character: "S", word: "Sol", icon: "sun.max.fill", color: Color(hex: "#FFAB91"))
    ]
}

// MARK: - CLASE DE AUDIO
class AlphabetSpeaker: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.15
        synthesizer.speak(utterance)
    }
}

// MARK: - VISTA PRINCIPAL
struct JuegoAlfabetoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var speaker = AlphabetSpeaker()
    
    @State private var currentLetter: LetterItem = LetterItem.allLetters.randomElement()!
    @State private var options: [LetterItem] = []
    @State private var score = 0
    
    @State private var isRevealed = false
    @State private var showSuccess = false
    @State private var shakeError = false
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundGradient
                .ignoresSafeArea()
            
            if showSuccess {
                Color.white.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            VStack {
               
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 45))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                    }
                    Spacer()
                    
                    Button(action: {
                        if isRevealed {
                            speaker.speak("\(currentLetter.character) de \(currentLetter.word)")
                        } else {
                            speaker.speak("Encuentra la letra \(currentLetter.character)")
                        }
                    }) {
                        Image(systemName: "speaker.wave.2.circle.fill")
                            .font(.system(size: 45))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .foregroundColor(DesignSystem.Colors.warning)
                        Text("\(score)")
                            .font(DesignSystem.Fonts.title())
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                VStack(spacing: 20) {
                    FlipCardView(
                        item: currentLetter,
                        isRevealed: isRevealed
                    )
                    .frame(height: 280)
                    .onTapGesture {
                        if isRevealed {
                            speaker.speak(currentLetter.word)
                        } else {
                            speaker.speak(currentLetter.character)
                        }
                    }
                    .offset(x: shakeError ? -10 : 0)
                    .animation(.default.repeatCount(3, autoreverses: true).speed(2), value: shakeError)
                    
                    Text(isRevealed ? "¡\(currentLetter.character) de \(currentLetter.word)!" :
                            "¿Dónde está la letra **\(currentLetter.character)**?")
                        .font(DesignSystem.Fonts.header())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: isRevealed)
                }
                
                Spacer()
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2),
                    spacing: 20
                ) {
                    ForEach(options) { option in
                        LetterOptionButton(letter: option.character, color: option.color) {
                            checkAnswer(option)
                        }
                        .disabled(isRevealed)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear { startNewRound() }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    func startNewRound() {
        isRevealed = false
        showSuccess = false
        
        let previous = currentLetter
        repeat {
            currentLetter = LetterItem.allLetters.randomElement()!
        } while currentLetter == previous && LetterItem.allLetters.count > 1
        
        var newOptions = [currentLetter]
        while newOptions.count < 4 {
            if let r = LetterItem.allLetters.randomElement(),
               !newOptions.contains(r) { newOptions.append(r) }
        }
        options = newOptions.shuffled()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            speaker.speak("Encuentra la letra \(currentLetter.character)")
        }
    }
    
    func checkAnswer(_ selected: LetterItem) {
        if selected == currentLetter {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                isRevealed = true
                showSuccess = true
                score += 10
            }
            
            speaker.speak("¡Sí! \(currentLetter.character) de \(currentLetter.word)")
            AudioServicesPlaySystemSound(1026)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                startNewRound()
            }
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            withAnimation { shakeError = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shakeError = false }
            
            speaker.speak("Intenta de nuevo")
        }
    }
}

// MARK: - COMPONENTES

struct FlipCardView: View {
    let item: LetterItem
    let isRevealed: Bool
    
    var body: some View {
        ZStack {
            DesignSystem.MagicCard {
                VStack {
                    Text(item.character)
                        .font(.system(size: 120, weight: .heavy, design: .rounded))
                        .foregroundColor(item.color)
                        .shadow(color: item.color.opacity(0.3), radius: 10, y: 5)
                    Text("Toca la letra igual")
                        .font(DesignSystem.Fonts.body())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.top, -10)
                }
            }
            .opacity(isRevealed ? 0 : 1)
            .rotation3DEffect(.degrees(isRevealed ? 180 : 0), axis: (0,1,0))
            
            DesignSystem.MagicCard {
                VStack(spacing: 10) {
                    Image(systemName: item.icon)
                        .font(.system(size: 100))
                        .foregroundColor(item.color)
                        .shadow(color: item.color.opacity(0.4), radius: 10)
                    Text(item.word)
                        .font(DesignSystem.Fonts.title())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            .opacity(isRevealed ? 1 : 0)
            .rotation3DEffect(.degrees(isRevealed ? 0 : -180), axis: (0,1,0))
        }
        .padding(.horizontal, 40)
    }
}

struct LetterOptionButton: View {
    let letter: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .frame(height: 90)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
                
                Text(letter)
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    JuegoAlfabetoView()
}
