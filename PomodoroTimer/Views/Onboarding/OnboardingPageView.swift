import SwiftUI

struct OnboardingPageView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let animateIcon: Bool
    
    @State private var appear = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)
                    .scaleEffect(appear ? 1 : 0.8)
                
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 180, height: 180)
                    .scaleEffect(appear ? 1 : 0.8)
                
                Image("OnboardingCompanion")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .scaleEffect(appear ? 1 : 0.5)
            }

            VStack(spacing: 14) {
                Text(title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
}
