import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Font Validation Protocol

/// Base protocol for all font validation types.
///
/// `FontValidation` extends `ValidatedResource` to provide a common interface
/// for validating PDF fonts. All concrete font types (Type 0, Type 1, TrueType,
/// CID) conform to this protocol.
///
/// ## Key Properties
///
/// - **Base Font Name**: The PostScript name of the font
/// - **Font Subtype**: The font type (Type0, Type1, TrueType, etc.)
/// - **Encoding**: The font encoding (WinAnsiEncoding, MacRomanEncoding, etc.)
/// - **Font Descriptor**: Metrics and flags for the font
/// - **Embedded**: Whether the font program is embedded
///
/// ## Relationship to veraPDF
///
/// Corresponds to the Java `GFPDFont` abstract class from veraPDF-validation,
/// which provides the base interface for all PD-layer font validation objects.
///
/// ## Swift Adaptations
///
/// - Protocol instead of abstract class for composition
/// - Default implementations for shared behavior
/// - All conforming types are value types (structs) for thread safety
/// - Sendable conformance for concurrent validation
public protocol FontValidation: ValidatedResource {

    /// The font subtype (e.g., Type0, Type1, TrueType, CIDFontType0).
    var fontSubtype: FontSubtype { get }

    /// The base font name (PostScript name) from the `/BaseFont` entry.
    ///
    /// This is the PostScript name of the font, which may differ from
    /// the font's display name. Returns `nil` if the entry is missing.
    var baseFontName: String? { get }

    /// The font encoding name from the `/Encoding` entry.
    ///
    /// For simple fonts this is a name like "WinAnsiEncoding" or a dictionary.
    /// For Type 0 fonts this is the name of a CMap.
    var encodingName: String? { get }

    /// Whether the font has a `/ToUnicode` CMap.
    ///
    /// The ToUnicode CMap maps character codes to Unicode values, enabling
    /// text extraction and accessibility. Its presence is required by many
    /// PDF/A and PDF/UA rules.
    var hasToUnicode: Bool { get }

    /// Whether the font program is embedded in the PDF.
    ///
    /// Embedding is required for PDF/A compliance and strongly recommended
    /// for PDF/UA. A font is considered embedded if the font descriptor
    /// references a FontFile, FontFile2, or FontFile3 stream.
    var isEmbedded: Bool { get }

    /// Whether the font has a font descriptor dictionary.
    var hasFontDescriptor: Bool { get }

    /// The font descriptor flags, if available.
    ///
    /// These flags encode properties like fixed-pitch, serif, symbolic,
    /// script, italic, all-cap, small-cap, etc.
    var fontDescriptorFlags: Int64? { get }

    /// The italic angle from the font descriptor.
    var italicAngle: Double? { get }

    /// The font bounding box from the font descriptor.
    ///
    /// An array of four numbers `[llx lly urx ury]` specifying the font
    /// bounding box in glyph coordinate units.
    var fontBBox: [Double]? { get }

    /// Whether the font is symbolic.
    ///
    /// Symbolic fonts use a custom character set that does not conform to
    /// the Adobe standard Latin character set.
    var isSymbolic: Bool { get }

    /// Whether all glyphs have non-zero widths.
    var hasConsistentWidths: Bool { get }

    /// The font program validation object, if the font is embedded.
    var fontProgram: FontProgramValidation? { get }

    /// The number of glyphs defined in this font.
    var glyphCount: Int { get }

    /// Whether the font has proper Unicode mappings for all used glyphs.
    var hasCompleteUnicodeMappings: Bool { get }
}

// MARK: - Font Subtype

/// Enumeration of PDF font subtypes.
///
/// Each case corresponds to a value of the `/Subtype` entry in a font
/// dictionary, identifying the font format.
public enum FontSubtype: String, Sendable, CaseIterable, Equatable {

    /// Type 0 (composite) font.
    ///
    /// A composite font consisting of a CIDFont and a CMap that maps
    /// character codes to CID values. Used primarily for CJK scripts.
    case type0 = "Type0"

    /// Type 1 font.
    ///
    /// A single-byte font using Adobe Type 1 font technology.
    case type1 = "Type1"

    /// Multiple Master Type 1 font.
    ///
    /// An extension of Type 1 that supports multiple design axes.
    case mmType1 = "MMType1"

    /// Type 3 font.
    ///
    /// A font whose glyphs are defined by PDF content streams.
    case type3 = "Type3"

    /// TrueType font.
    ///
    /// A font using Apple/Microsoft TrueType technology.
    case trueType = "TrueType"

    /// CIDFont Type 0 (CID-keyed Type 1/CFF).
    ///
    /// A CIDFont whose glyph descriptions are based on Type 1 or CFF.
    case cidFontType0 = "CIDFontType0"

    /// CIDFont Type 2 (CID-keyed TrueType).
    ///
    /// A CIDFont whose glyph descriptions are based on TrueType.
    case cidFontType2 = "CIDFontType2"

    /// Unknown or unrecognized font subtype.
    case unknown = "Unknown"

