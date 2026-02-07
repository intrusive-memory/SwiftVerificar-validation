import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - JPEG 2000 Validation

/// Validation wrapper for JPEG 2000 images embedded in PDF documents.
///
/// JPEG 2000 (JPX) is an image compression format defined in ISO/IEC 15444.
/// PDF 1.5+ supports JPEG 2000 via the `/JPXDecode` filter. This type validates
/// the JPEG 2000 image properties for compliance with PDF specification requirements
/// and PDF/A restrictions.
///
/// ## Key Properties
///
/// - **Compression**: Lossy or lossless compression type
/// - **Color Space**: The image's color space within the JPEG 2000 codestream
/// - **Bit Depth**: Bits per component per channel
/// - **Resolution**: Image dimensions and resolution information
/// - **Tile Structure**: Tile dimensions and count
///
/// ## Validation Rules
///
/// JPEG 2000 images are checked for:
/// - Valid codestream structure
/// - PDF/A restrictions on JPEG 2000 features
/// - Color space consistency between JPEG 2000 header and PDF color space
/// - Bit depth validity and component count
/// - Number of resolution levels
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFJPEG2000` from veraPDF-validation.
public struct JPEG2000Validation: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for the JPEG 2000 image stream.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    // MARK: - Image Properties

    /// The width of the image in pixels.
    public let width: Int

    /// The height of the image in pixels.
    public let height: Int

    /// The number of color components in the image.
    public let componentCount: Int

    /// The bits per component (bit depth) for each channel.
    public let bitsPerComponent: Int

    /// The compression type used.
    public let compressionType: JPEG2000CompressionType

    /// The color space type from the JPEG 2000 codestream.
    public let colorSpaceType: JPEG2000ColorSpace

    // MARK: - JPEG 2000 Specific Properties

    /// The number of resolution levels in the codestream.
    ///
    /// More resolution levels enable progressive rendering. PDF/A
    /// has no specific restriction on the number of levels.
    public let resolutionLevels: Int

    /// The number of quality layers in the codestream.
    ///
    /// Quality layers enable progressive quality improvement during decoding.
    public let qualityLayers: Int

    /// The tile width in pixels.
    ///
    /// A value of 0 indicates a single tile covering the entire image.
    public let tileWidth: Int

    /// The tile height in pixels.
    ///
    /// A value of 0 indicates a single tile covering the entire image.
    public let tileHeight: Int

    /// The total number of tiles in the image.
    public let tileCount: Int

    /// Whether the JPEG 2000 codestream is valid and parseable.
    public let isValid: Bool

    /// Whether the JPEG 2000 data contains a valid SOC (Start of Codestream) marker.
    public let hasValidSOCMarker: Bool

    /// Whether the image uses the JPEG 2000 Part 2 (JPX) extended format.
    ///
    /// PDF/A-1 restricts the use of JPEG 2000 Part 2 extensions.
    public let usesJPXExtensions: Bool

    /// Whether the codestream contains a color specification box.
    public let hasColorSpecBox: Bool

    /// The enumerated color space value from the color specification box.
    ///
    /// 16 = sRGB, 17 = Greyscale, 18 = sYCC, 12 = CMYK, etc.
    public let enumeratedColorSpace: Int?

    /// Whether the JPEG 2000 stream has an ICC profile embedded.
    public let hasEmbeddedICCProfile: Bool

    // MARK: - Computed Properties

    /// The total number of pixels in the image.
    public var pixelCount: Int {
        width * height
    }

    /// Whether the image is single-tiled.
    public var isSingleTiled: Bool {
        tileCount <= 1
    }

    /// Whether the image has valid dimensions.
    public var hasValidDimensions: Bool {
        width > 0 && height > 0
    }

    /// Whether the bit depth is valid (1-38 bits per component per ISO 15444-1).
    public var hasValidBitDepth: Bool {
        bitsPerComponent >= 1 && bitsPerComponent <= 38
    }

    /// Whether the image is compliant with PDF/A-1.
    ///
    /// PDF/A-1 requires:
    /// - No JPX extensions (Part 1 only)
    /// - Valid codestream structure
    public var isPDFA1Compliant: Bool {
        isValid && !usesJPXExtensions && hasValidSOCMarker
    }

    /// Whether the image is compliant with PDF/A-2 and later.
    ///
    /// PDF/A-2+ is more permissive with JPEG 2000 but still requires
    /// a valid codestream.
    public var isPDFA2Compliant: Bool {
        isValid && hasValidSOCMarker
    }

    /// Whether the bit depth and component count are consistent.
    public var hasConsistentBitDepth: Bool {
        bitsPerComponent > 0 && componentCount > 0
    }

    // MARK: - Initialization

    /// Creates a JPEG 2000 validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the image stream.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - width: The image width in pixels.
    ///   - height: The image height in pixels.
    ///   - componentCount: The number of color components.
    ///   - bitsPerComponent: The bits per component.
    ///   - compressionType: The compression type.
    ///   - colorSpaceType: The JPEG 2000 color space type.
    ///   - resolutionLevels: The number of resolution levels.
    ///   - qualityLayers: The number of quality layers.
    ///   - tileWidth: The tile width in pixels.
    ///   - tileHeight: The tile height in pixels.
    ///   - tileCount: The total number of tiles.
    ///   - isValid: Whether the codestream is valid.
    ///   - hasValidSOCMarker: Whether the SOC marker is valid.
    ///   - usesJPXExtensions: Whether JPX extensions are used.
    ///   - hasColorSpecBox: Whether a color specification box exists.
    ///   - enumeratedColorSpace: The enumerated color space value.
    ///   - hasEmbeddedICCProfile: Whether an ICC profile is embedded.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        width: Int = 0,
        height: Int = 0,
        componentCount: Int = 3,
        bitsPerComponent: Int = 8,
        compressionType: JPEG2000CompressionType = .lossy,
        colorSpaceType: JPEG2000ColorSpace = .sRGB,
        resolutionLevels: Int = 5,
        qualityLayers: Int = 1,
        tileWidth: Int = 0,
        tileHeight: Int = 0,
        tileCount: Int = 1,
        isValid: Bool = true,
        hasValidSOCMarker: Bool = true,
        usesJPXExtensions: Bool = false,
        hasColorSpecBox: Bool = true,
        enumeratedColorSpace: Int? = nil,
        hasEmbeddedICCProfile: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? ObjectContext(location: "JPEG2000", role: "Image")
        self.width = width
        self.height = height
        self.componentCount = componentCount
        self.bitsPerComponent = bitsPerComponent
        self.compressionType = compressionType
        self.colorSpaceType = colorSpaceType
        self.resolutionLevels = resolutionLevels
        self.qualityLayers = qualityLayers
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.tileCount = tileCount
        self.isValid = isValid
        self.hasValidSOCMarker = hasValidSOCMarker
        self.usesJPXExtensions = usesJPXExtensions
        self.hasColorSpecBox = hasColorSpecBox
        self.enumeratedColorSpace = enumeratedColorSpace
        self.hasEmbeddedICCProfile = hasEmbeddedICCProfile
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "JPEG2000"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "width", "height", "componentCount", "bitsPerComponent",
            "compressionType", "colorSpaceType",
            "resolutionLevels", "qualityLayers",
            "tileWidth", "tileHeight", "tileCount",
            "isValid", "hasValidSOCMarker", "usesJPXExtensions",
            "hasColorSpecBox", "enumeratedColorSpace", "hasEmbeddedICCProfile",
            "pixelCount", "isSingleTiled", "hasValidDimensions",
            "hasValidBitDepth", "isPDFA1Compliant", "isPDFA2Compliant",
            "hasConsistentBitDepth"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "width":
            return .integer(Int64(width))
        case "height":
            return .integer(Int64(height))
        case "componentCount":
            return .integer(Int64(componentCount))
        case "bitsPerComponent":
            return .integer(Int64(bitsPerComponent))
        case "compressionType":
            return .string(compressionType.rawValue)
        case "colorSpaceType":
            return .string(colorSpaceType.rawValue)
        case "resolutionLevels":
            return .integer(Int64(resolutionLevels))
        case "qualityLayers":
            return .integer(Int64(qualityLayers))
        case "tileWidth":
            return .integer(Int64(tileWidth))
        case "tileHeight":
            return .integer(Int64(tileHeight))
        case "tileCount":
            return .integer(Int64(tileCount))
        case "isValid":
            return .boolean(isValid)
        case "hasValidSOCMarker":
            return .boolean(hasValidSOCMarker)
        case "usesJPXExtensions":
            return .boolean(usesJPXExtensions)
        case "hasColorSpecBox":
            return .boolean(hasColorSpecBox)
        case "enumeratedColorSpace":
            if let ecs = enumeratedColorSpace { return .integer(Int64(ecs)) }
            return .null
        case "hasEmbeddedICCProfile":
            return .boolean(hasEmbeddedICCProfile)
        case "pixelCount":
            return .integer(Int64(pixelCount))
        case "isSingleTiled":
            return .boolean(isSingleTiled)
        case "hasValidDimensions":
            return .boolean(hasValidDimensions)
        case "hasValidBitDepth":
            return .boolean(hasValidBitDepth)
        case "isPDFA1Compliant":
            return .boolean(isPDFA1Compliant)
        case "isPDFA2Compliant":
            return .boolean(isPDFA2Compliant)
        case "hasConsistentBitDepth":
            return .boolean(hasConsistentBitDepth)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: JPEG2000Validation, rhs: JPEG2000Validation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - JPEG 2000 Compression Type

/// The compression type used in a JPEG 2000 image.
public enum JPEG2000CompressionType: String, Sendable, CaseIterable, Equatable {

    /// Lossy compression (irreversible).
    ///
    /// Uses the 9-7 irreversible wavelet transform (CDF 9/7).
    case lossy = "Lossy"

    /// Lossless compression (reversible).
    ///
    /// Uses the 5-3 reversible wavelet transform (LeGall 5/3).
    case lossless = "Lossless"

    /// Unknown compression type.
    case unknown = "Unknown"

    /// Whether this is a lossless compression type.
    public var isLossless: Bool {
        self == .lossless
    }
}

// MARK: - JPEG 2000 Color Space

/// Color space types used in JPEG 2000 codestreams.
///
/// These correspond to the enumerated color space values in the
/// JPEG 2000 color specification box (colr).
public enum JPEG2000ColorSpace: String, Sendable, CaseIterable, Equatable {

    /// sRGB color space (enumerated CS = 16).
    case sRGB = "sRGB"

    /// Greyscale color space (enumerated CS = 17).
    case greyscale = "Greyscale"

    /// sYCC color space (enumerated CS = 18).
    case sYCC = "sYCC"

    /// CMYK color space (enumerated CS = 12).
    case cmyk = "CMYK"

    /// CIELab color space (enumerated CS = 14).
    case cieLab = "CIELab"

    /// ICC profile-based color space.
    case iccProfile = "ICCProfile"

    /// Unknown color space.
    case unknown = "Unknown"

    /// Creates a color space from the enumerated color space value.
    ///
    /// - Parameter enumeratedValue: The enumerated CS value from the colr box.
    public init(fromEnumerated enumeratedValue: Int?) {
        guard let value = enumeratedValue else {
            self = .unknown
            return
        }
        switch value {
        case 16:
            self = .sRGB
        case 17:
            self = .greyscale
        case 18:
            self = .sYCC
        case 12:
            self = .cmyk
        case 14:
            self = .cieLab
        default:
            self = .unknown
        }
    }

    /// The standard number of components for this color space.
    public var standardComponentCount: Int? {
        switch self {
        case .greyscale:
            return 1
        case .sRGB, .sYCC, .cieLab:
            return 3
        case .cmyk:
            return 4
        case .iccProfile, .unknown:
            return nil
        }
    }
}

// MARK: - Factory Methods

extension JPEG2000Validation {

    /// Creates a minimal valid JPEG 2000 image for testing.
    ///
    /// - Parameters:
    ///   - width: The image width.
    ///   - height: The image height.
    /// - Returns: A valid JPEG 2000 validation object.
    public static func validImage(width: Int = 800, height: Int = 600) -> JPEG2000Validation {
        JPEG2000Validation(
            width: width,
            height: height,
            componentCount: 3,
            bitsPerComponent: 8,
            compressionType: .lossy,
            colorSpaceType: .sRGB,
            resolutionLevels: 5,
            qualityLayers: 1,
            tileCount: 1,
            isValid: true,
            hasValidSOCMarker: true,
            hasColorSpecBox: true,
            enumeratedColorSpace: 16
        )
    }

    /// Creates a lossless grayscale JPEG 2000 image for testing.
    ///
    /// - Parameters:
    ///   - width: The image width.
    ///   - height: The image height.
    /// - Returns: A lossless grayscale JPEG 2000 validation object.
    public static func losslessGray(width: Int = 256, height: Int = 256) -> JPEG2000Validation {
        JPEG2000Validation(
            width: width,
            height: height,
            componentCount: 1,
            bitsPerComponent: 8,
            compressionType: .lossless,
            colorSpaceType: .greyscale,
            resolutionLevels: 3,
            qualityLayers: 1,
            tileCount: 1,
            isValid: true,
            hasValidSOCMarker: true,
            hasColorSpecBox: true,
            enumeratedColorSpace: 17
        )
    }
}
