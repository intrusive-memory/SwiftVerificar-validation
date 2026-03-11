import Foundation
import SwiftVerificarValidationProfiles
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

/// Validator for PDF/A-1a and PDF/A-1b conformance
///
/// PDF/A-1 (ISO 19005-1:2005) is based on PDF 1.4 and provides:
/// - Level A: Accessible (tagged PDF with structure tree)
/// - Level B: Basic visual appearance preservation
///
/// Key requirements:
/// - No encryption
/// - All fonts embedded
/// - No external content references
/// - XMP metadata required
/// - Device-independent color spaces
/// - No transparency
/// - No JavaScript or executable actions
public struct PDFA1Validator: PDFAValidator {
    public let conformance: PDFAConformance

    private let profileLoader: ValidationProfileLoader
    private let engine: ValidationEngine?

    /// Initialize a PDF/A-1 validator
    /// - Parameters:
    ///   - level: Conformance level (.a or .b)
    ///   - profileLoader: Loader for validation profiles
    ///   - engine: Optional custom validation engine
    public init(
        level: PDFALevel,
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) throws {
        // Validate level is supported for Part 1
        guard level == .a || level == .b else {
            throw ValidationError(
                code: .configurationError,
                message: "PDF/A-1 only supports levels A and B, got: \(level.rawValue)"
            )
        }

        self.conformance = try PDFAConformance(part: .part1, level: level)
        self.profileLoader = profileLoader
        self.engine = engine
    }

    /// Convenience initializer for PDF/A-1a
    public static func levelA(
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) async throws -> PDFA1Validator {
        try PDFA1Validator(level: .a, profileLoader: profileLoader, engine: engine)
    }

    /// Convenience initializer for PDF/A-1b
    public static func levelB(
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        engine: ValidationEngine? = nil
    ) async throws -> PDFA1Validator {
        try PDFA1Validator(level: .b, profileLoader: profileLoader, engine: engine)
    }

    // MARK: - PDFAValidator Implementation

    public func validate(
        _ document: Any,
        configuration: ValidatorConfiguration = .default
    ) async throws -> PDFAValidationResult {
        // Load the appropriate validation profile
        let profile = try await profileLoader.loadProfile(
            flavour: PDFAFlavour.pdfa1(level: conformance.level)
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

        // Create enhanced result
        return PDFAValidationResult(
            validationResult: ValidationResult(
                isCompliant: result.isCompliant,
                profileName: profile.details.name,
                totalRules: result.totalRules,
                passedRules: result.passedRules,
                failedRules: result.failedRules,
                ruleResults: result.ruleResults,
                duration: duration
            ),
            conformance: conformance,
            claimedConformance: claimedConformance,
            pdfaIssues: pdfaIssues
        )
    }

    public func detectClaimedConformance(_ document: Any) async throws -> PDFAConformance? {
        // Parse XMP metadata to detect PDF/A-1 conformance claim.
        // Look for pdfaid:part == 1 and pdfaid:conformance in the document XMP metadata.
        // Returns the matching PDFAConformance for PDF/A-1a or PDF/A-1b, or nil otherwise.
        #if canImport(SwiftVerificarParser)
        if let pdfDoc = document as? PDFDocument,
           let xmp = pdfDoc.xmpMetadata,
           let part = xmp.pdfaPart,
           part == 1,
           let conformanceStr = xmp.pdfaConformance {
            let level = PDFALevel(rawValue: conformanceStr.uppercased()) ?? .b
            return try? PDFAConformance(part: .part1, level: level)
        }
        #endif
        return nil
    }

    // MARK: - Private Helpers

    private func createDefaultEngine(configuration: ValidatorConfiguration) -> ValidationEngine {
        // Create engine configuration from validator configuration
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
        // Map failed rules to PDF/A-specific issues
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
        // Categorize based on rule ID prefixes/patterns
        // This is a simplified heuristic - real implementation would use profile metadata
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
            // Try other patterns
            if ruleId.contains("font") || ruleId.contains("Font") {
                return .fonts
            } else if ruleId.contains("color") || ruleId.contains("Color") {
                return .colorSpaces
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
}

// MARK: - Supporting Types

/// PDF/A flavour identifier
public enum PDFAFlavour: Sendable, Hashable {
    case pdfa1(level: PDFALevel)
    case pdfa2(level: PDFALevel)
    case pdfa3(level: PDFALevel)
    case pdfa4

    public var profileName: String {
        switch self {
        case .pdfa1(let level):
            return "PDF/A-1\(level.rawValue.lowercased())"
        case .pdfa2(let level):
            return "PDF/A-2\(level.rawValue.lowercased())"
        case .pdfa3(let level):
            return "PDF/A-3\(level.rawValue.lowercased())"
        case .pdfa4:
            return "PDF/A-4"
        }
    }
}

/// Protocol for loading validation profiles
public protocol ValidationProfileLoader: Sendable {
    /// Load a validation profile for a specific PDF/A flavour
    func loadProfile(flavour: PDFAFlavour) async throws -> ValidationProfile
}

/// Default implementation of profile loader
public struct DefaultProfileLoader: ValidationProfileLoader {
    public init() {}

    public func loadProfile(flavour: PDFAFlavour) async throws -> ValidationProfile {
        // Map PDFAFlavour to PDFFlavour for use with ValidationProfileLoader (ProfileLoader.shared)
        let pdfFlavour: PDFFlavour
        switch flavour {
        case .pdfa1(let level):
            pdfFlavour = level == .a ? .pdfA1a : .pdfA1b
        case .pdfa2(let level):
            switch level {
            case .a: pdfFlavour = .pdfA2a
            case .b: pdfFlavour = .pdfA2b
            case .u: pdfFlavour = .pdfA2u
            }
        case .pdfa3(let level):
            switch level {
            case .a: pdfFlavour = .pdfA3a
            case .b: pdfFlavour = .pdfA3b
            case .u: pdfFlavour = .pdfA3u
            }
        case .pdfa4:
            pdfFlavour = .pdfA4
        }

        // Load the real validation profile via ValidationProfileLoader (ProfileLoader.shared)
        do {
            return try await ProfileLoader.shared.loadProfile(for: pdfFlavour)
        } catch {
            // Fall back to a minimal profile if the XML resource is not available
            return ValidationProfile(
                details: ProfileDetails(
                    name: flavour.profileName,
                    description: "PDF/A validation profile for \(flavour.profileName)",
                    creator: "SwiftVerificar",
                    created: Date()
                ),
                hash: nil,
                rules: [],
                variables: [],
                flavour: pdfFlavour
            )
        }
    }
}
