import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var animateIcon = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    icon: "cat.fill",
                    iconColor: .appOrange,
                    title: "Meet your focus companion",
                    subtitle: "Raise a virtual cat by completing focus sessions. Stay focused — your cat's life depends on it!",
                    animateIcon: animateIcon
                )
                .tag(0)

                OnboardingPageView(
                    icon: "timer",
                    iconColor: .purple,
                    title: "The Pomodoro method",
                    subtitle: "Focus for 25 minutes, rest for 5. Build streaks, grow your pet, unlock new companions.",
                    animateIcon: animateIcon
                )
                .tag(1)

                OnboardingPageView(
                    icon: "bell.fill",
                    iconColor: .teal,
                    title: "Stay on track",
                    subtitle: "Allow notifications so we can remind you when sessions end.",
                    animateIcon: animateIcon
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .onChange(of: currentPage) { _, _ in
                animateIcon.toggle()
            }

            VStack(spacing: 12) {
                if currentPage < 2 {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appOrange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Button {
                        Task {
                            _ = await NotificationService.shared.requestAuthorization()
                            hasCompletedOnboarding = true
                        }
                    } label: {
                        Text("Enable Notifications")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appOrange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button("Skip for now") {
                        hasCompletedOnboarding = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color.appBackground)
        .onAppear { animateIcon = true }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
