import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - SADocument Tests

@Suite("SADocument")
struct SADocumentTests {

    // MARK: - Initialization Tests

    @Test("Default initialization with validated document")
    func defaultInit() {
        let doc = ValidatedDocument.minimal()
        let saDoc = SADocument(document: doc)

        #expect(saDoc.document == doc)
        #expect(saDoc.pages.isEmpty)
        #expect(saDoc.structureRoot == nil)
    }

    @Test("Full initialization with pages and structure root")
    func fullInit() {
        let doc = ValidatedDocument.minimal(
            pdfVersion: "2.0",
            pageCount: 2,
            isTagged: true,
            language: "en"
        )
        let page1 = SAPage.minimal(pageNumber: 1)
        let page2 = SAPage.minimal(pageNumber: 2)
        let root = SAStructureRoot.minimal()

        let saDoc = SADocument(
            document: doc,
            pages: [page1, page2],
            structureRoot: root
        )

        #expect(saDoc.pages.count == 2)
        #expect(saDoc.structureRoot != nil)
        #expect(saDoc.pdfVersion == "2.0")
        #expect(saDoc.pageCount == 2)
    }

    // MARK: - SAObject Conformance Tests

    @Test("saObjectType is SADocument")
    func saObjectType() {
        let saDoc = SADocument.minimal()
        #expect(saDoc.saObjectType == "SADocument")
    }

    @Test("validationContext is SA document context")
    func validationContextTest() {
        let saDoc = SADocument.minimal()
        #expect(saDoc.validationContext.location == "SADocument")
    }

    @Test("accessibilityPropertyNames includes all expected names")
    func propertyNamesComplete() {
        let saDoc = SADocument.minimal()
        let names = saDoc.accessibilityPropertyNames
        #expect(names.contains("language"))
        #expect(names.contains("isTagged"))
        #expect(names.contains("isMarked"))
        #expect(names.contains("hasStructTreeRoot"))
        #expect(names.contains("pdfVersion"))
        #expect(names.contains("pageCount"))
        #expect(names.contains("hasMetadata"))
        #expect(names.contains("hasOutlines"))
        #expect(names.contains("hasSuspects"))
        #expect(names.contains("isAccessible"))
        #expect(names.contains("structureElementCount"))
        #expect(names.contains("hasLanguage"))
        #expect(names.contains("hasStructureRoot"))
    }

    // MARK: - Accessibility Property Access Tests

    @Test("accessibilityProperty returns language")
    func propertyLanguage() {
        let saDoc = SADocument.minimal(language: "en-US")
        #expect(saDoc.accessibilityProperty(named: "language") == .string("en-US"))
    }

    @Test("accessibilityProperty returns null for missing language")
    func propertyLanguageNull() {
        let saDoc = SADocument.minimal()
        #expect(saDoc.accessibilityProperty(named: "language") == .null)
    }

    @Test("accessibilityProperty returns isTagged")
    func propertyIsTagged() {
        let tagged = SADocument.minimal(isTagged: true)
        #expect(tagged.accessibilityProperty(named: "isTagged") == .boolean(true))

        let untagged = SADocument.minimal(isTagged: false)
        #expect(untagged.accessibilityProperty(named: "isTagged") == .boolean(false))
    }

    @Test("accessibilityProperty returns pdfVersion")
    func propertyPdfVersion() {
        let saDoc = SADocument.minimal(pdfVersion: "2.0")
        #expect(saDoc.accessibilityProperty(named: "pdfVersion") == .string("2.0"))
    }

    @Test("accessibilityProperty returns pageCount")
    func propertyPageCount() {
        let saDoc = SADocument.minimal(pageCount: 5)
        #expect(saDoc.accessibilityProperty(named: "pageCount") == .integer(5))
    }

    @Test("accessibilityProperty returns hasStructureRoot")
    func propertyHasStructureRoot() {
        let withRoot = SADocument.accessible()
        #expect(withRoot.accessibilityProperty(named: "hasStructureRoot") == .boolean(true))

        let withoutRoot = SADocument.minimal()
        #expect(withoutRoot.accessibilityProperty(named: "hasStructureRoot") == .boolean(false))
    }

    @Test("accessibilityProperty returns nil for unknown property")
    func propertyUnknown() {
        let saDoc = SADocument.minimal()
        #expect(saDoc.accessibilityProperty(named: "nonexistent") == nil)
    }

    @Test("accessibilityProperty returns hasLanguage")
    func propertyHasLanguage() {
        let withLang = SADocument.minimal(language: "fr")
        #expect(withLang.accessibilityProperty(named: "hasLanguage") == .boolean(true))

        let withoutLang = SADocument.minimal()
        #expect(withoutLang.accessibilityProperty(named: "hasLanguage") == .boolean(false))
    }

