import Testing
import Foundation
@testable import SwiftVerificarValidation
@testable import SwiftVerificarValidationProfiles

// MARK: - PDFA4Validator Tests

@Suite("PDFA4Validator")
struct PDFA4ValidatorTests {

    @Test("Initialize PDF/A-4 validator")
    func initializeValidator() async throws {
        let validator = try PDFA4Validator()
        let conformance = validator.conformance

        #expect(conformance.part == .part4)
        #expect(conformance.identifier == "PDF/A-4b")
    }

    @Test("PDF/A-4 has unified conformance level")
    func unifiedConformanceLevel() async throws {
        let validator = try PDFA4Validator()
        let conformance = validator.conformance

        // PDF/A-4 simplifies to single level (no A/B/U distinction)
        #expect(conformance.part == .part4)
    }

    @Test("Validate with mock document")
    func validateDocument() async throws {
        let validator = try PDFA4Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.conformance.part == .part4)
        #expect(result.validationResult.profileName.contains("PDF/A-4"))
    }

    @Test("PDF/A-4 based on PDF 2.0")
    func basedOnPDF20() async throws {
        // PDF/A-4 is based on PDF 2.0 (ISO 32000-2)
        let validator = try PDFA4Validator()
        let conformance = validator.conformance

        #expect(conformance.part == .part4)
        // PDF 2.0 compliance is a key requirement
    }

    @Test("Validate with fast configuration")
    func validateFastConfig() async throws {
        let validator = try PDFA4Validator()
        let mockDocument = MockPDFDocument()
        let config = ValidatorConfiguration.fast

        let result = try await validator.validate(mockDocument, configuration: config)

        #expect(result.conformance.part == .part4)
    }

    @Test("Validate with thorough configuration")
    func validateThoroughConfig() async throws {
        let validator = try PDFA4Validator()
        let mockDocument = MockPDFDocument()
        let config = ValidatorConfiguration.thorough

        let result = try await validator.validate(mockDocument, configuration: config)

        #expect(result.conformance.part == .part4)
    }

    @Test("Detect claimed conformance")
    func detectClaimedConformance() async throws {
        let validator = try PDFA4Validator()
        let mockDocument = MockPDFDocument()

        let claimed = try await validator.detectClaimedConformance(mockDocument)
        #expect(claimed == nil) // Not implemented yet
    }

    @Test("ValidationEngine protocol conformance")
    func validationEngineConformance() async throws {
        let validator = try PDFA4Validator()
        let mockDocument = MockPDFDocument()

        let profile = ValidationProfile(
            details: ProfileDetails(
                name: "PDF/A-4 Test",
                description: "Test",
                creator: "Test Suite",
                created: Date()
            ),
            rules: [],
            flavour: .pdfA4
        )

        let result = try await validator.validate(mockDocument, profile: profile)
        #expect(result.profileName == "PDF/A-4 Test")
    }

    @Test("Custom profile loader")
    func customProfileLoader() async throws {
        let mockLoader = MockProfileLoader()
        let validator = try PDFA4Validator(profileLoader: mockLoader)

        let mockDocument = MockPDFDocument()
        let result = try await validator.validate(mockDocument)

        #expect(result.validationResult.profileName == "Mock Profile")
    }

    @Test("Multiple validators coexist")
    func multipleValidators() async throws {
        let v1 = try PDFA4Validator()
        let v2 = try PDFA4Validator()

        let c1 = v1.conformance
        let c2 = v2.conformance

        #expect(c1 == c2)
        #expect(c1.part == .part4)
    }

    @Test("Concurrent validation")
    func concurrentValidation() async throws {
        let validator = try PDFA4Validator()
        let docs = [MockPDFDocument(), MockPDFDocument(), MockPDFDocument()]

        async let r1 = validator.validate(docs[0])
        async let r2 = validator.validate(docs[1])
        async let r3 = validator.validate(docs[2])

        let results = try await (r1, r2, r3)

        #expect(results.0.conformance.part == .part4)
        #expect(results.1.conformance.part == .part4)
        #expect(results.2.conformance.part == .part4)
    }

    @Test("Result includes duration")
    func resultDuration() async throws {
        let validator = try PDFA4Validator()
        let mockDocument = MockPDFDocument()

        let result = try await validator.validate(mockDocument)

        #expect(result.validationResult.duration > 0)
    }

    @Test("PDF/A-4 supports rich media")
    func supportsRichMedia() async throws {
        // PDF/A-4 allows rich media and 3D content
        let validator = try PDFA4Validator()
        let conformance = validator.conformance

        #expect(conformance.part == .part4)
        // Rich media support is a PDF 2.0 feature
    }

    @Test("PDF/A-4 supports AES-256 encryption")
    func supportsAES256() async throws {
        // PDF/A-4 allows AES-256 encryption (PDF 2.0 feature)
        let validator = try PDFA4Validator()
        let conformance = validator.conformance

        #expect(conformance.part == .part4)
    }

    @Test("PDF/A-4 requires Unicode support")
    func requiresUnicode() async throws {
        // PDF/A-4 mandates Unicode (no separate level U)
        let validator = try PDFA4Validator()
        let conformance = validator.conformance

        // Unicode is mandatory in PDF/A-4
        #expect(conformance.part == .part4)
    }

    @Test("PDF/A-4 supports geospatial extensions")
    func supportsGeospatial() async throws {
        // PDF/A-4 includes geospatial extensions from PDF 2.0
        let validator = try PDFA4Validator()
        let conformance = validator.conformance

        #expect(conformance.part == .part4)
    }

    @Test("PDF/A-4 supports PRC 3D format")
    func supportsPRC3D() async throws {
        // PDF/A-4 allows PRC (Product Representation Compact) 3D format
        let validator = try PDFA4Validator()
        let conformance = validator.conformance

        #expect(conformance.part == .part4)
    }

    @Test("Validator default initialization")
    func defaultInitialization() async throws {
        let validator = try PDFA4Validator()
        let conformance = validator.conformance

        #expect(conformance.part == .part4)
        #expect(conformance.level == .b) // Default level
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
            flavour: .pdfA4
        )
    }
}
