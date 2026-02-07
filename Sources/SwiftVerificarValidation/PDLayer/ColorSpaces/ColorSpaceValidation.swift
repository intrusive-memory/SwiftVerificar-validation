import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Color Space Validation Protocol

/// Base protocol for all color space validation types.
///
/// `ColorSpaceValidation` extends `ValidatedResource` to provide a common interface
/// for validating PDF color spaces. All concrete color space types (DeviceGray,
/// DeviceRGB, DeviceCMYK, ICCBased, CalGray, CalRGB, Indexed, Separation) conform
/// to this protocol.
///
/// ## Key Properties
///
/// - **Color Space Family**: Identifies the color space type (Device, CIE-based, Special)
/// - **Component Count**: The number of color components
/// - **Alternate Space**: The fallback color space, if applicable
///
/// ## Validation Rules
///
/// Color spaces are checked for:
/// - Correct component count for the family
/// - Valid alternate color space chains (no circular references)
/// - ICC profile validity (for ICCBased)
/// - Valid calibration parameters (for Cal* spaces)
/// - PDF/A restrictions on device color spaces
///
/// ## Relationship to veraPDF
///
/// Corresponds to the Java `GFPDColorSpace` abstract class and its subclasses
/// from veraPDF-validation, which provide validation wrappers for all PDF
/// color space types.
///
/// ## Swift Adaptations
///
/// - Protocol instead of abstract class for composition
/// - Default implementations for shared behavior
/// - All conforming types are value types (structs) for thread safety
/// - Sendable conformance for concurrent validation
public protocol ColorSpaceValidation: ValidatedResource {

    /// The color space family identifying the type of color space.
    var colorSpaceFamily: ColorSpaceFamily { get }

    /// The number of color components in this color space.
    ///
    /// For example: DeviceGray = 1, DeviceRGB = 3, DeviceCMYK = 4.
    var componentCount: Int { get }

    /// The alternate color space, if this color space defines one.
    ///
    /// ICCBased, Separation, and DeviceN color spaces can specify an
    /// alternate color space used when the primary cannot be used.
    var alternateColorSpaceName: String? { get }

    /// Whether this color space is device-dependent.
    ///
    /// Device-dependent color spaces (DeviceGray, DeviceRGB, DeviceCMYK)
    /// produce device-specific results and are restricted in PDF/A.
    var isDeviceDependent: Bool { get }

    /// Whether this color space is CIE-based (device-independent).
    ///
    /// CIE-based color spaces (CalGray, CalRGB, Lab, ICCBased) produce
    /// consistent results across devices and are preferred for PDF/A.
    var isCIEBased: Bool { get }

    /// Whether this color space is a special color space.
    ///
    /// Special color spaces (Indexed, Separation, DeviceN, Pattern)
    /// are built on top of other color spaces.
    var isSpecial: Bool { get }
}

// MARK: - Color Space Family

/// Enumeration of PDF color space families.
///
/// Each case corresponds to a color space type as defined in the PDF specification
/// (ISO 32000-1, Section 8.6).
public enum ColorSpaceFamily: String, Sendable, CaseIterable, Equatable {

    /// DeviceGray color space (1 component).
    case deviceGray = "DeviceGray"

    /// DeviceRGB color space (3 components).
    case deviceRGB = "DeviceRGB"

    /// DeviceCMYK color space (4 components).
    case deviceCMYK = "DeviceCMYK"

    /// CalGray calibrated gray color space (1 component).
    case calGray = "CalGray"

    /// CalRGB calibrated RGB color space (3 components).
    case calRGB = "CalRGB"

    /// Lab color space (3 components).
    case lab = "Lab"

    /// ICCBased color space (variable components, 1/3/4).
    case iccBased = "ICCBased"

    /// Indexed color space (1 component, index into a base color space).
    case indexed = "Indexed"

    /// Separation color space (1 component, maps to alternate).
    case separation = "Separation"

    /// DeviceN color space (N components).
    case deviceN = "DeviceN"

    /// Pattern color space.
    case pattern = "Pattern"

    /// Unknown or unrecognized color space family.
    case unknown = "Unknown"

    /// Creates a color space family from a name string.
    ///
    /// - Parameter name: The color space name.
    public init(fromName name: String?) {
        guard let name = name else {
            self = .unknown
            return
        }
        self = ColorSpaceFamily(rawValue: name) ?? .unknown
    }

    /// Creates a color space family from an ASAtom.
    ///
    /// - Parameter atom: The ASAtom to convert.
    public init(fromAtom atom: ASAtom?) {
        self.init(fromName: atom?.stringValue)
    }

    /// Whether this is a device-dependent color space.
    public var isDeviceDependent: Bool {
        switch self {
        case .deviceGray, .deviceRGB, .deviceCMYK:
            return true
        default:
            return false
        }
    }

    /// Whether this is a CIE-based (device-independent) color space.
    public var isCIEBased: Bool {
        switch self {
        case .calGray, .calRGB, .lab, .iccBased:
            return true
        default:
            return false
        }
    }

    /// Whether this is a special color space.
    public var isSpecial: Bool {
        switch self {
        case .indexed, .separation, .deviceN, .pattern:
            return true
        default:
            return false
        }
    }

    /// The standard number of components for this color space family.
    ///
    /// Returns `nil` for variable-component spaces (ICCBased, DeviceN, Pattern).
    public var standardComponentCount: Int? {
        switch self {
        case .deviceGray, .calGray, .indexed, .separation:
            return 1
        case .deviceRGB, .calRGB, .lab:
            return 3
        case .deviceCMYK:
            return 4
        case .iccBased, .deviceN, .pattern, .unknown:
            return nil
        }
    }
}

// MARK: - Default Color Space Validation Implementations

extension ColorSpaceValidation {

    /// Default resource type for color spaces.
    public var resourceType: ResourceType {
        .colorSpace
    }

    /// Default: No alternate color space.
    public var alternateColorSpaceName: String? {
        nil
    }

    /// Default: Derives device-dependent status from family.
    public var isDeviceDependent: Bool {
        colorSpaceFamily.isDeviceDependent
    }

    /// Default: Derives CIE-based status from family.
    public var isCIEBased: Bool {
        colorSpaceFamily.isCIEBased
    }

    /// Default: Derives special status from family.
    public var isSpecial: Bool {
        colorSpaceFamily.isSpecial
    }

    /// Default color space property names.
    public var colorSpacePropertyNames: [String] {
        [
            "colorSpaceFamily", "componentCount", "alternateColorSpaceName",
            "isDeviceDependent", "isCIEBased", "isSpecial"
        ]
    }

    /// Default color space property access.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func colorSpaceProperty(named name: String) -> PropertyValue? {
        switch name {
        case "colorSpaceFamily":
            return .string(colorSpaceFamily.rawValue)
        case "componentCount":
            return .integer(Int64(componentCount))
        case "alternateColorSpaceName":
            if let alt = alternateColorSpaceName {
                return .string(alt)
            }
            return .null
        case "isDeviceDependent":
            return .boolean(isDeviceDependent)
        case "isCIEBased":
            return .boolean(isCIEBased)
        case "isSpecial":
            return .boolean(isSpecial)
        default:
            return nil
        }
    }
}
