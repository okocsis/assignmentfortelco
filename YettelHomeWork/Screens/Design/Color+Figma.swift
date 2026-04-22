import SwiftUI

extension Color {
    // MARK: - Figma named styles
    static let figmaPrimaryColorsLime = Color(hex: 0xB4FF00)
    static let figmaGrey0 = Color(hex: 0xFFFFFF)
    static let figmaGrey50 = Color(hex: 0xF2F4F5)
    static let figmaAnnotationMain = Color(hex: 0x5C43C2)

    // MARK: - Figma component page fill tokens
    static let figmaFillUSG1V1 = Color(hex: 0x002340)
    static let figmaFillU3Z1JF = Color(hex: 0xB4FF00)
    static let figmaFillBYD0FP = Color(hex: 0xCCD3D9)
    static let figmaFillXD9P3M = Color(hex: 0x80919F)
    static let figmaFillUV5OR5 = Color(hex: 0xE5E9EC)
    static let figmaFillQ6EL9A = Color(hex: 0xFF5728)
    static let figmaFillDS9Q7E = Color(hex: 0xF2F4F5)

    // MARK: - County map fills
    static let figmaCountyMapSelectedFill = Color(hex: 0xBAFF00)
    static let figmaCountyMapUnselectedFill = Color(hex: 0xC4DEED)

    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}
