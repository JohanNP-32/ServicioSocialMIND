import SwiftUI

struct LaunchScreenView: View {
    var onStartTap: () -> Void
    
    @State private var isAppearing = false
    @State private var isFloating = false
    
    var body: some View {
        ZStack {
            // =============================================
            // CAPA 1: FONDO Y DECORACIÓN
            // =============================================
            DesignSystem.Colors.backgroundGradient
                .ignoresSafeArea()
            
            // Elementos flotantes (Nubes y Iconos)
            GeometryReader { geo in
                ZStack {
                    // --- NUBES  ---
                    // Nube Izquierda Superior
                    MovingCloud(
                        delay: 0,
                        yPos: geo.size.height * 0.12,
                        xStart: geo.size.width * 0.1, // Empieza un poco adentro
                        xEnd: geo.size.width * 0.3    // Se mueve solo un poco a la derecha
                    )
                    
                    // Nube Derecha un poco más abajo
                    MovingCloud(
                        delay: 2,
                        yPos: geo.size.height * 0.28,
                        xStart: geo.size.width * 0.8, // Empieza a la derecha
                        xEnd: geo.size.width * 0.6    // Se mueve a la izquierda
                    )
                    
                    // --- ICONOS (Más centrados y seguros) ---
                    
                    // Estrella (Arriba Izquierda, más adentro)
                    FloatingIcon(
                        icon: "star.fill",
                        color: Color(hex: "#FFD54F"),
                        size: 40,
                        x: geo.size.width * 0.2, // 20% del ancho (más centrado)
                        y: geo.size.height * 0.15,
                        delay: 0
                    )
                    
                    // ABC (Arriba Derecha, más adentro)
                    FloatingIcon(
                        icon: "textformat.abc",
                        color: DesignSystem.Colors.secondary,
                        size: 50,
                        x: geo.size.width * 0.8, // 80% del ancho
                        y: geo.size.height * 0.18,
                        delay: 1
                    )
                    
                    // 123 (Abajo Izquierda, cuidando no tapar el cerebro)
                    FloatingIcon(
                        icon: "123.rectangle.fill",
                        color: DesignSystem.Colors.primary,
                        size: 45,
                        x: geo.size.width * 0.18,
                        y: geo.size.height * 0.55,
                        delay: 2
                    )
                    
                    // Paleta (Abajo Derecha)
                    FloatingIcon(
                        icon: "paintpalette.fill",
                        color: DesignSystem.Colors.success,
                        size: 40,
                        x: geo.size.width * 0.82,
                        y: geo.size.height * 0.65,
                        delay: 1.5
                    )
                }
            }
            
            // =============================================
            // CAPA 2: LA MASCOTA (GIGANTE Y LIBRE)
            // =============================================
            ZStack {
                // Halo de luz
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 550, height: 550)
                    .blur(radius: 40)
                    .scaleEffect(isFloating ? 1.05 : 1.0)
                
                // Imagen del Cerebro
                Image("brain_mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 500)
                    .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 20)
                    .offset(y: isFloating ? -20 : 10)
                    .offset(y: -30)
            }
            .animation(
                Animation.easeInOut(duration: 3.5).repeatForever(autoreverses: true),
                value: isFloating
            )
            .scaleEffect(isAppearing ? 1.0 : 0.5)
            .opacity(isAppearing ? 1.0 : 0.0)
            
            // =============================================
            // CAPA 3: INTERFAZ (TEXTO Y BOTÓN)
            // =============================================
            VStack {
                Spacer()
                Spacer()
                
                // Título
                VStack(spacing: 5) {
                    Text("MIND")
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .tracking(2)
                        .shadow(color: Color.white, radius: 0, x: 3, y: 3)
                    
                    Text("Aventura de Aprendizaje")
                        .font(DesignSystem.Fonts.body())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fontWeight(.medium)
                }
                .padding(.bottom, 30)
                .opacity(isAppearing ? 1.0 : 0.0)
                
                // BOTÓN DE ACCIÓN
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onStartTap()
                }) {
                    HStack(spacing: 15) {
                        Image(systemName: "play.fill")
                            .font(.title2.bold())
                        Text("INICIAR AVENTURA")
                            .font(.system(.title3, design: .rounded).bold())
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 50)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FFAB91"), Color(hex: "#FF8A65")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: Color(hex: "#FF8A65").opacity(0.4), radius: 15, y: 10)
                }
                .padding(.bottom, 60)
                .scaleEffect(isAppearing ? 1.0 : 0.8)
                .opacity(isAppearing ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAppearing = true
            }
            isFloating = true
        }
    }
}

// MARK: - ELEMENTOS VISUALES MEJORADOS

struct FloatingIcon: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let delay: Double
    
    @State private var animate = false
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size))
            .foregroundColor(color)
            // Sombra oscura suave para resaltar sobre fondo claro
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .position(x: x, y: y)
            .offset(y: animate ? -15 : 15)
            .rotationEffect(.degrees(animate ? 10 : -10))
            .opacity(1.0) // Totalmente visible
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 4.0)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    animate = true
                }
            }
    }
}

// NUBE CORREGIDA: Ahora oscila en lugar de irse
struct MovingCloud: View {
    let delay: Double
    let yPos: CGFloat
    let xStart: CGFloat
    let xEnd: CGFloat
    
    @State private var move = false
    
    var body: some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: 90))
            .foregroundColor(.white.opacity(0.8))
            .shadow(color: Color(hex: "#E3F2FD"), radius: 10, y: 5)
            .position(x: move ? xEnd : xStart, y: yPos) // Se mueve entre dos puntos dentro de la pantalla
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 8.0) // Movimiento suave de ida y vuelta
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    move = true
                }
            }
    }
}

#Preview {
    LaunchScreenView(onStartTap: {})
}
