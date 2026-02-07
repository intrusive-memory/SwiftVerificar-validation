import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - FeatureExtractor Tests

@Suite("FeatureExtractor Tests")
struct FeatureExtractorTests {

    // MARK: - Initialization

    @Test("FeatureExtractor creates with default configuration")
    func defaultInit() {
        let extractor = FeatureExtractor()

        #expect(extractor.configuration == .default)
        #expect(extractor.statistics.totalExtracted == 0)
    }

    @Test("FeatureExtractor creates with custom configuration")
    func customInit() {
        let config = FeatureExtractionConfiguration.minimal
        let extractor = FeatureExtractor(configuration: config)

        #expect(extractor.configuration == config)
    }

    // MARK: - Single Object Extraction

    @Test("FeatureExtractor extracts from font object")
    func extractsFromFont() throws {
        var extractor = FeatureExtractor()
        let fontObject = MockFontObject(name: "Helvetica")

        let node = try extractor.extract(from: fontObject)

        #expect(node != nil)
        #expect(node?.featureType == .font)
        #expect(node?.stringValue(for: "name") == "Helvetica")
    }

    @Test("FeatureExtractor extracts from image object")
    func extractsFromImage() throws {
        var extractor = FeatureExtractor()
        let imageObject = MockImageObject(width: 800, height: 600)

        let node = try extractor.extract(from: imageObject)

        #expect(node != nil)
        #expect(node?.featureType == .image)
        #expect(node?.intValue(for: "width") == 800)
        #expect(node?.intValue(for: "height") == 600)
    }

    @Test("FeatureExtractor returns nil for unsupported object")
    func returnsNilForUnsupported() throws {
        var extractor = FeatureExtractor()
        let unsupported = UnsupportedObject()

        let node = try extractor.extract(from: unsupported)

        #expect(node == nil)
    }

    // MARK: - Multiple Object Extraction

    @Test("FeatureExtractor extracts from multiple objects")
    func extractsFromMultiple() throws {
        var extractor = FeatureExtractor()
        let objects: [any PDFObject] = [
            MockFontObject(name: "Font1"),
            MockFontObject(name: "Font2"),
            MockImageObject()
        ]

        let nodes = try extractor.extract(from: objects)

        #expect(nodes.count == 3)
    }

    @Test("FeatureExtractor skips unsupported objects in batch")
    func skipsUnsupportedInBatch() throws {
        var extractor = FeatureExtractor()
        let objects: [any PDFObject] = [
            MockFontObject(name: "Font1"),
            UnsupportedObject(),
            MockImageObject()
        ]

        let nodes = try extractor.extract(from: objects)

        #expect(nodes.count == 2)
    }

    // MARK: - Document and Page Extraction

    @Test("FeatureExtractor extracts document node")
    func extractsDocumentNode() {
        let extractor = FeatureExtractor()
        let docFeatures = DocumentFeatures(
            title: "Test",
            pdfVersion: "1.7",
            pageCount: 5
        )

        let node = extractor.extractDocumentNode(from: docFeatures)

        #expect(node.featureType == .document)
        #expect(node.stringValue(for: "title") == "Test")
    }

    @Test("FeatureExtractor extracts page node")
    func extractsPageNode() {
        let extractor = FeatureExtractor()
        let pageFeatures = PageFeatures(
            pageNumber: 1,
            mediaBox: .letter
        )

        let node = extractor.extractPageNode(from: pageFeatures)

        #expect(node.featureType == .page)
        #expect(node.intValue(for: "pageNumber") == 1)
    }

    @Test("FeatureExtractor extracts complete feature tree")
    func extractsFeatureTree() {
        let extractor = FeatureExtractor()
        let docFeatures = DocumentFeatures(
            title: "Test Document",
            pageCount: 2
        )
        let pageFeatures = [
            PageFeatures(pageNumber: 1, mediaBox: .letter),
            PageFeatures(pageNumber: 2, mediaBox: .letter)
        ]

        let tree = extractor.extractFeatureTree(
            documentFeatures: docFeatures,
            pageFeatures: pageFeatures
        )

        #expect(tree.featureType == .document)
        #expect(tree.children.count == 2)
        #expect(tree.children(ofType: .page).count == 2)
    }

