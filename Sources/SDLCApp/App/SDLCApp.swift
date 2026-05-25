import SwiftUI

@main
struct SDLCApp: App {
    @StateObject private var env = AppEnvironment()
    
    init() {
        // Setup initial configuration if needed
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(env)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
    }
}
