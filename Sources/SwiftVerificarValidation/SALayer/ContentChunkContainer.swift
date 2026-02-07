import Foundation

// MARK: - Content Chunk Type

/// The type of content extracted from a page content stream.
///
/// Content chunks represent discrete pieces of content found in a PDF
/// page's content stream. They are categorized by the type of graphical
/// operation they represent.
///
/// ## Relationship to veraPDF
///
/// Corresponds to chunk type distinctions made in veraPDF-validation's
/// `ChunkContainer` and related chunk classes from the wcag-validation module.
public enum ContentChunkType: String, Sendable, Hashable, CaseIterable, Codable {

    /// A text chunk containing rendered text content.
    case text = "Text"

    /// An image chunk representing a raster image (XObject or inline).
    case image = "Image"

    /// A path chunk representing vector graphics (lines, curves, rectangles).
    case path = "Path"

    /// A shading chunk representing gradient fills.
    case shading = "Shading"

    /// A marked content chunk wrapping tagged content.
    case markedContent = "MarkedContent"

    /// A form XObject chunk representing embedded form content.
    case formXObject = "FormXObject"

    /// An inline image chunk embedded directly in the content stream.
    case inlineImage = "InlineImage"

    /// An unknown or unclassified chunk.
    case unknown = "Unknown"
}

// MARK: - Content Chunk

/// A chunk of content extracted from a PDF page content stream.
///
/// Content chunks are the unit of analysis for WCAG accessibility validation.
/// Each chunk represents a piece of rendered content (text, image, path, etc.)
/// along with its associated graphics state and position information.
///
/// ## Relationship to veraPDF
///
/// Corresponds to individual chunk types (text chunks, image chunks, etc.)
/// from veraPDF-validation's wcag-validation module. In Swift, these are
/// unified into a single struct with a `type` discriminator instead of
/// a class hierarchy.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent processing
/// - Single struct with type discriminator instead of class hierarchy
public struct ContentChunk: Sendable, Equatable, Identifiable {

    /// Unique identifier for this content chunk.
    public let id: UUID

    /// The type of content this chunk represents.
    public let type: ContentChunkType

    /// The page number where this chunk appears (1-based).
    public let pageNumber: Int

    /// The index of this chunk within its page's content sequence.
    public let sequenceIndex: Int

    /// The operators that comprise this chunk.
    public let operators: [ValidatedOperator]

    /// The marked content tag, if this chunk is within marked content.
    public let markedContentTag: String?

    /// The marked content ID (MCID), if within marked content.
    public let markedContentID: Int?

    /// The structure element type associated with this chunk via marked content.
    public let structureElementType: StructureElementType?

    /// The graphics state depth at which this chunk begins.
    public let graphicsStateDepth: Int

    /// The bounding box estimate for this chunk, if available.
    ///
    /// Represented as (x, y, width, height) in user space coordinates.
    public let boundingBox: (x: Double, y: Double, width: Double, height: Double)?

    /// Additional properties extracted from the chunk context.
    public let properties: [String: String]

    /// Creates a content chunk.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - type: The content chunk type.
    ///   - pageNumber: The page number (1-based).
    ///   - sequenceIndex: Index in the content sequence.
    ///   - operators: The operators comprising this chunk.
    ///   - markedContentTag: Marked content tag, if any.
    ///   - markedContentID: Marked content ID, if any.
    ///   - structureElementType: Associated structure element type.
    ///   - graphicsStateDepth: Graphics state nesting depth.
    ///   - boundingBox: Bounding box estimate.
    ///   - properties: Additional properties.
    public init(
        id: UUID = UUID(),
        type: ContentChunkType,
        pageNumber: Int = 1,
        sequenceIndex: Int = 0,
        operators: [ValidatedOperator] = [],
        markedContentTag: String? = nil,
        markedContentID: Int? = nil,
        structureElementType: StructureElementType? = nil,
        graphicsStateDepth: Int = 0,
        boundingBox: (x: Double, y: Double, width: Double, height: Double)? = nil,
        properties: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.pageNumber = pageNumber
        self.sequenceIndex = sequenceIndex
        self.operators = operators
        self.markedContentTag = markedContentTag
        self.markedContentID = markedContentID
        self.structureElementType = structureElementType
        self.graphicsStateDepth = graphicsStateDepth
        self.boundingBox = boundingBox
        self.properties = properties
    }