    // MARK: - Statistics

    @Test("FeatureExtractor tracks extraction statistics")
    func tracksStatistics() throws {
        var extractor = FeatureExtractor()

        _ = try extractor.extract(from: MockFontObject())
        _ = try extractor.extract(from: MockFontObject())
        _ = try extractor.extract(from: MockImageObject())

        #expect(extractor.statistics.totalExtracted == 3)
        #expect(extractor.statistics.extractedByType[.font] == 2)
        #expect(extractor.statistics.extractedByType[.image] == 1)
    }

    @Test("FeatureExtractor tracks skipped objects")
    func tracksSkipped() throws {
        var extractor = FeatureExtractor()

        _ = try extractor.extract(from: UnsupportedObject())
        _ = try extractor.extract(from: UnsupportedObject())

        #expect(extractor.statistics.skippedCount == 2)
    }

    @Test("FeatureExtractor resets statistics")
    func resetsStatistics() throws {
        var extractor = FeatureExtractor()

        _ = try extractor.extract(from: MockFontObject())
        #expect(extractor.statistics.totalExtracted == 1)

        extractor.resetStatistics()
        #expect(extractor.statistics.totalExtracted == 0)
    }

    // MARK: - Report Creation

    @Test("FeatureExtractor creates report")
    func createsReport() {
        let extractor = FeatureExtractor()
        let rootNode = FeatureNode(
            featureType: .document,
            children: [
                FeatureNode(featureType: .page),
                FeatureNode(featureType: .page)
            ]
        )

        let report = extractor.createReport(from: rootNode)

        #expect(report.rootNode.featureType == .document)
        #expect(report.featureCount == 3)
        #expect(report.featureTypes.contains(.document))
        #expect(report.featureTypes.contains(.page))
    }
}

// MARK: - FeatureExtractionConfiguration Tests

@Suite("FeatureExtractionConfiguration Tests")
struct FeatureExtractionConfigurationTests {

    @Test("Default configuration")
    func defaultConfiguration() {
        let config = FeatureExtractionConfiguration.default

        #expect(config.includedFeatureTypes.isEmpty)
        #expect(config.excludedFeatureTypes.isEmpty)
        #expect(config.stopOnError == false)
        #expect(config.maxDepth == 10)
        #expect(config.includeLowLevel == false)
        #expect(config.extractResources == true)
        #expect(config.extractAnnotations == true)
        #expect(config.extractStructure == true)
    }

    @Test("Minimal configuration")
    func minimalConfiguration() {
        let config = FeatureExtractionConfiguration.minimal

        #expect(config.includedFeatureTypes.contains(.document))
        #expect(config.includedFeatureTypes.contains(.page))
        #expect(config.extractResources == false)
        #expect(config.extractAnnotations == false)
        #expect(config.extractStructure == false)
    }

    @Test("Complete configuration")
    func completeConfiguration() {
        let config = FeatureExtractionConfiguration.complete

        #expect(config.includeLowLevel == true)
        #expect(config.extractResources == true)
        #expect(config.extractAnnotations == true)
        #expect(config.extractStructure == true)
    }

    @Test("Accessibility configuration")
    func accessibilityConfiguration() {
        let config = FeatureExtractionConfiguration.accessibility

        #expect(config.includedFeatureTypes.contains(.document))
        #expect(config.includedFeatureTypes.contains(.taggedStructure))
        #expect(config.includedFeatureTypes.contains(.structureElement))
        #expect(config.extractStructure == true)
    }

    @Test("Configuration shouldExtract respects exclusions")
    func shouldExtractRespectsExclusions() {
        let config = FeatureExtractionConfiguration(
            excludedFeatureTypes: [.font, .image]
        )

        #expect(config.shouldExtract(.font) == false)
        #expect(config.shouldExtract(.image) == false)
        #expect(config.shouldExtract(.colorSpace) == true)
    }

