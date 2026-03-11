import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarParser

// MARK: - SA Layer Integration Tests
//
// These tests verify the SA layer works end-to-end:
// 1. Building an SA document from validated types
// 2. Traversing the accessibility tree
// 3. Extracting content chunks
// 4. Running WCAG validation context operations
// 5. Encoding the result to JSON

@Suite("SA Layer End-to-End Integration")
struct SALayerEndToEndIntegrationTests {

    // MARK: - Full Document Lifecycle

    @Test("Build, traverse, and encode a tagged document")
    func fullDocumentLifecycle() throws {
        // 1. Create PD-layer validated types
        let validatedDoc = ValidatedDocument.minimal(
            pdfVersion: "2.0",
            pageCount: 2,
            isTagged: true,
            language: "en"
        )
        let structTreeRoot = ValidatedStructTreeRoot.minimal()

        // 2. Create structure elements
        let heading = ValidatedStructElem.heading(level: 1)
        let para1 = ValidatedStructElem.paragraph()
        let figure = ValidatedStructElem(
            structureTypeName: "Figure",
            altText: "A photograph of a sunset"
        )
        let para2 = ValidatedStructElem.paragraph()

        // 3. Build SA document using tree builder
        let builder = SATreeBuilder()
        let saDoc = builder.buildDocument(
            from: validatedDoc,
            structTreeRoot: structTreeRoot,
            structElems: [heading, para1, figure, para2],
            inheritedLanguage: "en"
        )

        // 4. Verify SA document properties
        #expect(saDoc.isTagged)
        #expect(saDoc.language == "en")
        #expect(saDoc.pdfVersion == "2.0")
        #expect(saDoc.hasStructureRoot)
        #expect(saDoc.meetsBasicAccessibility)

        // 5. Traverse the accessibility tree
        let root = saDoc.structureRoot
        #expect(root != nil)
        #expect(root?.childCount == 4)
        let allNodes = root?.allNodes ?? []
        #expect(allNodes.count == 4)

        // 6. Check heading traversal
        let headings = root?.headings ?? []
        #expect(headings.count == 1)
        #expect(headings.first?.isHeading == true)

        // 7. Check figure traversal
        let figures = root?.figures ?? []
        #expect(figures.count == 1)
        #expect(figures.first?.hasAltText == true)

        // 8. Compute accessibility summary
        let summary = saDoc.accessibilitySummary()
        #expect(summary.totalElements == 4)
        #expect(summary.headingCount == 1)
        #expect(summary.figureCount == 1)
        #expect(summary.missingAltTextCount == 0)

        // 9. Encode to JSON
        let encoder = SADocumentEncoder.default()
        let jsonData = try encoder.encode(saDoc)
        #expect(!jsonData.isEmpty)

        // 10. Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        #expect(json?["pdfVersion"] as? String == "2.0")
        #expect(json?["language"] as? String == "en")
        #expect(json?["isTagged"] as? Bool == true)
        #expect(json?["meetsBasicAccessibility"] as? Bool == true)

        let structRoot = json?["structureRoot"] as? [String: Any]
        #expect(structRoot != nil)
        #expect(structRoot?["childCount"] as? Int == 4)
    }

    @Test("Build and validate an inaccessible document")
    func inaccessibleDocument() throws {
        // Document without language, without structure tree
        let validatedDoc = ValidatedDocument.minimal(
            pdfVersion: "1.4",
            pageCount: 1,
            isTagged: false
        )

        let builder = SATreeBuilder()
        let saDoc = builder.buildDocument(from: validatedDoc)

        // Verify it fails basic accessibility
        #expect(!saDoc.isTagged)
        #expect(saDoc.language == nil)
        #expect(!saDoc.hasStructureRoot)
        #expect(!saDoc.meetsBasicAccessibility)

        // Summary should be empty
        let summary = saDoc.accessibilitySummary()
        #expect(summary.totalElements == 0)

        // Encode
        let encoder = SADocumentEncoder.default()
        let jsonString = try encoder.encodeToString(saDoc)
        #expect(jsonString.contains("\"meetsBasicAccessibility\" : false"))
    }

    // MARK: - Structure Element Tree Integration

