import SwiftUI
import AVFoundation
import SpriteKit

// MARK: - 1. CONFIGURACIÓN Y DATOS
enum TraceType: String, CaseIterable {
    case shapes = "Figuras"
    case numbers = "Números"
    case letters = "Letras"
    
    var color: Color {
        switch self {
        case .shapes: return Color(hex: "#FF80AB")   // Rosa
        case .numbers: return Color(hex: "#B39DDB") // Morado
        case .letters: return Color(hex: "#FFF59D") // Amarillo
        }
    }
    
    var icon: String {
        switch self {
        case .shapes: return "square.on.circle.fill"
        case .numbers: return "123.rectangle.fill"
        case .letters: return "textformat.abc"
        }
    }
}

struct TraceItem {
    let id = UUID()
    let name: String
    let pathPoints: [CGPoint]
    let isClosed: Bool
}

// MARK: - 2. VISTA PRINCIPAL
struct TrazosMagicosView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: TraceType? = nil
    
    // Persistencia de niveles
    @AppStorage("trace_level_figuras") private var levelFiguras: Int = 1
    @AppStorage("trace_level_letras") private var levelLetras: Int = 1
    @AppStorage("trace_level_numeros") private var levelNumeros: Int = 1
    
    var body: some View {
        ZStack {
            // 1. FONDO
            DesignSystem.Colors.backgroundGradient.ignoresSafeArea()
            
            // 2. ELEMENTOS FLOTANTES
            ArtBackgroundOverlay()
            
            if let category = selectedCategory {
                // --- JUEGO ACTIVO ---
                TraceCanvasView(category: category, level: bindingForCategory(category)) {
                    selectedCategory = nil
                }
                .transition(.opacity)
            } else {
                // --- MENÚ DE SELECCIÓN ---
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
                    
                    Spacer()
                    
                    // HÉROE CENTRAL
                    VStack(spacing: 15) {
                        Image(systemName: "scribble.variable")
                            .font(.system(size: 110))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .white.opacity(0.8), radius: 20)
                            .rotationEffect(.degrees(-10))
                        
                        Text("Trazos Mágicos")
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .shadow(color: .white, radius: 2)
                        
                        Text("¡Vamos a dibujar!")
                            .font(.title3.bold())
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.8))
                    }
                    .padding(.bottom, 30)
                    
                    Spacer()
                    
                    // BOTONES
                    VStack(spacing: 20) {
                        TraceMenuButton(type: .shapes) { selectedCategory = .shapes }
                        TraceMenuButton(type: .numbers) { selectedCategory = .numbers }
                        TraceMenuButton(type: .letters) { selectedCategory = .letters }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedCategory)
        .navigationBarHidden(true)
    }
    
    func bindingForCategory(_ category: TraceType) -> Binding<Int> {
        switch category {
        case .shapes: return $levelFiguras
        case .letters: return $levelLetras
        case .numbers: return $levelNumeros
        }
    }
}

// MARK: - 3. BOTÓN DE MENÚ
struct TraceMenuButton: View {
    let type: TraceType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 45, height: 45)
                    Image(systemName: type.icon)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                Text(type.rawValue)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 25)
            .background(
                LinearGradient(
                    colors: [type.color, type.color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white, lineWidth: 4))
            .shadow(color: type.color.opacity(0.5), radius: 10, y: 5)
        }
    }
}

// MARK: - 4. LIENZO DE DIBUJO
struct TraceCanvasView: View {
    let category: TraceType
    @Binding var level: Int
    let onBack: () -> Void
    
    @State private var currentShape: TraceItem?
    @State private var drawnPoints: [CGPoint] = []
    @State private var showWin = false
    @State private var showMistake = false
    @State private var modeComplete = false
    
