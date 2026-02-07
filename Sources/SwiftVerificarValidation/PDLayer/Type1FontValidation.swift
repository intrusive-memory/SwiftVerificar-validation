import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Type 1 Font Validation

/// Validation wrapper for a Type 1 font.
///
/// Type 1 fonts are single-byte fonts using Adobe Type 1 font technology.
/// They can encode up to 256 glyphs and are one of the most common font
/// types in older PDF documents.
///
/// ## Key Properties
///
/// - **Encoding**: The character encoding (WinAnsi, MacRoman, or custom)
/// - **Widths**: Per-glyph width values for text layout validation
/// - **First/Last Char**: Range of encoded character codes
/// - **Font Descriptor**: Contains metrics and embedding info
///
/// ## Validation Rules
///
/// Type 1 fonts are checked for:
/// - Embedding of the font program (required for PDF/A)
/// - Consistent widths between font dictionary and font program
/// - Proper encoding specification
/// - ToUnicode CMap for text extraction
/// - Valid character code range (FirstChar/LastChar)
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDType1Font` from veraPDF-validation. Also covers
/// MMType1 (Multiple Master) fonts which have identical validation logic.
public struct Type1FontValidation: FontValidation, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the font.
    public let cosDictionary: COSValue?

    /// The object key for the font, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    /// The resource name of this font in the Resources dictionary.
    public let resourceName: ASAtom

    // MARK: - Font Properties

    /// The font subtype (`.type1` or `.mmType1`).
    public let fontSubtype: FontSubtype

    /// The base font name from the `/BaseFont` entry.
    public let baseFontName: String?

    /// The encoding name from the `/Encoding` entry.
    ///
    /// Common values: "WinAnsiEncoding", "MacRomanEncoding",
    /// "MacExpertEncoding", or a custom encoding dictionary.
    public let encodingName: String?

    /// Whether the font has a `/ToUnicode` CMap.
    public let hasToUnicode: Bool

    /// Whether the font program is embedded.
    public let isEmbedded: Bool

    /// Whether the font has a font descriptor.
    public let hasFontDescriptor: Bool

    /// The font descriptor flags.
    public let fontDescriptorFlags: Int64?

    /// The italic angle.
    public let italicAngle: Double?

    /// The font bounding box.
    public let fontBBox: [Double]?

    /// Whether all glyphs have non-zero widths.
    public let hasConsistentWidths: Bool

    /// The font program, if embedded.
    public let fontProgram: FontProgramValidation?

    /// The number of glyphs.
    public let glyphCount: Int

    /// Whether all used glyphs have Unicode mappings.
    public let hasCompleteUnicodeMappings: Bool

    // MARK: - Type 1 Specific Properties

    /// The first character code defined in the `/Widths` array.
    ///
    /// This is the value of the `/FirstChar` entry. Character codes
    /// are in the range 0-255.
    public let firstChar: Int?

    /// The last character code defined in the `/Widths` array.
    ///
    /// This is the value of the `/LastChar` entry. Character codes
    /// are in the range 0-255.
    public let lastChar: Int?

    /// The per-glyph widths array.
    ///
    /// Contains `(lastChar - firstChar + 1)` width values corresponding
    /// to character codes from `firstChar` to `lastChar`.
    public let widths: [Double]

    /// Whether the font is one of the 14 standard Type 1 fonts.
    ///
    /// The standard 14 fonts (Times, Helvetica, Courier, Symbol, ZapfDingbats
    /// and their variants) may be used without embedding in older PDF versions,
    /// but must be embedded for PDF/A compliance.
    public let isStandard14: Bool

    /// Whether the encoding is a differences encoding.
    ///
    /// A differences encoding modifies a base encoding by remapping
    /// specific character codes.
    public let hasDifferencesEncoding: Bool

    /// The number of encoding differences, if using a differences encoding.
    public let differencesCount: Int

    /// Whether the font has a valid character code range.
    ///
    /// Returns `true` if `firstChar` and `lastChar` are both present
    /// and `firstChar <= lastChar`.
    public var hasValidCharRange: Bool {
        guard let first = firstChar, let last = lastChar else { return false }
        return first <= last && first >= 0 && last <= 255
    }

    /// Whether the widths array length matches the character code range.
    public var hasMatchingWidths: Bool {
        guard let first = firstChar, let last = lastChar else {
            return widths.isEmpty
        }
        let expectedCount = last - first + 1
        return widths.count == expectedCount
    }

    /// Whether this is a Multiple Master Type 1 font.
    public var isMultipleMaster: Bool {
        fontSubtype == .mmType1
    }

    // MARK: - Initialization

    /// Creates a Type 1 font validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the font.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - fontSubtype: The font subtype (`.type1` or `.mmType1`).
    ///   - baseFontName: The base font name.
    ///   - encodingName: The encoding name.
    ///   - hasToUnicode: Whether the font has a ToUnicode CMap.
    ///   - isEmbedded: Whether the font program is embedded.
    ///   - hasFontDescriptor: Whether the font has a descriptor.
    ///   - fontDescriptorFlags: The descriptor flags.
    ///   - italicAngle: The italic angle.
    ///   - fontBBox: The font bounding box.
    ///   - hasConsistentWidths: Whether widths are consistent.
    ///   - fontProgram: The font program validation object.
    ///   - glyphCount: The number of glyphs.
    ///   - hasCompleteUnicodeMappings: Whether Unicode mappings are complete.
    ///   - firstChar: The first character code.
    ///   - lastChar: The last character code.
    ///   - widths: The per-glyph widths array.
    ///   - isStandard14: Whether this is a standard 14 font.
    ///   - hasDifferencesEncoding: Whether the encoding has differences.
    ///   - differencesCount: The number of encoding differences.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("F0"),
        fontSubtype: FontSubtype = .type1,
        baseFontName: String? = nil,
        encodingName: String? = nil,
        hasToUnicode: Bool = false,
        isEmbedded: Bool = false,
        hasFontDescriptor: Bool = false,
        fontDescriptorFlags: Int64? = nil,
        italicAngle: Double? = nil,
        fontBBox: [Double]? = nil,
        hasConsistentWidths: Bool = true,
        fontProgram: FontProgramValidation? = nil,
        glyphCount: Int = 0,
        hasCompleteUnicodeMappings: Bool = true,
        firstChar: Int? = nil,
        lastChar: Int? = nil,
        widths: [Double] = [],
        isStandard14: Bool = false,
        hasDifferencesEncoding: Bool = false,
        differencesCount: Int = 0
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .font(baseFontName ?? resourceName.stringValue)
        self.resourceName = resourceName
        self.fontSubtype = fontSubtype
        self.baseFontName = baseFontName
        self.encodingName = encodingName
        self.hasToUnicode = hasToUnicode
        self.isEmbedded = isEmbedded
        self.hasFontDescriptor = hasFontDescriptor
        self.fontDescriptorFlags = fontDescriptorFlags
        self.italicAngle = italicAngle
        self.fontBBox = fontBBox
        self.hasConsistentWidths = hasConsistentWidths
        self.fontProgram = fontProgram
        self.glyphCount = glyphCount
        self.hasCompleteUnicodeMappings = hasCompleteUnicodeMappings
        self.firstChar = firstChar
        self.lastChar = lastChar
        self.widths = widths
        self.isStandard14 = isStandard14
        self.hasDifferencesEncoding = hasDifferencesEncoding
        self.differencesCount = differencesCount
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDType1Font"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = fontPropertyNames
        names.append(contentsOf: [
            "firstChar", "lastChar", "widthsCount",
            "isStandard14", "hasDifferencesEncoding", "differencesCount",
            "hasValidCharRange", "hasMatchingWidths", "isMultipleMaster"
        ])
        return names
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "firstChar":
            if let fc = firstChar {
                return .integer(Int64(fc))
            }
            return .null
        case "lastChar":
            if let lc = lastChar {
                return .integer(Int64(lc))
            }
            return .null
        case "widthsCount":
            return .integer(Int64(widths.count))
        case "isStandard14":
            return .boolean(isStandard14)
        case "hasDifferencesEncoding":
            return .boolean(hasDifferencesEncoding)
        case "differencesCount":
            return .integer(Int64(differencesCount))
        case "hasValidCharRange":
            return .boolean(hasValidCharRange)
        case "hasMatchingWidths":
            return .boolean(hasMatchingWidths)
        case "isMultipleMaster":
            return .boolean(isMultipleMaster)
        default:
            if let fontProp = fontProperty(named: name) {
                return fontProp
            }
            return resourceProperty(named: name)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: Type1FontValidation, rhs: Type1FontValidation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Standard 14 Fonts

extension Type1FontValidation {

    /// The list of standard 14 Type 1 font names.
    ///
    /// These fonts may be referenced by name without embedding in pre-PDF/A
    /// documents. PDF viewers are expected to have built-in substitutes.
    public static let standard14FontNames: Set<String> = [
        "Courier",
        "Courier-Bold",
        "Courier-BoldOblique",
        "Courier-Oblique",
        "Helvetica",
        "Helvetica-Bold",
        "Helvetica-BoldOblique",
        "Helvetica-Oblique",
        "Symbol",
        "Times-Bold",
        "Times-BoldItalic",
        "Times-Italic",
        "Times-Roman",
        "ZapfDingbats"
    ]

    /// Whether a given font name is a standard 14 font.
    ///
    /// - Parameter name: The base font name.
    /// - Returns: `true` if the name matches a standard 14 font.
    public static func isStandard14(name: String) -> Bool {
        standard14FontNames.contains(name)
    }
}

// MARK: - Factory Methods

extension Type1FontValidation {

    /// Creates a minimal Type 1 font for testing.
    ///
    /// - Parameters:
    ///   - name: The base font name.
    ///   - encoding: The encoding name.
    ///   - embedded: Whether the font is embedded.
    /// - Returns: A minimal Type 1 font validation object.
    public static func minimal(
        name: String = "TestType1Font",
        encoding: String? = "WinAnsiEncoding",
        embedded: Bool = false
    ) -> Type1FontValidation {
        Type1FontValidation(
            baseFontName: name,
            encodingName: encoding,
            isEmbedded: embedded
        )
    }

    /// Creates a standard 14 font for testing.
    ///
    /// - Parameter name: The standard 14 font name.
    /// - Returns: A standard 14 font validation object.
    public static func standard14(name: String = "Helvetica") -> Type1FontValidation {
        Type1FontValidation(
            baseFontName: name,
            encodingName: "WinAnsiEncoding",
            isStandard14: true
        )
    }
}
