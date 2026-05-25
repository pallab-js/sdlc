import SwiftUI

public struct ModulePlaceholderView: View {
    public var moduleName: String
    public var systemImageName: String
    public var description: String
    
    public init(moduleName: String, systemImageName: String, description: String) {
        self.moduleName = moduleName
        self.systemImageName = systemImageName
        self.description = description
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(moduleName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: systemImageName)
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .indigo.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text("\(moduleName) Module")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
                    .lineSpacing(4)
                
                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .foregroundColor(.indigo)
                    Text("Target: Phase 2 / Core Expansion")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.indigo)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.indigo.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
