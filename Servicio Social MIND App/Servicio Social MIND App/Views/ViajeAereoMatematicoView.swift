import SwiftUI
import AVFoundation
import Combine

// MARK: - 1. MODELO DE NIVELES Y DATOS
enum MathLevel: Int, CaseIterable {
    case one = 1, two, three, four, five, six
    
    var title: String { "Nivel \(self.rawValue)" }
    
    var description: String {
        switch self {
        case .one: return "Sumas con dedos (1-5)"
        case .two: return "Sumas grandes (1-10)"
        case .three: return "Restas fáciles (1-5)"
        case .four: return "Restas grandes (1-10)"
        case .five: return "Mix de prueba (1-15)"
        case .six: return "Maestro del Cielo (1-20)"
        }
    }
    
    var badgeIcon: String {
        switch self {
        case .one: return "star.fill"
        case .two: return "moon.stars.fill"
        case .three: return "sun.max.fill"
        case .four: return "cloud.rainbow.half.fill"
        case .five: return "airplane"
        case .six: return "crown.fill"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .one: return Color(hex: "#FFD54F") // Amarillo
        case .two: return Color(hex: "#90CAF9") // Azul
        case .three: return Color(hex: "#FFAB91") // Naranja
        case .four: return Color(hex: "#CE93D8") // Lila
        case .five: return Color(hex: "#80CBC4") // Aqua
        case .six: return Color(hex: "#F48FB1") // Rosa
        }
    }
    
    func generateQuestion() -> MathQuestion {
        let isSum: Bool
        let range: ClosedRange<Int>
        switch self {
        case .one:   isSum = true;  range = 1...5
        case .two:   isSum = true;  range = 1...10
        case .three: isSum = false; range = 1...5
        case .four:  isSum = false; range = 1...10
        case .five:  isSum = Bool.random(); range = 1...15
        case .six:   isSum = Bool.random(); range = 1...20
        }
        let num1 = Int.random(in: range); let num2 = Int.random(in: 1...range.upperBound)
        let val1 = max(num1, num2); let val2 = min(num1, num2)
        let answer = isSum ? val1 + val2 : val1 - val2
        if isSum && answer > 20 { return generateQuestion() }
        let text = isSum ? "\(val1) + \(val2)" : "\(val1) - \(val2)"
        var optionsSet: Set<Int> = [answer]
        while optionsSet.count < 3 {
            let fake = answer + Int.random(in: -4...4)
            if fake >= 0 && fake != answer { optionsSet.insert(fake) }
        }
        return MathQuestion(text: text, answer: answer, options: Array(optionsSet).shuffled())
    }
}

struct MathQuestion {
    let text: String
    let answer: Int
    let options: [Int]
}

// MARK: - 2. GESTOR DE PROGRESO
class MathProgress: ObservableObject {
    @Published var currentLevel: MathLevel = .one
    @Published var currentScore: Int = 0
    @Published var unlockedLevels: Int = 1
    let targetScore = 5
    
    func addScore() -> Bool {
        currentScore += 1
        if currentScore >= targetScore {
            unlockNextLevel()
            return true
        }
        return false
    }
    func unlockNextLevel() { if unlockedLevels < currentLevel.rawValue + 1 { unlockedLevels = currentLevel.rawValue + 1 } }
    func nextLevel() { if let next = MathLevel(rawValue: currentLevel.rawValue + 1) { currentLevel = next; currentScore = 0 } }
    func resetLevel() { currentScore = 0 }
}

