import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Validated Content Stream

/// A validation wrapper for a PDF content stream.
///
/// Content streams contain sequences of operators that describe the visual content
/// of a page, form XObject, or other content-bearing PDF objects. This struct
/// wraps parsed content stream data for operator-level validation.
///
/// ## Key Properties
///
/// - **Operators**: The sequence of content stream operators
/// - **Resources**: Reference to the resource dictionary for operator resolution
/// - **Metrics**: Statistics about operator usage
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDContentStream` from veraPDF-validation, which provides
/// operator-level access for content stream validation rules.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent validation
/// - Uses `ValidatedOperator` enum instead of 97 Java operator classes
public struct ValidatedContentStream: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this content stream.
    public let id: UUID

    /// The underlying COS stream dictionary.
    public let cosDictionary: COSValue?

    /// The object key for the stream, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context for this content stream.
    public let validationContext: ObjectContext

    // MARK: - Content Stream Properties

    /// The page number this content stream belongs to (1-based).
    public let pageNumber: Int

    /// The index of this content stream within the page's Contents array.
    ///
    /// A page can have multiple content streams. This index identifies
    /// which one this is (0-based).
    public let streamIndex: Int

    /// The operators in this content stream.
    public let operators: [ValidatedOperator]

    /// Whether this content stream is from a Form XObject rather than a page.
    public let isFormXObject: Bool

    /// The Form XObject name, if this is from a Form XObject.
    public let formXObjectName: ASAtom?

    /// The length of the content stream data in bytes.
    public let contentLength: Int

    // MARK: - Operator Statistics

    /// The total number of operators in this content stream.
    public var operatorCount: Int {
        operators.count
    }

    /// The number of text operators.
    public var textOperatorCount: Int {
        operators.filter { $0.category == .textObject || $0.category == .textState ||
            $0.category == .textPositioning || $0.category == .textShowing }.count
    }

    /// The number of graphics state operators.
    public var graphicsStateOperatorCount: Int {
        operators.filter { $0.category == .graphicsState }.count
    }

    /// The number of path operators.
    public var pathOperatorCount: Int {
        operators.filter { $0.category == .pathConstruction || $0.category == .pathPainting }.count
    }

    /// The number of color operators.
    public var colorOperatorCount: Int {
        operators.filter { $0.category == .color }.count
    }

    /// The number of marked content operators.
    public var markedContentOperatorCount: Int {
        operators.filter { $0.category == .markedContent }.count
    }

    // MARK: - Marked Content Analysis

    /// Whether the content stream contains any marked content operators.
    public var hasMarkedContent: Bool {
        markedContentOperatorCount > 0
    }

    /// The number of begin marked content operations (BMC/BDC).
    public var beginMarkedContentCount: Int {
        operators.filter { op in
            switch op {
            case .beginMarkedContent, .beginMarkedContentWithProperties:
                return true
            default:
                return false
            }
        }.count
    }

    /// The number of end marked content operations (EMC).
    public var endMarkedContentCount: Int {
        operators.filter { op in
            if case .endMarkedContent = op { return true }
            return false
        }.count
    }

    /// Whether the marked content operators are balanced (equal BMC/BDC and EMC).
    public var isMarkedContentBalanced: Bool {
        beginMarkedContentCount == endMarkedContentCount
    }

    // MARK: - Text Analysis

    /// Whether the content stream contains any text operators.
    public var hasTextContent: Bool {
        textOperatorCount > 0
    }

    /// Whether the BT/ET pairs are balanced.
    public var isTextObjectBalanced: Bool {
        let beginCount = operators.filter { op in
            if case .beginText = op { return true }
            return false
        }.count
        let endCount = operators.filter { op in
            if case .endText = op { return true }
            return false
        }.count
        return beginCount == endCount
    }

    // MARK: - Graphics State Analysis

    /// Whether the q/Q (save/restore) pairs are balanced.
    public var isGraphicsStateBalanced: Bool {
        let saveCount = operators.filter { op in
            if case .saveGraphicsState = op { return true }
            return false
        }.count
        let restoreCount = operators.filter { op in
            if case .restoreGraphicsState = op { return true }
            return false
        }.count
        return saveCount == restoreCount
    }

    /// The maximum nesting depth of graphics state save/restore.
    public var maxGraphicsStateDepth: Int {
        var depth = 0
        var maxDepth = 0
        for op in operators {
            switch op {
            case .saveGraphicsState:
                depth += 1
                maxDepth = max(maxDepth, depth)
            case .restoreGraphicsState:
                depth = max(0, depth - 1)
            default:
                break
            }
        }
        return maxDepth
    }

    // MARK: - Initialization

    /// Creates a validated content stream.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - cosDictionary: The COS stream dictionary.
    ///   - objectKey: The object key.
    ///   - context: The validation context.
    ///   - pageNumber: The page number (1-based).
    ///   - streamIndex: Index within the page's Contents array.
    ///   - operators: The parsed operators.
    ///   - isFormXObject: Whether this is from a Form XObject.
    ///   - formXObjectName: The Form XObject name.
    ///   - contentLength: The content length in bytes.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        pageNumber: Int = 1,
        streamIndex: Int = 0,
        operators: [ValidatedOperator] = [],
        isFormXObject: Bool = false,
        formXObjectName: ASAtom? = nil,
        contentLength: Int = 0
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .contentStream(page: pageNumber)
        self.pageNumber = pageNumber
        self.streamIndex = streamIndex
        self.operators = operators
        self.isFormXObject = isFormXObject
        self.formXObjectName = formXObjectName
        self.contentLength = contentLength
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDContentStream"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "pageNumber", "streamIndex", "operatorCount",
            "isFormXObject", "formXObjectName", "contentLength",
            "textOperatorCount", "graphicsStateOperatorCount",
            "pathOperatorCount", "colorOperatorCount",
            "markedContentOperatorCount", "hasMarkedContent",
            "isMarkedContentBalanced", "hasTextContent",
            "isTextObjectBalanced", "isGraphicsStateBalanced",
            "maxGraphicsStateDepth"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "pageNumber":
            return .integer(Int64(pageNumber))
        case "streamIndex":
            return .integer(Int64(streamIndex))
        case "operatorCount":
            return .integer(Int64(operatorCount))
        case "isFormXObject":
            return .boolean(isFormXObject)
        case "formXObjectName":
            if let formName = formXObjectName {
                return .name(formName.stringValue)
            }
            return .null
        case "contentLength":
            return .integer(Int64(contentLength))
        case "textOperatorCount":
            return .integer(Int64(textOperatorCount))
        case "graphicsStateOperatorCount":
            return .integer(Int64(graphicsStateOperatorCount))
        case "pathOperatorCount":
            return .integer(Int64(pathOperatorCount))
        case "colorOperatorCount":
            return .integer(Int64(colorOperatorCount))
        case "markedContentOperatorCount":
            return .integer(Int64(markedContentOperatorCount))
        case "hasMarkedContent":
            return .boolean(hasMarkedContent)
        case "isMarkedContentBalanced":
            return .boolean(isMarkedContentBalanced)
        case "hasTextContent":
            return .boolean(hasTextContent)
        case "isTextObjectBalanced":
            return .boolean(isTextObjectBalanced)
        case "isGraphicsStateBalanced":
            return .boolean(isGraphicsStateBalanced)
        case "maxGraphicsStateDepth":
            return .integer(Int64(maxGraphicsStateDepth))
        default:
            return nil
        }
    }

    // MARK: - Operator Access

    /// Returns operators of a specific category.
    ///
    /// - Parameter category: The operator category to filter by.
    /// - Returns: Operators matching the category.
    public func operators(inCategory category: OperatorCategory) -> [ValidatedOperator] {
        operators.filter { $0.category == category }
    }

    /// Returns the operator at a given index.
    ///
    /// - Parameter index: The index.
    /// - Returns: The operator, or `nil` if the index is out of bounds.
    public func operatorAt(_ index: Int) -> ValidatedOperator? {
        guard operators.indices.contains(index) else { return nil }
        return operators[index]
    }

    /// Returns a summary string describing the content stream.
    public var summary: String {
        var parts: [String] = []
        if isFormXObject {
            if let name = formXObjectName {
                parts.append("Form XObject \(name.stringValue)")
            } else {
                parts.append("Form XObject")
            }
        } else {
            parts.append("Page \(pageNumber) stream[\(streamIndex)]")
        }
        parts.append("\(operatorCount) ops")
        if hasTextContent { parts.append("text") }
        if hasMarkedContent { parts.append("marked") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedContentStream, rhs: ValidatedContentStream) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Factory Methods

extension ValidatedContentStream {

    /// Creates a minimal content stream for testing.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number.
    ///   - operators: The operators.
    /// - Returns: A minimal content stream.
    public static func minimal(
        pageNumber: Int = 1,
        operators: [ValidatedOperator] = []
    ) -> ValidatedContentStream {
        ValidatedContentStream(
            pageNumber: pageNumber,
            operators: operators
        )
    }

    /// Creates a content stream from a Form XObject.
    ///
    /// - Parameters:
    ///   - name: The Form XObject name.
    ///   - pageNumber: The page number.
    ///   - operators: The operators.
    /// - Returns: A Form XObject content stream.
    public static func formXObject(
        named name: ASAtom,
        pageNumber: Int = 1,
        operators: [ValidatedOperator] = []
    ) -> ValidatedContentStream {
        ValidatedContentStream(
            pageNumber: pageNumber,
            operators: operators,
            isFormXObject: true,
            formXObjectName: name
        )
    }
}
