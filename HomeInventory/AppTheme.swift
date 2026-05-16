import SwiftUI
#if os(iOS)
import UIKit
private typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
private typealias PlatformColor = NSColor
#endif

enum AppTheme {
    static let cardCornerRadius: CGFloat = 14
    static let mediaCornerRadius: CGFloat = 12
    static let borderWidth: CGFloat = 1
}

extension Color {
    static let appBackground = Color(lightHex: "#F8F6F1", darkHex: "#101816")
    static let appSurface = Color(lightHex: "#FFFFFF", darkHex: "#17211F")
    static let appSurfaceSecondary = Color(lightHex: "#EAF1EA", darkHex: "#22302D")
    static let appPrimary = Color(lightHex: "#1F6F68", darkHex: "#5FB3AA")
    static let appPrimaryPressed = Color(lightHex: "#14504B", darkHex: "#8AD4CC")
    static let appAccent = Color(lightHex: "#F2A93B", darkHex: "#F2B653")
    static let appTextPrimary = Color(lightHex: "#1F2933", darkHex: "#F4F1EA")
    static let appTextSecondary = Color(lightHex: "#6B7280", darkHex: "#B8C0BD")
    static let appBorder = Color(lightHex: "#DDD8CE", darkHex: "#2E3B38")
    static let appSuccess = Color(lightHex: "#4F8A5B", darkHex: "#7DB887")
    static let appWarning = Color(lightHex: "#F2A93B", darkHex: "#F2B653")
    static let appError = Color(lightHex: "#C65A4A", darkHex: "#E07A6D")

    private init(lightHex: String, darkHex: String) {
        self = Color(dynamicLight: PlatformColor(hex: lightHex), dark: PlatformColor(hex: darkHex))
    }

    private init(dynamicLight light: PlatformColor, dark: PlatformColor) {
        #if os(iOS)
        self.init(PlatformColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
        #elseif os(macOS)
        self.init(PlatformColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            return bestMatch == .darkAqua ? dark : light
        })
        #endif
    }
}

extension View {
    func appCardStyle() -> some View {
        clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(Color.appBorder, lineWidth: AppTheme.borderWidth)
            )
    }
}

private extension PlatformColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
