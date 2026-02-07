import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Separation Validation

/// Validation wrapper for the Separation color space.
///
/// Separation is a special color space used for spot colors and custom
/// colorants. It has a single component representing a tint value
/// (0.0 = no colorant, 1.0 = maximum colorant). A tint transformation
/// function maps the tint value to an alternate color space.
///
/// ## Key Properties
///
/// - **Colorant Name**: The name of the colorant (e.g., "PANTONE 185 C", "All", "None")
/// - **Alternate Color Space**: The fallback color space for rendering
/// - **Tint Transform**: The function mapping tint values to alternate space
///
/// ## Validation Rules
///
/// Separation color spaces are checked for:
/// - Valid colorant name (must not be empty)
/// - Valid alternate color space (cannot be Pattern, Indexed, Separation, or DeviceN)
/// - Presence of tint transform function
/// - Special names "All" and "None" require specific handling
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDSeparation` from veraPDF-validation.
public struct SeparationValidation: ColorSpaceValidation, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for this color space (the array definition).
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    /// The resource name.
    public let resourceName: ASAtom

    // MARK: - Color Space Properties

    /// The color space family. Always `.separation`.
    public let colorSpaceFamily: ColorSpaceFamily = .separation

    /// The number of components. Always 1 (the tint value).
    public let componentCount: Int = 1

    // MARK: - Separation Specific Properties

    /// The colorant name identifying the spot color.
    ///
    /// Common values include specific spot color names (e.g., "PANTONE 185 C"),
    /// "All" (applies to all colorants), and "None" (invisible).
    public let colorantName: String?

    /// The alternate color space name used for rendering.
    ///
    /// The alternate space cannot be Pattern, Indexed, Separation, or DeviceN.
    public let alternateColorSpaceName: String?

    /// The number of components in the alternate color space.
    public let alternateComponentCount: Int

    /// Whether the tint transformation function is present.
    public let hasTintTransform: Bool

    /// Whether the colorant name is "All".
    ///
    /// The special name "All" means this separation applies tint to
    /// all colorants simultaneously.
    public var isAllColorant: Bool {
        colorantName == "All"
    }

    /// Whether the colorant name is "None".
    ///
    /// The special name "None" means this separation produces no visible output.
    public var isNoneColorant: Bool {
        colorantName == "None"
    }

    /// Whether the colorant name is valid.
    ///
    /// The colorant name must not be empty.
    public var hasValidColorantName: Bool {
        guard let name = colorantName else { return false }
        return !name.isEmpty
    }

    /// Whether the alternate color space is valid.
    ///
    /// The alternate cannot be Pattern, Indexed, Separation, or DeviceN.
    public var hasValidAlternateColorSpace: Bool {
        guard let name = alternateColorSpaceName else { return false }
        let forbidden: Set<String> = ["Pattern", "Indexed", "Separation", "DeviceN"]
        return !forbidden.contains(name)
    }

    /// Whether the Separation color space definition is valid.
    public var isValid: Bool {
        hasValidColorantName && hasValidAlternateColorSpace && hasTintTransform
    }

    // MARK: - Initialization

    /// Creates a Separation validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS value for the color space definition.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - colorantName: The colorant name.
    ///   - alternateColorSpaceName: The alternate color space name.
    ///   - alternateComponentCount: The alternate space component count.
    ///   - hasTintTransform: Whether the tint transform is present.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("CS0"),
        colorantName: String? = nil,
        alternateColorSpaceName: String? = nil,
        alternateComponentCount: Int = 3,
        hasTintTransform: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .colorSpace("Separation")
        self.resourceName = resourceName
        self.colorantName = colorantName
        self.alternateColorSpaceName = alternateColorSpaceName
        self.alternateComponentCount = alternateComponentCount
        self.hasTintTransform = hasTintTransform
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDSeparation"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = colorSpacePropertyNames
        names.append(contentsOf: [
            "colorantName", "alternateComponentCount", "hasTintTransform",
            "isAllColorant", "isNoneColorant",
            "hasValidColorantName", "hasValidAlternateColorSpace", "isValid"
        ])
        return names
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "colorantName":
            if let cn = colorantName {
                return .string(cn)
            }
            return .null
        case "alternateComponentCount":
            return .integer(Int64(alternateComponentCount))
        case "hasTintTransform":
            return .boolean(hasTintTransform)
        case "isAllColorant":
            return .boolean(isAllColorant)
        case "isNoneColorant":
            return .boolean(isNoneColorant)
        case "hasValidColorantName":
            return .boolean(hasValidColorantName)
        case "hasValidAlternateColorSpace":
            return .boolean(hasValidAlternateColorSpace)
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

    public static func == (lhs: SeparationValidation, rhs: SeparationValidation) -> Bool {
        lhs.id == rhs.id
    }
}
