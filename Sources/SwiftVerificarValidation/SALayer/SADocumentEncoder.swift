import Foundation

// MARK: - SA Document Encoder

/// Encodes an SA (Structured Accessibility) document tree into JSON/Codable
/// format for serialization, reporting, and integration with the biblioteca layer.
///
/// `SADocumentEncoder` provides the bridge between the SA layer's in-memory
/// value types and their JSON-serializable representations. Since the SA types
/// reference PD-layer types that contain non-Codable fields (e.g., `COSValue`,
/// `AnyPDFObject`), direct `Codable` conformance is not practical. Instead,
/// this encoder creates a parallel hierarchy of lightweight Codable DTOs
/// (Data Transfer Objects) that capture the accessibility-relevant properties.
///
/// ## Usage
///
/// ```swift
/// let encoder = SADocumentEncoder()
/// let jsonData = try encoder.encode(saDocument)
/// // jsonData is a UTF-8 JSON representation of the SA document tree
/// ```
///
/// ## Relationship to veraPDF
///
/// Corresponds to the Jackson JSON serializers in veraPDF-validation's
/// wcag-validation module (9 serializer classes). In Swift, `Codable`
/// replaces Jackson entirely. The DTO types handle the conversion from
/// the domain model to the serialized form.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent encoding
/// - Uses Codable DTOs instead of custom Jackson serializers
/// - JSONEncoder configuration for output formatting
public struct SADocumentEncoder: Sendable, Equatable {

    // MARK: - Configuration

    /// Whether to use pretty-printed JSON output.
    public let prettyPrinted: Bool

    /// Whether to sort keys in the JSON output.
    public let sortedKeys: Bool

    /// Whether to include null values in the output.
    public let includeNullValues: Bool

    /// Whether to include the full structure tree in the output.
    public let includeStructureTree: Bool

    /// Whether to include content chunk information in the output.
    public let includeContentChunks: Bool

    /// Whether to include WCAG issue details in the output.
    public let includeIssues: Bool

    // MARK: - Initialization

    /// Creates an SA document encoder.
    ///
    /// - Parameters:
    ///   - prettyPrinted: Whether to use pretty-printed JSON output. Defaults to `true`.
    ///   - sortedKeys: Whether to sort JSON keys. Defaults to `false`.
    ///   - includeNullValues: Whether to include null values. Defaults to `false`.
    ///   - includeStructureTree: Whether to include the full structure tree. Defaults to `true`.
    ///   - includeContentChunks: Whether to include content chunk info. Defaults to `false`.
    ///   - includeIssues: Whether to include WCAG issue details. Defaults to `true`.
    public init(
        prettyPrinted: Bool = true,
        sortedKeys: Bool = false,
        includeNullValues: Bool = false,
        includeStructureTree: Bool = true,
        includeContentChunks: Bool = false,
        includeIssues: Bool = true
    ) {
        self.prettyPrinted = prettyPrinted
        self.sortedKeys = sortedKeys
        self.includeNullValues = includeNullValues
        self.includeStructureTree = includeStructureTree
        self.includeContentChunks = includeContentChunks
        self.includeIssues = includeIssues
    }

    // MARK: - Encoding

    /// Encodes an SA document into JSON data.
    ///
    /// - Parameter document: The SA document to encode.
    /// - Returns: JSON data representing the document.
    /// - Throws: `SAEncodingError` if encoding fails.
    public func encode(_ document: SADocument) throws -> Data {
        let dto = documentDTO(from: document)
        return try encodeDTO(dto)
    }