    @Test("Configuration shouldExtract respects inclusions")
    func shouldExtractRespectsInclusions() {
        let config = FeatureExtractionConfiguration(
            includedFeatureTypes: [.document, .page]
        )

        #expect(config.shouldExtract(.document) == true)
        #expect(config.shouldExtract(.page) == true)
        #expect(config.shouldExtract(.font) == false)
    }

    @Test("Configuration shouldExtract respects category settings")
    func shouldExtractRespectsCategories() {
        let config = FeatureExtractionConfiguration(
            includeLowLevel: false,
            extractResources: false,
            extractAnnotations: false
        )

        #expect(config.shouldExtract(.xref) == false)
        #expect(config.shouldExtract(.font) == false)
        #expect(config.shouldExtract(.annotation) == false)
        #expect(config.shouldExtract(.document) == true)
        #expect(config.shouldExtract(.page) == true)
    }

    @Test("Configuration is equatable")
    func equatable() {
        let config1 = FeatureExtractionConfiguration.default
        let config2 = FeatureExtractionConfiguration.default
        let config3 = FeatureExtractionConfiguration.minimal

        #expect(config1 == config2)
        #expect(config1 != config3)
    }
}

// MARK: - FeatureExtractionStatistics Tests

@Suite("FeatureExtractionStatistics Tests")
struct FeatureExtractionStatisticsTests {

    @Test("Statistics starts empty")
    func startsEmpty() {
        let stats = FeatureExtractionStatistics()

        #expect(stats.totalExtracted == 0)
        #expect(stats.skippedCount == 0)
        #expect(stats.errorCount == 0)
        #expect(stats.totalDuration == 0)
        #expect(stats.extractedByType.isEmpty)
    }

    @Test("Statistics records extraction")
    func recordsExtraction() {
        var stats = FeatureExtractionStatistics()

        stats.recordExtraction(featureType: .font, duration: 0.001)
        stats.recordExtraction(featureType: .font, duration: 0.002)
        stats.recordExtraction(featureType: .image, duration: 0.003)

        #expect(stats.totalExtracted == 3)
        #expect(stats.extractedByType[.font] == 2)
        #expect(stats.extractedByType[.image] == 1)
        #expect(stats.totalDuration == 0.006)
    }

    @Test("Statistics average extraction time")
    func averageExtractionTime() {
        var stats = FeatureExtractionStatistics()

        stats.recordExtraction(featureType: .font, duration: 0.001)
        stats.recordExtraction(featureType: .font, duration: 0.002)

        #expect(stats.averageExtractionTime == 0.0015)
    }

    @Test("Statistics average time with no extractions")
    func averageTimeNoExtractions() {
        let stats = FeatureExtractionStatistics()
        #expect(stats.averageExtractionTime == 0)
    }

    @Test("Statistics success rate")
    func successRate() {
        var stats = FeatureExtractionStatistics()

        stats.recordExtraction(featureType: .font, duration: 0.001)
        stats.recordExtraction(featureType: .font, duration: 0.001)
        stats.incrementSkipped()
        stats.incrementErrors()

        #expect(stats.successRate == 0.5)  // 2 out of 4
    }

    @Test("Statistics success rate with no attempts")
    func successRateNoAttempts() {
        let stats = FeatureExtractionStatistics()
        #expect(stats.successRate == 1.0)
    }

    @Test("Statistics description")
    func description() {
        var stats = FeatureExtractionStatistics()
        stats.recordExtraction(featureType: .font, duration: 0.001)
        stats.incrementSkipped()
        stats.incrementErrors()

        let desc = stats.description
        #expect(desc.contains("1 extracted"))
        #expect(desc.contains("1 skipped"))
        #expect(desc.contains("1 errors"))
    }
}

// MARK: - FeatureReport Tests

@Suite("FeatureReport Tests")
struct FeatureReportTests {

