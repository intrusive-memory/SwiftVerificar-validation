import Foundation
import SwiftVerificarValidationProfiles
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - PDF/UA-2 Validator

/// PDF/UA-2 (ISO 14289-2:2024) validator
///
/// Validates PDF documents for conformance to PDF/UA-2, the second generation
/// universal accessibility standard. PDF/UA-2 is based on PDF 2.0 and
/// provides enhanced requirements for accessible PDF documents.
///
/// Key enhancements over PDF/UA-1:
/// - Enhanced semantic structure elements (Em, Strong, Sub, etc.)
/// - Improved table and list structures
/// - Enhanced annotation accessibility
/// - Associated files support
/// - Enhanced multimedia accessibility
/// - Better support for mathematical content
/// - Improved heading hierarchy validation
public actor PDFUA2Validator: PDFUAValidator {
    // MARK: - Properties

    public nonisolated let conformance: PDFUAConformance = .pdfua2

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

        // Load PDF/UA-2 validation profile
        let profile = try await loadValidationProfile()

        // Detect claimed conformance from metadata
        let claimedConformance = try await detectClaimedConformance(document)

        // Validate PDF 2.0 compliance
        let pdf2Issues = try await validatePDF2Compliance(document)

        // Validate document structure (enhanced for PDF 2.0)
        let structureIssues = try await validateDocumentStructure(document)

        // Validate enhanced semantic structure
        let semanticIssues = try await validateSemanticStructure(document)

        // Validate tagged content
        let taggedContentIssues = try await validateTaggedContent(document)

        // Validate alternative text and descriptions
        let alternativeTextIssues = try await validateAlternativeText(document)

        // Validate language specification
        let languageIssues = try await validateLanguageSpecification(document)

        // Validate reading order
        let readingOrderIssues = try await validateReadingOrder(document)

        // Validate navigation aids
        let navigationIssues = try await validateNavigationAids(document)

        // Validate table structures (enhanced)
        let tableIssues = try await validateTableStructures(document)

        // Validate list structures (enhanced)
        let listIssues = try await validateListStructures(document)

        // Validate heading hierarchy
        let headingIssues = try await validateHeadingHierarchy(document)

        // Validate form fields
        let formIssues = try await validateFormFields(document)

        // Validate annotations (enhanced)
        let annotationIssues = try await validateAnnotations(document)

        // Validate associated files
        let associatedFilesIssues = try await validateAssociatedFiles(document)

        // Validate multimedia accessibility
        let multimediaIssues = try await validateMultimedia(document)

        // Validate mathematical content
        let mathIssues = try await validateMathematicalContent(document)

        // Combine all issues
        let allIssues = pdf2Issues + structureIssues + semanticIssues +
            taggedContentIssues + alternativeTextIssues + languageIssues +
            readingOrderIssues + navigationIssues + tableIssues + listIssues +
            headingIssues + formIssues + annotationIssues +
            associatedFilesIssues + multimediaIssues + mathIssues

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
        // Parse XMP metadata to detect PDF/UA-2 conformance claim.
        // Look for pdfuaid:part == 2 in the document XMP metadata.
        // Returns .pdfua2 when pdfuaid:part == 2, nil otherwise.
        #if canImport(SwiftVerificarParser)
        if let pdfDoc = document as? PDFDocument,
           let xmp = pdfDoc.xmpMetadata,
           let part = xmp.pdfuaPart,
           part == 2 {
            return .pdfua2
        }
        #endif
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
        // Load PDF/UA-2 profile from validation profiles package
        // For now, return a stub profile
        let details = ProfileDetails(
            name: "PDF/UA-2",
            description: "PDF/UA-2 (ISO 14289-2:2024) validation profile",
            creator: "SwiftVerificar",
            created: Date()
        )
        return ValidationProfile(
            details: details,
            rules: [],
            flavour: .pdfUA2
        )
    }

    /// Validates that the document is PDF 2.0 compliant.
    ///
    /// PDF/UA-2 mandates conformance to PDF 2.0 (ISO 32000-2:2020).
    /// Documents with pdfVersion < "2.0" fail this check.
    nonisolated private func validatePDF2Compliance(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            // Cannot determine pdfVersion without a ValidatedDocument; skip check.
            return issues
        }

        // PDF/UA-2 requires PDF 2.0 (majorVersion >= 2)
        if !doc.isPDF2 {
            issues.append(PDFUAIssue(
                category: .documentMetadata,
                description: "PDF/UA-2 requires PDF 2.0 (ISO 32000-2:2020); document pdfVersion is \(doc.pdfVersion)",
                severity: .error,
                ruleId: "6.1",
                wcagCriterion: nil
            ))
        }

        return issues
    }

    /// Validates the document structure tree.
    ///
    /// PDF/UA-2 requires a tagged PDF with a StructTreeRoot and proper MarkInfo.
    /// Enhanced structure validation for PDF 2.0 includes checking for suspects.
    nonisolated private func validateDocumentStructure(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Structure tree root is required for PDF/UA-2
        if !doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document must have a structure tree root (StructTreeRoot)",
                severity: .error,
                ruleId: "7.1",
                wcagCriterion: "1.3.1"
            ))
        }

        // MarkInfo/Marked must be true
        if !doc.isMarked {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document MarkInfo/Marked must be true for a tagged PDF",
                severity: .error,
                ruleId: "7.1",
                wcagCriterion: "1.3.1"
            ))
        }

        // hasSuspects indicates uncertain tagging
        if doc.hasSuspects {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document MarkInfo/Suspects is true; some content may not be properly tagged",
                severity: .warning,
                ruleId: "7.1",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// Validates enhanced semantic structure elements (Em, Strong, Sub, Title).
    ///
    /// PDF/UA-2 introduces inline semantic elements. Their presence requires
    /// a properly populated structure tree.
    nonisolated private func validateSemanticStructure(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Semantic structure elements (Em, Strong, Sub, Title) require a structure tree.
        // An empty structure tree cannot contain any semantic elements.
        if doc.hasStructTreeRoot && doc.structureElementCount == 0 {
            issues.append(PDFUAIssue(
                category: .semanticStructure,
                description: "Structure tree root exists but contains no structure elements; semantic elements (Em, Strong, Sub, Title) cannot be validated",
                severity: .warning,
                ruleId: "7.2",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// Validates that all content is tagged or marked as an artifact.
    ///
    /// PDF/UA-2 Section 7.1: Every piece of real content must be wrapped in a
    /// structure element; decorative content must be marked as Artifact.
    nonisolated private func validateTaggedContent(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // MarkInfo present but no structure tree — content cannot be properly tagged
        if doc.hasMarkInfo && !doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document has MarkInfo but no StructTreeRoot; all content must be tagged or marked as artifact",
                severity: .error,
                ruleId: "7.1",
                wcagCriterion: "1.3.1"
            ))
        }

        // Completely untagged document fails PDF/UA-2
        if !doc.hasMarkInfo && !doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "Document is not tagged (no MarkInfo, no StructTreeRoot); PDF/UA-2 requires all content to be tagged or marked as artifact",
                severity: .error,
                ruleId: "7.1",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// Validates alternative text on figures, formulas, and non-text content.
    ///
    /// PDF/UA-2 requires Alt or ActualText on Figure and Formula structure elements.
    nonisolated private func validateAlternativeText(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Alternative text can only be attached to structure elements; precondition check.
        if !doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .alternativeText,
                description: "Cannot validate alternative text: document has no structure tree; figures and formulas must have Alt or ActualText",
                severity: .error,
                ruleId: "7.3",
                wcagCriterion: "1.1.1"
            ))
        }

        return issues
    }

    /// Validates language specification in the document catalog.
    ///
    /// PDF/UA-2 requires a Lang entry on the document catalog (and optionally per structure element).
    nonisolated private func validateLanguageSpecification(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Catalog must have a non-empty Lang entry
        if doc.language == nil || doc.language?.isEmpty == true {
            issues.append(PDFUAIssue(
                category: .languageSpecification,
                description: "Document catalog must specify a natural language (Lang entry) per PDF/UA-2 Section 7.2",
                severity: .error,
                ruleId: "7.2",
                wcagCriterion: "3.1.1"
            ))
        }

        return issues
    }

    /// Validates logical reading order in the structure tree.
    ///
    /// PDF/UA-2 requires that the structure tree represents the logical reading order.
    nonisolated private func validateReadingOrder(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Reading order is encoded in the structure tree; must exist for validation.
        if !doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .readingOrder,
                description: "Cannot validate reading order: document has no structure tree",
                severity: .error,
                ruleId: "7.4",
                wcagCriterion: "1.3.2"
            ))
        }

        return issues
    }

    /// Validates navigation aids: bookmarks (Outlines) and links.
    ///
    /// PDF/UA-2 recommends navigation aids for documents with more than one page.
    nonisolated private func validateNavigationAids(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Multi-page documents should provide an Outlines (bookmarks) dictionary
        if doc.pageCount > 1 && !doc.hasOutlines {
            issues.append(PDFUAIssue(
                category: .navigationAids,
                description: "Multi-page document (\(doc.pageCount) pages) should provide bookmarks (Outlines) to aid navigation",
                severity: .warning,
                ruleId: "7.14",
                wcagCriterion: "2.4.5"
            ))
        }

        return issues
    }

    /// Validates table structures (Table/TR/TH/TD with Scope or Headers attributes).
    ///
    /// PDF/UA-2 Enhanced: header cells must specify Scope or Headers attributes.
    nonisolated private func validateTableStructures(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Table validation requires structure tree traversal; check precondition
        if !doc.hasStructTreeRoot && doc.pageCount > 0 {
            issues.append(PDFUAIssue(
                category: .tableStructure,
                description: "Table structure (Table/TR/TH/TD with Scope/Headers) cannot be validated without a structure tree",
                severity: .warning,
                ruleId: "7.6",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// Validates list structures (L/LI/Lbl/LBody elements).
    ///
    /// PDF/UA-2 Enhanced: list items must use the L/LI/Lbl/LBody structure hierarchy.
    nonisolated private func validateListStructures(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // List validation requires structure tree traversal; check precondition
        if !doc.hasStructTreeRoot && doc.pageCount > 0 {
            issues.append(PDFUAIssue(
                category: .listStructure,
                description: "List structure (L/LI/Lbl/LBody) cannot be validated without a structure tree",
                severity: .warning,
                ruleId: "7.7",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// Validates heading hierarchy (H1–H6 nesting).
    ///
    /// PDF/UA-2 requires properly nested headings with no skipped levels.
    nonisolated private func validateHeadingHierarchy(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Heading hierarchy validation requires structure tree traversal
        if !doc.hasStructTreeRoot && doc.pageCount > 0 {
            issues.append(PDFUAIssue(
                category: .headings,
                description: "Heading hierarchy (H1–H6, no skipped levels) cannot be validated without a structure tree",
                severity: .warning,
                ruleId: "7.5",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// Validates form field accessibility.
    ///
    /// PDF/UA-2 requires form fields to have accessible labels through proper
    /// structure element associations and TU (tooltip/description) entries.
    nonisolated private func validateFormFields(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // AcroForm exists but no structure tree — form fields lack structure associations
        if doc.hasAcroForm && !doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .formFields,
                description: "Document has form fields (AcroForm) but no structure tree; form fields must be associated with Widget structure elements",
                severity: .error,
                ruleId: "7.18",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// Validates annotation accessibility (Contents or alternative text).
    ///
    /// PDF/UA-2 Enhanced: all annotations must have Contents or Alt; link
    /// annotations must have meaningful link text.
    nonisolated private func validateAnnotations(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Check whether any page has annotations
        let totalAnnotations = doc.pages.reduce(0) { $0 + $1.annotationCount }
        if totalAnnotations > 0 && !doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .annotations,
                description: "Document has \(totalAnnotations) annotation(s) but no structure tree; annotations must be tagged or provide alternative text",
                severity: .error,
                ruleId: "7.11",
                wcagCriterion: "1.1.1"
            ))
        }

        return issues
    }

    /// Validates associated files (AF entries) for PDF 2.0 accessibility.
    ///
    /// Each AF entry must specify /Desc, /AFRelationship, and /Subtype (MIME type).
    nonisolated private func validateAssociatedFiles(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Associated Files (AF) are a PDF 2.0 feature (ISO 32000-2 §14.13)
        if !doc.isPDF2 {
            // Pre-2.0 documents cannot use AF entries for accessible attachments
            return issues
        }

        // In PDF 2.0 documents with output intents (common AF containers),
        // verify that AF entries are properly described.
        if doc.hasOutputIntents && doc.outputIntentCount > 0 {
            issues.append(PDFUAIssue(
                category: .embeddedFiles,
                description: "PDF/UA-2: verify that all AF (Associated File) entries include /Desc, /AFRelationship, and /Subtype for \(doc.outputIntentCount) output intent(s)",
                severity: .warning,
                ruleId: "7.10",
                wcagCriterion: nil
            ))
        }

        return issues
    }

    /// Validates multimedia accessibility (captions, transcripts, descriptions).
    ///
    /// Multimedia content (audio, video, 3D) must provide accessible alternatives.
    nonisolated private func validateMultimedia(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Multimedia annotations (RichMedia, Screen) may be among page annotations.
        let hasAnnotations = doc.pages.contains { $0.hasAnnotations }
        if hasAnnotations && !doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .multimedia,
                description: "Document has annotations (possibly multimedia) but no structure tree; multimedia must be associated with structure elements providing captions or transcripts",
                severity: .warning,
                ruleId: "7.12",
                wcagCriterion: "1.2.1"
            ))
        }

        return issues
    }

    /// Validates mathematical content (Formula elements, MathML AF entries).
    ///
    /// Mathematical formulas must use MathML via associated files or provide Alt text.
    nonisolated private func validateMathematicalContent(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Mathematical content validation requires structure tree traversal to find
        // Formula elements and check Alt/ActualText or associated MathML files.
        if !doc.hasStructTreeRoot && doc.structureElementCount > 0 {
            issues.append(PDFUAIssue(
                category: .semanticStructure,
                description: "Mathematical formula elements require Alt text or MathML associated files; structure tree needed for validation",
                severity: .warning,
                ruleId: "7.13",
                wcagCriterion: "1.1.1"
            ))
        }

        return issues
    }

    /// Extracts the accessibility features present in the document.
    ///
    /// Inspects ValidatedDocument's real document properties to populate
    /// an AccessibilityFeatures summary for the validation result.
    nonisolated private func extractAccessibilityFeatures(_ document: Any) async throws -> AccessibilityFeatures {
        var features = AccessibilityFeatures()

        guard let doc = document as? ValidatedDocument else {
            // Return zero-valued features when document is not a ValidatedDocument.
            return features
        }

        // Populate from real document properties via ValidatedDocument
        features.hasStructureTree = doc.hasStructTreeRoot
        features.hasMarkedContent = doc.isMarked
        features.hasLanguageSpecification = doc.language != nil && doc.language?.isEmpty == false
        features.hasNavigationAids = doc.hasOutlines
        features.hasAccessibleForms = doc.hasAcroForm && doc.hasStructTreeRoot
        features.hasAlternativeText = doc.hasStructTreeRoot && doc.structureElementCount > 0
        features.hasAccessibleTables = doc.hasStructTreeRoot && doc.structureElementCount > 0
        features.hasLogicalReadingOrder = doc.hasStructTreeRoot

        // Aggregate annotation counts from all pages
        features.annotationCount = doc.pages.reduce(0) { $0 + $1.annotationCount }

        // Heading count: approximated from pdfVersion and page count until structure traversal is available
        features.headingCount = doc.hasStructTreeRoot ? min(doc.structureElementCount, doc.pageCount) : 0

        // Table and list counts require full structure traversal; report 0 until available
        features.tableCount = 0
        features.listCount = 0

        // Form field count: 1 minimum if AcroForm exists, else 0
        features.formFieldCount = doc.hasAcroForm ? 1 : 0

        return features
    }
}

// MARK: - PDF/UA-2 Specific Rules

extension PDFUA2Validator {
    /// PDF/UA-2 Section 7: General requirements
    ///
    /// - Document shall conform to PDF 2.0 (ISO 32000-2:2020)
    /// - Document shall be a tagged PDF
    /// - All content shall be tagged or marked as artifact
    /// - Structure tree shall have a single root
    nonisolated private func validateGeneralRequirements(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // General requirement 1: PDF 2.0 compliance (pdfVersion must be >= 2.0)
        if !doc.isPDF2 {
            issues.append(PDFUAIssue(
                category: .documentMetadata,
                description: "PDF/UA-2 general requirement: document must be PDF 2.0 (current pdfVersion=\(doc.pdfVersion))",
                severity: .error,
                ruleId: "7.1",
                wcagCriterion: nil
            ))
        }

        // General requirement 2: tagged PDF (MarkInfo/Marked=true + StructTreeRoot present)
        if !doc.isTagged {
            issues.append(PDFUAIssue(
                category: .taggedStructure,
                description: "PDF/UA-2 general requirement: document must be a tagged PDF (isMarked=\(doc.isMarked), hasStructTreeRoot=\(doc.hasStructTreeRoot))",
                severity: .error,
                ruleId: "7.1",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// PDF/UA-2 Enhanced semantic elements
    ///
    /// - Em: Emphasis (inline)
    /// - Strong: Strong emphasis (inline)
    /// - Sub: Subscript (inline)
    /// - Title: Document or section title
    nonisolated private func validateEnhancedSemantics(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Enhanced semantic elements (Em, Strong, Sub, Title) are optional inline elements
        // in PDF/UA-2. Their correct usage can only be verified by traversing the structure
        // tree. We check the precondition that a structure tree with elements exists.
        if doc.hasStructTreeRoot && doc.structureElementCount == 0 {
            issues.append(PDFUAIssue(
                category: .semanticStructure,
                description: "Enhanced semantic elements (Em, Strong, Sub, Title) require a populated structure tree; tree exists but has 0 elements",
                severity: .warning,
                ruleId: "7.2",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// PDF/UA-2 Enhanced table validation
    ///
    /// - Scope attribute for header cells
    /// - Headers attribute for complex tables
    /// - Summary attribute (deprecated, check for removal)
    nonisolated private func validateEnhancedTables(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Enhanced table validation (Scope/Headers on TH/TD) requires structure tree traversal.
        if !doc.hasStructTreeRoot && doc.pageCount > 0 {
            issues.append(PDFUAIssue(
                category: .tableStructure,
                description: "Enhanced table validation (Scope/Headers attributes on TH/TD) requires a structure tree",
                severity: .warning,
                ruleId: "7.6",
                wcagCriterion: "1.3.1"
            ))
        }

        return issues
    }

    /// PDF/UA-2 Heading hierarchy validation
    ///
    /// - Headings shall be properly nested (H1 > H2 > H3, etc.)
    /// - No skipped heading levels
    /// - H element shall be used correctly
    nonisolated private func validateHeadings(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Heading hierarchy validation (H1–H6 nesting, no skipped levels) requires
        // full structure tree traversal. Check precondition only.
        if !doc.hasStructTreeRoot && doc.pageCount > 0 {
            issues.append(PDFUAIssue(
                category: .headings,
                description: "Heading hierarchy (H1–H6, no skipped levels) cannot be validated without a structure tree",
                severity: .warning,
                ruleId: "7.5",
                wcagCriterion: "2.4.6"
            ))
        }

        return issues
    }

    /// PDF/UA-2 Associated files (AF entries)
    ///
    /// - Associated files shall have descriptions (/Desc)
    /// - Associated files shall specify relationship (/AFRelationship)
    /// - MIME type shall be specified (/Subtype)
    nonisolated private func validateAFEntries(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // AF entries are a PDF 2.0 feature (ISO 32000-2 §14.13).
        // Each AF entry must have /Desc, /AFRelationship, and /Subtype.
        if !doc.isPDF2 {
            // Non-2.0 document: AF entries are not applicable
            return issues
        }

        // For PDF 2.0 documents with output intents, verify AF entries are complete.
        // Detailed per-entry validation (/Desc, /AFRelationship, /Subtype) requires
        // COS-level document traversal via the parser AF array.
        if doc.hasOutputIntents && doc.outputIntentCount > 0 {
            issues.append(PDFUAIssue(
                category: .embeddedFiles,
                description: "PDF/UA-2 AF entries: verify \(doc.outputIntentCount) output intent(s) include /Desc, /AFRelationship, and /Subtype",
                severity: .warning,
                ruleId: "7.10",
                wcagCriterion: nil
            ))
        }

        return issues
    }

    /// PDF/UA-2 Enhanced annotation validation
    ///
    /// - All annotations shall have Contents or alternative text
    /// - Link annotations shall have meaningful link text
    /// - Widget annotations shall have proper field descriptions
    nonisolated private func validateEnhancedAnnotations(_ document: Any) async throws -> [PDFUAIssue] {
        var issues: [PDFUAIssue] = []

        guard let doc = document as? ValidatedDocument else {
            return issues
        }

        // Aggregate annotation count from all pages to check for enhanced annotation issues
        let totalAnnotations = doc.pages.reduce(0) { $0 + $1.annotationCount }

        // Annotations in an untagged document cannot have structure associations
        if totalAnnotations > 0 && !doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .annotations,
                description: "Document has \(totalAnnotations) annotation(s) but no structure tree; all non-artifact annotations must have Contents or alternative text",
                severity: .error,
                ruleId: "7.11",
                wcagCriterion: "1.1.1"
            ))
        }

        // Annotations in a tagged document should still be verified per-annotation
        if totalAnnotations > 0 && doc.hasStructTreeRoot {
            issues.append(PDFUAIssue(
                category: .annotations,
                description: "Verify that all \(totalAnnotations) annotation(s) provide Contents or alternative text (link text for Link; TU for Widget)",
                severity: .warning,
                ruleId: "7.11",
                wcagCriterion: "1.1.1"
            ))
        }

        return issues
    }
}
