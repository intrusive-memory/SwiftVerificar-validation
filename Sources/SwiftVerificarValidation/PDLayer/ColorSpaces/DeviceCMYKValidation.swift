import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - DeviceCMYK Validation

/// Validation wrapper for the DeviceCMYK color space.
///
/// DeviceCMYK is a device-dependent color space with four components
/// representing cyan, magenta, yellow, and black (key) values. Each
/// component ranges from 0.0 to 1.0.
///
/// ## Validation Rules
///
/// DeviceCMYK is checked for:
/// - PDF/A restrictions: Device color spaces must be overridden by a
///   default color space or an output intent in PDF/A documents
/// - Proper usage in content streams (valid operand range 0.0-1.0)
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDDeviceCMYK` from veraPDF-validation.
public struct DeviceCMYKValidation: ColorSpaceValidation, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for this color space.
    ///
    /// DeviceCMYK is a name object, so this is typically `nil`.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    /// The resource name.
    public let resourceName: ASAtom

    // MARK: - Color Space Properties

    /// The color space family. Always `.deviceCMYK`.
    public let colorSpaceFamily: ColorSpaceFamily = .deviceCMYK

    /// The number of components. Always 4.
    public let componentCount: Int = 4

    /// Whether a default CMYK color space is defined in the page resources.
    public let hasDefaultColorSpace: Bool

    /// Whether an output intent overrides this device color space.
    public let hasOutputIntentOverride: Bool

    /// Whether this color space usage is PDF/A compliant.
    ///
    /// A DeviceCMYK usage is PDF/A compliant if either a default CMYK
    /// color space is defined or an output intent covers it.
    public var isPDFACompliant: Bool {
        hasDefaultColorSpace || hasOutputIntentOverride
    }

    // MARK: - Initialization

    /// Creates a DeviceCMYK validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS value (typically nil for DeviceCMYK).
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - hasDefaultColorSpace: Whether a default CMYK color space exists.
    ///   - hasOutputIntentOverride: Whether an output intent covers this space.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("DeviceCMYK"),
        hasDefaultColorSpace: Bool = false,
        hasOutputIntentOverride: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .colorSpace("DeviceCMYK")
        self.resourceName = resourceName
        self.hasDefaultColorSpace = hasDefaultColorSpace
        self.hasOutputIntentOverride = hasOutputIntentOverride
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDDeviceCMYK"
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

    public static func == (lhs: DeviceCMYKValidation, rhs: DeviceCMYKValidation) -> Bool {
        lhs.id == rhs.id
    }
}
