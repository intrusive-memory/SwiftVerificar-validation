import Foundation

// MARK: - SA Accessibility Summary

/// A summary of accessibility characteristics for an SA document or subtree.
///
/// `SAAccessibilitySummary` aggregates key accessibility metrics from the SA
/// layer, providing a high-level overview of a document's accessibility status.
/// It is useful for reporting and quick assessment of document quality.
///
/// ## Relationship to veraPDF
///
/// Corresponds to summary information gathered by the WCAG validation pipeline
/// in veraPDF-validation. In Java, this is typically computed ad-hoc during
/// validation; in Swift, it is captured as a first-class value type.
public struct SAAccessibilitySummary: Sendable, Equatable, Codable {

    /// The total number of structure elements analyzed.
    public let totalElements: Int

    /// The number of heading elements.
    public let headingCount: Int

    /// The number of figure elements.
    public let figureCount: Int

    /// The number of table elements.
    public let tableCount: Int

    /// The number of list elements.
    public let listCount: Int

    /// The number of link elements.
    public let linkCount: Int

    /// The number of elements with alternative text.
    public let elementsWithAltText: Int

    /// The number of elements with actual text.
    public let elementsWithActualText: Int

    /// The number of elements with an effective language.
    public let elementsWithLanguage: Int

    /// The number of elements that require alt text but lack it.
    public let missingAltTextCount: Int

    /// The number of elements that fail accessibility requirements.
    public let accessibilityIssueCount: Int

    /// The maximum heading level found (1-6), or `nil` if no headings.
    public let maxHeadingLevel: Int?

    /// The minimum heading level found (1-6), or `nil` if no headings.
    public let minHeadingLevel: Int?

    /// The maximum depth of the structure tree.
    public let maxDepth: Int

    /// The accessibility compliance ratio (0.0 to 1.0).
    ///
    /// Calculated as the proportion of elements that meet their accessibility
    /// requirements out of all accessibility-relevant elements.
    public var complianceRatio: Double {
        let relevant = totalElements - artifactCount
        guard relevant > 0 else { return 1.0 }
        return Double(relevant - accessibilityIssueCount) / Double(relevant)
    }

    /// The number of artifact elements.
    public let artifactCount: Int

    /// Creates an accessibility summary.
    public init(
        totalElements: Int = 0,
        headingCount: Int = 0,
        figureCount: Int = 0,
        tableCount: Int = 0,
        listCount: Int = 0,
        linkCount: Int = 0,
        elementsWithAltText: Int = 0,
        elementsWithActualText: Int = 0,
        elementsWithLanguage: Int = 0,
        missingAltTextCount: Int = 0,
        accessibilityIssueCount: Int = 0,
        maxHeadingLevel: Int? = nil,
        minHeadingLevel: Int? = nil,
        maxDepth: Int = 0,
        artifactCount: Int = 0
    ) {
        self.totalElements = totalElements
        self.headingCount = headingCount
        self.figureCount = figureCount
        self.tableCount = tableCount
        self.listCount = listCount
        self.linkCount = linkCount
        self.elementsWithAltText = elementsWithAltText
        self.elementsWithActualText = elementsWithActualText
        self.elementsWithLanguage = elementsWithLanguage
        self.missingAltTextCount = missingAltTextCount
        self.accessibilityIssueCount = accessibilityIssueCount
        self.maxHeadingLevel = maxHeadingLevel
        self.minHeadingLevel = minHeadingLevel
        self.maxDepth = maxDepth
        self.artifactCount = artifactCount
    }
}

// MARK: - SA Document Summary Extension

extension SADocument {

