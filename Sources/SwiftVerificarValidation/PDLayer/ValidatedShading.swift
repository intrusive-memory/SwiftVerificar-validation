import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Shading Type

/// The type of a PDF shading.
///
/// PDF supports seven types of shading, each defining a different
/// method of computing colors across a region.
///
/// See PDF specification Table 78 -- Shading types.
public enum ShadingType: Int, Sendable, Hashable, CaseIterable {
    /// Function-based shading: colors are computed by a mathematical function.
    case functionBased = 1

    /// Axial shading: a linear gradient between two points.
    case axial = 2

    /// Radial shading: a gradient between two circles.
    case radial = 3

    /// Free-form Gouraud-shaded triangle mesh.
    case freeFormGouraud = 4

    /// Lattice-form Gouraud-shaded triangle mesh.
    case latticeFormGouraud = 5

    /// Coons patch mesh.
    case coonsPatch = 6

    /// Tensor-product patch mesh.
    case tensorProduct = 7

    /// Unknown shading type.
    case unknown = 0

    /// Creates a shading type from an integer value.
    ///
    /// - Parameter value: The shading type integer.
    public init(fromValue value: Int?) {
        guard let value = value else {
            self = .unknown
            return
        }
        self = ShadingType(rawValue: value) ?? .unknown
    }

    /// Whether this is a mesh-based shading (types 4-7).
    public var isMesh: Bool {
        switch self {
        case .freeFormGouraud, .latticeFormGouraud, .coonsPatch, .tensorProduct:
            return true
        default:
            return false
        }
    }

    /// Whether this is a gradient shading (types 2-3).
    public var isGradient: Bool {
        self == .axial || self == .radial
    }
}

// MARK: - Validated Shading

