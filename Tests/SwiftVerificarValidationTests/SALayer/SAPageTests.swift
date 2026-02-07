import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - SAPage Tests

@Suite("SAPage")
struct SAPageTests {

    // MARK: - Initialization Tests

    @Test("Default initialization with validated page")
    func defaultInit() {
        let page = ValidatedPage.minimal(pageNumber: 1)
        let saPage = SAPage(page: page)

        #expect(saPage.page == page)
        #expect(saPage.nodes.isEmpty)
        #expect(saPage.pageNumber == 1)
    }

    @Test("Full initialization with nodes")
    func fullInit() {
        let page = ValidatedPage.minimal(pageNumber: 2)
        let node1 = SANode.minimal(typeName: "P")
        let node2 = SANode.minimal(typeName: "H1")

        let saPage = SAPage(
            page: page,
            nodes: [node1, node2]
        )

        #expect(saPage.nodes.count == 2)
        #expect(saPage.pageNumber == 2)
    }

    // MARK: - SAObject Conformance Tests

    @Test("saObjectType is SAPage")
    func saObjectType() {
        let saPage = SAPage.minimal()
        #expect(saPage.saObjectType == "SAPage")
    }

    @Test("validationContext is SA page context with page number")
    func validationContextTest() {
        let saPage = SAPage.minimal(pageNumber: 5)
        #expect(saPage.validationContext.location == "SAPage")
        #expect(saPage.validationContext.pageNumber == 5)
    }

    @Test("accessibilityPropertyNames includes all expected names")
    func propertyNamesComplete() {
        let saPage = SAPage.minimal()
        let names = saPage.accessibilityPropertyNames
        #expect(names.contains("pageNumber"))
        #expect(names.contains("hasContentStreams"))
        #expect(names.contains("hasAnnotations"))
        #expect(names.contains("annotationCount"))
        #expect(names.contains("hasResources"))
        #expect(names.contains("rotation"))
        #expect(names.contains("mediaBoxWidth"))
        #expect(names.contains("mediaBoxHeight"))
        #expect(names.contains("nodeCount"))
        #expect(names.contains("hasNodes"))
        #expect(names.contains("hasTransparencyGroup"))
    }

    // MARK: - Accessibility Property Access Tests

    @Test("accessibilityProperty returns pageNumber")
    func propertyPageNumber() {
        let saPage = SAPage.minimal(pageNumber: 3)
        #expect(saPage.accessibilityProperty(named: "pageNumber") == .integer(3))
    }

    @Test("accessibilityProperty returns hasContentStreams")
    func propertyHasContentStreams() {
        let page = ValidatedPage(pageNumber: 1, hasContentStreams: true)
        let saPage = SAPage(page: page)
        #expect(saPage.accessibilityProperty(named: "hasContentStreams") == .boolean(true))

        let noContent = SAPage.minimal()
        #expect(noContent.accessibilityProperty(named: "hasContentStreams") == .boolean(false))
    }

    @Test("accessibilityProperty returns hasAnnotations")
    func propertyHasAnnotations() {
        let page = ValidatedPage(pageNumber: 1, hasAnnotations: true, annotationCount: 5)
        let saPage = SAPage(page: page)
        #expect(saPage.accessibilityProperty(named: "hasAnnotations") == .boolean(true))
        #expect(saPage.accessibilityProperty(named: "annotationCount") == .integer(5))
    }

    @Test("accessibilityProperty returns rotation")
    func propertyRotation() {
        let page = ValidatedPage(pageNumber: 1, rotation: 90)
        let saPage = SAPage(page: page)
        #expect(saPage.accessibilityProperty(named: "rotation") == .integer(90))
    }

    @Test("accessibilityProperty returns media box dimensions")
    func propertyMediaBox() {
        let page = ValidatedPage(pageNumber: 1, mediaBox: .letter)
        let saPage = SAPage(page: page)

        let width = saPage.accessibilityProperty(named: "mediaBoxWidth")
        let height = saPage.accessibilityProperty(named: "mediaBoxHeight")

        #expect(width == .real(PDFRect.letter.width))
        #expect(height == .real(PDFRect.letter.height))
    }

