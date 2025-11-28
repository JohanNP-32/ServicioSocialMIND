//
//  DesignSystem.swift
//  Servicio Social MIND App
//
//

import SwiftUI

// MARK: - SISTEMA DE DISEÑO (UI KIT)
// Aquí definimos los estilos globales para toda la app.

struct DesignSystem {
    
    // 1. PALETA DE COLORES (Inclusiva y Calmada)
    struct Colors {
        // Fondo Principal: Gradiente Cielo Amanecer (Muy suave)
        static let backgroundGradient = LinearGradient(
            colors: [Color(hex: "#E3F2FD"), Color(hex: "#F3E5F5")], // Azul nube a Lavanda pálido
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Fondos de Tarjetas
        static let cardBackground = Color.white.opacity(0.9) // Efecto cristal
        
        // Acciones y Elementos
        static let primary = Color(hex: "#FFAB91")   // Coral suave (Botones principales)
        static let secondary = Color(hex: "#5C6BC0") // Indigo suave (Navegación/Títulos)
        static let success = Color(hex: "#A5D6A7")   // Verde menta (Aciertos)
        static let warning = Color(hex: "#FFF59D")   // Amarillo suave (Estrellas/Atención)
        
        // Textos (Alto contraste pero amigable)
        static let textPrimary = Color(hex: "#263238")   // Gris oscuro azulado (No negro puro)
        static let textSecondary = Color(hex: "#546E7A") // Gris medio
    }
    
    // 2. TIPOGRAFÍA (SF Pro Rounded - Amigable para dislexia)
    struct Fonts {
        static func title() -> Font {
            return .system(size: 34, weight: .bold, design: .rounded)
        }
        
        static func header() -> Font {
            return .system(size: 24, weight: .semibold, design: .rounded)
        }
        
        static func body() -> Font {
            return .system(size: 20, weight: .medium, design: .rounded)
        }
        
        static func bigNumber() -> Font {
            return .system(size: 50, weight: .heavy, design: .rounded)
        }
    }
    
    // 3. COMPONENTES REUTILIZABLES
    
    // Tarjeta Mágica (Contenedor blanco con sombra suave)
    struct MagicCard<Content: View>: View {
        let content: Content
        
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            content
                .padding(20)
                .background(Colors.cardBackground)
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
    
    // Botón Grande (Fácil de tocar)
    struct BigButton: View {
        let title: String
        let icon: String?
        let color: Color
        let action: () -> Void
        
        init(title: String, icon: String? = nil, color: Color = Colors.primary, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.color = color
            self.action = action
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    if let iconName = icon {
                        Image(systemName: iconName)
                            .font(.title2)
                    }
                    Text(title)
                        .font(Fonts.body())
                        .kerning(1.0) // Espaciado extra para lectura
                }
                .foregroundColor(Colors.textPrimary)
                .padding(.vertical, 18)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity)
                .background(color)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                )
                .shadow(color: color.opacity(0.4), radius: 8, y: 4)
            }
        }
    }
}

// EXTENSIÓN PARA USAR CÓDIGOS HEXADECIMALES
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
