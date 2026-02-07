import Testing
import Foundation
@testable import SwiftVerificarValidation
@testable import SwiftVerificarValidationProfiles

// MARK: - PDF/UA Conformance Tests

@Suite("PDF/UA Conformance")
struct PDFUAConformanceTests {

    @Test("PDF/UA Part enumeration")
    func pdfuaPart() {
        #expect(PDFUAPart.part1.rawValue == "1")
        #expect(PDFUAPart.part2.rawValue == "2")

        // Check descriptions
        #expect(PDFUAPart.part1.description.contains("ISO 14289-1:2014"))
        #expect(PDFUAPart.part2.description.contains("ISO 14289-2:2024"))

        // Check ISO references
        #expect(PDFUAPart.part1.isoReference == "ISO 14289-1:2014")
        #expect(PDFUAPart.part2.isoReference == "ISO 14289-2:2024")

        // Check base PDF versions
        #expect(PDFUAPart.part1.basePDFVersion == "1.4")
        #expect(PDFUAPart.part2.basePDFVersion == "2.0")
    }

    @Test("PDF/UA-1 conformance")
    func pdfua1Conformance() {
        let pdfua1 = PDFUAConformance(part: .part1)
        #expect(pdfua1.part == .part1)
        #expect(pdfua1.profileId == "1")
        #expect(pdfua1.identifier == "PDF/UA-1")
        #expect(pdfua1.isoReference == "ISO 14289-1:2014")
    }

    @Test("PDF/UA-2 conformance")
    func pdfua2Conformance() {
        let pdfua2 = PDFUAConformance(part: .part2)
        #expect(pdfua2.part == .part2)
        #expect(pdfua2.profileId == "2")
        #expect(pdfua2.identifier == "PDF/UA-2")
        #expect(pdfua2.isoReference == "ISO 14289-2:2024")
    }

    @Test("Predefined conformances")
    func predefinedConformances() {
        #expect(PDFUAConformance.pdfua1.identifier == "PDF/UA-1")
        #expect(PDFUAConformance.pdfua2.identifier == "PDF/UA-2")
    }

    @Test("Conformance equality")
    func conformanceEquality() {
        let pdfua1a = PDFUAConformance(part: .part1)
        let pdfua1b = PDFUAConformance(part: .part1)
        let pdfua2 = PDFUAConformance(part: .part2)

        #expect(pdfua1a == pdfua1b)
        #expect(pdfua1a != pdfua2)
    }

    @Test("Conformance hashability")
    func conformanceHashability() {
        let pdfua1 = PDFUAConformance.pdfua1
        let pdfua2 = PDFUAConformance.pdfua2

        var set = Set<PDFUAConformance>()
        set.insert(pdfua1)
        set.insert(pdfua2)

        #expect(set.count == 2)
        #expect(set.contains(pdfua1))
        #expect(set.contains(pdfua2))
    }

    @Test("Conformance codability")
    func conformanceCodability() throws {
        let original = PDFUAConformance.pdfua2
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(PDFUAConformance.self, from: data)

        #expect(decoded == original)
        #expect(decoded.identifier == "PDF/UA-2")
    }
}

// MARK: - PDF/UA Issue Category Tests

@Suite("PDF/UA Issue Categories")
struct PDFUAIssueCategoryTests {

    @Test("All issue categories")
    func allCategories() {
        let categories: [PDFUAIssueCategory] = [
            .documentMetadata,
            .taggedStructure,
            .readingOrder,
            .alternativeText,
            .languageSpecification,
            .navigationAids,
            .tableStructure,
            .listStructure,
            .headings,
            .annotations,
            .formFields,
            .embeddedFiles,
            .multimedia,
            .security,
            .fonts,
            .colorAndContrast,
            .semanticStructure
        ]

        #expect(categories.count == 17)

        // Check raw values are descriptive
        #expect(PDFUAIssueCategory.documentMetadata.rawValue == "Document Metadata")
        #expect(PDFUAIssueCategory.taggedStructure.rawValue == "Tagged Structure")
        #expect(PDFUAIssueCategory.alternativeText.rawValue == "Alternative Text")
    }

    @Test("Category codability")
    func categoryCodability() throws {
        let category = PDFUAIssueCategory.taggedStructure
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(category)
        let decoded = try decoder.decode(PDFUAIssueCategory.self, from: data)

        #expect(decoded == category)
    }
}

// MARK: - PDF/UA Issue Tests

@Suite("PDF/UA Issues")
struct PDFUAIssueTests {

    @Test("Issue creation")
    func issueCreation() {
        let issue = PDFUAIssue(
            category: .taggedStructure,
            description: "Missing structure tree",
            location: "Page 1",
            severity: .error,
            ruleId: "7.1",
            wcagCriterion: "1.3.1"
        )

        #expect(issue.category == .taggedStructure)
        #expect(issue.description == "Missing structure tree")
        #expect(issue.location == "Page 1")
        #expect(issue.severity == .error)
        #expect(issue.ruleId == "7.1")
        #expect(issue.wcagCriterion == "1.3.1")
    }

    @Test("Issue severity levels")
    func issueSeverity() {
        let error = PDFUAIssue.IssueSeverity.error
        let warning = PDFUAIssue.IssueSeverity.warning
        let info = PDFUAIssue.IssueSeverity.info

        #expect(error.rawValue == "error")
        #expect(warning.rawValue == "warning")
        #expect(info.rawValue == "info")
    }

    @Test("Issue default values")
    func issueDefaults() {
        let issue = PDFUAIssue(
            category: .alternativeText,
            description: "Missing alt text"
        )

        #expect(issue.location == nil)
        #expect(issue.severity == .error)
        #expect(issue.ruleId == nil)
        #expect(issue.wcagCriterion == nil)
    }

