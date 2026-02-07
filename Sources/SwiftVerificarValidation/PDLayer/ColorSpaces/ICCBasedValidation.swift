import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - ICCBased Validation

/// Validation wrapper for the ICCBased color space.
///
/// ICCBased color spaces are CIE-based color spaces defined by an embedded
/// ICC (International Color Consortium) profile. They can have 1, 3, or 4
/// components depending on the profile type (gray, RGB, or CMYK).
///
/// ## Key Properties
///
/// - **Component Count**: 1 (gray), 3 (RGB), or 4 (CMYK) from the ICC profile
/// - **Alternate**: A fallback color space used when the ICC profile is unavailable
/// - **ICC Profile Version**: The version of the ICC specification the profile conforms to
/// - **Color Space Type**: The profile's color space signature (Gray, RGB, CMYK, Lab)
///
/// ## Validation Rules
///
/// ICCBased color spaces are checked for:
/// - Valid ICC profile structure and version
/// - Component count matching the profile type
/// - PDF/A version restrictions on ICC profile versions
/// - Proper alternate color space specification
/// - Profile rendering intent validity
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDICCBased` from veraPDF-validation.
public struct ICCBasedValidation: ColorSpaceValidation, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for this color space (the ICC profile stream dictionary).
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    /// The resource name.
    public let resourceName: ASAtom

    // MARK: - Color Space Properties

    /// The color space family. Always `.iccBased`.
    public let colorSpaceFamily: ColorSpaceFamily = .iccBased

    /// The number of components (1, 3, or 4) from the `/N` entry.
    public let componentCount: Int

    /// The alternate color space name.
    ///
    /// If the ICC profile cannot be used, this color space is used instead.
    /// The alternate must have the same number of components.
    public let alternateColorSpaceName: String?

    // MARK: - ICC Profile Properties

    /// The ICC profile version string (e.g., "2.1.0", "4.3.0").
    public let iccProfileVersion: String?

    /// The ICC profile color space type signature.
    ///
    /// Common values: "GRAY", "RGB ", "CMYK", "Lab ".
    public let profileColorSpaceType: String?

    /// The ICC profile device class.
    ///
    /// Common values: "mntr" (monitor), "prtr" (printer), "scnr" (scanner).
    public let profileDeviceClass: String?

    /// Whether the ICC profile is valid.
    public let isProfileValid: Bool

    /// The rendering intent from the ICC profile.
    ///
    /// Values: 0 (perceptual), 1 (media-relative colorimetric),
    /// 2 (saturation), 3 (ICC-absolute colorimetric).
    public let renderingIntent: Int?

    /// The range array for the color space components.
    ///
    /// An array of `2 * N` numbers defining the min/max for each component.
    /// Default ranges are [0.0, 1.0] for each component.
    public let ranges: [Double]

    /// Whether the component count matches the profile type.
    ///
    /// The `/N` entry must agree with the ICC profile's color space type:
    /// GRAY = 1, RGB = 3, CMYK = 4.
    public var hasMatchingComponentCount: Bool {
        guard let profileType = profileColorSpaceType else { return true }
        let trimmed = profileType.trimmingCharacters(in: .whitespaces)
        switch trimmed {
        case "GRAY":
            return componentCount == 1
        case "RGB":
            return componentCount == 3
        case "CMYK":
            return componentCount == 4
        case "Lab":
            return componentCount == 3
        default:
            return true
        }
    }

    /// Whether the ranges array has the correct length.
    ///
    /// The range array should contain `2 * componentCount` values.
    public var hasValidRanges: Bool {
        ranges.isEmpty || ranges.count == componentCount * 2
    }

    /// Whether the ICC profile version is allowed for PDF/A-1.
    ///
    /// PDF/A-1 requires ICC profile version 2.x or earlier.
    public var isPDFA1ProfileVersionValid: Bool {
        guard let version = iccProfileVersion else { return false }
        guard let major = version.split(separator: ".").first,
              let majorNum = Int(major) else { return false }
        return majorNum <= 2
    }

    /// Whether the ICC profile version is allowed for PDF/A-2 and later.
    ///
    /// PDF/A-2+ allows ICC profile version 4.x and earlier.
    public var isPDFA2ProfileVersionValid: Bool {
        guard let version = iccProfileVersion else { return false }
        guard let major = version.split(separator: ".").first,
              let majorNum = Int(major) else { return false }
        return majorNum <= 4
    }

    // MARK: - Initialization

    /// Creates an ICCBased validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the profile stream.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - componentCount: The number of components (1, 3, or 4).
    ///   - alternateColorSpaceName: The alternate color space name.
    ///   - iccProfileVersion: The ICC profile version string.
    ///   - profileColorSpaceType: The profile color space type.
    ///   - profileDeviceClass: The profile device class.
    ///   - isProfileValid: Whether the ICC profile is valid.
    ///   - renderingIntent: The rendering intent.
    ///   - ranges: The range array for components.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("CS0"),
        componentCount: Int = 3,
        alternateColorSpaceName: String? = nil,
        iccProfileVersion: String? = nil,
        profileColorSpaceType: String? = nil,
        profileDeviceClass: String? = nil,
        isProfileValid: Bool = true,
        renderingIntent: Int? = nil,
        ranges: [Double] = []
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .colorSpace("ICCBased")
        self.resourceName = resourceName
        self.componentCount = componentCount
        self.alternateColorSpaceName = alternateColorSpaceName
        self.iccProfileVersion = iccProfileVersion
        self.profileColorSpaceType = profileColorSpaceType
        self.profileDeviceClass = profileDeviceClass
        self.isProfileValid = isProfileValid
        self.renderingIntent = renderingIntent
        self.ranges = ranges
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDICCBased"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = colorSpacePropertyNames
        names.append(contentsOf: [
            "iccProfileVersion", "profileColorSpaceType", "profileDeviceClass",
            "isProfileValid", "renderingIntent", "rangeCount",
            "hasMatchingComponentCount", "hasValidRanges",
            "isPDFA1ProfileVersionValid", "isPDFA2ProfileVersionValid"
        ])
        return names
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "iccProfileVersion":
            if let v = iccProfileVersion {
                return .string(v)
            }
            return .null
        case "profileColorSpaceType":
            if let t = profileColorSpaceType {
                return .string(t)
            }
            return .null
        case "profileDeviceClass":
            if let d = profileDeviceClass {
                return .string(d)
            }
            return .null
        case "isProfileValid":
            return .boolean(isProfileValid)
        case "renderingIntent":
            if let ri = renderingIntent {
                return .integer(Int64(ri))
            }
            return .null
        case "rangeCount":
            return .integer(Int64(ranges.count))
        case "hasMatchingComponentCount":
            return .boolean(hasMatchingComponentCount)
        case "hasValidRanges":
            return .boolean(hasValidRanges)
        case "isPDFA1ProfileVersionValid":
            return .boolean(isPDFA1ProfileVersionValid)
        case "isPDFA2ProfileVersionValid":
            return .boolean(isPDFA2ProfileVersionValid)
        default:
            if let csProp = colorSpaceProperty(named: name) {
                return csProp
            }
            return resourceProperty(named: name)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ICCBasedValidation, rhs: ICCBasedValidation) -> Bool {
        lhs.id == rhs.id
    }
}