    /// Encodes an SA document into a JSON string.
    ///
    /// - Parameter document: The SA document to encode.
    /// - Returns: A JSON string representing the document.
    /// - Throws: `SAEncodingError` if encoding fails.
    public func encodeToString(_ document: SADocument) throws -> String {
        let data = try encode(document)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SAEncodingError.stringConversionFailed
        }
        return string
    }

    /// Encodes an SA structure element into JSON data.
    ///
    /// - Parameter element: The SA structure element to encode.
    /// - Returns: JSON data representing the element.
    /// - Throws: `SAEncodingError` if encoding fails.
    public func encode(_ element: SAStructureElement) throws -> Data {
        let dto = structureElementDTO(from: element)
        return try encodeDTO(dto)
    }

    /// Encodes an SA node into JSON data.
    ///
    /// - Parameter node: The SA node to encode.
    /// - Returns: JSON data representing the node.
    /// - Throws: `SAEncodingError` if encoding fails.
    public func encode(_ node: SANode) throws -> Data {
        let dto = nodeDTO(from: node)
        return try encodeDTO(dto)
    }

    /// Encodes a content chunk container into JSON data.
    ///
    /// - Parameter container: The content chunk container to encode.
    /// - Returns: JSON data representing the container.
    /// - Throws: `SAEncodingError` if encoding fails.
    public func encode(_ container: ContentChunkContainer) throws -> Data {
        let dto = chunkContainerDTO(from: container)
        return try encodeDTO(dto)
    }

    /// Encodes WCAG issues into JSON data.
    ///
    /// - Parameter issues: The WCAG issues to encode.
    /// - Returns: JSON data representing the issues.
    /// - Throws: `SAEncodingError` if encoding fails.
    public func encode(_ issues: [WCAGIssue]) throws -> Data {
        let dtos = issues.map { issueDTO(from: $0) }
        return try encodeDTO(dtos)
    }

    // MARK: - Internal Encoding

    /// Creates a configured JSONEncoder.
    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        var formatting: JSONEncoder.OutputFormatting = []
        if prettyPrinted {
            formatting.insert(.prettyPrinted)
        }
        if sortedKeys {
            formatting.insert(.sortedKeys)
        }
        encoder.outputFormatting = formatting
        return encoder
    }

    /// Encodes a Codable value to JSON data.
    func encodeDTO<T: Encodable>(_ value: T) throws -> Data {
        let encoder = makeEncoder()
        do {
            return try encoder.encode(value)
        } catch {
            throw SAEncodingError.encodingFailed(error.localizedDescription)
        }
    }

    // MARK: - DTO Conversion

    /// Converts an SADocument to its DTO representation.
    func documentDTO(from document: SADocument) -> SADocumentDTO {
        let pages = document.pages.map { pageDTO(from: $0) }
        let structureRoot: SAStructureRootDTO?
        if includeStructureTree, let root = document.structureRoot {
            structureRoot = structureRootDTO(from: root)
        } else {
            structureRoot = nil
        }

        return SADocumentDTO(
            id: document.id.uuidString,
            saObjectType: document.saObjectType,
            pdfVersion: document.pdfVersion,
            pageCount: document.pageCount,
            isTagged: document.isTagged,
            language: document.language,
            hasStructureRoot: document.hasStructureRoot,
            meetsBasicAccessibility: document.meetsBasicAccessibility,
            pages: pages,
            structureRoot: structureRoot
        )
    }

    /// Converts an SAPage to its DTO representation.
    func pageDTO(from page: SAPage) -> SAPageDTO {
        let nodes = page.nodes.map { nodeDTO(from: $0) }
        return SAPageDTO(
            id: page.id.uuidString,
            saObjectType: page.saObjectType,
            pageNumber: page.pageNumber,
            hasContent: page.hasContent,
            hasAnnotations: page.hasAnnotations,
            annotationCount: page.annotationCount,
            nodeCount: page.nodeCount,
            nodes: nodes
        )
    }

    /// Converts an SAStructureRoot to its DTO representation.
    func structureRootDTO(from root: SAStructureRoot) -> SAStructureRootDTO {
        let children = root.children.map { nodeDTO(from: $0) }
        return SAStructureRootDTO(
            id: root.id.uuidString,
            saObjectType: root.saObjectType,
            childCount: root.childCount,
            totalElementCount: root.structTreeRoot.totalElementCount,
            maxDepth: root.structTreeRoot.maxDepth,
            headingCount: root.headingCount,
            tableCount: root.tableCount,
            figureCount: root.figureCount,
            listCount: root.listCount,
            children: children
        )
    }

    /// Converts an SANode to its DTO representation.
    func nodeDTO(from node: SANode) -> SANodeDTO {
        let children = node.children.map { nodeDTO(from: $0) }
        return SANodeDTO(
            id: node.id.uuidString,
            saObjectType: node.saObjectType,
            structureTypeName: node.structureTypeName,
            structureType: node.structureType?.rawValue,
            altText: node.altText,
            actualText: node.actualText,
            language: node.language,
            effectiveLanguage: node.effectiveLanguage,
            inheritedLanguage: node.inheritedLanguage,
            isHeading: node.isHeading,
            headingLevel: node.headingLevel,
            isFigure: node.isFigure,
            isArtifact: node.isArtifact,
            isAccessible: node.isAccessible,
            pageNumber: node.pageNumber,
            childCount: node.childCount,
            children: children
        )
    }

    /// Converts an SAStructureElement to its DTO representation.
    func structureElementDTO(from element: SAStructureElement) -> SAStructureElementDTO {
        let children = element.children.map { structureElementDTO(from: $0) }
        return SAStructureElementDTO(
            id: element.id.uuidString,
            saObjectType: element.saObjectType,
            originalTypeName: element.originalTypeName,
            resolvedTypeName: element.resolvedTypeName,
            resolvedType: element.resolvedType?.rawValue,
            wasRemapped: element.wasRemapped,
            isStandardType: element.isStandardType,
            altText: element.altText,
            actualText: element.actualText,
            expansionText: element.expansionText,
            effectiveLanguage: element.effectiveLanguage,
            hasOwnLanguage: element.hasOwnLanguage,
            depth: element.depth,
            siblingIndex: element.siblingIndex,
            pageNumber: element.pageNumber,
            elementID: element.elementID,
            namespaceURI: element.namespaceURI,
            isHeading: element.isHeading,
            headingLevel: element.headingLevel,
            isFigure: element.isFigure,
            isAccessible: element.isAccessible,
            isAccessibilityRelevant: element.isAccessibilityRelevant,
            meetsAccessibilityRequirements: element.meetsAccessibilityRequirements,
            childCount: element.childCount,
            kidsStandardTypes: element.kidsStandardTypes,
            children: children
        )
    }

    /// Converts a ContentChunkContainer to its DTO representation.
    func chunkContainerDTO(from container: ContentChunkContainer) -> ContentChunkContainerDTO {
        let chunks = container.chunks.map { chunkDTO(from: $0) }
        return ContentChunkContainerDTO(
            count: container.count,
            pageNumbers: container.pageNumbers,
            countsByType: container.countsByType.reduce(into: [:]) { dict, pair in
                dict[pair.key.rawValue] = pair.value
            },
            chunks: chunks
        )
    }

    /// Converts a ContentChunk to its DTO representation.
    func chunkDTO(from chunk: ContentChunk) -> ContentChunkDTO {
        ContentChunkDTO(
            id: chunk.id.uuidString,
            type: chunk.type.rawValue,
            pageNumber: chunk.pageNumber,
            sequenceIndex: chunk.sequenceIndex,
            operatorCount: chunk.operatorCount,
            markedContentTag: chunk.markedContentTag,
            markedContentID: chunk.markedContentID,
            structureElementType: chunk.structureElementType?.rawValue,
            graphicsStateDepth: chunk.graphicsStateDepth,
            isMarkedContent: chunk.isMarkedContent,
            isText: chunk.isText,
            isImage: chunk.isImage,
            isPath: chunk.isPath
        )
    }

    /// Converts a WCAGIssue to its DTO representation.
    func issueDTO(from issue: WCAGIssue) -> WCAGIssueDTO {
        WCAGIssueDTO(
            id: issue.id.uuidString,
            severity: issue.severity.rawValue,
            category: issue.category.rawValue,
            message: issue.message,
            successCriterion: issue.successCriterion,
            pageNumber: issue.pageNumber,
            structureElementType: issue.structureElementType
        )
    }
}

