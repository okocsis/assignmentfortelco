import XCTest
@testable import CountyAdjacencyTool

final class MapGenerationTests: XCTestCase {
    func testGenerateDatasetsWritesSVGAndDescriptorDatasets() throws {
        let sandbox = try makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }

        let mapDir = sandbox.appendingPathComponent("tools/maps/hu", isDirectory: true)
        let assetsDir = sandbox.appendingPathComponent("YettelHomeWork/Assets.xcassets", isDirectory: true)
        try FileManager.default.createDirectory(at: mapDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)

        try "<svg><path id=\"hu.pest\" d=\"M 0 0 L 10 0 L 10 10 Z\"/></svg>".write(to: mapDir.appendingPathComponent("map.svg"), atomically: true, encoding: .utf8)
        try "{}".write(to: mapDir.appendingPathComponent("hu.counties.v1.json"), atomically: true, encoding: .utf8)

        let configURL = mapDir.appendingPathComponent("map.config.json")
        try makeConfigJSON(
            svgDatasetName: "CountyMapSVG",
            descriptorDatasetName: "HUCountiesDescriptor",
            descriptorFileName: "hu.counties.v1.json"
        ).write(to: configURL, atomically: true, encoding: .utf8)

        let generated = try generateDatasets(fromConfigPath: configURL.path)

        XCTAssertEqual(generated.mapID, "hu.counties")
        XCTAssertEqual(generated.datasetPaths.count, 2)

        let svgDatasetURL = assetsDir.appendingPathComponent("CountyMapSVG.dataset")
        let descriptorDatasetURL = assetsDir.appendingPathComponent("HUCountiesDescriptor.dataset")
        XCTAssertTrue(FileManager.default.fileExists(atPath: svgDatasetURL.appendingPathComponent("countyMap.svg").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: descriptorDatasetURL.appendingPathComponent("hu.counties.v1.json").path))

        let svgContents = try Data(contentsOf: svgDatasetURL.appendingPathComponent("Contents.json"))
        let svgDecoded = try JSONDecoder().decode(DatasetContents.self, from: svgContents)
        XCTAssertEqual(svgDecoded.data.count, 1)
        XCTAssertEqual(svgDecoded.data.first?.filename, "countyMap.svg")
        XCTAssertEqual(svgDecoded.data.first?.universalTypeIdentifier, "public.svg-image")

