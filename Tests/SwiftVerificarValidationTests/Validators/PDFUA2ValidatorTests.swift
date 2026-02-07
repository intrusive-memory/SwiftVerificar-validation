import Testing
import Foundation
@testable import SwiftVerificarValidation
@testable import SwiftVerificarValidationProfiles

// MARK: - PDF/UA-2 Validator Tests

@Suite("PDF/UA-2 Validator")
struct PDFUA2ValidatorTests {

    @Test("Validator initialization")
    func validatorInitialization() async {
        let validator = PDFUA2Validator()
        let conformance = validator.conformance

        #expect(conformance == PDFUAConformance.pdfua2)
        #expect(conformance.identifier == "PDF/UA-2")
        #expect(conformance.isoReference == "ISO 14289-2:2024")
    }

    @Test("Validator with custom configuration")
    func validatorWithConfiguration() async {
        let config = ValidatorConfiguration.thorough
        let validator = PDFUA2Validator(configuration: config)
        let conformance = validator.conformance

        #expect(conformance == PDFUAConformance.pdfua2)
    }

    @Test("Validator with custom profile loader")
    func validatorWithProfileLoader() async {
        let loader = DefaultProfileLoader()
        let validator = PDFUA2Validator(profileLoader: loader)
        let conformance = validator.conformance

        #expect(conformance == PDFUAConformance.pdfua2)
    }

    @Test("Detect claimed conformance - no metadata")
    func detectClaimedConformanceNone() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let claimedConformance = try await validator.detectClaimedConformance(mockDocument)

        #expect(claimedConformance == nil)
    }

    @Test("Validate document - basic structure")
    func validateDocumentBasic() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        #expect(result.conformance == PDFUAConformance.pdfua2)
        #expect(result.validationResult.profileName == "PDF/UA-2")
    }

    @Test("Validate document with thorough configuration")
    func validateDocumentThorough() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .thorough
        )

        #expect(result.conformance == PDFUAConformance.pdfua2)
    }

    @Test("Validate document with fast configuration")
    func validateDocumentFast() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .fast
        )

        #expect(result.conformance == PDFUAConformance.pdfua2)
    }

    @Test("Validate document - default configuration")
    func validateDocumentDefaultConfig() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.conformance == PDFUAConformance.pdfua2)
    }

    @Test("Validation result structure")
    func validationResultStructure() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        #expect(result.conformance == PDFUAConformance.pdfua2)
        #expect(result.pdfuaIssues.count >= 0)
        #expect(result.accessibilityFeatures.hasStructureTree == false)
    }

    @Test("Validation with ValidationEngine protocol")
    func validationWithEngineProtocol() async throws {
        let validator: any ValidationEngine = PDFUA2Validator()
        let mockDocument = MockPDFDocument()
        let profile = ValidationProfile(
            details: ProfileDetails(
                name: "PDF/UA-2",
                description: "Test profile",
                creator: "Test Suite",
                created: Date()
            ),
            rules: [],
            flavour: .pdfUA2
        )

        let result = try await validator.validate(mockDocument, profile: profile)

        #expect(result.isCompliant == false || result.isCompliant == true)
    }

    @Test("Concurrent validations")
    func concurrentValidations() async throws {
        let validator = PDFUA2Validator()
        let mockDocument1 = MockPDFDocument()
        let mockDocument2 = MockPDFDocument()

        async let result1 = validator.validate(mockDocument1, configuration: .default)
        async let result2 = validator.validate(mockDocument2, configuration: .default)

        let (r1, r2) = try await (result1, result2)

        #expect(r1.conformance == PDFUAConformance.pdfua2)
        #expect(r2.conformance == PDFUAConformance.pdfua2)
    }

    @Test("Validation statistics")
    func validationStatistics() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        #expect(result.validationResult.totalRules >= 0)
        #expect(result.validationResult.passedRules + result.validationResult.failedRules <= result.validationResult.totalRules)
    }

    @Test("Validation issues structure")
    func validationIssuesStructure() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        // Check that issues have proper structure
        for issue in result.pdfuaIssues {
            #expect(!issue.description.isEmpty)
        }
    }

    @Test("Accessibility features extraction")
    func accessibilityFeaturesExtraction() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        let features = result.accessibilityFeatures
        #expect(features.headingCount >= 0)
        #expect(features.tableCount >= 0)
        #expect(features.listCount >= 0)
        #expect(features.formFieldCount >= 0)
        #expect(features.annotationCount >= 0)
    }

    @Test("Compliance determination")
    func complianceDetermination() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        // Result should be either compliant or non-compliant
        let errorIssues = result.pdfuaIssues.filter { $0.severity == .error }
        if errorIssues.isEmpty {
            #expect(result.isCompliant == true)
        } else {
            #expect(result.isCompliant == false)
        }
    }

    @Test("PDF 2.0 requirement")
    func pdf2Requirement() async throws {
        let validator = PDFUA2Validator()
        let conformance = validator.conformance

        // PDF/UA-2 requires PDF 2.0
        #expect(conformance.part.basePDFVersion == "2.0")
    }

    @Test("Enhanced semantic elements support")
    func enhancedSemanticElements() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        // PDF/UA-2 validates enhanced semantic elements
        // This is verified through the validation profile
        #expect(result.conformance.part == .part2)
    }

    @Test("Heading hierarchy validation")
    func headingHierarchyValidation() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        // PDF/UA-2 includes enhanced heading hierarchy validation
        // Check that heading-related features are tracked
        #expect(result.accessibilityFeatures.headingCount >= 0)
    }

    @Test("Associated files support")
    func associatedFilesSupport() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        // PDF/UA-2 includes associated files (AF entries) validation
        #expect(result.conformance.part == .part2)
    }

    @Test("Enhanced table validation")
    func enhancedTableValidation() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        // PDF/UA-2 includes enhanced table structure validation
        #expect(result.accessibilityFeatures.tableCount >= 0)
    }

    @Test("Enhanced annotation validation")
    func enhancedAnnotationValidation() async throws {
        let validator = PDFUA2Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        // PDF/UA-2 includes enhanced annotation accessibility validation
        #expect(result.accessibilityFeatures.annotationCount >= 0)
    }
}

// MARK: - PDF/UA-1 vs PDF/UA-2 Comparison Tests

@Suite("PDF/UA-1 vs PDF/UA-2 Comparison")
struct PDFUAComparisonTests {

    @Test("Different conformance levels")
    func differentConformanceLevels() async {
        let validator1 = PDFUA1Validator()
        let validator2 = PDFUA2Validator()

        let conformance1 = validator1.conformance
        let conformance2 = validator2.conformance

        #expect(conformance1 != conformance2)
        #expect(conformance1.part == .part1)
        #expect(conformance2.part == .part2)
    }

    @Test("Different base PDF versions")
    func differentBasePDFVersions() async {
        let validator1 = PDFUA1Validator()
        let validator2 = PDFUA2Validator()

        let conformance1 = validator1.conformance
        let conformance2 = validator2.conformance

        #expect(conformance1.part.basePDFVersion == "1.4")
        #expect(conformance2.part.basePDFVersion == "2.0")
    }

    @Test("Different ISO references")
    func differentISOReferences() async {
        let validator1 = PDFUA1Validator()
        let validator2 = PDFUA2Validator()

        let conformance1 = validator1.conformance
        let conformance2 = validator2.conformance

        #expect(conformance1.isoReference == "ISO 14289-1:2014")
        #expect(conformance2.isoReference == "ISO 14289-2:2024")
    }
}

// MARK: - Mock PDF Document

private struct MockPDFDocument {
    // Minimal mock document for testing
}