/// A validation wrapper for a PDF shading dictionary.
///
/// Shadings define smooth color transitions across regions. They are used
/// by shading patterns and the `sh` operator to paint gradients and
/// computed color fills.
///
/// ## Key Properties
///
/// - **ShadingType**: The type of shading (1-7)
/// - **ColorSpace**: The color space for the shading
/// - **BBox**: Optional clipping bounding box
/// - **Background**: Optional background color
/// - **Function**: Mathematical function(s) defining color variation
///
/// ## Validation Rules
///
/// - **PDF/A**: Shading color spaces must comply with PDF/A requirements.
/// - **PDF/A-1**: Device-dependent color spaces in shadings may need
///   an output intent or ICC profile.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDShading` from veraPDF-validation, which validates
/// shading dictionaries against PDF/A color space requirements.
public struct ValidatedShading: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the shading.
    public let cosDictionary: COSValue?

    /// The object key for the shading, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Shading Properties

    /// The shading type.
    public let shadingType: ShadingType

    /// The color space name for the shading (`/ColorSpace` entry).
    public let colorSpaceName: String?

    /// The number of color components in the shading's color space.
    public let colorComponentCount: Int

    /// Whether the shading has a bounding box (`/BBox` entry).
    public let hasBBox: Bool

    /// The bounding box, if present.
    public let bBox: PDFRect?

    /// Whether the shading has a background color (`/Background` entry).
    public let hasBackground: Bool

    /// Whether the shading has a function (`/Function` entry).
    public let hasFunction: Bool

    /// The number of functions (some shadings have multiple).
    public let functionCount: Int

    /// Whether anti-aliasing is enabled (`/AntiAlias` entry).
    public let antiAlias: Bool

    // MARK: - Gradient Properties (Axial/Radial)

    /// Whether the shading has domain values (`/Domain` entry).
    public let hasDomain: Bool

    /// Whether the shading has coordinate values (`/Coords` entry).
    public let hasCoords: Bool

    /// Whether the shading extends beyond the start point (`/Extend[0]`).
    public let extendStart: Bool

    /// Whether the shading extends beyond the end point (`/Extend[1]`).
    public let extendEnd: Bool

    // MARK: - Mesh Properties (Types 4-7)

    /// The bits per coordinate for mesh shadings.
    public let bitsPerCoordinate: Int?

    /// The bits per component for mesh shadings.
    public let bitsPerComponent: Int?

    /// The bits per flag for free-form and Coons/tensor patch shadings.
    public let bitsPerFlag: Int?

    /// The number of vertices per row for lattice-form mesh shadings.
    public let verticesPerRow: Int?

    // MARK: - Initialization

    /// Creates a validated shading.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the shading.
    ///   - objectKey: The object key.
    ///   - context: Validation context.
    ///   - shadingType: The shading type.
    ///   - colorSpaceName: The color space name.
    ///   - colorComponentCount: Number of color components.
    ///   - hasBBox: Whether a bounding box exists.
    ///   - bBox: The bounding box.
    ///   - hasBackground: Whether a background color exists.
    ///   - hasFunction: Whether a function exists.
    ///   - functionCount: Number of functions.
    ///   - antiAlias: Whether anti-aliasing is enabled.
    ///   - hasDomain: Whether domain values exist.
    ///   - hasCoords: Whether coordinate values exist.
    ///   - extendStart: Whether to extend beyond start.
    ///   - extendEnd: Whether to extend beyond end.
    ///   - bitsPerCoordinate: Bits per coordinate for mesh.
    ///   - bitsPerComponent: Bits per component for mesh.
    ///   - bitsPerFlag: Bits per flag for mesh.
    ///   - verticesPerRow: Vertices per row for lattice mesh.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(location: "Shading"),
        shadingType: ShadingType = .axial,
        colorSpaceName: String? = nil,
        colorComponentCount: Int = 3,
        hasBBox: Bool = false,
        bBox: PDFRect? = nil,
        hasBackground: Bool = false,
        hasFunction: Bool = false,
        functionCount: Int = 0,
        antiAlias: Bool = false,
        hasDomain: Bool = false,
        hasCoords: Bool = false,
        extendStart: Bool = false,
        extendEnd: Bool = false,
        bitsPerCoordinate: Int? = nil,
        bitsPerComponent: Int? = nil,
        bitsPerFlag: Int? = nil,
        verticesPerRow: Int? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.shadingType = shadingType
        self.colorSpaceName = colorSpaceName
        self.colorComponentCount = colorComponentCount
        self.hasBBox = hasBBox
        self.bBox = bBox
        self.hasBackground = hasBackground
        self.hasFunction = hasFunction
        self.functionCount = functionCount
        self.antiAlias = antiAlias
        self.hasDomain = hasDomain
        self.hasCoords = hasCoords
        self.extendStart = extendStart
        self.extendEnd = extendEnd
        self.bitsPerCoordinate = bitsPerCoordinate
        self.bitsPerComponent = bitsPerComponent
        self.bitsPerFlag = bitsPerFlag
        self.verticesPerRow = verticesPerRow
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDShading"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "shadingType", "colorSpaceName", "colorComponentCount",
            "hasBBox", "bBox", "hasBackground",
            "hasFunction", "functionCount", "antiAlias",
            "hasDomain", "hasCoords", "extendStart", "extendEnd",
            "bitsPerCoordinate", "bitsPerComponent", "bitsPerFlag",
            "verticesPerRow",
            "isMesh", "isGradient", "isValid"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "shadingType":
            return .integer(Int64(shadingType.rawValue))
        case "colorSpaceName":
            if let csn = colorSpaceName { return .string(csn) }
            return .null
        case "colorComponentCount":
            return .integer(Int64(colorComponentCount))
        case "hasBBox":
            return .boolean(hasBBox)
        case "bBox":
            if let bb = bBox { return .string(bb.description) }
            return .null
        case "hasBackground":
            return .boolean(hasBackground)
        case "hasFunction":
            return .boolean(hasFunction)
        case "functionCount":
            return .integer(Int64(functionCount))
        case "antiAlias":
            return .boolean(antiAlias)
        case "hasDomain":
            return .boolean(hasDomain)
        case "hasCoords":
            return .boolean(hasCoords)
        case "extendStart":
            return .boolean(extendStart)
        case "extendEnd":
            return .boolean(extendEnd)
        case "bitsPerCoordinate":
            if let bpc = bitsPerCoordinate { return .integer(Int64(bpc)) }
            return .null
        case "bitsPerComponent":
            if let bpc = bitsPerComponent { return .integer(Int64(bpc)) }
            return .null
        case "bitsPerFlag":
            if let bpf = bitsPerFlag { return .integer(Int64(bpf)) }
            return .null
        case "verticesPerRow":
            if let vpr = verticesPerRow { return .integer(Int64(vpr)) }
            return .null
        case "isMesh":
            return .boolean(isMesh)
        case "isGradient":
            return .boolean(isGradient)
        case "isValid":
            return .boolean(isValid)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedShading, rhs: ValidatedShading) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedShading {

    /// Whether this is a mesh-based shading.
    public var isMesh: Bool {
        shadingType.isMesh
    }

    /// Whether this is a gradient shading.
    public var isGradient: Bool {
        shadingType.isGradient
    }

    /// Whether the shading has a valid configuration.
    ///
    /// Validates that required entries are present for the shading type.
    public var isValid: Bool {
        switch shadingType {
        case .functionBased:
            return hasFunction
        case .axial, .radial:
            return hasCoords && hasFunction
        case .freeFormGouraud, .coonsPatch, .tensorProduct:
            return bitsPerCoordinate != nil && bitsPerComponent != nil && bitsPerFlag != nil
        case .latticeFormGouraud:
            return bitsPerCoordinate != nil && bitsPerComponent != nil && verticesPerRow != nil
        case .unknown:
            return false
        }
    }

    /// Whether the color space is device-dependent.
    ///
    /// Device-dependent color spaces (DeviceGray, DeviceRGB, DeviceCMYK)
    /// may need special handling for PDF/A compliance.
    public var usesDeviceDependentColorSpace: Bool {
        guard let cs = colorSpaceName else { return false }
        return cs == "DeviceGray" || cs == "DeviceRGB" || cs == "DeviceCMYK"
    }

    /// Returns a summary string describing the shading.
    public var summary: String {
        var parts: [String] = ["Type \(shadingType.rawValue)"]
        if let csn = colorSpaceName { parts.append(csn) }
        if hasFunction { parts.append("fn(\(functionCount))") }
        if antiAlias { parts.append("AA") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedShading {

    /// Creates an axial shading for testing.
    ///
    /// - Parameter colorSpaceName: The color space name.
    /// - Returns: An axial (linear gradient) shading.
    public static func axial(
        colorSpaceName: String = "DeviceRGB"
    ) -> ValidatedShading {
        ValidatedShading(
            shadingType: .axial,
            colorSpaceName: colorSpaceName,
            colorComponentCount: 3,
            hasFunction: true,
            functionCount: 1,
            hasCoords: true
        )
    }

    /// Creates a radial shading for testing.
    ///
    /// - Parameter colorSpaceName: The color space name.
    /// - Returns: A radial (circular gradient) shading.
    public static func radial(
        colorSpaceName: String = "DeviceRGB"
    ) -> ValidatedShading {
        ValidatedShading(
            shadingType: .radial,
            colorSpaceName: colorSpaceName,
            colorComponentCount: 3,
            hasFunction: true,
            functionCount: 1,
            hasCoords: true
        )
    }

    /// Creates a function-based shading for testing.
    ///
    /// - Parameter colorSpaceName: The color space name.
    /// - Returns: A function-based shading.
    public static func functionBased(
        colorSpaceName: String = "DeviceGray"
    ) -> ValidatedShading {
        ValidatedShading(
            shadingType: .functionBased,
            colorSpaceName: colorSpaceName,
            colorComponentCount: 1,
            hasFunction: true,
            functionCount: 1,
            hasDomain: true
        )
    }
}
