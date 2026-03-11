import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarParser

// MARK: - ContentChunkFactory Tests

@Suite("ContentChunkFactory")
struct ContentChunkFactoryTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let factory = ContentChunkFactory()
        #expect(!factory.trackBoundingBoxes)
        #expect(factory.resolveStructureTypes)
    }

    @Test("Custom initialization")
    func customInit() {
        let factory = ContentChunkFactory(
            trackBoundingBoxes: true,
            resolveStructureTypes: false
        )
        #expect(factory.trackBoundingBoxes)
        #expect(!factory.resolveStructureTypes)
    }

    // MARK: - Chunk Creation Tests

    @Test("createTextChunk creates text chunk")
    func createTextChunk() {
        let factory = ContentChunkFactory()
        let ops: [ValidatedOperator] = [.beginText, .showText(Data()), .endText]

        let chunk = factory.createTextChunk(
            operators: ops,
            pageNumber: 2,
            sequenceIndex: 3,
            markedContentTag: "P",
            markedContentID: 7,
            graphicsStateDepth: 1
        )

        #expect(chunk.type == .text)
        #expect(chunk.pageNumber == 2)
        #expect(chunk.sequenceIndex == 3)
        #expect(chunk.operators.count == 3)
        #expect(chunk.markedContentTag == "P")
        #expect(chunk.markedContentID == 7)
        #expect(chunk.graphicsStateDepth == 1)
    }

    @Test("createImageChunk creates image chunk")
    func createImageChunk() {
        let factory = ContentChunkFactory()
        let ops: [ValidatedOperator] = [.invokeXObject(ASAtom("Im0"))]

        let chunk = factory.createImageChunk(
            operators: ops,
            pageNumber: 1,
            markedContentTag: "Figure"
        )

        #expect(chunk.type == .image)
        #expect(chunk.pageNumber == 1)
        #expect(chunk.operators.count == 1)
        #expect(chunk.markedContentTag == "Figure")
    }

    @Test("createPathChunk creates path chunk")
    func createPathChunk() {
        let factory = ContentChunkFactory()
        let ops: [ValidatedOperator] = [
            .moveTo(x: 0, y: 0),
            .lineTo(x: 100, y: 100),
            .stroke
        ]

        let chunk = factory.createPathChunk(
            operators: ops,
            pageNumber: 1,
            graphicsStateDepth: 2
        )

        #expect(chunk.type == .path)
        #expect(chunk.operators.count == 3)
        #expect(chunk.graphicsStateDepth == 2)
    }

    @Test("createInlineImageChunk creates inline image chunk")
    func createInlineImageChunk() {
        let factory = ContentChunkFactory()
        let ops: [ValidatedOperator] = [.beginInlineImage, .endInlineImage]

        let chunk = factory.createInlineImageChunk(
            operators: ops,
            pageNumber: 1,
            markedContentID: 10
        )

        #expect(chunk.type == .inlineImage)
        #expect(chunk.markedContentID == 10)
    }

    @Test("createShadingChunk creates shading chunk")
    func createShadingChunk() {
        let factory = ContentChunkFactory()
        let ops: [ValidatedOperator] = [.paintShading(ASAtom("sh0"))]

        let chunk = factory.createShadingChunk(
            operators: ops,
            pageNumber: 1
        )

        #expect(chunk.type == .shading)
        #expect(chunk.operators.count == 1)
    }

    @Test("createFormXObjectChunk creates form XObject chunk")
    func createFormXObjectChunk() {
        let factory = ContentChunkFactory()
        let ops: [ValidatedOperator] = [.invokeXObject(ASAtom("Form1"))]

        let chunk = factory.createFormXObjectChunk(
            operators: ops,
            pageNumber: 2,
            sequenceIndex: 1
        )

        #expect(chunk.type == .formXObject)
        #expect(chunk.pageNumber == 2)
        #expect(chunk.sequenceIndex == 1)
    }

    // MARK: - Operator Classification Tests

    @Test("chunkType for text operators returns .text")
    func chunkTypeText() {
        let factory = ContentChunkFactory()

        #expect(factory.chunkType(for: .beginText) == .text)
        #expect(factory.chunkType(for: .endText) == .text)
        #expect(factory.chunkType(for: .showText(Data())) == .text)
        #expect(factory.chunkType(for: .setFont(name: ASAtom("F1"), size: 12)) == .text)
    }

    @Test("chunkType for path operators returns .path")
    func chunkTypePath() {
        let factory = ContentChunkFactory()

        #expect(factory.chunkType(for: .moveTo(x: 0, y: 0)) == .path)
        #expect(factory.chunkType(for: .lineTo(x: 100, y: 100)) == .path)
        #expect(factory.chunkType(for: .stroke) == .path)
        #expect(factory.chunkType(for: .fill) == .path)
    }

    @Test("chunkType for inline image operators returns .inlineImage")
    func chunkTypeInlineImage() {
        let factory = ContentChunkFactory()
        #expect(factory.chunkType(for: .beginInlineImage) == .inlineImage)
    }

    @Test("chunkType for shading operators returns .shading")
    func chunkTypeShading() {
        let factory = ContentChunkFactory()
        #expect(factory.chunkType(for: .paintShading(ASAtom("sh0"))) == .shading)
    }

    @Test("chunkType for XObject operators returns .image")
    func chunkTypeXObject() {
        let factory = ContentChunkFactory()
        #expect(factory.chunkType(for: .invokeXObject(ASAtom("Im0"))) == .image)
    }

    @Test("chunkType for marked content operators returns .markedContent")
    func chunkTypeMarkedContent() {
        let factory = ContentChunkFactory()
        #expect(factory.chunkType(for: .beginMarkedContent(ASAtom("P"))) == .markedContent)
        #expect(factory.chunkType(for: .endMarkedContent) == .markedContent)
    }

    @Test("chunkType for non-chunk operators returns nil")
    func chunkTypeNil() {
        let factory = ContentChunkFactory()
        #expect(factory.chunkType(for: .saveGraphicsState) == nil)
        #expect(factory.chunkType(for: .setLineWidth(1.0)) == nil)
        #expect(factory.chunkType(for: .setGrayFill(0.5)) == nil)
    }

    // MARK: - Chunk Boundary Tests

    @Test("isChunkStart detects chunk-starting operators")
    func isChunkStart() {
        let factory = ContentChunkFactory()

        #expect(factory.isChunkStart(.beginText))
        #expect(factory.isChunkStart(.beginInlineImage))
        #expect(factory.isChunkStart(.beginMarkedContent(ASAtom("P"))))
        #expect(factory.isChunkStart(.moveTo(x: 0, y: 0)))
        #expect(factory.isChunkStart(.appendRectangle(x: 0, y: 0, width: 100, height: 50)))
        #expect(factory.isChunkStart(.invokeXObject(ASAtom("Im0"))))
        #expect(factory.isChunkStart(.paintShading(ASAtom("sh0"))))
    }

    @Test("isChunkStart returns false for non-starting operators")
    func isChunkStartFalse() {
        let factory = ContentChunkFactory()

        #expect(!factory.isChunkStart(.saveGraphicsState))
        #expect(!factory.isChunkStart(.setGrayFill(0.5)))
        #expect(!factory.isChunkStart(.endText))
        #expect(!factory.isChunkStart(.showText(Data())))
    }

    @Test("isChunkEnd detects chunk-ending operators")
    func isChunkEnd() {
        let factory = ContentChunkFactory()

        #expect(factory.isChunkEnd(.endText))
        #expect(factory.isChunkEnd(.endInlineImage))
        #expect(factory.isChunkEnd(.endMarkedContent))
        #expect(factory.isChunkEnd(.stroke))
        #expect(factory.isChunkEnd(.fill))
        #expect(factory.isChunkEnd(.fillEvenOdd))
        #expect(factory.isChunkEnd(.fillAndStroke))
        #expect(factory.isChunkEnd(.closeFillAndStroke))
        #expect(factory.isChunkEnd(.endPath))
    }

    @Test("isChunkEnd returns false for non-ending operators")
    func isChunkEndFalse() {
        let factory = ContentChunkFactory()

        #expect(!factory.isChunkEnd(.beginText))
        #expect(!factory.isChunkEnd(.saveGraphicsState))
        #expect(!factory.isChunkEnd(.moveTo(x: 0, y: 0)))
    }

    // MARK: - Equatable Tests

    @Test("Equatable compares configuration")
    func equatable() {
        let factory1 = ContentChunkFactory()
        let factory2 = ContentChunkFactory()
        let factory3 = ContentChunkFactory(trackBoundingBoxes: true)

        #expect(factory1 == factory2)
        #expect(factory1 != factory3)
    }

    // MARK: - Factory Method Tests

    @Test("default() creates default factory")
    func defaultFactory() {
        let factory = ContentChunkFactory.default()
        #expect(!factory.trackBoundingBoxes)
        #expect(factory.resolveStructureTypes)
    }

    @Test("withBoundingBoxes() creates factory with bounding box tracking")
    func withBoundingBoxesFactory() {
        let factory = ContentChunkFactory.withBoundingBoxes()
        #expect(factory.trackBoundingBoxes)
    }
}
