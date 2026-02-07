import Foundation

// MARK: - Content Chunk Factory

/// Factory for creating content chunks from operator sequences.
///
/// `ContentChunkFactory` analyzes sequences of `ValidatedOperator` values
/// and creates appropriately typed `ContentChunk` instances. It understands
/// operator grouping (e.g., BT...ET for text, q...Q for graphics state)
/// and marked content boundaries (BMC/BDC...EMC) to produce meaningful
/// chunks for WCAG accessibility validation.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `ChunkFactory` from veraPDF-validation's wcag-validation
/// module. In the Java codebase, this class creates chunk objects from
/// operator sequences during content stream processing.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent processing
/// - Uses `ValidatedOperator` enum pattern matching
/// - Stateless factory methods
public struct ContentChunkFactory: Sendable, Equatable {

    // MARK: - Configuration

    /// Whether to track bounding box estimates during chunk creation.
    public let trackBoundingBoxes: Bool

    /// Whether to associate chunks with structure element types via MCIDs.
    public let resolveStructureTypes: Bool

    // MARK: - Initialization

    /// Creates a content chunk factory.
    ///
    /// - Parameters:
    ///   - trackBoundingBoxes: Whether to estimate bounding boxes. Defaults to `false`.
    ///   - resolveStructureTypes: Whether to resolve structure types from MCIDs. Defaults to `true`.
    public init(
        trackBoundingBoxes: Bool = false,
        resolveStructureTypes: Bool = true
    ) {
        self.trackBoundingBoxes = trackBoundingBoxes
        self.resolveStructureTypes = resolveStructureTypes
    }

    // MARK: - Chunk Creation

    /// Creates a text chunk from a sequence of text operators.
    ///
    /// Text chunks are created from operators found between BT (beginText)
    /// and ET (endText) operators.
    ///
    /// - Parameters:
    ///   - operators: The text operators (including BT and ET).
    ///   - pageNumber: The page number (1-based).
    ///   - sequenceIndex: The index in the content sequence.
    ///   - markedContentTag: The enclosing marked content tag, if any.
    ///   - markedContentID: The enclosing marked content ID, if any.
    ///   - graphicsStateDepth: The graphics state nesting depth.
    /// - Returns: A text content chunk.
    public func createTextChunk(
        operators: [ValidatedOperator],
        pageNumber: Int,
        sequenceIndex: Int = 0,
        markedContentTag: String? = nil,
        markedContentID: Int? = nil,
        graphicsStateDepth: Int = 0
    ) -> ContentChunk {
        ContentChunk(
            type: .text,
            pageNumber: pageNumber,
            sequenceIndex: sequenceIndex,
            operators: operators,
            markedContentTag: markedContentTag,
            markedContentID: markedContentID,
            graphicsStateDepth: graphicsStateDepth
        )
    }

    /// Creates an image chunk from an XObject invocation.
    ///
    /// Image chunks are created when a `Do` operator references an
    /// image XObject.
    ///
    /// - Parameters:
    ///   - operators: The operator(s) involved.
    ///   - pageNumber: The page number (1-based).
    ///   - sequenceIndex: The index in the content sequence.
    ///   - markedContentTag: The enclosing marked content tag, if any.
    ///   - markedContentID: The enclosing marked content ID, if any.
    ///   - graphicsStateDepth: The graphics state nesting depth.
    /// - Returns: An image content chunk.
    public func createImageChunk(
        operators: [ValidatedOperator],
        pageNumber: Int,
        sequenceIndex: Int = 0,
        markedContentTag: String? = nil,
        markedContentID: Int? = nil,
        graphicsStateDepth: Int = 0
    ) -> ContentChunk {
        ContentChunk(
            type: .image,
            pageNumber: pageNumber,
            sequenceIndex: sequenceIndex,
            operators: operators,
            markedContentTag: markedContentTag,
            markedContentID: markedContentID,
            graphicsStateDepth: graphicsStateDepth
        )
    }

    /// Creates a path chunk from path construction and painting operators.
    ///
    /// Path chunks are created from sequences of path construction operators
    /// (m, l, c, v, y, h, re) followed by a painting operator (S, s, f, etc.).
    ///
    /// - Parameters:
    ///   - operators: The path operators.
    ///   - pageNumber: The page number (1-based).
    ///   - sequenceIndex: The index in the content sequence.
    ///   - markedContentTag: The enclosing marked content tag, if any.
    ///   - markedContentID: The enclosing marked content ID, if any.
    ///   - graphicsStateDepth: The graphics state nesting depth.
    /// - Returns: A path content chunk.
    public func createPathChunk(
        operators: [ValidatedOperator],
        pageNumber: Int,
        sequenceIndex: Int = 0,
        markedContentTag: String? = nil,
        markedContentID: Int? = nil,
        graphicsStateDepth: Int = 0
    ) -> ContentChunk {
        ContentChunk(
            type: .path,
            pageNumber: pageNumber,
            sequenceIndex: sequenceIndex,
            operators: operators,
            markedContentTag: markedContentTag,
            markedContentID: markedContentID,
            graphicsStateDepth: graphicsStateDepth
        )
    }

