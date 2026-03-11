import Foundation
import SwiftVerificarValidationProfiles
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

/// Validator for PDF/A-3a, PDF/A-3b, and PDF/A-3u conformance
///
/// PDF/A-3 (ISO 19005-3:2012) is based on PDF 1.7 (like PDF/A-2) and provides:
/// - Level A: Accessible (tagged PDF with structure tree)
/// - Level B: Basic visual appearance preservation
/// - Level U: Unicode mapping (text extractable)
///
/// Key feature over PDF/A-2:
/// - Allows embedding of arbitrary file formats (not just PDF/A)
/// - Enables workflows like ZUGFeRD (embedded XML invoices)
/// - Associated files with AF (Associated Files) relationship
///
/// All PDF/A-2 requirements apply, plus:
/// - Embedded files must have correct MIME types
/// - Associated files must use AF relationship
/// - File specification dictionaries required
public struct PDFA3Validator: PDFAValidator {
    public let conformance: PDFAConformance

    private let profileLoader: ValidationProfileLoader
    private let engine: ValidationEngine?

    /// Initialize a PDF/A-3 validator
    /// - Parameters:
    ///   - level: Conformance level (.a, .b, or .u)
    ///   - profileLoader: Loader for validation profiles
    ///   - engine: Optional custom validation engine
    public init(
        level: PDFALevel,
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) throws {
        // All levels are valid for Part 3
        self.conformance = try PDFAConformance(part: .part3, level: level)
        self.profileLoader = profileLoader
        self.engine = engine
    }

    /// Convenience initializer for PDF/A-3a
    public static func levelA(
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) async throws -> PDFA3Validator {
        try PDFA3Validator(level: .a, profileLoader: profileLoader, engine: engine)
    }

    /// Convenience initializer for PDF/A-3b
    public static func levelB(
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) async throws -> PDFA3Validator {
        try PDFA3Validator(level: .b, profileLoader: profileLoader, engine: engine)
    }

    /// Convenience initializer for PDF/A-3u
    public static func levelU(
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) async throws -> PDFA3Validator {
        try PDFA3Validator(level: .u, profileLoader: profileLoader, engine: engine)
    }

    // MARK: - PDFAValidator Implementation

    public func validate(
        _ document: Any,
        configuration: ValidatorConfiguration = .default
    ) async throws -> PDFAValidationResult {
        // Load the appropriate validation profile
        let profile = try await profileLoader.loadProfile(
            flavour: PDFAFlavour.pdfa3(level: conformance.level)
        )

        // Get or create validation engine
        let validationEngine: ValidationEngine
        if let engine = engine {
            validationEngine = engine
        } else {
            validationEngine = createDefaultEngine(configuration: configuration)
        }

        // Perform validation
        let startTime = Date()
        let result = try await validationEngine.validate(document, profile: profile)
        let duration = Date().timeIntervalSince(startTime)

        // Detect claimed conformance
        let claimedConformance = try await detectClaimedConformance(document)

        // Extract PDF/A-specific issues
        let pdfaIssues = extractPDFAIssues(from: result, profile: profile)

        // Add PDF/A-3 specific checks
        let additionalIssues = await performPDFA3SpecificChecks(document)

        // Create enhanced result
        return PDFAValidationResult(
            validationResult: ValidationResult(
                isCompliant: result.isCompliant && additionalIssues.isEmpty,
                profileName: profile.details.name,
                totalRules: result.totalRules + additionalIssues.count,
                passedRules: result.passedRules,
                failedRules: result.failedRules + additionalIssues.count,
                ruleResults: result.ruleResults,
                duration: duration
            ),
            conformance: conformance,
            claimedConformance: claimedConformance,
            pdfaIssues: pdfaIssues + additionalIssues
        )
    }

