import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Color Space Type

/// Types of PDF color spaces for validation.
public enum ColorSpaceType: String, Sendable, CaseIterable {
    /// Device gray (1 component).
    case deviceGray = "DeviceGray"

    /// Device RGB (3 components).
    case deviceRGB = "DeviceRGB"

    /// Device CMYK (4 components).
    case deviceCMYK = "DeviceCMYK"

    /// CalGray (1 component, calibrated).
    case calGray = "CalGray"

    /// CalRGB (3 components, calibrated).
    case calRGB = "CalRGB"

    /// Lab (3 components).
    case lab = "Lab"

    /// ICC-based color space (variable components).
    case iccBased = "ICCBased"

    /// Indexed color space (1 component - index).
    case indexed = "Indexed"

    /// Pattern color space.
    case pattern = "Pattern"

    /// Separation color space (1 component).
    case separation = "Separation"

    /// DeviceN color space (N components).
    case deviceN = "DeviceN"

    /// Unknown color space.
    case unknown = "Unknown"

    /// Creates a color space type from an ASAtom name.
    public init(from name: ASAtom) {
        let str = name.stringValue
        switch str {
        case "DeviceGray", "G": self = .deviceGray
        case "DeviceRGB", "RGB": self = .deviceRGB
        case "DeviceCMYK", "CMYK": self = .deviceCMYK
        case "CalGray": self = .calGray
        case "CalRGB": self = .calRGB
        case "Lab": self = .lab
        case "ICCBased": self = .iccBased
        case "Indexed", "I": self = .indexed
        case "Pattern": self = .pattern
        case "Separation": self = .separation
        case "DeviceN": self = .deviceN
        default: self = .unknown
        }
    }

    /// The expected number of components for this color space, or nil if variable.
    public var expectedComponentCount: Int? {
        switch self {
        case .deviceGray, .calGray, .indexed, .separation:
            return 1
        case .deviceRGB, .calRGB, .lab:
            return 3
        case .deviceCMYK:
            return 4
        case .iccBased, .deviceN, .pattern, .unknown:
            return nil  // Variable or unknown
        }
    }

    /// Whether this is a device color space (not calibrated).
    public var isDeviceColorSpace: Bool {
        switch self {
        case .deviceGray, .deviceRGB, .deviceCMYK:
            return true
        default:
            return false
        }
    }

    /// Whether this is a CIE-based color space.
    public var isCIEBased: Bool {
        switch self {
        case .calGray, .calRGB, .lab, .iccBased:
            return true
        default:
            return false
        }
    }

    /// Whether this is a special color space.
    public var isSpecialColorSpace: Bool {
        switch self {
        case .indexed, .pattern, .separation, .deviceN:
            return true
        default:
            return false
        }
    }
}

// MARK: - Color Validation Result

/// Result of validating a color operator.
public struct ColorValidationResult: Sendable, Equatable {

    /// Whether the validation passed.
    public let isValid: Bool

    /// Any issues found during validation.
    public let issues: [ColorValidationIssue]

    /// The validated color space, if determinable.
    public let colorSpace: ColorSpaceType?

    /// The validated color components.
    public let components: [Double]

    /// Creates a successful validation result.
    public static func success(
        colorSpace: ColorSpaceType,
        components: [Double]
    ) -> ColorValidationResult {
        ColorValidationResult(
            isValid: true,
            issues: [],
            colorSpace: colorSpace,
            components: components
        )
    }

    /// Creates a failed validation result.
    public static func failure(
        issues: [ColorValidationIssue],
        colorSpace: ColorSpaceType? = nil,
        components: [Double] = []
    ) -> ColorValidationResult {
        ColorValidationResult(
            isValid: false,
            issues: issues,
            colorSpace: colorSpace,
            components: components
        )
    }
}

// MARK: - Color Validation Issue

/// An issue found during color operator validation.
public enum ColorValidationIssue: Sendable, Equatable, CustomStringConvertible {

    /// Color component value is out of range [0, 1].
    case componentOutOfRange(index: Int, value: Double, expected: ClosedRange<Double>)

    /// Wrong number of color components for the color space.
    case wrongComponentCount(expected: Int, actual: Int)

    /// Device color space used where not permitted (e.g., PDF/A).
    case deviceColorSpaceNotPermitted(ColorSpaceType)

    /// Color space not set before color operator.
    case colorSpaceNotSet

    /// Invalid color space for the operator.
    case invalidColorSpaceForOperator(operator: String, colorSpace: ColorSpaceType)

    /// Pattern specified without Pattern color space.
    case patternWithoutPatternColorSpace

    /// Unknown color space.
    case unknownColorSpace(name: String)