    /// Computes an accessibility summary for this document.
    ///
    /// Traverses the entire SA structure tree (if present) and gathers
    /// accessibility metrics.
    ///
    /// - Returns: An accessibility summary for the document.
    public func accessibilitySummary() -> SAAccessibilitySummary {
        guard let root = structureRoot else {
            return SAAccessibilitySummary()
        }

        let allNodes = root.allNodes
        let headings = allNodes.filter { $0.structureType?.isHeading == true }
        let headingLevels = headings.compactMap { $0.structureType?.headingLevel }

        return SAAccessibilitySummary(
            totalElements: allNodes.count,
            headingCount: headings.count,
            figureCount: allNodes.filter { $0.structureType == .figure }.count,
            tableCount: allNodes.filter { $0.structureType == .table }.count,
            listCount: allNodes.filter { $0.structureType == .list }.count,
            linkCount: allNodes.filter { $0.structureType == .link }.count,
            elementsWithAltText: allNodes.filter(\.hasAltText).count,
            elementsWithActualText: allNodes.filter(\.hasActualText).count,
            elementsWithLanguage: allNodes.filter(\.hasEffectiveLanguage).count,
            missingAltTextCount: allNodes.filter { $0.requiresAltText && !$0.hasAltText && !$0.hasActualText }.count,
            accessibilityIssueCount: allNodes.filter { !$0.isAccessible }.count,
            maxHeadingLevel: headingLevels.max(),
            minHeadingLevel: headingLevels.min(),
            maxDepth: root.structTreeRoot.maxDepth,
            artifactCount: allNodes.filter { $0.structureType == .artifact }.count
        )
    }
}

// MARK: - SA Structure Element Summary Extension

extension SAStructureElement {

    /// Computes an accessibility summary for this element and its descendants.
    ///
    /// - Returns: An accessibility summary for this subtree.
    public func accessibilitySummary() -> SAAccessibilitySummary {
        let all = [self] + allDescendants
        let headings = all.filter(\.isHeading)
        let headingLevels = headings.compactMap(\.headingLevel)

        return SAAccessibilitySummary(
            totalElements: all.count,
            headingCount: headings.count,
            figureCount: all.filter(\.isFigure).count,
            tableCount: all.filter(\.isTableElement).count,
            listCount: all.filter(\.isListElement).count,
            linkCount: all.filter(\.isLink).count,
            elementsWithAltText: all.filter(\.hasAltText).count,
            elementsWithActualText: all.filter(\.hasActualText).count,
            elementsWithLanguage: all.filter(\.hasEffectiveLanguage).count,
            missingAltTextCount: all.filter { $0.requiresAltText && !$0.hasAltText && !$0.hasActualText }.count,
            accessibilityIssueCount: all.filter { !$0.isAccessible }.count,
            maxHeadingLevel: headingLevels.max(),
            minHeadingLevel: headingLevels.min(),
            maxDepth: all.map(\.depth).max() ?? 0,
            artifactCount: all.filter(\.isArtifact).count
        )
    }
}

// MARK: - SA Tree Builder

/// Builder for constructing SA document trees from validated PD-layer types.
///
/// `SATreeBuilder` provides convenience methods for constructing a complete
/// SA document tree from the PD-layer validated types. It handles the
/// wrapping of `ValidatedDocument` -> `SADocument`, `ValidatedPage` -> `SAPage`,
/// `ValidatedStructTreeRoot` -> `SAStructureRoot`, and `ValidatedStructElem` -> `SANode`.
///
/// ## Usage
///
/// ```swift
/// let builder = SATreeBuilder()
/// let saDocument = builder.buildDocument(from: validatedDoc, structElems: elems)
/// ```
public struct SATreeBuilder: Sendable, Equatable {

    /// Creates an SA tree builder.
    public init() {}

    /// Builds an SA document from a validated document and optional structure elements.
    ///
    /// - Parameters:
    ///   - document: The validated document.
    ///   - structTreeRoot: The validated structure tree root, if present.
    ///   - structElems: The top-level structure elements.
    ///   - inheritedLanguage: The document-level language to inherit.
    /// - Returns: A fully constructed SA document.
    public func buildDocument(
        from document: ValidatedDocument,
        structTreeRoot: ValidatedStructTreeRoot? = nil,
        structElems: [ValidatedStructElem] = [],
        inheritedLanguage: String? = nil
    ) -> SADocument {
        let effectiveLanguage = inheritedLanguage ?? document.language

        // Build SA nodes from structure elements
        let saNodes = structElems.map { buildNode(from: $0, inheritedLanguage: effectiveLanguage) }

        // Build SA pages
        let saPages = document.pages.enumerated().map { _, page in
            let pageNodes = saNodes.filter { $0.pageNumber == page.pageNumber }
            return SAPage(page: page, nodes: pageNodes)
        }

        // Build SA structure root
        let saRoot: SAStructureRoot?
        if let root = structTreeRoot {
            saRoot = SAStructureRoot(structTreeRoot: root, children: saNodes)
        } else {
            saRoot = nil
        }

        return SADocument(
            document: document,
            pages: saPages,
            structureRoot: saRoot
        )
    }

