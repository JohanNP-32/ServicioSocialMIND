import SwiftUI
import AVFoundation
import Combine

// MARK: - MODELO DE DATOS
struct ColorItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
    let icon: String
    
    static let allColors: [ColorItem] = [
        ColorItem(name: "Rojo", color: Color(hex: "#FF8A80"), icon: "heart.fill"),
        ColorItem(name: "Azul", color: Color(hex: "#82B1FF"), icon: "drop.fill"),
        ColorItem(name: "Verde", color: Color(hex: "#B9F6CA"), icon: "leaf.fill"),
        ColorItem(name: "Amarillo", color: Color(hex: "#FFFF8D"), icon: "sun.max.fill"),
        ColorItem(name: "Naranja", color: Color(hex: "#FFD180"), icon: "flame.fill"),
        ColorItem(name: "Morado", color: Color(hex: "#EA80FC"), icon: "star.fill")
    ]
}

// MARK: - CLASE DE AUDIO
class Speaker: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    func speak(_ text: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.1
        
        synthesizer.speak(utterance)
    }
}

// MARK: - VISTA PRINCIPAL
struct JuegoArcoirisView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var speaker = Speaker()
    
    @State private var targetColor: ColorItem = ColorItem.allColors.randomElement()!
    @State private var options: [ColorItem] = []
    @State private var score = 0
    
    @State private var showSuccess = false
    @State private var animateCharacter = false
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
                    
                    Button(action: { speaker.speak("Busca el color \(targetColor.name)") }) {
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
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 260, height: 260)
                            .blur(radius: 20)
                        
                        PaintBlobView(color: targetColor.color)
                            .frame(width: 220, height: 220)
                            .shadow(color: targetColor.color.opacity(0.4), radius: 15, y: 10)
                            .scaleEffect(animateCharacter ? 1.1 : 1.0)
                            .offset(x: shakeError ? -10 : (shakeError ? 10 : 0))
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: animateCharacter)
                            .animation(.default.repeatCount(3, autoreverses: true).speed(2), value: shakeError)
                    }
                    .onTapGesture {
                        speaker.speak(targetColor.name)
                        withAnimation { animateCharacter.toggle() }
                    }
                    
                    Text("¿Cuál es el color **\(targetColor.name)**?")
                        .font(DesignSystem.Fonts.header())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(options) { item in
                        ColorOptionButton(item: item) {
                            checkAnswer(item)
                        }
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
        targetColor = ColorItem.allColors.randomElement()!
        
        var newOptions = [targetColor]
        while newOptions.count < 4 {
            if let random = ColorItem.allColors.randomElement(), !newOptions.contains(random) {
                newOptions.append(random)
            }
        }
        
        options = newOptions.shuffled()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            speaker.speak("Busca el color \(targetColor.name)")
        }
    }
    
    func checkAnswer(_ item: ColorItem) {
        if item == targetColor {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            speaker.speak("¡Muy bien! Es \(item.name)")
            
            withAnimation {
                score += 10
                showSuccess = true
                animateCharacter = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSuccess = false
                animateCharacter = false
                startNewRound()
            }
            
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            withAnimation { shakeError = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shakeError = false }
        }
    }
}

// MARK: - PERSONAJE
struct PaintBlobView: View {
    let color: Color
    
    var body: some View {
        ZStack {
            Image(systemName: "seal.fill")
                .resizable()
                .foregroundStyle(color.gradient)
            
            HStack(spacing: 35) {
                Circle().fill(.white).frame(width: 35, height: 35)
                    .overlay(Circle().fill(.black).frame(width: 15, height: 15).offset(x: 5))
                
                Circle().fill(.white).frame(width: 35, height: 35)
                    .overlay(Circle().fill(.black).frame(width: 15, height: 15).offset(x: 5))
            }
            .offset(y: -10)
            
            Circle()
                .trim(from: 0.0, to: 0.5)
                .stroke(Color.black.opacity(0.7), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 30, height: 20)
                .offset(y: 30)
        }
    }
}

// MARK: - BOTONES DE COLORES
struct ColorOptionButton: View {
    let item: ColorItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(item.name)
                    .font(DesignSystem.Fonts.body().bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 25)
            .background(item.color)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white, lineWidth: 3)
            )
            .shadow(color: item.color.opacity(0.4), radius: 8, y: 5)
        }
    }
}

#Preview {
    JuegoArcoirisView()
}
