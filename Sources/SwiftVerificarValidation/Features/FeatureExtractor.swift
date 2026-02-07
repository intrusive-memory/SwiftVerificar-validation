import Foundation

/// Main entry point for PDF feature extraction.
///
/// The `FeatureExtractor` coordinates the extraction of features from
/// PDF documents. It uses registered `FeatureAdapter` implementations
/// to extract type-specific features and assembles them into a
/// hierarchical `FeatureNode` structure.
///
/// Corresponds to the feature extraction system in veraPDF.
public struct FeatureExtractor: Sendable {

    // MARK: - Properties

    /// The adapter registry for feature extraction.
    public let registry: FeatureAdapterRegistry

    /// Configuration for feature extraction.
    public let configuration: FeatureExtractionConfiguration

    /// Statistics collected during extraction.
    public private(set) var statistics: FeatureExtractionStatistics

    // MARK: - Initialization

    /// Creates a new feature extractor with default configuration.
    public init() {
        self.registry = FeatureAdapterRegistry.shared
        self.configuration = .default
        self.statistics = FeatureExtractionStatistics()
    }

    /// Creates a new feature extractor with custom configuration.
    ///
    /// - Parameters:
    ///   - registry: The adapter registry to use.
    ///   - configuration: The extraction configuration.
    public init(
        registry: FeatureAdapterRegistry = .shared,
        configuration: FeatureExtractionConfiguration = .default
    ) {
        self.registry = registry
        self.configuration = configuration
        self.statistics = FeatureExtractionStatistics()
    }

    // MARK: - Extraction

    /// Extracts features from a PDF object.
    ///
    /// - Parameter object: The PDF object to extract features from.
    /// - Returns: A feature node, or nil if no adapter can handle the object.
    /// - Throws: `FeatureExtractionError` if extraction fails.
    public mutating func extract(from object: any PDFObject) throws -> FeatureNode? {
        let startTime = Date()

        guard let adapter = registry.findAdapter(for: object) else {
            statistics.incrementSkipped()
            return nil
        }

        do {
            let node = try adapter.extract(from: object)
            let duration = Date().timeIntervalSince(startTime)
            statistics.recordExtraction(featureType: node.featureType, duration: duration)
            return node
        } catch {
            statistics.incrementErrors()
            throw error
        }
    }

    /// Extracts features from multiple PDF objects.
    ///
    /// - Parameter objects: The PDF objects to extract features from.
    /// - Returns: An array of feature nodes for objects that could be processed.
    /// - Throws: `FeatureExtractionError` if extraction fails and `stopOnError` is true.
    public mutating func extract(from objects: [any PDFObject]) throws -> [FeatureNode] {
        var nodes: [FeatureNode] = []

        for object in objects {
            do {
                if let node = try extract(from: object) {
                    nodes.append(node)
                }
            } catch {
                if configuration.stopOnError {
                    throw error
                }
                // Continue with next object
            }
        }

        return nodes
    }

    /// Extracts document-level features.
    ///
    /// - Parameter documentFeatures: The document features to convert.
    /// - Returns: A feature node representing the document.
    public func extractDocumentNode(from documentFeatures: DocumentFeatures) -> FeatureNode {
        documentFeatures.toFeatureNode()
    }

    /// Extracts page-level features.
    ///
    /// - Parameter pageFeatures: The page features to convert.
    /// - Returns: A feature node representing the page.
    public func extractPageNode(from pageFeatures: PageFeatures) -> FeatureNode {
        pageFeatures.toFeatureNode()
    }

    /// Extracts a complete feature tree from document and page features.
    ///
    /// - Parameters:
    ///   - documentFeatures: The document-level features.
    ///   - pageFeatures: The page-level features for each page.
    /// - Returns: A root feature node with the complete feature tree.
    public func extractFeatureTree(
        documentFeatures: DocumentFeatures,
        pageFeatures: [PageFeatures]
    ) -> FeatureNode {
        let documentNode = documentFeatures.toFeatureNode()
        let pageNodes = pageFeatures.map { $0.toFeatureNode() }

        return documentNode.withChildren(pageNodes)
    }

    /// Creates a feature report from the extracted features.
    ///
    /// - Parameter rootNode: The root feature node.
    /// - Returns: A feature report.
    public func createReport(from rootNode: FeatureNode) -> FeatureReport {
        FeatureReport(
            rootNode: rootNode,
            statistics: statistics,
            configuration: configuration,
            extractionDate: Date()
        )
    }

    // MARK: - Statistics

    /// Resets the extraction statistics.
    public mutating func resetStatistics() {
        statistics = FeatureExtractionStatistics()
    }
}

// MARK: - Feature Extraction Configuration

