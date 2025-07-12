import SwiftUI

@main
struct FitMateAppApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isLoading {
                SplashView()
            } else {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(authManager)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
        }
    }
} 