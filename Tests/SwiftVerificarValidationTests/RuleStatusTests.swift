import Foundation
import Testing
@testable import SwiftVerificarValidation

@Suite("RuleStatus Tests")
struct RuleStatusTests {

    // MARK: - Raw Value Tests

    @Test("RuleStatus raw values are correct")
    func rawValues() {
        #expect(RuleStatus.passed.rawValue == "passed")
        #expect(RuleStatus.failed.rawValue == "failed")
        #expect(RuleStatus.warning.rawValue == "warning")
        #expect(RuleStatus.error.rawValue == "error")
    }

    @Test("All RuleStatus cases have unique raw values")
    func uniqueRawValues() {
        let statuses: [RuleStatus] = [.passed, .failed, .warning, .error]
        let rawValues = statuses.map { $0.rawValue }
        let uniqueValues = Set(rawValues)

        #expect(rawValues.count == uniqueValues.count)
    }

    // MARK: - Codable Tests

    @Test("RuleStatus is Codable - passed")
    func encodePassed() throws {
        let status = RuleStatus.passed

        let encoder = JSONEncoder()
        let data = try encoder.encode(status)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RuleStatus.self, from: data)

        #expect(decoded == status)
    }

    @Test("RuleStatus is Codable - failed")
    func encodeFailed() throws {
        let status = RuleStatus.failed

        let encoder = JSONEncoder()
        let data = try encoder.encode(status)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RuleStatus.self, from: data)

        #expect(decoded == status)
    }

    @Test("RuleStatus is Codable - warning")
    func encodeWarning() throws {
        let status = RuleStatus.warning

        let encoder = JSONEncoder()
        let data = try encoder.encode(status)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RuleStatus.self, from: data)

        #expect(decoded == status)
    }

    @Test("RuleStatus is Codable - error")
    func encodeError() throws {
        let status = RuleStatus.error

        let encoder = JSONEncoder()
        let data = try encoder.encode(status)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RuleStatus.self, from: data)

        #expect(decoded == status)
    }

    @Test("RuleStatus JSON encoding produces expected format")
    func jsonFormat() throws {
        let status = RuleStatus.passed

        let encoder = JSONEncoder()
        let data = try encoder.encode(status)
        let jsonString = String(data: data, encoding: .utf8)

        #expect(jsonString == "\"passed\"")
    }

    @Test("RuleStatus can be decoded from JSON string")
    func decodeFromJSON() throws {
        let jsonString = "\"failed\""
        let data = jsonString.data(using: .utf8)!

        let decoder = JSONDecoder()
        let status = try decoder.decode(RuleStatus.self, from: data)

        #expect(status == .failed)
    }

    // MARK: - Sendable Conformance

    @Test("RuleStatus is Sendable")
    func isSendable() {
        let status = RuleStatus.passed

        Task {
            let _ = status
            #expect(true)
        }
    }

    // MARK: - Equatable Tests

    @Test("RuleStatus equality - same values")
    func equalitySame() {
        #expect(RuleStatus.passed == RuleStatus.passed)
        #expect(RuleStatus.failed == RuleStatus.failed)
        #expect(RuleStatus.warning == RuleStatus.warning)
        #expect(RuleStatus.error == RuleStatus.error)
    }

    @Test("RuleStatus inequality - different values")
    func inequalityDifferent() {
        #expect(RuleStatus.passed != RuleStatus.failed)
        #expect(RuleStatus.warning != RuleStatus.error)
        #expect(RuleStatus.passed != RuleStatus.warning)
    }

    // MARK: - All Cases

    @Test("All RuleStatus cases are covered")
    func allCases() {
        let allStatuses: [RuleStatus] = [.passed, .failed, .warning, .error]
        #expect(allStatuses.count == 4)
    }
}
