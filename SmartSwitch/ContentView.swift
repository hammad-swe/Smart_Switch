import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @AppStorage("app_theme") private var appTheme = "system"

    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if showSplash {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation {
                                self.showSplash = false
                            }
                        }
                    }
            } else {
                HomeView()
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