        let descriptorContents = try Data(contentsOf: descriptorDatasetURL.appendingPathComponent("Contents.json"))
        let descriptorDecoded = try JSONDecoder().decode(DatasetContents.self, from: descriptorContents)
        XCTAssertEqual(descriptorDecoded.data.count, 1)
        XCTAssertEqual(descriptorDecoded.data.first?.filename, "hu.counties.v1.json")
        XCTAssertEqual(descriptorDecoded.data.first?.universalTypeIdentifier, "public.json")
    }

    func testGenerateDatasetsSupportsSingleCombinedDataset() throws {
        let sandbox = try makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }

        let mapDir = sandbox.appendingPathComponent("tools/maps/hu", isDirectory: true)
        let assetsDir = sandbox.appendingPathComponent("YettelHomeWork/Assets.xcassets", isDirectory: true)
        try FileManager.default.createDirectory(at: mapDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)

        try "<svg/>".write(to: mapDir.appendingPathComponent("map.svg"), atomically: true, encoding: .utf8)
        try "{}".write(to: mapDir.appendingPathComponent("hu.counties.v1.json"), atomically: true, encoding: .utf8)

        let datasetURL = assetsDir.appendingPathComponent("HUCountyMapData.dataset")
        try FileManager.default.createDirectory(at: datasetURL, withIntermediateDirectories: true)
        try "stale".write(to: datasetURL.appendingPathComponent("old.txt"), atomically: true, encoding: .utf8)

        let configURL = mapDir.appendingPathComponent("map.config.json")
        try makeConfigJSON(
            svgDatasetName: "HUCountyMapData",
            descriptorDatasetName: "HUCountyMapData",
            descriptorFileName: "counties.json"
        ).write(to: configURL, atomically: true, encoding: .utf8)

        let generated = try generateDatasets(fromConfigPath: configURL.path)

        XCTAssertEqual(generated.datasetPaths.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: datasetURL.appendingPathComponent("countyMap.svg").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: datasetURL.appendingPathComponent("counties.json").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: datasetURL.appendingPathComponent("old.txt").path))

        let contentsData = try Data(contentsOf: datasetURL.appendingPathComponent("Contents.json"))
        let contents = try JSONDecoder().decode(DatasetContents.self, from: contentsData)
        XCTAssertEqual(contents.data.map(\.filename), ["counties.json", "countyMap.svg"])
    }

    func testGenerateIndexWritesStableSwiftFile() throws {
        let sandbox = try makeSandbox()
        defer { try? FileManager.default.removeItem(at: sandbox) }

        let huMapDir = sandbox.appendingPathComponent("tools/maps/hu", isDirectory: true)
        let roMapDir = sandbox.appendingPathComponent("tools/maps/ro", isDirectory: true)
        let assetsDir = sandbox.appendingPathComponent("YettelHomeWork/Assets.xcassets", isDirectory: true)
        try FileManager.default.createDirectory(at: huMapDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: roMapDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)

        try "<svg/>".write(to: huMapDir.appendingPathComponent("map.svg"), atomically: true, encoding: .utf8)
        try "{}".write(to: huMapDir.appendingPathComponent("hu.counties.v1.json"), atomically: true, encoding: .utf8)
        try "<svg/>".write(to: roMapDir.appendingPathComponent("map.svg"), atomically: true, encoding: .utf8)
        try "{}".write(to: roMapDir.appendingPathComponent("ro.counties.v1.json"), atomically: true, encoding: .utf8)

        let huConfig = huMapDir.appendingPathComponent("map.config.json")
        let roConfig = roMapDir.appendingPathComponent("map.config.json")

        try makeConfigJSON(
            mapID: "hu.counties",
            countryCode: "HU",
            displayName: "Hungary Counties",
            descriptorFileName: "hu.counties.v1.json"
        ).write(to: huConfig, atomically: true, encoding: .utf8)

        try makeConfigJSON(
            mapID: "ro.counties",
            countryCode: "RO",
            displayName: "Romania Counties",
            descriptorFileName: "ro.counties.v1.json"
        ).write(to: roConfig, atomically: true, encoding: .utf8)

        let index = try generateMapAssetIndex(configPaths: [roConfig.path, huConfig.path])
        let outputURL = sandbox.appendingPathComponent("YettelHomeWork/Generated/MapAssetIndex.swift")
        try writeMapAssetIndex(index, outputPath: outputURL.path)

        let content = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(content.contains("enum MapAssetIndex"))
        XCTAssertTrue(content.contains("mapID: \"hu.counties\""))
        XCTAssertTrue(content.contains("mapID: \"ro.counties\""))
    }

    private func makeSandbox() throws -> URL {
        let sandbox = FileManager.default.temporaryDirectory
            .appendingPathComponent("county-adjacency-tool-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sandbox, withIntermediateDirectories: true)
        return sandbox
    }

    private func makeConfigJSON(
        mapID: String = "hu.counties",
        countryCode: String = "HU",
        displayName: String = "Hungary Counties",
        svgDatasetName: String = "CountyMapSVG",
        descriptorDatasetName: String = "HUCountiesDescriptor",
        descriptorFileName: String = "hu.counties.v1.json"
    ) -> String {
        """
        {
          "schemaVersion": 1,
          "mapId": "\(mapID)",
          "countryCode": "\(countryCode)",
          "displayName": "\(displayName)",
          "inputs": {
            "svgPath": "map.svg",
            "descriptorPath": "hu.counties.v1.json"
          },
          "outputs": {
            "assetCatalogPath": "../../../YettelHomeWork/Assets.xcassets",
            "svgDatasetName": "\(svgDatasetName)",
            "svgFileName": "countyMap.svg",
            "descriptorDatasetName": "\(descriptorDatasetName)",
            "descriptorFileName": "\(descriptorFileName)"
          },
          "adjacency": {
            "minSharedLength": 1.0,
            "snapTolerance": 0.05,
            "curveSubdivisions": 20
          }
        }
        """
    }
}
