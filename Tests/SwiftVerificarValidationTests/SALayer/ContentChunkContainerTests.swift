import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - ContentChunkType Tests

@Suite("ContentChunkType")
struct ContentChunkTypeTests {

    @Test("All cases have correct raw values")
    func rawValues() {
        #expect(ContentChunkType.text.rawValue == "Text")
        #expect(ContentChunkType.image.rawValue == "Image")
        #expect(ContentChunkType.path.rawValue == "Path")
        #expect(ContentChunkType.shading.rawValue == "Shading")
        #expect(ContentChunkType.markedContent.rawValue == "MarkedContent")
        #expect(ContentChunkType.formXObject.rawValue == "FormXObject")
        #expect(ContentChunkType.inlineImage.rawValue == "InlineImage")
        #expect(ContentChunkType.unknown.rawValue == "Unknown")
    }

    @Test("CaseIterable provides all cases")
    func caseIterable() {
        #expect(ContentChunkType.allCases.count == 8)
    }

    @Test("Hashable works correctly")
    func hashable() {
        var set: Set<ContentChunkType> = [.text, .image, .text]
        #expect(set.count == 2)
        set.insert(.path)
        #expect(set.count == 3)
    }
}

// MARK: - ContentChunk Tests

@Suite("ContentChunk")
struct ContentChunkTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let chunk = ContentChunk(type: .text)

        #expect(chunk.type == .text)
        #expect(chunk.pageNumber == 1)
        #expect(chunk.sequenceIndex == 0)
        #expect(chunk.operators.isEmpty)
        #expect(chunk.markedContentTag == nil)
        #expect(chunk.markedContentID == nil)
        #expect(chunk.structureElementType == nil)
        #expect(chunk.graphicsStateDepth == 0)
        #expect(chunk.boundingBox == nil)
        #expect(chunk.properties.isEmpty)
    }

    @Test("Full initialization")
    func fullInit() {
        let ops: [ValidatedOperator] = [.beginText, .endText]
        let chunk = ContentChunk(
            type: .text,
            pageNumber: 3,
            sequenceIndex: 5,
            operators: ops,
            markedContentTag: "P",
            markedContentID: 42,
            structureElementType: .paragraph,
            graphicsStateDepth: 2,
            boundingBox: (x: 10, y: 20, width: 100, height: 50),
            properties: ["font": "Helvetica"]
        )

        #expect(chunk.type == .text)
        #expect(chunk.pageNumber == 3)
        #expect(chunk.sequenceIndex == 5)
        #expect(chunk.operators.count == 2)
        #expect(chunk.markedContentTag == "P")
        #expect(chunk.markedContentID == 42)
        #expect(chunk.structureElementType == .paragraph)
        #expect(chunk.graphicsStateDepth == 2)
        #expect(chunk.hasBoundingBox)
        #expect(chunk.properties["font"] == "Helvetica")
    }

    // MARK: - Computed Property Tests

    @Test("operatorCount returns correct count")
    func operatorCount() {
        let ops: [ValidatedOperator] = [.beginText, .showText(Data()), .endText]
        let chunk = ContentChunk(type: .text, operators: ops)
        #expect(chunk.operatorCount == 3)
    }

    @Test("isMarkedContent returns true when tag is set")
    func isMarkedContentWithTag() {
        let chunk = ContentChunk(type: .text, markedContentTag: "Span")
        #expect(chunk.isMarkedContent)
    }

    @Test("isMarkedContent returns true when MCID is set")
    func isMarkedContentWithMCID() {
        let chunk = ContentChunk(type: .text, markedContentID: 7)
        #expect(chunk.isMarkedContent)
    }

    @Test("isMarkedContent returns false when neither is set")
    func isMarkedContentFalse() {
        let chunk = ContentChunk(type: .text)
        #expect(!chunk.isMarkedContent)
    }

    @Test("hasBoundingBox returns correct value")
    func hasBoundingBox() {
        let withBB = ContentChunk(
            type: .text,
            boundingBox: (x: 0, y: 0, width: 100, height: 50)
        )
        let withoutBB = ContentChunk(type: .text)

        #expect(withBB.hasBoundingBox)
        #expect(!withoutBB.hasBoundingBox)
    }

    @Test("hasStructureElement returns correct value")
    func hasStructureElement() {
        let withSE = ContentChunk(type: .text, structureElementType: .paragraph)
        let withoutSE = ContentChunk(type: .text)

        #expect(withSE.hasStructureElement)
        #expect(!withoutSE.hasStructureElement)
    }

    @Test("isText returns true for text chunks")
    func isText() {
        let textChunk = ContentChunk(type: .text)
        let imageChunk = ContentChunk(type: .image)

        #expect(textChunk.isText)
        #expect(!imageChunk.isText)
    }

    @Test("isImage returns true for image and inlineImage chunks")
    func isImage() {
        let image = ContentChunk(type: .image)
        let inline = ContentChunk(type: .inlineImage)
        let text = ContentChunk(type: .text)

        #expect(image.isImage)
        #expect(inline.isImage)
        #expect(!text.isImage)
    }

    @Test("isPath returns true for path chunks")
    func isPath() {
        let path = ContentChunk(type: .path)
        let text = ContentChunk(type: .text)

        #expect(path.isPath)
        #expect(!text.isPath)
    }

    @Test("summary includes type and page number")
    func summary() {
        let chunk = ContentChunk(
            type: .text,
            pageNumber: 2,
            operators: [.beginText]
        )
        let sum = chunk.summary
        #expect(sum.contains("Text"))
        #expect(sum.contains("p2"))
        #expect(sum.contains("1 ops"))
    }

    @Test("summary includes tag and MCID when present")
    func summaryWithMarkedContent() {
        let chunk = ContentChunk(
            type: .text,
            markedContentTag: "P",
            markedContentID: 42,
            structureElementType: .paragraph
        )
        let sum = chunk.summary
        #expect(sum.contains("tag=P"))
        #expect(sum.contains("mcid=42"))
        #expect(sum.contains("se=P"))
    }

    // MARK: - Factory Method Tests

    @Test("text() creates text chunk")
    func textFactory() {
        let chunk = ContentChunk.text(pageNumber: 2, markedContentID: 5)
        #expect(chunk.type == .text)
        #expect(chunk.pageNumber == 2)
        #expect(chunk.markedContentID == 5)
    }

    @Test("image() creates image chunk")
    func imageFactory() {
        let chunk = ContentChunk.image(pageNumber: 3)
        #expect(chunk.type == .image)
        #expect(chunk.pageNumber == 3)
    }

    @Test("path() creates path chunk")
    func pathFactory() {
        let ops: [ValidatedOperator] = [.moveTo(x: 0, y: 0), .lineTo(x: 100, y: 100)]
        let chunk = ContentChunk.path(operators: ops)
        #expect(chunk.type == .path)
        #expect(chunk.operatorCount == 2)
    }

    // MARK: - Equatable Tests

    @Test("Equatable uses id comparison")
    func equatable() {
        let id = UUID()
        let chunk1 = ContentChunk(id: id, type: .text)
        let chunk2 = ContentChunk(id: id, type: .text)
        let chunk3 = ContentChunk(type: .text)

        #expect(chunk1 == chunk2)
        #expect(chunk1 != chunk3)
    }
}