    public var description: String {
        switch self {
        case .componentOutOfRange(let index, let value, let expected):
            return "Color component \(index) value \(value) out of range \(expected)"
        case .wrongComponentCount(let expected, let actual):
            return "Wrong number of color components: expected \(expected), got \(actual)"
        case .deviceColorSpaceNotPermitted(let cs):
            return "Device color space \(cs.rawValue) not permitted"
        case .colorSpaceNotSet:
            return "Color space not set before color operator"
        case .invalidColorSpaceForOperator(let op, let cs):
            return "Invalid color space \(cs.rawValue) for operator \(op)"
        case .patternWithoutPatternColorSpace:
            return "Pattern name specified without Pattern color space"
        case .unknownColorSpace(let name):
            return "Unknown color space: \(name)"
        }
    }
}

// MARK: - Color Operator Validator

/// Validates color-related operators in PDF content streams.
///
/// This struct provides validation for:
/// - Color component counts matching the color space
/// - Color component values in valid ranges
/// - Proper color space selection
/// - PDF/A compliance for device color spaces
///
/// Corresponds to the Java `GFOp_g_fill`, `GFOp_rg_fill`, etc. classes
/// from veraPDF-validation, consolidated into a single validator.
public struct ColorOperatorValidator: Sendable {

    // MARK: - Configuration

    /// Whether to allow device color spaces (false for PDF/A validation).
    public let allowDeviceColorSpaces: Bool

    /// Whether to validate component ranges strictly.
    public let strictRangeValidation: Bool

    /// ICC profile information for ICC-based color space validation.
    public let iccProfileInfo: ICCProfileInfo?

    // MARK: - Initialization

    /// Creates a color operator validator with default settings.
    public init() {
        self.allowDeviceColorSpaces = true
        self.strictRangeValidation = true
        self.iccProfileInfo = nil
    }

    /// Creates a color operator validator with custom settings.
    public init(
        allowDeviceColorSpaces: Bool,
        strictRangeValidation: Bool = true,
        iccProfileInfo: ICCProfileInfo? = nil
    ) {
        self.allowDeviceColorSpaces = allowDeviceColorSpaces
        self.strictRangeValidation = strictRangeValidation
        self.iccProfileInfo = iccProfileInfo
    }

    // MARK: - Validation

    /// Validates a color operator.
    ///
    /// - Parameters:
    ///   - op: The color operator to validate.
    ///   - context: The current validation context.
    /// - Returns: The validation result.
    public func validate(
        _ op: ValidatedOperator,
        in context: OperatorValidationContext
    ) -> ColorValidationResult {
        switch op {
        case .setGrayStroke(let gray):
            return validateGray(gray, isStroke: true)

        case .setGrayFill(let gray):
            return validateGray(gray, isStroke: false)

        case .setRGBStroke(let r, let g, let b):
            return validateRGB(r: r, g: g, b: b, isStroke: true)

        case .setRGBFill(let r, let g, let b):
            return validateRGB(r: r, g: g, b: b, isStroke: false)

        case .setCMYKStroke(let c, let m, let y, let k):
            return validateCMYK(c: c, m: m, y: y, k: k, isStroke: true)

        case .setCMYKFill(let c, let m, let y, let k):
            return validateCMYK(c: c, m: m, y: y, k: k, isStroke: false)

        case .setColorSpaceStroke(let cs):
            return validateColorSpaceSelection(cs)

        case .setColorSpaceFill(let cs):
            return validateColorSpaceSelection(cs)

        case .setColorStroke(let components):
            return validateColor(
                components,
                colorSpace: context.currentGraphicsState.strokeColorSpace,
                isStroke: true
            )

        case .setColorFill(let components):
            return validateColor(
                components,
                colorSpace: context.currentGraphicsState.fillColorSpace,
                isStroke: false
            )

        case .setColorStrokeN(let components, let pattern):
            return validateColorN(
                components,
                pattern: pattern,
                colorSpace: context.currentGraphicsState.strokeColorSpace,
                isStroke: true
            )

        case .setColorFillN(let components, let pattern):
            return validateColorN(
                components,
                pattern: pattern,
                colorSpace: context.currentGraphicsState.fillColorSpace,
                isStroke: false
            )

        default:
            // Not a color operator
            return .success(colorSpace: .unknown, components: [])
        }
    }

    // MARK: - Private Validation Methods

    /// Validates a gray color value.
    private func validateGray(_ gray: Double, isStroke: Bool) -> ColorValidationResult {
        var issues: [ColorValidationIssue] = []

        // Check device color space permission
        if !allowDeviceColorSpaces {
            issues.append(.deviceColorSpaceNotPermitted(.deviceGray))
        }

        // Validate range
        if strictRangeValidation && (gray < 0.0 || gray > 1.0) {
            issues.append(.componentOutOfRange(index: 0, value: gray, expected: 0.0...1.0))
        }

        if issues.isEmpty {
            return .success(colorSpace: .deviceGray, components: [gray])
        } else {
            return .failure(issues: issues, colorSpace: .deviceGray, components: [gray])
        }
    }

