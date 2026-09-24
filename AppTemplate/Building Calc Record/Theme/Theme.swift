import SwiftUI

enum AppTheme {
    static let yellow = Color(red: 1.0, green: 0.78, blue: 0.0)
    static let green = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let orange = Color(red: 1.0, green: 0.55, blue: 0.0)

    static func screenBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color(red: 0.99, green: 0.97, blue: 0.93)
    }

    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color.white
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white : Color.black
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.gray : Color(red: 0.45, green: 0.45, blue: 0.45)
    }

    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 16
}

struct PrimaryYellowButtonStyle: ButtonStyle {
    var enabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(enabled ? Color.black : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(enabled ? AppTheme.yellow.opacity(configuration.isPressed ? 0.85 : 1) : AppTheme.yellow.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonRadius))
    }
}
