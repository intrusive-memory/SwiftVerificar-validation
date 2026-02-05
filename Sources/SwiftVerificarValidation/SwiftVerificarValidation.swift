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

// MARK: - Validation Error

/// Error that occurs during PDF validation
public struct ValidationError: Error, Sendable, CustomStringConvertible {
    /// The error code identifying the type of error
    public let code: ErrorCode

    /// A human-readable description of the error
    public let message: String

    /// Optional context information about where the error occurred
    public let context: ValidationContext?

    /// The underlying error that caused this validation error, if any
    public let underlyingError: (any Error)?

    public init(
        code: ErrorCode,
        message: String,
        context: ValidationContext? = nil,
        underlyingError: (any Error)? = nil
    ) {
        self.code = code
        self.message = message
        self.context = context
        self.underlyingError = underlyingError
    }

    public var description: String {
        var desc = "ValidationError(\(code.rawValue)): \(message)"
        if let context = context {
            desc += " [Context: \(context)]"
        }
        if let underlying = underlyingError {
            desc += " [Underlying: \(underlying)]"
        }
        return desc
    }

    /// Error codes for validation failures
    public enum ErrorCode: String, Sendable, Codable {
        /// Document parsing failed
        case parsingFailed

        /// Profile loading failed
        case profileLoadFailed

        /// Rule execution failed
        case ruleExecutionFailed

        /// Invalid document structure
        case invalidStructure

        /// Missing required metadata
        case missingMetadata

        /// Invalid object reference
        case invalidReference

        /// Unsupported feature
        case unsupportedFeature

        /// Configuration error
        case configurationError

        /// Internal validation engine error
        case internalError
    }
}

// MARK: - Validation Context

/// Context information for validation errors
public struct ValidationContext: Sendable, CustomStringConvertible {
    /// The object being validated (e.g., "Page 3", "Font /F1")
    public let objectIdentifier: String

    /// The rule ID that triggered the error, if applicable
    public let ruleId: String?

    /// The location in the PDF file (page number, object number, etc.)
    public let location: String?

    /// Additional metadata about the context
    public let metadata: [String: String]

    public init(
        objectIdentifier: String,
        ruleId: String? = nil,
        location: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.objectIdentifier = objectIdentifier
        self.ruleId = ruleId
        self.location = location
        self.metadata = metadata
    }

    public var description: String {
        var parts: [String] = [objectIdentifier]
        if let ruleId = ruleId {
            parts.append("rule=\(ruleId)")
        }
        if let location = location {
            parts.append("location=\(location)")
        }
        if !metadata.isEmpty {
            let metaStr = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            parts.append(metaStr)
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Validator Configuration

/// Configuration options for PDF validation
public struct ValidatorConfiguration: Sendable {
    /// Whether to stop validation on the first error
    public let stopOnFirstError: Bool

    /// Maximum number of errors to collect before stopping
    public let maxErrors: Int?

    /// Whether to include warnings in validation results
    public let includeWarnings: Bool

    /// Whether to perform detailed feature reporting
    public let enableFeatureReporting: Bool

    /// Whether to enable parallel rule evaluation
    public let enableParallelValidation: Bool

    /// Maximum number of concurrent validation tasks
    public let maxConcurrentTasks: Int

    /// Timeout for validation in seconds
    public let validationTimeout: TimeInterval?

    /// Custom metadata to include in validation results
    public let customMetadata: [String: String]

    /// Logging level for validation operations
    public let loggingLevel: LoggingLevel

    public init(
        stopOnFirstError: Bool = false,
        maxErrors: Int? = nil,
        includeWarnings: Bool = true,
        enableFeatureReporting: Bool = false,
        enableParallelValidation: Bool = true,
        maxConcurrentTasks: Int = 8,
        validationTimeout: TimeInterval? = nil,
        customMetadata: [String: String] = [:],
        loggingLevel: LoggingLevel = .warning
    ) {
        self.stopOnFirstError = stopOnFirstError
        self.maxErrors = maxErrors
        self.includeWarnings = includeWarnings
        self.enableFeatureReporting = enableFeatureReporting
        self.enableParallelValidation = enableParallelValidation
        self.maxConcurrentTasks = maxConcurrentTasks
        self.validationTimeout = validationTimeout
        self.customMetadata = customMetadata
        self.loggingLevel = loggingLevel
    }

    /// Default configuration optimized for quick validation
    public static let fast = ValidatorConfiguration(
        stopOnFirstError: true,
        enableFeatureReporting: false,
        enableParallelValidation: true,
        maxConcurrentTasks: 16
    )

    /// Default configuration optimized for thorough validation
    public static let thorough = ValidatorConfiguration(
        stopOnFirstError: false,
        includeWarnings: true,
        enableFeatureReporting: true,
        enableParallelValidation: true,
        maxConcurrentTasks: 8
    )

    /// Default configuration with conservative settings
    public static let `default` = ValidatorConfiguration()

    /// Logging level for validation operations
    public enum LoggingLevel: String, Sendable, Codable {
        case none
        case error
        case warning
        case info
        case debug
    }
}