    let maxLevel = 4 // Solo 4 niveles
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                // Header
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 45))
                            .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                            .background(Color.white.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                    
                    VStack {
                        Text(currentShape?.name ?? "")
                            .font(DesignSystem.Fonts.header())
                            .foregroundColor(category.color)
                            .shadow(color: .white, radius: 2)
                        
                        Text("Nivel \(level)")
                            .font(.caption.bold())
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(5)
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    Image(systemName: "arrow.left.circle.fill").font(.system(size: 45)).opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // TABLERO
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                        .padding(20)
                    
                    GeometryReader { innerGeo in
                        ZStack {
                            if let shape = currentShape {
                                // Guía de fondo
                                TracePathShape(points: shape.pathPoints, isClosed: shape.isClosed)
                                    .stroke(style: StrokeStyle(lineWidth: 40, lineCap: .round, lineJoin: .round))
                                    .foregroundColor(Color.gray.opacity(0.15))
                                    .padding(20)
                                
                                // Línea central
                                TracePathShape(points: shape.pathPoints, isClosed: shape.isClosed)
                                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .foregroundColor(Color.white.opacity(0.6))
                                    .padding(20)
                                
                                // Trazo del niño
                                Path { path in
                                    if let first = drawnPoints.first {
                                        path.move(to: first)
                                        for point in drawnPoints.dropFirst() {
                                            path.addLine(to: point)
                                        }
                                    }
                                }
                                .stroke(style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
                                .foregroundColor(showMistake ? .red : category.color)
                                .opacity(0.8)
                                
                                // Efecto Win
                                if showWin {
                                    TracePathShape(points: shape.pathPoints, isClosed: shape.isClosed)
                                        .stroke(style: StrokeStyle(lineWidth: 35, lineCap: .round, lineJoin: .round))
                                        .foregroundColor(category.color)
                                        .shadow(color: category.color, radius: 20)
                                        .padding(20)
                                        .overlay(EmitterView(color: category.color))
                                        .transition(.opacity)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    addPointStrict(value.location, canvasSize: innerGeo.size)
                                }
                                .onEnded { _ in validateCompletion() }
                        )
                    }
                    .padding(40)
                }
                .aspectRatio(1, contentMode: .fit)
                .offset(x: showMistake ? -10 : 0)
                .animation(showMistake ? .default.repeatCount(3).speed(4) : .default, value: showMistake)
                
                Spacer()
                Text(showMistake ? "¡Ups! No te salgas de la línea" : "Sigue la línea punteada")
                    .font(DesignSystem.Fonts.body())
                    .foregroundColor(showMistake ? .red : DesignSystem.Colors.textSecondary.opacity(0.7))
                    .padding(.bottom, 30)
            }
            
            // CAPA DE CELEBRACIÓN (CONFETI)
            .overlay(
                Group {
                    if modeComplete {
                        ZStack {
                            Color.black.opacity(0.6).ignoresSafeArea()
                            ConfettiSpriteView().ignoresSafeArea()
                            
                            VStack(spacing: 20) {
                                Text("🎉")
                                    .font(.system(size: 100))
                                Text("¡Modo Completado!")
                                    .font(DesignSystem.Fonts.title())
                                    .foregroundColor(.white)
                                    .shadow(radius: 10)
                                
                                Button(action: {
                                    level = 1 // Reiniciar nivel
                                    onBack()  // Salir
                                }) {
                                    Text("Volver al Menú")
                                        .font(DesignSystem.Fonts.header())
                                        .foregroundColor(category.color)
                                        .padding(.vertical, 15)
                                        .padding(.horizontal, 40)
                                        .background(Color.white)
                                        .cornerRadius(25)
                                        .shadow(radius: 10)
                                }
                            }
                        }
                        .transition(.opacity)
                        .zIndex(100)
                    }
                }
            )
            .onAppear { loadLevel(size: geo.size) }
        }
    }
    
    func loadLevel(size: CGSize) {
        drawnPoints = []
        showWin = false
        showMistake = false
        let s = min(size.width, size.height) / 330
        currentShape = ShapeGenerator.getShape(category: category, level: level, center: .zero, scale: s)
    }
    
    func addPointStrict(_ touchPoint: CGPoint, canvasSize: CGSize) {
        guard !showWin, let shape = currentShape, !showMistake else { return }
        
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let scale = min(canvasSize.width, canvasSize.height) / 250
        let tolerance: CGFloat = 85.0
        let errorThreshold: CGFloat = 130.0
        
        var isNearPath = false
        var isWayOff = true
        
        for shapePoint in shape.pathPoints {
            let screenX = center.x + shapePoint.x * scale
            let screenY = center.y + shapePoint.y * scale
            let distance = hypot(touchPoint.x - screenX, touchPoint.y - screenY)
            
            if distance < tolerance {
                isNearPath = true
                isWayOff = false
                break
            } else if distance < errorThreshold {
                isWayOff = false
            }
        }
        
        if isNearPath {
            drawnPoints.append(touchPoint)
        } else if isWayOff {
            if drawnPoints.count > 5 {
                triggerMistake()
            }
        }
    }
    
    func triggerMistake() {
        guard !showMistake else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        withAnimation { showMistake = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            drawnPoints = []
            showMistake = false
        }
    }
    
    func validateCompletion() {
        if drawnPoints.count > 15 {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            AudioServicesPlaySystemSound(1026)
            
            withAnimation(.easeInOut(duration: 0.5)) { showWin = true }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if level < maxLevel {
                    level += 1
                    loadLevel(size: CGSize(width: 300, height: 300))
                } else {
                    withAnimation { modeComplete = true }
                }
            }
        } else {
            withAnimation { drawnPoints = [] }
        }
    }
}