/// Configuration options for feature extraction.
public struct FeatureExtractionConfiguration: Sendable, Equatable {

    /// Feature types to include in extraction.
    public let includedFeatureTypes: Set<FeatureType>

    /// Feature types to exclude from extraction.
    public let excludedFeatureTypes: Set<FeatureType>

    /// Whether to stop extraction on first error.
    public let stopOnError: Bool

    /// Maximum depth for recursive feature extraction.
    public let maxDepth: Int

    /// Whether to include low-level features.
    public let includeLowLevel: Bool

    /// Whether to extract resource features.
    public let extractResources: Bool

    /// Whether to extract annotation features.
    public let extractAnnotations: Bool

    /// Whether to extract structure features.
    public let extractStructure: Bool

    /// Creates a new extraction configuration.
    ///
    /// - Parameters:
    ///   - includedFeatureTypes: Types to include (empty means all).
    ///   - excludedFeatureTypes: Types to exclude.
    ///   - stopOnError: Whether to stop on error.
    ///   - maxDepth: Maximum extraction depth.
    ///   - includeLowLevel: Whether to include low-level features.
    ///   - extractResources: Whether to extract resources.
    ///   - extractAnnotations: Whether to extract annotations.
    ///   - extractStructure: Whether to extract structure.
    public init(
        includedFeatureTypes: Set<FeatureType> = [],
        excludedFeatureTypes: Set<FeatureType> = [],
        stopOnError: Bool = false,
        maxDepth: Int = 10,
        includeLowLevel: Bool = false,
        extractResources: Bool = true,
        extractAnnotations: Bool = true,
        extractStructure: Bool = true
    ) {
        self.includedFeatureTypes = includedFeatureTypes
        self.excludedFeatureTypes = excludedFeatureTypes
        self.stopOnError = stopOnError
        self.maxDepth = maxDepth
        self.includeLowLevel = includeLowLevel
        self.extractResources = extractResources
        self.extractAnnotations = extractAnnotations
        self.extractStructure = extractStructure
    }

    /// Default configuration for general feature extraction.
    public static let `default` = FeatureExtractionConfiguration()

    /// Configuration for minimal feature extraction.
    public static let minimal = FeatureExtractionConfiguration(
        includedFeatureTypes: [.document, .page],
        extractResources: false,
        extractAnnotations: false,
        extractStructure: false
    )

    /// Configuration for complete feature extraction.
    public static let complete = FeatureExtractionConfiguration(
        includeLowLevel: true,
        extractResources: true,
        extractAnnotations: true,
        extractStructure: true
    )

    /// Configuration for accessibility analysis.
    public static let accessibility = FeatureExtractionConfiguration(
        includedFeatureTypes: [.document, .page, .taggedStructure, .structureElement, .annotation],
        extractStructure: true
    )

    /// Determines whether a feature type should be extracted.
    ///
    /// - Parameter featureType: The feature type to check.
    /// - Returns: `true` if the feature type should be extracted.
    public func shouldExtract(_ featureType: FeatureType) -> Bool {
        // Check exclusions first
        if excludedFeatureTypes.contains(featureType) {
            return false
        }

        // If inclusions are specified, check them
        if !includedFeatureTypes.isEmpty {
            return includedFeatureTypes.contains(featureType)
        }

        // Check category-level settings
        switch featureType.category {
        case .lowLevel:
            return includeLowLevel
        case .resource:
            return extractResources
        case .structure:
            return extractStructure
        case .page:
            if featureType == .annotation {
                return extractAnnotations
            }
            return true
        case .document:
            return true
        }
    }
}

// MARK: - Feature Extraction Statistics

/// Statistics collected during feature extraction.
public struct FeatureExtractionStatistics: Sendable, Equatable {

    /// Number of features extracted by type.
    public private(set) var extractedByType: [FeatureType: Int]

    /// Total extraction time by type.
    public private(set) var durationByType: [FeatureType: TimeInterval]

    /// Total number of features extracted.
    public private(set) var totalExtracted: Int

    /// Number of objects skipped (no adapter found).
    public private(set) var skippedCount: Int

    /// Number of extraction errors.
    public private(set) var errorCount: Int

    /// Total extraction duration.
    public private(set) var totalDuration: TimeInterval

    /// Creates new empty statistics.
    public init() {
        self.extractedByType = [:]
        self.durationByType = [:]
        self.totalExtracted = 0
        self.skippedCount = 0
        self.errorCount = 0
        self.totalDuration = 0
    }

    /// Records a successful extraction.
    ///
    /// - Parameters:
    ///   - featureType: The type of feature extracted.
    ///   - duration: The time taken for extraction.
    public mutating func recordExtraction(featureType: FeatureType, duration: TimeInterval) {
        extractedByType[featureType, default: 0] += 1
        durationByType[featureType, default: 0] += duration
        totalExtracted += 1
        totalDuration += duration
    }

