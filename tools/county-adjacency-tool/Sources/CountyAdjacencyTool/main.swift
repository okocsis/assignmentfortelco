import ArgumentParser
import Foundation

@main
struct CountyAdjacencyTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "county-adjacency-tool",
        abstract: "County adjacency tooling (SVG validation + Wikidata ground truth fetch).",
        discussion: """
        Use `validate-svg` to compute/validate adjacency from SVG map geometry.
        Use `fetch-ground-truth` to pull normalized adjacency from Wikidata.
        Use `generate-dataset` to write xcassets dataset files from map config.
        Use `generate-index` to write a typed Swift index for map assets.
        Use `sync-assets` to run both generation steps.
        """,
        subcommands: [
            ValidateSVG.self,
            FetchGroundTruth.self,
            CompareAdjacency.self,
            GenerateDataset.self,
            GenerateIndex.self,
            SyncAssets.self,
        ],
        defaultSubcommand: ValidateSVG.self
    )
}

struct ValidateSVG: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate-svg",
        abstract: "Compute and validate adjacency from SVG path geometry."
    )

    @Option(help: "Path to SVG file")
    var svg: String

    @Option(help: "Path to counties descriptor JSON")
    var descriptor: String

    @Option(help: "Minimum shared boundary length to count as adjacency")
    var minSharedLength: Double = 1.0

    @Option(help: "Snap tolerance used when normalizing coordinates")
    var snapTolerance: Double = 0.05

    @Option(help: "Number of line segments used to approximate cubic curves")
    var curveSubdivisions: Int = 20

    @Flag(help: "Update descriptor regions[].neighbors with computed result")
    var updateDescriptor = false

    @Option(help: "Write output JSON to this path")
    var output: String?

    @Flag(help: "Fallback: map unmapped SVG paths by descriptor order (unsafe)")
    var allowOrderFallback = false

    @Flag(name: .customLong("strict-unmapped-paths"), help: "Fail if SVG contains unmapped paths")
    var strictUnmappedPaths = false

    @Option(name: .customLong("ground-truth"), help: "Path to expected adjacency JSON for validation")
    var groundTruth: String?

    @Flag(name: .customLong("strict-ground-truth"), help: "Fail command on any ground-truth mismatch")
    var strictGroundTruth = false

    mutating func validate() throws {
        guard minSharedLength > 0 else { throw ValidationError("--min-shared-length must be > 0") }
        guard snapTolerance > 0 else { throw ValidationError("--snap-tolerance must be > 0") }
        guard curveSubdivisions >= 2 else { throw ValidationError("--curve-subdivisions must be >= 2") }
    }

    func run() throws {
        let options = Options(
            svgPath: svg,
            descriptorPath: descriptor,
            minSharedLength: minSharedLength,
            snapTolerance: snapTolerance,
            curveSubdivisions: curveSubdivisions,
            updateDescriptor: updateDescriptor,
            outputPath: output,
            allowOrderFallback: allowOrderFallback,
            ignoreUnmappedPaths: !strictUnmappedPaths,
            groundTruthPath: groundTruth
        )

        var descriptor = try loadDescriptor(at: options.descriptorPath)
        let pathElements = try extractPaths(fromSVGAt: options.svgPath)

        let regionToSegments = try mapRegionsToSegments(pathElements: pathElements, descriptor: descriptor, options: options)
        let computedNeighbors = computeNeighbors(
            regionToSegments: regionToSegments,
            minSharedLength: options.minSharedLength,
            snapTolerance: options.snapTolerance
        )

        if let groundTruthPath = options.groundTruthPath {
            if strictGroundTruth {
                try validateAgainstGroundTruth(computedNeighbors: computedNeighbors, groundTruthPath: groundTruthPath)
            } else {
                let report = try makeGroundTruthReport(computedNeighbors: computedNeighbors, groundTruthPath: groundTruthPath)
                printGroundTruthReport(report)
            }
        }

        let sortedOutput = Dictionary(uniqueKeysWithValues: computedNeighbors.map { key, value in
            (key, value.sorted())
        })

        if options.updateDescriptor {
            for index in descriptor.regions.indices {
                let key = descriptor.regions[index].regionKey
                descriptor.regions[index].neighbors = sortedOutput[key, default: []]
            }

            let encoded = try JSONEncoder.pretty.encode(descriptor)
            let targetPath = options.outputPath ?? options.descriptorPath
            try encoded.write(to: URL(fileURLWithPath: targetPath))
            print("Updated descriptor: \(targetPath)")
            return
        }

        let outputData = try JSONSerialization.data(withJSONObject: sortedOutput, options: [.prettyPrinted, .sortedKeys])
        if let outputPath = options.outputPath {
            try outputData.write(to: URL(fileURLWithPath: outputPath))
            print("Wrote adjacency JSON: \(outputPath)")
            return
        }

        if let outputText = String(data: outputData, encoding: .utf8) {
            print(outputText)
        }
    }
}

struct FetchGroundTruth: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fetch-ground-truth",
        abstract: "Fetch and normalize administrative adjacency from Wikidata."
    )

    @Option(name: .customLong("country-qid"), help: "Wikidata country QID (example: Q28 for Hungary)")
    var countryQID: String

    @Option(name: .customLong("subdivision-class-qid"), help: "Wikidata subdivision class QID (example: Q188604 county of Hungary)")
    var subdivisionClassQID: String

    @Option(name: .customLong("include-qid"), parsing: .upToNextOption, help: "Extra Wikidata entity QID(s) to include (repeatable)")
    var includeQIDs: [String] = []

    @Option(name: .customLong("country-code"), help: "Country code used in metadata and default prefix")
    var countryCode: String = "HU"

    @Option(name: .customLong("normalize-prefix"), help: "Region key prefix used in normalization (default: lowercase country code)")
    var normalizePrefix: String?

    @Option(name: .customLong("wikidata-language"), help: "Wikidata label language for normalization")
    var wikidataLanguage: String = "en"

    @Option(name: .customLong("qid-region-map"), help: "Optional JSON file mapping Wikidata QID to regionKey")
    var qidRegionMap: String?

    @Option(help: "Write output JSON to this path")
    var output: String?

    mutating func validate() throws {
        guard !countryQID.isEmpty, countryQID.first == "Q" else {
            throw ValidationError("--country-qid must be a Wikidata QID like Q28")
        }
        guard !subdivisionClassQID.isEmpty, subdivisionClassQID.first == "Q" else {
            throw ValidationError("--subdivision-class-qid must be a Wikidata QID like Q188604")
        }
        for qid in includeQIDs {
            guard qid.first == "Q" else {
                throw ValidationError("--include-qid values must be Wikidata QIDs like Q1781")
            }
        }
    }

    func run() throws {
        let options = GroundTruthFetchOptions(
            countryQID: countryQID,
            subdivisionClassQID: subdivisionClassQID,
            includeQIDs: includeQIDs,
            countryCode: countryCode,
            normalizePrefix: normalizePrefix ?? countryCode.lowercased(),
            language: wikidataLanguage,
            qidRegionMapPath: qidRegionMap,
            outputPath: output
        )
        try fetchAndWriteGroundTruth(options: options)
    }
}