    @Test("FeatureReport creation")
    func creation() {
        let rootNode = FeatureNode(
            featureType: .document,
            children: [
                FeatureNode(featureType: .page),
                FeatureNode(featureType: .font)
            ]
        )

        let report = FeatureReport(
            rootNode: rootNode,
            statistics: FeatureExtractionStatistics(),
            configuration: .default,
            extractionDate: Date()
        )

        #expect(report.rootNode.featureType == .document)
        #expect(report.featureCount == 3)
    }

    @Test("FeatureReport feature types")
    func featureTypes() {
        let rootNode = FeatureNode(
            featureType: .document,
            children: [
                FeatureNode(featureType: .page),
                FeatureNode(featureType: .font),
                FeatureNode(featureType: .font)
            ]
        )

        let report = FeatureReport(
            rootNode: rootNode,
            statistics: FeatureExtractionStatistics(),
            configuration: .default,
            extractionDate: Date()
        )

        let types = report.featureTypes
        #expect(types.contains(.document))
        #expect(types.contains(.page))
        #expect(types.contains(.font))
        #expect(types.count == 3)
    }

    @Test("FeatureReport nodes of type")
    func nodesOfType() {
        let rootNode = FeatureNode(
            featureType: .document,
            children: [
                FeatureNode(featureType: .font, name: "Font1"),
                FeatureNode(featureType: .font, name: "Font2"),
                FeatureNode(featureType: .image)
            ]
        )

        let report = FeatureReport(
            rootNode: rootNode,
            statistics: FeatureExtractionStatistics(),
            configuration: .default,
            extractionDate: Date()
        )

        let fonts = report.nodes(ofType: .font)
        #expect(fonts.count == 2)

        let images = report.nodes(ofType: .image)
        #expect(images.count == 1)
    }

    @Test("FeatureReport summary")
    func summary() {
        let rootNode = FeatureNode(
            featureType: .document,
            children: [
                FeatureNode(featureType: .page),
                FeatureNode(featureType: .font)
            ]
        )

        var stats = FeatureExtractionStatistics()
        stats.recordExtraction(featureType: .document, duration: 0.01)

        let report = FeatureReport(
            rootNode: rootNode,
            statistics: stats,
            configuration: .default,
            extractionDate: Date()
        )

        let summary = report.summary
        #expect(summary.totalFeatures == 3)
        #expect(summary.extractionDuration == 0.01)
    }

    @Test("FeatureReport description")
    func description() {
        let rootNode = FeatureNode(featureType: .document)

        let report = FeatureReport(
            rootNode: rootNode,
            statistics: FeatureExtractionStatistics(),
            configuration: .default,
            extractionDate: Date()
        )

        let desc = report.description
        #expect(desc.contains("FeatureReport"))
        #expect(desc.contains("1 features"))
        #expect(desc.contains("1 types"))
    }
}

// MARK: - FeatureReportSummary Tests

@Suite("FeatureReportSummary Tests")
struct FeatureReportSummaryTests {

    @Test("Summary creation")
    func creation() {
        let summary = FeatureReportSummary(
            totalFeatures: 100,
            featuresByType: [.font: 10, .image: 20],
            extractionDuration: 1.5,
            extractionDate: Date()
        )

        #expect(summary.totalFeatures == 100)
        #expect(summary.featuresByType[.font] == 10)
        #expect(summary.featuresByType[.image] == 20)
        #expect(summary.extractionDuration == 1.5)
    }

    @Test("Summary is equatable")
    func equatable() {
        let date = Date()
        let summary1 = FeatureReportSummary(
            totalFeatures: 100,
            featuresByType: [:],
            extractionDuration: 1.0,
            extractionDate: date
        )
        let summary2 = FeatureReportSummary(
            totalFeatures: 100,
            featuresByType: [:],
            extractionDuration: 1.0,
            extractionDate: date
        )
        let summary3 = FeatureReportSummary(
            totalFeatures: 50,
            featuresByType: [:],
            extractionDuration: 1.0,
            extractionDate: date
        )

        #expect(summary1 == summary2)
        #expect(summary1 != summary3)
    }
}
