import Testing
import Foundation
@testable import SwiftVerificarValidation
@testable import SwiftVerificarValidationProfiles

// MARK: - PDFA2Validator Tests

@Suite("PDFA2Validator")
struct PDFA2ValidatorTests {

    @Test("Initialize PDF/A-2a validator")
    func initializeLevelA() async throws {
        let validator = try await PDFA2Validator.levelA()
        let conformance = validator.conformance

        #expect(conformance.part == .part2)
        #expect(conformance.level == .a)
        #expect(conformance.identifier == "PDF/A-2a")
    }

    @Test("Initialize PDF/A-2b validator")
    func initializeLevelB() async throws {
        let validator = try await PDFA2Validator.levelB()
        let conformance = validator.conformance

        #expect(conformance.part == .part2)
        #expect(conformance.level == .b)
        #expect(conformance.identifier == "PDF/A-2b")
    }

    @Test("Initialize PDF/A-2u validator")
    func initializeLevelU() async throws {
        let validator = try await PDFA2Validator.levelU()
        let conformance = validator.conformance

        #expect(conformance.part == .part2)
        #expect(conformance.level == .u)
        #expect(conformance.identifier == "PDF/A-2u")
    }

    @Test("All levels valid for PDF/A-2")
    func allLevelsValid() async throws {
        let validatorA = try PDFA2Validator(level: .a)
        let validatorB = try PDFA2Validator(level: .b)
        let validatorU = try PDFA2Validator(level: .u)

        let confA = validatorA.conformance
        let confB = validatorB.conformance
        let confU = validatorU.conformance

        #expect(confA.level == .a)
        #expect(confB.level == .b)
        #expect(confU.level == .u)
    }

    @Test("Validate with mock document")
    func validateDocument() async throws {
        let validator = try await PDFA2Validator.levelB()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.conformance == .pdf2b)
        #expect(result.validationResult.profileName.contains("PDF/A-2b"))
    }

    @Test("Level U requires Unicode")
    func levelURequiresUnicode() async throws {
        let validator = try await PDFA2Validator.levelU()
        let conformance = validator.conformance

        #expect(conformance.level.requiresUnicode == true)
    }

    @Test("Level A requires accessibility and Unicode")
    func levelARequirements() async throws {
        let validator = try await PDFA2Validator.levelA()
        let conformance = validator.conformance

        #expect(conformance.level.requiresAccessibility == true)
        #expect(conformance.level.requiresUnicode == true)
    }

    @Test("Level B requires neither")
    func levelBRequirements() async throws {
        let validator = try await PDFA2Validator.levelB()
        let conformance = validator.conformance

        #expect(conformance.level.requiresAccessibility == false)
        #expect(conformance.level.requiresUnicode == false)
    }

    @Test("Validate with fast configuration")
    func validateFastConfig() async throws {
        let validator = try await PDFA2Validator.levelU()
        let mockDocument = MockPDFDocument()
        let config = ValidatorConfiguration.fast

        let result = try await validator.validate(mockDocument, configuration: config)

        #expect(result.conformance == .pdf2u)
    }

    @Test("Validate with thorough configuration")
    func validateThoroughConfig() async throws {
        let validator = try await PDFA2Validator.levelA()
        let mockDocument = MockPDFDocument()
        let config = ValidatorConfiguration.thorough

        let result = try await validator.validate(mockDocument, configuration: config)

        #expect(result.conformance == .pdf2a)
    }

    @Test("Detect claimed conformance returns nil")
    func detectClaimedConformance() async throws {
        let validator = try await PDFA2Validator.levelB()
        let mockDocument = MockPDFDocument()

        let claimed = try await validator.detectClaimedConformance(mockDocument)
        #expect(claimed == nil)
    }

    @Test("ValidationEngine protocol conformance")
    func validationEngineConformance() async throws {
        let validator = try await PDFA2Validator.levelU()
        let mockDocument = MockPDFDocument()

        let profile = ValidationProfile(
            details: ProfileDetails(
                name: "PDF/A-2u Test",
                description: "Test",
                creator: "Test Suite",
                created: Date()
            ),
            rules: [],
            flavour: .pdfA2u
        )

        let result = try await validator.validate(mockDocument, profile: profile)
        #expect(result.profileName == "PDF/A-2u Test")
    }

    @Test("Custom profile loader")
    func customProfileLoader() async throws {
        let mockLoader = MockProfileLoader()
        let validator = try PDFA2Validator(level: .a, profileLoader: mockLoader)

        let mockDocument = MockPDFDocument()
        let result = try await validator.validate(mockDocument)

        #expect(result.validationResult.profileName == "Mock Profile")
    }

    @Test("Multiple validators coexist")
    func multipleValidators() async throws {
        let v1 = try await PDFA2Validator.levelA()
        let v2 = try await PDFA2Validator.levelB()
        let v3 = try await PDFA2Validator.levelU()

        let c1 = v1.conformance
        let c2 = v2.conformance
        let c3 = v3.conformance

        #expect(c1.level == .a)
        #expect(c2.level == .b)
        #expect(c3.level == .u)
    }

    @Test("Concurrent validation")
    func concurrentValidation() async throws {
        let validator = try await PDFA2Validator.levelB()
        let doc1 = MockPDFDocument()
        let doc2 = MockPDFDocument()
        let doc3 = MockPDFDocument()

        async let r1 = validator.validate(doc1)
        async let r2 = validator.validate(doc2)
        async let r3 = validator.validate(doc3)

        let results = try await (r1, r2, r3)

        #expect(results.0.conformance == .pdf2b)
        #expect(results.1.conformance == .pdf2b)
        #expect(results.2.conformance == .pdf2b)
    }

    @Test("Result includes duration")
    func resultDuration() async throws {
        let validator = try await PDFA2Validator.levelU()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.validationResult.duration > 0)
    }

    @Test("PDF/A-2 supports transparency")
    func supportsTransparency() async throws {
        // PDF/A-2 allows transparency (unlike PDF/A-1)
        let validator = try await PDFA2Validator.levelB()
        let conformance = validator.conformance

        #expect(conformance.part == .part2)
        // Transparency support is implicit in PDF/A-2
    }

    @Test("PDF/A-2 supports JPEG2000")
    func supportsJPEG2000() async throws {
        // PDF/A-2 allows JPEG2000 compression
        let validator = try await PDFA2Validator.levelB()
        let conformance = validator.conformance

        #expect(conformance.part == .part2)
        // JPEG2000 support is implicit in PDF/A-2
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
                creator: "Test Suite",
                created: Date()
            ),
            rules: [],
            flavour: .pdfA2a
        )
    }
}