struct CompareAdjacency: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "compare",
        abstract: "Write compact edge-level diff artifacts for CI."
    )

    @Option(help: "Path to SVG file")
    var svg: String

    @Option(help: "Path to counties descriptor JSON")
    var descriptor: String

    @Option(name: .customLong("ground-truth"), help: "Path to expected adjacency JSON")
    var groundTruth: String

    @Option(name: .customLong("output-dir"), help: "Directory for JSON artifacts")
    var outputDir: String = "."

    @Option(help: "Minimum shared boundary length to count as adjacency")
    var minSharedLength: Double = 1.0

    @Option(help: "Snap tolerance used when normalizing coordinates")
    var snapTolerance: Double = 0.05

    @Option(help: "Number of line segments used to approximate cubic curves")
    var curveSubdivisions: Int = 20

    @Flag(help: "Fallback: map unmapped SVG paths by descriptor order (unsafe)")
    var allowOrderFallback = false

    @Flag(name: .customLong("strict-unmapped-paths"), help: "Fail if SVG contains unmapped paths")
    var strictUnmappedPaths = false

    @Flag(name: .customLong("fail-on-diff"), help: "Exit non-zero when any edge diff exists")
    var failOnDiff = false

    mutating func validate() throws {
        guard minSharedLength > 0 else { throw ValidationError("--min-shared-length must be > 0") }
        guard snapTolerance > 0 else { throw ValidationError("--snap-tolerance must be > 0") }
        guard curveSubdivisions >= 2 else { throw ValidationError("--curve-subdivisions must be >= 2") }
    }

    func run() throws {
        let options = Options(
            svgPath: svg,
            descriptorPath: descriptor,
            minSharedLength: minSharedLength,
            snapTolerance: snapTolerance,
            curveSubdivisions: curveSubdivisions,
            updateDescriptor: false,
            outputPath: nil,
            allowOrderFallback: allowOrderFallback,
            ignoreUnmappedPaths: !strictUnmappedPaths,
            groundTruthPath: groundTruth
        )

        let descriptor = try loadDescriptor(at: options.descriptorPath)
        let pathElements = try extractPaths(fromSVGAt: options.svgPath)
        let regionToSegments = try mapRegionsToSegments(pathElements: pathElements, descriptor: descriptor, options: options)
        let computedNeighbors = computeNeighbors(
            regionToSegments: regionToSegments,
            minSharedLength: options.minSharedLength,
            snapTolerance: options.snapTolerance
        )

        let diff = try makeGroundTruthDiff(computedNeighbors: computedNeighbors, groundTruthPath: groundTruth)

        let fileManager = FileManager.default
        let outputURL = URL(fileURLWithPath: outputDir, isDirectory: true)
        try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let missingPath = outputURL.appendingPathComponent("missing_edges.json")
        let extraPath = outputURL.appendingPathComponent("extra_edges.json")
        let summaryPath = outputURL.appendingPathComponent("compare_summary.json")

        try JSONEncoder.pretty.encode(diff.missingEdges).write(to: missingPath)
        try JSONEncoder.pretty.encode(diff.extraEdges).write(to: extraPath)

        let summary = CompareSummary(
            expectedEdgeCount: diff.expectedEdgeCount,
            computedEdgeCount: diff.computedEdgeCount,
            overlapEdgeCount: diff.intersectionEdgeCount,
            missingEdgeCount: diff.missingEdges.count,
            extraEdgeCount: diff.extraEdges.count,
            precision: diff.precision,
            recall: diff.recall,
            missingEdgesFile: "missing_edges.json",
            extraEdgesFile: "extra_edges.json"
        )
        try JSONEncoder.pretty.encode(summary).write(to: summaryPath)

        print("Wrote artifacts:")
        print("- \(missingPath.path)")
        print("- \(extraPath.path)")
        print("- \(summaryPath.path)")

        if failOnDiff, !diff.missingEdges.isEmpty || !diff.extraEdges.isEmpty {
            throw ToolError.validation("Diff detected: missing=\(diff.missingEdges.count), extra=\(diff.extraEdges.count)")
        }
    }
}

struct GenerateDataset: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate-dataset",
        abstract: "Generate xcassets dataset files from map config."
    )

    @Option(help: "Path to map.config.json")
    var config: String

    func run() throws {
        let generated = try generateDatasets(fromConfigPath: config)
        print("Generated datasets for \(generated.mapID):")
        for datasetPath in generated.datasetPaths.sorted() {
            print("- \(datasetPath)")
        }
    }
}

struct GenerateIndex: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate-index",
        abstract: "Generate typed Swift map asset index from map config files."
    )

    @Option(name: .customLong("config"), parsing: .upToNextOption, help: "Path(s) to map.config.json")
    var configs: [String]

    @Option(help: "Path to generated Swift output file")
    var output: String

    mutating func validate() throws {
        guard !configs.isEmpty else {
            throw ValidationError("--config must be provided at least once")
        }
    }

    func run() throws {
        let index = try generateMapAssetIndex(configPaths: configs)
        try writeMapAssetIndex(index, outputPath: output)
        print("Wrote map asset index: \(output)")
    }
}

struct SyncAssets: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sync-assets",
        abstract: "Generate dataset assets and Swift index in one command."
    )

    @Option(name: .customLong("config"), parsing: .upToNextOption, help: "Path(s) to map.config.json")
    var configs: [String]

    @Option(help: "Path to generated Swift output file")
    var indexOutput: String

    mutating func validate() throws {
        guard !configs.isEmpty else {
            throw ValidationError("--config must be provided at least once")
        }
    }

    func run() throws {
        var allDatasetPaths: [String] = []
        for configPath in configs {
            let generated = try generateDatasets(fromConfigPath: configPath)
            allDatasetPaths.append(contentsOf: generated.datasetPaths)
        }

        let index = try generateMapAssetIndex(configPaths: configs)
        try writeMapAssetIndex(index, outputPath: indexOutput)

        print("Synced assets")
        for datasetPath in allDatasetPaths.sorted() {
            print("- \(datasetPath)")
        }
        print("- \(indexOutput)")
    }
}

