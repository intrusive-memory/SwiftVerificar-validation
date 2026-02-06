import Testing
import Foundation
@testable import SwiftVerificarValidation
@testable import SwiftVerificarValidationProfiles

// MARK: - PDF/A Conformance Tests

@Suite("PDF/A Conformance")
struct PDFAConformanceTests {

    @Test("PDF/A Part enumeration")
    func pdfaPart() {
        #expect(PDFAPart.part1.rawValue == "1")
        #expect(PDFAPart.part2.rawValue == "2")
        #expect(PDFAPart.part3.rawValue == "3")
        #expect(PDFAPart.part4.rawValue == "4")

        // Check descriptions
        #expect(PDFAPart.part1.description.contains("ISO 19005-1:2005"))
        #expect(PDFAPart.part2.description.contains("ISO 19005-2:2011"))
        #expect(PDFAPart.part3.description.contains("ISO 19005-3:2012"))
        #expect(PDFAPart.part4.description.contains("ISO 19005-4:2020"))
    }

    @Test("PDF/A Level enumeration")
    func pdfaLevel() {
        #expect(PDFALevel.a.rawValue == "A")
        #expect(PDFALevel.b.rawValue == "B")
        #expect(PDFALevel.u.rawValue == "U")

        // Check accessibility requirement
        #expect(PDFALevel.a.requiresAccessibility == true)
        #expect(PDFALevel.b.requiresAccessibility == false)
        #expect(PDFALevel.u.requiresAccessibility == false)

        // Check Unicode requirement
        #expect(PDFALevel.a.requiresUnicode == true)
        #expect(PDFALevel.b.requiresUnicode == false)
        #expect(PDFALevel.u.requiresUnicode == true)
    }

    @Test("PDF/A-1 conformance levels")
    func pdfa1Conformance() throws {
        let pdf1a = try PDFAConformance(part: .part1, level: .a)
        #expect(pdf1a.part == .part1)
        #expect(pdf1a.level == .a)
        #expect(pdf1a.profileId == "1a")
        #expect(pdf1a.identifier == "PDF/A-1a")

        let pdf1b = try PDFAConformance(part: .part1, level: .b)
        #expect(pdf1b.profileId == "1b")
        #expect(pdf1b.identifier == "PDF/A-1b")
    }

    @Test("PDF/A-1 invalid conformance")
    func pdfa1InvalidLevel() {
        #expect(throws: ValidationError.self) {
            try PDFAConformance(part: .part1, level: .u)
        }
    }

    @Test("PDF/A-2 conformance levels")
    func pdfa2Conformance() throws {
        let pdf2a = try PDFAConformance(part: .part2, level: .a)
        #expect(pdf2a.profileId == "2a")
        #expect(pdf2a.identifier == "PDF/A-2a")

        let pdf2b = try PDFAConformance(part: .part2, level: .b)
        #expect(pdf2b.profileId == "2b")

        let pdf2u = try PDFAConformance(part: .part2, level: .u)
        #expect(pdf2u.profileId == "2u")
        #expect(pdf2u.identifier == "PDF/A-2u")
    }

    @Test("PDF/A-3 conformance levels")
    func pdfa3Conformance() throws {
        let pdf3a = try PDFAConformance(part: .part3, level: .a)
        #expect(pdf3a.profileId == "3a")
        #expect(pdf3a.identifier == "PDF/A-3a")

        let pdf3b = try PDFAConformance(part: .part3, level: .b)
        #expect(pdf3b.profileId == "3b")

        let pdf3u = try PDFAConformance(part: .part3, level: .u)
        #expect(pdf3u.profileId == "3u")
    }

    @Test("PDF/A-4 conformance")
    func pdfa4Conformance() throws {
        // PDF/A-4 uses simplified conformance model
        let pdf4 = try PDFAConformance(part: .part4, level: .b)
        #expect(pdf4.profileId == "4b")
        #expect(pdf4.identifier == "PDF/A-4b")
    }

    @Test("Predefined conformances")
    func predefinedConformances() {
        #expect(PDFAConformance.pdf1a.identifier == "PDF/A-1a")
        #expect(PDFAConformance.pdf1b.identifier == "PDF/A-1b")
        #expect(PDFAConformance.pdf2a.identifier == "PDF/A-2a")
        #expect(PDFAConformance.pdf2b.identifier == "PDF/A-2b")
        #expect(PDFAConformance.pdf2u.identifier == "PDF/A-2u")
        #expect(PDFAConformance.pdf3a.identifier == "PDF/A-3a")
        #expect(PDFAConformance.pdf3b.identifier == "PDF/A-3b")
        #expect(PDFAConformance.pdf3u.identifier == "PDF/A-3u")
        #expect(PDFAConformance.pdf4.identifier == "PDF/A-4b")
    }

    @Test("Conformance equality")
    func conformanceEquality() throws {
        let conf1 = try PDFAConformance(part: .part1, level: .a)
        let conf2 = try PDFAConformance(part: .part1, level: .a)
        let conf3 = try PDFAConformance(part: .part1, level: .b)

        #expect(conf1 == conf2)
        #expect(conf1 != conf3)
    }

    @Test("Conformance Codable")
    func conformanceCodable() throws {
        let original = try PDFAConformance(part: .part2, level: .u)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PDFAConformance.self, from: data)

        #expect(decoded == original)
        #expect(decoded.profileId == "2u")
    }
}