    /// Validates an RGB color value.
    private func validateRGB(r: Double, g: Double, b: Double, isStroke: Bool) -> ColorValidationResult {
        var issues: [ColorValidationIssue] = []

        // Check device color space permission
        if !allowDeviceColorSpaces {
            issues.append(.deviceColorSpaceNotPermitted(.deviceRGB))
        }

        // Validate ranges
        if strictRangeValidation {
            if r < 0.0 || r > 1.0 {
                issues.append(.componentOutOfRange(index: 0, value: r, expected: 0.0...1.0))
            }
            if g < 0.0 || g > 1.0 {
                issues.append(.componentOutOfRange(index: 1, value: g, expected: 0.0...1.0))
            }
            if b < 0.0 || b > 1.0 {
                issues.append(.componentOutOfRange(index: 2, value: b, expected: 0.0...1.0))
            }
        }

        let components = [r, g, b]
        if issues.isEmpty {
            return .success(colorSpace: .deviceRGB, components: components)
        } else {
            return .failure(issues: issues, colorSpace: .deviceRGB, components: components)
        }
    }

    /// Validates a CMYK color value.
    private func validateCMYK(c: Double, m: Double, y: Double, k: Double, isStroke: Bool) -> ColorValidationResult {
        var issues: [ColorValidationIssue] = []

        // Check device color space permission
        if !allowDeviceColorSpaces {
            issues.append(.deviceColorSpaceNotPermitted(.deviceCMYK))
        }

        // Validate ranges
        if strictRangeValidation {
            if c < 0.0 || c > 1.0 {
                issues.append(.componentOutOfRange(index: 0, value: c, expected: 0.0...1.0))
            }
            if m < 0.0 || m > 1.0 {
                issues.append(.componentOutOfRange(index: 1, value: m, expected: 0.0...1.0))
            }
            if y < 0.0 || y > 1.0 {
                issues.append(.componentOutOfRange(index: 2, value: y, expected: 0.0...1.0))
            }
            if k < 0.0 || k > 1.0 {
                issues.append(.componentOutOfRange(index: 3, value: k, expected: 0.0...1.0))
            }
        }

        let components = [c, m, y, k]
        if issues.isEmpty {
            return .success(colorSpace: .deviceCMYK, components: components)
        } else {
            return .failure(issues: issues, colorSpace: .deviceCMYK, components: components)
        }
    }

    /// Validates a color space selection.
    private func validateColorSpaceSelection(_ cs: ASAtom) -> ColorValidationResult {
        let colorSpaceType = ColorSpaceType(from: cs)

        var issues: [ColorValidationIssue] = []

        // Check if device color space is allowed
        if !allowDeviceColorSpaces && colorSpaceType.isDeviceColorSpace {
            issues.append(.deviceColorSpaceNotPermitted(colorSpaceType))
        }

        // Check for unknown color space
        if colorSpaceType == .unknown {
            issues.append(.unknownColorSpace(name: cs.stringValue))
        }

        if issues.isEmpty {
            return .success(colorSpace: colorSpaceType, components: [])
        } else {
            return .failure(issues: issues, colorSpace: colorSpaceType, components: [])
        }
    }

    /// Validates color components against the current color space.
    private func validateColor(
        _ components: [Double],
        colorSpace: ASAtom?,
        isStroke: Bool
    ) -> ColorValidationResult {
        guard let cs = colorSpace else {
            return .failure(issues: [.colorSpaceNotSet])
        }

        let colorSpaceType = ColorSpaceType(from: cs)
        var issues: [ColorValidationIssue] = []

        // Check component count
        if let expected = colorSpaceType.expectedComponentCount {
            if components.count != expected {
                issues.append(.wrongComponentCount(expected: expected, actual: components.count))
            }
        }

        // Validate component ranges
        if strictRangeValidation {
            for (index, value) in components.enumerated() {
                if value < 0.0 || value > 1.0 {
                    issues.append(.componentOutOfRange(index: index, value: value, expected: 0.0...1.0))
                }
            }
        }

        if issues.isEmpty {
            return .success(colorSpace: colorSpaceType, components: components)
        } else {
            return .failure(issues: issues, colorSpace: colorSpaceType, components: components)
        }
    }