struct Options {
    var svgPath: String
    var descriptorPath: String
    var minSharedLength: Double
    var snapTolerance: Double
    var curveSubdivisions: Int
    var updateDescriptor: Bool
    var outputPath: String?
    var allowOrderFallback: Bool
    var ignoreUnmappedPaths: Bool
    var groundTruthPath: String?
}

struct GroundTruthFetchOptions {
    var countryQID: String
    var subdivisionClassQID: String
    var includeQIDs: [String]
    var countryCode: String
    var normalizePrefix: String
    var language: String
    var qidRegionMapPath: String?
    var outputPath: String?
}

struct MapConfig: Codable {
    struct Inputs: Codable {
        var svgPath: String
        var descriptorPath: String
    }

    struct Outputs: Codable {
        var assetCatalogPath: String
        var svgDatasetName: String
        var svgFileName: String
        var descriptorDatasetName: String
        var descriptorFileName: String
    }

    struct AdjacencyConfig: Codable {
        var minSharedLength: Double?
        var snapTolerance: Double?
        var curveSubdivisions: Int?
    }

    var schemaVersion: Int
    var mapID: String
    var countryCode: String
    var displayName: String?
    var inputs: Inputs
    var outputs: Outputs
    var adjacency: AdjacencyConfig?

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case mapID = "mapId"
        case countryCode
        case displayName
        case inputs
        case outputs
        case adjacency
    }
}

struct ResolvedMapConfigPaths {
    var svgPath: String
    var descriptorPath: String
    var assetCatalogPath: String
}

struct DatasetSourceFile {
    var datasetName: String
    var fileName: String
    var sourcePath: String
    var uti: String
}

struct GeneratedDatasets {
    var mapID: String
    var datasetPaths: [String]
}

struct DatasetContents: Codable {
    struct DataEntry: Codable {
        var filename: String
        var idiom: String
        var universalTypeIdentifier: String

        enum CodingKeys: String, CodingKey {
            case filename
            case idiom
            case universalTypeIdentifier = "universal-type-identifier"
        }
    }

    struct Info: Codable {
        var author: String
        var version: Int
    }

    var data: [DataEntry]
    var info: Info
}

struct MapAssetIndexEntry {
    var mapID: String
    var countryCode: String
    var displayName: String?
    var svgDatasetName: String
    var svgFileName: String
    var descriptorDatasetName: String
    var descriptorFileName: String
}

struct MapAssetIndex {
    var entries: [MapAssetIndexEntry]
}

struct Descriptor: Codable {
    var schemaVersion: Int
    var countryCode: String
    var svgAssetName: String?
    var regions: [Region]
}

struct Region: Codable {
    var regionKey: String
    var associatedVignetteTypes: [String]
    var neighbors: [String]
}

struct PathElement {
    var id: String?
    var regionKey: String?
    var ignoreAdjacency: Bool
    var d: String
}

struct Point: Hashable {
    var x: Double
    var y: Double
}

struct Segment {
    var start: Point
    var end: Point

    var length: Double {
        hypot(end.x - start.x, end.y - start.y)
    }
}

struct SnappedPoint: Hashable {
    var x: Int
    var y: Int
}

struct SnappedEdgeKey: Hashable {
    var a: SnappedPoint
    var b: SnappedPoint
}

enum Token {
    case command(Character)
    case number(Double)
}

enum ToolError: Error, CustomStringConvertible {
    case io(String)
    case parse(String)
    case validation(String)

    var description: String {
        switch self {
        case let .io(message), let .parse(message), let .validation(message):
            return message
        }
    }
}

func loadDescriptor(at path: String) throws -> Descriptor {
    let url = URL(fileURLWithPath: path)
    guard let data = try? Data(contentsOf: url) else {
        throw ToolError.io("Cannot read descriptor file: \(path)")
    }
    do {
        return try JSONDecoder().decode(Descriptor.self, from: data)
    } catch {
        throw ToolError.parse("Failed to parse descriptor JSON: \(error.localizedDescription)")
    }
}

func loadMapConfig(at path: String) throws -> MapConfig {
    let url = URL(fileURLWithPath: path)
    guard let data = try? Data(contentsOf: url) else {
        throw ToolError.io("Cannot read map config file: \(path)")
    }

    do {
        return try JSONDecoder().decode(MapConfig.self, from: data)
    } catch {
        throw ToolError.parse("Failed to parse map config JSON: \(error.localizedDescription)")
    }
}

func resolveMapConfigPaths(configPath: String, config: MapConfig) throws -> ResolvedMapConfigPaths {
    let configURL = URL(fileURLWithPath: configPath)
    let baseURL = configURL.deletingLastPathComponent()

    func resolve(_ path: String) -> String {
        let url: URL
        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else {
            url = URL(fileURLWithPath: path, relativeTo: baseURL).standardizedFileURL
        }
        return url.path
    }

    return ResolvedMapConfigPaths(
        svgPath: resolve(config.inputs.svgPath),
        descriptorPath: resolve(config.inputs.descriptorPath),
        assetCatalogPath: resolve(config.outputs.assetCatalogPath)
    )
}

func generateDatasets(fromConfigPath configPath: String) throws -> GeneratedDatasets {
    let loadedConfig = try loadMapConfig(at: configPath)
    let resolved = try resolveMapConfigPaths(configPath: configPath, config: loadedConfig)

    guard FileManager.default.fileExists(atPath: resolved.svgPath) else {
        throw ToolError.validation("SVG input file does not exist: \(resolved.svgPath)")
    }

    guard FileManager.default.fileExists(atPath: resolved.descriptorPath) else {
        throw ToolError.validation("Descriptor input file does not exist: \(resolved.descriptorPath)")
    }

    guard FileManager.default.fileExists(atPath: resolved.assetCatalogPath) else {
        throw ToolError.validation("Asset catalog path does not exist: \(resolved.assetCatalogPath)")
    }

    guard resolved.assetCatalogPath.hasSuffix(".xcassets") else {
        throw ToolError.validation("Configured assetCatalogPath is not an .xcassets directory: \(resolved.assetCatalogPath)")
    }

    let sourceFiles = try makeDatasetSourceFiles(config: loadedConfig, resolvedPaths: resolved)
    let groupedByDataset = Dictionary(grouping: sourceFiles, by: \.datasetName)

    var datasetPaths: [String] = []
    for datasetName in groupedByDataset.keys.sorted() {
        guard let files = groupedByDataset[datasetName] else { continue }
        let datasetPath = try writeDataset(
            assetCatalogPath: resolved.assetCatalogPath,
            datasetName: datasetName,
            sourceFiles: files
        )
        datasetPaths.append(datasetPath)
    }

    return GeneratedDatasets(mapID: loadedConfig.mapID, datasetPaths: datasetPaths)
}

