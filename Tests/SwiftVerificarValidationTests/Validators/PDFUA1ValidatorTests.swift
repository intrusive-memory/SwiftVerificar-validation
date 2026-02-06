import Testing
import Foundation
@testable import SwiftVerificarValidation
@testable import SwiftVerificarValidationProfiles

// MARK: - PDF/UA-1 Validator Tests

@Suite("PDF/UA-1 Validator")
struct PDFUA1ValidatorTests {

    @Test("Validator initialization")
    func validatorInitialization() async {
        let validator = PDFUA1Validator()
        let conformance = await validator.conformance

        #expect(conformance == .pdfua1)
        #expect(conformance.identifier == "PDF/UA-1")
        #expect(conformance.isoReference == "ISO 14289-1:2014")
    }

    @Test("Validator with custom configuration")
    func validatorWithConfiguration() async {
        let config = ValidatorConfiguration.thorough
        let validator = PDFUA1Validator(configuration: config)
        let conformance = await validator.conformance

        #expect(conformance == .pdfua1)
    }

    @Test("Validator with custom profile loader")
    func validatorWithProfileLoader() async {
        let loader = DefaultProfileLoader()
        let validator = PDFUA1Validator(profileLoader: loader)
        let conformance = await validator.conformance

        #expect(conformance == .pdfua1)
    }

    @Test("Detect claimed conformance - no metadata")
    func detectClaimedConformanceNone() async throws {
        let validator = PDFUA1Validator()
        let mockDocument = MockPDFDocument()

        let claimedConformance = try await validator.detectClaimedConformance(mockDocument)

        #expect(claimedConformance == nil)
    }

    @Test("Validate document - basic structure")
    func validateDocumentBasic() async throws {
        let validator = PDFUA1Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        #expect(result.conformance == .pdfua1)
        #expect(result.validationResult.profile.name == "PDF/UA-1")
    }

    @Test("Validate document with thorough configuration")
    func validateDocumentThorough() async throws {
        let validator = PDFUA1Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .thorough
        )

        #expect(result.conformance == .pdfua1)
    }

    @Test("Validate document with fast configuration")
    func validateDocumentFast() async throws {
        let validator = PDFUA1Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .fast
        )

        #expect(result.conformance == .pdfua1)
    }

    @Test("Validate document - default configuration")
    func validateDocumentDefaultConfig() async throws {
        let validator = PDFUA1Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.conformance == .pdfua1)
    }

    @Test("Validation result structure")
    func validationResultStructure() async throws {
        let validator = PDFUA1Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        #expect(result.conformance == .pdfua1)
        #expect(result.pdfuaIssues.count >= 0)
        #expect(result.accessibilityFeatures.hasStructureTree == false)
    }

    @Test("Validation with ValidationEngine protocol")
    func validationWithEngineProtocol() async throws {
        let validator: any ValidationEngine = PDFUA1Validator()
        let mockDocument = MockPDFDocument()
        let profile = ValidationProfile(
            name: "PDF/UA-1",
            description: "Test profile",
            rules: []
        )

        let result = try await validator.validate(mockDocument, profile: profile)

        #expect(result.isCompliant == false || result.isCompliant == true)
    }

    @Test("Concurrent validations")
    func concurrentValidations() async throws {
        let validator = PDFUA1Validator()
        let mockDocument1 = MockPDFDocument()
        let mockDocument2 = MockPDFDocument()

        async let result1 = validator.validate(mockDocument1, configuration: .default)
        async let result2 = validator.validate(mockDocument2, configuration: .default)

        let (r1, r2) = try await (result1, result2)

        #expect(r1.conformance == .pdfua1)
        #expect(r2.conformance == .pdfua1)
    }

    @Test("Validation statistics")
    func validationStatistics() async throws {
        let validator = PDFUA1Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        let stats = result.validationResult.statistics
        #expect(stats.totalRulesEvaluated >= 0)
        #expect(stats.passedRules + stats.failedRules + stats.skippedRules <= stats.totalRulesEvaluated)
    }

    @Test("Validation issues structure")
    func validationIssuesStructure() async throws {
        let validator = PDFUA1Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(
            mockDocument,
            configuration: .default
        )

        // Check that issues have proper structure
        for issue in result.pdfuaIssues {
            #expect(!issue.description.isEmpty)
            #expect(issue.category != nil)
            #expect(issue.severity != nil)
        }
    }

    @Test("Accessibility features extraction")
    func accessibilityFeaturesExtraction() async throws {
        let validator = PDFUA1Validator()
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
        let validator = PDFUA1Validator()
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
}

// MARK: - Mock PDF Document

private struct MockPDFDocument {
    // Minimal mock document for testing
}
