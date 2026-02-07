import Foundation

// MARK: - Content Chunk Parser

/// Parser for extracting content chunks from validated content streams.
///
/// `ContentChunkParser` processes `ValidatedContentStream` objects and extracts
/// meaningful content chunks by analyzing operator sequences, tracking marked
/// content boundaries, and maintaining graphics state context. The resulting
/// chunks are used for WCAG accessibility validation.
///
/// ## Processing Flow
///
/// 1. Iterate through the operators in a content stream
/// 2. Track graphics state depth (q/Q pairs)
/// 3. Track marked content boundaries (BMC/BDC...EMC)
/// 4. Group operators into chunks by type (text, image, path, etc.)
/// 5. Associate chunks with marked content IDs when available
/// 6. Return a `ContentChunkContainer` with all extracted chunks
///
/// ## Relationship to veraPDF
///
/// Corresponds to `ChunkParser` from veraPDF-validation's wcag-validation
/// module. In the Java codebase, this class processes content streams to
/// extract chunks for WCAG analysis. The Swift version uses the
/// `ValidatedOperator` enum for pattern matching instead of visitor patterns.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent processing
/// - Uses Swift pattern matching on `ValidatedOperator` enum
/// - Returns value types (`ContentChunkContainer`) instead of mutating state
public struct ContentChunkParser: Sendable, Equatable {

    // MARK: - Properties

    /// The factory used to create content chunks.
    public let factory: ContentChunkFactory

    // MARK: - Initialization

    /// Creates a content chunk parser.
    ///
    /// - Parameter factory: The factory for creating chunks. Defaults to a default factory.
    public init(factory: ContentChunkFactory = .default()) {
        self.factory = factory
    }

    // MARK: - Parsing

    /// Parses a validated content stream and extracts content chunks.
    ///
    /// This method processes all operators in the content stream, groups them
    /// into logical chunks, and tracks marked content boundaries to associate
    /// chunks with structure elements.
    ///
    /// - Parameter contentStream: The validated content stream to parse.
    /// - Returns: A container with all extracted content chunks.
    public func parse(_ contentStream: ValidatedContentStream) -> ContentChunkContainer {
        var chunks: [ContentChunk] = []
        var state = ParserState(pageNumber: contentStream.pageNumber)

        for op in contentStream.operators {
            processOperator(op, state: &state, chunks: &chunks)
        }

        // Flush any remaining operators in the accumulator
        flushAccumulator(state: &state, chunks: &chunks)

        return ContentChunkContainer(chunks: chunks)
    }

    /// Parses multiple content streams and returns a combined container.
    ///
    /// - Parameter contentStreams: The content streams to parse.
    /// - Returns: A container with chunks from all content streams.
    public func parse(_ contentStreams: [ValidatedContentStream]) -> ContentChunkContainer {
        var allChunks: [ContentChunk] = []
        for stream in contentStreams {
            let container = parse(stream)
            allChunks.append(contentsOf: container.chunks)
        }
        return ContentChunkContainer(chunks: allChunks)
    }

    // MARK: - Internal State

    /// Internal parser state used during content stream processing.
    struct ParserState: Sendable {
        /// The page number being processed.
        var pageNumber: Int

        /// Current graphics state depth (q/Q nesting).
        var graphicsStateDepth: Int = 0

        /// Stack of marked content contexts.
        var markedContentStack: [MarkedContentEntry] = []

        /// The current accumulator of operators for the in-progress chunk.
        var accumulatorOps: [ValidatedOperator] = []

        /// The type of the chunk currently being accumulated.
        var accumulatorType: ContentChunkType?

        /// Running sequence index for chunk ordering.
        var sequenceIndex: Int = 0

        /// Whether we are inside a text object (BT...ET).
        var inTextObject: Bool = false
    }

    /// An entry in the marked content stack.
    struct MarkedContentEntry: Sendable {
        /// The marked content tag (e.g., "P", "Span", "Artifact").
        let tag: String

        /// The marked content ID (MCID), if present in properties.
        let mcid: Int?
    }

    // MARK: - Operator Processing