func makeDatasetSourceFiles(config: MapConfig, resolvedPaths: ResolvedMapConfigPaths) throws -> [DatasetSourceFile] {
    let files = [
        DatasetSourceFile(
            datasetName: config.outputs.svgDatasetName,
            fileName: config.outputs.svgFileName,
            sourcePath: resolvedPaths.svgPath,
            uti: "public.svg-image"
        ),
        DatasetSourceFile(
            datasetName: config.outputs.descriptorDatasetName,
            fileName: config.outputs.descriptorFileName,
            sourcePath: resolvedPaths.descriptorPath,
            uti: "public.json"
        ),
    ]

    let duplicateNames = Dictionary(grouping: files, by: \.fileName)
        .filter { $0.value.count > 1 }
        .keys
        .sorted()
    if !duplicateNames.isEmpty {
        throw ToolError.validation(
            "Duplicate output file name(s) across dataset specs: \(duplicateNames.joined(separator: ", "))"
        )
    }

    return files
}

func writeDataset(assetCatalogPath: String, datasetName: String, sourceFiles: [DatasetSourceFile]) throws -> String {
    let fileManager = FileManager.default
    let datasetURL = URL(fileURLWithPath: assetCatalogPath, isDirectory: true)
        .appendingPathComponent("\(datasetName).dataset", isDirectory: true)

    try fileManager.createDirectory(at: datasetURL, withIntermediateDirectories: true)

    let allowedNames = Set(sourceFiles.map(\.fileName)).union(["Contents.json"])
    try pruneUnexpectedDatasetFiles(datasetURL: datasetURL, allowedNames: allowedNames)

    for file in sourceFiles {
        let sourceURL = URL(fileURLWithPath: file.sourcePath)
        let targetURL = datasetURL.appendingPathComponent(file.fileName)
        let inputData = try Data(contentsOf: sourceURL)
        try writeFileIfChanged(data: inputData, to: targetURL)
    }

    let dataEntries = sourceFiles
        .map { file in
            DatasetContents.DataEntry(filename: file.fileName, idiom: "universal", universalTypeIdentifier: file.uti)
        }
        .sorted { $0.filename < $1.filename }

    let contents = DatasetContents(
        data: dataEntries,
        info: .init(author: "xcode", version: 1)
    )
    let encodedContents = try JSONEncoder.pretty.encode(contents)
    let contentsURL = datasetURL.appendingPathComponent("Contents.json")
    try writeFileIfChanged(data: encodedContents, to: contentsURL)

    return datasetURL.path
}

func pruneUnexpectedDatasetFiles(datasetURL: URL, allowedNames: Set<String>) throws {
    let fileManager = FileManager.default
    let existing = try fileManager.contentsOfDirectory(atPath: datasetURL.path)
    for name in existing where !allowedNames.contains(name) {
        let staleURL = datasetURL.appendingPathComponent(name)
        try fileManager.removeItem(at: staleURL)
    }
}

func writeFileIfChanged(data: Data, to url: URL) throws {
    if let current = try? Data(contentsOf: url), current == data {
        return
    }
    try data.write(to: url, options: .atomic)
}

func generateMapAssetIndex(configPaths: [String]) throws -> MapAssetIndex {
    var entries: [MapAssetIndexEntry] = []
    entries.reserveCapacity(configPaths.count)

    for configPath in configPaths {
        let config = try loadMapConfig(at: configPath)
        entries.append(
            MapAssetIndexEntry(
                mapID: config.mapID,
                countryCode: config.countryCode,
                displayName: config.displayName,
                svgDatasetName: config.outputs.svgDatasetName,
                svgFileName: config.outputs.svgFileName,
                descriptorDatasetName: config.outputs.descriptorDatasetName,
                descriptorFileName: config.outputs.descriptorFileName
            )
        )
    }

    entries.sort { $0.mapID < $1.mapID }
    return MapAssetIndex(entries: entries)
}

func writeMapAssetIndex(_ index: MapAssetIndex, outputPath: String) throws {
    let outputURL = URL(fileURLWithPath: outputPath)
    let outputDirectory = outputURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    var lines: [String] = []
    lines.append("import Foundation")
    lines.append("")
    lines.append("struct MapAssetDefinition: Sendable {")
    lines.append("    let mapID: String")
    lines.append("    let countryCode: String")
    lines.append("    let displayName: String")
    lines.append("    let svgDatasetName: String")
    lines.append("    let svgFileName: String")
    lines.append("    let descriptorDatasetName: String")
    lines.append("    let descriptorFileName: String")
    lines.append("}")
    lines.append("")
    lines.append("enum MapAssetIndex {")
    lines.append("    static let all: [MapAssetDefinition] = [")

    for entry in index.entries {
        let displayName = swiftStringLiteral(entry.displayName ?? entry.mapID)
        lines.append(
            "        MapAssetDefinition(mapID: \(swiftStringLiteral(entry.mapID)), countryCode: \(swiftStringLiteral(entry.countryCode)), displayName: \(displayName), svgDatasetName: \(swiftStringLiteral(entry.svgDatasetName)), svgFileName: \(swiftStringLiteral(entry.svgFileName)), descriptorDatasetName: \(swiftStringLiteral(entry.descriptorDatasetName)), descriptorFileName: \(swiftStringLiteral(entry.descriptorFileName))),"
        )
    }

    lines.append("    ]")
    lines.append("}")
    lines.append("")

    let content = lines.joined(separator: "\n")
    guard let data = content.data(using: .utf8) else {
        throw ToolError.io("Failed to encode generated Swift index as UTF-8")
    }
    try writeFileIfChanged(data: data, to: outputURL)
}

func swiftStringLiteral(_ value: String) -> String {
    let escaped = value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
    return "\"\(escaped)\""
}

