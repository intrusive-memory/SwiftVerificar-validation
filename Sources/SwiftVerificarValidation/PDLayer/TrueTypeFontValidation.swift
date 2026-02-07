import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - TrueType Font Validation

/// Validation wrapper for a TrueType font.
///
/// TrueType fonts use Apple/Microsoft TrueType technology with quadratic
/// Bezier curve outlines. They are one of the most common font formats in
/// modern PDF documents and support a wide range of scripts and languages.
///
/// ## Key Properties
///
/// - **Encoding**: The character encoding (WinAnsi, MacRoman, or custom)
/// - **Widths**: Per-glyph width values
/// - **First/Last Char**: Range of encoded character codes
/// - **Font Descriptor**: Contains metrics, flags, and embedding info
///
/// ## Validation Rules
///
/// TrueType fonts are checked for:
/// - Embedding of the font program (required for PDF/A)
/// - Correct `/Subtype` entry ("TrueType")
/// - Consistent widths between font dictionary and font program
/// - Proper encoding specification
/// - ToUnicode CMap for text extraction
/// - Valid `cmap` table in the embedded font program
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDTrueTypeFont` from veraPDF-validation, which wraps
/// a TrueType font dictionary for PDF/A and PDF/UA validation.
public struct TrueTypeFontValidation: FontValidation, Sendable, Equatable {

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

    /// The font subtype (always `.trueType`).
    public let fontSubtype: FontSubtype

    /// The base font name from the `/BaseFont` entry.
    public let baseFontName: String?

    /// The encoding name from the `/Encoding` entry.
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

    // MARK: - TrueType Specific Properties

    /// The first character code defined in the `/Widths` array.
    public let firstChar: Int?

    /// The last character code defined in the `/Widths` array.
    public let lastChar: Int?

    /// The per-glyph widths array.
    public let widths: [Double]

    /// Whether the encoding is a differences encoding.
    public let hasDifferencesEncoding: Bool

    /// The number of encoding differences.
    public let differencesCount: Int

    /// Whether the embedded font program has a valid `cmap` table.
    ///
    /// The `cmap` table maps character codes to glyph indices. Its presence
    /// and correctness are critical for text rendering and extraction.
    public let hasCmapTable: Bool

    /// Whether the embedded font program has a valid `post` table.
    ///
    /// The `post` table provides glyph name to glyph index mappings.
    public let hasPostTable: Bool

    /// Whether the font uses a Windows symbol encoding.
    ///
    /// Fonts with symbol encoding use platform ID 3, encoding ID 0 in
    /// the `cmap` table and may have different validation requirements.
    public let isWindowsSymbolEncoding: Bool

    /// Whether the font has a valid character code range.
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

    // MARK: - Initialization

    /// Creates a TrueType font validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - cosDictionary: The COS dictionary for the font.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - baseFontName: The base font name.
    ///   - encodingName: The encoding name.
    ///   - hasToUnicode: Whether the font has a ToUnicode CMap.
    ///   - isEmbedded: Whether the font is embedded.
    ///   - hasFontDescriptor: Whether the font has a descriptor.
    ///   - fontDescriptorFlags: The descriptor flags.
    ///   - italicAngle: The italic angle.
    ///   - fontBBox: The font bounding box.
    ///   - hasConsistentWidths: Whether widths are consistent.
    ///   - fontProgram: The font program.
    ///   - glyphCount: The number of glyphs.
    ///   - hasCompleteUnicodeMappings: Whether Unicode mappings are complete.
    ///   - firstChar: The first character code.
    ///   - lastChar: The last character code.
    ///   - widths: The per-glyph widths array.
    ///   - hasDifferencesEncoding: Whether the encoding has differences.
    ///   - differencesCount: The number of differences.
    ///   - hasCmapTable: Whether the font has a cmap table.
    ///   - hasPostTable: Whether the font has a post table.
    ///   - isWindowsSymbolEncoding: Whether the font uses Windows symbol encoding.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("F0"),
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
        hasDifferencesEncoding: Bool = false,
        differencesCount: Int = 0,
        hasCmapTable: Bool = true,
        hasPostTable: Bool = true,
        isWindowsSymbolEncoding: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .font(baseFontName ?? resourceName.stringValue)
        self.resourceName = resourceName
        self.fontSubtype = .trueType
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
        self.hasDifferencesEncoding = hasDifferencesEncoding
        self.differencesCount = differencesCount
        self.hasCmapTable = hasCmapTable
        self.hasPostTable = hasPostTable
        self.isWindowsSymbolEncoding = isWindowsSymbolEncoding
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDTrueTypeFont"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = fontPropertyNames
        names.append(contentsOf: [
            "firstChar", "lastChar", "widthsCount",
            "hasDifferencesEncoding", "differencesCount",
            "hasCmapTable", "hasPostTable", "isWindowsSymbolEncoding",
            "hasValidCharRange", "hasMatchingWidths"
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
        case "hasDifferencesEncoding":
            return .boolean(hasDifferencesEncoding)
        case "differencesCount":
            return .integer(Int64(differencesCount))
        case "hasCmapTable":
            return .boolean(hasCmapTable)
        case "hasPostTable":
            return .boolean(hasPostTable)
        case "isWindowsSymbolEncoding":
            return .boolean(isWindowsSymbolEncoding)
        case "hasValidCharRange":
            return .boolean(hasValidCharRange)
        case "hasMatchingWidths":
            return .boolean(hasMatchingWidths)
        default:
            if let fontProp = fontProperty(named: name) {
                return fontProp
            }
            return resourceProperty(named: name)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: TrueTypeFontValidation, rhs: TrueTypeFontValidation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Factory Methods

extension TrueTypeFontValidation {

    /// Creates a minimal TrueType font for testing.
    ///
    /// - Parameters:
    ///   - name: The base font name.
    ///   - encoding: The encoding name.
    ///   - embedded: Whether the font is embedded.
    /// - Returns: A minimal TrueType font validation object.
    public static func minimal(
        name: String = "TestTrueTypeFont",
        encoding: String? = "WinAnsiEncoding",
        embedded: Bool = false
    ) -> TrueTypeFontValidation {
        TrueTypeFontValidation(
            baseFontName: name,
            encodingName: encoding,
            isEmbedded: embedded
        )
    }
}
