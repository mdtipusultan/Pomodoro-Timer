import SwiftUI

struct SplashView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var isActive = false
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

                VStack(spacing: 12) {
                    PetAnimationView(
                        petType: .cat,
                        animationState: .focusing,
                        growth: 0,
                        playsIntro: true
                    )

                    VStack(spacing: 8) {
                        Text(AppBrand.name)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Text(AppBrand.tagline)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.45).delay(0.25)) {
                    showTitle = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
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
