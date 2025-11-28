import SwiftUI
import PencilKit
import AVFoundation

// MARK: - 1. EXTENSIONES Y AYUDAS

extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int >> 8 & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ArtScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ArtDesignSystem {
    struct Colors {
        static let textPrimary = Color.black.opacity(0.8)
        static let backgroundGradient = LinearGradient(colors: [.white, .blue.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        static let titleColor = Color(hexString: "#FF8C94")
    }
}

// MARK: - 2. MODELOS DE DATOS

struct DrawingTemplate: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let isSystemImage: Bool
    let color: Color
    
    static let allTemplates: [DrawingTemplate] = [
        DrawingTemplate(name: "Gato", imageName: "cat", isSystemImage: true, color: Color(hexString: "#FF922B")),
        DrawingTemplate(name: "Tortuga", imageName: "tortoise", isSystemImage: true, color: Color(hexString: "#51CF66")),
        DrawingTemplate(name: "Mariposa", imageName: "ladybug", isSystemImage: true, color: Color(hexString: "#FF6B6B")),
        DrawingTemplate(name: "Conejo", imageName: "hare", isSystemImage: true, color: Color(hexString: "#B197FC")),
        DrawingTemplate(name: "Oso", imageName: "teddybear", isSystemImage: true, color: Color(hexString: "#8B4513")),
        DrawingTemplate(name: "Pez", imageName: "fish", isSystemImage: true, color: Color(hexString: "#4DABF7"))
    ]
}

struct StickerItem: Identifiable {
    let id = UUID()
    var content: String
    var position: CGPoint
    var scale: CGFloat = 1.0
}

struct ColorPalette {
    static let colors: [Color] = [
        Color(hexString: "#FF6B6B"), Color(hexString: "#FF922B"), Color(hexString: "#FFD93D"),
        Color(hexString: "#51CF66"), Color(hexString: "#20C997"), Color(hexString: "#228BE6"),
        Color(hexString: "#5C7CFA"), Color(hexString: "#CC5DE8"), Color(hexString: "#868E96"),
        Color(hexString: "#000000")
    ]
}

// MARK: - 3. VISTA PRINCIPAL

struct ColoreaYCreaView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTemplate: DrawingTemplate? = nil
    
    var body: some View {
        ZStack {
            FluidBackgroundView()
                .ignoresSafeArea()
            
            if let template = selectedTemplate {
                ColoringCanvasView(
                    template: template,
                    onBack: { selectedTemplate = nil }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                TemplateSelectionView(
                    onDismiss: { dismiss() },
                    onSelectTemplate: { template in
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedTemplate = template
                        }
                    }
                )
                .transition(.move(edge: .leading))
            }
        }
        .animation(.default, value: selectedTemplate != nil)
        .navigationBarHidden(true)
    }
}

// MARK: - 4. SELECCIÓN DE PLANTILLAS

struct TemplateSelectionView: View {
    let onDismiss: () -> Void
    let onSelectTemplate: (DrawingTemplate) -> Void
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 20)]
    
    var body: some View {
        VStack(spacing: 5) {
            
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 45))
                        .foregroundStyle(.gray.opacity(0.5))
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            VStack(spacing: 2) {
                Text("Colorea y Crea")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(ArtDesignSystem.Colors.titleColor)
                    .shadow(color: .white, radius: 2, x: 0, y: 1)
                
                Text("¡Vamos a pintar!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.bottom, 5)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 25) {
                    ForEach(DrawingTemplate.allTemplates) { template in
                        TemplateCard(template: template) {
                            onSelectTemplate(template)
                        }
                    }
                }
                .padding()
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct TemplateCard: View {
    let template: DrawingTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(template.color.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    if template.isSystemImage {
                        Image(systemName: template.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(template.color)
                    } else {
                        Image(template.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }
                }
                Text(template.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ArtScaleButtonStyle())
    }
}

// MARK: - 4. LIENZO DE COLOREAR

struct ColoringCanvasView: View {
    let template: DrawingTemplate
    let onBack: () -> Void
    
    @State private var canvasView = PKCanvasView()
    @State private var selectedColor: Color = ColorPalette.colors[0]
    @State private var brushSize: CGFloat = 15
    @State private var isEraser = false
    @State private var stickers: [StickerItem] = []
    @State private var showStickerPicker = false
    @State private var paperColor: Color = .white
    @State private var showCelebration = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(template.name)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Spacer()
                
                Button(action: {
                    canvasView.drawing = PKDrawing()
                    stickers.removeAll()
                    paperColor = .white
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            .padding()
            
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(paperColor)
                        .shadow(radius: 10)
                    
                    PencilKitCanvasRepresentable(
                        canvasView: $canvasView,
                        selectedColor: $selectedColor,
                        brushSize: $brushSize,
                        isEraser: $isEraser
                    )
                    .cornerRadius(20)
                    
                    Group {
                        if template.isSystemImage {
                            Image(systemName: template.imageName)
                                .resizable()
                                .scaledToFit()
                                .fontWeight(.light)
                        } else {
                            Image(template.imageName)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .foregroundColor(.black)
                    .padding(40)
                    .allowsHitTesting(false)
                    .opacity(0.8)
                    
                    ForEach($stickers) { $sticker in
                        Text(sticker.content)
                            .font(.system(size: 60 * sticker.scale))
                            .position(sticker.position)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        sticker.position = value.location
                                    }
                            )
                            .onTapGesture(count: 2) {
                                if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                                    stickers.remove(at: index)
                                }
                            }
                    }
                }
                .padding()
            }
            
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ToolButton(icon: "paintbrush.pointed.fill", color: selectedColor, isSelected: !isEraser) {
                            isEraser = false
                        }
                        
                        ToolButton(icon: "eraser.fill", color: .gray, isSelected: isEraser) {
                            isEraser = true
                        }
                        
                        Divider().frame(height: 30)
                        
                        Button(action: {
                            withAnimation { paperColor = selectedColor.opacity(0.3) }
                            AudioServicesPlaySystemSound(1004)
                        }) {
                            VStack {
                                Image(systemName: "paintpalette.fill").font(.title2)
                                Text("Fondo").font(.caption2)
                            }
                            .foregroundColor(.black)
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .cornerRadius(15)
                        }
                        
                        Divider().frame(height: 30)
                        
                        ForEach(ColorPalette.colors, id: \.self) { color in
                            ColorButton(color: color, isSelected: selectedColor == color && !isEraser) {
                                selectedColor = color
                                isEraser = false
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 70)
                
                HStack {
                    Button(action: { showStickerPicker.toggle() }) {
                        Label("Stickers", systemImage: "star.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.orange)
                            .cornerRadius(25)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showCelebration = true
                        AudioServicesPlaySystemSound(1004)
                    }) {
                        Label("¡Listo!", systemImage: "checkmark")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.green)
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
            }
            .background(Color.white.opacity(0.9).ignoresSafeArea())
        }
        .sheet(isPresented: $showStickerPicker) {
            StickerPickerView { stickerContent in
                let newSticker = StickerItem(content: stickerContent, position: CGPoint(x: 200, y: 300))
                stickers.append(newSticker)
                showStickerPicker = false
            }
            .presentationDetents([.height(300)])
        }
        .overlay(showCelebration ? CelebrationOverlay(onDismiss: { showCelebration = false }) : nil)
    }
}