    // MARK: - Computed Properties

    /// The number of operators in this chunk.
    public var operatorCount: Int {
        operators.count
    }

    /// Whether this chunk is within marked content.
    public var isMarkedContent: Bool {
        markedContentTag != nil || markedContentID != nil
    }

    /// Whether this chunk has a bounding box estimate.
    public var hasBoundingBox: Bool {
        boundingBox != nil
    }

    /// Whether this chunk is associated with a structure element.
    public var hasStructureElement: Bool {
        structureElementType != nil
    }

    /// Whether this chunk contains text content.
    public var isText: Bool {
        type == .text
    }

    /// Whether this chunk contains image content.
    public var isImage: Bool {
        type == .image || type == .inlineImage
    }

    /// Whether this chunk contains path (vector) content.
    public var isPath: Bool {
        type == .path
    }

    /// A summary string describing this content chunk.
    public var summary: String {
        var parts: [String] = [type.rawValue]
        parts.append("p\(pageNumber)")
        parts.append("\(operatorCount) ops")
        if let tag = markedContentTag { parts.append("tag=\(tag)") }
        if let mcid = markedContentID { parts.append("mcid=\(mcid)") }
        if let seType = structureElementType { parts.append("se=\(seType.rawValue)") }
        return parts.joined(separator: " ")
    }

    // MARK: - Equatable

    public static func == (lhs: ContentChunk, rhs: ContentChunk) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Content Chunk Container

/// Container for content chunks extracted from page content streams.
///
/// `ContentChunkContainer` collects and organizes content chunks from one
/// or more pages of a PDF document. It provides filtering and query methods
/// for accessing chunks by type, page, or structure association.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `ChunkContainer` from veraPDF-validation's wcag-validation
/// module. In the Java codebase, this class stores and organizes content chunks
/// for WCAG accessibility analysis.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent WCAG validation
/// - Provides rich query methods using Swift collections APIs
public struct ContentChunkContainer: Sendable, Equatable {

    // MARK: - Properties

    /// All content chunks in the container.
    public let chunks: [ContentChunk]

    /// The page numbers that have chunks in this container.
    public var pageNumbers: [Int] {
        Array(Set(chunks.map(\.pageNumber))).sorted()
    }

    /// The total number of chunks.
    public var count: Int {
        chunks.count
    }

    /// Whether the container is empty.
    public var isEmpty: Bool {
        chunks.isEmpty
    }

    // MARK: - Initialization

    /// Creates a content chunk container.
    ///
    /// - Parameter chunks: The content chunks to store.
    public init(chunks: [ContentChunk] = []) {
        self.chunks = chunks
    }

    // MARK: - Query Methods

    /// Returns chunks filtered by type.
    ///
    /// - Parameter type: The chunk type to filter by.
    /// - Returns: All chunks of the specified type.
    public func chunks(ofType type: ContentChunkType) -> [ContentChunk] {
        chunks.filter { $0.type == type }
    }

    /// Returns chunks for a specific page.
    ///
    /// - Parameter pageNumber: The page number (1-based).
    /// - Returns: All chunks on the specified page.
    public func chunks(forPage pageNumber: Int) -> [ContentChunk] {
        chunks.filter { $0.pageNumber == pageNumber }
    }

    /// Returns chunks associated with a specific marked content ID.
    ///
    /// - Parameter mcid: The marked content ID.
    /// - Returns: All chunks with the specified MCID.
    public func chunks(withMCID mcid: Int) -> [ContentChunk] {
        chunks.filter { $0.markedContentID == mcid }
    }

    /// Returns chunks associated with a specific structure element type.
    ///
    /// - Parameter type: The structure element type.
    /// - Returns: All chunks associated with the specified type.
    public func chunks(forStructureType type: StructureElementType) -> [ContentChunk] {
        chunks.filter { $0.structureElementType == type }
    }

    /// Returns all text chunks.
    public var textChunks: [ContentChunk] {
        chunks(ofType: .text)
    }