    /// Creates a font subtype from a `/Subtype` entry value.
    ///
    /// - Parameter name: The subtype name from the font dictionary.
    public init(fromName name: String?) {
        guard let name = name else {
            self = .unknown
            return
        }
        self = FontSubtype(rawValue: name) ?? .unknown
    }

    /// Creates a font subtype from an ASAtom.
    ///
    /// - Parameter atom: The ASAtom to convert.
    public init(fromAtom atom: ASAtom?) {
        self.init(fromName: atom?.stringValue)
    }

    /// Whether this is a simple (non-composite) font type.
    public var isSimpleFont: Bool {
        switch self {
        case .type1, .mmType1, .type3, .trueType:
            return true
        default:
            return false
        }
    }

    /// Whether this is a composite font type.
    public var isCompositeFont: Bool {
        self == .type0
    }

    /// Whether this is a CIDFont.
    public var isCIDFont: Bool {
        self == .cidFontType0 || self == .cidFontType2
    }
}

// MARK: - Font Descriptor Flags

/// Constants for font descriptor flags.
///
/// These correspond to the bit flags in the `/Flags` entry of a
/// font descriptor dictionary (PDF Reference Table 5.20).
public struct FontDescriptorFlags: OptionSet, Sendable, Equatable {

    public let rawValue: Int64

    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    /// Fixed-width font (monospaced).
    public static let fixedPitch = FontDescriptorFlags(rawValue: 1 << 0)

    /// Serif font.
    public static let serif = FontDescriptorFlags(rawValue: 1 << 1)

    /// Symbolic font (uses non-standard character set).
    public static let symbolic = FontDescriptorFlags(rawValue: 1 << 2)

    /// Script font (resembles handwriting).
    public static let script = FontDescriptorFlags(rawValue: 1 << 3)

    /// Uses the Adobe standard Latin character set.
    public static let nonsymbolic = FontDescriptorFlags(rawValue: 1 << 5)

    /// Italic or oblique font.
    public static let italic = FontDescriptorFlags(rawValue: 1 << 6)

    /// All-cap font (no lowercase letters).
    public static let allCap = FontDescriptorFlags(rawValue: 1 << 16)

    /// Small-cap font (lowercase rendered as small capitals).
    public static let smallCap = FontDescriptorFlags(rawValue: 1 << 17)

    /// Force bold rendering at small text sizes.
    public static let forceBold = FontDescriptorFlags(rawValue: 1 << 18)
}

// MARK: - Default Font Validation Implementations

extension FontValidation {

    /// Default resource type for fonts.
    public var resourceType: ResourceType {
        .font
    }

    /// Default: Font has no descriptor.
    public var hasFontDescriptor: Bool {
        false
    }

    /// Default: No descriptor flags.
    public var fontDescriptorFlags: Int64? {
        nil
    }

    /// Default: No italic angle.
    public var italicAngle: Double? {
        nil
    }

    /// Default: No bounding box.
    public var fontBBox: [Double]? {
        nil
    }

    /// Default: Not symbolic.
    public var isSymbolic: Bool {
        guard let flags = fontDescriptorFlags else { return false }
        return FontDescriptorFlags(rawValue: flags).contains(.symbolic)
    }

    /// Default: Consistent widths.
    public var hasConsistentWidths: Bool {
        true
    }

    /// Default: No font program.
    public var fontProgram: FontProgramValidation? {
        nil
    }

    /// Default: Zero glyphs.
    public var glyphCount: Int {
        0
    }

    /// Default: Complete mappings.
    public var hasCompleteUnicodeMappings: Bool {
        true
    }

    /// Default font property names.
    public var fontPropertyNames: [String] {
        [
            "fontSubtype", "baseFontName", "encodingName",
            "hasToUnicode", "isEmbedded", "hasFontDescriptor",
            "fontDescriptorFlags", "italicAngle", "isSymbolic",
            "hasConsistentWidths", "glyphCount", "hasCompleteUnicodeMappings"
        ]
    }

    /// Default font property access.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func fontProperty(named name: String) -> PropertyValue? {
        switch name {
        case "fontSubtype":
            return .string(fontSubtype.rawValue)
        case "baseFontName":
            if let name = baseFontName {
                return .string(name)
            }
            return .null
        case "encodingName":
            if let name = encodingName {
                return .string(name)
            }
            return .null
        case "hasToUnicode":
            return .boolean(hasToUnicode)
        case "isEmbedded":
            return .boolean(isEmbedded)
        case "hasFontDescriptor":
            return .boolean(hasFontDescriptor)
        case "fontDescriptorFlags":
            if let flags = fontDescriptorFlags {
                return .integer(flags)
            }
            return .null
        case "italicAngle":
            if let angle = italicAngle {
                return .real(angle)
            }
            return .null
        case "isSymbolic":
            return .boolean(isSymbolic)
        case "hasConsistentWidths":
            return .boolean(hasConsistentWidths)
        case "glyphCount":
            return .integer(Int64(glyphCount))
        case "hasCompleteUnicodeMappings":
            return .boolean(hasCompleteUnicodeMappings)
        default:
            return nil
        }
    }
}
