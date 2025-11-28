import SwiftUI
import AVFoundation
import Combine

// MARK: - MODELO DE DATOS
struct LetterItem: Identifiable, Equatable {
    let id = UUID()
    let character: String
    let word: String
    let icon: String // SF Symbol para asegurar que se vea bien sin assets externos
    let color: Color
    
    // Un set básico de letras con iconos de SF Symbols que los niños reconocen
    static let allLetters: [LetterItem] = [
        LetterItem(character: "A", word: "Avión", icon: "airplane", color: Color(hex: "#EF9A9A")), // Rojo suave
        LetterItem(character: "B", word: "Bici", icon: "bicycle", color: Color(hex: "#90CAF9")), // Azul suave
        LetterItem(character: "C", word: "Casa", icon: "house.fill", color: Color(hex: "#A5D6A7")), // Verde suave
        LetterItem(character: "E", word: "Estrella", icon: "star.fill", color: Color(hex: "#FFF59D")), // Amarillo
        LetterItem(character: "F", word: "Flor", icon: "camera.macro", color: Color(hex: "#F48FB1")), // Rosa
        LetterItem(character: "G", word: "Gato", icon: "cat.fill", color: Color(hex: "#CE93D8")), // Lila
        LetterItem(character: "L", word: "Luna", icon: "moon.stars.fill", color: Color(hex: "#B0BEC5")), // Gris azulado
        LetterItem(character: "M", word: "Mano", icon: "hand.raised.fill", color: Color(hex: "#FFCC80")), // Naranja
        LetterItem(character: "R", word: "Reloj", icon: "clock.fill", color: Color(hex: "#80CBC4")), // Aqua
        LetterItem(character: "S", word: "Sol", icon: "sun.max.fill", color: Color(hex: "#FFAB91"))  // Coral
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
        utterance.pitchMultiplier = 1.15 // Voz amigable
        
        synthesizer.speak(utterance)
    }
}

// MARK: - VISTA PRINCIPAL
struct JuegoAlfabetoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var speaker = AlphabetSpeaker()
    
    // Estado del juego
    @State private var currentLetter: LetterItem = LetterItem.allLetters.randomElement()!
    @State private var options: [LetterItem] = []
    @State private var score = 0
    
    // Animaciones
    @State private var isRevealed = false // Controla si se muestra el objeto
    @State private var showSuccess = false
    @State private var shakeError = false
    
    var body: some View {
        ZStack {
            // 1. FONDO (Cielo)
            DesignSystem.Colors.backgroundGradient
                .ignoresSafeArea()
            
            // Confeti al ganar
            if showSuccess {
                Color.white.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            VStack {
                // 2. HEADER
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 45))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.5))
                    }
                    Spacer()
                    
                    // Botón Repetir Instrucción
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
                    
                    // Score
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
                
                // 3. TARJETA PRINCIPAL (EL RETO)
                VStack(spacing: 20) {
                    FlipCardView(
                        item: currentLetter,
                        isRevealed: isRevealed
                    )
                    .frame(height: 280)
                    .onTapGesture {
                        // Repetir sonido al tocar la tarjeta
                        if isRevealed {
                            speaker.speak(currentLetter.word)
                        } else {
                            speaker.speak(currentLetter.character)
                        }
                    }
                    .offset(x: shakeError ? -10 : (shakeError ? 10 : 0))
                    .animation(.default.repeatCount(3, autoreverses: true).speed(2), value: shakeError)
                    
                    // Instrucción visual
                    Text(isRevealed ? "¡\(currentLetter.character) de \(currentLetter.word)!" : "¿Dónde está la letra **\(currentLetter.character)**?")
                        .font(DesignSystem.Fonts.header())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: isRevealed)
                }
                
                Spacer()
                
                // 4. OPCIONES (GRID)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                    ForEach(options) { option in
                        LetterOptionButton(letter: option.character, color: option.color) {
                            checkAnswer(option)
                        }
                        .disabled(isRevealed) // Bloquear botones al ganar
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startNewRound()
        }
    }
    
    // --- LÓGICA ---
    func startNewRound() {
        isRevealed = false
        showSuccess = false
        
        // Elegir nueva letra (asegurar que sea diferente a la anterior si es posible)
        let previous = currentLetter
        repeat {
            currentLetter = LetterItem.allLetters.randomElement()!
        } while currentLetter == previous && LetterItem.allLetters.count > 1
        
        // Generar opciones
        var newOptions = [currentLetter]
        while newOptions.count < 4 {
            if let random = LetterItem.allLetters.randomElement(), !newOptions.contains(random) {
                newOptions.append(random)
            }
        }
        options = newOptions.shuffled()
        
        // Audio inicial
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            speaker.speak("Encuentra la letra \(currentLetter.character)")
        }
    }
    
    func checkAnswer(_ selected: LetterItem) {
        if selected == currentLetter {
            // CORRECTO
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                isRevealed = true // Voltear tarjeta
                showSuccess = true
                score += 10
            }
            
            speaker.speak("¡Sí! \(currentLetter.character) de \(currentLetter.word)")
            AudioServicesPlaySystemSound(1026)
            
            // Esperar más tiempo para que el niño vea el dibujo
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                startNewRound()
            }
        } else {
            // INCORRECTO
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            withAnimation { shakeError = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shakeError = false }
            
            speaker.speak("Intenta de nuevo")
        }
    }
}

// MARK: - COMPONENTES VISUALES

// Tarjeta que se voltea (Flip Card)
struct FlipCardView: View {
    let item: LetterItem
    let isRevealed: Bool
    
    var body: some View {
        ZStack {
            // ESTADO 1: Pregunta (Solo Letra)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .opacity(isRevealed ? 0 : 1)
            .rotation3DEffect(.degrees(isRevealed ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            
            // ESTADO 2: Revelación (Imagen + Palabra)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .opacity(isRevealed ? 1 : 0)
            .rotation3DEffect(.degrees(isRevealed ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .padding(.horizontal, 40)
    }
}

// Botón de Opción (Nube con Letra)
struct LetterOptionButton: View {
    let letter: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Forma de nube suave
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
        .buttonStyle(ScaleButtonStyle()) // Reutilizamos la animación de pulsación del menú
    }
}

#Preview {
    JuegoAlfabetoView()
}