    @Test("accessibilityProperty returns nodeCount and hasNodes")
    func propertyNodeCount() {
        let withNodes = SAPage.minimal(
            pageNumber: 1,
            nodes: [SANode.minimal(typeName: "P")]
        )
        #expect(withNodes.accessibilityProperty(named: "nodeCount") == .integer(1))
        #expect(withNodes.accessibilityProperty(named: "hasNodes") == .boolean(true))

        let noNodes = SAPage.minimal()
        #expect(noNodes.accessibilityProperty(named: "nodeCount") == .integer(0))
        #expect(noNodes.accessibilityProperty(named: "hasNodes") == .boolean(false))
    }

    @Test("accessibilityProperty returns hasTransparencyGroup")
    func propertyTransparency() {
        let page = ValidatedPage(pageNumber: 1, hasTransparencyGroup: true)
        let saPage = SAPage(page: page)
        #expect(saPage.accessibilityProperty(named: "hasTransparencyGroup") == .boolean(true))
    }

    @Test("accessibilityProperty returns nil for unknown property")
    func propertyUnknown() {
        let saPage = SAPage.minimal()
        #expect(saPage.accessibilityProperty(named: "nonexistent") == nil)
    }

    // MARK: - Computed Properties Tests

    @Test("pageNumber computed property")
    func pageNumberComputed() {
        let saPage = SAPage.minimal(pageNumber: 7)
        #expect(saPage.pageNumber == 7)
    }

    @Test("hasContent computed property")
    func hasContentComputed() {
        let page = ValidatedPage(pageNumber: 1, hasContentStreams: true)
        let saPage = SAPage(page: page)
        #expect(saPage.hasContent == true)

        let noContent = SAPage.minimal()
        #expect(noContent.hasContent == false)
    }

    @Test("hasAnnotations computed property")
    func hasAnnotationsComputed() {
        let page = ValidatedPage(pageNumber: 1, hasAnnotations: true, annotationCount: 3)
        let saPage = SAPage(page: page)
        #expect(saPage.hasAnnotations == true)
        #expect(saPage.annotationCount == 3)
    }

    @Test("nodeCount and hasNodes computed properties")
    func nodeCountComputed() {
        let nodes = [SANode.minimal(typeName: "P"), SANode.minimal(typeName: "H1")]
        let saPage = SAPage.minimal(pageNumber: 1, nodes: nodes)
        #expect(saPage.nodeCount == 2)
        #expect(saPage.hasNodes == true)

        let empty = SAPage.minimal()
        #expect(empty.nodeCount == 0)
        #expect(empty.hasNodes == false)
    }

    @Test("effectiveWidth and effectiveHeight computed properties")
    func effectiveDimensions() {
        let page = ValidatedPage(pageNumber: 1, mediaBox: .letter)
        let saPage = SAPage(page: page)
        #expect(saPage.effectiveWidth == PDFRect.letter.width)
        #expect(saPage.effectiveHeight == PDFRect.letter.height)
    }

    @Test("summary computed property")
    func summaryTest() {
        let nodes = [SANode.minimal(typeName: "P")]
        let page = ValidatedPage(
            pageNumber: 3,
            mediaBox: .letter,
            hasAnnotations: true,
            annotationCount: 2
        )
        let saPage = SAPage(page: page, nodes: nodes)
        let summary = saPage.summary
        #expect(summary.contains("SAPage 3"))
        #expect(summary.contains("annots"))
        #expect(summary.contains("1 nodes"))
    }

    // MARK: - Factory Methods Tests

    @Test("minimal factory creates basic page")
    func factoryMinimal() {
        let saPage = SAPage.minimal(pageNumber: 4)
        #expect(saPage.pageNumber == 4)
        #expect(saPage.nodes.isEmpty)
    }

    @Test("minimal factory with nodes")
    func factoryMinimalWithNodes() {
        let nodes = [SANode.minimal(typeName: "P"), SANode.minimal(typeName: "Figure")]
        let saPage = SAPage.minimal(pageNumber: 1, nodes: nodes)
        #expect(saPage.nodeCount == 2)
    }

    // MARK: - Equatable Tests

    @Test("Equal SAPages have same id")
    func equatable() {
        let page = ValidatedPage.minimal()
        let id = UUID()
        let saPage1 = SAPage(id: id, page: page)
        let saPage2 = SAPage(id: id, page: page)
        #expect(saPage1 == saPage2)
    }

    @Test("Different SAPages have different ids")
    func notEqual() {
        let page = ValidatedPage.minimal()
        let saPage1 = SAPage(page: page)
        let saPage2 = SAPage(page: page)
        #expect(saPage1 != saPage2)
    }
}
