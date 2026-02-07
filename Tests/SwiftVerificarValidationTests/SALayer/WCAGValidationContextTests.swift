import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - WCAGIssueSeverity Tests

@Suite("WCAGIssueSeverity")
struct WCAGIssueSeverityTests {

    @Test("Raw values are correct")
    func rawValues() {
        #expect(WCAGIssueSeverity.critical.rawValue == "Critical")
        #expect(WCAGIssueSeverity.major.rawValue == "Major")
        #expect(WCAGIssueSeverity.minor.rawValue == "Minor")
        #expect(WCAGIssueSeverity.informational.rawValue == "Informational")
    }

    @Test("CaseIterable provides all cases")
    func caseIterable() {
        #expect(WCAGIssueSeverity.allCases.count == 4)
    }

    @Test("Comparable ordering: critical > major > minor > informational")
    func comparable() {
        #expect(WCAGIssueSeverity.informational < WCAGIssueSeverity.minor)
        #expect(WCAGIssueSeverity.minor < WCAGIssueSeverity.major)
        #expect(WCAGIssueSeverity.major < WCAGIssueSeverity.critical)
        #expect(WCAGIssueSeverity.informational < WCAGIssueSeverity.critical)
    }

    @Test("Hashable works for sets and dictionaries")
    func hashable() {
        var set: Set<WCAGIssueSeverity> = [.critical, .major, .critical]
        #expect(set.count == 2)
        set.insert(.minor)
        #expect(set.count == 3)
    }
}

// MARK: - WCAGIssueCategory Tests

@Suite("WCAGIssueCategory")
struct WCAGIssueCategoryTests {

    @Test("Raw values are correct")
    func rawValues() {
        #expect(WCAGIssueCategory.alternativeText.rawValue == "AlternativeText")
        #expect(WCAGIssueCategory.language.rawValue == "Language")
        #expect(WCAGIssueCategory.taggedStructure.rawValue == "TaggedStructure")
        #expect(WCAGIssueCategory.headingHierarchy.rawValue == "HeadingHierarchy")
        #expect(WCAGIssueCategory.colorContrast.rawValue == "ColorContrast")
    }

    @Test("CaseIterable provides all 14 cases")
    func caseIterable() {
        #expect(WCAGIssueCategory.allCases.count == 14)
    }
}

// MARK: - WCAGIssue Tests

@Suite("WCAGIssue")
struct WCAGIssueTests {

    @Test("Default initialization")
    func defaultInit() {
        let issue = WCAGIssue(
            severity: .critical,
            category: .alternativeText,
            message: "Figure missing alt text"
        )

        #expect(issue.severity == .critical)
        #expect(issue.category == .alternativeText)
        #expect(issue.message == "Figure missing alt text")
        #expect(issue.successCriterion == nil)
        #expect(issue.pageNumber == nil)
        #expect(issue.structureElementType == nil)
        #expect(issue.context == nil)
    }

    @Test("Full initialization")
    func fullInit() {
        let context = ObjectContext.saNode("Figure")
        let issue = WCAGIssue(
            severity: .major,
            category: .language,
            message: "Missing language tag",
            successCriterion: "3.1.1",
            pageNumber: 5,
            structureElementType: "P",
            context: context
        )

        #expect(issue.severity == .major)
        #expect(issue.category == .language)
        #expect(issue.message == "Missing language tag")
        #expect(issue.successCriterion == "3.1.1")
        #expect(issue.pageNumber == 5)
        #expect(issue.structureElementType == "P")
        #expect(issue.context == context)
    }

    @Test("Identifiable provides unique id")
    func identifiable() {
        let issue1 = WCAGIssue(severity: .minor, category: .other, message: "A")
        let issue2 = WCAGIssue(severity: .minor, category: .other, message: "A")
        #expect(issue1.id != issue2.id)
    }

    @Test("Equatable uses id")
    func equatable() {
        let id = UUID()
        let issue1 = WCAGIssue(id: id, severity: .minor, category: .other, message: "A")
        let issue2 = WCAGIssue(id: id, severity: .minor, category: .other, message: "A")
        let issue3 = WCAGIssue(severity: .minor, category: .other, message: "A")

        #expect(issue1 == issue2)
        #expect(issue1 != issue3)
    }
}

// MARK: - WCAGValidationPhase Tests

@Suite("WCAGValidationPhase")
struct WCAGValidationPhaseTests {

    @Test("Raw values are correct")
    func rawValues() {
        #expect(WCAGValidationPhase.documentLevel.rawValue == "DocumentLevel")
        #expect(WCAGValidationPhase.structureTree.rawValue == "StructureTree")
        #expect(WCAGValidationPhase.headings.rawValue == "Headings")
        #expect(WCAGValidationPhase.colorContrast.rawValue == "ColorContrast")
        #expect(WCAGValidationPhase.summary.rawValue == "Summary")
    }

