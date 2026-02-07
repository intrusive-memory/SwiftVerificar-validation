import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Pattern Type

/// The type of a PDF pattern.
///
/// PDF supports two types of patterns: tiling patterns and shading patterns.
///
/// See PDF specification Table 75 -- Pattern types.
public enum PatternType: Int, Sendable, Hashable, CaseIterable {
    /// Tiling pattern: content is repeated to fill a region.
    case tiling = 1

    /// Shading pattern: a smooth color gradient fills a region.
    case shading = 2

    /// Unknown pattern type.
    case unknown = 0

    /// Creates a pattern type from an integer value.
    ///
    /// - Parameter value: The pattern type integer.
    public init(fromValue value: Int?) {
        guard let value = value else {
            self = .unknown
            return
        }
        self = PatternType(rawValue: value) ?? .unknown
    }
}

// MARK: - Tiling Paint Type

/// The paint type of a tiling pattern.
///
/// The paint type determines whether the pattern cell's colors come from
/// the pattern definition or from the current color at the time of painting.
///
/// See PDF specification Table 76 -- Entries in a Type 1 (tiling) pattern dictionary.
public enum TilingPaintType: Int, Sendable, Hashable, CaseIterable {
    /// Colored tiling pattern: the pattern definition specifies colors.
    case colored = 1

    /// Uncolored tiling pattern: colors come from the current graphics state.
    case uncolored = 2

    /// Unknown paint type.
    case unknown = 0

    /// Creates a paint type from an integer value.
    ///
    /// - Parameter value: The paint type integer.
    public init(fromValue value: Int?) {
        guard let value = value else {
            self = .unknown
            return
        }
        self = TilingPaintType(rawValue: value) ?? .unknown
    }

    /// Whether this paint type uses colors from the pattern itself.
    public var isColored: Bool {
        self == .colored
    }
}

// MARK: - Tiling Type

/// The tiling type of a tiling pattern.
///
/// The tiling type controls how the pattern cell is adjusted to
/// fill the painted area.
///
/// See PDF specification Table 76.
public enum TilingType: Int, Sendable, Hashable, CaseIterable {
    /// Constant spacing: pattern cells are spaced consistently.
    case constantSpacing = 1

    /// No distortion: pattern cells maintain their shape.
    case noDistortion = 2

    /// Constant spacing and faster tiling.
    case constantSpacingFasterTiling = 3

    /// Unknown tiling type.
    case unknown = 0

    /// Creates a tiling type from an integer value.
    ///
    /// - Parameter value: The tiling type integer.
    public init(fromValue value: Int?) {
        guard let value = value else {
            self = .unknown
            return
        }
        self = TilingType(rawValue: value) ?? .unknown
    }
}

// MARK: - Validated Pattern

