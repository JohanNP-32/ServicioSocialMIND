import SwiftUI

struct ContentView: View {
    @State private var showMainMenu = false
    
    var body: some View {
        ZStack {
            if showMainMenu {
                MainMenuView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            } else {
               
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