    @Test("Build deep structure element tree and traverse")
    func deepStructureElementTree() {
        // Build a multi-level structure tree:
        // Document
        //   Sect
        //     H1
        //     P
        //     Table
        //       TR
        //         TH
        //         TD

        let td = SAStructureElement.minimal(typeName: "TD")
        let th = SAStructureElement.minimal(typeName: "TH")
        let tr = SAStructureElement.minimal(typeName: "TR", children: [th, td])
        let table = SAStructureElement.minimal(typeName: "Table", children: [tr])
        let h1 = SAStructureElement.heading(level: 1, language: "en")
        let para = SAStructureElement.paragraph(language: "en")
        let sect = SAStructureElement.minimal(
            typeName: "Sect",
            children: [h1, para, table],
            language: "en"
        )

        // Traverse descendants
        let allDescendants = sect.allDescendants
        #expect(allDescendants.count == 6) // h1, para, table, tr, th, td

        // Find headings
        let headings = sect.headingDescendants
        #expect(headings.count == 1)

        // Find table elements
        let tables = sect.descendants(ofType: .table)
        #expect(tables.count == 1)

        // Children's standard types
        #expect(sect.kidsStandardTypes == "H1&P&Table")

        // Accessibility summary
        let summary = sect.accessibilitySummary()
        #expect(summary.totalElements == 7) // includes self
        #expect(summary.headingCount == 1)
        #expect(summary.tableCount == 4) // all table-related elements (Table, TR, TH, TD)
    }

    @Test("SAStructureElement from ValidatedStructureElement recursive")
    func structureElementFromValidated() {
        let childValidated = ValidatedStructureElement(
            originalTypeName: "P",
            depth: 1,
            effectiveLanguage: "en"
        )
        let parentValidated = ValidatedStructureElement(
            originalTypeName: "Sect",
            children: [childValidated],
            effectiveLanguage: "en"
        )

        let saElement = SAStructureElement.from(parentValidated)
        #expect(saElement.resolvedTypeName == "Sect")
        #expect(saElement.childCount == 1)
        #expect(saElement.children[0].resolvedTypeName == "P")
    }

    // MARK: - Content Chunk Integration

    @Test("Parse content stream and create chunk container")
    func contentChunkParsing() {
        // Create a content stream with text and path operators
        let operators: [ValidatedOperator] = [
            .saveGraphicsState,
            .beginText,
            .setFont(name: ASAtom("F1"), size: 12.0),
            .showText(Data("Hello".utf8)),
            .endText,
            .moveTo(x: 10.0, y: 20.0),
            .lineTo(x: 100.0, y: 20.0),
            .stroke,
            .restoreGraphicsState
        ]
        let stream = ValidatedContentStream(
            pageNumber: 1,
            operators: operators
        )

        // Parse the stream
        let parser = ContentChunkParser.default()
        let container = parser.parse(stream)

        // Verify chunks were created
        #expect(container.count >= 2) // at least text + path
        #expect(!container.textChunks.isEmpty)
        #expect(!container.pathChunks.isEmpty)
    }

    @Test("Content chunks from multiple pages")
    func multiPageChunks() {
        let stream1 = ValidatedContentStream(
            pageNumber: 1,
            operators: [.beginText, .showText(Data("Page 1".utf8)), .endText]
        )
        let stream2 = ValidatedContentStream(
            pageNumber: 2,
            operators: [.beginText, .showText(Data("Page 2".utf8)), .endText]
        )

        let parser = ContentChunkParser.default()
        let container = parser.parse([stream1, stream2])

        #expect(container.count >= 2)
        #expect(container.pageNumbers.contains(1))
        #expect(container.pageNumbers.contains(2))
        #expect(!container.chunks(forPage: 1).isEmpty)
        #expect(!container.chunks(forPage: 2).isEmpty)
    }

    @Test("Content chunks with marked content boundaries")
    func markedContentChunks() {
        let operators: [ValidatedOperator] = [
            .beginMarkedContentWithProperties(tag: ASAtom("P"), properties: .dictionary([ASAtom("MCID"): .integer(42)])),
            .beginText,
            .showText(Data("Tagged text".utf8)),
            .endText,
            .endMarkedContent
        ]
        let stream = ValidatedContentStream(pageNumber: 1, operators: operators)
        let parser = ContentChunkParser.default()
        let container = parser.parse(stream)

        // Text chunk should have MCID
        let textChunks = container.textChunks
        #expect(!textChunks.isEmpty)
        let firstText = textChunks.first
        #expect(firstText?.markedContentID == 42)
        #expect(firstText?.markedContentTag == "P")
        #expect(firstText?.isMarkedContent == true)
    }

