import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - ICC Profile Validation

/// Validation wrapper for ICC color profiles.
///
/// ICC (International Color Consortium) profiles define the color characteristics
/// of input and output devices, enabling color management across the PDF workflow.
/// This type validates the profile's structure and compliance with PDF specification
/// requirements.
///
/// ## Key Properties
///
/// - **Profile Version**: The ICC specification version (e.g., 2.1.0, 4.3.0)
/// - **Color Space**: The profile's color space signature (GRAY, RGB, CMYK, Lab)
/// - **Component Count**: Number of color components (1, 3, or 4)
/// - **Device Class**: The profile's device class (monitor, printer, scanner)
/// - **Data Integrity**: Whether the profile data is valid and parseable
///
/// ## Validation Rules
///
/// ICC profiles are checked for:
/// - Valid profile header and structure
/// - PDF/A version restrictions on ICC profile versions
/// - Color space and component count consistency
/// - Rendering intent validity
/// - Required tag presence
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFICCProfile`, `GFICCInputProfile`, and `GFICCOutputProfile`
/// from veraPDF-validation. Consolidated into a single struct using the
/// `ICCProfileType` enum to distinguish profile classes.
public struct ICCProfileValidation: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for the ICC profile stream.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    // MARK: - Profile Properties

    /// The ICC profile version string (e.g., "2.1.0", "4.3.0").
    public let profileVersion: String?

    /// The major version number extracted from the profile version string.
    public var majorVersion: Int? {
        guard let version = profileVersion,
              let major = version.split(separator: ".").first,
              let num = Int(major) else { return nil }
        return num
    }

    /// The minor version number extracted from the profile version string.
    public var minorVersion: Int? {
        guard let version = profileVersion else { return nil }
        let parts = version.split(separator: ".")
        guard parts.count >= 2, let num = Int(parts[1]) else { return nil }
        return num
    }

    /// The color space type signature from the ICC profile header.
    ///
    /// Common values: "GRAY", "RGB ", "CMYK", "Lab ".
    public let colorSpace: String?

    /// The number of color components in the profile.
    ///
    /// Determined by the color space: GRAY = 1, RGB = 3, CMYK = 4, Lab = 3.
    public let componentCount: Int

    /// The device class of the ICC profile.
    ///
    /// Common values: "mntr" (monitor), "prtr" (printer), "scnr" (scanner),
    /// "link" (device link), "spac" (color space), "abst" (abstract),
    /// "nmcl" (named color).
    public let deviceClass: String?

    /// The ICC profile type classification.
    public let profileType: ICCProfileType

    /// The rendering intent from the profile header.
    ///
    /// Values: 0 (perceptual), 1 (media-relative colorimetric),
    /// 2 (saturation), 3 (ICC-absolute colorimetric).
    public let renderingIntent: Int?

    /// The size of the profile data in bytes.
    public let dataSize: Int

    /// Whether the profile data is structurally valid.
    ///
    /// Checks that the profile header can be parsed, required fields
    /// are present, and the data is self-consistent.
    public let isValid: Bool

    /// Whether the profile has a valid header signature.
    ///
    /// The ICC profile header must begin with a valid 128-byte header
    /// containing the profile size, CMM type, version, etc.
    public let hasValidHeader: Bool

    /// Whether required ICC profile tags are present.
    ///
    /// Minimum required tags include: profileDescriptionTag,
    /// copyrightTag, mediaWhitePointTag.
    public let hasRequiredTags: Bool

    /// The list of missing required tag names.
    public let missingRequiredTags: [String]

    /// The total number of tags in the profile.
    public let tagCount: Int

    /// The creator signature from the profile header.
    public let creatorSignature: String?

    // MARK: - Computed Properties

    /// Whether the ICC profile version is valid for PDF/A-1.
    ///
    /// PDF/A-1 (ISO 19005-1) requires ICC profile version 2.x or earlier.
    public var isPDFA1Compliant: Bool {
        guard let major = majorVersion else { return false }
        return major <= 2
    }

    /// Whether the ICC profile version is valid for PDF/A-2 and later.
    ///
    /// PDF/A-2+ (ISO 19005-2+) allows ICC profile version 4.x and earlier.
    public var isPDFA2Compliant: Bool {
        guard let major = majorVersion else { return false }
        return major <= 4
    }

    /// Whether the color space matches the component count.
    public var hasConsistentComponents: Bool {
        guard let cs = colorSpace else { return true }
        let trimmed = cs.trimmingCharacters(in: .whitespaces)
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

    /// Whether the rendering intent value is within the valid range (0-3).
    public var hasValidRenderingIntent: Bool {
        guard let intent = renderingIntent else { return true }
        return intent >= 0 && intent <= 3
    }

    /// Whether the profile has non-zero data.
    public var hasData: Bool {
        dataSize > 0
    }

    /// Whether any required tags are missing.
    public var hasMissingTags: Bool {
        !missingRequiredTags.isEmpty
    }

    // MARK: - Initialization

    /// Creates an ICC profile validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the profile stream.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - profileVersion: The ICC profile version string.
    ///   - colorSpace: The color space type signature.
    ///   - componentCount: The number of color components.
    ///   - deviceClass: The device class signature.
    ///   - profileType: The ICC profile type classification.
    ///   - renderingIntent: The rendering intent value.
    ///   - dataSize: The profile data size in bytes.
    ///   - isValid: Whether the profile is structurally valid.
    ///   - hasValidHeader: Whether the header is valid.
    ///   - hasRequiredTags: Whether required tags are present.
    ///   - missingRequiredTags: Missing required tag names.
    ///   - tagCount: Total number of tags.
    ///   - creatorSignature: The profile creator signature.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        profileVersion: String? = nil,
        colorSpace: String? = nil,
        componentCount: Int = 3,
        deviceClass: String? = nil,
        profileType: ICCProfileType = .output,
        renderingIntent: Int? = nil,
        dataSize: Int = 0,
        isValid: Bool = true,
        hasValidHeader: Bool = true,
        hasRequiredTags: Bool = true,
        missingRequiredTags: [String] = [],
        tagCount: Int = 0,
        creatorSignature: String? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? ObjectContext(location: "ICCProfile", role: profileType.rawValue)
        self.profileVersion = profileVersion
        self.colorSpace = colorSpace
        self.componentCount = componentCount
        self.deviceClass = deviceClass
        self.profileType = profileType
        self.renderingIntent = renderingIntent
        self.dataSize = dataSize
        self.isValid = isValid
        self.hasValidHeader = hasValidHeader
        self.hasRequiredTags = hasRequiredTags
        self.missingRequiredTags = missingRequiredTags
        self.tagCount = tagCount
        self.creatorSignature = creatorSignature
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "ICCProfile"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "profileVersion", "majorVersion", "minorVersion",
            "colorSpace", "componentCount", "deviceClass",
            "profileType", "renderingIntent", "dataSize",
            "isValid", "hasValidHeader", "hasRequiredTags",
            "missingRequiredTagCount", "tagCount", "creatorSignature",
            "isPDFA1Compliant", "isPDFA2Compliant",
            "hasConsistentComponents", "hasValidRenderingIntent",
            "hasData", "hasMissingTags"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "profileVersion":
            if let v = profileVersion { return .string(v) }
            return .null
        case "majorVersion":
            if let v = majorVersion { return .integer(Int64(v)) }
            return .null
        case "minorVersion":
            if let v = minorVersion { return .integer(Int64(v)) }
            return .null
        case "colorSpace":
            if let cs = colorSpace { return .string(cs) }
            return .null
        case "componentCount":
            return .integer(Int64(componentCount))
        case "deviceClass":
            if let dc = deviceClass { return .string(dc) }
            return .null
        case "profileType":
            return .string(profileType.rawValue)
        case "renderingIntent":
            if let ri = renderingIntent { return .integer(Int64(ri)) }
            return .null
        case "dataSize":
            return .integer(Int64(dataSize))
        case "isValid":
            return .boolean(isValid)
        case "hasValidHeader":
            return .boolean(hasValidHeader)
        case "hasRequiredTags":
            return .boolean(hasRequiredTags)
        case "missingRequiredTagCount":
            return .integer(Int64(missingRequiredTags.count))
        case "tagCount":
            return .integer(Int64(tagCount))
        case "creatorSignature":
            if let cs = creatorSignature { return .string(cs) }
            return .null
        case "isPDFA1Compliant":
            return .boolean(isPDFA1Compliant)
        case "isPDFA2Compliant":
            return .boolean(isPDFA2Compliant)
        case "hasConsistentComponents":
            return .boolean(hasConsistentComponents)
        case "hasValidRenderingIntent":
            return .boolean(hasValidRenderingIntent)
        case "hasData":
            return .boolean(hasData)
        case "hasMissingTags":
            return .boolean(hasMissingTags)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ICCProfileValidation, rhs: ICCProfileValidation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ICC Profile Type

/// Classification of ICC profile types by device class.
///
/// Identifies the intended use of the ICC profile, which affects
/// validation requirements and PDF/A compliance.
public enum ICCProfileType: String, Sendable, CaseIterable, Equatable {

    /// Input device profile (scanner, camera).
    case input = "Input"

    /// Display device profile (monitor).
    case display = "Display"

    /// Output device profile (printer).
    case output = "Output"

    /// Device link profile (device-to-device transform).
    case deviceLink = "DeviceLink"

    /// Color space conversion profile.
    case colorSpace = "ColorSpace"

    /// Abstract profile.
    case abstract = "Abstract"

    /// Named color profile.
    case namedColor = "NamedColor"

    /// Unknown profile type.
    case unknown = "Unknown"

    /// Creates an ICC profile type from a device class signature.
    ///
    /// - Parameter deviceClass: The 4-character device class signature.
    public init(fromDeviceClass deviceClass: String?) {
        guard let dc = deviceClass else {
            self = .unknown
            return
        }
        switch dc.trimmingCharacters(in: .whitespaces) {
        case "scnr":
            self = .input
        case "mntr":
            self = .display
        case "prtr":
            self = .output
        case "link":
            self = .deviceLink
        case "spac":
            self = .colorSpace
        case "abst":
            self = .abstract
        case "nmcl":
            self = .namedColor
        default:
            self = .unknown
        }
    }

    /// Whether this profile type is valid for use as an output intent profile.
    ///
    /// PDF/A requires output intent profiles to be of type Output or Display.
    public var isValidForOutputIntent: Bool {
        self == .output || self == .display
    }

    /// Whether this profile type can be embedded in a PDF color space.
    public var isEmbeddable: Bool {
        switch self {
        case .input, .display, .output, .colorSpace:
            return true
        case .deviceLink, .abstract, .namedColor, .unknown:
            return false
        }
    }
}

// MARK: - Factory Methods

extension ICCProfileValidation {

    /// Creates a minimal sRGB ICC profile for testing.
    ///
    /// - Parameter dataSize: The profile data size.
    /// - Returns: An sRGB ICC profile.
    public static func sRGBProfile(dataSize: Int = 3144) -> ICCProfileValidation {
        ICCProfileValidation(
            profileVersion: "2.1.0",
            colorSpace: "RGB",
            componentCount: 3,
            deviceClass: "mntr",
            profileType: .display,
            renderingIntent: 1,
            dataSize: dataSize,
            hasRequiredTags: true,
            tagCount: 17
        )
    }

    /// Creates a minimal CMYK ICC profile for testing.
    ///
    /// - Parameter dataSize: The profile data size.
    /// - Returns: A CMYK ICC profile.
    public static func cmykProfile(dataSize: Int = 557168) -> ICCProfileValidation {
        ICCProfileValidation(
            profileVersion: "2.1.0",
            colorSpace: "CMYK",
            componentCount: 4,
            deviceClass: "prtr",
            profileType: .output,
            renderingIntent: 0,
            dataSize: dataSize,
            hasRequiredTags: true,
            tagCount: 12
        )
    }

    /// Creates a minimal gray ICC profile for testing.
    ///
    /// - Parameter dataSize: The profile data size.
    /// - Returns: A gray ICC profile.
    public static func grayProfile(dataSize: Int = 440) -> ICCProfileValidation {
        ICCProfileValidation(
            profileVersion: "2.1.0",
            colorSpace: "GRAY",
            componentCount: 1,
            deviceClass: "mntr",
            profileType: .display,
            renderingIntent: 0,
            dataSize: dataSize,
            hasRequiredTags: true,
            tagCount: 7
        )
    }
}