    /// Returns all image chunks (including inline images).
    public var imageChunks: [ContentChunk] {
        chunks.filter { $0.isImage }
    }

    /// Returns all path chunks.
    public var pathChunks: [ContentChunk] {
        chunks(ofType: .path)
    }

    /// Returns all chunks that are within marked content.
    public var markedContentChunks: [ContentChunk] {
        chunks.filter(\.isMarkedContent)
    }

    /// Returns all chunks that are NOT within marked content.
    ///
    /// Unmarked content is a potential WCAG accessibility issue because
    /// it is not associated with the document's tagged structure.
    public var unmarkedContentChunks: [ContentChunk] {
        chunks.filter { !$0.isMarkedContent }
    }

    /// Returns all chunks that have structure element associations.
    public var structuredChunks: [ContentChunk] {
        chunks.filter(\.hasStructureElement)
    }

    /// Returns the number of chunks grouped by type.
    public var countsByType: [ContentChunkType: Int] {
        var counts: [ContentChunkType: Int] = [:]
        for chunk in chunks {
            counts[chunk.type, default: 0] += 1
        }
        return counts
    }

    /// Returns the number of chunks grouped by page.
    public var countsByPage: [Int: Int] {
        var counts: [Int: Int] = [:]
        for chunk in chunks {
            counts[chunk.pageNumber, default: 0] += 1
        }
        return counts
    }

    // MARK: - Combining

    /// Returns a new container with additional chunks appended.
    ///
    /// - Parameter newChunks: The chunks to add.
    /// - Returns: A new container with the combined chunks.
    public func adding(_ newChunks: [ContentChunk]) -> ContentChunkContainer {
        ContentChunkContainer(chunks: chunks + newChunks)
    }

    /// Returns a new container with chunks from another container merged.
    ///
    /// - Parameter other: The other container to merge.
    /// - Returns: A new container with merged chunks.
    public func merging(_ other: ContentChunkContainer) -> ContentChunkContainer {
        adding(other.chunks)
    }

    // MARK: - Summary

    /// Returns a summary string describing this container.
    public var summary: String {
        var parts: [String] = ["\(count) chunks"]
        let types = countsByType
        for type in ContentChunkType.allCases {
            if let count = types[type], count > 0 {
                parts.append("\(count) \(type.rawValue)")
            }
        }
        parts.append("\(pageNumbers.count) pages")
        return parts.joined(separator: ", ")
    }

    // MARK: - Equatable

    public static func == (lhs: ContentChunkContainer, rhs: ContentChunkContainer) -> Bool {
        lhs.chunks.map(\.id) == rhs.chunks.map(\.id)
    }
}

// MARK: - Factory Methods

extension ContentChunk {

    /// Creates a minimal text chunk for testing.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number.
    ///   - operators: Text operators.
    ///   - markedContentID: Optional MCID.
    /// - Returns: A minimal text chunk.
    public static func text(
        pageNumber: Int = 1,
        operators: [ValidatedOperator] = [],
        markedContentID: Int? = nil
    ) -> ContentChunk {
        ContentChunk(
            type: .text,
            pageNumber: pageNumber,
            operators: operators,
            markedContentID: markedContentID
        )
    }

    /// Creates a minimal image chunk for testing.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number.
    ///   - markedContentID: Optional MCID.
    /// - Returns: A minimal image chunk.
    public static func image(
        pageNumber: Int = 1,
        markedContentID: Int? = nil
    ) -> ContentChunk {
        ContentChunk(
            type: .image,
            pageNumber: pageNumber,
            markedContentID: markedContentID
        )
    }

    /// Creates a minimal path chunk for testing.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number.
    ///   - operators: Path operators.
    /// - Returns: A minimal path chunk.
    public static func path(
        pageNumber: Int = 1,
        operators: [ValidatedOperator] = []
    ) -> ContentChunk {
        ContentChunk(
            type: .path,
            pageNumber: pageNumber,
            operators: operators
        )
    }
}

extension ContentChunkContainer {

    /// Creates an empty container for testing.
    public static func empty() -> ContentChunkContainer {
        ContentChunkContainer()
    }
}
