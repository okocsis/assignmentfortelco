import SwiftUI

struct CountyMapView: View {
    let counties: [CountyVignetteOption]
    let mapShapes: [String: MapRegionShape]
    let selectedCountyIDs: Set<String>
    let onToggle: (String) -> Void

    private enum MapMetrics {
        static let aspectRatio: CGFloat = 1.55
        static let borderWidth: CGFloat = 1.8
        static let selectedFill = Color.figmaCountyMapSelectedFill
        static let unselectedFill = Color.figmaCountyMapUnselectedFill
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(counties) { county in
                    countyShapeView(for: county, in: geometry.size)
                }
            }
        }
        .aspectRatio(MapMetrics.aspectRatio, contentMode: .fit)
    }

    @ViewBuilder
    private func countyShapeView(for county: CountyVignetteOption, in size: CGSize) -> some View {
        let isSelected = selectedCountyIDs.contains(county.id)

        if let shape = mapShapes[county.id] {
            let path = makePath(for: shape, in: size)

            path
                .fill(isSelected ? MapMetrics.selectedFill : MapMetrics.unselectedFill)
                .overlay(
                    path.stroke(.white, lineWidth: MapMetrics.borderWidth)
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

#Preview {
    CountyMapView(counties: [], mapShapes: [:], selectedCountyIDs: []) { _ in
        
    }
}
