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
                    title: "Welcome to \(AppBrand.name)",
                    subtitle: "Stay focused and your kitty grows into a big cat. Finish a session to raise a companion.",
                    animateIcon: animateIcon
                )
                .tag(0)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Onboarding page 1 of 3. Welcome to \(AppBrand.name). Stay focused and your kitty grows into a big cat.")

                OnboardingPageView(
                    icon: "timer",
                    iconColor: .purple,
                    title: "The Pomodoro method",
                    subtitle: "Focus for 25 minutes, rest for 5. As time goes, your kitty becomes a cat. Build streaks and unlock companions.",
                    animateIcon: animateIcon
                )
                .tag(1)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Onboarding page 2 of 3. The Pomodoro method. Focus for 25 minutes, rest for 5 minutes.")

                OnboardingPageView(
                    icon: "bell.fill",
                    iconColor: .teal,
                    title: "Stay on track",
                    subtitle: "Allow notifications so we can remind you when sessions end.",
                    animateIcon: animateIcon
                )
                .tag(2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Onboarding page 3 of 3. Stay on track. Enable notifications to get reminders.")
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .onChange(of: currentPage) { _, _ in
                animateIcon.toggle()
                HapticManager.shared.selection()
            }

            VStack(spacing: 14) {
                if currentPage < 2 {
                    Button {
                        HapticManager.shared.buttonTap()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { 
                            currentPage += 1 
                        }
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                } else {
                    Button {
                        HapticManager.shared.buttonTap()
                        Task {
                            _ = await NotificationService.shared.requestAuthorization()
                            withAnimation {
                                hasCompletedOnboarding = true
                            }
                        }
                    } label: {
                        Text("Enable Notifications")
                    }
                    .buttonStyle(AppPrimaryButtonStyle())

                    Button("Skip for now") {
                        HapticManager.shared.buttonTap()
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
        .appScreenBackground()
        .onAppear { animateIcon = true }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