    /// Processes a single operator, updating parser state and creating chunks.
    private func processOperator(
        _ op: ValidatedOperator,
        state: inout ParserState,
        chunks: inout [ContentChunk]
    ) {
        switch op {
        // Graphics state tracking
        case .saveGraphicsState:
            state.graphicsStateDepth += 1

        case .restoreGraphicsState:
            state.graphicsStateDepth = max(0, state.graphicsStateDepth - 1)

        // Text object boundaries
        case .beginText:
            flushAccumulator(state: &state, chunks: &chunks)
            state.inTextObject = true
            state.accumulatorType = .text
            state.accumulatorOps.append(op)

        case .endText:
            state.accumulatorOps.append(op)
            state.inTextObject = false
            flushAccumulator(state: &state, chunks: &chunks)

        // Marked content boundaries
        case .beginMarkedContent(let tag):
            let entry = MarkedContentEntry(tag: tag.stringValue, mcid: nil)
            state.markedContentStack.append(entry)

        case .beginMarkedContentWithProperties(let tag, let props):
            let mcid = extractMCID(from: props)
            let entry = MarkedContentEntry(tag: tag.stringValue, mcid: mcid)
            state.markedContentStack.append(entry)

        case .endMarkedContent:
            if !state.markedContentStack.isEmpty {
                state.markedContentStack.removeLast()
            }

        // Inline image
        case .beginInlineImage:
            flushAccumulator(state: &state, chunks: &chunks)
            state.accumulatorType = .inlineImage
            state.accumulatorOps.append(op)

        case .inlineImageData:
            state.accumulatorOps.append(op)

        case .endInlineImage:
            state.accumulatorOps.append(op)
            flushAccumulator(state: &state, chunks: &chunks)

        // XObject invocation
        case .invokeXObject:
            flushAccumulator(state: &state, chunks: &chunks)
            let chunk = factory.createImageChunk(
                operators: [op],
                pageNumber: state.pageNumber,
                sequenceIndex: state.sequenceIndex,
                markedContentTag: currentMarkedContentTag(state),
                markedContentID: currentMarkedContentID(state),
                graphicsStateDepth: state.graphicsStateDepth
            )
            chunks.append(chunk)
            state.sequenceIndex += 1

        // Shading
        case .paintShading:
            flushAccumulator(state: &state, chunks: &chunks)
            let chunk = factory.createShadingChunk(
                operators: [op],
                pageNumber: state.pageNumber,
                sequenceIndex: state.sequenceIndex,
                markedContentTag: currentMarkedContentTag(state),
                markedContentID: currentMarkedContentID(state),
                graphicsStateDepth: state.graphicsStateDepth
            )
            chunks.append(chunk)
            state.sequenceIndex += 1

        // Path construction
        case .moveTo, .lineTo, .curveTo, .curveToInitialReplicated,
             .curveToFinalReplicated, .closePath, .appendRectangle:
            if state.accumulatorType != .path && !state.inTextObject {
                flushAccumulator(state: &state, chunks: &chunks)
                state.accumulatorType = .path
            }
            state.accumulatorOps.append(op)

        // Path painting (ends path chunk)
        case .stroke, .closeAndStroke, .fill, .fillEvenOdd,
             .fillAndStroke, .fillAndStrokeEvenOdd,
             .closeFillAndStroke, .closeFillAndStrokeEvenOdd, .endPath:
            state.accumulatorOps.append(op)
            if !state.inTextObject {
                flushAccumulator(state: &state, chunks: &chunks)
            }

        // Text operators within a text object
        default:
            if state.inTextObject {
                state.accumulatorOps.append(op)
            }
            // Other operators (color, graphics state params) are not chunked
        }
    }

    // MARK: - Accumulator Management

    /// Flushes the current operator accumulator, creating a chunk if there
    /// are operators accumulated.
    private func flushAccumulator(
        state: inout ParserState,
        chunks: inout [ContentChunk]
    ) {
        guard !state.accumulatorOps.isEmpty,
              let chunkType = state.accumulatorType else {
            state.accumulatorOps.removeAll()
            state.accumulatorType = nil
            return
        }

        let chunk = ContentChunk(
            type: chunkType,
            pageNumber: state.pageNumber,
            sequenceIndex: state.sequenceIndex,
            operators: state.accumulatorOps,
            markedContentTag: currentMarkedContentTag(state),
            markedContentID: currentMarkedContentID(state),
            graphicsStateDepth: state.graphicsStateDepth
        )
        chunks.append(chunk)

        state.sequenceIndex += 1
        state.accumulatorOps.removeAll()
        state.accumulatorType = nil
    }

    // MARK: - Marked Content Helpers

    /// Returns the current marked content tag from the stack.
    private func currentMarkedContentTag(_ state: ParserState) -> String? {
        state.markedContentStack.last?.tag
    }

    /// Returns the current marked content ID from the stack.
    private func currentMarkedContentID(_ state: ParserState) -> Int? {
        // Walk up the stack to find the nearest MCID
        for entry in state.markedContentStack.reversed() {
            if let mcid = entry.mcid {
                return mcid
            }
        }
        return nil
    }

    /// Extracts the MCID value from a marked content properties dictionary.
    ///
    /// The MCID is found in the properties dictionary as an integer value
    /// with the key "MCID".
    ///
    /// - Parameter properties: The COS value representing marked content properties.
    /// - Returns: The MCID integer, or `nil` if not found.
    private func extractMCID(from properties: COSValue) -> Int? {
        // COSValue is a dictionary; look for the MCID key
        if let dict = properties.dictionaryValue {
            if let mcidValue = dict[ASAtom("MCID")] {
                return mcidValue.integerValue.map { Int($0) }
            }
        }
        return nil
    }
}

// MARK: - Factory Methods

extension ContentChunkParser {

    /// Creates a default content chunk parser.
    public static func `default`() -> ContentChunkParser {
        ContentChunkParser()
    }

    /// Creates a content chunk parser with a custom factory.
    ///
    /// - Parameter factory: The factory to use for chunk creation.
    /// - Returns: A parser using the specified factory.
    public static func with(factory: ContentChunkFactory) -> ContentChunkParser {
        ContentChunkParser(factory: factory)
    }
}