    /// Creates an inline image chunk.
    ///
    /// Inline image chunks are created from BI/ID/EI operator sequences
    /// embedded directly in the content stream.
    ///
    /// - Parameters:
    ///   - operators: The inline image operators.
    ///   - pageNumber: The page number (1-based).
    ///   - sequenceIndex: The index in the content sequence.
    ///   - markedContentTag: The enclosing marked content tag, if any.
    ///   - markedContentID: The enclosing marked content ID, if any.
    ///   - graphicsStateDepth: The graphics state nesting depth.
    /// - Returns: An inline image content chunk.
    public func createInlineImageChunk(
        operators: [ValidatedOperator],
        pageNumber: Int,
        sequenceIndex: Int = 0,
        markedContentTag: String? = nil,
        markedContentID: Int? = nil,
        graphicsStateDepth: Int = 0
    ) -> ContentChunk {
        ContentChunk(
            type: .inlineImage,
            pageNumber: pageNumber,
            sequenceIndex: sequenceIndex,
            operators: operators,
            markedContentTag: markedContentTag,
            markedContentID: markedContentID,
            graphicsStateDepth: graphicsStateDepth
        )
    }

    /// Creates a shading chunk from a shading paint operator.
    ///
    /// - Parameters:
    ///   - operators: The shading operator(s).
    ///   - pageNumber: The page number (1-based).
    ///   - sequenceIndex: The index in the content sequence.
    ///   - markedContentTag: The enclosing marked content tag, if any.
    ///   - markedContentID: The enclosing marked content ID, if any.
    ///   - graphicsStateDepth: The graphics state nesting depth.
    /// - Returns: A shading content chunk.
    public func createShadingChunk(
        operators: [ValidatedOperator],
        pageNumber: Int,
        sequenceIndex: Int = 0,
        markedContentTag: String? = nil,
        markedContentID: Int? = nil,
        graphicsStateDepth: Int = 0
    ) -> ContentChunk {
        ContentChunk(
            type: .shading,
            pageNumber: pageNumber,
            sequenceIndex: sequenceIndex,
            operators: operators,
            markedContentTag: markedContentTag,
            markedContentID: markedContentID,
            graphicsStateDepth: graphicsStateDepth
        )
    }

    /// Creates a form XObject chunk.
    ///
    /// Form XObject chunks are created when a `Do` operator references
    /// a form XObject.
    ///
    /// - Parameters:
    ///   - operators: The operator(s) involved.
    ///   - pageNumber: The page number (1-based).
    ///   - sequenceIndex: The index in the content sequence.
    ///   - markedContentTag: The enclosing marked content tag, if any.
    ///   - markedContentID: The enclosing marked content ID, if any.
    ///   - graphicsStateDepth: The graphics state nesting depth.
    /// - Returns: A form XObject content chunk.
    public func createFormXObjectChunk(
        operators: [ValidatedOperator],
        pageNumber: Int,
        sequenceIndex: Int = 0,
        markedContentTag: String? = nil,
        markedContentID: Int? = nil,
        graphicsStateDepth: Int = 0
    ) -> ContentChunk {
        ContentChunk(
            type: .formXObject,
            pageNumber: pageNumber,
            sequenceIndex: sequenceIndex,
            operators: operators,
            markedContentTag: markedContentTag,
            markedContentID: markedContentID,
            graphicsStateDepth: graphicsStateDepth
        )
    }

    // MARK: - Operator Classification

    /// Determines the chunk type for a given operator.
    ///
    /// - Parameter op: The operator to classify.
    /// - Returns: The content chunk type, or `nil` if the operator
    ///   does not directly produce a chunk.
    public func chunkType(for op: ValidatedOperator) -> ContentChunkType? {
        switch op.category {
        case .textObject, .textState, .textPositioning, .textShowing:
            return .text
        case .pathConstruction, .pathPainting:
            return .path
        case .inlineImage:
            return .inlineImage
        case .shading:
            return .shading
        case .xObject:
            // XObjects could be images or forms; defaults to image
            return .image
        case .markedContent:
            return .markedContent
        default:
            return nil
        }
    }

    /// Whether a given operator starts a new chunk group.
    ///
    /// - Parameter op: The operator to check.
    /// - Returns: `true` if this operator begins a new chunk group.
    public func isChunkStart(_ op: ValidatedOperator) -> Bool {
        switch op {
        case .beginText, .beginInlineImage, .beginMarkedContent,
             .beginMarkedContentWithProperties, .moveTo, .appendRectangle:
            return true
        case .invokeXObject, .paintShading:
            return true
        default:
            return false
        }
    }

    /// Whether a given operator ends a chunk group.
    ///
    /// - Parameter op: The operator to check.
    /// - Returns: `true` if this operator ends a chunk group.
    public func isChunkEnd(_ op: ValidatedOperator) -> Bool {
        switch op {
        case .endText, .endInlineImage, .endMarkedContent:
            return true
        case .stroke, .closeAndStroke, .fill, .fillEvenOdd,
             .fillAndStroke, .fillAndStrokeEvenOdd,
             .closeFillAndStroke, .closeFillAndStrokeEvenOdd, .endPath:
            return true
        default:
            return false
        }
    }
}

// MARK: - Factory Methods

extension ContentChunkFactory {

    /// Creates a default content chunk factory.
    public static func `default`() -> ContentChunkFactory {
        ContentChunkFactory()
    }

    /// Creates a content chunk factory with bounding box tracking.
    public static func withBoundingBoxes() -> ContentChunkFactory {
        ContentChunkFactory(trackBoundingBoxes: true)
    }
}
