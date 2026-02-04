import Foundation

/// SwiftVerificarValidation - PDF validation engine for SwiftVerificar
///
/// Swift port of veraPDF-validation providing rule execution,
/// feature reporting, and validation result generation.
///
/// - SeeAlso: [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation)
public struct SwiftVerificarValidation {

    /// The current version of the library
    public static let version = "0.1.0"

    /// Creates a new instance of SwiftVerificarValidation
    public init() {}
}

// MARK: - Validation Engine Protocol

/// Protocol for PDF validation engines
public protocol ValidationEngine: Sendable {
    /// Validate a PDF document against a profile
    func validate(_ document: Any, profile: ValidationProfile) async throws -> ValidationResult
}

// MARK: - Validation Profile

/// A validation profile defining rules to check
public struct ValidationProfile: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let rules: [ValidationRule]

    public init(id: String, name: String, description: String, rules: [ValidationRule]) {
        self.id = id
        self.name = name
        self.description = description
        self.rules = rules
    }
}

// MARK: - Validation Rule

/// A single validation rule
public struct ValidationRule: Sendable, Identifiable {
    public let id: String
    public let specification: String
    public let clause: String
    public let testNumber: Int
    public let description: String
    public let objectType: String
    public let test: String
    public let errorMessage: String

    public init(
        id: String,
        specification: String,
        clause: String,
        testNumber: Int,
        description: String,
        objectType: String,
        test: String,
        errorMessage: String
    ) {
        self.id = id
        self.specification = specification
        self.clause = clause
        self.testNumber = testNumber
        self.description = description
        self.objectType = objectType
        self.test = test
        self.errorMessage = errorMessage
    }
}

// MARK: - Validation Result

/// Result of validating a PDF document
public struct ValidationResult: Sendable {
    /// Whether the document is compliant
    public let isCompliant: Bool

    /// The profile used for validation
    public let profileName: String

    /// Total number of rules checked
    public let totalRules: Int

    /// Number of passed rules
    public let passedRules: Int

    /// Number of failed rules
    public let failedRules: Int

    /// Individual rule results
    public let ruleResults: [RuleResult]

    /// Validation duration
    public let duration: TimeInterval

    /// Compliance percentage
    public var compliancePercentage: Double {
        guard totalRules > 0 else { return 100.0 }
        return (Double(passedRules) / Double(totalRules)) * 100.0
    }

    public init(
        isCompliant: Bool,
        profileName: String,
        totalRules: Int,
        passedRules: Int,
        failedRules: Int,
        ruleResults: [RuleResult],
        duration: TimeInterval
    ) {
        self.isCompliant = isCompliant
        self.profileName = profileName
        self.totalRules = totalRules
        self.passedRules = passedRules
        self.failedRules = failedRules
        self.ruleResults = ruleResults
        self.duration = duration
    }
}

// MARK: - Rule Result

/// Result of evaluating a single rule
public struct RuleResult: Sendable, Identifiable {
    public let id: UUID
    public let ruleId: String
    public let status: RuleStatus
    public let message: String?
    public let context: String?

    public init(
        id: UUID = UUID(),
        ruleId: String,
        status: RuleStatus,
        message: String? = nil,
        context: String? = nil
    ) {
        self.id = id
        self.ruleId = ruleId
        self.status = status
        self.message = message
        self.context = context
    }
}

/// Status of a rule evaluation
public enum RuleStatus: String, Sendable, Codable {
    case passed
    case failed
    case warning
    case error
}
