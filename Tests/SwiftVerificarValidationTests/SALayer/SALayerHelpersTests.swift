import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - SAAccessibilitySummary Tests

@Suite("SAAccessibilitySummary")
struct SAAccessibilitySummaryTests {

    @Test("Default summary has all zeroes")
    func defaultSummary() {
        let summary = SAAccessibilitySummary()
        #expect(summary.totalElements == 0)
        #expect(summary.headingCount == 0)
        #expect(summary.figureCount == 0)
        #expect(summary.tableCount == 0)
        #expect(summary.listCount == 0)
        #expect(summary.linkCount == 0)
        #expect(summary.elementsWithAltText == 0)
        #expect(summary.elementsWithActualText == 0)
        #expect(summary.elementsWithLanguage == 0)
        #expect(summary.missingAltTextCount == 0)
        #expect(summary.accessibilityIssueCount == 0)
        #expect(summary.maxHeadingLevel == nil)
        #expect(summary.minHeadingLevel == nil)
        #expect(summary.maxDepth == 0)
        #expect(summary.artifactCount == 0)
    }

    @Test("Compliance ratio is 1.0 for empty summary")
    func emptyComplianceRatio() {
        let summary = SAAccessibilitySummary()
        #expect(summary.complianceRatio == 1.0)
    }

    @Test("Compliance ratio calculated correctly")
    func complianceRatioCalculation() {
        let summary = SAAccessibilitySummary(
            totalElements: 10,
            accessibilityIssueCount: 2,
            artifactCount: 0
        )
        #expect(summary.complianceRatio == 0.8)
    }

    @Test("Compliance ratio excludes artifacts")
    func complianceRatioExcludesArtifacts() {
        let summary = SAAccessibilitySummary(
            totalElements: 10,
            accessibilityIssueCount: 1,
            artifactCount: 5
        )
        // Relevant = 10 - 5 = 5, issues = 1, ratio = 4/5 = 0.8
        #expect(summary.complianceRatio == 0.8)
    }

    @Test("Compliance ratio is 1.0 when all elements are artifacts")
    func complianceAllArtifacts() {
        let summary = SAAccessibilitySummary(
            totalElements: 5,
            accessibilityIssueCount: 0,
            artifactCount: 5
        )
        #expect(summary.complianceRatio == 1.0)
    }

    @Test("Summary is Codable")
    func summaryCodable() throws {
        let summary = SAAccessibilitySummary(
            totalElements: 15,
            headingCount: 3,
            figureCount: 2,
            tableCount: 1,
            listCount: 1,
            linkCount: 4,
            elementsWithAltText: 2,
            elementsWithActualText: 1,
            elementsWithLanguage: 12,
            missingAltTextCount: 0,
            accessibilityIssueCount: 1,
            maxHeadingLevel: 3,
            minHeadingLevel: 1,
            maxDepth: 4,
            artifactCount: 2
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(summary)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SAAccessibilitySummary.self, from: data)
        #expect(decoded == summary)
    }

    @Test("Summary is Equatable")
    func summaryEquatable() {
        let a = SAAccessibilitySummary(totalElements: 5, headingCount: 2)
        let b = SAAccessibilitySummary(totalElements: 5, headingCount: 2)
        #expect(a == b)

        let c = SAAccessibilitySummary(totalElements: 5, headingCount: 3)
        #expect(a != c)
    }
}

// MARK: - SADocument Accessibility Summary Tests

@Suite("SADocument accessibilitySummary")
struct SADocumentAccessibilitySummaryTests {

    @Test("Document without structure root returns empty summary")
    func documentWithoutRoot() {
        let doc = SADocument.minimal()
        let summary = doc.accessibilitySummary()
        #expect(summary.totalElements == 0)
        #expect(summary.headingCount == 0)
    }

    @Test("Document with structure root computes summary")
    func documentWithRoot() {
        let h1 = SANode.heading(level: 1, language: "en")
        let h2 = SANode.heading(level: 2, language: "en")
        let fig = SANode.figure(altText: "Photo")
        let para = SANode.paragraph(language: "en")
        let root = SAStructureRoot.minimal(children: [h1, h2, fig, para])
        let doc = SADocument(
            document: ValidatedDocument.minimal(isTagged: true, language: "en"),
            structureRoot: root
        )
        let summary = doc.accessibilitySummary()
        #expect(summary.totalElements == 4)
        #expect(summary.headingCount == 2)
        #expect(summary.figureCount == 1)
        #expect(summary.maxHeadingLevel == 2)
        #expect(summary.minHeadingLevel == 1)
    }