// MARK: - 5. SELECTOR DE STICKERS

struct StickerPickerView: View {
    let onSelect: (String) -> Void
    let stickers = ["⭐", "❤️", "🌈", "🦋", "🌸", "🚀", "🐶", "🐱", "👑", "🎨", "⚽️", "🍦"]
    let columns = [GridItem(.adaptive(minimum: 60))]
    
    var body: some View {
        VStack {
            Text("¡Elige un Sticker!")
                .font(.title2.bold())
                .padding(.top)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(stickers, id: \.self) { sticker in
                        Button(action: { onSelect(sticker) }) {
                            Text(sticker).font(.system(size: 50))
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - 6. COMPONENTES UI Y WRAPPERS

struct PencilKitCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var selectedColor: Color
    @Binding var brushSize: CGFloat
    @Binding var isEraser: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        updateTool()
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        updateTool()
    }

    func updateTool() {
        if isEraser {
            canvasView.tool = PKEraserTool(.bitmap)
        } else {
            let color = UIColor(selectedColor)
            canvasView.tool = PKInkingTool(.marker, color: color, width: brushSize)
        }
    }
}

struct ToolButton: View {
    let icon: String
    let color: Color
    var isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : color)
                .frame(width: 50, height: 50)
                .background(isSelected ? color : Color.gray.opacity(0.1))
                .clipShape(Circle())
                .overlay(Circle().stroke(color, lineWidth: isSelected ? 0 : 2))
                .shadow(radius: isSelected ? 4 : 0)
        }
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(Color.white, lineWidth: 3).shadow(radius: 2))
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .overlay(isSelected ? Image(systemName: "checkmark").foregroundColor(.white) : nil)
        }
    }
}

struct CelebrationOverlay: View {
    let onDismiss: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🌟").font(.system(size: 80))
                Text("¡Obra de Arte!").font(.largeTitle.bold()).foregroundColor(.primary)
                Button("Continuar") { onDismiss() }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(40)
            .background(
                LinearGradient(colors: [.white.opacity(0.9), Color(hexString: "#FFD93D").opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(30)
            .shadow(radius: 20)
        }
    }
}

// MARK: - 7. FONDO FLUIDO NATIVO

struct FluidBackgroundView: View {
    let icons = ["paintpalette.fill", "paintbrush.fill", "pencil.tip", "scribble", "star.fill", "sparkles", "scissors", "ruler.fill"]
    let colors: [Color] = [
        Color(hexString: "#FFB7B2"), // Rosa
        Color(hexString: "#FFDAC1"), // Melocotón
        Color(hexString: "#E2F0CB"), // Verde menta
        Color(hexString: "#B5EAD7"), // Turquesa
        Color(hexString: "#C7CEEA")  // Lavanda
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [
                    Color.white,
                    Color(hexString: "#F0F4F8"),
                    Color.blue.opacity(0.05)
                ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                
                ForEach(0..<15, id: \.self) { _ in
                    FloatingItemView(
                        icon: icons.randomElement()!,
                        color: colors.randomElement()!,
                        containerSize: geometry.size
                    )
                }
            }
        }
    }
}

struct FloatingItemView: View {
    let icon: String
    let color: Color
    let containerSize: CGSize
    
    
    @State private var position: CGPoint = CGPoint(x: -100, y: -100)
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 45))
            .foregroundColor(color)
            .opacity(0.6)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .onAppear {
                
                let safeWidth = containerSize.width > 0 ? containerSize.width : UIScreen.main.bounds.width
                let safeHeight = containerSize.height > 0 ? containerSize.height : UIScreen.main.bounds.height
                
                position = CGPoint(
                    x: CGFloat.random(in: 0...safeWidth),
                    y: CGFloat.random(in: 0...safeHeight)
                )
                
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 5...10))
                        .repeatForever(autoreverses: true)
                ) {
                    position.x += CGFloat.random(in: -100...100)
                    position.y += CGFloat.random(in: -100...100)
                    rotation += Double.random(in: -90...90)
                    scale = CGFloat.random(in: 0.7...1.3)
                }
            }
    }
}

// MARK: - PREVIEW
#Preview {
    ColoreaYCreaView()
}