func extractPaths(fromSVGAt path: String) throws -> [PathElement] {
    let url = URL(fileURLWithPath: path)
    guard let svg = try? String(contentsOf: url, encoding: .utf8) else {
        throw ToolError.io("Cannot read SVG file: \(path)")
    }

    let pathPattern = #"<path\b[^>]*>"#
    let regex = try NSRegularExpression(pattern: pathPattern, options: [.caseInsensitive])
    let nsRange = NSRange(svg.startIndex..<svg.endIndex, in: svg)
    let matches = regex.matches(in: svg, options: [], range: nsRange)

    var result: [PathElement] = []
    result.reserveCapacity(matches.count)

    for match in matches {
        guard let range = Range(match.range, in: svg) else { continue }
        let tag = String(svg[range])
        guard let d = attribute(named: "d", in: tag) else { continue }

        let id = attribute(named: "id", in: tag)
        let regionKey = attribute(named: "data-region-key", in: tag)
        let ignoreAdjacency = attribute(named: "data-ignore-adjacency", in: tag) == "true"
        result.append(PathElement(id: id, regionKey: regionKey, ignoreAdjacency: ignoreAdjacency, d: d))
    }

    if result.isEmpty {
        throw ToolError.parse("No <path ... d=...> elements found in SVG")
    }

    return result
}

func attribute(named name: String, in tag: String) -> String? {
    let escapedName = NSRegularExpression.escapedPattern(for: name)
    let pattern = "\\b\(escapedName)\\s*=\\s*\"([^\"]+)\""
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
        return nil
    }
    let nsRange = NSRange(tag.startIndex..<tag.endIndex, in: tag)
    guard let match = regex.firstMatch(in: tag, options: [], range: nsRange),
          match.numberOfRanges > 1,
          let valueRange = Range(match.range(at: 1), in: tag)
    else {
        return nil
    }
    return String(tag[valueRange])
}

func mapRegionsToSegments(pathElements: [PathElement], descriptor: Descriptor, options: Options) throws -> [String: [Segment]] {
    let descriptorKeys = Set(descriptor.regions.map(\.regionKey))

    var assigned: [(regionKey: String, segments: [Segment])] = []
    var unassigned: [[Segment]] = []

    for element in pathElements {
        if element.ignoreAdjacency {
            continue
        }

        let segments = try parsePathSegments(from: element.d, curveSubdivisions: options.curveSubdivisions)
        guard !segments.isEmpty else { continue }

        if let explicit = element.regionKey, descriptorKeys.contains(explicit) {
            assigned.append((explicit, segments))
            continue
        }

        if let id = element.id, descriptorKeys.contains(id) {
            assigned.append((id, segments))
            continue
        }

        unassigned.append(segments)
    }

    var regionToSegments: [String: [Segment]] = [:]
    for item in assigned {
        if regionToSegments[item.regionKey] != nil {
            throw ToolError.validation("Duplicate SVG region mapping for key: \(item.regionKey)")
        }
        regionToSegments[item.regionKey] = item.segments
    }

    if !unassigned.isEmpty {
        if options.allowOrderFallback {
            let availableKeys = descriptor.regions.map(\.regionKey).filter { regionToSegments[$0] == nil }
            if unassigned.count > availableKeys.count {
                if options.ignoreUnmappedPaths {
                    let mappableCount = availableKeys.count
                    for index in 0 ..< mappableCount {
                        regionToSegments[availableKeys[index]] = unassigned[index]
                    }
                    fputs("Warning: order fallback mapped \(mappableCount) paths and ignored \(unassigned.count - mappableCount) extra unmapped paths.\n", stderr)
                } else {
                    throw ToolError.validation("Order fallback cannot map all paths. Unassigned paths: \(unassigned.count), available descriptor regions: \(availableKeys.count)")
                }
            } else {
                for (index, segments) in unassigned.enumerated() {
                    regionToSegments[availableKeys[index]] = segments
                }
                fputs("Warning: used order fallback for \(unassigned.count) SVG paths. Add data-region-key/id to SVG for deterministic mapping.\n", stderr)
            }
        } else if options.ignoreUnmappedPaths {
            fputs("Warning: ignored \(unassigned.count) unmapped SVG paths. Add data-region-key/id to include them.\n", stderr)
        } else {
            throw ToolError.validation("Found \(unassigned.count) SVG paths without matching data-region-key/id. Add explicit region keys or run with --allow-order-fallback.")
        }
    }

    let missingKeys = descriptor.regions.map(\.regionKey).filter { regionToSegments[$0] == nil }
    if !missingKeys.isEmpty {
        throw ToolError.validation("SVG missing descriptor regions: \(missingKeys.joined(separator: ", "))")
    }

    return regionToSegments
}

func parsePathSegments(from d: String, curveSubdivisions: Int) throws -> [Segment] {
    let tokens = tokenizePathData(d)
    if tokens.isEmpty {
        return []
    }

    var segments: [Segment] = []
    var i = 0
    var command: Character?
    var current = Point(x: 0, y: 0)
    var start = Point(x: 0, y: 0)

    func nextNumber() throws -> Double {
        guard i < tokens.count else { throw ToolError.parse("Unexpected end of path data") }
        defer { i += 1 }
        if case let .number(value) = tokens[i] {
            return value
        }
        throw ToolError.parse("Expected number in path data")
    }

    func addLine(to point: Point) {
        if current != point {
            segments.append(Segment(start: current, end: point))
            current = point
        }
    }

    while i < tokens.count {
        if case let .command(newCommand) = tokens[i] {
            command = newCommand
            i += 1
        }

        guard let command else {
            throw ToolError.parse("Path data missing initial command")
        }

        switch command {
        case "M":
            let x = try nextNumber()
            let y = try nextNumber()
            current = Point(x: x, y: y)
            start = current

            while i < tokens.count {
                if case .command = tokens[i] { break }
                let lx = try nextNumber()
                let ly = try nextNumber()
                addLine(to: Point(x: lx, y: ly))
            }
        case "L":
            while i < tokens.count {
                if case .command = tokens[i] { break }
                let x = try nextNumber()
                let y = try nextNumber()
                addLine(to: Point(x: x, y: y))
            }
        case "H":
            while i < tokens.count {
                if case .command = tokens[i] { break }
                let x = try nextNumber()
                addLine(to: Point(x: x, y: current.y))
            }
        case "V":
            while i < tokens.count {
                if case .command = tokens[i] { break }
                let y = try nextNumber()
                addLine(to: Point(x: current.x, y: y))
            }
        case "C":
            while i < tokens.count {
                if case .command = tokens[i] { break }
                let c1x = try nextNumber()
                let c1y = try nextNumber()
                let c2x = try nextNumber()
                let c2y = try nextNumber()
                let ex = try nextNumber()
                let ey = try nextNumber()

                let p0 = current
                let p1 = Point(x: c1x, y: c1y)
                let p2 = Point(x: c2x, y: c2y)
                let p3 = Point(x: ex, y: ey)

                var previous = p0
                for step in 1 ... curveSubdivisions {
                    let t = Double(step) / Double(curveSubdivisions)
                    let point = cubicBezier(p0: p0, p1: p1, p2: p2, p3: p3, t: t)
                    if previous != point {
                        segments.append(Segment(start: previous, end: point))
                    }
                    previous = point
                }
                current = p3
            }
        case "Z":
            addLine(to: start)
        default:
            throw ToolError.parse("Unsupported SVG path command: \(command)")
        }
    }

    return segments
}