    @Test("Summary counts missing alt text")
    func summaryMissingAltText() {
        let figWithAlt = SANode.figure(altText: "Description")
        let figWithoutAlt = SANode.figure(altText: nil)
        let root = SAStructureRoot.minimal(children: [figWithAlt, figWithoutAlt])
        let doc = SADocument(
            document: ValidatedDocument.minimal(isTagged: true),
            structureRoot: root
        )
        let summary = doc.accessibilitySummary()
        #expect(summary.missingAltTextCount == 1)
        #expect(summary.elementsWithAltText == 1)
    }
}

// MARK: - SAStructureElement Accessibility Summary Tests

@Suite("SAStructureElement accessibilitySummary")
struct SAStructureElementAccessibilitySummaryTests {

    @Test("Element summary includes self and descendants")
    func elementSummaryIncludesSelf() {
        let child1 = SAStructureElement.heading(level: 1)
        let child2 = SAStructureElement.paragraph(language: "en")
        let parent = SAStructureElement.minimal(
            typeName: "Sect",
            children: [child1, child2]
        )
        let summary = parent.accessibilitySummary()
        #expect(summary.totalElements == 3) // parent + 2 children
        #expect(summary.headingCount == 1)
    }

    @Test("Element summary counts figures needing alt text")
    func elementSummaryFigures() {
        let figWithAlt = SAStructureElement.figure(altText: "Photo")
        let figWithoutAlt = SAStructureElement.figure(altText: nil)
        let parent = SAStructureElement.minimal(
            typeName: "Div",
            children: [figWithAlt, figWithoutAlt]
        )
        let summary = parent.accessibilitySummary()
        #expect(summary.figureCount == 2)
        #expect(summary.missingAltTextCount == 1)
    }
}

// MARK: - SATreeBuilder Tests

@Suite("SATreeBuilder")
struct SATreeBuilderTests {

    @Test("Builder creates instance")
    func builderCreates() {
        let builder = SATreeBuilder()
        let builder2 = SATreeBuilder()
        #expect(builder == builder2) // Sendable, Equatable
    }

    @Test("Build document from validated document")
    func buildDocument() {
        let builder = SATreeBuilder()
        let validatedDoc = ValidatedDocument.minimal(pdfVersion: "2.0", pageCount: 2, isTagged: true, language: "en")
        let saDoc = builder.buildDocument(from: validatedDoc)
        #expect(saDoc.pdfVersion == "2.0")
        #expect(saDoc.language == "en")
        #expect(saDoc.structureRoot == nil)
    }

    @Test("Build document with structure tree root")
    func buildDocumentWithRoot() {
        let builder = SATreeBuilder()
        let validatedDoc = ValidatedDocument.minimal(isTagged: true, language: "en")
        let root = ValidatedStructTreeRoot.minimal()
        let saDoc = builder.buildDocument(from: validatedDoc, structTreeRoot: root)
        #expect(saDoc.structureRoot != nil)
        #expect(saDoc.hasStructureRoot)
    }

    @Test("Build document with structure elements creates nodes")
    func buildDocumentWithElems() {
        let builder = SATreeBuilder()
        let validatedDoc = ValidatedDocument.minimal(isTagged: true, language: "en")
        let root = ValidatedStructTreeRoot.minimal()
        let elem = ValidatedStructElem.minimal(typeName: "P")
        let saDoc = builder.buildDocument(
            from: validatedDoc,
            structTreeRoot: root,
            structElems: [elem]
        )
        #expect(saDoc.structureRoot?.childCount == 1)
    }

    @Test("Build node from validated struct elem")
    func buildNode() {
        let builder = SATreeBuilder()
        let childElem = ValidatedStructElem.minimal(typeName: "Span")
        let elem = ValidatedStructElem(
            structureTypeName: "P",
            children: [childElem],
            language: "en"
        )
        let node = builder.buildNode(from: elem, inheritedLanguage: "fr")
        #expect(node.structureTypeName == "P")
        #expect(node.language == "en")
        #expect(node.inheritedLanguage == "fr")
        #expect(node.effectiveLanguage == "en") // own language takes priority
        #expect(node.childCount == 1)
        #expect(node.children[0].structureTypeName == "Span")
        // Child inherits parent language
        #expect(node.children[0].inheritedLanguage == "en")
    }

    @Test("Build structure element from validated structure element")
    func buildStructureElement() {
        let builder = SATreeBuilder()
        let childValidated = ValidatedStructureElement.minimal(typeName: "Span")
        let validated = ValidatedStructureElement(
            originalTypeName: "P",
            children: [childValidated],
            effectiveLanguage: "en"
        )
        let saElem = builder.buildStructureElement(from: validated)
        #expect(saElem.resolvedTypeName == "P")
        #expect(saElem.effectiveLanguage == "en")
        #expect(saElem.childCount == 1)
        #expect(saElem.children[0].resolvedTypeName == "Span")
    }

