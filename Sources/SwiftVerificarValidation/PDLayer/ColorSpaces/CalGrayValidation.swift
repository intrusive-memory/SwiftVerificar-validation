import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - CalGray Validation

/// Validation wrapper for the CalGray calibrated gray color space.
///
/// CalGray is a CIE-based color space with a single component representing
/// a calibrated grayscale value. It is defined by a white point, an optional
/// black point, and a gamma value.
///
/// ## Key Properties
///
/// - **White Point**: Required tristimulus values for the diffuse white point
/// - **Black Point**: Optional tristimulus values for the diffuse black point
/// - **Gamma**: The gamma exponent for the gray component
///
/// ## Validation Rules
///
/// CalGray is checked for:
/// - Presence of required WhitePoint entry
/// - Valid WhitePoint values (Y component must be 1.0, X and Z must be positive)
/// - Valid BlackPoint values (all components must be non-negative)
/// - Valid Gamma value (must be positive)
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDCalGray` from veraPDF-validation.
public struct CalGrayValidation: ColorSpaceValidation, Sendable, Equatable {

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

    /// The color space family. Always `.calGray`.
    public let colorSpaceFamily: ColorSpaceFamily = .calGray

    /// The number of components. Always 1.
    public let componentCount: Int = 1

    // MARK: - CalGray Specific Properties

    /// The white point tristimulus values `[Xw Yw Zw]`.
    ///
    /// Required. `Yw` must be 1.0. `Xw` and `Zw` must be positive.
    public let whitePoint: [Double]?

    /// The black point tristimulus values `[Xb Yb Zb]`.
    ///
    /// Optional. Defaults to `[0.0 0.0 0.0]`. All values must be non-negative.
    public let blackPoint: [Double]?

    /// The gamma exponent for the gray component.
    ///
    /// Optional. Defaults to 1.0. Must be positive.
    public let gamma: Double?

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

    /// Whether the gamma value, if present, is valid.
    ///
    /// Gamma must be positive.
    public var hasValidGamma: Bool {
        guard let g = gamma else { return true }
        return g > 0
    }

    /// Whether all CalGray parameters are valid.
    public var isValid: Bool {
        hasValidWhitePoint && hasValidBlackPoint && hasValidGamma
    }

    // MARK: - Initialization

    /// Creates a CalGray validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for this color space.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - whitePoint: The white point tristimulus values.
    ///   - blackPoint: The black point tristimulus values.
    ///   - gamma: The gamma exponent.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("CS0"),
        whitePoint: [Double]? = nil,
        blackPoint: [Double]? = nil,
        gamma: Double? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .colorSpace("CalGray")
        self.resourceName = resourceName
        self.whitePoint = whitePoint
        self.blackPoint = blackPoint
        self.gamma = gamma
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDCalGray"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = colorSpacePropertyNames
        names.append(contentsOf: [
            "hasWhitePoint", "hasBlackPoint", "gamma",
            "hasValidWhitePoint", "hasValidBlackPoint", "hasValidGamma", "isValid"
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
        case "gamma":
            if let g = gamma {
                return .real(g)
            }
            return .null
        case "hasValidWhitePoint":
            return .boolean(hasValidWhitePoint)
        case "hasValidBlackPoint":
            return .boolean(hasValidBlackPoint)
        case "hasValidGamma":
            return .boolean(hasValidGamma)
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

    public static func == (lhs: CalGrayValidation, rhs: CalGrayValidation) -> Bool {
        lhs.id == rhs.id
    }
}