// MARK: - Factory Methods

extension SADocumentEncoder {

    /// Creates a default encoder with pretty-printed output.
    public static func `default`() -> SADocumentEncoder {
        SADocumentEncoder()
    }

    /// Creates a compact encoder without pretty-printing.
    public static func compact() -> SADocumentEncoder {
        SADocumentEncoder(prettyPrinted: false, sortedKeys: false)
    }

    /// Creates a full encoder that includes all available data.
    public static func full() -> SADocumentEncoder {
        SADocumentEncoder(
            prettyPrinted: true,
            sortedKeys: true,
            includeNullValues: true,
            includeStructureTree: true,
            includeContentChunks: true,
            includeIssues: true
        )
    }

    /// Creates a minimal encoder that includes only summary data.
    public static func minimal() -> SADocumentEncoder {
        SADocumentEncoder(
            prettyPrinted: false,
            sortedKeys: false,
            includeNullValues: false,
            includeStructureTree: false,
            includeContentChunks: false,
            includeIssues: false
        )
    }
}

// MARK: - SA Encoding Error

/// Errors that can occur during SA document encoding.
public enum SAEncodingError: Error, Sendable, Equatable {

    /// The encoding process failed.
    case encodingFailed(String)

    /// String conversion from UTF-8 data failed.
    case stringConversionFailed

