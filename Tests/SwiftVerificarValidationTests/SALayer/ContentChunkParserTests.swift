import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - ContentChunkParser Tests

@Suite("ContentChunkParser")
struct ContentChunkParserTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let parser = ContentChunkParser()
        #expect(parser.factory == ContentChunkFactory.default())
    }

    @Test("Custom factory initialization")
    func customFactoryInit() {
        let factory = ContentChunkFactory(trackBoundingBoxes: true)
        let parser = ContentChunkParser(factory: factory)
        #expect(parser.factory.trackBoundingBoxes)
    }

    // MARK: - Empty Stream Parsing

    @Test("Parsing empty content stream produces empty container")
    func parseEmptyStream() {
        let parser = ContentChunkParser()
        let stream = ValidatedContentStream.minimal()
        let container = parser.parse(stream)

        #expect(container.isEmpty)
    }

    // MARK: - Text Chunk Parsing

    @Test("Parsing BT/ET block creates text chunk")
    func parseTextBlock() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .beginText,
            .setFont(name: ASAtom("F1"), size: 12),
            .moveTextPosition(tx: 72, ty: 700),
            .showText(Data("Hello".utf8)),
            .endText
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.count == 1)
        #expect(container.textChunks.count == 1)
        let chunk = container.chunks[0]
        #expect(chunk.type == .text)
        #expect(chunk.operators.count == 5)
        #expect(chunk.pageNumber == 1)
    }

    @Test("Multiple text blocks create separate chunks")
    func parseMultipleTextBlocks() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .beginText,
            .showText(Data("First".utf8)),
            .endText,
            .beginText,
            .showText(Data("Second".utf8)),
            .endText
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.textChunks.count == 2)
    }

    // MARK: - Path Chunk Parsing

    @Test("Path construction followed by stroke creates path chunk")
    func parsePathChunk() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .moveTo(x: 10, y: 10),
            .lineTo(x: 100, y: 10),
            .lineTo(x: 100, y: 100),
            .closePath,
            .stroke
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.pathChunks.count == 1)
        let chunk = container.pathChunks[0]
        #expect(chunk.operators.count == 5)
    }

    @Test("Rectangle followed by fill creates path chunk")
    func parseRectangleFill() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .appendRectangle(x: 50, y: 50, width: 200, height: 100),
            .fill
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.pathChunks.count == 1)
    }

    @Test("Multiple paths create separate chunks")
    func parseMultiplePaths() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .moveTo(x: 0, y: 0),
            .lineTo(x: 100, y: 0),
            .stroke,
            .moveTo(x: 0, y: 50),
            .lineTo(x: 100, y: 50),
            .stroke
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.pathChunks.count == 2)
    }

    // MARK: - Image Chunk Parsing

    @Test("invokeXObject creates image chunk")
    func parseXObjectImage() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .invokeXObject(ASAtom("Im0"))
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.imageChunks.count == 1)
        let chunk = container.imageChunks[0]
        #expect(chunk.type == .image)
    }

    // MARK: - Inline Image Parsing

    @Test("BI/ID/EI sequence creates inline image chunk")
    func parseInlineImage() {
        let parser = ContentChunkParser()
        let imageData = InlineImageData(dictionary: [:], data: Data())
        let ops: [ValidatedOperator] = [
            .beginInlineImage,
            .inlineImageData(imageData),
            .endInlineImage
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.count == 1)
        let chunk = container.chunks[0]
        #expect(chunk.type == .inlineImage)
        #expect(chunk.operators.count == 3)
    }

    // MARK: - Shading Parsing

    @Test("paintShading creates shading chunk")
    func parseShadingChunk() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .paintShading(ASAtom("sh0"))
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.count == 1)
        let chunk = container.chunks[0]
        #expect(chunk.type == .shading)
    }

    // MARK: - Marked Content Tracking

    @Test("Chunks within BMC/EMC get marked content tag")
    func parseMarkedContentTagging() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .beginMarkedContent(ASAtom("P")),
            .beginText,
            .showText(Data("Tagged text".utf8)),
            .endText,
            .endMarkedContent
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.count == 1)
        let chunk = container.chunks[0]
        #expect(chunk.markedContentTag == "P")
    }

    @Test("Nested marked content uses innermost tag")
    func parseNestedMarkedContent() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .beginMarkedContent(ASAtom("Sect")),
            .beginMarkedContent(ASAtom("P")),
            .beginText,
            .showText(Data("Nested".utf8)),
            .endText,
            .endMarkedContent,
            .endMarkedContent
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.count == 1)
        let chunk = container.chunks[0]
        #expect(chunk.markedContentTag == "P")
    }

    @Test("BDC with MCID properties propagates MCID to chunks")
    func parseBDCWithMCID() {
        let parser = ContentChunkParser()
        let propsDict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(42)
        ]
        let props = COSValue.dictionary(propsDict)
        let ops: [ValidatedOperator] = [
            .beginMarkedContentWithProperties(tag: ASAtom("P"), properties: props),
            .beginText,
            .showText(Data("MCID text".utf8)),
            .endText,
            .endMarkedContent
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.count == 1)
        let chunk = container.chunks[0]
        #expect(chunk.markedContentTag == "P")
        #expect(chunk.markedContentID == 42)
    }

    @Test("Chunks outside marked content have no tag")
    func parseUnmarkedContent() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .beginText,
            .showText(Data("Unmarked".utf8)),
            .endText
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.count == 1)
        let chunk = container.chunks[0]
        #expect(chunk.markedContentTag == nil)
        #expect(chunk.markedContentID == nil)
    }

    // MARK: - Graphics State Tracking

    @Test("Graphics state depth is tracked through q/Q pairs")
    func parseGraphicsStateDepth() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .saveGraphicsState,
            .saveGraphicsState,
            .beginText,
            .showText(Data("Deep".utf8)),
            .endText,
            .restoreGraphicsState,
            .restoreGraphicsState
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.count == 1)
        let chunk = container.chunks[0]
        #expect(chunk.graphicsStateDepth == 2)
    }

    // MARK: - Mixed Content Parsing

    @Test("Mixed content creates multiple chunk types")
    func parseMixedContent() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            // Text
            .beginText,
            .showText(Data("Hello".utf8)),
            .endText,
            // Path
            .moveTo(x: 0, y: 0),
            .lineTo(x: 100, y: 0),
            .stroke,
            // Image
            .invokeXObject(ASAtom("Im0")),
            // More text
            .beginText,
            .showText(Data("World".utf8)),
            .endText
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.textChunks.count == 2)
        #expect(container.pathChunks.count == 1)
        #expect(container.imageChunks.count == 1)
        #expect(container.count == 4)
    }

    // MARK: - Multiple Stream Parsing

    @Test("parse() with multiple streams combines results")
    func parseMultipleStreams() {
        let parser = ContentChunkParser()
        let stream1 = ValidatedContentStream.minimal(
            pageNumber: 1,
            operators: [.beginText, .showText(Data("Page 1".utf8)), .endText]
        )
        let stream2 = ValidatedContentStream.minimal(
            pageNumber: 2,
            operators: [.beginText, .showText(Data("Page 2".utf8)), .endText]
        )
        let container = parser.parse([stream1, stream2])

        #expect(container.count == 2)
        #expect(container.chunks(forPage: 1).count == 1)
        #expect(container.chunks(forPage: 2).count == 1)
    }

    // MARK: - Sequence Index Tests

    @Test("Chunks have incrementing sequence indices")
    func sequenceIndices() {
        let parser = ContentChunkParser()
        let ops: [ValidatedOperator] = [
            .beginText, .showText(Data("1".utf8)), .endText,
            .beginText, .showText(Data("2".utf8)), .endText,
            .beginText, .showText(Data("3".utf8)), .endText
        ]
        let stream = ValidatedContentStream.minimal(operators: ops)
        let container = parser.parse(stream)

        #expect(container.count == 3)
        #expect(container.chunks[0].sequenceIndex == 0)
        #expect(container.chunks[1].sequenceIndex == 1)
        #expect(container.chunks[2].sequenceIndex == 2)
    }

    // MARK: - Page Number Tests

    @Test("Chunks inherit page number from content stream")
    func pageNumberInheritance() {
        let parser = ContentChunkParser()
        let stream = ValidatedContentStream.minimal(
            pageNumber: 5,
            operators: [.beginText, .showText(Data()), .endText]
        )
        let container = parser.parse(stream)

        #expect(container.chunks[0].pageNumber == 5)
    }

    // MARK: - Equatable Tests

    @Test("Equatable compares factory")
    func equatable() {
        let parser1 = ContentChunkParser()
        let parser2 = ContentChunkParser()
        let parser3 = ContentChunkParser(factory: ContentChunkFactory(trackBoundingBoxes: true))

        #expect(parser1 == parser2)
        #expect(parser1 != parser3)
    }

    // MARK: - Factory Method Tests

    @Test("default() creates default parser")
    func defaultFactory() {
        let parser = ContentChunkParser.default()
        #expect(parser.factory == ContentChunkFactory.default())
    }

    @Test("with(factory:) creates parser with custom factory")
    func withFactory() {
        let factory = ContentChunkFactory(trackBoundingBoxes: true)
        let parser = ContentChunkParser.with(factory: factory)
        #expect(parser.factory.trackBoundingBoxes)
    }
}