func tokenizePathData(_ d: String) -> [Token] {
    var tokens: [Token] = []
    var i = d.startIndex

    func isCommand(_ c: Character) -> Bool {
        c == "M" || c == "L" || c == "H" || c == "V" || c == "C" || c == "Z"
    }

    while i < d.endIndex {
        let c = d[i]
        if c == " " || c == "\n" || c == "\t" || c == "," {
            i = d.index(after: i)
            continue
        }

        if isCommand(c) {
            tokens.append(.command(c))
            i = d.index(after: i)
            continue
        }

        if c == "-" || c == "+" || c == "." || c.isNumber {
            let start = i
            i = d.index(after: i)
            while i < d.endIndex {
                let ch = d[i]
                let isNumeric = ch.isNumber || ch == "." || ch == "e" || ch == "E" || ch == "-" || ch == "+"
                if isNumeric {
                    let prev = d[d.index(before: i)]
                    if (ch == "-" || ch == "+") && prev != "e" && prev != "E" {
                        break
                    }
                    i = d.index(after: i)
                } else {
                    break
                }
            }
            let value = String(d[start ..< i])
            if let number = Double(value) {
                tokens.append(.number(number))
            }
            continue
        }

        i = d.index(after: i)
    }

    return tokens
}

func cubicBezier(p0: Point, p1: Point, p2: Point, p3: Point, t: Double) -> Point {
    let mt = 1 - t
    let a = mt * mt * mt
    let b = 3 * mt * mt * t
    let c = 3 * mt * t * t
    let d = t * t * t
    return Point(
        x: a * p0.x + b * p1.x + c * p2.x + d * p3.x,
        y: a * p0.y + b * p1.y + c * p2.y + d * p3.y
    )
}

func computeNeighbors(regionToSegments: [String: [Segment]], minSharedLength: Double, snapTolerance: Double) -> [String: Set<String>] {
    var boundaryEdgeToRegions: [SnappedEdgeKey: [String: Int]] = [:]

    for (regionKey, segments) in regionToSegments {
        for segment in segments where segment.length > 0 {
            let sampleCount = max(1, Int(ceil(segment.length / snapTolerance)))
            var sampledPoints: [SnappedPoint] = []
            sampledPoints.reserveCapacity(sampleCount + 1)

            for sampleIndex in 0 ... sampleCount {
                let t = Double(sampleIndex) / Double(sampleCount)
                let point = Point(
                    x: segment.start.x + (segment.end.x - segment.start.x) * t,
                    y: segment.start.y + (segment.end.y - segment.start.y) * t
                )
                let snapped = snapPoint(point, snapTolerance: snapTolerance)
                sampledPoints.append(snapped)
            }

            guard sampledPoints.count >= 2 else { continue }

            for index in 0 ..< (sampledPoints.count - 1) {
                let start = sampledPoints[index]
                let end = sampledPoints[index + 1]
                guard start != end else { continue }

                let edge = makeEdgeKey(start: start, end: end)
                boundaryEdgeToRegions[edge, default: [:]][regionKey, default: 0] += 1
            }
        }
    }

    var sharedEdgeCountByPair: [String: [String: Int]] = [:]

    for regionCounts in boundaryEdgeToRegions.values where regionCounts.count >= 2 {
        let entries = Array(regionCounts)
        for i in 0 ..< entries.count {
            for j in (i + 1) ..< entries.count {
                let lhs = entries[i]
                let rhs = entries[j]
                let shared = min(lhs.value, rhs.value)
                sharedEdgeCountByPair[lhs.key, default: [:]][rhs.key, default: 0] += shared
                sharedEdgeCountByPair[rhs.key, default: [:]][lhs.key, default: 0] += shared
            }
        }
    }

    var neighbors: [String: Set<String>] = [:]
    for region in regionToSegments.keys {
        neighbors[region] = []
    }

    for (lhs, rhsMap) in sharedEdgeCountByPair {
        for (rhs, sharedEdgeCount) in rhsMap {
            let sharedLengthEstimate = Double(sharedEdgeCount) * snapTolerance
            guard sharedLengthEstimate >= minSharedLength else { continue }
            neighbors[lhs, default: []].insert(rhs)
            neighbors[rhs, default: []].insert(lhs)
        }
    }

    return neighbors
}

func makeEdgeKey(start: SnappedPoint, end: SnappedPoint) -> SnappedEdgeKey {
    let startBeforeEnd = (start.x < end.x) || (start.x == end.x && start.y <= end.y)
    if startBeforeEnd {
        return SnappedEdgeKey(a: start, b: end)
    }
    return SnappedEdgeKey(a: end, b: start)
}

func snapPoint(_ point: Point, snapTolerance: Double) -> SnappedPoint {
    let sx = Int((point.x / snapTolerance).rounded())
    let sy = Int((point.y / snapTolerance).rounded())
    return SnappedPoint(x: sx, y: sy)
}

func validateAgainstGroundTruth(computedNeighbors: [String: Set<String>], groundTruthPath: String) throws {
    let report = try makeGroundTruthReport(computedNeighbors: computedNeighbors, groundTruthPath: groundTruthPath)

    if !report.mismatches.isEmpty {
        throw ToolError.validation("Ground-truth mismatch:\n\(report.mismatches.joined(separator: "\n"))")
    }

    print("Ground-truth validation passed")
}

struct GroundTruthReport {
    var expectedEdgeCount: Int
    var computedEdgeCount: Int
    var intersectionEdgeCount: Int
    var precision: Double
    var recall: Double
    var mismatches: [String]
}

struct GroundTruthDiff {
    var expectedEdgeCount: Int
    var computedEdgeCount: Int
    var intersectionEdgeCount: Int
    var precision: Double
    var recall: Double
    var missingEdges: [String]
    var extraEdges: [String]
}