    // MARK: - WCAG Validation Context Integration

    @Test("Full WCAG validation lifecycle")
    func wcagValidationLifecycle() async {
        // 1. Create an SA document
        let doc = SADocument.accessible(pdfVersion: "2.0", language: "en")
        let context = WCAGValidationContext()

        // 2. Begin validation
        await context.beginValidation(document: doc)
        let isValidating = await context.isValidating
        #expect(isValidating)

        // 3. Run phases
        await context.beginPhase(.documentLevel)
        // Simulate document-level checks
        let docFromCtx = await context.document
        #expect(docFromCtx?.isTagged == true)
        await context.completePhase()

        await context.beginPhase(.structureTree)
        await context.completePhase()

        await context.beginPhase(.alternativeText)
        // Record an issue
        await context.recordIssue(
            severity: .major,
            category: .alternativeText,
            message: "Figure on page 3 missing alt text",
            successCriterion: "1.1.1",
            pageNumber: 3,
            structureElementType: "Figure"
        )
        await context.completePhase()

        // 4. Store content chunks
        let chunks = ContentChunkContainer(chunks: [
            ContentChunk.text(pageNumber: 1),
            ContentChunk.image(pageNumber: 1)
        ])
        await context.setChunks(chunks, forPage: 1)

        // 5. Complete validation
        await context.completeValidation()

        // 6. Verify results
        let isComplete = await context.isComplete
        #expect(isComplete)

        let issueCount = await context.issueCount
        #expect(issueCount == 1)

        let completedPhases = await context.completedPhases
        #expect(completedPhases.count == 3)

        let progress = await context.progress
        #expect(progress > 0.0)

        let pageChunks = await context.chunks(forPage: 1)
        #expect(pageChunks?.count == 2)

        let hasSignificant = await context.hasSignificantIssues
        #expect(hasSignificant) // has major issue
    }

    @Test("WCAG context issue filtering")
    func wcagContextIssueFiltering() async {
        let context = WCAGValidationContext()
        let doc = SADocument.minimal()
        await context.beginValidation(document: doc)

        // Add various issues
        await context.addIssue(WCAGIssue(severity: .critical, category: .taggedStructure, message: "Not tagged"))
        await context.addIssue(WCAGIssue(severity: .major, category: .language, message: "No language"))
        await context.addIssue(WCAGIssue(severity: .minor, category: .headingHierarchy, message: "Heading skip", pageNumber: 2))
        await context.addIssue(WCAGIssue(severity: .informational, category: .metadata, message: "Missing title"))

        // Filter by severity
        let critical = await context.issues(withSeverity: .critical)
        #expect(critical.count == 1)

        let major = await context.issues(withSeverity: .major)
        #expect(major.count == 1)

        // Filter by category
        let langIssues = await context.issues(inCategory: .language)
        #expect(langIssues.count == 1)

        // Filter by page
        let page2Issues = await context.issues(forPage: 2)
        #expect(page2Issues.count == 1)

        // Counts
        let countsBySeverity = await context.issueCountsBySeverity
        #expect(countsBySeverity[.critical] == 1)
        #expect(countsBySeverity[.major] == 1)
        #expect(countsBySeverity[.minor] == 1)
        #expect(countsBySeverity[.informational] == 1)

        let countsByCategory = await context.issueCountsByCategory
        #expect(countsByCategory[.taggedStructure] == 1)
    }

    // MARK: - End-to-End: Build -> Validate -> Encode

