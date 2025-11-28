import SwiftUI

struct ContentView: View {
    // Estado para controlar qué pantalla mostrar.
    // Empieza en 'false', por lo que muestra la pantalla de inicio.
    @State private var showMainMenu = false
    
    var body: some View {
        ZStack {
            if showMainMenu {
                // Si el estado es verdadero, mostramos el Menú Principal con una transición suave.
                MainMenuView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            } else {
                // Si no, mostramos la Pantalla de Inicio.
                // Le pasamos la acción: cuando toquen el botón, cambia el estado a 'true'.
                LaunchScreenView {
                    withAnimation {
                        showMainMenu = true
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