// MARK: - PDF/A Issue Tests

@Suite("PDF/A Issue")
struct PDFAIssueTests {

    @Test("Issue creation")
    func issueCreation() {
        let issue = PDFAIssue(
            category: .fonts,
            description: "Font not embedded",
            location: "Page 1",
            severity: .error,
            ruleId: "6.3.3-1"
        )

        #expect(issue.category == .fonts)
        #expect(issue.description == "Font not embedded")
        #expect(issue.location == "Page 1")
        #expect(issue.severity == .error)
        #expect(issue.ruleId == "6.3.3-1")
    }

    @Test("Issue categories")
    func issueCategories() {
        let categories: [PDFAIssueCategory] = [
            .fileStructure,
            .graphics,
            .fonts,
            .transparency,
            .annotations,
            .actions,
            .metadata,
            .logicalStructure,
            .embeddedFiles,
            .colorSpaces,
            .encryption
        ]

        for category in categories {
            let issue = PDFAIssue(
                category: category,
                description: "Test issue"
            )
            #expect(issue.category == category)
        }
    }

    @Test("Issue severity levels")
    func issueSeverity() {
        let error = PDFAIssue(
            category: .fonts,
            description: "Critical error",
            severity: .error
        )
        #expect(error.severity == .error)

        let warning = PDFAIssue(
            category: .metadata,
            description: "Warning",
            severity: .warning
        )
        #expect(warning.severity == .warning)

        let info = PDFAIssue(
            category: .annotations,
            description: "Info",
            severity: .info
        )
        #expect(info.severity == .info)
    }

    @Test("Issue with optional fields")
    func issueOptionalFields() {
        let minimal = PDFAIssue(
            category: .graphics,
            description: "Simple issue"
        )

        #expect(minimal.location == nil)
        #expect(minimal.severity == .error) // Default severity
        #expect(minimal.ruleId == nil)
    }
}

// MARK: - PDF/A Validation Result Tests

@Suite("PDF/A Validation Result")
struct PDFAValidationResultTests {

    @Test("Validation result creation")
    func resultCreation() {
        let validationResult = ValidationResult(
            isCompliant: true,
            profileName: "PDF/A-1b",
            totalRules: 100,
            passedRules: 100,
            failedRules: 0,
            ruleResults: [],
            duration: 1.5
        )

        let pdfaResult = PDFAValidationResult(
            validationResult: validationResult,
            conformance: .pdf1b,
            claimedConformance: .pdf1b,
            pdfaIssues: []
        )

        #expect(pdfaResult.isCompliant == true)
        #expect(pdfaResult.conformance == .pdf1b)
        #expect(pdfaResult.claimedConformance == .pdf1b)
        #expect(pdfaResult.conformanceMatches == true)
        #expect(pdfaResult.pdfaIssues.isEmpty)
    }

