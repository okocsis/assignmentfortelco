import XCTest
@testable import CountyAdjacencyTool

final class AdjacencyAlgorithmTests: XCTestCase {
    func testGroundTruthWrappedFormatIsAccepted() throws {
        let groundTruthPath = fixtureURL(path: "data/hu_wikidata_county_adjacency_regionKey.json").path
        let computed = try loadGroundTruth(path: groundTruthPath)

        XCTAssertNoThrow(try validateAgainstGroundTruth(computedNeighbors: computed, groundTruthPath: groundTruthPath))
    }

    func testSVGAdjacencyMatchesWikidataGroundTruth() throws {
        let options = Options(
            svgPath: projectSVGPath,
            descriptorPath: projectDescriptorPath,
            minSharedLength: 1.0,
            snapTolerance: 0.05,
            curveSubdivisions: 20,
            updateDescriptor: false,
            outputPath: nil,
            allowOrderFallback: false,
            ignoreUnmappedPaths: false,
            groundTruthPath: nil
        )

        let descriptor = try loadDescriptor(at: options.descriptorPath)
        let paths = try extractPaths(fromSVGAt: options.svgPath)
        let mapped = try mapRegionsToSegments(pathElements: paths, descriptor: descriptor, options: options)
        let actual = computeNeighbors(
            regionToSegments: mapped,
            minSharedLength: options.minSharedLength,
            snapTolerance: options.snapTolerance
        ).mapValues { Set($0) }

        let expected = try loadGroundTruth(path: fixtureURL(path: "data/hu_wikidata_county_adjacency_regionKey.json").path)
        let actualEdges = undirectedEdges(from: actual)
        let expectedEdges = undirectedEdges(from: expected)
        let intersectionCount = actualEdges.intersection(expectedEdges).count

        let precision = Double(intersectionCount) / Double(max(actualEdges.count, 1))
        let recall = Double(intersectionCount) / Double(max(expectedEdges.count, 1))

        XCTAssertGreaterThanOrEqual(precision, 0.95, "Adjacency precision too low against Wikidata ground truth")
        XCTAssertGreaterThanOrEqual(recall, 0.95, "Adjacency recall too low against Wikidata ground truth")
    }

    func testGroundTruthDiffEdgesAreProduced() throws {
        let options = Options(
            svgPath: projectSVGPath,
            descriptorPath: projectDescriptorPath,
            minSharedLength: 1.0,
            snapTolerance: 0.05,
            curveSubdivisions: 20,
            updateDescriptor: false,
            outputPath: nil,
            allowOrderFallback: false,
            ignoreUnmappedPaths: false,
            groundTruthPath: nil
        )

        let descriptor = try loadDescriptor(at: options.descriptorPath)
        let paths = try extractPaths(fromSVGAt: options.svgPath)
        let mapped = try mapRegionsToSegments(pathElements: paths, descriptor: descriptor, options: options)
        let actual = computeNeighbors(
            regionToSegments: mapped,
            minSharedLength: options.minSharedLength,
            snapTolerance: options.snapTolerance
        )

        let diff = try makeGroundTruthDiff(
            computedNeighbors: actual,
            groundTruthPath: fixtureURL(path: "data/hu_wikidata_county_adjacency_regionKey.json").path
        )

        XCTAssertEqual(diff.missingEdges.count, 2)
        XCTAssertEqual(diff.extraEdges.count, 0)
        XCTAssertTrue(diff.missingEdges.contains("hu.bacs_kiskun|hu.fejer"))
        XCTAssertTrue(diff.missingEdges.contains("hu.fejer|hu.somogy"))
    }

    private var projectSVGPath: String {
        fixtureURL(path: "../../YettelHomeWork/Assets.xcassets/CountyMapSVG.dataset/countyMap.svg").path
    }

    private var projectDescriptorPath: String {
        fixtureURL(path: "../../YettelHomeWork/Assets.xcassets/HUCountiesDescriptor.dataset/hu.counties.v1.json").path
    }

    private func fixtureURL(path: String) -> URL {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let packageRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return packageRoot.appendingPathComponent(path)
    }

    private func loadGroundTruth(path: String) throws -> [String: Set<String>] {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let object = try JSONSerialization.jsonObject(with: data)

        if let direct = object as? [String: [String]] {
            return direct.mapValues(Set.init)
        }

        if let wrapped = object as? [String: Any], let adjacency = wrapped["adjacency"] as? [String: [String]] {
            return adjacency.mapValues(Set.init)
        }

        throw ToolError.parse("Invalid ground-truth format in test fixture")
    }

    private func undirectedEdges(from adjacency: [String: Set<String>]) -> Set<String> {
        var edges: Set<String> = []
        for (lhs, neighbors) in adjacency {
            for rhs in neighbors {
                if lhs < rhs {
                    edges.insert("\(lhs)|\(rhs)")
                } else {
                    edges.insert("\(rhs)|\(lhs)")
                }
            }
        }
        return edges
    }
}
