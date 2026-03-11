import Foundation
import SwiftVerificarValidationProfiles
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - PDF/UA-1 Validator

/// PDF/UA-1 (ISO 14289-1:2014) validator
///
/// Validates PDF documents for conformance to PDF/UA-1, the first generation
/// universal accessibility standard. PDF/UA-1 is based on PDF 1.4-1.7 and
/// provides requirements for accessible PDF documents.
///
/// Key requirements validated:
/// - Tagged PDF structure tree
/// - Alternative text for non-text content
/// - Natural language specification
/// - Logical reading order
/// - Accessible table and list structures
/// - Form field accessibility
/// - Navigation aids
public actor PDFUA1Validator: PDFUAValidator {
    // MARK: - Properties

    public nonisolated let conformance: PDFUAConformance = .pdfua1

    /// Validation profile loader
    private let profileLoader: ValidationProfileLoader

    /// Validation configuration
    private var configuration: ValidatorConfiguration

    /// Statistics for the last validation run (removed - tracked in ValidationResult)

    // MARK: - Initialization

    public init(
        profileLoader: ValidationProfileLoader = DefaultProfileLoader(),
        configuration: ValidatorConfiguration = .default
    ) {
        self.profileLoader = profileLoader
        self.configuration = configuration
    }

    // MARK: - PDFUAValidator Protocol

    nonisolated public func validate(
        _ document: Any,
        configuration: ValidatorConfiguration
    ) async throws -> PDFUAValidationResult {
        // Note: Cannot mutate actor-isolated state from nonisolated method
        // Configuration is passed as parameter instead

        // Load PDF/UA-1 validation profile
        let profile = try await loadValidationProfile()

        // Detect claimed conformance from metadata
        let claimedConformance = try await detectClaimedConformance(document)

        // Validate document structure
        let structureIssues = try await validateDocumentStructure(document)

        // Validate tagged content
        let taggedContentIssues = try await validateTaggedContent(document)

        // Validate alternative text
        let alternativeTextIssues = try await validateAlternativeText(document)

        // Validate language specification
        let languageIssues = try await validateLanguageSpecification(document)

        // Validate reading order
        let readingOrderIssues = try await validateReadingOrder(document)

        // Validate navigation aids
        let navigationIssues = try await validateNavigationAids(document)

        // Validate table structures
        let tableIssues = try await validateTableStructures(document)

        // Validate list structures
        let listIssues = try await validateListStructures(document)

        // Validate form fields
        let formIssues = try await validateFormFields(document)

        // Validate annotations
        let annotationIssues = try await validateAnnotations(document)

        // Combine all issues
        let allIssues = structureIssues + taggedContentIssues + alternativeTextIssues +
            languageIssues + readingOrderIssues + navigationIssues +
            tableIssues + listIssues + formIssues + annotationIssues

        // Extract accessibility features
        let features = try await extractAccessibilityFeatures(document)

        // Create base validation result
        let errorCount = allIssues.filter { $0.severity == .error }.count
        let isCompliant = errorCount == 0
        let totalIssues = allIssues.count
        let passedCount = totalIssues - errorCount

        let validationResult = ValidationResult(
            isCompliant: isCompliant,
            profileName: profile.details.name,
            totalRules: totalIssues,
            passedRules: passedCount,
            failedRules: errorCount,
            ruleResults: [], // Will be populated by actual rule evaluation
            duration: 0.0 // Will be measured
        )

        return PDFUAValidationResult(
            validationResult: validationResult,
            conformance: conformance,
            claimedConformance: claimedConformance,
            pdfuaIssues: allIssues,
            accessibilityFeatures: features
        )
    }

    nonisolated public func detectClaimedConformance(_ document: Any) async throws -> PDFUAConformance? {
        // Parse XMP metadata to detect PDF/UA conformance claim.
        // The PDF/UA part number is stored in XMP as pdfuaid:part.
        // ValidatedDocument exposes hasMetadata but not the parsed XMP part number,
        // so we cannot distinguish UA-1 from UA-2 from metadata alone at this layer.
        // Return nil (no claim detected) and rely on structural validation.
        return nil
    }

    nonisolated public func validate(
        _ document: Any,
        profile: ValidationProfile
    ) async throws -> ValidationResult {
        let result = try await validate(document, configuration: configuration)
        return result.validationResult
    }

    // MARK: - Private Validation Methods

    nonisolated private func loadValidationProfile() async throws -> ValidationProfile {
        // Load PDF/UA-1 profile from validation profiles package
        // For now, return a stub profile
        let details = ProfileDetails(
            name: "PDF/UA-1",
            description: "PDF/UA-1 (ISO 14289-1:2014) validation profile",
            creator: "SwiftVerificar",
            created: Date()
        )
        return ValidationProfile(
            details: details,
            rules: [],
            flavour: .pdfUA1
        )
    }

    nonisolated private func validateDocumentStructure(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        if !validatedDoc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document must have a structure tree (StructTreeRoot) — PDF/UA-1 Section 7.1",
                severity: .error,
                ruleId: "7.1-1",
                wcagCriterion: "1.3.1"
            ))
        }

        if !validatedDoc.isMarked {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document MarkInfo dictionary must have Marked = true — PDF/UA-1 Section 7.1",
                severity: .error,
                ruleId: "7.1-2",
                wcagCriterion: "1.3.1"
            ))
        }

        if validatedDoc.hasSuspects {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document MarkInfo/Suspects shall be false or absent — PDF/UA-1 Section 7.1",
                severity: .error,
                ruleId: "7.1-3",
                wcagCriterion: "1.3.1"
            ))
        }

        if validatedDoc.hasStructTreeRoot && validatedDoc.structureElementCount == 0 {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Structure tree root has no child elements — PDF/UA-1 Section 7.1",
                severity: .warning,
                ruleId: "7.1-4",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    nonisolated private func validateTaggedContent(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        for page in validatedDoc.pages {
            if page.hasContentStreams && !validatedDoc.isMarked {
                issues.append(PDFUAIssue(
                    category: .taggedStructure,
                    description: "Page \(page.pageNumber) has content streams but document is not marked — PDF/UA-1 Section 7.1",
                    location: "Page \(page.pageNumber)",
                    severity: .error,
                    ruleId: "7.1-5",
                    wcagCriterion: "1.3.1"
                ))
                break
            }
        }

        return issues
    }

    nonisolated private func validateAlternativeText(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        // Alternative text can only be attached to structure elements.
        // Precondition: structure tree must exist for alt text to be present.
        if !validatedDoc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .alternativeText,
                description: "Cannot validate alternative text: document has no structure tree; figures and formulas must have Alt or ActualText — PDF/UA-1 Section 7.2",
                severity: .error,
                ruleId: "7.2-1",
                wcagCriterion: "1.1.1"
            ))
        }

        return issues
    }

    nonisolated private func validateLanguageSpecification(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        if validatedDoc.language == nil || (validatedDoc.language?.isEmpty ?? true) {
            issues.append(PDFUAIssue(
                category: .languageSpecification,
                description: "Document catalog must have a Lang entry specifying the document language — PDF/UA-1 Section 7.3",
                severity: .error,
                ruleId: "7.3-1",
                wcagCriterion: "3.1.1"
            ))
        } else if let lang = validatedDoc.language, lang.count < 2 {
            // Basic sanity check: BCP 47 language tags are at least 2 characters.
            issues.append(PDFUAIssue(
                category: .languageSpecification,
                description: "Document language tag '\(lang)' appears invalid (too short for a valid BCP 47 tag) — PDF/UA-1 Section 7.3",
                severity: .warning,
                ruleId: "7.3-2",
                wcagCriterion: "3.1.1"
            ))
        }

        return issues
    }

    nonisolated private func validateReadingOrder(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        if validatedDoc.hasStructTreeRoot && validatedDoc.structureElementCount == 0 {
            issues.append(PDFUAIssue(
                category: .readingOrder,
                description: "Structure tree is empty — no logical reading order is defined — PDF/UA-1 Section 7.4",
                severity: .error,
                ruleId: "7.4-1",
                wcagCriterion: "1.3.2"
            ))
        }

        return issues
    }

    nonisolated private func validateNavigationAids(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        if validatedDoc.pageCount >= 20 && !validatedDoc.hasOutlines {
            issues.append(PDFUAIssue(
                category: .navigationAids,
                description: "Multi-page document (\(validatedDoc.pageCount) pages) lacks bookmark/outline navigation — PDF/UA-1 Section 7.24",
                severity: .warning,
                ruleId: "7.24-1",
                wcagCriterion: "2.4.5"
            ))
        }

        var reportedUntaggedAnnotations = false
        for page in validatedDoc.pages where !reportedUntaggedAnnotations {
            if page.hasAnnotations && !validatedDoc.hasStructTreeRoot {
                issues.append(PDFUAIssue(
                    category: .navigationAids,
                    description: "Page \(page.pageNumber) has annotations but document lacks structure tree — annotations cannot be tagged — PDF/UA-1 Section 7.24",
                    location: "Page \(page.pageNumber)",
                    severity: .error,
                    ruleId: "7.24-2",
                    wcagCriterion: "2.4.3"
                ))
                reportedUntaggedAnnotations = true
            }
        }

        return issues
    }

    nonisolated private func validateTableStructures(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        // Table validation requires structure tree traversal to check Table/TR/TH/TD.
        if !validatedDoc.hasStructTreeRoot && validatedDoc.pageCount > 0 {
            issues.append(PDFUAIssue(
                category: .tableStructure,
                description: "Table structure (Table/TR/TH/TD with header associations) cannot be validated without a structure tree — PDF/UA-1 Section 7.18",
                severity: .warning,
                ruleId: "7.18-1",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    nonisolated private func validateListStructures(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        // List validation requires structure tree traversal to check L/LI/Lbl/LBody.
        if !validatedDoc.hasStructTreeRoot && validatedDoc.pageCount > 0 {
            issues.append(PDFUAIssue(
                category: .listStructure,
                description: "List structure (L/LI/Lbl/LBody) cannot be validated without a structure tree — PDF/UA-1 Section 7.19",
                severity: .warning,
                ruleId: "7.19-1",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    nonisolated private func validateFormFields(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        if validatedDoc.hasAcroForm {
            if !validatedDoc.hasStructTreeRoot {
                issues.append(PDFUAIssue(
                    category: .formFields,
                    description: "Document has AcroForm fields but no structure tree — form fields cannot be tagged — PDF/UA-1 Section 7.18",
                    severity: .error,
                    ruleId: "7.18-4",
                    wcagCriterion: "1.3.1"
                ))
            } else if validatedDoc.structureElementCount == 0 {
                for page in validatedDoc.pages where page.hasAnnotations && page.annotationCount > 0 {
                    issues.append(PDFUAIssue(
                        category: .formFields,
                        description: "Page \(page.pageNumber) has annotations but structure tree has no elements — form widgets cannot be tagged — PDF/UA-1 Section 7.18",
                        location: "Page \(page.pageNumber)",
                        severity: .error,
                        ruleId: "7.18-5",
                        wcagCriterion: "1.3.1"
                    ))
                    break
                }
            }
        }

        return issues
    }

    nonisolated private func validateAnnotations(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        if !validatedDoc.hasStructTreeRoot {
            let hasAnnotations = validatedDoc.pages.contains { $0.hasAnnotations && $0.annotationCount > 0 }
            if hasAnnotations {
                issues.append(PDFUAIssue(
                    category: .annotations,
                    description: "Document has annotations but no structure tree — annotations cannot meet PDF/UA-1 tagging requirements — PDF/UA-1 Section 7.24",
                    severity: .error,
                    ruleId: "7.24-3",
                    wcagCriterion: "1.3.1"
                ))
            }
        }

        return issues
    }

    nonisolated private func extractAccessibilityFeatures(_ document: Any) async throws -> AccessibilityFeatures {
        var features = AccessibilityFeatures()

        guard let validatedDoc = document as? ValidatedDocument else {
            return features
        }

        features.hasStructureTree = validatedDoc.hasStructTreeRoot
        features.hasMarkedContent = validatedDoc.isMarked
        features.hasLanguageSpecification = validatedDoc.language != nil
            && !(validatedDoc.language?.isEmpty ?? true)
        features.hasNavigationAids = validatedDoc.hasOutlines
        features.hasLogicalReadingOrder = validatedDoc.isTagged
            && validatedDoc.structureElementCount > 0
        features.hasAccessibleForms = validatedDoc.hasAcroForm && validatedDoc.isTagged
        features.hasAlternativeText = validatedDoc.hasStructTreeRoot
            && validatedDoc.structureElementCount > 0
        features.hasAccessibleTables = validatedDoc.isTagged
            && validatedDoc.structureElementCount > 0
        features.annotationCount = validatedDoc.pages.reduce(0) { $0 + $1.annotationCount }

        return features
    }
}

// MARK: - PDF/UA-1 Specific Rules

extension PDFUA1Validator {
    /// PDF/UA-1 Section 7.1: General requirements
    ///
    /// - Document shall conform to PDF 1.4 or later
    /// - Document shall be a tagged PDF (ISO 32000-1:2008, 14.8)
    /// - All content shall be tagged or marked as artifact
    /// - Structure tree shall have a single root
    nonisolated private func validateGeneralRequirements(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        let majorVersion = validatedDoc.majorVersion
        let minorVersion = validatedDoc.minorVersion
        let isAtLeast14 = majorVersion > 1 || (majorVersion == 1 && minorVersion >= 4)
        if !isAtLeast14 {
            issues.append(PDFUAIssue(
                category: .documentMetadata,
                description: "PDF/UA-1 requires PDF version 1.4 or later; document is PDF \(validatedDoc.pdfVersion) — PDF/UA-1 Section 7.1",
                severity: .error,
                ruleId: "7.1-6",
                wcagCriterion: nil
            ))
        }

        if !validatedDoc.isTagged {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document is not a tagged PDF (requires MarkInfo/Marked = true and StructTreeRoot) — PDF/UA-1 Section 7.1",
                severity: .error,
                ruleId: "7.1-7",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// PDF/UA-1 Section 7.2: Alternative descriptions
    ///
    /// - Figures shall have alternative text
    /// - Formulas shall have alternative text
    /// - Annotations shall have Contents or alternative text
    nonisolated private func validateAlternativeDescriptions(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        // Detailed per-element alternative description validation requires structure
        // tree traversal. Check precondition: structure tree must exist.
        if !validatedDoc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .alternativeText,
                description: "Cannot validate alternative descriptions: document has no structure tree — PDF/UA-1 Section 7.2",
                severity: .error,
                ruleId: "7.2-3",
                wcagCriterion: "1.1.1"
            ))
        }

        return issues
    }

    /// PDF/UA-1 Section 7.3: Natural language specification
    ///
    /// - Document shall specify a natural language
    /// - Changes in language shall be marked
    nonisolated private func validateNaturalLanguage(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        if validatedDoc.language == nil || (validatedDoc.language?.isEmpty ?? true) {
            issues.append(PDFUAIssue(
                category: .languageSpecification,
                description: "Document catalog Lang entry is missing — PDF/UA-1 Section 7.3",
                severity: .error,
                ruleId: "7.3-3",
                wcagCriterion: "3.1.1"
            ))
        }

        return issues
    }

    /// PDF/UA-1 Section 7.4: Logical structure
    ///
    /// - Structure tree shall represent logical reading order
    /// - Standard structure types shall be used correctly
    /// - Role mapping shall be provided for custom types
    nonisolated private func validateLogicalStructure(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let validatedDoc = document as? ValidatedDocument else {
            return issues
        }

        // Logical structure validation requires structure tree traversal to check
        // standard structure types and role mappings. Check precondition only.
        if !validatedDoc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document lacks a structure tree — logical structure cannot be validated — PDF/UA-1 Section 7.4",
                severity: .error,
                ruleId: "7.4-2",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// PDF/UA-1 Section 7.18: Tables
    ///
    /// - Tables shall use Table structure element
    /// - Header cells shall use TH element
    /// - Data cells shall use TD element
    /// - Header associations shall be specified
    nonisolated private func validateTables(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let structTreeRoot = document as? ValidatedStructTreeRoot else {
            return issues
        }

        for table in structTreeRoot.tables {
            for child in table.children {
                let ct = child.structureTypeName
                let validChild = ct == "TR" || ct == "THead" || ct == "TBody"
                    || ct == "TFoot" || ct == "Caption"
                if !validChild {
                    issues.append(PDFUAIssue(
                        category: .tableStructure,
                        description: "Table contains invalid child element '\(ct)' — expected TR, THead, TBody, TFoot, or Caption — PDF/UA-1 Section 7.18",
                        location: child.pageNumber.map { "Page \($0)" },
                        severity: .error,
                        ruleId: "7.18-1",
                        wcagCriterion: "1.3.1"
                    ))
                }
                let rows = ct == "TR" ? [child] : child.children.filter { $0.structureTypeName == "TR" }
                for row in rows {
                    let validCells = row.children.allSatisfy { $0.structureTypeName == "TH" || $0.structureTypeName == "TD" }
                    if !row.children.isEmpty && !validCells {
                        issues.append(PDFUAIssue(
                            category: .tableStructure,
                            description: "Table row (TR) contains non-cell elements — cells must be TH or TD — PDF/UA-1 Section 7.18",
                            location: row.pageNumber.map { "Page \($0)" },
                            severity: .error,
                            ruleId: "7.18-2",
                            wcagCriterion: "1.3.1"
                        ))
                    }
                }
            }
            for header in table.allDescendants where header.structureTypeName == "TH" {
                if header.attributes["Scope"] == nil {
                    issues.append(PDFUAIssue(
                        category: .tableStructure,
                        description: "Table header cell (TH) is missing Scope attribute — PDF/UA-1 Section 7.18",
                        location: header.pageNumber.map { "Page \($0)" },
                        severity: .warning,
                        ruleId: "7.18-3",
                        wcagCriterion: "1.3.1"
                    ))
                }
            }
        }

        return issues
    }

    /// PDF/UA-1 Section 7.19: Lists
    ///
    /// - Lists shall use L structure element
    /// - List items shall use LI element
    /// - List item labels shall use Lbl element
    /// - List item content shall use LBody element
    nonisolated private func validateLists(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let structTreeRoot = document as? ValidatedStructTreeRoot else {
            return issues
        }

        for list in structTreeRoot.lists {
            for child in list.children {
                let ct = child.structureTypeName
                guard ct == "LI" || ct == "Caption" else {
                    issues.append(PDFUAIssue(
                        category: .listStructure,
                        description: "List (L) contains invalid child element '\(ct)' — expected LI — PDF/UA-1 Section 7.19",
                        location: child.pageNumber.map { "Page \($0)" },
                        severity: .error,
                        ruleId: "7.19-1",
                        wcagCriterion: "1.3.1"
                    ))
                    continue
                }
                if ct == "LI" {
                    let hasLbl = child.children.contains { $0.structureTypeName == "Lbl" }
                    let hasLBody = child.children.contains { $0.structureTypeName == "LBody" }
                    if !child.children.isEmpty && !hasLbl && !hasLBody {
                        issues.append(PDFUAIssue(
                            category: .listStructure,
                            description: "List item (LI) must contain Lbl and/or LBody elements — PDF/UA-1 Section 7.19",
                            location: child.pageNumber.map { "Page \($0)" },
                            severity: .error,
                            ruleId: "7.19-2",
                            wcagCriterion: "1.3.1"
                        ))
                    }
                }
            }
        }

        return issues
    }
}
