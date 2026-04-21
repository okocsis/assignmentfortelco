import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

protocol MapRepository {
    func countyAdjacencyByVignetteType(mapID: String) throws(MapRepositoryError) -> [String: Set<String>]
    func countyShapesByVignetteType(mapID: String) throws(MapRepositoryError) -> [String: MapRegionShape]
    func mapSVGText(mapID: String) throws(MapRepositoryError) -> String
}

struct AssetMapRepository: MapRepository {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func countyAdjacencyByVignetteType(mapID: String) throws(MapRepositoryError) -> [String: Set<String>] {
        let payload = try loadMapPayload(mapID: mapID)
        return buildAdjacencyByVignetteType(from: payload.descriptor)
    }

    func countyShapesByVignetteType(mapID: String) throws(MapRepositoryError) -> [String: MapRegionShape] {
        let payload = try loadMapPayload(mapID: mapID)
        let geometryByRegionKey = try extractRegionGeometry(fromSVG: payload.svgText)
        return buildShapesByVignetteType(descriptor: payload.descriptor, geometryByRegionKey: geometryByRegionKey)
    }

    func mapSVGText(mapID: String) throws(MapRepositoryError) -> String {
        try loadMapPayload(mapID: mapID).svgText
    }

    private func loadMapPayload(mapID: String) throws(MapRepositoryError) -> LoadedMapPayload {
        guard let definition = MapAssetIndex.all.first(where: { $0.mapID == mapID }) else {
            throw MapRepositoryError.mapNotFound(mapID)
        }

        let descriptorData = try loadDataAsset(named: definition.descriptorDatasetName)
        let descriptor: MapDescriptor
        do {
            descriptor = try JSONDecoder().decode(MapDescriptor.self, from: descriptorData)
        } catch {
            throw MapRepositoryError.invalidDescriptor(error.localizedDescription)
        }

        let svgData = try loadDataAsset(named: definition.svgDatasetName)
        guard let svgText = String(data: svgData, encoding: .utf8) else {
            throw MapRepositoryError.invalidSVG("SVG asset is not valid UTF-8")
        }

        return LoadedMapPayload(descriptor: descriptor, svgText: svgText)
    }

    private func loadDataAsset(named name: String) throws(MapRepositoryError) -> Data {
        #if canImport(UIKit) || canImport(AppKit)
        guard let dataAsset = NSDataAsset(name: name, bundle: bundle) else {
            throw MapRepositoryError.assetNotFound(name)
        }
        return dataAsset.data
        #else
        throw MapRepositoryError.unsupportedPlatform
        #endif
    }
}

func buildAdjacencyByVignetteType(from descriptor: MapDescriptor) -> [String: Set<String>] {
    let regionByKey = Dictionary(uniqueKeysWithValues: descriptor.regions.map { ($0.regionKey, $0) })

    var adjacency: [String: Set<String>] = [:]
    for region in descriptor.regions {
        for vignetteType in region.associatedVignetteTypes {
            if adjacency[vignetteType] == nil {
                adjacency[vignetteType] = []
            }

            for neighborKey in region.neighbors {
                guard let neighbor = regionByKey[neighborKey] else { continue }
                for neighborType in neighbor.associatedVignetteTypes where neighborType != vignetteType {
                    adjacency[vignetteType, default: []].insert(neighborType)
                }
            }
        }
    }

    return adjacency
}

private struct LoadedMapPayload {
    var descriptor: MapDescriptor
    var svgText: String
}

private struct SVGViewBox {
    var minX: Double
    var minY: Double
    var width: Double
    var height: Double
}

private struct SVGPathElement {
    var regionKey: String
    var d: String
}

private struct SVGPoint: Equatable {
    var x: Double
    var y: Double
}

private struct SVGPolyline {
    var points: [SVGPoint]
    var isClosed: Bool
}

private struct SVGRegionGeometry {
    var polylines: [SVGPolyline]
}

private enum SVGToken {
    case command(Character)
    case number(Double)
}

private func extractRegionGeometry(fromSVG svg: String, curveSubdivisions: Int = 20) throws(MapRepositoryError) -> [String: SVGRegionGeometry] {
    let viewBox = try extractViewBox(fromSVG: svg)
    let pathElements = try extractPathElements(fromSVG: svg)

    var geometryByRegionKey: [String: SVGRegionGeometry] = [:]
    for element in pathElements {
        let polylines = try parsePathPolylines(from: element.d, curveSubdivisions: curveSubdivisions)
        if polylines.isEmpty { continue }

        let normalized = polylines.map { polyline in
            SVGPolyline(
                points: polyline.points.map { point in
                    SVGPoint(
                        x: (point.x - viewBox.minX) / viewBox.width,
                        y: (point.y - viewBox.minY) / viewBox.height
                    )
                },
                isClosed: polyline.isClosed
            )
        }

        geometryByRegionKey[element.regionKey] = SVGRegionGeometry(polylines: normalized)
    }

    return geometryByRegionKey
}