    /// The input was invalid or incomplete.
    case invalidInput(String)
}

// MARK: - Codable DTOs

/// Codable DTO for SADocument.
///
/// This is a lightweight, JSON-serializable representation of an SA document
/// containing only accessibility-relevant properties.
public struct SADocumentDTO: Codable, Sendable, Equatable {

    /// The document's unique identifier.
    public let id: String

    /// The SA object type name.
    public let saObjectType: String

    /// The PDF version string.
    public let pdfVersion: String

    /// The number of pages.
    public let pageCount: Int

    /// Whether the document is tagged.
    public let isTagged: Bool

    /// The document language.
    public let language: String?

    /// Whether the document has a structure root.
    public let hasStructureRoot: Bool

    /// Whether the document meets basic accessibility.
    public let meetsBasicAccessibility: Bool

    /// The SA pages.
    public let pages: [SAPageDTO]

    /// The SA structure root, if included.
    public let structureRoot: SAStructureRootDTO?
}

/// Codable DTO for SAPage.
public struct SAPageDTO: Codable, Sendable, Equatable {

    /// The page's unique identifier.
    public let id: String

    /// The SA object type name.
    public let saObjectType: String

    /// The 1-based page number.
    public let pageNumber: Int

    /// Whether the page has content.
    public let hasContent: Bool

    /// Whether the page has annotations.
    public let hasAnnotations: Bool

    /// The annotation count.
    public let annotationCount: Int

    /// The number of SA nodes.
    public let nodeCount: Int

    /// The SA nodes on this page.
    public let nodes: [SANodeDTO]
}

/// Codable DTO for SAStructureRoot.
public struct SAStructureRootDTO: Codable, Sendable, Equatable {

    /// The structure root's unique identifier.
    public let id: String

    /// The SA object type name.
    public let saObjectType: String

    /// The number of top-level children.
    public let childCount: Int

    /// The total number of elements in the tree.
    public let totalElementCount: Int

    /// The maximum depth of the tree.
    public let maxDepth: Int

    /// The number of heading elements.
    public let headingCount: Int

    /// The number of table elements.
    public let tableCount: Int

    /// The number of figure elements.
    public let figureCount: Int

    /// The number of list elements.
    public let listCount: Int

    /// The top-level SA nodes.
    public let children: [SANodeDTO]
}

/// Codable DTO for SANode.
public struct SANodeDTO: Codable, Sendable, Equatable {

    /// The node's unique identifier.
    public let id: String

    /// The SA object type name.
    public let saObjectType: String

    /// The raw structure type name.
    public let structureTypeName: String

    /// The resolved structure type, if known.
    public let structureType: String?

    /// Alternative text.
    public let altText: String?

    /// Actual text.
    public let actualText: String?

    /// The node's own language.
    public let language: String?

    /// The effective language.
    public let effectiveLanguage: String?