    @Test("Conformance mismatch detection")
    func conformanceMismatch() {
        let validationResult = ValidationResult(
            isCompliant: false,
            profileName: "PDF/A-1b",
            totalRules: 100,
            passedRules: 95,
            failedRules: 5,
            ruleResults: [],
            duration: 1.5
        )

        let pdfaResult = PDFAValidationResult(
            validationResult: validationResult,
            conformance: .pdf1b,
            claimedConformance: .pdf1a,
            pdfaIssues: []
        )

        #expect(pdfaResult.conformanceMatches == false)
    }

    @Test("No claimed conformance")
    func noClaimedConformance() {
        let validationResult = ValidationResult(
            isCompliant: true,
            profileName: "PDF/A-2a",
            totalRules: 100,
            passedRules: 100,
            failedRules: 0,
            ruleResults: [],
            duration: 1.5
        )

        let pdfaResult = PDFAValidationResult(
            validationResult: validationResult,
            conformance: .pdf2a,
            claimedConformance: nil,
            pdfaIssues: []
        )

        #expect(pdfaResult.conformanceMatches == false)
        #expect(pdfaResult.claimedConformance == nil)
    }

    @Test("Result with PDF/A issues")
    func resultWithIssues() {
        let validationResult = ValidationResult(
            isCompliant: false,
            profileName: "PDF/A-1a",
            totalRules: 100,
            passedRules: 98,
            failedRules: 2,
            ruleResults: [],
            duration: 1.5
        )

        let issues = [
            PDFAIssue(
                category: .fonts,
                description: "Font not embedded",
                severity: .error
            ),
            PDFAIssue(
                category: .metadata,
                description: "Missing XMP metadata",
                severity: .error
            )
        ]

        let pdfaResult = PDFAValidationResult(
            validationResult: validationResult,
            conformance: .pdf1a,
            claimedConformance: .pdf1a,
            pdfaIssues: issues
        )

        #expect(pdfaResult.pdfaIssues.count == 2)
        #expect(pdfaResult.isCompliant == false)
    }
}

// MARK: - PDF/A Flavour Tests

@Suite("PDF/A Flavour")
struct PDFAFlavourTests {

    @Test("PDF/A-1 flavours")
    func pdfa1Flavours() {
        let flavourA = PDFAFlavour.pdfa1(level: .a)
        #expect(flavourA.profileName == "PDF/A-1a")

        let flavourB = PDFAFlavour.pdfa1(level: .b)
        #expect(flavourB.profileName == "PDF/A-1b")
    }

    @Test("PDF/A-2 flavours")
    func pdfa2Flavours() {
        let flavourA = PDFAFlavour.pdfa2(level: .a)
        #expect(flavourA.profileName == "PDF/A-2a")

        let flavourB = PDFAFlavour.pdfa2(level: .b)
        #expect(flavourB.profileName == "PDF/A-2b")

        let flavourU = PDFAFlavour.pdfa2(level: .u)
        #expect(flavourU.profileName == "PDF/A-2u")
    }

    @Test("PDF/A-3 flavours")
    func pdfa3Flavours() {
        let flavourA = PDFAFlavour.pdfa3(level: .a)
        #expect(flavourA.profileName == "PDF/A-3a")

        let flavourB = PDFAFlavour.pdfa3(level: .b)
        #expect(flavourB.profileName == "PDF/A-3b")

        let flavourU = PDFAFlavour.pdfa3(level: .u)
        #expect(flavourU.profileName == "PDF/A-3u")
    }

    @Test("PDF/A-4 flavour")
    func pdfa4Flavour() {
        let flavour = PDFAFlavour.pdfa4
        #expect(flavour.profileName == "PDF/A-4")
    }
}