// MARK: - ContentChunkContainer Tests

@Suite("ContentChunkContainer")
struct ContentChunkContainerTests {

    // MARK: - Initialization Tests

    @Test("Empty container")
    func emptyContainer() {
        let container = ContentChunkContainer()

        #expect(container.isEmpty)
        #expect(container.count == 0)
        #expect(container.pageNumbers.isEmpty)
    }

    @Test("Container with chunks")
    func containerWithChunks() {
        let chunks = [
            ContentChunk.text(pageNumber: 1),
            ContentChunk.image(pageNumber: 1),
            ContentChunk.text(pageNumber: 2)
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(!container.isEmpty)
        #expect(container.count == 3)
        #expect(container.pageNumbers == [1, 2])
    }

    // MARK: - Query Method Tests

    @Test("chunks(ofType:) filters correctly")
    func chunksOfType() {
        let chunks = [
            ContentChunk.text(),
            ContentChunk.image(),
            ContentChunk.text(),
            ContentChunk.path()
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.chunks(ofType: .text).count == 2)
        #expect(container.chunks(ofType: .image).count == 1)
        #expect(container.chunks(ofType: .path).count == 1)
        #expect(container.chunks(ofType: .shading).isEmpty)
    }

    @Test("chunks(forPage:) filters by page")
    func chunksForPage() {
        let chunks = [
            ContentChunk.text(pageNumber: 1),
            ContentChunk.text(pageNumber: 2),
            ContentChunk.image(pageNumber: 1),
            ContentChunk.text(pageNumber: 3)
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.chunks(forPage: 1).count == 2)
        #expect(container.chunks(forPage: 2).count == 1)
        #expect(container.chunks(forPage: 4).isEmpty)
    }

    @Test("chunks(withMCID:) filters by MCID")
    func chunksWithMCID() {
        let chunks = [
            ContentChunk.text(markedContentID: 1),
            ContentChunk.text(markedContentID: 2),
            ContentChunk.text(markedContentID: 1)
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.chunks(withMCID: 1).count == 2)
        #expect(container.chunks(withMCID: 2).count == 1)
        #expect(container.chunks(withMCID: 99).isEmpty)
    }

    @Test("chunks(forStructureType:) filters by structure type")
    func chunksForStructureType() {
        let chunks = [
            ContentChunk(type: .text, structureElementType: .paragraph),
            ContentChunk(type: .text, structureElementType: .h1),
            ContentChunk(type: .image, structureElementType: .figure)
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.chunks(forStructureType: .paragraph).count == 1)
        #expect(container.chunks(forStructureType: .figure).count == 1)
        #expect(container.chunks(forStructureType: .table).isEmpty)
    }

    @Test("textChunks returns only text chunks")
    func textChunks() {
        let chunks = [
            ContentChunk.text(),
            ContentChunk.image(),
            ContentChunk.text()
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.textChunks.count == 2)
    }

    @Test("imageChunks returns image and inlineImage chunks")
    func imageChunks() {
        let chunks = [
            ContentChunk(type: .image),
            ContentChunk(type: .inlineImage),
            ContentChunk(type: .text)
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.imageChunks.count == 2)
    }

    @Test("pathChunks returns only path chunks")
    func pathChunks() {
        let chunks = [
            ContentChunk.path(),
            ContentChunk.text(),
            ContentChunk.path()
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.pathChunks.count == 2)
    }

    @Test("markedContentChunks filters tagged chunks")
    func markedContentChunks() {
        let chunks = [
            ContentChunk(type: .text, markedContentTag: "P"),
            ContentChunk(type: .text),
            ContentChunk(type: .text, markedContentID: 5)
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.markedContentChunks.count == 2)
    }

    @Test("unmarkedContentChunks filters untagged chunks")
    func unmarkedContentChunks() {
        let chunks = [
            ContentChunk(type: .text, markedContentTag: "P"),
            ContentChunk(type: .text),
            ContentChunk(type: .image)
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.unmarkedContentChunks.count == 2)
    }

    @Test("structuredChunks filters by structure association")
    func structuredChunks() {
        let chunks = [
            ContentChunk(type: .text, structureElementType: .paragraph),
            ContentChunk(type: .text),
            ContentChunk(type: .image, structureElementType: .figure)
        ]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.structuredChunks.count == 2)
    }

