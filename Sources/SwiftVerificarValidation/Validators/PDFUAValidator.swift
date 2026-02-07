import Foundation
import SwiftVerificarValidationProfiles

// MARK: - PDF/UA Standard Parts

/// PDF/UA standard part (version)
public enum PDFUAPart: String, Sendable, Codable, CaseIterable {
    /// PDF/UA-1 (ISO 14289-1:2014) - First generation universal accessibility
    case part1 = "1"

    /// PDF/UA-2 (ISO 14289-2:2024) - Second generation universal accessibility (PDF 2.0 based)
    case part2 = "2"

    /// Description of the PDF/UA part
    public var description: String {
        switch self {
        case .part1: return "PDF/UA-1 (ISO 14289-1:2014)"
        case .part2: return "PDF/UA-2 (ISO 14289-2:2024)"
        }
    }

    /// ISO standard reference
    public var isoReference: String {
        switch self {
        case .part1: return "ISO 14289-1:2014"
        case .part2: return "ISO 14289-2:2024"
        }
    }

    /// Base PDF version required for this PDF/UA part
    public var basePDFVersion: String {
        switch self {
        case .part1: return "1.4" // PDF/UA-1 based on PDF 1.4-1.7
        case .part2: return "2.0" // PDF/UA-2 based on PDF 2.0
        }
    }
}

// MARK: - PDF/UA Conformance

/// Complete PDF/UA conformance specification
public struct PDFUAConformance: Sendable, Hashable, Codable {
    /// The PDF/UA part (version)
    public let part: PDFUAPart

    /// The profile identifier (e.g., "1", "2")
    public var profileId: String {
        part.rawValue
    }

    /// The full conformance identifier (e.g., "PDF/UA-1")
    public var identifier: String {
        "PDF/UA-\(part.rawValue)"
    }

    /// ISO standard reference
    public var isoReference: String {
        part.isoReference
    }

    public init(part: PDFUAPart) {
        self.part = part
    }

    // Predefined conformances
    public static let pdfua1 = PDFUAConformance(part: .part1)
    public static let pdfua2 = PDFUAConformance(part: .part2)
}

// MARK: - PDF/UA Validator Protocol

/// Protocol for PDF/UA (Universal Accessibility) validators
///
/// PDF/UA validators check PDF documents for conformance to universal
/// accessibility standards (ISO 14289 series).
public protocol PDFUAValidator: ValidationEngine {
    /// The PDF/UA conformance level this validator checks
    var conformance: PDFUAConformance { get }

    /// Validate a PDF document against the PDF/UA standard
    /// - Parameters:
    ///   - document: The PDF document to validate (parser-provided type)
    ///   - configuration: Optional validation configuration
    /// - Returns: Validation result with conformance status
    func validate(
        _ document: Any,
        configuration: ValidatorConfiguration
    ) async throws -> PDFUAValidationResult

    /// Quick check if document claims PDF/UA conformance in metadata
    /// - Parameter document: The PDF document to check
    /// - Returns: The claimed conformance, if any
    func detectClaimedConformance(_ document: Any) async throws -> PDFUAConformance?
}

// MARK: - PDF/UA Validation Result

/// Result of PDF/UA validation
public struct PDFUAValidationResult: Sendable {
    /// The base validation result
    public let validationResult: ValidationResult

    /// The PDF/UA conformance level validated against
    public let conformance: PDFUAConformance

    /// The PDF/UA conformance claimed in document metadata (if any)
    public let claimedConformance: PDFUAConformance?

    /// Whether the document is PDF/UA compliant
    public var isCompliant: Bool {
        validationResult.isCompliant
    }

    /// Whether claimed conformance matches validated conformance
    public var conformanceMatches: Bool {
        guard let claimed = claimedConformance else { return false }
        return claimed == conformance
    }

    /// Issues specific to PDF/UA conformance
    public let pdfuaIssues: [PDFUAIssue]

    /// Accessibility feature summary
    public let accessibilityFeatures: AccessibilityFeatures

