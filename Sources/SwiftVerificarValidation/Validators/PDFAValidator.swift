import Foundation
import SwiftVerificarValidationProfiles

// MARK: - PDF/A Conformance Levels

/// PDF/A standard part (version)
public enum PDFAPart: String, Sendable, Codable, CaseIterable {
    case part1 = "1"
    case part2 = "2"
    case part3 = "3"
    case part4 = "4"

    /// Description of the PDF/A part
    public var description: String {
        switch self {
        case .part1: return "PDF/A-1 (ISO 19005-1:2005)"
        case .part2: return "PDF/A-2 (ISO 19005-2:2011)"
        case .part3: return "PDF/A-3 (ISO 19005-3:2012)"
        case .part4: return "PDF/A-4 (ISO 19005-4:2020)"
        }
    }
}

/// PDF/A conformance level
public enum PDFALevel: String, Sendable, Codable {
    /// Level A - Accessible (tagged PDF with structure tree)
    case a = "A"

    /// Level B - Basic (visual appearance preservable)
    case b = "B"

    /// Level U - Unicode (PDF/A-2 and above, text extractable)
    case u = "U"

    /// Description of the conformance level
    public var description: String {
        switch self {
        case .a: return "Level A - Accessible"
        case .b: return "Level B - Basic"
        case .u: return "Level U - Unicode"
        }
    }

    /// Whether this level requires accessibility features
    public var requiresAccessibility: Bool {
        self == .a
    }

    /// Whether this level requires Unicode mapping
    public var requiresUnicode: Bool {
        self == .u || self == .a
    }
}

/// Complete PDF/A conformance specification
public struct PDFAConformance: Sendable, Hashable, Codable {
    /// The PDF/A part (version)
    public let part: PDFAPart

    /// The conformance level
    public let level: PDFALevel

    /// The profile identifier (e.g., "1b", "2a", "3u")
    public var profileId: String {
        "\(part.rawValue)\(level.rawValue.lowercased())"
    }

    /// The full conformance identifier (e.g., "PDF/A-1b")
    public var identifier: String {
        "PDF/A-\(profileId)"
    }

    public init(part: PDFAPart, level: PDFALevel) throws {
        // Validate conformance level for part
        try Self.validateConformance(part: part, level: level)
        self.part = part
        self.level = level
    }

    /// Validate that a conformance level is valid for a given part
    private static func validateConformance(part: PDFAPart, level: PDFALevel) throws {
        switch (part, level) {
        case (.part1, .a), (.part1, .b):
            return // Valid
        case (.part2, .a), (.part2, .b), (.part2, .u):
            return // Valid
        case (.part3, .a), (.part3, .b), (.part3, .u):
            return // Valid
        case (.part4, _):
            // PDF/A-4 uses different level naming, but we support mapping
            return
        default:
            throw ValidationError(
                code: .configurationError,
                message: "Invalid conformance: PDF/A-\(part.rawValue) does not support level \(level.rawValue)"
            )
        }
    }

    // Predefined conformances
    public static let pdf1a = try! PDFAConformance(part: .part1, level: .a)
    public static let pdf1b = try! PDFAConformance(part: .part1, level: .b)
    public static let pdf2a = try! PDFAConformance(part: .part2, level: .a)
    public static let pdf2b = try! PDFAConformance(part: .part2, level: .b)
    public static let pdf2u = try! PDFAConformance(part: .part2, level: .u)
    public static let pdf3a = try! PDFAConformance(part: .part3, level: .a)
    public static let pdf3b = try! PDFAConformance(part: .part3, level: .b)
    public static let pdf3u = try! PDFAConformance(part: .part3, level: .u)
    public static let pdf4 = try! PDFAConformance(part: .part4, level: .b)
}

// MARK: - PDF/A Validator Protocol

/// Protocol for PDF/A validators
///
/// PDF/A validators check PDF documents for conformance to specific
/// PDF/A standards (ISO 19005 series).
public protocol PDFAValidator: ValidationEngine {
    /// The PDF/A conformance level this validator checks
    var conformance: PDFAConformance { get }

