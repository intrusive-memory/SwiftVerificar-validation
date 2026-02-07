import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - SADocumentEncoder Tests

@Suite("SADocumentEncoder")
struct SADocumentEncoderTests {

    // MARK: - Initialization

    @Test("Default encoder has pretty printing enabled")
    func defaultEncoderPrettyPrinted() {
        let encoder = SADocumentEncoder.default()
        #expect(encoder.prettyPrinted == true)
        #expect(encoder.sortedKeys == false)
        #expect(encoder.includeNullValues == false)
        #expect(encoder.includeStructureTree == true)
        #expect(encoder.includeContentChunks == false)
        #expect(encoder.includeIssues == true)
    }

    @Test("Compact encoder has pretty printing disabled")
    func compactEncoder() {
        let encoder = SADocumentEncoder.compact()
        #expect(encoder.prettyPrinted == false)
        #expect(encoder.sortedKeys == false)
    }

    @Test("Full encoder includes all data")
    func fullEncoder() {
        let encoder = SADocumentEncoder.full()
        #expect(encoder.prettyPrinted == true)
        #expect(encoder.sortedKeys == true)
        #expect(encoder.includeNullValues == true)
        #expect(encoder.includeStructureTree == true)
        #expect(encoder.includeContentChunks == true)
        #expect(encoder.includeIssues == true)
    }

    @Test("Minimal encoder excludes structure tree")
    func minimalEncoder() {
        let encoder = SADocumentEncoder.minimal()
        #expect(encoder.prettyPrinted == false)
        #expect(encoder.includeStructureTree == false)
        #expect(encoder.includeContentChunks == false)
        #expect(encoder.includeIssues == false)
    }

    @Test("Custom encoder configuration")
    func customEncoder() {
        let encoder = SADocumentEncoder(
            prettyPrinted: false,
            sortedKeys: true,
            includeNullValues: true,
            includeStructureTree: false,
            includeContentChunks: true,
            includeIssues: false
        )
        #expect(encoder.prettyPrinted == false)
        #expect(encoder.sortedKeys == true)
        #expect(encoder.includeNullValues == true)
        #expect(encoder.includeStructureTree == false)
        #expect(encoder.includeContentChunks == true)
        #expect(encoder.includeIssues == false)
    }

    // MARK: - Document Encoding