    public init(
        validationResult: ValidationResult,
        conformance: PDFUAConformance,
        claimedConformance: PDFUAConformance? = nil,
        pdfuaIssues: [PDFUAIssue] = [],
        accessibilityFeatures: AccessibilityFeatures = AccessibilityFeatures()
    ) {
        self.validationResult = validationResult
        self.conformance = conformance
        self.claimedConformance = claimedConformance
        self.pdfuaIssues = pdfuaIssues
        self.accessibilityFeatures = accessibilityFeatures
    }
}

// MARK: - PDF/UA Issue

/// Specific PDF/UA conformance issue
public struct PDFUAIssue: Sendable, Identifiable {
    public let id: UUID

    /// Issue category
    public let category: PDFUAIssueCategory

    /// Description of the issue
    public let description: String

    /// Location in document where issue was found
    public let location: String?

    /// Severity of the issue
    public let severity: IssueSeverity

    /// Related rule ID from validation profile
    public let ruleId: String?

    /// WCAG success criterion reference (if applicable)
    public let wcagCriterion: String?

    public init(
        id: UUID = UUID(),
        category: PDFUAIssueCategory,
        description: String,
        location: String? = nil,
        severity: IssueSeverity = .error,
        ruleId: String? = nil,
        wcagCriterion: String? = nil
    ) {
        self.id = id
        self.category = category
        self.description = description
        self.location = location
        self.severity = severity
        self.ruleId = ruleId
        self.wcagCriterion = wcagCriterion
    }

    public enum IssueSeverity: String, Sendable, Codable {
        case error
        case warning
        case info
    }
}

/// Categories of PDF/UA conformance issues
public enum PDFUAIssueCategory: String, Sendable, Codable {
    case documentMetadata = "Document Metadata"
    case taggedStructure = "Tagged Structure"
    case readingOrder = "Reading Order"
    case alternativeText = "Alternative Text"
    case languageSpecification = "Language Specification"
    case navigationAids = "Navigation Aids"
    case tableStructure = "Table Structure"
    case listStructure = "List Structure"
    case headings = "Headings"
    case annotations = "Annotations"
    case formFields = "Form Fields"
    case embeddedFiles = "Embedded Files"
    case multimedia = "Multimedia"
    case security = "Security"
    case fonts = "Fonts"
    case colorAndContrast = "Color and Contrast"
    case semanticStructure = "Semantic Structure"
}

// MARK: - Accessibility Features

/// Summary of accessibility features found in a PDF document
public struct AccessibilityFeatures: Sendable {
    /// Whether the document has a structure tree (tagged PDF)
    public var hasStructureTree: Bool = false

    /// Whether the document has marked content
    public var hasMarkedContent: Bool = false

    /// Whether the document specifies a language
    public var hasLanguageSpecification: Bool = false

    /// Whether the document has alternative text for images
    public var hasAlternativeText: Bool = false

    /// Whether the document has accessible form fields
    public var hasAccessibleForms: Bool = false

    /// Whether the document has accessible tables
    public var hasAccessibleTables: Bool = false

    /// Whether the document has a logical reading order
    public var hasLogicalReadingOrder: Bool = false

    /// Whether the document has navigation aids (bookmarks, links)
    public var hasNavigationAids: Bool = false

    /// Number of headings found
    public var headingCount: Int = 0

    /// Number of tables found
    public var tableCount: Int = 0

    /// Number of lists found
    public var listCount: Int = 0

    /// Number of form fields found
    public var formFieldCount: Int = 0

    /// Number of annotations found
    public var annotationCount: Int = 0

    public init() {}
}

// MARK: - Default PDFUAValidator Extension

extension PDFUAValidator {
    /// Default implementation of ValidationEngine.validate
    public func validate(
        _ document: Any,
        profile: ValidationProfile
    ) async throws -> ValidationResult {
        let result = try await validate(document, configuration: .default)
        return result.validationResult
    }

    /// Validate with default configuration
    public func validate(_ document: Any) async throws -> PDFUAValidationResult {
        try await validate(document, configuration: .default)
    }
}