/// A validation wrapper for a PDF pattern.
///
/// Patterns define how a region is painted with repeated graphics (tiling)
/// or smooth color gradients (shading). They are referenced as color space
/// operands or as resources.
///
/// ## Key Properties
///
/// - **PatternType**: Tiling (1) or Shading (2)
/// - **BBox**: The bounding box of the pattern cell (for tiling)
/// - **XStep/YStep**: Spacing between pattern cells (for tiling)
/// - **Matrix**: The pattern-to-user space transform matrix
///
/// ## Validation Rules
///
/// - **PDF/A**: Patterns must have valid bounding boxes and step values.
/// - **PDF/A-1**: Certain restrictions on pattern color spaces apply.
/// - **PDF/UA**: Patterns used as backgrounds must not interfere with
///   content readability.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDTilingPattern` and `GFPDShadingPattern` from
/// veraPDF-validation, consolidated into a single struct.
public struct ValidatedPattern: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the pattern.
    public let cosDictionary: COSValue?

    /// The object key for the pattern, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Pattern Properties

    /// The pattern type (tiling or shading).
    public let patternType: PatternType

    /// Whether the pattern has a valid bounding box (`/BBox` entry).
    public let hasBBox: Bool

    /// The bounding box of the pattern cell.
    public let bBox: PDFRect?

    /// Whether the pattern has a transformation matrix (`/Matrix` entry).
    public let hasMatrix: Bool

    // MARK: - Tiling Pattern Properties

    /// The paint type for tiling patterns.
    public let paintType: TilingPaintType?

    /// The tiling type for tiling patterns.
    public let tilingType: TilingType?

    /// The horizontal spacing between pattern cells.
    public let xStep: Double?

    /// The vertical spacing between pattern cells.
    public let yStep: Double?

    /// Whether the tiling pattern has a content stream.
    public let hasContentStream: Bool

    /// Whether the tiling pattern has its own resources.
    public let hasResources: Bool

    // MARK: - Shading Pattern Properties

    /// Whether this is a shading pattern with an associated shading dictionary.
    public let hasShading: Bool

    /// The shading type for shading patterns.
    public let shadingType: Int?

    /// Whether the shading pattern has an ExtGState reference.
    public let hasExtGState: Bool

    // MARK: - Initialization

    /// Creates a validated pattern.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the pattern.
    ///   - objectKey: The object key.
    ///   - context: Validation context.
    ///   - patternType: The pattern type.
    ///   - hasBBox: Whether a bounding box exists.
    ///   - bBox: The bounding box.
    ///   - hasMatrix: Whether a transformation matrix exists.
    ///   - paintType: The tiling paint type.
    ///   - tilingType: The tiling type.
    ///   - xStep: Horizontal cell spacing.
    ///   - yStep: Vertical cell spacing.
    ///   - hasContentStream: Whether a content stream exists.
    ///   - hasResources: Whether pattern resources exist.
    ///   - hasShading: Whether a shading dictionary exists.
    ///   - shadingType: The shading type number.
    ///   - hasExtGState: Whether an ExtGState reference exists.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(location: "Pattern"),
        patternType: PatternType = .tiling,
        hasBBox: Bool = false,
        bBox: PDFRect? = nil,
        hasMatrix: Bool = false,
        paintType: TilingPaintType? = nil,
        tilingType: TilingType? = nil,
        xStep: Double? = nil,
        yStep: Double? = nil,
        hasContentStream: Bool = false,
        hasResources: Bool = false,
        hasShading: Bool = false,
        shadingType: Int? = nil,
        hasExtGState: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.patternType = patternType
        self.hasBBox = hasBBox
        self.bBox = bBox
        self.hasMatrix = hasMatrix
        self.paintType = paintType
        self.tilingType = tilingType
        self.xStep = xStep
        self.yStep = yStep
        self.hasContentStream = hasContentStream
        self.hasResources = hasResources
        self.hasShading = hasShading
        self.shadingType = shadingType
        self.hasExtGState = hasExtGState
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDPattern"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "patternType", "hasBBox", "bBox", "hasMatrix",
            "paintType", "tilingType", "xStep", "yStep",
            "hasContentStream", "hasResources",
            "hasShading", "shadingType", "hasExtGState",
            "isTilingPattern", "isShadingPattern",
            "hasValidSteps", "isColored"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "patternType":
            return .integer(Int64(patternType.rawValue))
        case "hasBBox":
            return .boolean(hasBBox)
        case "bBox":
            if let bb = bBox { return .string(bb.description) }
            return .null
        case "hasMatrix":
            return .boolean(hasMatrix)
        case "paintType":
            if let pt = paintType { return .integer(Int64(pt.rawValue)) }
            return .null
        case "tilingType":
            if let tt = tilingType { return .integer(Int64(tt.rawValue)) }
            return .null
        case "xStep":
            if let xs = xStep { return .real(xs) }
            return .null
        case "yStep":
            if let ys = yStep { return .real(ys) }
            return .null
        case "hasContentStream":
            return .boolean(hasContentStream)
        case "hasResources":
            return .boolean(hasResources)
        case "hasShading":
            return .boolean(hasShading)
        case "shadingType":
            if let st = shadingType { return .integer(Int64(st)) }
            return .null
        case "hasExtGState":
            return .boolean(hasExtGState)
        case "isTilingPattern":
            return .boolean(isTilingPattern)
        case "isShadingPattern":
            return .boolean(isShadingPattern)
        case "hasValidSteps":
            return .boolean(hasValidSteps)
        case "isColored":
            return .boolean(isColored)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedPattern, rhs: ValidatedPattern) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedPattern {

    /// Whether this is a tiling pattern.
    public var isTilingPattern: Bool {
        patternType == .tiling
    }

    /// Whether this is a shading pattern.
    public var isShadingPattern: Bool {
        patternType == .shading
    }

    /// Whether the tiling pattern has valid step values.
    ///
    /// Step values must be non-zero for a valid tiling pattern.
    public var hasValidSteps: Bool {
        guard isTilingPattern else { return true }
        guard let xs = xStep, let ys = yStep else { return false }
        return xs != 0 && ys != 0
    }

    /// Whether this is a colored tiling pattern.
    public var isColored: Bool {
        paintType?.isColored ?? false
    }

    /// Whether this is an uncolored tiling pattern.
    public var isUncolored: Bool {
        paintType == .uncolored
    }

    /// Returns a summary string describing the pattern.
    public var summary: String {
        var parts: [String] = []
        switch patternType {
        case .tiling:
            parts.append("Tiling")
            if let pt = paintType {
                parts.append(pt.isColored ? "colored" : "uncolored")
            }
            if let xs = xStep, let ys = yStep {
                parts.append("step=(\(xs),\(ys))")
            }
        case .shading:
            parts.append("Shading")
            if let st = shadingType {
                parts.append("type=\(st)")
            }
        case .unknown:
            parts.append("Unknown")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedPattern {

    /// Creates a colored tiling pattern for testing.
    ///
    /// - Parameters:
    ///   - xStep: Horizontal cell spacing.
    ///   - yStep: Vertical cell spacing.
    /// - Returns: A colored tiling pattern.
    public static func coloredTiling(
        xStep: Double = 10.0,
        yStep: Double = 10.0
    ) -> ValidatedPattern {
        ValidatedPattern(
            patternType: .tiling,
            hasBBox: true,
            bBox: PDFRect(x: 0, y: 0, width: xStep, height: yStep),
            paintType: .colored,
            tilingType: .constantSpacing,
            xStep: xStep,
            yStep: yStep,
            hasContentStream: true,
            hasResources: true
        )
    }

    /// Creates an uncolored tiling pattern for testing.
    ///
    /// - Parameters:
    ///   - xStep: Horizontal cell spacing.
    ///   - yStep: Vertical cell spacing.
    /// - Returns: An uncolored tiling pattern.
    public static func uncoloredTiling(
        xStep: Double = 10.0,
        yStep: Double = 10.0
    ) -> ValidatedPattern {
        ValidatedPattern(
            patternType: .tiling,
            hasBBox: true,
            bBox: PDFRect(x: 0, y: 0, width: xStep, height: yStep),
            paintType: .uncolored,
            tilingType: .constantSpacing,
            xStep: xStep,
            yStep: yStep,
            hasContentStream: true
        )
    }

    /// Creates a shading pattern for testing.
    ///
    /// - Parameter shadingType: The shading type (1-7).
    /// - Returns: A shading pattern.
    public static func shading(shadingType: Int = 2) -> ValidatedPattern {
        ValidatedPattern(
            patternType: .shading,
            hasShading: true,
            shadingType: shadingType
        )
    }
}