    @Test("End-to-end: build SA document, validate, and encode report")
    func endToEndBuildValidateEncode() async throws {
        // 1. Build the SA document from PD-layer types
        let validatedDoc = ValidatedDocument.minimal(
            pdfVersion: "2.0",
            pageCount: 3,
            isTagged: true,
            language: "en"
        )
        let root = ValidatedStructTreeRoot.minimal()
        let elems = [
            ValidatedStructElem.heading(level: 1),
            ValidatedStructElem.paragraph(),
            ValidatedStructElem(structureTypeName: "Figure", altText: "Photo"),
            ValidatedStructElem(structureTypeName: "Figure"), // missing alt text
            ValidatedStructElem.paragraph()
        ]

        let builder = SATreeBuilder()
        let saDoc = builder.buildDocument(
            from: validatedDoc,
            structTreeRoot: root,
            structElems: elems,
            inheritedLanguage: "en"
        )

        // 2. Validate using WCAG context
        let context = WCAGValidationContext()
        await context.beginValidation(document: saDoc)

        await context.beginPhase(.documentLevel)
        if saDoc.language == nil {
            await context.recordIssue(
                severity: .critical,
                category: .language,
                message: "Document missing language",
                successCriterion: "3.1.1"
            )
        }
        await context.completePhase()

        await context.beginPhase(.alternativeText)
        let figureNodes = saDoc.structureRoot?.figures ?? []
        for fig in figureNodes {
            if !fig.hasAltText && !fig.hasActualText {
                await context.recordIssue(
                    severity: .critical,
                    category: .alternativeText,
                    message: "Figure missing alternative text",
                    successCriterion: "1.1.1",
                    pageNumber: fig.pageNumber,
                    structureElementType: "Figure"
                )
            }
        }
        await context.completePhase()

        await context.completeValidation()

        // 3. Collect issues
        let issues = await context.issues
        #expect(issues.count == 1) // one figure missing alt text

        // 4. Encode the report
        let encoder = SADocumentEncoder.default()
        let report = encoder.generateReport(for: saDoc, issues: issues)
        #expect(report.issueCount == 1)
        #expect(report.criticalIssueCount == 1)
        #expect(report.documentSummary.meetsBasicAccessibility == true)

        // 5. Encode to JSON
        let jsonData = try encoder.encodeReport(for: saDoc, issues: issues)
        #expect(!jsonData.isEmpty)

        // 6. Verify JSON roundtrip of report
        let decoder = JSONDecoder()
        let decodedReport = try decoder.decode(SAValidationReport.self, from: jsonData)
        #expect(decodedReport.issueCount == 1)
        #expect(decodedReport.documentSummary.pdfVersion == "2.0")
        #expect(decodedReport.documentSummary.language == "en")
    }

    // MARK: - Encoder Configuration Variants

    @Test("Compact encoding produces smaller output than pretty printing")
    func compactVsPrettyPrinted() throws {
        let doc = SADocument.accessible(language: "en")
        let compactEncoder = SADocumentEncoder.compact()
        let prettyEncoder = SADocumentEncoder.default()

        let compactData = try compactEncoder.encode(doc)
        let prettyData = try prettyEncoder.encode(doc)

        #expect(compactData.count < prettyData.count)
    }

    @Test("Minimal encoding excludes structure tree")
    func minimalExcludesStructureTree() throws {
        let node = SANode.paragraph(language: "en")
        let root = SAStructureRoot.minimal(children: [node])
        let doc = SADocument(
            document: ValidatedDocument.minimal(isTagged: true, language: "en"),
            structureRoot: root
        )

        let minimalEncoder = SADocumentEncoder.minimal()
        let data = try minimalEncoder.encode(doc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        // structureRoot should be null when excluded
        #expect(json?["structureRoot"] is NSNull || json?["structureRoot"] == nil)
    }

    // MARK: - Content Chunk + Encoding Integration

    @Test("Create chunks, add to context, encode")
    func chunksContextEncoding() async throws {
        // Create chunks from operators
        let factory = ContentChunkFactory.default()
        let textChunk = factory.createTextChunk(
            operators: [.beginText, .showText(Data("Hello".utf8)), .endText],
            pageNumber: 1,
            markedContentTag: "P",
            markedContentID: 1
        )
        let imageChunk = factory.createImageChunk(
            operators: [.invokeXObject(ASAtom("Im1"))],
            pageNumber: 1,
            markedContentTag: "Figure",
            markedContentID: 2
        )

        let container = ContentChunkContainer(chunks: [textChunk, imageChunk])

        // Verify container queries
        #expect(container.textChunks.count == 1)
        #expect(container.imageChunks.count == 1)
        #expect(container.markedContentChunks.count == 2)
        #expect(container.unmarkedContentChunks.isEmpty)

        // Encode
        let encoder = SADocumentEncoder.default()
        let data = try encoder.encode(container)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["count"] as? Int == 2)

        let chunksJSON = json?["chunks"] as? [[String: Any]]
        #expect(chunksJSON?.count == 2)
        #expect(chunksJSON?[0]["type"] as? String == "Text")
        #expect(chunksJSON?[1]["type"] as? String == "Image")
    }