    /// The inherited language.
    public let inheritedLanguage: String?

    /// Whether the node is a heading.
    public let isHeading: Bool

    /// The heading level, if applicable.
    public let headingLevel: Int?

    /// Whether the node is a figure.
    public let isFigure: Bool

    /// Whether the node is an artifact.
    public let isArtifact: Bool

    /// Whether the node is accessible.
    public let isAccessible: Bool

    /// The page number.
    public let pageNumber: Int?

    /// The child count.
    public let childCount: Int

    /// Child nodes.
    public let children: [SANodeDTO]
}

/// Codable DTO for SAStructureElement.
public struct SAStructureElementDTO: Codable, Sendable, Equatable {

    /// The element's unique identifier.
    public let id: String

    /// The SA object type name.
    public let saObjectType: String

    /// The original type name from the PDF.
    public let originalTypeName: String

    /// The resolved type name.
    public let resolvedTypeName: String

    /// The resolved structure type, if known.
    public let resolvedType: String?

    /// Whether the type was remapped.
    public let wasRemapped: Bool

    /// Whether the type is a standard type.
    public let isStandardType: Bool

    /// Alternative text.
    public let altText: String?

    /// Actual text.
    public let actualText: String?

    /// Expansion text.
    public let expansionText: String?

    /// The effective language.
    public let effectiveLanguage: String?

    /// Whether the element has its own language.
    public let hasOwnLanguage: Bool

    /// The depth in the tree.
    public let depth: Int

    /// The sibling index.
    public let siblingIndex: Int

    /// The page number.
    public let pageNumber: Int?

    /// The element ID.
    public let elementID: String?

    /// The namespace URI.
    public let namespaceURI: String?

    /// Whether the element is a heading.
    public let isHeading: Bool

    /// The heading level.
    public let headingLevel: Int?

    /// Whether the element is a figure.
    public let isFigure: Bool

    /// Whether the element is accessible.
    public let isAccessible: Bool

    /// Whether the element is accessibility-relevant.
    public let isAccessibilityRelevant: Bool

    /// Whether the element meets accessibility requirements.
    public let meetsAccessibilityRequirements: Bool

    /// The child count.
    public let childCount: Int

    /// The children's standard types.
    public let kidsStandardTypes: String

    /// Child elements.
    public let children: [SAStructureElementDTO]
}

/// Codable DTO for ContentChunkContainer.
public struct ContentChunkContainerDTO: Codable, Sendable, Equatable {

    /// The total number of chunks.
    public let count: Int

    /// The page numbers present.
    public let pageNumbers: [Int]

    /// Chunk counts by type.
    public let countsByType: [String: Int]

    /// The individual chunks.
    public let chunks: [ContentChunkDTO]
}

/// Codable DTO for ContentChunk.
public struct ContentChunkDTO: Codable, Sendable, Equatable {

    /// The chunk's unique identifier.
    public let id: String

    /// The chunk type.
    public let type: String

    /// The page number.
    public let pageNumber: Int

    /// The sequence index.
    public let sequenceIndex: Int

    /// The number of operators.
    public let operatorCount: Int

    /// The marked content tag.
    public let markedContentTag: String?

    /// The marked content ID.
    public let markedContentID: Int?

    /// The structure element type.
    public let structureElementType: String?

    /// The graphics state depth.
    public let graphicsStateDepth: Int

    /// Whether the chunk is marked content.
    public let isMarkedContent: Bool

    /// Whether the chunk is text.
    public let isText: Bool

    /// Whether the chunk is an image.
    public let isImage: Bool

    /// Whether the chunk is a path.
    public let isPath: Bool
}

/// Codable DTO for WCAGIssue.
public struct WCAGIssueDTO: Codable, Sendable, Equatable {

    /// The issue's unique identifier.
    public let id: String

    /// The severity level.
    public let severity: String

    /// The issue category.
    public let category: String

    /// The issue message.
    public let message: String

    /// The WCAG success criterion.
    public let successCriterion: String?

    /// The page number.
    public let pageNumber: Int?

    /// The structure element type.
    public let structureElementType: String?
}