    /// Validate a PDF document against the PDF/A standard
    /// - Parameters:
    ///   - document: The PDF document to validate (parser-provided type)
    ///   - configuration: Optional validation configuration
    /// - Returns: Validation result with conformance status
    func validate(
        _ document: Any,
        configuration: ValidatorConfiguration
    ) async throws -> PDFAValidationResult

    /// Quick check if document claims PDF/A conformance in metadata
    /// - Parameter document: The PDF document to check
    /// - Returns: The claimed conformance, if any
    func detectClaimedConformance(_ document: Any) async throws -> PDFAConformance?
}

// MARK: - PDF/A Validation Result

/// Result of PDF/A validation
public struct PDFAValidationResult: Sendable {
    /// The base validation result
    public let validationResult: ValidationResult

    /// The PDF/A conformance level validated against
    public let conformance: PDFAConformance

    /// The PDF/A conformance claimed in document metadata (if any)
    public let claimedConformance: PDFAConformance?

    /// Whether the document is PDF/A compliant
    public var isCompliant: Bool {
        validationResult.isCompliant
    }

    /// Whether claimed conformance matches validated conformance
    public var conformanceMatches: Bool {
        guard let claimed = claimedConformance else { return false }
        return claimed == conformance
    }

    /// Issues specific to PDF/A conformance
    public let pdfaIssues: [PDFAIssue]

    public init(
        validationResult: ValidationResult,
        conformance: PDFAConformance,
        claimedConformance: PDFAConformance? = nil,
        pdfaIssues: [PDFAIssue] = []
    ) {
        self.validationResult = validationResult
        self.conformance = conformance
        self.claimedConformance = claimedConformance
        self.pdfaIssues = pdfaIssues
    }
}

/// Specific PDF/A conformance issue
public struct PDFAIssue: Sendable, Identifiable {
    public let id: UUID

    /// Issue category
    public let category: PDFAIssueCategory

    /// Description of the issue
    public let description: String

    /// Location in document where issue was found
    public let location: String?

    /// Severity of the issue
    public let severity: IssueSeverity

    /// Related rule ID from validation profile
    public let ruleId: String?

    public init(
        id: UUID = UUID(),
        category: PDFAIssueCategory,
        description: String,
        location: String? = nil,
        severity: IssueSeverity = .error,
        ruleId: String? = nil
    ) {
        self.id = id
        self.category = category
        self.description = description
        self.location = location
        self.severity = severity
        self.ruleId = ruleId
    }

    public enum IssueSeverity: String, Sendable, Codable {
        case error
        case warning
        case info
    }
}

/// Categories of PDF/A conformance issues
public enum PDFAIssueCategory: String, Sendable, Codable {
    case fileStructure = "File Structure"
    case graphics = "Graphics"
    case fonts = "Fonts"
    case transparency = "Transparency"
    case annotations = "Annotations"
    case actions = "Actions"
    case metadata = "Metadata"
    case logicalStructure = "Logical Structure"
    case embeddedFiles = "Embedded Files"
    case colorSpaces = "Color Spaces"
    case encryption = "Encryption"
}

// MARK: - Default PDFAValidator Extension

extension PDFAValidator {
    /// Default implementation of ValidationEngine.validate
    public func validate(
        _ document: Any,
        profile: ValidationProfile
    ) async throws -> ValidationResult {
        let result = try await validate(document, configuration: .default)
        // Use the provided profile's name instead of the internal profile name
        return ValidationResult(
            isCompliant: result.validationResult.isCompliant,
            profileName: profile.details.name,
            totalRules: result.validationResult.totalRules,
            passedRules: result.validationResult.passedRules,
            failedRules: result.validationResult.failedRules,
            ruleResults: result.validationResult.ruleResults,
            duration: result.validationResult.duration
        )
    }

    /// Validate with default configuration
    public func validate(_ document: Any) async throws -> PDFAValidationResult {
        try await validate(document, configuration: .default)
    }
}