    @Test("Build node inherits language down the tree")
    func buildNodeLanguageInheritance() {
        let builder = SATreeBuilder()
        let grandchild = ValidatedStructElem.minimal(typeName: "Span")
        let child = ValidatedStructElem(
            structureTypeName: "P",
            children: [grandchild]
        )
        let root = ValidatedStructElem(
            structureTypeName: "Sect",
            children: [child],
            language: "de"
        )
        let node = builder.buildNode(from: root, inheritedLanguage: "en")

        // Root has own language "de"
        #expect(node.effectiveLanguage == "de")

        // Child inherits "de" from root
        let childNode = node.children[0]
        #expect(childNode.inheritedLanguage == "de")
        #expect(childNode.effectiveLanguage == "de")

        // Grandchild also inherits "de"
        let grandchildNode = childNode.children[0]
        #expect(grandchildNode.inheritedLanguage == "de")
    }
}

// MARK: - SAValidationReport Tests

@Suite("SAValidationReport")
struct SAValidationReportTests {

    @Test("Report counts issues correctly")
    func reportIssueCounts() {
        let docDTO = SADocumentDTO(
            id: "doc-1",
            saObjectType: "SADocument",
            pdfVersion: "2.0",
            pageCount: 1,
            isTagged: true,
            language: "en",
            hasStructureRoot: true,
            meetsBasicAccessibility: true,
            pages: [],
            structureRoot: nil
        )
        let summary = SAAccessibilitySummary(totalElements: 10)
        let issues = [
            WCAGIssueDTO(id: "1", severity: "Critical", category: "AlternativeText", message: "Missing alt", successCriterion: nil, pageNumber: nil, structureElementType: nil),
            WCAGIssueDTO(id: "2", severity: "Major", category: "Language", message: "Missing lang", successCriterion: nil, pageNumber: nil, structureElementType: nil),
            WCAGIssueDTO(id: "3", severity: "Minor", category: "Structure", message: "Minor issue", successCriterion: nil, pageNumber: nil, structureElementType: nil)
        ]
        let report = SAValidationReport(
            documentSummary: docDTO,
            accessibilitySummary: summary,
            issues: issues
        )
        #expect(report.issueCount == 3)
        #expect(report.criticalIssueCount == 1)
        #expect(report.majorIssueCount == 1)
        #expect(report.passesBasicAccessibility == false) // has critical issues
    }

    @Test("Report passes when no critical issues and basic accessibility met")
    func reportPassesBasicAccessibility() {
        let docDTO = SADocumentDTO(
            id: "doc-1",
            saObjectType: "SADocument",
            pdfVersion: "2.0",
            pageCount: 1,
            isTagged: true,
            language: "en",
            hasStructureRoot: true,
            meetsBasicAccessibility: true,
            pages: [],
            structureRoot: nil
        )
        let summary = SAAccessibilitySummary()
        let report = SAValidationReport(
            documentSummary: docDTO,
            accessibilitySummary: summary,
            issues: []
        )
        #expect(report.passesBasicAccessibility == true)
    }

    @Test("Report is Codable")
    func reportCodable() throws {
        let docDTO = SADocumentDTO(
            id: "doc-1",
            saObjectType: "SADocument",
            pdfVersion: "1.7",
            pageCount: 1,
            isTagged: false,
            language: nil,
            hasStructureRoot: false,
            meetsBasicAccessibility: false,
            pages: [],
            structureRoot: nil
        )
        let summary = SAAccessibilitySummary(totalElements: 5)
        let report = SAValidationReport(
            documentSummary: docDTO,
            accessibilitySummary: summary,
            issues: []
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(report)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SAValidationReport.self, from: data)
        #expect(decoded == report)
    }
}

// MARK: - SADocumentEncoder Report Generation Tests

@Suite("SADocumentEncoder Report Generation")
struct SADocumentEncoderReportGenerationTests {

    @Test("Generate report from SA document")
    func generateReport() {
        let encoder = SADocumentEncoder.default()
        let doc = SADocument.accessible(language: "en")
        let issues = [
            WCAGIssue(severity: .minor, category: .headingHierarchy, message: "Skipped heading level")
        ]
        let report = encoder.generateReport(for: doc, issues: issues)
        #expect(report.documentSummary.language == "en")
        #expect(report.issueCount == 1)
    }

    @Test("Encode report produces valid JSON")
    func encodeReport() throws {
        let encoder = SADocumentEncoder.default()
        let doc = SADocument.minimal()
        let data = try encoder.encodeReport(for: doc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["documentSummary"] != nil)
        #expect(json?["accessibilitySummary"] != nil)
        #expect(json?["issues"] != nil)
    }
}