    /// Increments the skipped count.
    public mutating func incrementSkipped() {
        skippedCount += 1
    }

    /// Increments the error count.
    public mutating func incrementErrors() {
        errorCount += 1
    }

    /// The average extraction time per feature.
    public var averageExtractionTime: TimeInterval {
        guard totalExtracted > 0 else { return 0 }
        return totalDuration / Double(totalExtracted)
    }

    /// The success rate (extracted / total attempts).
    public var successRate: Double {
        let total = totalExtracted + skippedCount + errorCount
        guard total > 0 else { return 1.0 }
        return Double(totalExtracted) / Double(total)
    }
}

// MARK: - Feature Report

/// A complete feature report from extraction.
///
/// Contains the extracted feature tree along with metadata
/// about the extraction process.
public struct FeatureReport: Sendable, Identifiable {

    /// Unique identifier for this report.
    public let id: UUID

    /// The root feature node of the extracted tree.
    public let rootNode: FeatureNode

    /// Statistics from the extraction process.
    public let statistics: FeatureExtractionStatistics

    /// Configuration used for extraction.
    public let configuration: FeatureExtractionConfiguration

    /// When the extraction was performed.
    public let extractionDate: Date

    /// Creates a new feature report.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - rootNode: The root feature node.
    ///   - statistics: Extraction statistics.
    ///   - configuration: Extraction configuration.
    ///   - extractionDate: When extraction was performed.
    public init(
        id: UUID = UUID(),
        rootNode: FeatureNode,
        statistics: FeatureExtractionStatistics,
        configuration: FeatureExtractionConfiguration,
        extractionDate: Date
    ) {
        self.id = id
        self.rootNode = rootNode
        self.statistics = statistics
        self.configuration = configuration
        self.extractionDate = extractionDate
    }

    // MARK: - Convenience Access

    /// Total number of features in the report.
    public var featureCount: Int {
        1 + rootNode.descendantCount
    }

    /// All feature types present in the report.
    public var featureTypes: Set<FeatureType> {
        var types: Set<FeatureType> = [rootNode.featureType]
        for descendant in rootNode.allDescendants {
            types.insert(descendant.featureType)
        }
        return types
    }

    /// Returns all nodes of a specific feature type.
    ///
    /// - Parameter type: The feature type to filter by.
    /// - Returns: Array of matching nodes.
    public func nodes(ofType type: FeatureType) -> [FeatureNode] {
        var result: [FeatureNode] = []
        if rootNode.featureType == type {
            result.append(rootNode)
        }
        result.append(contentsOf: rootNode.descendants(ofType: type))
        return result
    }

    /// Returns a summary of the report.
    public var summary: FeatureReportSummary {
        FeatureReportSummary(
            totalFeatures: featureCount,
            featuresByType: Dictionary(
                rootNode.allDescendants.map { ($0.featureType, 1) },
                uniquingKeysWith: +
            ),
            extractionDuration: statistics.totalDuration,
            extractionDate: extractionDate
        )
    }
}

// MARK: - Feature Report Summary

/// A summary of a feature report.
public struct FeatureReportSummary: Sendable, Equatable {

    /// Total number of features.
    public let totalFeatures: Int

    /// Count of features by type.
    public let featuresByType: [FeatureType: Int]

    /// Total extraction duration.
    public let extractionDuration: TimeInterval

    /// When extraction was performed.
    public let extractionDate: Date

    /// Creates a new summary.
    public init(
        totalFeatures: Int,
        featuresByType: [FeatureType: Int],
        extractionDuration: TimeInterval,
        extractionDate: Date
    ) {
        self.totalFeatures = totalFeatures
        self.featuresByType = featuresByType
        self.extractionDuration = extractionDuration
        self.extractionDate = extractionDate
    }
}

// MARK: - CustomStringConvertible

extension FeatureExtractionStatistics: CustomStringConvertible {
    public var description: String {
        var parts = ["\(totalExtracted) extracted"]
        if skippedCount > 0 { parts.append("\(skippedCount) skipped") }
        if errorCount > 0 { parts.append("\(errorCount) errors") }
        parts.append(String(format: "%.2fms total", totalDuration * 1000))
        return parts.joined(separator: ", ")
    }
}

extension FeatureReport: CustomStringConvertible {
    public var description: String {
        let dateFormatter = ISO8601DateFormatter()
        return "FeatureReport(\(featureCount) features, \(featureTypes.count) types, \(dateFormatter.string(from: extractionDate)))"
    }
}