// MARK: - 3. VISTA PRINCIPAL 
struct ViajeAereoMatematicoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var progress = MathProgress()
    
 
    @State private var showGameScreen = false
    @State private var showLevelSelection = false
    @State private var showRewards = false
    
    var body: some View {
        ZStack {
            // 1. FONDO GLOBAL
            DesignSystem.Colors.backgroundGradient.ignoresSafeArea()
            
            // Nubes Flotando
            GeometryReader { geo in
                ZStack {
                    FloatingCloud(delay: 0, x: geo.size.width * 0.1, y: geo.size.height * 0.1)
                    FloatingCloud(delay: 2, x: geo.size.width * 0.8, y: geo.size.height * 0.25)
                    FloatingCloud(delay: 1, x: geo.size.width * 0.2, y: geo.size.height * 0.4)
                    FloatingCloud(delay: 3, x: geo.size.width * 0.85, y: geo.size.height * 0.6)
                }
            }
            
            // 2. MENÚ DE INICIO DEL JUEGO
            VStack(spacing: 0) {
                
                // HEADER
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 45))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                            .background(Color.white.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Título y Globo
                VStack(spacing: 10) {
                    Spacer()
                    Text("Viaje Aéreo")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .shadow(color: .white, radius: 2)
                    
                    HotAirBalloon()
                        .frame(width: 220, height: 280)
                        .shadow(color: Color.black.opacity(0.15), radius: 15, y: 10)
                        .scaleEffect(1.1)
                    
                    Spacer()
                }
                
                // --- BOTONES ---
                VStack(spacing: 18) {
                    ShinyMenuButton(title: "Jugar", icon: "play.fill", color: Color(hex: "#FFAB91")) {
                        showGameScreen = true
                    }
                    ShinyMenuButton(title: "Niveles", icon: "list.star", color: Color(hex: "#7986CB")) {
                        showLevelSelection = true
                    }
                    ShinyMenuButton(title: "Logros", icon: "trophy.fill", color: Color(hex: "#FFF176")) {
                        showRewards = true
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
          
            .transaction { $0.animation = nil }
        }
        // NAVEGACIÓN
        .fullScreenCover(isPresented: $showGameScreen) {
            GamePlayView(progress: progress)
        }
        .sheet(isPresented: $showLevelSelection) {
            LevelSelectionView(progress: progress, showGameScreen: $showGameScreen)
        }
        .sheet(isPresented: $showRewards) {
            RewardsView(progress: progress)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - 4. PANTALLA DE JUEGO
struct GamePlayView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var progress: MathProgress
    
    @State private var question: MathQuestion
    @State private var showSuccess = false
    @State private var showError = false
    @State private var showLevelComplete = false
    
    init(progress: MathProgress) {
        self.progress = progress
        _question = State(initialValue: progress.currentLevel.generateQuestion())
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundGradient.ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    FloatingCloud(delay: 0, x: geo.size.width * 0.15, y: geo.size.height * 0.15)
                    FloatingCloud(delay: 2, x: geo.size.width * 0.85, y: geo.size.height * 0.3)
                }
            }
            
            VStack {
                // --- HEADER ---
                ZStack {
                  
                    Text(progress.currentLevel.title)
                        .font(DesignSystem.Fonts.body())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(12)
                    
                
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 45))
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                                .background(Color.white.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                      
                        HStack(spacing: 4) {
                            ForEach(0..<progress.targetScore, id: \.self) { i in
                                Circle()
                                    .fill(i < progress.currentScore ? DesignSystem.Colors.success : Color.white.opacity(0.5))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Globo
                ZStack {
                    HotAirBalloon()
                        .frame(width: 180, height: 220)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)
                        .offset(y: showSuccess ? -60 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showSuccess)
                }
                .padding(.bottom, 20)
                
                Spacer()
                
                
                DesignSystem.MagicCard {
                    VStack(spacing: 20) {
                        Text("Resuelve:")
                            .font(DesignSystem.Fonts.body())
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(question.text)
                            .font(DesignSystem.Fonts.bigNumber())
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        HStack(spacing: 15) {
                            ForEach(question.options, id: \.self) { option in
                                AnswerButton(number: option) {
                                    checkAnswer(option)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 15)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            
            if showSuccess && !showLevelComplete {
                VStack {
                    Text("¡Excelente!")
                        .font(DesignSystem.Fonts.title())
                        .foregroundColor(DesignSystem.Colors.success)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                }
                .offset(y: -250)
                .transition(.scale.combined(with: .opacity))
                .zIndex(5)
            }
            
            if showLevelComplete {
                LevelCompleteView(level: progress.currentLevel) {
                    progress.nextLevel()
                    question = progress.currentLevel.generateQuestion()
                    withAnimation { showLevelComplete = false }
                }
                .zIndex(10)
                .transition(.scale)
            }
        }
    }
    
    func checkAnswer(_ selected: Int) {
        if selected == question.answer {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1026)
            withAnimation { showSuccess = true }
            if progress.addScore() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showSuccess = false; withAnimation { showLevelComplete = true } }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showSuccess = false; question = progress.currentLevel.generateQuestion() }
            }
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            withAnimation { showError = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showError = false }
        }
    }
}

// MARK: - 5. VISTAS DE NAVEGACIÓN
struct LevelSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var progress: MathProgress
    @Binding var showGameScreen: Bool
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundGradient.ignoresSafeArea()
            VStack {
                HStack {
                    Spacer(); Text("Niveles").font(DesignSystem.Fonts.title()).foregroundColor(DesignSystem.Colors.textPrimary); Spacer()
                    Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").font(.title).foregroundColor(DesignSystem.Colors.textSecondary) }
                }.padding()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(MathLevel.allCases, id: \.self) { level in
                            let isUnlocked = level.rawValue <= progress.unlockedLevels
                            Button(action: { if isUnlocked { progress.currentLevel = level; progress.resetLevel(); showGameScreen = true; dismiss() } }) {
                                VStack(spacing: 10) {
                                    Image(systemName: isUnlocked ? "play.circle.fill" : "lock.fill").font(.system(size: 40)).foregroundColor(isUnlocked ? level.badgeColor : .gray)
                                    Text(level.title).font(DesignSystem.Fonts.header()).foregroundColor(DesignSystem.Colors.textPrimary)
                                    Text(level.description).font(.caption).foregroundColor(.gray).multilineTextAlignment(.center)
                                }.padding().frame(maxWidth: .infinity).background(Color.white.opacity(0.9)).cornerRadius(20).opacity(isUnlocked ? 1.0 : 0.6)
                            }.disabled(!isUnlocked)
                        }
                    }.padding()
                }
            }
        }
    }
}

