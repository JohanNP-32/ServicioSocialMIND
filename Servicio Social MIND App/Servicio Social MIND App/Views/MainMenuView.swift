import SwiftUI

// Modelo de datos para el menú
struct GameItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let destinationView: AnyView
}

struct MainMenuView: View {
    // Columnas adaptables
    let columns = [
        GridItem(.flexible(), spacing: 25),
        GridItem(.flexible(), spacing: 25)
    ]
    
    // DEFINICIÓN DE JUEGOS 
    let games: [GameItem] = [
        GameItem(
            title: "Matematicas",
            icon: "balloon.2.fill", // O "plus.forwardslash.minus"
            color: Color(hex: "#FFAB91"), // Coral
            destinationView: AnyView(ViajeAereoMatematicoView())
        ),
        GameItem(
            title: "Trazos Magicos",
            icon: "scribble.variable",
            color: Color(hex: "#A96BFF"), // Morado
            destinationView: AnyView(TrazosMagicosView())
        ),
        GameItem(
            title: "Colores",
            icon: "paintpalette.fill",
            color: Color(hex: "#A5D6A7"), // Verde
            destinationView: AnyView(JuegoArcoirisView())
        ),
        GameItem(
            title: "Letras",
            icon: "textformat.abc",
            color: Color(hex: "#FFD54F"), // Amarillo
            destinationView: AnyView(JuegoAlfabetoView())
        )
    ]
    
    // Estados para animación
    @State private var animateMascot = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1. FONDO MÁGICO (Consistente con LaunchScreen)
                DesignSystem.Colors.backgroundGradient
                    .ignoresSafeArea()
                
                // Decoración de Fondo (Nubes lentas)
                GeometryReader { geo in
                    ZStack {
                        MenuMovingCloud(delay: 0, yPos: geo.size.height * 0.05, duration: 40)
                        MenuMovingCloud(delay: 10, yPos: geo.size.height * 0.4, duration: 50)
                        MenuMovingCloud(delay: 5, yPos: geo.size.height * 0.8, duration: 45)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // 2. HEADER (Título + Mascota Real)
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
                            
                            // Mascota Asomándose
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 90, height: 90)
                                    .blur(radius: 10)
                                
                                Image("brain_mascot") // Usamos la misma imagen del Launch
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .rotationEffect(.degrees(animateMascot ? 5 : -5))
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                            }
                            .onAppear {
                                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                    animateMascot = true
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        // 3. GRID DE JUEGOS (Tarjetas Mejoradas)
                        LazyVGrid(columns: columns, spacing: 25) {
                            ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                                NavigationLink(destination: game.destinationView) {
                                    EnhancedGameCard(game: game, index: index)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                        
                        // 4. SECCIÓN DE LOGROS (Banner inferior)
                        // Un pequeño extra visual para llenar la pantalla
                        HStack {
                            Image(systemName: "trophy.fill")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)
                                .shadow(color: .orange.opacity(0.5), radius: 2)
                            
                            VStack(alignment: .leading) {
                                Text("Mis Trofeos")
                                    .font(.headline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Text("¡Sigue jugando para ganar!")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    }
                    .padding(25)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack) // Evita problemas en iPad
    }
}

// MARK: - COMPONENTES UI MEJORADOS

struct EnhancedGameCard: View {
    let game: GameItem
    let index: Int
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 15) {
            // Icono Grande con Fondo de Color
            ZStack {
                Circle()
                    .fill(game.color.opacity(0.15)) // Fondo pastel del color del juego
                    .frame(width: 90, height: 90)
                
                Image(systemName: game.icon)
                    .font(.system(size: 45)) // Icono grande
                    .foregroundColor(game.color)
                    // Sombra del mismo color del juego para efecto "Glow"
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
        // Borde sutil
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white, lineWidth: 2)
        )
        // Sombra suave pero con tinte del color del juego
        .shadow(color: game.color.opacity(0.15), radius: 15, x: 0, y: 8)
        // Animación de entrada (Cascada)
        .offset(y: isAnimating ? 0 : 50)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
                isAnimating = true
            }
        }
        // Efecto al presionar (Scale down)
        .buttonStyle(ScaleButtonStyle())
    }
}

// Estilo de botón para la animación al tocar
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Nube de fondo para el menú (Local para no chocar con otros archivos)
struct MenuMovingCloud: View {
    let delay: Double
    let yPos: CGFloat
    let duration: Double
    @State private var move = false
    
    var body: some View {
        GeometryReader { geo in
            Image(systemName: "cloud.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.6)) // Más sutiles que en el intro
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
