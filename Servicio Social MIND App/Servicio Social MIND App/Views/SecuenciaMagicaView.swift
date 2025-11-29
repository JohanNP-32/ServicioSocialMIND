import SwiftUI
import AVFoundation
import Combine

// MARK: - 1. MODELO DEL JUEGO

enum SequenceGameState {
    case intro
    case preparing
    case showing
    case waiting
    case correct
    case wrong
}

struct SequenceColorItem: Identifiable, Equatable {
    let id: Int
    let color: Color
    let name: String
    let icon: String
    
    static let allColors: [SequenceColorItem] = [
        SequenceColorItem(id: 0, color: Color(hex: "#FF6B6B"), name: "Rojo", icon: "heart.fill"),
        SequenceColorItem(id: 1, color: Color(hex: "#51CF66"), name: "Verde", icon: "leaf.fill"),
        SequenceColorItem(id: 2, color: Color(hex: "#4DABF7"), name: "Azul", icon: "drop.fill"),
        SequenceColorItem(id: 3, color: Color(hex: "#FFD93D"), name: "Amarillo", icon: "sun.max.fill"),
        SequenceColorItem(id: 4, color: Color(hex: "#B197FC"), name: "Morado", icon: "star.fill"),
        SequenceColorItem(id: 5, color: Color(hex: "#FF922B"), name: "Naranja", icon: "flame.fill"),
        SequenceColorItem(id: 6, color: Color(hex: "#FF85C0"), name: "Rosa", icon: "sparkles"),
        SequenceColorItem(id: 7, color: Color(hex: "#20C997"), name: "Turquesa", icon: "moon.stars.fill")
    ]
}

// MARK: - 2. CLASE DE AUDIO MEJORADA

class SequenceSoundPlayer: ObservableObject {
    private let synth = AVSpeechSynthesizer()
    
    func playButtonSound(colorId: Int) {
       
        let soundId: SystemSoundID = 1104 + UInt32(colorId % 4)
        AudioServicesPlaySystemSound(soundId)
    }
    
    func playCorrectSound() {
        
        AudioServicesPlaySystemSound(1054)
    }
    
    func playWrongSound() {
        AudioServicesPlaySystemSound(1053)
    }
    
    func playLevelComplete() {
     
        AudioServicesPlaySystemSound(1026)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AudioServicesPlaySystemSound(1054)
        }
    }
    
    func speak(_ text: String) {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.2
        synth.speak(utterance)
    }
}

// MARK: - 3. LÓGICA DEL JUEGO

class SequenceGame: ObservableObject {
    @Published var gameState: SequenceGameState = .intro
    @Published var sequence: [Int] = []
    @Published var userInput: [Int] = []
    @Published var level: Int = 1
    @Published var currentHighlight: Int? = nil
    @Published var score: Int = 0
    @AppStorage("sequence_best_score") var bestScore: Int = 0
    
    let soundPlayer = SequenceSoundPlayer()
    private var cancellables = Set<AnyCancellable>()
    
    func startGame() {
        level = 1
        score = 0
        sequence = []
        generateNewSequence()
        gameState = .preparing
        
        soundPlayer.speak("¡Prepárate!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showSequence()
        }
    }
    
    func generateNewSequence() {
        if sequence.isEmpty {
            sequence = [Int.random(in: 0..<8)]
        } else {
            sequence.append(Int.random(in: 0..<8))
        }
        userInput = []
    }
    
    func showSequence() {
        gameState = .showing
        soundPlayer.speak("Mira bien la secuencia")
        
        var delay: Double = 1.0
        
        for (index, colorId) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.highlightButton(colorId)
                self.soundPlayer.playButtonSound(colorId: colorId)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.currentHighlight = nil
                    
                    if index == self.sequence.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.gameState = .waiting
                            self.soundPlayer.speak("¡Ahora tú!")
                        }
                    }
                }
            }
            delay += 0.9
        }
    }
    
    func highlightButton(_ id: Int) {
        currentHighlight = id
    }
    
    func playerTapped(_ id: Int) {
        guard gameState == .waiting else { return }
        
        userInput.append(id)
        highlightButton(id)
        soundPlayer.playButtonSound(colorId: id)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.currentHighlight = nil
            self.validateInput()
        }
    }
    
    func validateInput() {
        let currentIndex = userInput.count - 1
        
        if userInput[currentIndex] != sequence[currentIndex] {
            
            gameState = .wrong
            soundPlayer.playWrongSound()
            soundPlayer.speak("¡Ups! Inténtalo de nuevo")
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.resetGame()
            }
        } else if userInput.count == sequence.count {
        
            gameState = .correct
            score += 10
            
            if score > bestScore {
                bestScore = score
            }
            
            soundPlayer.playLevelComplete()
            soundPlayer.speak("¡Excelente!")
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.level += 1
                self.generateNewSequence()
                self.gameState = .preparing
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showSequence()
                }
            }
        }
    }
    
    func resetGame() {
        sequence = []
        userInput = []
        level = 1
        score = 0
        gameState = .intro
    }
}

// MARK: - 4. VISTA PRINCIPAL

