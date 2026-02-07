import Foundation
import SwiftVerificarValidationProfiles

/// Validator for PDF/A-2a, PDF/A-2b, and PDF/A-2u conformance
///
/// PDF/A-2 (ISO 19005-2:2011) is based on PDF 1.7 and provides:
/// - Level A: Accessible (tagged PDF with structure tree)
/// - Level B: Basic visual appearance preservation
/// - Level U: Unicode mapping (text extractable)
///
/// Key improvements over PDF/A-1:
/// - JPEG 2000 compression support
/// - Transparency support
/// - Embedded OpenType fonts
/// - PDF/A collections (portfolios)
/// - Optional content (layers)
/// - Digital signatures
/// - Comments and attachments with PDF/A files
public struct PDFA2Validator: PDFAValidator {
    public let conformance: PDFAConformance

    private let profileLoader: ValidationProfileLoader
    private let engine: ValidationEngine?

    /// Initialize a PDF/A-2 validator
    /// - Parameters:
    ///   - level: Conformance level (.a, .b, or .u)
    ///   - profileLoader: Loader for validation profiles
    ///   - engine: Optional custom validation engine
    public init(
        level: PDFALevel,
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) throws {
        // All levels are valid for Part 2
        self.conformance = try PDFAConformance(part: .part2, level: level)
        self.profileLoader = profileLoader
        self.engine = engine
    }

    /// Convenience initializer for PDF/A-2a
    public static func levelA(
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) async throws -> PDFA2Validator {
        try PDFA2Validator(level: .a, profileLoader: profileLoader, engine: engine)
    }

    /// Convenience initializer for PDF/A-2b
    public static func levelB(
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) async throws -> PDFA2Validator {
        try PDFA2Validator(level: .b, profileLoader: profileLoader, engine: engine)
    }

    /// Convenience initializer for PDF/A-2u
    public static func levelU(
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) async throws -> PDFA2Validator {
        try PDFA2Validator(level: .u, profileLoader: profileLoader, engine: engine)
    }

    // MARK: - PDFAValidator Implementation

    public func validate(
        _ document: Any,
        configuration: ValidatorConfiguration = .default
    ) async throws -> PDFAValidationResult {
        // Load the appropriate validation profile
        let profile = try await profileLoader.loadProfile(
            flavour: PDFAFlavour.pdfa2(level: conformance.level)
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

        // Add PDF/A-2 specific checks
        let additionalIssues = await performPDFA2SpecificChecks(document)

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
        // In a real implementation, this would parse XMP metadata
        // For now, return nil (no claimed conformance detected)
        // TODO: Implement XMP metadata parsing when parser is available
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
        // Categorize based on rule ID prefixes (ISO 19005-2 structure)
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
            if ruleId.contains("font") || ruleId.contains("Font") {
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

    private func performPDFA2SpecificChecks(_ document: Any) async -> [PDFAIssue] {
        var issues: [PDFAIssue] = []

        // PDF/A-2 specific validation checks
        // These would be implemented when parser is available

        // Check for JPEG 2000 compliance
        // Check transparency blend modes
        // Check OpenType font embedding
        // Check optional content configuration
        // Check digital signature compliance

        // Level U specific: Unicode mapping
        if conformance.level == .u {
            // Verify ToUnicode CMaps for all fonts
            // This would be checked via validation rules in production
        }

        return issues
    }
}