    // MARK: - SANode Tree Navigation

    @Test("Navigate complex node tree")
    func navigateComplexNodeTree() {
        // Build a complex tree
        let span1 = SANode.minimal(typeName: "Span")
        let span2 = SANode.minimal(typeName: "Span")
        let para1 = SANode.minimal(typeName: "P", children: [span1, span2])
        let figWithAlt = SANode.figure(altText: "Description")
        let figWithoutAlt = SANode.figure()
        let h1 = SANode.heading(level: 1, language: "en")
        let h2 = SANode.heading(level: 2, language: "en")
        let sect = SANode.minimal(
            typeName: "Sect",
            children: [h1, para1, figWithAlt, figWithoutAlt, h2]
        )

        // Tree navigation
        #expect(sect.allDescendants.count == 7) // all nodes below sect
        #expect(sect.headingDescendants.count == 2)
        #expect(sect.figureDescendants.count == 2)

        // Accessibility checks
        #expect(sect.hasAccessibilityIssues == true) // figWithoutAlt has no alt text

        // Node summaries
        #expect(h1.summary.contains("H1"))
    }

    // MARK: - SAObject Protocol Behavior

    @Test("All SA types implement SAObject protocol correctly")
    func saObjectProtocolConformance() {
        // SADocument
        let doc = SADocument.minimal()
        #expect(doc.saObjectType == "SADocument")
        #expect(!doc.accessibilityPropertyNames.isEmpty)

        // SAPage
        let page = SAPage.minimal()
        #expect(page.saObjectType == "SAPage")
        #expect(page.accessibilityProperty(named: "pageNumber") != nil)

        // SAStructureRoot
        let root = SAStructureRoot.minimal()
        #expect(root.saObjectType == "SAStructureRoot")
        #expect(root.accessibilityProperty(named: "childCount") != nil)

        // SANode
        let node = SANode.heading(level: 1)
        #expect(node.saObjectType == "SANode")
        #expect(node.accessibilityProperty(named: "isHeading")?.booleanValue == true)

        // SAStructureElement
        let elem = SAStructureElement.paragraph(language: "en")
        #expect(elem.saObjectType == "SAStructureElement")
        #expect(elem.accessibilityProperty(named: "effectiveLanguage") != nil)
    }

    // MARK: - Encoding Nested Structure

    @Test("Encode deeply nested structure preserves hierarchy")
    func encodeDeeplyNestedStructure() throws {
        let leaf = SANode.minimal(typeName: "Span")
        let innerPara = SANode.minimal(typeName: "P", children: [leaf])
        let listItem = SANode.minimal(typeName: "LI", children: [innerPara])
        let list = SANode.minimal(typeName: "L", children: [listItem])
        let root = SAStructureRoot.minimal(children: [list])
        let doc = SADocument(
            document: ValidatedDocument.minimal(isTagged: true, language: "en"),
            structureRoot: root
        )

        let encoder = SADocumentEncoder.default()
        let data = try encoder.encode(doc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Navigate into nested structure
        let rootJSON = json?["structureRoot"] as? [String: Any]
        let children = rootJSON?["children"] as? [[String: Any]]
        let listJSON = children?.first
        #expect(listJSON?["structureTypeName"] as? String == "L")

        let listChildren = listJSON?["children"] as? [[String: Any]]
        let liJSON = listChildren?.first
        #expect(liJSON?["structureTypeName"] as? String == "LI")

        let liChildren = liJSON?["children"] as? [[String: Any]]
        let pJSON = liChildren?.first
        #expect(pJSON?["structureTypeName"] as? String == "P")

        let pChildren = pJSON?["children"] as? [[String: Any]]
        let spanJSON = pChildren?.first
        #expect(spanJSON?["structureTypeName"] as? String == "Span")
        #expect(spanJSON?["childCount"] as? Int == 0)
    }
}

// MARK: - PropertyValue Extension for Tests

extension PropertyValue {

    /// Extracts the boolean value, if present.
    var booleanValue: Bool? {
        if case .boolean(let b) = self { return b }
        return nil
    }
}
