import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - DeviceGray Validation

/// Validation wrapper for the DeviceGray color space.
///
/// DeviceGray is a device-dependent color space with a single component
/// representing a grayscale intensity value. A value of 0.0 represents
/// black and 1.0 represents white.
///
/// ## Validation Rules
///
/// DeviceGray is checked for:
/// - PDF/A restrictions: Device color spaces must be overridden by a
///   default color space or an output intent in PDF/A documents
/// - Proper usage in content streams (valid operand range 0.0-1.0)
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDDeviceGray` from veraPDF-validation.
public struct DeviceGrayValidation: ColorSpaceValidation, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for this color space.
    ///
    /// DeviceGray is a name object, so this is typically `nil`.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    /// The resource name.
    public let resourceName: ASAtom

    // MARK: - Color Space Properties

    /// The color space family. Always `.deviceGray`.
    public let colorSpaceFamily: ColorSpaceFamily = .deviceGray

    /// The number of components. Always 1.
    public let componentCount: Int = 1

    /// Whether a default gray color space is defined in the page resources.
    ///
    /// PDF/A requires that device color spaces be overridden by either a
    /// default color space or an output intent ICC profile.
    public let hasDefaultColorSpace: Bool

    /// Whether an output intent overrides this device color space.
    public let hasOutputIntentOverride: Bool

    /// Whether this color space usage is PDF/A compliant.
    ///
    /// A DeviceGray usage is PDF/A compliant if either a default gray
    /// color space is defined or an output intent covers it.
    public var isPDFACompliant: Bool {
        hasDefaultColorSpace || hasOutputIntentOverride
    }

    // MARK: - Initialization

    /// Creates a DeviceGray validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS value (typically nil for DeviceGray).
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - hasDefaultColorSpace: Whether a default gray color space exists.
    ///   - hasOutputIntentOverride: Whether an output intent covers this space.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("DeviceGray"),
        hasDefaultColorSpace: Bool = false,
        hasOutputIntentOverride: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .colorSpace("DeviceGray")
        self.resourceName = resourceName
        self.hasDefaultColorSpace = hasDefaultColorSpace
        self.hasOutputIntentOverride = hasOutputIntentOverride
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDDeviceGray"
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

    public static func == (lhs: DeviceGrayValidation, rhs: DeviceGrayValidation) -> Bool {
        lhs.id == rhs.id
    }
}
