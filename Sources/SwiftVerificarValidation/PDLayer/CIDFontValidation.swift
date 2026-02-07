import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - CID Font Validation

/// Validation wrapper for a CIDFont.
///
/// CIDFonts are used as descendants of Type 0 (composite) fonts. They contain
/// glyph descriptions for CID (Character Identifier) values, which are mapped
/// from character codes by the parent Type 0 font's CMap.
///
/// There are two subtypes:
/// - **CIDFontType0**: Glyph descriptions in Type 1/CFF format
/// - **CIDFontType2**: Glyph descriptions in TrueType format
///
/// ## Key Properties
///
/// - **CID System Info**: Registry, ordering, and supplement for the character collection
/// - **Default Width**: The default glyph width for CIDs not listed in the W array
/// - **W Array**: Per-CID width specifications
/// - **CIDToGIDMap**: Mapping from CIDs to glyph indices (CIDFontType2 only)
///
/// ## Validation Rules
///
/// CIDFonts are checked for:
/// - Valid CIDSystemInfo dictionary (Registry, Ordering, Supplement)
/// - Embedding of the font program (required for PDF/A)
/// - CIDToGIDMap for CIDFontType2 (required for PDF/A-1)
/// - Consistent widths between W array and font program
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDCIDFont` from veraPDF-validation, which wraps
/// a CIDFont dictionary for PDF/A and PDF/UA validation.
public struct CIDFontValidation: FontValidation, Sendable, Equatable {

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

    /// The font subtype (`.cidFontType0` or `.cidFontType2`).
    public let fontSubtype: FontSubtype

    /// The base font name from the `/BaseFont` entry.
    public let baseFontName: String?

    /// The encoding name (not directly applicable to CIDFonts; inherited from parent).
    public let encodingName: String?

    /// Whether the parent font has a `/ToUnicode` CMap.
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

    // MARK: - CIDFont Specific Properties

    /// The CID system info registry (e.g., "Adobe").
    ///
    /// Identifies the issuer of the character collection.
    public let cidRegistry: String?

    /// The CID system info ordering (e.g., "Identity", "Japan1", "GB1").
    ///
    /// Identifies the character collection within the registry.
    public let cidOrdering: String?

    /// The CID system info supplement number.
    ///
    /// Identifies the supplement version of the character collection.
    public let cidSupplement: Int?

    /// The default glyph width for CIDs not listed in the W array.
    ///
    /// This is the value of the `/DW` entry. Defaults to 1000 per the
    /// PDF specification if not present.
    public let defaultWidth: Double

    /// The number of CID-to-width entries in the W array.
    ///
    /// The W array specifies widths for individual CIDs or ranges of CIDs.
    public let widthEntryCount: Int

    /// Whether the font has a `/CIDToGIDMap` entry.
    ///
    /// For CIDFontType2 fonts, this maps CIDs to glyph indices in the
    /// TrueType font program. Required for PDF/A-1.
    public let hasCIDToGIDMap: Bool

    /// Whether the CIDToGIDMap is the identity mapping.
    ///
    /// When `true`, CID values map directly to glyph indices (CID == GID).
    public let isCIDToGIDMapIdentity: Bool

    /// Whether the CIDSystemInfo dictionary is present and valid.
    public var hasCIDSystemInfo: Bool {
        cidRegistry != nil && cidOrdering != nil && cidSupplement != nil
    }

    /// Whether this is a CIDFontType0 (Type 1/CFF based).
    public var isCIDFontType0: Bool {
        fontSubtype == .cidFontType0
    }

    /// Whether this is a CIDFontType2 (TrueType based).
    public var isCIDFontType2: Bool {
        fontSubtype == .cidFontType2
    }

    /// The CID system info as a combined string (e.g., "Adobe-Identity-0").
    public var cidSystemInfoString: String? {
        guard let registry = cidRegistry,
              let ordering = cidOrdering,
              let supplement = cidSupplement else {
            return nil
        }
        return "\(registry)-\(ordering)-\(supplement)"
    }

    // MARK: - Initialization

    /// Creates a CIDFont validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - cosDictionary: The COS dictionary for the font.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - fontSubtype: The font subtype (`.cidFontType0` or `.cidFontType2`).
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
    ///   - cidRegistry: The CID system info registry.
    ///   - cidOrdering: The CID system info ordering.
    ///   - cidSupplement: The CID system info supplement.
    ///   - defaultWidth: The default glyph width.
    ///   - widthEntryCount: The number of width entries.
    ///   - hasCIDToGIDMap: Whether the font has a CIDToGIDMap.
    ///   - isCIDToGIDMapIdentity: Whether the CIDToGIDMap is identity.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("F0"),
        fontSubtype: FontSubtype = .cidFontType0,
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
        cidRegistry: String? = nil,
        cidOrdering: String? = nil,
        cidSupplement: Int? = nil,
        defaultWidth: Double = 1000.0,
        widthEntryCount: Int = 0,
        hasCIDToGIDMap: Bool = false,
        isCIDToGIDMapIdentity: Bool = false
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
        self.cidRegistry = cidRegistry
        self.cidOrdering = cidOrdering
        self.cidSupplement = cidSupplement
        self.defaultWidth = defaultWidth
        self.widthEntryCount = widthEntryCount
        self.hasCIDToGIDMap = hasCIDToGIDMap
        self.isCIDToGIDMapIdentity = isCIDToGIDMapIdentity
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDCIDFont"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = fontPropertyNames
        names.append(contentsOf: [
            "cidRegistry", "cidOrdering", "cidSupplement",
            "cidSystemInfoString", "hasCIDSystemInfo",
            "defaultWidth", "widthEntryCount",
            "hasCIDToGIDMap", "isCIDToGIDMapIdentity",
            "isCIDFontType0", "isCIDFontType2"
        ])
        return names
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "cidRegistry":
            if let reg = cidRegistry { return .string(reg) }
            return .null
        case "cidOrdering":
            if let ord = cidOrdering { return .string(ord) }
            return .null
        case "cidSupplement":
            if let sup = cidSupplement { return .integer(Int64(sup)) }
            return .null
        case "cidSystemInfoString":
            if let info = cidSystemInfoString { return .string(info) }
            return .null
        case "hasCIDSystemInfo":
            return .boolean(hasCIDSystemInfo)
        case "defaultWidth":
            return .real(defaultWidth)
        case "widthEntryCount":
            return .integer(Int64(widthEntryCount))
        case "hasCIDToGIDMap":
            return .boolean(hasCIDToGIDMap)
        case "isCIDToGIDMapIdentity":
            return .boolean(isCIDToGIDMapIdentity)
        case "isCIDFontType0":
            return .boolean(isCIDFontType0)
        case "isCIDFontType2":
            return .boolean(isCIDFontType2)
        default:
            if let fontProp = fontProperty(named: name) {
                return fontProp
            }
            return resourceProperty(named: name)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: CIDFontValidation, rhs: CIDFontValidation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Factory Methods

extension CIDFontValidation {

    /// Creates a minimal CIDFont for testing.
    ///
    /// - Parameters:
    ///   - name: The base font name.
    ///   - subtype: The CIDFont subtype.
    ///   - registry: The CID registry.
    ///   - ordering: The CID ordering.
    /// - Returns: A minimal CIDFont validation object.
    public static func minimal(
        name: String = "TestCIDFont",
        subtype: FontSubtype = .cidFontType0,
        registry: String = "Adobe",
        ordering: String = "Identity"
    ) -> CIDFontValidation {
        CIDFontValidation(
            fontSubtype: subtype,
            baseFontName: name,
            cidRegistry: registry,
            cidOrdering: ordering,
            cidSupplement: 0
        )
    }
}