private func buildShapesByVignetteType(
    descriptor: MapDescriptor,
    geometryByRegionKey: [String: SVGRegionGeometry]
) -> [String: MapRegionShape] {
    var shapes: [String: MapRegionShape] = [:]

    for region in descriptor.regions {
        guard let geometry = geometryByRegionKey[region.regionKey] else { continue }

        let shape = MapRegionShape(
            polylines: geometry.polylines.map { polyline in
                MapPolyline(
                    points: polyline.points.map { CGPoint(x: $0.x, y: $0.y) },
                    isClosed: polyline.isClosed
                )
            }
        )

        for vignetteType in region.associatedVignetteTypes {
            shapes[vignetteType] = shape
        }
    }

    return shapes
}

private func extractViewBox(fromSVG svg: String) throws(MapRepositoryError) -> SVGViewBox {
    let viewBoxRegex = /(?i)\bviewBox\s*=\s*"([^"]+)"/

    guard let match = svg.firstMatch(of: viewBoxRegex) else {
        throw MapRepositoryError.invalidSVG("Missing viewBox attribute")
    }

    let components = String(match.1)
        .split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\t" || $0 == "\n" })
        .compactMap { Double($0) }

    guard components.count == 4 else {
        throw MapRepositoryError.invalidSVG("Invalid viewBox format")
    }

    guard components[2] > 0, components[3] > 0 else {
        throw MapRepositoryError.invalidSVG("viewBox width/height must be positive")
    }

    return SVGViewBox(minX: components[0], minY: components[1], width: components[2], height: components[3])
}

private func extractPathElements(fromSVG svg: String) throws(MapRepositoryError) -> [SVGPathElement] {
    let pathTagRegex = /(?i)<path\b[^>]*>/
    let matches = svg.matches(of: pathTagRegex)

    var elements: [SVGPathElement] = []
    elements.reserveCapacity(matches.count)

    for match in matches {
        let tag = String(match.0)

        guard let d = attribute(named: "d", in: tag) else { continue }
        let regionKey = attribute(named: "data-region-key", in: tag) ?? attribute(named: "id", in: tag)
        guard let regionKey, !regionKey.isEmpty else { continue }

        elements.append(SVGPathElement(regionKey: regionKey, d: d))
    }

    if elements.isEmpty {
        throw MapRepositoryError.invalidSVG("No <path> elements with region keys were found")
    }

    return elements
}

private func attribute(named name: String, in tag: String) -> String? {
    let targetName = name.lowercased()
    let attributeRegex = /([A-Za-z_:][A-Za-z0-9_.:-]*)\s*=\s*"([^"]*)"/

    for match in tag.matches(of: attributeRegex) {
        if String(match.1).lowercased() == targetName {
            return String(match.2)
        }
    }

    return nil
}

