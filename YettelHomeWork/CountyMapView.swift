import SwiftUI

struct CountyMapView: View {
    let counties: [CountyVignetteOption]
    let mapShapes: [String: MapRegionShape]
    let selectedCountyIDs: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(counties) { county in
                    countyShapeView(for: county, in: geometry.size)
                }
            }
        }
        .aspectRatio(1.55, contentMode: .fit)
    }

    @ViewBuilder
    private func countyShapeView(for county: CountyVignetteOption, in size: CGSize) -> some View {
        let isSelected = selectedCountyIDs.contains(county.id)

        if let shape = mapShapes[county.id] {
            let path = makePath(for: shape, in: size)

            path
                .fill(isSelected ? Color(red: 0.73, green: 1.00, blue: 0.00) : Color(red: 0.77, green: 0.87, blue: 0.93))
                .overlay(
                    path.stroke(.white, lineWidth: 1.8)
                )
                .contentShape(path)
                .onTapGesture {
                    onToggle(county.id)
                }
                .accessibilityLabel(county.name)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        }
    }

    private func makePath(for shape: MapRegionShape, in size: CGSize) -> Path {
        var path = Path()

        for polyline in shape.polylines where !polyline.points.isEmpty {
            let scaled = polyline.points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
            guard let first = scaled.first else { continue }

            path.move(to: first)
            for point in scaled.dropFirst() {
                path.addLine(to: point)
            }
            if polyline.isClosed {
                path.closeSubpath()
            }
        }

        return path
    }
}