struct RewardsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var progress: MathProgress
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundGradient.ignoresSafeArea()
            VStack {
                HStack {
                    Spacer(); Text("Mis Logros").font(DesignSystem.Fonts.title()).foregroundColor(DesignSystem.Colors.textPrimary); Spacer()
                    Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").font(.title).foregroundColor(DesignSystem.Colors.textSecondary) }
                }.padding()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(MathLevel.allCases, id: \.self) { level in
                            let isUnlocked = level.rawValue <= progress.unlockedLevels
                            VStack {
                                Image(systemName: isUnlocked ? level.badgeIcon : "lock.fill").font(.system(size: 50)).foregroundColor(isUnlocked ? level.badgeColor : .gray.opacity(0.3)).padding().background(Circle().fill(Color.white)).shadow(radius: isUnlocked ? 5 : 0)
                                Text(level.title).font(DesignSystem.Fonts.body()).foregroundColor(.gray)
                            }.padding().background(Color.white.opacity(0.6)).cornerRadius(20)
                        }
                    }.padding()
                }
            }
        }
    }
}

// MARK: - 6. COMPONENTES VISUALES NUEVOS

struct ShinyMenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 30)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(color: color.opacity(0.5), radius: 10, y: 5)
        }
    }
}

struct FloatingCloud: View {
    let delay: Double
    let x: CGFloat
    let y: CGFloat
    @State private var offset: CGFloat = 0
    var body: some View {
        Image(systemName: "cloud.fill").font(.system(size: 80)).foregroundColor(.white.opacity(0.6)).position(x: x, y: y).offset(x: offset).onAppear { withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true).delay(delay)) { offset = 30 } }
    }
}

struct HotAirBalloon: View {
    @State private var hover = false
    var body: some View {
        ZStack {
            HStack(spacing: 20) { Rectangle().frame(width: 2, height: 40).foregroundColor(.gray); Rectangle().frame(width: 2, height: 40).foregroundColor(.gray) }.offset(y: 60)
            RoundedRectangle(cornerRadius: 5).fill(Color(hex: "#8D6E63")).frame(width: 40, height: 30).offset(y: 80)
            Circle().fill(LinearGradient(colors: [DesignSystem.Colors.primary, Color(hex: "#FFCCBC")], startPoint: .top, endPoint: .bottom)).frame(width: 140, height: 140).overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 4).padding(10))
            Path { path in
                path.move(to: CGPoint(x: 70, y: 140)); path.addQuadCurve(to: CGPoint(x: 70, y: 0), control: CGPoint(x: 20, y: 70))
                path.move(to: CGPoint(x: 70, y: 140)); path.addQuadCurve(to: CGPoint(x: 70, y: 0), control: CGPoint(x: 120, y: 70))
            }.stroke(Color.white.opacity(0.4), lineWidth: 2).frame(width: 140, height: 140)
        }
        .offset(y: hover ? -10 : 10)
        .onAppear { withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { hover = true } }
    }
}

struct AnswerButton: View {
    let number: Int
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("\(number)").font(DesignSystem.Fonts.title()).foregroundColor(DesignSystem.Colors.textPrimary).frame(width: 85, height: 85).background(Color.white).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(DesignSystem.Colors.primary.opacity(0.5), lineWidth: 3)).shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
        }
    }
}

struct LevelCompleteView: View {
    let level: MathLevel
    let onNext: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            ConfettiView()
            VStack(spacing: 25) {
                Text("🎉").font(.system(size: 80))
                Text("¡Nivel Completado!").font(DesignSystem.Fonts.title()).foregroundColor(DesignSystem.Colors.textPrimary)
                Button(action: onNext) { Text("Siguiente").font(DesignSystem.Fonts.header()).foregroundColor(.white).padding(.vertical, 15).padding(.horizontal, 40).background(DesignSystem.Colors.primary).cornerRadius(25).shadow(radius: 5) }.padding(.top, 10)
            }.padding(40).background(Color.white).cornerRadius(30).shadow(radius: 20).padding()
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    var body: some View { ZStack { ForEach(0..<30) { _ in Circle().fill([Color.red, Color.blue, Color.green, Color.yellow, Color.purple].randomElement()!).frame(width: 10, height: 10).offset(x: animate ? CGFloat.random(in: -200...200) : 0, y: animate ? CGFloat.random(in: 200...500) : -300).animation(Animation.linear(duration: Double.random(in: 2...4)).repeatForever(autoreverses: false), value: animate) } }.onAppear { animate = true } }
}

#Preview {
    ViajeAereoMatematicoView()
}