    /// Builds an SA node from a validated structure element.
    ///
    /// - Parameters:
    ///   - elem: The validated structure element.
    ///   - inheritedLanguage: The language inherited from ancestors.
    /// - Returns: An SA node wrapping the element.
    public func buildNode(
        from elem: ValidatedStructElem,
        inheritedLanguage: String? = nil
    ) -> SANode {
        let effectiveLanguage = elem.language ?? inheritedLanguage
        let children = elem.children.map { buildNode(from: $0, inheritedLanguage: effectiveLanguage) }
        return SANode(
            structElem: elem,
            children: children,
            inheritedLanguage: inheritedLanguage
        )
    }

    /// Builds an SA structure element tree from a validated structure element.
    ///
    /// - Parameter element: The validated structure element with resolved types.
    /// - Returns: An SA structure element with recursively built children.
    public func buildStructureElement(
        from element: ValidatedStructureElement
    ) -> SAStructureElement {
        SAStructureElement.from(element)
    }
}

// MARK: - SA Validation Report

/// A complete WCAG validation report for an SA document.
///
/// Combines the SA document encoding with WCAG issues and accessibility
/// summary into a single Codable report suitable for serialization.
public struct SAValidationReport: Sendable, Equatable, Codable {

    /// The document summary.
    public let documentSummary: SADocumentDTO

    /// The accessibility summary.
    public let accessibilitySummary: SAAccessibilitySummary

    /// The WCAG issues found.
    public let issues: [WCAGIssueDTO]

    /// The total number of issues.
    public var issueCount: Int {
        issues.count
    }

    /// The number of critical issues.
    public var criticalIssueCount: Int {
        issues.filter { $0.severity == WCAGIssueSeverity.critical.rawValue }.count
    }

    /// The number of major issues.
    public var majorIssueCount: Int {
        issues.filter { $0.severity == WCAGIssueSeverity.major.rawValue }.count
    }

    /// Whether the document passes basic accessibility checks.
    public var passesBasicAccessibility: Bool {
        documentSummary.meetsBasicAccessibility && criticalIssueCount == 0
    }

    /// Creates a validation report.
    ///
    /// - Parameters:
    ///   - documentSummary: The document DTO.
    ///   - accessibilitySummary: The accessibility summary.
    ///   - issues: The WCAG issues.
    public init(
        documentSummary: SADocumentDTO,
        accessibilitySummary: SAAccessibilitySummary,
        issues: [WCAGIssueDTO] = []
    ) {
        self.documentSummary = documentSummary
        self.accessibilitySummary = accessibilitySummary
        self.issues = issues
    }
}

// MARK: - SADocumentEncoder Report Generation

extension SADocumentEncoder {

    /// Generates a complete validation report for an SA document.
    ///
    /// - Parameters:
    ///   - document: The SA document to report on.
    ///   - issues: The WCAG issues found during validation.
    /// - Returns: A complete validation report.
    public func generateReport(
        for document: SADocument,
        issues: [WCAGIssue] = []
    ) -> SAValidationReport {
        let docDTO = documentDTO(from: document)
        let summary = document.accessibilitySummary()
        let issueDTOs = issues.map { issueDTO(from: $0) }

        return SAValidationReport(
            documentSummary: docDTO,
            accessibilitySummary: summary,
            issues: issueDTOs
        )
    }

    /// Encodes a complete validation report into JSON data.
    ///
    /// - Parameters:
    ///   - document: The SA document.
    ///   - issues: The WCAG issues.
    /// - Returns: JSON data representing the validation report.
    /// - Throws: `SAEncodingError` if encoding fails.
    public func encodeReport(
        for document: SADocument,
        issues: [WCAGIssue] = []
    ) throws -> Data {
        let report = generateReport(for: document, issues: issues)
        return try encodeDTO(report)
    }
}
