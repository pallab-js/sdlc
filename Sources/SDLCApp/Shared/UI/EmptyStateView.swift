import SwiftUI

public struct EmptyStateView: View {
    public var systemImageName: String
    public var title: String
    public var description: String
    public var actionTitle: String?
    public var action: (() -> Void)?
    
    public init(systemImageName: String, title: String, description: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.systemImageName = systemImageName
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImageName)
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .indigo.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.bottom, 5)
            
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .lineSpacing(4)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .buttonBorderShape(.roundedRectangle(radius: 8))
                .shadow(color: .indigo.opacity(0.2), radius: 5, x: 0, y: 3)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
        )
        .padding()
    }
}