// MARK: - 5. GENERADOR DE FORMAS (4 NIVELES POR CATEGORÍA)
struct ShapeGenerator {
    static func getShape(category: TraceType, level: Int, center: CGPoint, scale: CGFloat) -> TraceItem {
        let c = center; let s = scale
        
        switch category {
        case .numbers: return getNumber(level, c: c, s: s)
        case .letters: return getLetter(level, c: c, s: s)
        case .shapes: return getFigure(level, c: c, s: s)
        }
    }
    
    // NÚMEROS: 1, 2, 3, 4 (Eliminado 5)
    static func getNumber(_ level: Int, c: CGPoint, s: CGFloat) -> TraceItem {
        switch level {
        case 1: return TraceItem(name: "Número 1", pathPoints: [CGPoint(x: -20, y: -80), CGPoint(x: 0, y: -100), CGPoint(x: 0, y: 100)], isClosed: false)
        case 2:
            var points: [CGPoint] = []
            for angle in stride(from: 180.0, through: 0.0, by: -10.0) {
                let rad = angle * .pi / 180
                points.append(CGPoint(x: cos(rad) * 50, y: -50 - sin(rad) * 50))
            }
            points.append(CGPoint(x: -50, y: 100)); points.append(CGPoint(x: 50, y: 100))
            return TraceItem(name: "Número 2", pathPoints: points, isClosed: false)
        case 3:
            var points: [CGPoint] = []
            for angle in stride(from: 180.0, through: -90.0, by: -10.0) {
                let rad = angle * .pi / 180
                points.append(CGPoint(x: cos(rad) * 40, y: -50 - sin(rad) * 40))
            }
            for angle in stride(from: 90.0, through: -180.0, by: -10.0) {
                let rad = angle * .pi / 180
                points.append(CGPoint(x: cos(rad) * 50, y: 50 - sin(rad) * 50))
            }
            return TraceItem(name: "Número 3", pathPoints: points, isClosed: false)
        default: // Nivel 4 (Número 4)
            return TraceItem(name: "Número 4", pathPoints: [CGPoint(x: -50, y: -100), CGPoint(x: -50, y: 0), CGPoint(x: 50, y: 0), CGPoint(x: 50, y: -100), CGPoint(x: 50, y: 100)], isClosed: false)
        }
    }
    
    // LETRAS: A, L, F, T (Eliminada E)
    static func getLetter(_ level: Int, c: CGPoint, s: CGFloat) -> TraceItem {
        switch level {
        case 1: return TraceItem(name: "Letra A", pathPoints: [CGPoint(x: -60, y: 100), CGPoint(x: 0, y: -100), CGPoint(x: 60, y: 100), CGPoint(x: 30, y: 10), CGPoint(x: -30, y: 10)], isClosed: false)
        case 2: return TraceItem(name: "Letra L", pathPoints: [CGPoint(x: -40, y: -100), CGPoint(x: -40, y: 100), CGPoint(x: 60, y: 100)], isClosed: false)
        case 3: return TraceItem(name: "Letra F", pathPoints: [CGPoint(x: 60, y: -100), CGPoint(x: -40, y: -100), CGPoint(x: -40, y: 100), CGPoint(x: -40, y: 0), CGPoint(x: 40, y: 0)], isClosed: false)
        default: // Nivel 4 (Letra T)
            return TraceItem(name: "Letra T", pathPoints: [CGPoint(x: -60, y: -100), CGPoint(x: 60, y: -100), CGPoint(x: 0, y: -100), CGPoint(x: 0, y: 100)], isClosed: false)
        }
    }
    