    // MARK: - Counts Tests

    @Test("countsByType groups correctly")
    func countsByType() {
        let chunks = [
            ContentChunk.text(),
            ContentChunk.text(),
            ContentChunk.image(),
            ContentChunk.path()
        ]
        let container = ContentChunkContainer(chunks: chunks)
        let counts = container.countsByType

        #expect(counts[.text] == 2)
        #expect(counts[.image] == 1)
        #expect(counts[.path] == 1)
        #expect(counts[.shading] == nil)
    }

    @Test("countsByPage groups correctly")
    func countsByPage() {
        let chunks = [
            ContentChunk.text(pageNumber: 1),
            ContentChunk.text(pageNumber: 1),
            ContentChunk.text(pageNumber: 2)
        ]
        let container = ContentChunkContainer(chunks: chunks)
        let counts = container.countsByPage

        #expect(counts[1] == 2)
        #expect(counts[2] == 1)
    }

    // MARK: - Combining Tests

    @Test("adding() appends chunks")
    func adding() {
        let container = ContentChunkContainer(chunks: [ContentChunk.text()])
        let newContainer = container.adding([ContentChunk.image()])

        #expect(newContainer.count == 2)
        #expect(container.count == 1) // original unchanged
    }

    @Test("merging() combines containers")
    func merging() {
        let container1 = ContentChunkContainer(chunks: [ContentChunk.text()])
        let container2 = ContentChunkContainer(chunks: [ContentChunk.image()])
        let merged = container1.merging(container2)

        #expect(merged.count == 2)
    }

    // MARK: - Summary Tests

    @Test("summary includes chunk count")
    func summary() {
        let chunks = [ContentChunk.text(), ContentChunk.image()]
        let container = ContentChunkContainer(chunks: chunks)

        #expect(container.summary.contains("2 chunks"))
    }

    // MARK: - Equatable Tests

    @Test("Equatable compares by chunk ids")
    func equatable() {
        let id = UUID()
        let chunk = ContentChunk(id: id, type: .text)
        let container1 = ContentChunkContainer(chunks: [chunk])
        let container2 = ContentChunkContainer(chunks: [ContentChunk(id: id, type: .text)])
        let container3 = ContentChunkContainer(chunks: [ContentChunk(type: .text)])

        #expect(container1 == container2)
        #expect(container1 != container3)
    }

    // MARK: - Factory Tests

    @Test("empty() creates empty container")
    func emptyFactory() {
        let container = ContentChunkContainer.empty()
        #expect(container.isEmpty)
    }
}