struct SecuenciaMagicaView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var game = SequenceGame()
    
    var body: some View {
        ZStack {
          
            DesignSystem.Colors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if game.gameState == .intro {
                    IntroSequenceView(game: game, onDismiss: { dismiss() })
                } else {
                    GameplaySequenceView(game: game, onDismiss: { dismiss() })
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - 5. PANTALLA DE INICIO

struct IntroSequenceView: View {
    @ObservedObject var game: SequenceGame
    let onDismiss: () -> Void
    
    @State private var mascotBounce = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 45))
                        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
           
            VStack(spacing: 25) {
                ZStack {
                 
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                    
                    
                    SequenceMascot()
                        .scaleEffect(1.2)
                        .offset(y: mascotBounce ? -15 : 10)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        mascotBounce = true
                    }
                }
                
                Text("Secuencia Mágica")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .shadow(color: .white, radius: 1)
                
                Text("¡Memoriza y repite los colores!")
                    .font(DesignSystem.Fonts.body())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
         
            DesignSystem.BigButton(
                title: "JUGAR",
                icon: "play.fill",
                color: Color(hex: "#B197FC")
            ) {
                game.startGame()
            }
            .padding(.horizontal, 40)
            
          
            HStack(spacing: 20) {
                StatCard(icon: "star.fill", label: "Nivel Actual", value: "\(game.level)", color: Color(hex: "#FFD93D"))
                StatCard(icon: "trophy.fill", label: "Récord", value: "\(game.bestScore)", color: DesignSystem.Colors.warning)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - 6. PANTALLA DE JUEGO

struct GameplaySequenceView: View {
    @ObservedObject var game: SequenceGame
    let onDismiss: () -> Void
    
    var instructionText: String {
        switch game.gameState {
        case .intro: return ""
        case .preparing: return "¡Prepárate!"
        case .showing: return "Mira bien..."
        case .waiting: return "¡Ahora tú!"
        case .correct: return "¡Excelente! 🎉"
        case .wrong: return "¡Ups! Inténtalo de nuevo"
        }
    }
    
    var mascotMood: MascotMood {
        switch game.gameState {
        case .correct: return .happy
        case .wrong: return .sad
        default: return .normal
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    game.resetGame()
                    onDismiss()
                }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 45))
                        .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                }
                
                Spacer()
                
                Button(action: {
                    game.soundPlayer.speak(instructionText)
                }) {
                    Image(systemName: "speaker.wave.2.circle.fill")
                        .font(.system(size: 45))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Spacer()
                
              
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text("\(game.score)")
                        .font(DesignSystem.Fonts.title())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.6))
                .cornerRadius(20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer().frame(height: 30)
            
            
            VStack(spacing: 15) {
                ZStack {
                    SequenceMascot()
                        .scaleEffect(game.gameState == .wrong ? 0.85 : 1.0)
                        .offset(x: game.gameState == .wrong ? -8 : 0)
                        .animation(
                            game.gameState == .wrong ?
                                .default.repeatCount(5).speed(4) :
                                .spring(response: 0.5, dampingFraction: 0.7),
                            value: game.gameState
                        )
                    
                    
                    if game.gameState == .correct {
                        ConfettiCelebration()
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 150)
                
             
                VStack(spacing: 8) {
                    Text("Nivel \(game.level)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(12)
                    
                    Text(instructionText)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: instructionText)
                }
            }
            
            Spacer().frame(height: 40)
            
           
            SequenceColorGrid(game: game)
                .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// MARK: - 7. GRID DE COLORES

struct SequenceColorGrid: View {
    @ObservedObject var game: SequenceGame
    
    let columns = [
        GridItem(.flexible(), spacing: 25),
        GridItem(.flexible(), spacing: 25),
        GridItem(.flexible(), spacing: 25),
        GridItem(.flexible(), spacing: 25)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 25) {
            ForEach(SequenceColorItem.allColors) { item in
                SequenceColorButton(
                    item: item,
                    isHighlighted: game.currentHighlight == item.id,
                    isEnabled: game.gameState == .waiting
                ) {
                    game.playerTapped(item.id)
                }
            }
        }
    }
}

struct SequenceColorButton: View {
    let item: SequenceColorItem
    let isHighlighted: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            action()
        }) {
            ZStack {
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [item.color, item.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                
             
                Image(systemName: item.icon)
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.9))
                
               
                if isHighlighted {
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 88, height: 88)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: isHighlighted ? 6 : 4)
                    .frame(width: 88, height: 88)
            )
            .shadow(
                color: isHighlighted ? item.color.opacity(0.8) : item.color.opacity(0.3),
                radius: isHighlighted ? 18 : 10,
                y: 5
            )
            .scaleEffect(isHighlighted ? 1.15 : (isPressed ? 0.92 : 1.0))
            .brightness(isHighlighted ? 0.15 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHighlighted)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - 8. COMPONENTES VISUALES

enum MascotMood {
    case normal, happy, sad
}

struct SequenceMascot: View {
    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#B197FC").opacity(0.7),
                            Color(hex: "#7C3AED").opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.5), lineWidth: 4)
                )
            
      
            VStack(spacing: 15) {
       
                HStack(spacing: 28) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 25, height: 25)
                        .overlay(
                            Circle()
                                .fill(DesignSystem.Colors.textPrimary)
                                .frame(width: 12, height: 12)
                                .offset(x: 3)
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 25, height: 25)
                        .overlay(
                            Circle()
                                .fill(DesignSystem.Colors.textPrimary)
                                .frame(width: 12, height: 12)
                                .offset(x: 3)
                        )
                }
                .offset(y: -5)
                
         
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.white)
                    .frame(width: 45, height: 8)
                    .offset(y: -5)
                
            
                HStack(spacing: 5) {
                    ForEach(0..<4) { i in
                        Circle()
                            .fill(SequenceColorItem.allColors[i].color)
                            .frame(width: 10, height: 10)
                    }
                }
                .offset(y: 5)
            }
        }
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption.bold())
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.7))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
    }
}

struct ConfettiCelebration: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<25, id: \.self) { index in
                Circle()
                    .fill(SequenceColorItem.allColors[index % 8].color)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: animate ? CGFloat.random(in: -180...180) : 0,
                        y: animate ? CGFloat.random(in: -250...250) : 0
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.8)) {
                animate = true
            }
        }
    }
}

// MARK: - 9. PREVIEW

#Preview {
    SecuenciaMagicaView()
}