    // FIGURAS: Cuadrado, Triángulo, Rombo, Pentágono (Eliminado Rectángulo)
    static func getFigure(_ level: Int, c: CGPoint, s: CGFloat) -> TraceItem {
        switch level {
        case 1: return TraceItem(name: "Cuadrado", pathPoints: [CGPoint(x: -80, y: -80), CGPoint(x: 80, y: -80), CGPoint(x: 80, y: 80), CGPoint(x: -80, y: 80)], isClosed: true)
        case 2: return TraceItem(name: "Triángulo", pathPoints: [CGPoint(x: 0, y: -90), CGPoint(x: 90, y: 70), CGPoint(x: -90, y: 70)], isClosed: true)
        case 3: return TraceItem(name: "Rombo", pathPoints: [CGPoint(x: 0, y: -90), CGPoint(x: 70, y: 0), CGPoint(x: 0, y: 90), CGPoint(x: -70, y: 0)], isClosed: true)
        default: // Nivel 4 (Pentágono)
            return TraceItem(name: "Pentágono", pathPoints: [CGPoint(x: 0, y: -90), CGPoint(x: 90, y: -20), CGPoint(x: 55, y: 90), CGPoint(x: -55, y: 90), CGPoint(x: -90, y: -20)], isClosed: true)
        }
    }
}

// MARK: - 6. ELEMENTOS DECORATIVOS Y SPRITEKIT
struct ArtBackgroundOverlay: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ArtFloatingIcon(icon: "pencil", color: .blue, x: geo.size.width * 0.1, y: geo.size.height * 0.15, delay: 0)
                ArtFloatingIcon(icon: "paintbrush.fill", color: .purple, x: geo.size.width * 0.85, y: geo.size.height * 0.25, delay: 1)
                ArtFloatingIcon(icon: "ruler.fill", color: .orange, x: geo.size.width * 0.15, y: geo.size.height * 0.5, delay: 2)
                ArtFloatingIcon(icon: "scissors", color: .red, x: geo.size.width * 0.9, y: geo.size.height * 0.7, delay: 3)
                ArtFloatingIcon(icon: "scribble", color: .green, x: geo.size.width * 0.2, y: geo.size.height * 0.8, delay: 1.5)
            }
        }
    }
}

struct ArtFloatingIcon: View {
    let icon: String
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let delay: Double
    @State private var animate = false
    var body: some View {
        Image(systemName: icon).font(.system(size: 40)).foregroundColor(color.opacity(0.3))
            .rotationEffect(.degrees(animate ? 15 : -15)).offset(y: animate ? -20 : 20).position(x: x, y: y)
            .onAppear { withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(delay)) { animate = true } }
    }
}

struct TracePathShape: Shape {
    let points: [CGPoint]
    let isClosed: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path(); guard !points.isEmpty else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY); let scale = min(rect.width, rect.height) / 250
        let start = CGPoint(x: center.x + points[0].x * scale, y: center.y + points[0].y * scale)
        path.move(to: start)
        for point in points.dropFirst() { path.addLine(to: CGPoint(x: center.x + point.x * scale, y: center.y + point.y * scale)) }
        if isClosed { path.closeSubpath() }
        return path
    }
}

struct EmitterView: View {
    let color: Color
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let angle = Angle.degrees(now * 100)
                let x = cos(angle.radians) * 50 + size.width/2
                let y = sin(angle.radians) * 50 + size.height/2
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 10, height: 10)), with: .color(color))
            }
        }
    }
}

// --- MODIFICACIÓN AQUÍ ---
struct ConfettiSpriteView: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        let scene = SKScene(size: CGSize(width: 400, height: 800))
        scene.backgroundColor = .clear
        scene.scaleMode = .resizeFill
        
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(image: createConfettiImage())
        emitter.particleBirthRate = 150
        emitter.particleLifetime = 5.0
        emitter.particlePosition = CGPoint(x: 200, y: 800)
        emitter.particlePositionRange = CGVector(dx: 400, dy: 0)
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 4
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 100
        emitter.yAcceleration = -150
        // SE REDUJO LA ESCALA PARA QUE EL CONFETI SEA PEQUEÑO Y NÍTIDO
        emitter.particleScale = 0.8
        emitter.particleScaleRange = 0.4
        emitter.particleColorBlendFactor = 1.0
        
        let colors: [UIColor] = [.red, .cyan, .yellow, .green, .orange, .magenta]
        emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: colors, times: [0, 0.2, 0.4, 0.6, 0.8, 1.0])
        
        scene.addChild(emitter)
        view.presentScene(scene)
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {}
    
    func createConfettiImage() -> UIImage {
        // SE REDUJO EL TAMAÑO BASE DE LA IMAGEN
        let size = CGSize(width: 6, height: 4)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
// --- FIN DE MODIFICACIÓN ---

#Preview {
    TrazosMagicosView()
}
