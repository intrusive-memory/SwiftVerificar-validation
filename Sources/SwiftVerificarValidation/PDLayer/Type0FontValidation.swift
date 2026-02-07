import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Type 0 Font Validation

/// Validation wrapper for a Type 0 (composite) font.
///
/// Type 0 fonts are composite fonts that consist of a top-level font dictionary
/// referencing one or more CIDFont descendants and a CMap that maps character
/// codes to CID values. They are used primarily for CJK (Chinese, Japanese,
/// Korean) text and other complex scripts.
///
/// ## Key Properties
///
/// - **CMap**: The character map used to translate codes to CID values
/// - **Descendant Font**: The CIDFont that contains the glyph descriptions
/// - **ToUnicode**: Optional CMap for mapping to Unicode
///
/// ## Validation Rules
///
/// Type 0 fonts are checked for:
/// - Presence of a descendant CIDFont
/// - Valid CMap (either predefined or embedded)
/// - Embedding of the descendant font program
/// - ToUnicode CMap for text extraction
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDType0Font` from veraPDF-validation, which wraps
/// a Type 0 font dictionary for PDF/A and PDF/UA validation.
public struct Type0FontValidation: FontValidation, Sendable, Equatable {

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

    /// The font subtype (always `.type0` for this type).
    public let fontSubtype: FontSubtype

    /// The base font name from the `/BaseFont` entry.
    public let baseFontName: String?

    /// The CMap name or encoding from the `/Encoding` entry.
    ///
    /// For Type 0 fonts, this is the name of a predefined CMap
    /// (e.g., "Identity-H", "UniJIS-UCS2-H") or a reference to an
    /// embedded CMap stream.
    public let encodingName: String?

    /// Whether the font has a `/ToUnicode` CMap.
    public let hasToUnicode: Bool

    /// Whether the font program is embedded.
    ///
    /// For Type 0 fonts, embedding is determined by the descendant
    /// CIDFont's font descriptor.
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

    // MARK: - Type 0 Specific Properties

    /// The descendant CIDFont validation object.
    ///
    /// A Type 0 font must have exactly one descendant CIDFont.
    public let descendantFont: CIDFontValidation?

    /// The CMap validation object, if the CMap is embedded.
    ///
    /// Predefined CMaps (like "Identity-H") do not have an embedded
    /// CMap stream.
    public let cmap: CMapValidation?

    /// Whether the CMap is a predefined (named) CMap.
    public var isPredefinedCMap: Bool {
        cmap == nil && encodingName != nil
    }

    /// Whether the CMap is an Identity CMap.
    ///
    /// Identity CMaps map character codes directly to CID values without
    /// transformation. "Identity-H" is horizontal, "Identity-V" is vertical.
    public var isIdentityCMap: Bool {
        guard let name = encodingName else { return false }
        return name.hasPrefix("Identity")
    }

    /// Whether the font has a descendant font.
    public var hasDescendantFont: Bool {
        descendantFont != nil
    }

    /// Whether the font uses a vertical writing mode.
    public var isVerticalWriting: Bool {
        guard let name = encodingName else { return false }
        return name.hasSuffix("-V")
    }

    // MARK: - Initialization

    /// Creates a Type 0 font validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the font.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - baseFontName: The base font name.
    ///   - encodingName: The CMap/encoding name.
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
    ///   - descendantFont: The descendant CIDFont.
    ///   - cmap: The CMap validation object.
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
        descendantFont: CIDFontValidation? = nil,
        cmap: CMapValidation? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .font(baseFontName ?? resourceName.stringValue)
        self.resourceName = resourceName
        self.fontSubtype = .type0
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
        self.descendantFont = descendantFont
        self.cmap = cmap
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDType0Font"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = fontPropertyNames
        names.append(contentsOf: [
            "hasDescendantFont", "isPredefinedCMap",
            "isIdentityCMap", "isVerticalWriting"
        ])
        return names
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "hasDescendantFont":
            return .boolean(hasDescendantFont)
        case "isPredefinedCMap":
            return .boolean(isPredefinedCMap)
        case "isIdentityCMap":
            return .boolean(isIdentityCMap)
        case "isVerticalWriting":
            return .boolean(isVerticalWriting)
        default:
            if let fontProp = fontProperty(named: name) {
                return fontProp
            }
            return resourceProperty(named: name)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: Type0FontValidation, rhs: Type0FontValidation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Factory Methods

extension Type0FontValidation {

    /// Creates a minimal Type 0 font for testing.
    ///
    /// - Parameters:
    ///   - name: The base font name.
    ///   - encoding: The CMap/encoding name.
    ///   - embedded: Whether the font is embedded.
    /// - Returns: A minimal Type 0 font validation object.
    public static func minimal(
        name: String = "TestFont",
        encoding: String? = "Identity-H",
        embedded: Bool = false
    ) -> Type0FontValidation {
        Type0FontValidation(
            baseFontName: name,
            encodingName: encoding,
            isEmbedded: embedded
        )
    }
}
