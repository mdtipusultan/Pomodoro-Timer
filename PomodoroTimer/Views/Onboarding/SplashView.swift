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
                Color.appOrangeGradient
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
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCat = true
                }
                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    showTitle = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
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
