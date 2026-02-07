import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - CalRGB Validation

/// Validation wrapper for the CalRGB calibrated RGB color space.
///
/// CalRGB is a CIE-based color space with three components representing
/// calibrated red, green, and blue values. It is defined by a white point,
/// an optional black point, per-component gamma values, and a 3x3 matrix.
///
/// ## Key Properties
///
/// - **White Point**: Required tristimulus values for the diffuse white point
/// - **Black Point**: Optional tristimulus values for the diffuse black point
/// - **Gamma**: Per-component gamma exponents `[GR GG GB]`
/// - **Matrix**: A 3x3 transformation matrix (9 values, row-major)
///
/// ## Validation Rules
///
/// CalRGB is checked for:
/// - Presence of required WhitePoint entry
/// - Valid WhitePoint values (Y component must be 1.0, X and Z must be positive)
/// - Valid BlackPoint values (all components must be non-negative)
/// - Valid Gamma values (all must be positive)
/// - Valid Matrix (must contain exactly 9 values)
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDCalRGB` from veraPDF-validation.
public struct CalRGBValidation: ColorSpaceValidation, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for this color space.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    /// The resource name.
    public let resourceName: ASAtom

    // MARK: - Color Space Properties

    /// The color space family. Always `.calRGB`.
    public let colorSpaceFamily: ColorSpaceFamily = .calRGB

    /// The number of components. Always 3.
    public let componentCount: Int = 3

    // MARK: - CalRGB Specific Properties

    /// The white point tristimulus values `[Xw Yw Zw]`.
    ///
    /// Required. `Yw` must be 1.0. `Xw` and `Zw` must be positive.
    public let whitePoint: [Double]?

    /// The black point tristimulus values `[Xb Yb Zb]`.
    ///
    /// Optional. Defaults to `[0.0 0.0 0.0]`. All values must be non-negative.
    public let blackPoint: [Double]?

    /// The per-component gamma exponents `[GR GG GB]`.
    ///
    /// Optional. Defaults to `[1.0 1.0 1.0]`. All values must be positive.
    public let gammaValues: [Double]?

    /// The 3x3 linear transformation matrix (9 values, row-major).
    ///
    /// Optional. Defaults to the identity matrix. Transforms decoded ABC
    /// components to the CIE 1931 XYZ color space.
    public let matrix: [Double]?

    /// Whether the white point is present and valid.
    ///
    /// The white point must have exactly 3 values, Y must be 1.0,
    /// and X and Z must be positive.
    public var hasValidWhitePoint: Bool {
        guard let wp = whitePoint, wp.count == 3 else { return false }
        return wp[1] == 1.0 && wp[0] > 0 && wp[2] > 0
    }

    /// Whether the black point, if present, is valid.
    ///
    /// The black point must have exactly 3 values, all non-negative.
    public var hasValidBlackPoint: Bool {
        guard let bp = blackPoint else { return true }
        guard bp.count == 3 else { return false }
        return bp.allSatisfy { $0 >= 0 }
    }

    /// Whether the gamma values, if present, are valid.
    ///
    /// Gamma values must contain exactly 3 positive values.
    public var hasValidGamma: Bool {
        guard let gv = gammaValues else { return true }
        guard gv.count == 3 else { return false }
        return gv.allSatisfy { $0 > 0 }
    }

    /// Whether the matrix, if present, is valid.
    ///
    /// The matrix must contain exactly 9 values.
    public var hasValidMatrix: Bool {
        guard let m = matrix else { return true }
        return m.count == 9
    }

    /// Whether all CalRGB parameters are valid.
    public var isValid: Bool {
        hasValidWhitePoint && hasValidBlackPoint && hasValidGamma && hasValidMatrix
    }

    // MARK: - Initialization

    /// Creates a CalRGB validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for this color space.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - whitePoint: The white point tristimulus values.
    ///   - blackPoint: The black point tristimulus values.
    ///   - gammaValues: The per-component gamma exponents.
    ///   - matrix: The 3x3 transformation matrix.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("CS0"),
        whitePoint: [Double]? = nil,
        blackPoint: [Double]? = nil,
        gammaValues: [Double]? = nil,
        matrix: [Double]? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .colorSpace("CalRGB")
        self.resourceName = resourceName
        self.whitePoint = whitePoint
        self.blackPoint = blackPoint
        self.gammaValues = gammaValues
        self.matrix = matrix
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDCalRGB"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = colorSpacePropertyNames
        names.append(contentsOf: [
            "hasWhitePoint", "hasBlackPoint", "hasGamma", "hasMatrix",
            "hasValidWhitePoint", "hasValidBlackPoint", "hasValidGamma",
            "hasValidMatrix", "isValid"
        ])
        return names
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "hasWhitePoint":
            return .boolean(whitePoint != nil)
        case "hasBlackPoint":
            return .boolean(blackPoint != nil)
        case "hasGamma":
            return .boolean(gammaValues != nil)
        case "hasMatrix":
            return .boolean(matrix != nil)
        case "hasValidWhitePoint":
            return .boolean(hasValidWhitePoint)
        case "hasValidBlackPoint":
            return .boolean(hasValidBlackPoint)
        case "hasValidGamma":
            return .boolean(hasValidGamma)
        case "hasValidMatrix":
            return .boolean(hasValidMatrix)
        case "isValid":
            return .boolean(isValid)
        default:
            if let csProp = colorSpaceProperty(named: name) {
                return csProp
            }
            return resourceProperty(named: name)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: CalRGBValidation, rhs: CalRGBValidation) -> Bool {
        lhs.id == rhs.id
    }
}