    @Test("accessibilityProperty returns isAccessible")
    func propertyIsAccessible() {
        let accessible = SADocument.minimal(isTagged: true, language: "en")
        #expect(accessible.accessibilityProperty(named: "isAccessible") == .boolean(true))
    }

    @Test("accessibilityProperty returns hasSuspects")
    func propertyHasSuspects() {
        let saDoc = SADocument.minimal()
        #expect(saDoc.accessibilityProperty(named: "hasSuspects") == .boolean(false))
    }

    // MARK: - Computed Properties Tests

    @Test("hasLanguage computed property")
    func hasLanguageComputed() {
        let withLang = SADocument.minimal(language: "en")
        #expect(withLang.hasLanguage == true)

        let withoutLang = SADocument.minimal()
        #expect(withoutLang.hasLanguage == false)
    }

    @Test("language computed property")
    func languageComputed() {
        let saDoc = SADocument.minimal(language: "de-DE")
        #expect(saDoc.language == "de-DE")

        let noLang = SADocument.minimal()
        #expect(noLang.language == nil)
    }

    @Test("isTagged computed property")
    func isTaggedComputed() {
        let tagged = SADocument.minimal(isTagged: true)
        #expect(tagged.isTagged == true)

        let untagged = SADocument.minimal()
        #expect(untagged.isTagged == false)
    }

    @Test("hasStructureRoot computed property")
    func hasStructureRootComputed() {
        let withRoot = SADocument.accessible()
        #expect(withRoot.hasStructureRoot == true)

        let withoutRoot = SADocument.minimal()
        #expect(withoutRoot.hasStructureRoot == false)
    }

    @Test("meetsBasicAccessibility computed property")
    func meetsBasicAccessibility() {
        let accessible = SADocument.accessible(language: "en")
        #expect(accessible.meetsBasicAccessibility == true)

        let untagged = SADocument.minimal(language: "en")
        #expect(untagged.meetsBasicAccessibility == false)

        let noLang = SADocument.minimal(isTagged: true)
        #expect(noLang.meetsBasicAccessibility == false)

        let noRoot = SADocument.minimal(isTagged: true, language: "en")
        #expect(noRoot.meetsBasicAccessibility == false)
    }

    @Test("saPageCount computed property")
    func saPageCount() {
        let saDoc = SADocument(
            document: ValidatedDocument.minimal(pageCount: 3),
            pages: [SAPage.minimal(pageNumber: 1), SAPage.minimal(pageNumber: 2)]
        )
        #expect(saDoc.saPageCount == 2)
    }

    @Test("summary computed property")
    func summaryTest() {
        let saDoc = SADocument.accessible(pdfVersion: "2.0", language: "en")
        let summary = saDoc.summary
        #expect(summary.contains("SADocument"))
        #expect(summary.contains("PDF 2.0"))
        #expect(summary.contains("tagged"))
        #expect(summary.contains("lang=en"))
        #expect(summary.contains("structured"))
    }

    // MARK: - Factory Methods Tests

    @Test("minimal factory creates basic document")
    func factoryMinimal() {
        let saDoc = SADocument.minimal(pdfVersion: "1.4", pageCount: 3)
        #expect(saDoc.pdfVersion == "1.4")
        #expect(saDoc.pageCount == 3)
        #expect(saDoc.isTagged == false)
        #expect(saDoc.pages.isEmpty)
        #expect(saDoc.structureRoot == nil)
    }

    @Test("accessible factory creates tagged document with root")
    func factoryAccessible() {
        let saDoc = SADocument.accessible(pdfVersion: "2.0", language: "fr")
        #expect(saDoc.pdfVersion == "2.0")
        #expect(saDoc.isTagged == true)
        #expect(saDoc.language == "fr")
        #expect(saDoc.structureRoot != nil)
    }

    // MARK: - Equatable Tests

    @Test("Equal SADocuments have same id")
    func equatable() {
        let doc = ValidatedDocument.minimal()
        let id = UUID()
        let saDoc1 = SADocument(id: id, document: doc)
        let saDoc2 = SADocument(id: id, document: doc)
        #expect(saDoc1 == saDoc2)
    }

    @Test("Different SADocuments have different ids")
    func notEqual() {
        let doc = ValidatedDocument.minimal()
        let saDoc1 = SADocument(document: doc)
        let saDoc2 = SADocument(document: doc)
        #expect(saDoc1 != saDoc2)
    }
}