    @Test("Encode minimal document produces valid JSON")
    func encodeMinimalDocument() throws {
        let encoder = SADocumentEncoder.default()
        let doc = SADocument.minimal(pdfVersion: "1.7", pageCount: 1, isTagged: false)
        let data = try encoder.encode(doc)
        #expect(!data.isEmpty)

        // Verify it's valid JSON
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json != nil)
        #expect(json?["pdfVersion"] as? String == "1.7")
        #expect(json?["pageCount"] as? Int == 1)
        #expect(json?["isTagged"] as? Bool == false)
        #expect(json?["saObjectType"] as? String == "SADocument")
    }

    @Test("Encode accessible document includes language")
    func encodeAccessibleDocument() throws {
        let encoder = SADocumentEncoder.default()
        let doc = SADocument.accessible(pdfVersion: "2.0", language: "en")
        let data = try encoder.encode(doc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["language"] as? String == "en")
        #expect(json?["isTagged"] as? Bool == true)
        #expect(json?["hasStructureRoot"] as? Bool == true)
        #expect(json?["meetsBasicAccessibility"] as? Bool == true)
    }

    @Test("Encode document to string produces UTF-8 string")
    func encodeDocumentToString() throws {
        let encoder = SADocumentEncoder.compact()
        let doc = SADocument.minimal()
        let string = try encoder.encodeToString(doc)
        #expect(!string.isEmpty)
        #expect(string.contains("SADocument"))
        #expect(string.contains("pdfVersion"))
    }

    @Test("Encode document with pages includes page data")
    func encodeDocumentWithPages() throws {
        let encoder = SADocumentEncoder.default()
        let page1 = SAPage.minimal(pageNumber: 1)
        let page2 = SAPage.minimal(pageNumber: 2)
        let doc = SADocument(
            document: ValidatedDocument.minimal(pageCount: 2),
            pages: [page1, page2]
        )
        let data = try encoder.encode(doc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let pages = json?["pages"] as? [[String: Any]]
        #expect(pages?.count == 2)
        #expect(pages?[0]["pageNumber"] as? Int == 1)
        #expect(pages?[1]["pageNumber"] as? Int == 2)
    }

    @Test("Encode document without structure tree when disabled")
    func encodeDocumentWithoutStructureTree() throws {
        let encoder = SADocumentEncoder(includeStructureTree: false)
        let doc = SADocument.accessible()
        let data = try encoder.encode(doc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        // structureRoot should be null when excluded
        #expect(json?["structureRoot"] is NSNull || json?["structureRoot"] == nil)
    }

    @Test("Encode document with structure root includes tree")
    func encodeDocumentWithStructureRoot() throws {
        let encoder = SADocumentEncoder.default()
        let node = SANode.paragraph(language: "en")
        let root = SAStructureRoot.minimal(children: [node])
        let doc = SADocument(
            document: ValidatedDocument.minimal(isTagged: true, language: "en"),
            structureRoot: root
        )
        let data = try encoder.encode(doc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rootJSON = json?["structureRoot"] as? [String: Any]
        #expect(rootJSON != nil)
        #expect(rootJSON?["childCount"] as? Int == 1)
        let children = rootJSON?["children"] as? [[String: Any]]
        #expect(children?.count == 1)
    }

    // MARK: - Node Encoding

    @Test("Encode SA node produces valid JSON")
    func encodeNode() throws {
        let encoder = SADocumentEncoder.default()
        let node = SANode.heading(level: 1, language: "en")
        let data = try encoder.encode(node)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["saObjectType"] as? String == "SANode")
        #expect(json?["isHeading"] as? Bool == true)
        #expect(json?["headingLevel"] as? Int == 1)
    }

    @Test("Encode SA node with children includes recursive children")
    func encodeNodeWithChildren() throws {
        let encoder = SADocumentEncoder.default()
        let child1 = SANode.paragraph(language: "en")
        let child2 = SANode.figure(altText: "A photo")
        let parent = SANode.minimal(typeName: "Sect", children: [child1, child2])
        let data = try encoder.encode(parent)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["childCount"] as? Int == 2)
        let children = json?["children"] as? [[String: Any]]
        #expect(children?.count == 2)
    }

    // MARK: - Structure Element Encoding

    @Test("Encode SA structure element produces valid JSON")
    func encodeStructureElement() throws {
        let encoder = SADocumentEncoder.default()
        let element = SAStructureElement.heading(level: 2, language: "fr")
        let data = try encoder.encode(element)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["saObjectType"] as? String == "SAStructureElement")
        #expect(json?["isHeading"] as? Bool == true)
        #expect(json?["headingLevel"] as? Int == 2)
    }

    @Test("Encode structure element with remapped type")
    func encodeRemappedElement() throws {
        let encoder = SADocumentEncoder.default()
        let validated = ValidatedStructureElement(
            originalTypeName: "CustomPara",
            resolvedTypeName: "P",
            effectiveLanguage: "en"
        )
        let element = SAStructureElement(validatedElement: validated)
        let data = try encoder.encode(element)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["originalTypeName"] as? String == "CustomPara")
        #expect(json?["resolvedTypeName"] as? String == "P")
        #expect(json?["wasRemapped"] as? Bool == true)
    }

    // MARK: - Content Chunk Encoding

    @Test("Encode content chunk container produces valid JSON")
    func encodeChunkContainer() throws {
        let encoder = SADocumentEncoder.default()
        let chunks = [
            ContentChunk.text(pageNumber: 1),
            ContentChunk.image(pageNumber: 1),
            ContentChunk.text(pageNumber: 2)
        ]
        let container = ContentChunkContainer(chunks: chunks)
        let data = try encoder.encode(container)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["count"] as? Int == 3)
        let pageNumbers = json?["pageNumbers"] as? [Int]
        #expect(pageNumbers?.contains(1) == true)
        #expect(pageNumbers?.contains(2) == true)
    }

    // MARK: - WCAG Issue Encoding

    @Test("Encode WCAG issues produces valid JSON array")
    func encodeWCAGIssues() throws {
        let encoder = SADocumentEncoder.default()
        let issues = [
            WCAGIssue(
                severity: .critical,
                category: .alternativeText,
                message: "Figure missing alt text",
                successCriterion: "1.1.1",
                pageNumber: 3,
                structureElementType: "Figure"
            ),
            WCAGIssue(
                severity: .major,
                category: .language,
                message: "Document missing language",
                successCriterion: "3.1.1"
            )
        ]
        let data = try encoder.encode(issues)
        let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(json?.count == 2)
        #expect(json?[0]["severity"] as? String == "Critical")
        #expect(json?[0]["category"] as? String == "AlternativeText")
        #expect(json?[0]["message"] as? String == "Figure missing alt text")
        #expect(json?[0]["successCriterion"] as? String == "1.1.1")
        #expect(json?[0]["pageNumber"] as? Int == 3)
        #expect(json?[1]["severity"] as? String == "Major")
    }

    // MARK: - Equatable Conformance

    @Test("SADocumentEncoder is Equatable")
    func encoderEquatable() {
        let a = SADocumentEncoder.default()
        let b = SADocumentEncoder.default()
        #expect(a == b)

        let c = SADocumentEncoder.compact()
        #expect(a != c)
    }

    // MARK: - Sorted Keys

    @Test("Sorted keys encoder produces alphabetically sorted output")
    func sortedKeysEncoder() throws {
        let encoder = SADocumentEncoder(prettyPrinted: false, sortedKeys: true)
        let doc = SADocument.minimal()
        let string = try encoder.encodeToString(doc)
        // In sorted output, "hasStructureRoot" should come before "id"
        if let hasIdx = string.range(of: "hasStructureRoot"),
           let idIdx = string.range(of: "\"id\"") {
            #expect(hasIdx.lowerBound < idIdx.lowerBound)
        }
    }

    // MARK: - Roundtrip DTOs

    @Test("SADocumentDTO roundtrips through JSON")
    func documentDTORoundtrip() throws {
        let dto = SADocumentDTO(
            id: "test-id",
            saObjectType: "SADocument",
            pdfVersion: "2.0",
            pageCount: 5,
            isTagged: true,
            language: "en",
            hasStructureRoot: true,
            meetsBasicAccessibility: true,
            pages: [],
            structureRoot: nil
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SADocumentDTO.self, from: data)
        #expect(decoded == dto)
    }

    @Test("SANodeDTO roundtrips through JSON")
    func nodeDTORoundtrip() throws {
        let dto = SANodeDTO(
            id: "node-1",
            saObjectType: "SANode",
            structureTypeName: "H1",
            structureType: "H1",
            altText: nil,
            actualText: nil,
            language: "en",
            effectiveLanguage: "en",
            inheritedLanguage: nil,
            isHeading: true,
            headingLevel: 1,
            isFigure: false,
            isArtifact: false,
            isAccessible: true,
            pageNumber: 1,
            childCount: 0,
            children: []
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SANodeDTO.self, from: data)
        #expect(decoded == dto)
    }

    @Test("SAStructureElementDTO roundtrips through JSON")
    func structureElementDTORoundtrip() throws {
        let dto = SAStructureElementDTO(
            id: "elem-1",
            saObjectType: "SAStructureElement",
            originalTypeName: "P",
            resolvedTypeName: "P",
            resolvedType: "P",
            wasRemapped: false,
            isStandardType: true,
            altText: nil,
            actualText: nil,
            expansionText: nil,
            effectiveLanguage: "en",
            hasOwnLanguage: true,
            depth: 1,
            siblingIndex: 0,
            pageNumber: 1,
            elementID: nil,
            namespaceURI: nil,
            isHeading: false,
            headingLevel: nil,
            isFigure: false,
            isAccessible: true,
            isAccessibilityRelevant: true,
            meetsAccessibilityRequirements: true,
            childCount: 0,
            kidsStandardTypes: "",
            children: []
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SAStructureElementDTO.self, from: data)
        #expect(decoded == dto)
    }

    @Test("WCAGIssueDTO roundtrips through JSON")
    func issueDTORoundtrip() throws {
        let dto = WCAGIssueDTO(
            id: "issue-1",
            severity: "Critical",
            category: "AlternativeText",
            message: "Figure missing alt text",
            successCriterion: "1.1.1",
            pageNumber: 2,
            structureElementType: "Figure"
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WCAGIssueDTO.self, from: data)
        #expect(decoded == dto)
    }

    @Test("ContentChunkDTO roundtrips through JSON")
    func chunkDTORoundtrip() throws {
        let dto = ContentChunkDTO(
            id: "chunk-1",
            type: "Text",
            pageNumber: 1,
            sequenceIndex: 0,
            operatorCount: 5,
            markedContentTag: "P",
            markedContentID: 3,
            structureElementType: "P",
            graphicsStateDepth: 1,
            isMarkedContent: true,
            isText: true,
            isImage: false,
            isPath: false
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ContentChunkDTO.self, from: data)
        #expect(decoded == dto)
    }

    @Test("ContentChunkContainerDTO roundtrips through JSON")
    func chunkContainerDTORoundtrip() throws {
        let dto = ContentChunkContainerDTO(
            count: 2,
            pageNumbers: [1, 2],
            countsByType: ["Text": 1, "Image": 1],
            chunks: []
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(dto)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ContentChunkContainerDTO.self, from: data)
        #expect(decoded == dto)
    }
}

// MARK: - SA Encoding Error Tests

@Suite("SAEncodingError")
struct SAEncodingErrorTests {

    @Test("SAEncodingError cases are Equatable")
    func errorEquatable() {
        let a = SAEncodingError.stringConversionFailed
        let b = SAEncodingError.stringConversionFailed
        #expect(a == b)

        let c = SAEncodingError.encodingFailed("test")
        let d = SAEncodingError.encodingFailed("test")
        #expect(c == d)

        let e = SAEncodingError.invalidInput("bad")
        let f = SAEncodingError.invalidInput("bad")
        #expect(e == f)

        #expect(a != c)
    }

    @Test("SAEncodingError conforms to Error")
    func errorConformsToError() {
        let error: Error = SAEncodingError.stringConversionFailed
        #expect(error is SAEncodingError)
    }
}