    /// Validates color components with optional pattern.
    private func validateColorN(
        _ components: [Double],
        pattern: ASAtom?,
        colorSpace: ASAtom?,
        isStroke: Bool
    ) -> ColorValidationResult {
        // First validate the basic color
        let basicResult = validateColor(components, colorSpace: colorSpace, isStroke: isStroke)

        var issues = basicResult.issues

        // Check pattern consistency
        if pattern != nil {
            let colorSpaceType = colorSpace.map { ColorSpaceType(from: $0) } ?? .unknown
            if colorSpaceType != .pattern && !colorSpaceType.isSpecialColorSpace {
                issues.append(.patternWithoutPatternColorSpace)
            }
        }

        if issues.isEmpty {
            return .success(colorSpace: basicResult.colorSpace ?? .unknown, components: components)
        } else {
            return .failure(issues: issues, colorSpace: basicResult.colorSpace, components: components)
        }
    }

    // MARK: - Utility Methods

    /// Returns the expected component count for a color space name.
    public func expectedComponentCount(for colorSpaceName: ASAtom) -> Int? {
        ColorSpaceType(from: colorSpaceName).expectedComponentCount
    }

    /// Validates that color components are within the valid range.
    public func validateComponentRanges(
        _ components: [Double],
        range: ClosedRange<Double> = 0.0...1.0
    ) -> [ColorValidationIssue] {
        var issues: [ColorValidationIssue] = []
        for (index, value) in components.enumerated() {
            if !range.contains(value) {
                issues.append(.componentOutOfRange(index: index, value: value, expected: range))
            }
        }
        return issues
    }
}

// MARK: - ICC Profile Info

/// Information about an ICC profile for validation.
public struct ICCProfileInfo: Sendable, Equatable {

    /// The ICC profile version.
    public let version: String

    /// The color space signature (e.g., "RGB ", "CMYK", "GRAY").
    public let colorSpaceSignature: String

    /// The number of color components.
    public let componentCount: Int

    /// The profile class (e.g., input, display, output).
    public let profileClass: String

    /// Creates ICC profile info.
    public init(
        version: String,
        colorSpaceSignature: String,
        componentCount: Int,
        profileClass: String
    ) {
        self.version = version
        self.colorSpaceSignature = colorSpaceSignature
        self.componentCount = componentCount
        self.profileClass = profileClass
    }

    /// Whether this is an output profile.
    public var isOutputProfile: Bool {
        profileClass == "output" || profileClass == "prtr"
    }

    /// The color space type corresponding to this profile.
    public var colorSpaceType: ColorSpaceType {
        switch colorSpaceSignature.trimmingCharacters(in: .whitespaces).uppercased() {
        case "RGB": return .deviceRGB
        case "CMYK": return .deviceCMYK
        case "GRAY": return .deviceGray
        case "LAB": return .lab
        default: return .iccBased
        }
    }
}

// MARK: - PDF/A Color Validator

/// Extended color validator for PDF/A compliance.
public struct PDFAColorValidator: Sendable {

    /// The base color validator.
    private let baseValidator: ColorOperatorValidator

    /// The PDF/A conformance level.
    public let conformanceLevel: PDFAColorConformance

    /// Creates a PDF/A color validator.
    public init(conformanceLevel: PDFAColorConformance) {
        self.conformanceLevel = conformanceLevel
        self.baseValidator = ColorOperatorValidator(
            allowDeviceColorSpaces: conformanceLevel.allowsDeviceColorSpaces,
            strictRangeValidation: true,
            iccProfileInfo: nil
        )
    }

    /// Validates a color operator for PDF/A compliance.
    public func validate(
        _ op: ValidatedOperator,
        in context: OperatorValidationContext
    ) -> ColorValidationResult {
        // Use base validator
        let result = baseValidator.validate(op, in: context)

        // Add PDF/A-specific checks
        var issues = result.issues

        // Check for device color spaces in PDF/A
        if let colorSpace = result.colorSpace,
           colorSpace.isDeviceColorSpace,
           !conformanceLevel.allowsDeviceColorSpaces {
            issues.append(.deviceColorSpaceNotPermitted(colorSpace))
        }

        if issues.isEmpty {
            return result
        } else {
            return .failure(issues: issues, colorSpace: result.colorSpace, components: result.components)
        }
    }
}

// MARK: - PDF/A Color Conformance

/// PDF/A conformance levels for color validation.
public enum PDFAColorConformance: String, Sendable, CaseIterable {
    case pdfa1a = "PDF/A-1a"
    case pdfa1b = "PDF/A-1b"
    case pdfa2a = "PDF/A-2a"
    case pdfa2b = "PDF/A-2b"
    case pdfa2u = "PDF/A-2u"
    case pdfa3a = "PDF/A-3a"
    case pdfa3b = "PDF/A-3b"
    case pdfa3u = "PDF/A-3u"
    case pdfa4 = "PDF/A-4"

    /// Whether device color spaces are allowed without an output intent.
    public var allowsDeviceColorSpaces: Bool {
        // PDF/A generally requires device-independent color or output intent
        false
    }

    /// Whether uncalibrated color spaces are allowed.
    public var allowsUncalibratedColor: Bool {
        // Only allowed with an output intent
        false
    }
}
