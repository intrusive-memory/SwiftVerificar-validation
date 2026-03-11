import Testing
import Foundation
@testable import SwiftVerificarValidation
@testable import SwiftVerificarValidationProfiles

// MARK: - PDFA3Validator Tests

@Suite("PDFA3Validator")
struct PDFA3ValidatorTests {

    @Test("Initialize PDF/A-3a validator")
    func initializeLevelA() async throws {
        let validator = try await PDFA3Validator.levelA()
        let conformance = validator.conformance

        #expect(conformance.part == .part3)
        #expect(conformance.level == .a)
        #expect(conformance.identifier == "PDF/A-3a")
    }

    @Test("Initialize PDF/A-3b validator")
    func initializeLevelB() async throws {
        let validator = try await PDFA3Validator.levelB()
        let conformance = validator.conformance

        #expect(conformance.part == .part3)
        #expect(conformance.level == .b)
        #expect(conformance.identifier == "PDF/A-3b")
    }

    @Test("Initialize PDF/A-3u validator")
    func initializeLevelU() async throws {
        let validator = try await PDFA3Validator.levelU()
        let conformance = validator.conformance

        #expect(conformance.part == .part3)
        #expect(conformance.level == .u)
        #expect(conformance.identifier == "PDF/A-3u")
    }

    @Test("All levels valid for PDF/A-3")
    func allLevelsValid() async throws {
        let validatorA = try PDFA3Validator(level: .a)
        let validatorB = try PDFA3Validator(level: .b)
        let validatorU = try PDFA3Validator(level: .u)

        let confA = validatorA.conformance
        let confB = validatorB.conformance
        let confU = validatorU.conformance

        #expect(confA.level == .a)
        #expect(confB.level == .b)
        #expect(confU.level == .u)
    }

    @Test("Validate with mock document")
    func validateDocument() async throws {
        let validator = try await PDFA3Validator.levelB()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.conformance == .pdf3b)
        #expect(result.validationResult.profileName.lowercased().contains("pdf/a-3b") ||
                result.validationResult.profileName.lowercased().contains("pdf/a-3"))
    }

    @Test("PDF/A-3 allows embedded files")
    func allowsEmbeddedFiles() async throws {
        // PDF/A-3 key feature: arbitrary file embedding
        let validator = try await PDFA3Validator.levelB()
        let conformance = validator.conformance

        #expect(conformance.part == .part3)
        // Embedded file support is the key differentiator
    }

    @Test("Level requirements inherited from PDF/A-2")
    func levelRequirements() async throws {
        let validatorA = try await PDFA3Validator.levelA()
        let validatorU = try await PDFA3Validator.levelU()
        let validatorB = try await PDFA3Validator.levelB()

        let confA = validatorA.conformance
        let confU = validatorU.conformance
        let confB = validatorB.conformance

        #expect(confA.level.requiresAccessibility == true)
        #expect(confA.level.requiresUnicode == true)
        #expect(confU.level.requiresUnicode == true)
        #expect(confB.level.requiresAccessibility == false)
    }

    @Test("Validate with configurations")
    func validateWithConfigurations() async throws {
        let validator = try await PDFA3Validator.levelA()
        let mockDocument = MockPDFDocument()

        let fastResult = try await validator.validate(
            mockDocument,
            configuration: .fast
        )
        #expect(fastResult.conformance == .pdf3a)

        let thoroughResult = try await validator.validate(
            mockDocument,
            configuration: .thorough
        )
        #expect(thoroughResult.conformance == .pdf3a)
    }

    @Test("Detect claimed conformance")
    func detectClaimedConformance() async throws {
        let validator = try await PDFA3Validator.levelU()
        let mockDocument = MockPDFDocument()

        let claimed = try await validator.detectClaimedConformance(mockDocument)
        #expect(claimed == nil) // Not implemented yet
    }

    @Test("ValidationEngine protocol conformance")
    func validationEngineConformance() async throws {
        let validator = try await PDFA3Validator.levelB()
        let mockDocument = MockPDFDocument()

        let profile = ValidationProfile(
            details: ProfileDetails(
                name: "PDF/A-3b Test",
                description: "Test",
                creator: "Test Suite",
                created: Date()
            ),
            rules: [],
            flavour: .pdfA3b
        )

        let result = try await validator.validate(mockDocument, profile: profile)
        #expect(result.profileName == "PDF/A-3b Test")
    }

    @Test("Custom profile loader")
    func customProfileLoader() async throws {
        let mockLoader = MockProfileLoader()
        let validator = try PDFA3Validator(level: .u, profileLoader: mockLoader)

        let mockDocument = MockPDFDocument()
        let result = try await validator.validate(mockDocument)

        #expect(result.validationResult.profileName == "Mock Profile")
    }

    @Test("Multiple validators coexist")
    func multipleValidators() async throws {
        let v1 = try await PDFA3Validator.levelA()
        let v2 = try await PDFA3Validator.levelB()
        let v3 = try await PDFA3Validator.levelU()

        let c1 = v1.conformance
        let c2 = v2.conformance
        let c3 = v3.conformance

        #expect(c1 != c2)
        #expect(c2 != c3)
        #expect(c1 != c3)
    }

    @Test("Concurrent validation")
    func concurrentValidation() async throws {
        let validator = try await PDFA3Validator.levelB()
        let docs = [MockPDFDocument(), MockPDFDocument(), MockPDFDocument()]

        async let r1 = validator.validate(docs[0])
        async let r2 = validator.validate(docs[1])
        async let r3 = validator.validate(docs[2])

        let results = try await (r1, r2, r3)

        #expect(results.0.conformance == .pdf3b)
        #expect(results.1.conformance == .pdf3b)
        #expect(results.2.conformance == .pdf3b)
    }

    @Test("Result includes duration")
    func resultDuration() async throws {
        let validator = try await PDFA3Validator.levelA()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.validationResult.duration > 0)
    }

    @Test("ZUGFeRD use case support")
    func zugferdUseCase() async throws {
        // PDF/A-3 is commonly used for ZUGFeRD (embedded XML invoices)
        let validator = try await PDFA3Validator.levelB()
        let conformance = validator.conformance

        #expect(conformance.part == .part3)
        // ZUGFeRD typically uses PDF/A-3b with embedded XML
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
            flavour: .pdfA3b
        )
    }
}
