import SwiftUI

struct SplashView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var isActive = false
    @State private var showCat = false
    @State private var showTitle = false

    var body: some View {
        if isActive {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.58, blue: 0.0), Color(red: 1.0, green: 0.72, blue: 0.30)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "cat.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: showCat)
                        .opacity(showCat ? 1 : 0)
                        .scaleEffect(showCat ? 1 : 0.5)

                    VStack(spacing: 8) {
                        Text("ChickFocus")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Text("Focus. Grow. Thrive.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showCat = true
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                    showTitle = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView(hasCompletedOnboarding: .constant(false))
}