struct CompareSummary: Codable {
    var expectedEdgeCount: Int
    var computedEdgeCount: Int
    var overlapEdgeCount: Int
    var missingEdgeCount: Int
    var extraEdgeCount: Int
    var precision: Double
    var recall: Double
    var missingEdgesFile: String
    var extraEdgesFile: String
}

func makeGroundTruthDiff(computedNeighbors: [String: Set<String>], groundTruthPath: String) throws -> GroundTruthDiff {
    let url = URL(fileURLWithPath: groundTruthPath)
    guard let data = try? Data(contentsOf: url) else {
        throw ToolError.io("Cannot read ground-truth file: \(groundTruthPath)")
    }

    let raw = try JSONSerialization.jsonObject(with: data)
    let dictionary = try decodeGroundTruthAdjacency(raw)

    let expected = dictionary.mapValues(Set.init)
    let expectedEdges = undirectedEdgeSet(from: expected)
    let computedEdges = undirectedEdgeSet(from: computedNeighbors)
    let intersection = expectedEdges.intersection(computedEdges)

    let missing = expectedEdges.subtracting(computedEdges).sorted()
    let extra = computedEdges.subtracting(expectedEdges).sorted()

    return GroundTruthDiff(
        expectedEdgeCount: expectedEdges.count,
        computedEdgeCount: computedEdges.count,
        intersectionEdgeCount: intersection.count,
        precision: Double(intersection.count) / Double(max(computedEdges.count, 1)),
        recall: Double(intersection.count) / Double(max(expectedEdges.count, 1)),
        missingEdges: missing,
        extraEdges: extra
    )
}

func makeGroundTruthReport(computedNeighbors: [String: Set<String>], groundTruthPath: String) throws -> GroundTruthReport {
    let url = URL(fileURLWithPath: groundTruthPath)
    guard let data = try? Data(contentsOf: url) else {
        throw ToolError.io("Cannot read ground-truth file: \(groundTruthPath)")
    }

    let raw = try JSONSerialization.jsonObject(with: data)
    let dictionary = try decodeGroundTruthAdjacency(raw)

    let expected = dictionary.mapValues(Set.init)
    var issues: [String] = []
    let allKeys = Set(expected.keys).union(computedNeighbors.keys)

    for key in allKeys {
        let expectedSet = expected[key, default: []]
        let computedSet = computedNeighbors[key, default: []]
        if expectedSet != computedSet {
            let missing = expectedSet.subtracting(computedSet).sorted()
            let extra = computedSet.subtracting(expectedSet).sorted()
            issues.append("\(key) missing=\(missing) extra=\(extra)")
        }
    }

    let diff = try makeGroundTruthDiff(computedNeighbors: computedNeighbors, groundTruthPath: groundTruthPath)

    return GroundTruthReport(
        expectedEdgeCount: diff.expectedEdgeCount,
        computedEdgeCount: diff.computedEdgeCount,
        intersectionEdgeCount: diff.intersectionEdgeCount,
        precision: diff.precision,
        recall: diff.recall,
        mismatches: issues.sorted()
    )
}

func printGroundTruthReport(_ report: GroundTruthReport) {
    let precision = String(format: "%.4f", report.precision)
    let recall = String(format: "%.4f", report.recall)

    if report.mismatches.isEmpty {
        print("Ground-truth validation passed")
        print("edges expected=\(report.expectedEdgeCount) computed=\(report.computedEdgeCount) precision=\(precision) recall=\(recall)")
        return
    }

    print("Ground-truth mismatch (non-strict mode)")
    print("edges expected=\(report.expectedEdgeCount) computed=\(report.computedEdgeCount) overlap=\(report.intersectionEdgeCount) precision=\(precision) recall=\(recall)")
    for issue in report.mismatches {
        print(issue)
    }
}

func decodeGroundTruthAdjacency(_ raw: Any) throws -> [String: [String]] {
    if let direct = raw as? [String: [String]] {
        return direct
    }
    if let wrapped = raw as? [String: Any], let adjacency = wrapped["adjacency"] as? [String: [String]] {
        return adjacency
    }
    throw ToolError.parse("Ground-truth file must be either {regionKey:[neighbors]} or {meta:..., adjacency:{regionKey:[neighbors]}}")
}

func undirectedEdgeSet(from adjacency: [String: Set<String>]) -> Set<String> {
    var edges: Set<String> = []
    for (lhs, rhsSet) in adjacency {
        for rhs in rhsSet {
            if lhs < rhs {
                edges.insert("\(lhs)|\(rhs)")
            } else {
                edges.insert("\(rhs)|\(lhs)")
            }
        }
    }
    return edges
}

struct GroundTruthMeta: Codable {
    var source: String
    var sourceURL: String
    var retrievedAtUtc: String
    var countryQID: String
    var subdivisionClassQID: String
    var language: String
    var query: String
    var note: String
}

struct GroundTruthDocument: Codable {
    var meta: GroundTruthMeta
    var adjacency: [String: [String]]
}

struct WikidataEntity {
    var qid: String
    var label: String
}

func fetchAndWriteGroundTruth(options: GroundTruthFetchOptions) throws {
    let qidRegionMap = try loadQIDRegionMap(path: options.qidRegionMapPath)
    let entities = try fetchWikidataEntities(
        countryQID: options.countryQID,
        subdivisionClassQID: options.subdivisionClassQID,
        includeQIDs: options.includeQIDs,
        language: options.language
    )

    var qidToRegionKey: [String: String] = [:]
    for entity in entities {
        if let mapped = qidRegionMap[entity.qid] {
            qidToRegionKey[entity.qid] = mapped
        } else {
            qidToRegionKey[entity.qid] = makeRegionKey(prefix: options.normalizePrefix, label: entity.label)
        }
    }

    let adjacencyQuery = makeAdjacencyQuery(qids: entities.map(\.qid), language: options.language)
    let adjacencyRows = try runWikidataSPARQL(query: adjacencyQuery)

    var adjacency: [String: Set<String>] = [:]
    for regionKey in qidToRegionKey.values {
        adjacency[regionKey] = []
    }

    for row in adjacencyRows {
        guard let countyURI = row["county"]?["value"] as? String,
              let neighborURI = row["neighbor"]?["value"] as? String else {
            continue
        }

        let countyQID = countyURI.components(separatedBy: "/").last ?? ""
        let neighborQID = neighborURI.components(separatedBy: "/").last ?? ""

        guard let countyKey = qidToRegionKey[countyQID],
              let neighborKey = qidToRegionKey[neighborQID],
              countyKey != neighborKey else {
            continue
        }

        adjacency[countyKey, default: []].insert(neighborKey)
        adjacency[neighborKey, default: []].insert(countyKey)
    }

    let sortedAdjacency = Dictionary(uniqueKeysWithValues: adjacency.map { key, values in
        (key, values.sorted())
    }).sorted { $0.key < $1.key }

    let document = GroundTruthDocument(
        meta: GroundTruthMeta(
            source: "Wikidata SPARQL endpoint",
            sourceURL: "https://query.wikidata.org/",
            retrievedAtUtc: iso8601NowUTC(),
            countryQID: options.countryQID,
            subdivisionClassQID: options.subdivisionClassQID,
            language: options.language,
            query: adjacencyQuery,
            note: "Use --qid-region-map for stable app-specific regionKey mapping."
        ),
        adjacency: Dictionary(uniqueKeysWithValues: sortedAdjacency)
    )

    let encoded = try JSONEncoder.pretty.encode(document)
    if let outputPath = options.outputPath {
        try encoded.write(to: URL(fileURLWithPath: outputPath))
        print("Wrote ground truth: \(outputPath)")
    } else if let text = String(data: encoded, encoding: .utf8) {
        print(text)
    }
}

