import Foundation
import Testing
@testable import SwiftVerificarValidation

@Suite("ValidationError Tests")
struct ValidationErrorTests {

    // MARK: - Initialization Tests

    @Test("Create ValidationError with all parameters")
    func createWithAllParameters() {
        let context = ValidationContext(
            objectIdentifier: "Page 1",
            ruleId: "rule-001",
            location: "page:1"
        )
        let underlying = NSError(domain: "test", code: 1)

        let error = ValidationError(
            code: .parsingFailed,
            message: "Failed to parse PDF",
            context: context,
            underlyingError: underlying
        )

        #expect(error.code == .parsingFailed)
        #expect(error.message == "Failed to parse PDF")
        #expect(error.context?.objectIdentifier == "Page 1")
        #expect(error.underlyingError != nil)
    }

    @Test("Create ValidationError with minimal parameters")
    func createWithMinimalParameters() {
        let error = ValidationError(
            code: .profileLoadFailed,
            message: "Profile not found"
        )

        #expect(error.code == .profileLoadFailed)
        #expect(error.message == "Profile not found")
        #expect(error.context == nil)
        #expect(error.underlyingError == nil)
    }

    // MARK: - Error Code Tests

    @Test("All error codes have unique raw values")
    func errorCodesAreUnique() {
        let codes: [ValidationError.ErrorCode] = [
            .parsingFailed,
            .profileLoadFailed,
            .ruleExecutionFailed,
            .invalidStructure,
            .missingMetadata,
            .invalidReference,
            .unsupportedFeature,
            .configurationError,
            .internalError
        ]

        let rawValues = codes.map { $0.rawValue }
        let uniqueValues = Set(rawValues)

        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("Error codes are Codable")
    func errorCodesAreCodable() throws {
        let code = ValidationError.ErrorCode.parsingFailed

        let encoder = JSONEncoder()
        let data = try encoder.encode(code)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ValidationError.ErrorCode.self, from: data)

        #expect(decoded == code)
    }

    @Test("Error code raw values are descriptive")
    func errorCodeRawValues() {
        #expect(ValidationError.ErrorCode.parsingFailed.rawValue == "parsingFailed")
        #expect(ValidationError.ErrorCode.profileLoadFailed.rawValue == "profileLoadFailed")
        #expect(ValidationError.ErrorCode.ruleExecutionFailed.rawValue == "ruleExecutionFailed")
        #expect(ValidationError.ErrorCode.invalidStructure.rawValue == "invalidStructure")
        #expect(ValidationError.ErrorCode.missingMetadata.rawValue == "missingMetadata")
        #expect(ValidationError.ErrorCode.invalidReference.rawValue == "invalidReference")
        #expect(ValidationError.ErrorCode.unsupportedFeature.rawValue == "unsupportedFeature")
        #expect(ValidationError.ErrorCode.configurationError.rawValue == "configurationError")
        #expect(ValidationError.ErrorCode.internalError.rawValue == "internalError")
    }

    // MARK: - Description Tests

    @Test("Description includes error code and message")
    func descriptionBasic() {
        let error = ValidationError(
            code: .parsingFailed,
            message: "Failed to parse"
        )

        let description = error.description
        #expect(description.contains("parsingFailed"))
        #expect(description.contains("Failed to parse"))
    }

    @Test("Description includes context when provided")
    func descriptionWithContext() {
        let context = ValidationContext(objectIdentifier: "Page 1")
        let error = ValidationError(
            code: .invalidStructure,
            message: "Invalid page structure",
            context: context
        )

        let description = error.description
        #expect(description.contains("Page 1"))
        #expect(description.contains("Context"))
    }

    @Test("Description includes underlying error when provided")
    func descriptionWithUnderlyingError() {
        let underlying = NSError(domain: "test", code: 42)
        let error = ValidationError(
            code: .internalError,
            message: "Internal error occurred",
            underlyingError: underlying
        )

        let description = error.description
        #expect(description.contains("Underlying"))
    }

    @Test("Description with all components")
    func descriptionComplete() {
        let context = ValidationContext(
            objectIdentifier: "Font /F1",
            ruleId: "rule-123",
            location: "page:5"
        )
        let underlying = NSError(domain: "test", code: 1)
        let error = ValidationError(
            code: .invalidReference,
            message: "Font reference invalid",
            context: context,
            underlyingError: underlying
        )

        let description = error.description
        #expect(description.contains("invalidReference"))
        #expect(description.contains("Font reference invalid"))
        #expect(description.contains("Context"))
        #expect(description.contains("Underlying"))
    }

    // MARK: - Error Protocol Conformance

    @Test("ValidationError conforms to Error protocol")
    func conformsToError() {
        let error: any Error = ValidationError(
            code: .parsingFailed,
            message: "Test"
        )

        #expect(error is ValidationError)
    }

    @Test("Can throw and catch ValidationError")
    func canThrowAndCatch() throws {
        func throwsError() throws {
            throw ValidationError(
                code: .profileLoadFailed,
                message: "Profile not found"
            )
        }

        var caughtError: ValidationError?
        do {
            try throwsError()
        } catch let error as ValidationError {
            caughtError = error
        }

        #expect(caughtError != nil)
        #expect(caughtError?.code == .profileLoadFailed)
    }

    // MARK: - Sendable Conformance

    @Test("ValidationError is Sendable")
    func isSendable() {
        let error = ValidationError(
            code: .parsingFailed,
            message: "Test"
        )

        Task {
            let _ = error
            #expect(true)
        }
    }
}
