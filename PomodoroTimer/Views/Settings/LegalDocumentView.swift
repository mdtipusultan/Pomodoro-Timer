import SwiftUI

struct LegalDocumentView: View {
    enum Kind {
        case privacy, terms

        var title: String {
            switch self {
            case .privacy: return "Privacy Policy"
            case .terms: return "Terms of Use"
            }
        }
    }

    let kind: Kind

    var body: some View {
        ScrollView {
            Text(bodyText)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .appScreenBackground()
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bodyText: String {
        switch kind {
        case .privacy:
            return """
            ChickFocus respects your privacy.

            Data we store
            Focus sessions, tags, companions, and settings stay on your device. Purchases are processed by Apple through StoreKit. We do not operate our own account server.

            Notifications
            If you allow notifications, ChickFocus schedules local alerts for session end and optional daily reminders. These never leave your device.

            Widgets and Watch
            Stats shared with widgets and Apple Watch use an App Group on this device.

            Contact
            For privacy questions, use App Store support for ChickFocus.
            """
        case .terms:
            return """
            ChickFocus Terms of Use

            ChickFocus is a focus timer with optional in-app purchases. Subscriptions and lifetime access are billed by Apple. You can manage or cancel subscriptions in your Apple ID settings.

            The timer, farm, and stats are provided as-is. Completing sessions grows virtual companions for fun; they are not a medical or productivity guarantee.

            Apple’s Standard Licensed Application End User License Agreement also applies: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
            """
        }
    }
}