func loadQIDRegionMap(path: String?) throws -> [String: String] {
    guard let path else { return [:] }
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    do {
        return try JSONDecoder().decode([String: String].self, from: data)
    } catch {
        throw ToolError.parse("Failed to parse qid-region map JSON: \(error.localizedDescription)")
    }
}

func fetchWikidataEntities(countryQID: String, subdivisionClassQID: String, includeQIDs: [String], language: String) throws -> [WikidataEntity] {
    let baseQuery = """
    SELECT ?item ?itemLabel WHERE {
      ?item wdt:P31 wd:\(subdivisionClassQID) ; wdt:P17 wd:\(countryQID) .
      SERVICE wikibase:label { bd:serviceParam wikibase:language "\(language),en". }
    }
    ORDER BY ?itemLabel
    """

    var rows = try runWikidataSPARQL(query: baseQuery)

    if !includeQIDs.isEmpty {
        let includeValues = includeQIDs.map { "wd:\($0)" }.joined(separator: " ")
        let includeQuery = """
        SELECT ?item ?itemLabel WHERE {
          VALUES ?item { \(includeValues) }
          SERVICE wikibase:label { bd:serviceParam wikibase:language "\(language),en". }
        }
        """
        rows += try runWikidataSPARQL(query: includeQuery)
    }

    var seen: Set<String> = []
    var entities: [WikidataEntity] = []
    for row in rows {
        guard let uri = row["item"]?["value"] as? String,
              let label = row["itemLabel"]?["value"] as? String else {
            continue
        }
        let qid = uri.components(separatedBy: "/").last ?? ""
        guard !qid.isEmpty, !seen.contains(qid) else { continue }
        seen.insert(qid)
        entities.append(WikidataEntity(qid: qid, label: label))
    }

    if entities.isEmpty {
        throw ToolError.validation("No entities fetched from Wikidata. Check --country-qid and --subdivision-class-qid.")
    }

    return entities
}

func makeAdjacencyQuery(qids: [String], language: String) -> String {
    let values = qids.map { "wd:\($0)" }.joined(separator: " ")
    return """
    SELECT ?county ?countyLabel ?neighbor ?neighborLabel WHERE {
      VALUES ?county { \(values) }
      VALUES ?neighbor { \(values) }
      ?county wdt:P47 ?neighbor .
      FILTER(?county != ?neighbor)
      SERVICE wikibase:label { bd:serviceParam wikibase:language "\(language),en". }
    }
    ORDER BY ?countyLabel ?neighborLabel
    """
}

func runWikidataSPARQL(query: String) throws -> [[String: [String: Any]]] {
    var components = URLComponents(string: "https://query.wikidata.org/sparql")
    components?.queryItems = [
        URLQueryItem(name: "format", value: "json"),
        URLQueryItem(name: "query", value: query),
    ]

    guard let url = components?.url else {
        throw ToolError.io("Failed to construct Wikidata query URL")
    }

    var request = URLRequest(url: url)
    request.timeoutInterval = 60
    request.setValue("CountyAdjacencyTool/1.0", forHTTPHeaderField: "User-Agent")

    let semaphore = DispatchSemaphore(value: 0)
    var resultData: Data?
    var resultError: Error?

    URLSession.shared.dataTask(with: request) { data, _, error in
        resultData = data
        resultError = error
        semaphore.signal()
    }.resume()

    semaphore.wait()

    if let resultError {
        throw ToolError.io("Wikidata request failed: \(resultError.localizedDescription)")
    }

    guard let resultData else {
        throw ToolError.io("Wikidata request returned no data")
    }

    let json = try JSONSerialization.jsonObject(with: resultData)
    guard let root = json as? [String: Any],
          let results = root["results"] as? [String: Any],
          let bindings = results["bindings"] as? [[String: [String: Any]]] else {
        throw ToolError.parse("Unexpected Wikidata response format")
    }
    return bindings
}

func makeRegionKey(prefix: String, label: String) -> String {
    let lowerPrefix = prefix.lowercased()
    let cleaned = stripAdministrativeSuffixes(label)
    let slug = slugify(cleaned)
    return "\(lowerPrefix).\(slug)"
}

func stripAdministrativeSuffixes(_ label: String) -> String {
    var result = label
    let suffixes = [
        " County",
        " county",
        " Province",
        " province",
        " Region",
        " region",
        " Department",
        " department",
    ]
    for suffix in suffixes where result.hasSuffix(suffix) {
        result = String(result.dropLast(suffix.count))
    }
    return result
}

func slugify(_ value: String) -> String {
    let folded = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    let lower = folded.lowercased()

    var scalarBuffer = String.UnicodeScalarView()
    var previousUnderscore = false

    for scalar in lower.unicodeScalars {
        if CharacterSet.alphanumerics.contains(scalar) {
            scalarBuffer.append(scalar)
            previousUnderscore = false
        } else if !previousUnderscore {
            scalarBuffer.append("_")
            previousUnderscore = true
        }
    }

    var slug = String(scalarBuffer)
    while slug.hasPrefix("_") { slug.removeFirst() }
    while slug.hasSuffix("_") { slug.removeLast() }
    if slug.isEmpty { slug = "region" }
    return slug
}

func iso8601NowUTC() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: Date())
}

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
