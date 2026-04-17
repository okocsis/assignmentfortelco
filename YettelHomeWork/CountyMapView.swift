import SwiftUI

struct CountyMapView: View {
    let counties: [CountyVignetteOption]
    let selectedCountyIDs: Set<String>
    let onToggle: (String) -> Void

    private let mapLayout = CountyMapLayout.layout

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(counties) { county in
                    if let frame = mapLayout[county.id] {
                        let rect = frame.rect(in: geometry.size)
                        let isSelected = selectedCountyIDs.contains(county.id)

                        RoundedRectangle(cornerRadius: frame.cornerRadius)
                            .fill(isSelected ? Color(red: 0.73, green: 1.00, blue: 0.00) : Color(red: 0.77, green: 0.87, blue: 0.93))
                            .frame(width: rect.width, height: rect.height)
                            .overlay(
                                RoundedRectangle(cornerRadius: frame.cornerRadius)
                                    .stroke(.white, lineWidth: 2)
                            )
                            .rotationEffect(.degrees(frame.rotationDegrees))
                            .position(x: rect.midX, y: rect.midY)
                            .onTapGesture {
                                onToggle(county.id)
                            }
                            .accessibilityLabel(county.name)
                            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
                    }
                }
            }
        }
        .aspectRatio(1.55, contentMode: .fit)
    }
}

private struct CountyMapFrame {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let rotationDegrees: Double

    func rect(in size: CGSize) -> CGRect {
        CGRect(
            x: x * size.width,
            y: y * size.height,
            width: width * size.width,
            height: height * size.height
        )
    }
}

private enum CountyMapLayout {
    static let layout: [String: CountyMapFrame] = [
        "YEAR_17": CountyMapFrame(x: 0.08, y: 0.30, width: 0.14, height: 0.13, cornerRadius: 18, rotationDegrees: -8),
        "YEAR_27": CountyMapFrame(x: 0.21, y: 0.42, width: 0.14, height: 0.18, cornerRadius: 18, rotationDegrees: -6),
        "YEAR_28": CountyMapFrame(x: 0.28, y: 0.28, width: 0.13, height: 0.15, cornerRadius: 18, rotationDegrees: 4),
        "YEAR_24": CountyMapFrame(x: 0.30, y: 0.56, width: 0.16, height: 0.18, cornerRadius: 18, rotationDegrees: 0),
        "YEAR_16": CountyMapFrame(x: 0.37, y: 0.42, width: 0.15, height: 0.17, cornerRadius: 18, rotationDegrees: 2),
        "YEAR_21": CountyMapFrame(x: 0.38, y: 0.30, width: 0.13, height: 0.11, cornerRadius: 16, rotationDegrees: 5),
        "YEAR_23": CountyMapFrame(x: 0.47, y: 0.35, width: 0.15, height: 0.14, cornerRadius: 18, rotationDegrees: 3),
        "YEAR_26": CountyMapFrame(x: 0.47, y: 0.56, width: 0.15, height: 0.16, cornerRadius: 18, rotationDegrees: 2),
        "YEAR_19": CountyMapFrame(x: 0.53, y: 0.22, width: 0.11, height: 0.12, cornerRadius: 16, rotationDegrees: 4),
        "YEAR_22": CountyMapFrame(x: 0.59, y: 0.26, width: 0.10, height: 0.11, cornerRadius: 16, rotationDegrees: 2),
        "YEAR_14": CountyMapFrame(x: 0.65, y: 0.20, width: 0.23, height: 0.24, cornerRadius: 20, rotationDegrees: -4),
        "YEAR_25": CountyMapFrame(x: 0.75, y: 0.33, width: 0.18, height: 0.20, cornerRadius: 18, rotationDegrees: 2),
        "YEAR_18": CountyMapFrame(x: 0.64, y: 0.39, width: 0.14, height: 0.16, cornerRadius: 18, rotationDegrees: 2),
        "YEAR_20": CountyMapFrame(x: 0.57, y: 0.45, width: 0.16, height: 0.17, cornerRadius: 18, rotationDegrees: 0),
        "YEAR_13": CountyMapFrame(x: 0.68, y: 0.52, width: 0.15, height: 0.17, cornerRadius: 18, rotationDegrees: -1),
        "YEAR_15": CountyMapFrame(x: 0.58, y: 0.59, width: 0.14, height: 0.15, cornerRadius: 18, rotationDegrees: 0),
        "YEAR_11": CountyMapFrame(x: 0.51, y: 0.69, width: 0.15, height: 0.15, cornerRadius: 18, rotationDegrees: -5),
        "YEAR_12": CountyMapFrame(x: 0.42, y: 0.72, width: 0.12, height: 0.12, cornerRadius: 16, rotationDegrees: -8),
        "YEAR_29": CountyMapFrame(x: 0.20, y: 0.67, width: 0.20, height: 0.17, cornerRadius: 18, rotationDegrees: -12),
    ]
}
