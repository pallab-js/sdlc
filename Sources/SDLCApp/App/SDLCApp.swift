import SwiftUI

@main
struct SDLCApp: App {
    @StateObject private var env: AppEnvironment
    
    init() {
        let environment: AppEnvironment
        do {
            environment = try AppEnvironment()
        } catch {
            fatalError("Failed to initialize application: \(error.localizedDescription)")
        }
        _env = StateObject(wrappedValue: environment)
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
