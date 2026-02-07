import Foundation

// MARK: - WCAG Issue Severity

/// The severity level of a WCAG accessibility issue.
///
/// Represents the impact of an accessibility issue on users of
/// assistive technologies, aligned with WCAG conformance levels.
public enum WCAGIssueSeverity: String, Sendable, Hashable, CaseIterable, Codable, Comparable {

    /// Critical: prevents access to content (WCAG Level A failure).
    case critical = "Critical"

    /// Major: significantly impedes access (WCAG Level AA failure).
    case major = "Major"

    /// Minor: causes inconvenience (WCAG Level AAA failure).
    case minor = "Minor"

    /// Informational: best practice recommendation, not a failure.
    case informational = "Informational"

    /// Comparison for severity ordering (critical > major > minor > informational).
    public static func < (lhs: WCAGIssueSeverity, rhs: WCAGIssueSeverity) -> Bool {
        let order: [WCAGIssueSeverity] = [.informational, .minor, .major, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - WCAG Issue Category

/// The category of a WCAG accessibility issue.
///
/// Groups WCAG issues by the type of accessibility concern.
public enum WCAGIssueCategory: String, Sendable, Hashable, CaseIterable, Codable {

    /// Missing or incomplete alternative text for non-text content.
    case alternativeText = "AlternativeText"

    /// Missing or invalid document language specification.
    case language = "Language"

    /// Missing or incomplete tagged structure.
    case taggedStructure = "TaggedStructure"

    /// Heading hierarchy issues (skipped levels, missing headings).
    case headingHierarchy = "HeadingHierarchy"

    /// Table structure issues (missing headers, scope, etc.).
    case tableStructure = "TableStructure"

    /// List structure issues (improper nesting, missing labels).
    case listStructure = "ListStructure"

    /// Insufficient color contrast.
    case colorContrast = "ColorContrast"

    /// Reading order issues.
    case readingOrder = "ReadingOrder"

    /// Form field accessibility issues.
    case formAccessibility = "FormAccessibility"

    /// Link text and destination issues.
    case linkAccessibility = "LinkAccessibility"

    /// Image accessibility issues.
    case imageAccessibility = "ImageAccessibility"

    /// Metadata and document information issues.
    case metadata = "Metadata"

    /// General structural issue not covered by other categories.
    case structure = "Structure"

    /// Uncategorized issue.
    case other = "Other"
}

// MARK: - WCAG Issue

/// A single WCAG accessibility issue found during validation.
///
/// Represents a specific accessibility problem detected in the PDF document,
/// including its location, severity, and a human-readable description.
public struct WCAGIssue: Sendable, Equatable, Identifiable {

    /// Unique identifier for this issue.
    public let id: UUID

    /// The severity of this issue.
    public let severity: WCAGIssueSeverity

    /// The category of this issue.
    public let category: WCAGIssueCategory

    /// A human-readable description of the issue.
    public let message: String

    /// The WCAG success criterion reference (e.g., "1.1.1", "2.4.6").
    public let successCriterion: String?

    /// The page number where the issue was found (1-based), if applicable.
    public let pageNumber: Int?

    /// The structure element type involved, if applicable.
    public let structureElementType: String?

    /// The object context where the issue was found.
    public let context: ObjectContext?

    /// Creates a WCAG issue.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - severity: The issue severity.
    ///   - category: The issue category.
    ///   - message: A human-readable description.
    ///   - successCriterion: The WCAG success criterion reference.
    ///   - pageNumber: The page number.
    ///   - structureElementType: The structure element type.
    ///   - context: The object context.
    public init(
        id: UUID = UUID(),
        severity: WCAGIssueSeverity,
        category: WCAGIssueCategory,
        message: String,
        successCriterion: String? = nil,
        pageNumber: Int? = nil,
        structureElementType: String? = nil,
        context: ObjectContext? = nil
    ) {
        self.id = id
        self.severity = severity
        self.category = category
        self.message = message
        self.successCriterion = successCriterion
        self.pageNumber = pageNumber
        self.structureElementType = structureElementType
        self.context = context
    }

    public static func == (lhs: WCAGIssue, rhs: WCAGIssue) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - WCAG Validation Phase

/// The current phase of WCAG validation.
///
/// Validation proceeds through multiple phases, each checking different
/// aspects of accessibility compliance.
public enum WCAGValidationPhase: String, Sendable, Hashable, CaseIterable, Codable {

    /// Initial document-level checks (language, tagged status, metadata).
    case documentLevel = "DocumentLevel"

    /// Structure tree analysis (presence, completeness).
    case structureTree = "StructureTree"

    /// Heading hierarchy validation.
    case headings = "Headings"

    /// Table structure validation.
    case tables = "Tables"

    /// List structure validation.
    case lists = "Lists"

    /// Alternative text validation for non-text content.
    case alternativeText = "AlternativeText"

    /// Content chunk extraction and analysis.
    case contentChunks = "ContentChunks"

    /// Color contrast analysis.
    case colorContrast = "ColorContrast"

    /// Reading order validation.
    case readingOrder = "ReadingOrder"

    /// Final summary and reporting.
    case summary = "Summary"
}

// MARK: - WCAG Validation Context

/// Thread-safe context for WCAG accessibility validation.
///
/// `WCAGValidationContext` is an actor that holds the document state,
/// accumulated validation issues, and progress information during WCAG
/// accessibility validation. It replaces the Java `StaticStorages` class
/// (which used `ThreadLocal` variables) with Swift's actor model for
/// safe concurrent access.
///
/// ## Key Responsibilities
///
/// - Tracks the current validation phase
/// - Accumulates WCAG issues found during validation
/// - Holds document-level state (SA document, pages, structure)
/// - Provides progress reporting
/// - Stores content chunk containers per page
///
/// ## Relationship to veraPDF
///
/// Corresponds to `StaticStorages` from veraPDF-validation's wcag-validation
/// module. In the Java codebase, this class uses `ThreadLocal` variables to
/// store validation state per thread. In Swift, the actor model provides
/// safe concurrent access without thread-local storage.
///
/// ## Swift Adaptations
///
/// - Actor for thread-safe mutable state management
/// - Replaces Java's ThreadLocal pattern with actor isolation
/// - Structured concurrency integration
/// - Progress reporting via phase tracking
public actor WCAGValidationContext {

    // MARK: - Properties

    /// The SA document being validated.
    public private(set) var document: SADocument?

    /// The current validation phase.
    public private(set) var currentPhase: WCAGValidationPhase?

    /// All accumulated WCAG issues.
    public private(set) var issues: [WCAGIssue] = []

    /// Content chunk containers indexed by page number.
    public private(set) var pageChunks: [Int: ContentChunkContainer] = [:]

    /// Whether validation has started.
    public private(set) var isValidating: Bool = false

    /// Whether validation has completed.
    public private(set) var isComplete: Bool = false

    /// The phases that have been completed.
    public private(set) var completedPhases: [WCAGValidationPhase] = []

    /// The timestamp when validation started.
    public private(set) var startTime: Date?

    /// The timestamp when validation completed.
    public private(set) var endTime: Date?

    // MARK: - Initialization

    /// Creates a WCAG validation context.
    public init() {}

    /// Creates a WCAG validation context with an SA document.
    ///
    /// - Parameter document: The SA document to validate.
    public init(document: SADocument) {
        self.document = document
    }

    // MARK: - Lifecycle

    /// Begins WCAG validation for a document.
    ///
    /// - Parameter document: The SA document to validate.
    public func beginValidation(document: SADocument) {
        self.document = document
        self.issues = []
        self.pageChunks = [:]
        self.isValidating = true
        self.isComplete = false
        self.completedPhases = []
        self.currentPhase = nil
        self.startTime = Date()
        self.endTime = nil
    }

    /// Begins a specific validation phase.
    ///
    /// - Parameter phase: The phase to begin.
    public func beginPhase(_ phase: WCAGValidationPhase) {
        currentPhase = phase
    }

    /// Completes the current validation phase.
    public func completePhase() {
        if let phase = currentPhase {
            completedPhases.append(phase)
        }
        currentPhase = nil
    }

    /// Completes validation.
    public func completeValidation() {
        if let phase = currentPhase {
            completedPhases.append(phase)
        }
        currentPhase = nil
        isValidating = false
        isComplete = true
        endTime = Date()
    }

    /// Resets the validation context for reuse.
    public func reset() {
        document = nil
        currentPhase = nil
        issues = []
        pageChunks = [:]
        isValidating = false
        isComplete = false
        completedPhases = []
        startTime = nil
        endTime = nil
    }

    // MARK: - Issue Management

    /// Records a WCAG issue.
    ///
    /// - Parameter issue: The issue to record.
    public func addIssue(_ issue: WCAGIssue) {
        issues.append(issue)
    }

    /// Records multiple WCAG issues.
    ///
    /// - Parameter newIssues: The issues to record.
    public func addIssues(_ newIssues: [WCAGIssue]) {
        issues.append(contentsOf: newIssues)
    }

    /// Records a WCAG issue with the specified parameters.
    ///
    /// - Parameters:
    ///   - severity: The issue severity.
    ///   - category: The issue category.
    ///   - message: A human-readable description.
    ///   - successCriterion: The WCAG success criterion reference.
    ///   - pageNumber: The page number.
    ///   - structureElementType: The structure element type.
    ///   - context: The object context.
    public func recordIssue(
        severity: WCAGIssueSeverity,
        category: WCAGIssueCategory,
        message: String,
        successCriterion: String? = nil,
        pageNumber: Int? = nil,
        structureElementType: String? = nil,
        context: ObjectContext? = nil
    ) {
        let issue = WCAGIssue(
            severity: severity,
            category: category,
            message: message,
            successCriterion: successCriterion,
            pageNumber: pageNumber,
            structureElementType: structureElementType,
            context: context
        )
        issues.append(issue)
    }

    // MARK: - Content Chunks

    /// Stores content chunks for a specific page.
    ///
    /// - Parameters:
    ///   - container: The content chunk container.
    ///   - pageNumber: The page number (1-based).
    public func setChunks(_ container: ContentChunkContainer, forPage pageNumber: Int) {
        pageChunks[pageNumber] = container
    }

    /// Returns content chunks for a specific page.
    ///
    /// - Parameter pageNumber: The page number (1-based).
    /// - Returns: The content chunk container for the page, or `nil`.
    public func chunks(forPage pageNumber: Int) -> ContentChunkContainer? {
        pageChunks[pageNumber]
    }

    /// Returns all content chunks across all pages.
    public var allChunks: ContentChunkContainer {
        var allChunksList: [ContentChunk] = []
        for pageNumber in pageChunks.keys.sorted() {
            if let container = pageChunks[pageNumber] {
                allChunksList.append(contentsOf: container.chunks)
            }
        }
        return ContentChunkContainer(chunks: allChunksList)
    }

    // MARK: - Issue Queries

    /// Returns issues filtered by severity.
    ///
    /// - Parameter severity: The severity to filter by.
    /// - Returns: Issues matching the specified severity.
    public func issues(withSeverity severity: WCAGIssueSeverity) -> [WCAGIssue] {
        issues.filter { $0.severity == severity }
    }

    /// Returns issues filtered by category.
    ///
    /// - Parameter category: The category to filter by.
    /// - Returns: Issues matching the specified category.
    public func issues(inCategory category: WCAGIssueCategory) -> [WCAGIssue] {
        issues.filter { $0.category == category }
    }

    /// Returns issues for a specific page.
    ///
    /// - Parameter pageNumber: The page number (1-based).
    /// - Returns: Issues on the specified page.
    public func issues(forPage pageNumber: Int) -> [WCAGIssue] {
        issues.filter { $0.pageNumber == pageNumber }
    }

    /// The total number of issues.
    public var issueCount: Int {
        issues.count
    }

    /// The number of critical issues.
    public var criticalIssueCount: Int {
        issues(withSeverity: .critical).count
    }

    /// The number of major issues.
    public var majorIssueCount: Int {
        issues(withSeverity: .major).count
    }

    /// The number of minor issues.
    public var minorIssueCount: Int {
        issues(withSeverity: .minor).count
    }

    /// Whether there are any critical or major issues.
    public var hasSignificantIssues: Bool {
        criticalIssueCount > 0 || majorIssueCount > 0
    }

    /// The number of issue counts grouped by category.
    public var issueCountsByCategory: [WCAGIssueCategory: Int] {
        var counts: [WCAGIssueCategory: Int] = [:]
        for issue in issues {
            counts[issue.category, default: 0] += 1
        }
        return counts
    }

    /// The number of issue counts grouped by severity.
    public var issueCountsBySeverity: [WCAGIssueSeverity: Int] {
        var counts: [WCAGIssueSeverity: Int] = [:]
        for issue in issues {
            counts[issue.severity, default: 0] += 1
        }
        return counts
    }

    // MARK: - Progress

    /// The validation progress as a fraction (0.0 to 1.0).
    public var progress: Double {
        let totalPhases = Double(WCAGValidationPhase.allCases.count)
        guard totalPhases > 0 else { return 0.0 }
        return Double(completedPhases.count) / totalPhases
    }

    /// The validation duration, if validation has started.
    public var duration: TimeInterval? {
        guard let start = startTime else { return nil }
        let end = endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    // MARK: - Summary

    /// Returns a summary string describing the current validation state.
    public var summary: String {
        var parts: [String] = []

        if isComplete {
            parts.append("Complete")
        } else if isValidating {
            parts.append("Validating")
            if let phase = currentPhase {
                parts.append("phase: \(phase.rawValue)")
            }
        } else {
            parts.append("Not started")
        }

        parts.append("\(issueCount) issues")
        if criticalIssueCount > 0 { parts.append("\(criticalIssueCount) critical") }
        if majorIssueCount > 0 { parts.append("\(majorIssueCount) major") }

        let completedCount = completedPhases.count
        let totalPhases = WCAGValidationPhase.allCases.count
        parts.append("\(completedCount)/\(totalPhases) phases")

        return parts.joined(separator: ", ")
    }
}
