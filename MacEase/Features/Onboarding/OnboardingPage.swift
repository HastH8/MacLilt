import Foundation

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome
    case screenshot
    case switcher
    case clipboard
    case features
    case permissions
    case ready

    var id: Int { rawValue }

    var eyebrow: String {
        switch self {
        case .welcome: "WELCOME"
        case .screenshot, .switcher, .clipboard: "A QUICK TOUR"
        case .features: "MAKE IT YOURS"
        case .permissions: "YOUR CONTROL"
        case .ready: "ALL SET"
        }
    }
}