private func parsePathPolylines(from d: String, curveSubdivisions: Int) throws(MapRepositoryError) -> [SVGPolyline] {
    let tokens = tokenizePathData(d)
    if tokens.isEmpty {
        return []
    }

    var polylines: [SVGPolyline] = []
    var index = 0
    var command: Character?
    var current = SVGPoint(x: 0, y: 0)
    var subpathStart: SVGPoint?
    var currentPoints: [SVGPoint] = []
    let subdivisions = max(curveSubdivisions, 2)

    func flushCurrentPolyline(isClosed: Bool) {
        guard currentPoints.count > 1 else {
            currentPoints.removeAll(keepingCapacity: true)
            return
        }
        polylines.append(SVGPolyline(points: currentPoints, isClosed: isClosed))
        currentPoints.removeAll(keepingCapacity: true)
    }

    func appendPoint(_ point: SVGPoint) {
        if currentPoints.last != point {
            currentPoints.append(point)
        }
        current = point
    }

    func nextNumber() throws(MapRepositoryError) -> Double {
        guard index < tokens.count else {
            throw MapRepositoryError.invalidSVG("Unexpected end of path data")
        }
        defer { index += 1 }

        if case let .number(value) = tokens[index] {
            return value
        }

        throw MapRepositoryError.invalidSVG("Expected number in path data")
    }

    while index < tokens.count {
        if case let .command(newCommand) = tokens[index] {
            command = newCommand
            index += 1
        }

        guard let command else {
            throw MapRepositoryError.invalidSVG("Path data is missing an initial command")
        }

        switch command {
        case "M":
            flushCurrentPolyline(isClosed: false)

            let x = try nextNumber()
            let y = try nextNumber()
            let point = SVGPoint(x: x, y: y)
            subpathStart = point
            currentPoints = [point]
            current = point

            while index < tokens.count {
                if case .command = tokens[index] { break }
                let lx = try nextNumber()
                let ly = try nextNumber()
                appendPoint(SVGPoint(x: lx, y: ly))
            }
        case "L":
            while index < tokens.count {
                if case .command = tokens[index] { break }
                let x = try nextNumber()
                let y = try nextNumber()
                appendPoint(SVGPoint(x: x, y: y))
            }
        case "H":
            while index < tokens.count {
                if case .command = tokens[index] { break }
                let x = try nextNumber()
                appendPoint(SVGPoint(x: x, y: current.y))
            }
        case "V":
            while index < tokens.count {
                if case .command = tokens[index] { break }
                let y = try nextNumber()
                appendPoint(SVGPoint(x: current.x, y: y))
            }
        case "C":
            while index < tokens.count {
                if case .command = tokens[index] { break }

                let c1x = try nextNumber()
                let c1y = try nextNumber()
                let c2x = try nextNumber()
                let c2y = try nextNumber()
                let ex = try nextNumber()
                let ey = try nextNumber()

                let p0 = current
                let p1 = SVGPoint(x: c1x, y: c1y)
                let p2 = SVGPoint(x: c2x, y: c2y)
                let p3 = SVGPoint(x: ex, y: ey)

                for step in 1 ... subdivisions {
                    let t = Double(step) / Double(subdivisions)
                    appendPoint(cubicBezier(p0: p0, p1: p1, p2: p2, p3: p3, t: t))
                }
            }
        case "Z":
            if let subpathStart {
                appendPoint(subpathStart)
            }
            flushCurrentPolyline(isClosed: true)
            subpathStart = nil
        default:
            throw MapRepositoryError.invalidSVG("Unsupported SVG path command: \(command)")
        }
    }

    flushCurrentPolyline(isClosed: false)
    return polylines
}

private func tokenizePathData(_ d: String) -> [SVGToken] {
    var tokens: [SVGToken] = []
    var index = d.startIndex

    func isCommand(_ character: Character) -> Bool {
        character == "M" || character == "L" || character == "H" || character == "V" || character == "C" || character == "Z"
    }

    while index < d.endIndex {
        let character = d[index]

        if character == " " || character == "\n" || character == "\t" || character == "," {
            index = d.index(after: index)
            continue
        }

        if isCommand(character) {
            tokens.append(.command(character))
            index = d.index(after: index)
            continue
        }

        if character == "-" || character == "+" || character == "." || character.isNumber {
            let start = index
            index = d.index(after: index)

            while index < d.endIndex {
                let value = d[index]
                let isNumericCharacter = value.isNumber || value == "." || value == "e" || value == "E" || value == "-" || value == "+"

                if isNumericCharacter {
                    let previous = d[d.index(before: index)]
                    if (value == "-" || value == "+") && previous != "e" && previous != "E" {
                        break
                    }
                    index = d.index(after: index)
                } else {
                    break
                }
            }

            let chunk = String(d[start ..< index])
            if let number = Double(chunk) {
                tokens.append(.number(number))
            }
            continue
        }

        index = d.index(after: index)
    }

    return tokens
}

private func cubicBezier(p0: SVGPoint, p1: SVGPoint, p2: SVGPoint, p3: SVGPoint, t: Double) -> SVGPoint {
    let mt = 1 - t
    let a = mt * mt * mt
    let b = 3 * mt * mt * t
    let c = 3 * mt * t * t
    let d = t * t * t

    return SVGPoint(
        x: a * p0.x + b * p1.x + c * p2.x + d * p3.x,
        y: a * p0.y + b * p1.y + c * p2.y + d * p3.y
    )
}

enum MapRepositoryError: LocalizedError {
    case mapNotFound(String)
    case assetNotFound(String)
    case invalidDescriptor(String)
    case invalidSVG(String)
    case unsupportedPlatform

    var errorDescription: String? {
        switch self {
        case let .mapNotFound(mapID):
            return "Map definition not found for map id: \(mapID)"
        case let .assetNotFound(assetName):
            return "Data asset not found: \(assetName)"
        case let .invalidDescriptor(reason):
            return "Failed to decode map descriptor: \(reason)"
        case let .invalidSVG(reason):
            return "Failed to parse SVG map data: \(reason)"
        case .unsupportedPlatform:
            return "Map assets are not supported on this platform"
        }
    }
}
