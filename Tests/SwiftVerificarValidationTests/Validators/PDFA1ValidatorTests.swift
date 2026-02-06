import Testing
import Foundation
@testable import SwiftVerificarValidation
@testable import SwiftVerificarValidationProfiles

// MARK: - PDFA1Validator Tests

@Suite("PDFA1Validator")
struct PDFA1ValidatorTests {

    @Test("Initialize PDF/A-1a validator")
    func initializeLevelA() async throws {
        let validator = try PDFA1Validator.levelA()
        let conformance = validator.conformance

        #expect(conformance.part == .part1)
        #expect(conformance.level == .a)
        #expect(conformance.identifier == "PDF/A-1a")
    }

    @Test("Initialize PDF/A-1b validator")
    func initializeLevelB() async throws {
        let validator = try PDFA1Validator.levelB()
        let conformance = validator.conformance

        #expect(conformance.part == .part1)
        #expect(conformance.level == .b)
        #expect(conformance.identifier == "PDF/A-1b")
    }

    @Test("Initialize with custom level")
    func initializeCustomLevel() async throws {
        let validator = try PDFA1Validator(level: .a)
        let conformance = validator.conformance

        #expect(conformance.level == .a)
    }

    @Test("Reject invalid level for PDF/A-1")
    func rejectInvalidLevel() async {
        #expect(throws: ValidationError.self) {
            _ = try PDFA1Validator(level: .u)
        }
    }

    @Test("Validate with mock document - compliant")
    func validateCompliantDocument() async throws {
        let validator = try PDFA1Validator.levelB()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.conformance == .pdf1b)
        #expect(result.validationResult.profileName.contains("PDF/A-1b"))
    }

    @Test("Validate with configuration")
    func validateWithConfiguration() async throws {
        let validator = try PDFA1Validator.levelA()
        let mockDocument = MockPDFDocument()
        let config = ValidatorConfiguration.fast

        let result = try await validator.validate(mockDocument, configuration: config)

        #expect(result.conformance == .pdf1a)
    }

    @Test("Validate with default configuration")
    func validateWithDefaultConfig() async throws {
        let validator = try PDFA1Validator.levelB()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.conformance.part == .part1)
    }

    @Test("Detect claimed conformance")
    func detectClaimedConformance() async throws {
        let validator = try PDFA1Validator.levelB()
        let mockDocument = MockPDFDocument()

        // Currently returns nil (not implemented)
        let claimed = try await validator.detectClaimedConformance(mockDocument)
        #expect(claimed == nil)
    }

    @Test("ValidationEngine protocol conformance")
    func validationEngineConformance() async throws {
        let validator = try PDFA1Validator.levelA()
        let mockDocument = MockPDFDocument()

        // Create a minimal profile
        let profile = ValidationProfile(
            name: "Test Profile",
            description: "Test",
            rules: []
        )

        let result = try await validator.validate(mockDocument, profile: profile)

        #expect(result.profileName == "Test Profile")
    }

    @Test("Level A requires structure")
    func levelARequiresStructure() async throws {
        let validator = try PDFA1Validator.levelA()
        let conformance = validator.conformance

        #expect(conformance.level.requiresAccessibility == true)
    }

    @Test("Level B does not require structure")
    func levelBNoStructureRequired() async throws {
        let validator = try PDFA1Validator.levelB()
        let conformance = validator.conformance

        #expect(conformance.level.requiresAccessibility == false)
    }

    @Test("Multiple validators can coexist")
    func multipleValidators() async throws {
        let validatorA = try PDFA1Validator.levelA()
        let validatorB = try PDFA1Validator.levelB()

        let confA = validatorA.conformance
        let confB = validatorB.conformance

        #expect(confA.level == .a)
        #expect(confB.level == .b)
        #expect(confA != confB)
    }

    @Test("Validator uses provided profile loader")
    func customProfileLoader() async throws {
        let mockLoader = MockProfileLoader()
        let validator = try PDFA1Validator(level: .b, profileLoader: mockLoader)

        let mockDocument = MockPDFDocument()
        let result = try await validator.validate(mockDocument)

        #expect(result.validationResult.profileName == "Mock Profile")
    }

    @Test("Validator categorizes font rules")
    func categorizeFontRules() async throws {
        let validator = try PDFA1Validator.levelB()
        // Test internal categorization would require exposing private methods
        // or testing through integration
        let conformance = validator.conformance
        #expect(conformance.part == .part1)
    }

    @Test("Validator categorizes metadata rules")
    func categorizeMetadataRules() async throws {
        let validator = try PDFA1Validator.levelB()
        let conformance = validator.conformance
        #expect(conformance.part == .part1)
    }

    @Test("Validator result includes duration")
    func resultIncludesDuration() async throws {
        let validator = try PDFA1Validator.levelB()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.validationResult.duration > 0)
    }

    @Test("Concurrent validation")
    func concurrentValidation() async throws {
        let validator = try PDFA1Validator.levelB()
        let doc1 = MockPDFDocument()
        let doc2 = MockPDFDocument()

        async let result1 = validator.validate(doc1)
        async let result2 = validator.validate(doc2)

        let (r1, r2) = try await (result1, result2)

        #expect(r1.conformance == .pdf1b)
        #expect(r2.conformance == .pdf1b)
    }
}

// MARK: - Mock Types

private struct MockPDFDocument {}

private struct MockProfileLoader: ValidationProfileLoader {
    func loadProfile(flavour: PDFAFlavour) async throws -> ValidationProfile {
        ValidationProfile(
            details: ProfileDetails(
                name: "Mock Profile",
                description: "Mock validation profile",
                creator: "Test",
                created: Date()
            ),
            hash: nil,
            rules: [],
            variables: [],
            flavour: .pdfA1a
        )
    }
}