    @Test("Issue identifiable")
    func issueIdentifiable() {
        let issue1 = PDFUAIssue(
            category: .taggedStructure,
            description: "Issue 1"
        )
        let issue2 = PDFUAIssue(
            category: .taggedStructure,
            description: "Issue 2"
        )

        #expect(issue1.id != issue2.id)
    }
}

// MARK: - Accessibility Features Tests

@Suite("Accessibility Features")
struct AccessibilityFeaturesTests {

    @Test("Default features")
    func defaultFeatures() {
        let features = AccessibilityFeatures()

        #expect(features.hasStructureTree == false)
        #expect(features.hasMarkedContent == false)
        #expect(features.hasLanguageSpecification == false)
        #expect(features.hasAlternativeText == false)
        #expect(features.hasAccessibleForms == false)
        #expect(features.hasAccessibleTables == false)
        #expect(features.hasLogicalReadingOrder == false)
        #expect(features.hasNavigationAids == false)
        #expect(features.headingCount == 0)
        #expect(features.tableCount == 0)
        #expect(features.listCount == 0)
        #expect(features.formFieldCount == 0)
        #expect(features.annotationCount == 0)
    }

    @Test("Modified features")
    func modifiedFeatures() {
        var features = AccessibilityFeatures()
        features.hasStructureTree = true
        features.hasLanguageSpecification = true
        features.headingCount = 5
        features.tableCount = 2

        #expect(features.hasStructureTree == true)
        #expect(features.hasLanguageSpecification == true)
        #expect(features.headingCount == 5)
        #expect(features.tableCount == 2)
    }
}

// MARK: - PDF/UA Validation Result Tests

@Suite("PDF/UA Validation Result")
struct PDFUAValidationResultTests {

    @Test("Compliant result")
    func compliantResult() {
        let baseResult = ValidationResult(
            isCompliant: true,
            profileName: "PDF/UA-1",
            totalRules: 10,
            passedRules: 10,
            failedRules: 0,
            ruleResults: [],
            duration: 0.5
        )

        let result = PDFUAValidationResult(
            validationResult: baseResult,
            conformance: PDFUAConformance.pdfua1,
            claimedConformance: PDFUAConformance.pdfua1,
            pdfuaIssues: [],
            accessibilityFeatures: AccessibilityFeatures()
        )

        #expect(result.isCompliant == true)
        #expect(result.conformance == PDFUAConformance.pdfua1)
        #expect(result.claimedConformance == PDFUAConformance.pdfua1)
        #expect(result.conformanceMatches == true)
        #expect(result.pdfuaIssues.isEmpty)
    }

    @Test("Non-compliant result")
    func nonCompliantResult() {
        let baseResult = ValidationResult(
            isCompliant: false,
            profileName: "PDF/UA-1",
            totalRules: 10,
            passedRules: 8,
            failedRules: 2,
            ruleResults: [],
            duration: 0.5
        )

        let issues = [
            PDFUAIssue(
                category: .taggedStructure,
                description: "Missing structure tree",
                severity: .error
            ),
            PDFUAIssue(
                category: .alternativeText,
                description: "Missing alt text",
                severity: .error
            )
        ]

        let result = PDFUAValidationResult(
            validationResult: baseResult,
            conformance: PDFUAConformance.pdfua1,
            claimedConformance: nil,
            pdfuaIssues: issues,
            accessibilityFeatures: AccessibilityFeatures()
        )

        #expect(result.isCompliant == false)
        #expect(result.conformance == PDFUAConformance.pdfua1)
        #expect(result.claimedConformance == nil)
        #expect(result.conformanceMatches == false)
        #expect(result.pdfuaIssues.count == 2)
    }

    @Test("Conformance mismatch")
    func conformanceMismatch() {
        let baseResult = ValidationResult(
            isCompliant: true,
            profileName: "PDF/UA-2",
            totalRules: 10,
            passedRules: 10,
            failedRules: 0,
            ruleResults: [],
            duration: 0.5
        )

        let result = PDFUAValidationResult(
            validationResult: baseResult,
            conformance: PDFUAConformance.pdfua2,
            claimedConformance: PDFUAConformance.pdfua1, // Claimed PDF/UA-1 but validated as PDF/UA-2
            pdfuaIssues: [],
            accessibilityFeatures: AccessibilityFeatures()
        )

        #expect(result.conformanceMatches == false)
        #expect(result.conformance == PDFUAConformance.pdfua2)
        #expect(result.claimedConformance == PDFUAConformance.pdfua1)
    }

    @Test("Result with accessibility features")
    func resultWithFeatures() {
        var features = AccessibilityFeatures()
        features.hasStructureTree = true
        features.hasLanguageSpecification = true
        features.hasAlternativeText = true
        features.headingCount = 10
        features.tableCount = 3

        let baseResult = ValidationResult(
            isCompliant: true,
            profileName: "PDF/UA-2",
            totalRules: 10,
            passedRules: 10,
            failedRules: 0,
            ruleResults: [],
            duration: 0.5
        )

        let result = PDFUAValidationResult(
            validationResult: baseResult,
            conformance: PDFUAConformance.pdfua2,
            claimedConformance: PDFUAConformance.pdfua2,
            pdfuaIssues: [],
            accessibilityFeatures: features
        )

        #expect(result.accessibilityFeatures.hasStructureTree == true)
        #expect(result.accessibilityFeatures.headingCount == 10)
        #expect(result.accessibilityFeatures.tableCount == 3)
    }
}