    @Test("CaseIterable provides all 10 phases")
    func caseIterable() {
        #expect(WCAGValidationPhase.allCases.count == 10)
    }
}

// MARK: - WCAGValidationContext Tests

@Suite("WCAGValidationContext")
struct WCAGValidationContextTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() async {
        let context = WCAGValidationContext()

        let doc = await context.document
        let isValidating = await context.isValidating
        let isComplete = await context.isComplete
        let issueCount = await context.issueCount

        #expect(doc == nil)
        #expect(!isValidating)
        #expect(!isComplete)
        #expect(issueCount == 0)
    }

    @Test("Initialization with document")
    func initWithDocument() async {
        let saDoc = SADocument.minimal(language: "en")
        let context = WCAGValidationContext(document: saDoc)

        let doc = await context.document
        #expect(doc != nil)
    }

    // MARK: - Lifecycle Tests

    @Test("beginValidation sets up context")
    func beginValidation() async {
        let context = WCAGValidationContext()
        let saDoc = SADocument.minimal(language: "en")

        await context.beginValidation(document: saDoc)

        let isValidating = await context.isValidating
        let isComplete = await context.isComplete
        let doc = await context.document

        #expect(isValidating)
        #expect(!isComplete)
        #expect(doc != nil)
    }

    @Test("beginPhase sets current phase")
    func beginPhase() async {
        let context = WCAGValidationContext()
        let saDoc = SADocument.minimal()
        await context.beginValidation(document: saDoc)

        await context.beginPhase(.documentLevel)

        let phase = await context.currentPhase
        #expect(phase == .documentLevel)
    }

    @Test("completePhase adds to completed phases")
    func completePhase() async {
        let context = WCAGValidationContext()
        let saDoc = SADocument.minimal()
        await context.beginValidation(document: saDoc)

        await context.beginPhase(.documentLevel)
        await context.completePhase()

        let phase = await context.currentPhase
        let completed = await context.completedPhases

        #expect(phase == nil)
        #expect(completed.count == 1)
        #expect(completed.contains(.documentLevel))
    }

    @Test("completeValidation finishes validation")
    func completeValidation() async {
        let context = WCAGValidationContext()
        let saDoc = SADocument.minimal()
        await context.beginValidation(document: saDoc)
        await context.beginPhase(.documentLevel)

        await context.completeValidation()

        let isValidating = await context.isValidating
        let isComplete = await context.isComplete
        let completed = await context.completedPhases

        #expect(!isValidating)
        #expect(isComplete)
        #expect(completed.count == 1)
    }

    @Test("reset clears all state")
    func reset() async {
        let context = WCAGValidationContext()
        let saDoc = SADocument.minimal()
        await context.beginValidation(document: saDoc)
        await context.recordIssue(
            severity: .critical,
            category: .alternativeText,
            message: "Test"
        )
        await context.setChunks(
            ContentChunkContainer(chunks: [ContentChunk.text()]),
            forPage: 1
        )
        await context.completeValidation()

        await context.reset()

        let doc = await context.document
        let isValidating = await context.isValidating
        let isComplete = await context.isComplete
        let issueCount = await context.issueCount
        let pageChunks = await context.pageChunks

        #expect(doc == nil)
        #expect(!isValidating)
        #expect(!isComplete)
        #expect(issueCount == 0)
        #expect(pageChunks.isEmpty)
    }

    // MARK: - Issue Management Tests

    @Test("addIssue adds a single issue")
    func addIssue() async {
        let context = WCAGValidationContext()
        let issue = WCAGIssue(
            severity: .critical,
            category: .alternativeText,
            message: "Missing alt text"
        )

        await context.addIssue(issue)

        let count = await context.issueCount
        #expect(count == 1)
    }

    @Test("addIssues adds multiple issues")
    func addIssues() async {
        let context = WCAGValidationContext()
        let issues = [
            WCAGIssue(severity: .critical, category: .alternativeText, message: "A"),
            WCAGIssue(severity: .major, category: .language, message: "B"),
            WCAGIssue(severity: .minor, category: .headingHierarchy, message: "C")
        ]

        await context.addIssues(issues)

        let count = await context.issueCount
        #expect(count == 3)
    }

    @Test("recordIssue creates and adds issue")
    func recordIssue() async {
        let context = WCAGValidationContext()

        await context.recordIssue(
            severity: .critical,
            category: .alternativeText,
            message: "Figure has no alt text",
            successCriterion: "1.1.1",
            pageNumber: 3,
            structureElementType: "Figure"
        )

        let issues = await context.issues
        #expect(issues.count == 1)
        #expect(issues[0].severity == .critical)
        #expect(issues[0].category == .alternativeText)
        #expect(issues[0].message == "Figure has no alt text")
        #expect(issues[0].successCriterion == "1.1.1")
        #expect(issues[0].pageNumber == 3)
        #expect(issues[0].structureElementType == "Figure")
    }

    // MARK: - Content Chunks Tests

    @Test("setChunks stores chunks for a page")
    func setChunks() async {
        let context = WCAGValidationContext()
        let container = ContentChunkContainer(chunks: [ContentChunk.text(pageNumber: 1)])

        await context.setChunks(container, forPage: 1)

        let retrieved = await context.chunks(forPage: 1)
        #expect(retrieved != nil)
        #expect(retrieved?.count == 1)
    }

    @Test("chunks(forPage:) returns nil for missing page")
    func chunksForMissingPage() async {
        let context = WCAGValidationContext()
        let retrieved = await context.chunks(forPage: 99)
        #expect(retrieved == nil)
    }

    @Test("allChunks combines all page chunks")
    func allChunks() async {
        let context = WCAGValidationContext()
        await context.setChunks(
            ContentChunkContainer(chunks: [ContentChunk.text(pageNumber: 1)]),
            forPage: 1
        )
        await context.setChunks(
            ContentChunkContainer(chunks: [
                ContentChunk.text(pageNumber: 2),
                ContentChunk.image(pageNumber: 2)
            ]),
            forPage: 2
        )

        let all = await context.allChunks
        #expect(all.count == 3)
    }

    // MARK: - Issue Query Tests

    @Test("issues(withSeverity:) filters correctly")
    func issuesWithSeverity() async {
        let context = WCAGValidationContext()
        await context.addIssues([
            WCAGIssue(severity: .critical, category: .alternativeText, message: "A"),
            WCAGIssue(severity: .major, category: .language, message: "B"),
            WCAGIssue(severity: .critical, category: .taggedStructure, message: "C")
        ])

        let criticals = await context.issues(withSeverity: .critical)
        let majors = await context.issues(withSeverity: .major)
        let minors = await context.issues(withSeverity: .minor)

        #expect(criticals.count == 2)
        #expect(majors.count == 1)
        #expect(minors.isEmpty)
    }

    @Test("issues(inCategory:) filters correctly")
    func issuesInCategory() async {
        let context = WCAGValidationContext()
        await context.addIssues([
            WCAGIssue(severity: .critical, category: .alternativeText, message: "A"),
            WCAGIssue(severity: .major, category: .alternativeText, message: "B"),
            WCAGIssue(severity: .minor, category: .language, message: "C")
        ])

        let altText = await context.issues(inCategory: .alternativeText)
        let lang = await context.issues(inCategory: .language)

        #expect(altText.count == 2)
        #expect(lang.count == 1)
    }

    @Test("issues(forPage:) filters by page")
    func issuesForPage() async {
        let context = WCAGValidationContext()
        await context.addIssues([
            WCAGIssue(severity: .critical, category: .alternativeText, message: "A", pageNumber: 1),
            WCAGIssue(severity: .major, category: .language, message: "B", pageNumber: 2),
            WCAGIssue(severity: .minor, category: .other, message: "C", pageNumber: 1)
        ])

        let page1 = await context.issues(forPage: 1)
        let page2 = await context.issues(forPage: 2)
        let page3 = await context.issues(forPage: 3)

        #expect(page1.count == 2)
        #expect(page2.count == 1)
        #expect(page3.isEmpty)
    }

    // MARK: - Issue Count Tests

    @Test("criticalIssueCount counts correctly")
    func criticalIssueCount() async {
        let context = WCAGValidationContext()
        await context.addIssues([
            WCAGIssue(severity: .critical, category: .alternativeText, message: "A"),
            WCAGIssue(severity: .critical, category: .language, message: "B"),
            WCAGIssue(severity: .major, category: .other, message: "C")
        ])

        let count = await context.criticalIssueCount
        #expect(count == 2)
    }

    @Test("majorIssueCount counts correctly")
    func majorIssueCount() async {
        let context = WCAGValidationContext()
        await context.addIssues([
            WCAGIssue(severity: .major, category: .alternativeText, message: "A"),
            WCAGIssue(severity: .minor, category: .language, message: "B")
        ])

        let count = await context.majorIssueCount
        #expect(count == 1)
    }

    @Test("minorIssueCount counts correctly")
    func minorIssueCount() async {
        let context = WCAGValidationContext()
        await context.addIssues([
            WCAGIssue(severity: .minor, category: .other, message: "A"),
            WCAGIssue(severity: .minor, category: .other, message: "B")
        ])

        let count = await context.minorIssueCount
        #expect(count == 2)
    }

    @Test("hasSignificantIssues detects critical and major")
    func hasSignificantIssues() async {
        let context1 = WCAGValidationContext()
        await context1.addIssue(
            WCAGIssue(severity: .critical, category: .other, message: "A")
        )
        let hasSignificant1 = await context1.hasSignificantIssues
        #expect(hasSignificant1)

        let context2 = WCAGValidationContext()
        await context2.addIssue(
            WCAGIssue(severity: .minor, category: .other, message: "B")
        )
        let hasSignificant2 = await context2.hasSignificantIssues
        #expect(!hasSignificant2)
    }

    @Test("issueCountsByCategory groups correctly")
    func issueCountsByCategory() async {
        let context = WCAGValidationContext()
        await context.addIssues([
            WCAGIssue(severity: .critical, category: .alternativeText, message: "A"),
            WCAGIssue(severity: .major, category: .alternativeText, message: "B"),
            WCAGIssue(severity: .minor, category: .language, message: "C")
        ])

        let counts = await context.issueCountsByCategory
        #expect(counts[.alternativeText] == 2)
        #expect(counts[.language] == 1)
    }

    @Test("issueCountsBySeverity groups correctly")
    func issueCountsBySeverity() async {
        let context = WCAGValidationContext()
        await context.addIssues([
            WCAGIssue(severity: .critical, category: .other, message: "A"),
            WCAGIssue(severity: .critical, category: .other, message: "B"),
            WCAGIssue(severity: .major, category: .other, message: "C"),
            WCAGIssue(severity: .minor, category: .other, message: "D")
        ])

        let counts = await context.issueCountsBySeverity
        #expect(counts[.critical] == 2)
        #expect(counts[.major] == 1)
        #expect(counts[.minor] == 1)
    }

    // MARK: - Progress Tests

    @Test("progress returns fraction of completed phases")
    func progress() async {
        let context = WCAGValidationContext()
        let saDoc = SADocument.minimal()
        await context.beginValidation(document: saDoc)

        let initialProgress = await context.progress
        #expect(initialProgress == 0.0)

        await context.beginPhase(.documentLevel)
        await context.completePhase()
        await context.beginPhase(.structureTree)
        await context.completePhase()

        let midProgress = await context.progress
        let expectedProgress = 2.0 / Double(WCAGValidationPhase.allCases.count)
        #expect(midProgress == expectedProgress)
    }

    @Test("duration returns time since start")
    func duration() async {
        let context = WCAGValidationContext()

        let noDuration = await context.duration
        #expect(noDuration == nil)

        let saDoc = SADocument.minimal()
        await context.beginValidation(document: saDoc)

        let hasDuration = await context.duration
        #expect(hasDuration != nil)
        #expect(hasDuration ?? 0 >= 0)
    }

    // MARK: - Summary Tests

    @Test("summary describes current state")
    func summary() async {
        let context = WCAGValidationContext()

        let notStarted = await context.summary
        #expect(notStarted.contains("Not started"))

        let saDoc = SADocument.minimal()
        await context.beginValidation(document: saDoc)
        await context.beginPhase(.documentLevel)

        let validating = await context.summary
        #expect(validating.contains("Validating"))
        #expect(validating.contains("DocumentLevel"))

        await context.completePhase()
        await context.completeValidation()

        let complete = await context.summary
        #expect(complete.contains("Complete"))
    }

    @Test("summary includes issue counts")
    func summaryWithIssues() async {
        let context = WCAGValidationContext()
        await context.addIssues([
            WCAGIssue(severity: .critical, category: .other, message: "A"),
            WCAGIssue(severity: .major, category: .other, message: "B"),
            WCAGIssue(severity: .minor, category: .other, message: "C")
        ])

        let summary = await context.summary
        #expect(summary.contains("3 issues"))
        #expect(summary.contains("1 critical"))
        #expect(summary.contains("1 major"))
    }

    // MARK: - Multiple Phase Flow Tests

    @Test("Full validation flow through multiple phases")
    func fullValidationFlow() async {
        let context = WCAGValidationContext()
        let saDoc = SADocument.accessible(language: "en")
        await context.beginValidation(document: saDoc)

        // Phase 1: Document level
        await context.beginPhase(.documentLevel)
        await context.recordIssue(
            severity: .informational,
            category: .metadata,
            message: "Document has correct language"
        )
        await context.completePhase()

        // Phase 2: Structure tree
        await context.beginPhase(.structureTree)
        await context.completePhase()

        // Phase 3: Headings
        await context.beginPhase(.headings)
        await context.recordIssue(
            severity: .major,
            category: .headingHierarchy,
            message: "Heading level skipped: H1 to H3"
        )
        await context.completePhase()

        await context.completeValidation()

        let issueCount = await context.issueCount
        let completed = await context.completedPhases
        let isComplete = await context.isComplete

        #expect(issueCount == 2)
        #expect(completed.count == 3)
        #expect(isComplete)
    }
}
