import SwiftUI


struct GameItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let destinationView: AnyView
}

struct MainMenuView: View {
   
    let games: [GameItem] = [
        GameItem(
            title: "Matematicas",
            icon: "balloon.2.fill",
            color: Color(hex: "#FFAB91"),
            destinationView: AnyView(ViajeAereoMatematicoView())
        ),
        GameItem(
            title: "Trazos Magicos",
            icon: "scribble.variable",
            color: Color(hex: "#A96BFF"),
            destinationView: AnyView(TrazosMagicosView())
        ),
        GameItem(
            title: "Colores",
            icon: "paintpalette.fill",
            color: Color(hex: "#A5D6A7"),
            destinationView: AnyView(JuegoArcoirisView())
        ),
        GameItem(
            title: "Letras",
            icon: "textformat.abc",
            color: Color(hex: "#FFD54F"),
            destinationView: AnyView(JuegoAlfabetoView())
        ),
        GameItem(
            title: "Repite",
            icon: "circle.hexagongrid.fill",
            color: Color(hex: "#B197FC"),
            destinationView: AnyView(SecuenciaMagicaView())
        ),
        GameItem(
            title: "Colorear",
            icon: "paintpalette.fill",
            color: Color(hex: "#FF85C0"),
            destinationView: AnyView(ColoreaYCreaView())
        )
    ]
    
 
    @State private var animateMascot = false
    
    var body: some View {
        NavigationView {
            ZStack {
               
                DesignSystem.Colors.backgroundGradient
                    .ignoresSafeArea()
                
              
                GeometryReader { geo in
                    ZStack {
                        MenuMovingCloud(delay: 0, yPos: geo.size.height * 0.05, duration: 40)
                        MenuMovingCloud(delay: 10, yPos: geo.size.height * 0.4, duration: 50)
                        MenuMovingCloud(delay: 5, yPos: geo.size.height * 0.8, duration: 45)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("¡Hola, Explorador!")
                                    .font(DesignSystem.Fonts.header())
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Text("¿Qué jugamos?")
                                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 90, height: 90)
                                    .blur(radius: 10)
                                
                                Image("brain_mascot")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .rotationEffect(.degrees(animateMascot ? 5 : -5))
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                            }
                            .onAppear {
                                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                    animateMascot = true
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 25),
                            GridItem(.flexible(), spacing: 25)
                        ], spacing: 25) {
                            ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                                NavigationLink(destination:
                                    game.destinationView
                                        .animation(nil, value: UUID())
                                        .transaction { $0.animation = nil } 
                                ) {
                                    EnhancedGameCard(game: game, index: index)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                        
                        
                    }
                    .padding(25)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - COMPONENTES UI

struct EnhancedGameCard: View {
    let game: GameItem
    let index: Int
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(game.color.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: game.icon)
                    .font(.system(size: 45))
                    .foregroundColor(game.color)
                    .shadow(color: game.color.opacity(0.5), radius: 8, x: 0, y: 4)
            }
            
            Text(game.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 25)
        .background(Color.white.opacity(0.9))
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: game.color.opacity(0.15), radius: 15, x: 0, y: 8)
        .offset(y: isAnimating ? 0 : 50)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            // Esta animación es solo para la entrada de las tarjetas, no afecta a los juegos
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
                isAnimating = true
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct MenuMovingCloud: View {
    let delay: Double
    let yPos: CGFloat
    let duration: Double
    @State private var move = false
    
    var body: some View {
        GeometryReader { geo in
            Image(systemName: "cloud.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.6))
                .position(x: -100, y: yPos)
                .offset(x: move ? geo.size.width + 250 : 0)
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: duration)
                            .repeatForever(autoreverses: false)
                            .delay(delay)
                    ) {
                        move = true
                    }
                }
        }
    }
}

#Preview {
    MainMenuView()
}