    public func detectClaimedConformance(_ document: Any) async throws -> PDFAConformance? {
        // Parse XMP metadata to detect PDF/A-3 conformance claim.
        // Look for pdfaid:part == 3 and pdfaid:conformance in the document XMP metadata.
        // Returns the matching PDFAConformance (PDF/A-3a, 3b, or 3u), or nil if not claimed.
        #if canImport(SwiftVerificarParser)
        if let pdfDoc = document as? PDFDocument,
           let xmp = pdfDoc.xmpMetadata,
           let part = xmp.pdfaPart,
           part == 3,
           let conformanceStr = xmp.pdfaConformance {
            let level = PDFALevel(rawValue: conformanceStr.uppercased()) ?? .b
            return try? PDFAConformance(part: .part3, level: level)
        }
        #endif
        return nil
    }

    // MARK: - Private Helpers

    private func createDefaultEngine(configuration: ValidatorConfiguration) -> ValidationEngine {
        let engineConfig = PDFValidationEngine.Configuration(
            enableParallelValidation: configuration.enableParallelValidation,
            maxConcurrentTasks: configuration.maxConcurrentTasks,
            validationTimeout: configuration.validationTimeout,
            customMetadata: configuration.customMetadata
        )
        return PDFValidationEngine(configuration: engineConfig)
    }

    private func extractPDFAIssues(
        from result: ValidationResult,
        profile: ValidationProfile
    ) -> [PDFAIssue] {
        result.ruleResults
            .filter { $0.status == .failed }
            .compactMap { ruleResult -> PDFAIssue? in
                guard let category = categorizeRule(ruleResult.ruleId, profile: profile) else {
                    return nil
                }

                return PDFAIssue(
                    category: category,
                    description: ruleResult.message ?? "Rule \(ruleResult.ruleId) failed",
                    location: ruleResult.context,
                    severity: .error,
                    ruleId: ruleResult.ruleId
                )
            }
    }

    private func categorizeRule(_ ruleId: String, profile: ValidationProfile) -> PDFAIssueCategory? {
        // Categorize based on rule ID prefixes (ISO 19005-3 structure)
        switch ruleId.prefix(2) {
        case "6.1": return .fileStructure
        case "6.2": return .graphics
        case "6.3": return .fonts
        case "6.4": return .transparency
        case "6.5": return .annotations
        case "6.6": return .actions
        case "6.7": return .metadata
        case "6.8": return .logicalStructure
        case "6.9": return .embeddedFiles
        default:
            if ruleId.contains("file") || ruleId.contains("File") || ruleId.contains("embed") {
                return .embeddedFiles
            } else if ruleId.contains("font") || ruleId.contains("Font") {
                return .fonts
            } else if ruleId.contains("color") || ruleId.contains("Color") {
                return .colorSpaces
            } else if ruleId.contains("transparency") || ruleId.contains("Transparency") {
                return .transparency
            } else if ruleId.contains("metadata") || ruleId.contains("XMP") {
                return .metadata
            } else if ruleId.contains("encrypt") || ruleId.contains("Encrypt") {
                return .encryption
            } else if ruleId.contains("annot") || ruleId.contains("Annot") {
                return .annotations
            } else if ruleId.contains("structure") || ruleId.contains("tag") {
                return .logicalStructure
            }
            return .fileStructure
        }
    }

    private func performPDFA3SpecificChecks(_ document: Any) async -> [PDFAIssue] {
        let issues: [PDFAIssue] = []

        // PDF/A-3 specific validation checks
        // These would be implemented when parser is available

        // Check embedded files have proper file specifications
        // Validate MIME types for embedded files
        // Check AF (Associated Files) relationships
        // Validate file attachment annotations
        // Check EmbeddedFiles name tree

        // All PDF/A-2 checks also apply
        // (would inherit from PDFA2Validator in a production implementation)

        return issues
    }

    // MARK: - Embedded File Validation

    /// Validate embedded files in PDF/A-3 document
    /// PDF/A-3 allows arbitrary file formats to be embedded
    private func validateEmbeddedFiles(_ document: Any) async -> [PDFAIssue] {
        let issues: [PDFAIssue] = []

        // Check for:
        // 1. Proper file specification dictionary
        // 2. MIME type (Subtype entry)
        // 3. AF relationship if using associated files
        // 4. Description (Desc entry) for accessibility (level A)

        // This would be implemented when parser provides embedded file access

        return issues
    }
}
