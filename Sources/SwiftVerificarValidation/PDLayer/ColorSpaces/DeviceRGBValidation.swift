import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - DeviceRGB Validation

/// Validation wrapper for the DeviceRGB color space.
///
/// DeviceRGB is a device-dependent color space with three components
/// representing red, green, and blue intensity values. Each component
/// ranges from 0.0 to 1.0.
///
/// ## Validation Rules
///
/// DeviceRGB is checked for:
/// - PDF/A restrictions: Device color spaces must be overridden by a
///   default color space or an output intent in PDF/A documents
/// - Proper usage in content streams (valid operand range 0.0-1.0)
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDDeviceRGB` from veraPDF-validation.
public struct DeviceRGBValidation: ColorSpaceValidation, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for this color space.
    ///
    /// DeviceRGB is a name object, so this is typically `nil`.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    /// The resource name.
    public let resourceName: ASAtom

    // MARK: - Color Space Properties

    /// The color space family. Always `.deviceRGB`.
    public let colorSpaceFamily: ColorSpaceFamily = .deviceRGB

    /// The number of components. Always 3.
    public let componentCount: Int = 3

    /// Whether a default RGB color space is defined in the page resources.
    public let hasDefaultColorSpace: Bool

    /// Whether an output intent overrides this device color space.
    public let hasOutputIntentOverride: Bool

    /// Whether this color space usage is PDF/A compliant.
    ///
    /// A DeviceRGB usage is PDF/A compliant if either a default RGB
    /// color space is defined or an output intent covers it.
    public var isPDFACompliant: Bool {
        hasDefaultColorSpace || hasOutputIntentOverride
    }

    // MARK: - Initialization

    /// Creates a DeviceRGB validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS value (typically nil for DeviceRGB).
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - hasDefaultColorSpace: Whether a default RGB color space exists.
    ///   - hasOutputIntentOverride: Whether an output intent covers this space.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("DeviceRGB"),
        hasDefaultColorSpace: Bool = false,
        hasOutputIntentOverride: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .colorSpace("DeviceRGB")
        self.resourceName = resourceName
        self.hasDefaultColorSpace = hasDefaultColorSpace
        self.hasOutputIntentOverride = hasOutputIntentOverride
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDDeviceRGB"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = colorSpacePropertyNames
        names.append(contentsOf: [
            "hasDefaultColorSpace", "hasOutputIntentOverride", "isPDFACompliant"
        ])
        return names
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "hasDefaultColorSpace":
            return .boolean(hasDefaultColorSpace)
        case "hasOutputIntentOverride":
            return .boolean(hasOutputIntentOverride)
        case "isPDFACompliant":
            return .boolean(isPDFACompliant)
        default:
            if let csProp = colorSpaceProperty(named: name) {
                return csProp
            }
            return resourceProperty(named: name)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: DeviceRGBValidation, rhs: DeviceRGBValidation) -> Bool {
        lhs.id == rhs.id
    }
}
