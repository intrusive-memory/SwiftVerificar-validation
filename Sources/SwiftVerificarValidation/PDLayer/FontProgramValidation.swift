import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Font Program Validation

/// Validation wrapper for an embedded font program.
///
/// A font program contains the actual glyph outlines and metrics for a font.
/// It is embedded in the PDF as a stream referenced by the font descriptor's
/// `/FontFile`, `/FontFile2`, or `/FontFile3` entry.
///
/// ## Font Program Types
///
/// - **Type 1**: Referenced by `/FontFile`. Adobe Type 1 format.
/// - **TrueType**: Referenced by `/FontFile2`. TrueType/OpenType format.
/// - **Type1C (CFF)**: Referenced by `/FontFile3` with Subtype `/Type1C`.
/// - **CIDFontType0C**: Referenced by `/FontFile3` with Subtype `/CIDFontType0C`.
/// - **OpenType**: Referenced by `/FontFile3` with Subtype `/OpenType`.
///
/// ## Validation Rules
///
/// Font programs are checked for:
/// - Valid program data (non-empty, parseable)
/// - Consistent glyph count with font dictionary
/// - Width consistency between program and font dictionary
/// - Required tables (for TrueType: cmap, head, hhea, hmtx, etc.)
/// - CID mappings (for CIDFont programs)
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFFontProgram`, `GFTrueTypeFontProgram`, and related
/// classes from veraPDF-validation. Consolidated into a single struct using
/// the `FontProgramType` enum to distinguish formats.
public struct FontProgramValidation: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the font program stream.
    public let cosDictionary: COSValue?

    /// The object key for the font program, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Font Program Properties

    /// The type of font program.
    public let programType: FontProgramType

    /// The size of the font program data in bytes.
    public let dataSize: Int

    /// The number of glyphs defined in the font program.
    public let glyphCount: Int

    /// Whether the font program data is valid and parseable.
    ///
    /// A font program is considered valid if it has non-zero size
    /// and its format-specific header/structure can be parsed.
    public let isValid: Bool

    /// Whether the font program contains width information.
    ///
    /// Width information is needed to validate consistency between
    /// the font dictionary's width values and the actual glyph metrics.
    public let hasWidthInfo: Bool

    /// The number of width mismatches between the program and font dictionary.
    ///
    /// A width mismatch occurs when the width specified in the font
    /// dictionary differs from the width in the font program by more
    /// than 1 unit (in glyph coordinate space).
    public let widthMismatchCount: Int

    /// Whether all required tables are present (TrueType/OpenType only).
    ///
    /// For TrueType programs, required tables include: `cmap`, `glyf`,
    /// `head`, `hhea`, `hmtx`, `loca`, `maxp`, `name`, `post`.
    public let hasRequiredTables: Bool

    /// The names of missing required tables (TrueType/OpenType only).
    public let missingTables: [String]

    /// Whether the font program has a valid CFF structure (CFF programs only).
    ///
    /// For Type1C and CIDFontType0C programs, this indicates whether
    /// the CFF data structure is well-formed.
    public let hasValidCFFStructure: Bool

    /// Whether the font program has CID mappings (CID programs only).
    public let hasCIDMappings: Bool

    /// The number of CID mappings in the program (CID programs only).
    public let cidMappingCount: Int

    /// Whether the font program is a subset.
    ///
    /// A subset font program contains only the glyphs actually used
    /// in the document. Subset fonts typically have a name prefix
    /// like "ABCDEF+FontName".
    public let isSubset: Bool

    /// The subset prefix, if the font is a subset.
    ///
    /// A 6-character uppercase prefix followed by "+", e.g., "ABCDEF+".
    public let subsetPrefix: String?

    // MARK: - Computed Properties

    /// Whether the font program has no width mismatches.
    public var hasConsistentWidths: Bool {
        widthMismatchCount == 0
    }

    /// Whether the font program has non-zero size.
    public var hasData: Bool {
        dataSize > 0
    }

    /// Whether there are missing tables.
    public var hasMissingTables: Bool {
        !missingTables.isEmpty
    }

    // MARK: - Initialization

    /// Creates a font program validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - cosDictionary: The COS dictionary for the stream.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - programType: The font program type.
    ///   - dataSize: The data size in bytes.
    ///   - glyphCount: The number of glyphs.
    ///   - isValid: Whether the program is valid.
    ///   - hasWidthInfo: Whether width info is present.
    ///   - widthMismatchCount: The number of width mismatches.
    ///   - hasRequiredTables: Whether required tables are present.
    ///   - missingTables: Names of missing tables.
    ///   - hasValidCFFStructure: Whether the CFF structure is valid.
    ///   - hasCIDMappings: Whether CID mappings are present.
    ///   - cidMappingCount: The number of CID mappings.
    ///   - isSubset: Whether the program is a subset.
    ///   - subsetPrefix: The subset prefix.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        programType: FontProgramType = .type1,
        dataSize: Int = 0,
        glyphCount: Int = 0,
        isValid: Bool = true,
        hasWidthInfo: Bool = true,
        widthMismatchCount: Int = 0,
        hasRequiredTables: Bool = true,
        missingTables: [String] = [],
        hasValidCFFStructure: Bool = true,
        hasCIDMappings: Bool = false,
        cidMappingCount: Int = 0,
        isSubset: Bool = false,
        subsetPrefix: String? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? ObjectContext(location: "FontProgram", role: programType.rawValue)
        self.programType = programType
        self.dataSize = dataSize
        self.glyphCount = glyphCount
        self.isValid = isValid
        self.hasWidthInfo = hasWidthInfo
        self.widthMismatchCount = widthMismatchCount
        self.hasRequiredTables = hasRequiredTables
        self.missingTables = missingTables
        self.hasValidCFFStructure = hasValidCFFStructure
        self.hasCIDMappings = hasCIDMappings
        self.cidMappingCount = cidMappingCount
        self.isSubset = isSubset
        self.subsetPrefix = subsetPrefix
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "FontProgram"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "programType", "dataSize", "glyphCount", "isValid",
            "hasWidthInfo", "widthMismatchCount", "hasConsistentWidths",
            "hasRequiredTables", "missingTableCount", "hasValidCFFStructure",
            "hasCIDMappings", "cidMappingCount",
            "isSubset", "subsetPrefix", "hasData", "hasMissingTables"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "programType":
            return .string(programType.rawValue)
        case "dataSize":
            return .integer(Int64(dataSize))
        case "glyphCount":
            return .integer(Int64(glyphCount))
        case "isValid":
            return .boolean(isValid)
        case "hasWidthInfo":
            return .boolean(hasWidthInfo)
        case "widthMismatchCount":
            return .integer(Int64(widthMismatchCount))
        case "hasConsistentWidths":
            return .boolean(hasConsistentWidths)
        case "hasRequiredTables":
            return .boolean(hasRequiredTables)
        case "missingTableCount":
            return .integer(Int64(missingTables.count))
        case "hasValidCFFStructure":
            return .boolean(hasValidCFFStructure)
        case "hasCIDMappings":
            return .boolean(hasCIDMappings)
        case "cidMappingCount":
            return .integer(Int64(cidMappingCount))
        case "isSubset":
            return .boolean(isSubset)
        case "subsetPrefix":
            if let prefix = subsetPrefix {
                return .string(prefix)
            }
            return .null
        case "hasData":
            return .boolean(hasData)
        case "hasMissingTables":
            return .boolean(hasMissingTables)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: FontProgramValidation, rhs: FontProgramValidation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Font Program Type

/// Enumeration of font program formats.
///
/// Identifies the format of the embedded font data, which determines
/// how it should be parsed and validated.
public enum FontProgramType: String, Sendable, CaseIterable, Equatable {

    /// Adobe Type 1 font program.
    ///
    /// Referenced by the font descriptor's `/FontFile` entry.
    /// Contains PostScript Type 1 charstrings.
    case type1 = "Type1"

    /// TrueType font program.
    ///
    /// Referenced by the font descriptor's `/FontFile2` entry.
    /// Contains TrueType table directory and glyph data.
    case trueType = "TrueType"

    /// Compact Font Format (CFF) Type 1 program.
    ///
    /// Referenced by the font descriptor's `/FontFile3` entry
    /// with Subtype `/Type1C`. A compact representation of Type 1.
    case type1C = "Type1C"

    /// CFF CIDFont Type 0 program.
    ///
    /// Referenced by the font descriptor's `/FontFile3` entry
    /// with Subtype `/CIDFontType0C`. CFF format for CID-keyed fonts.
    case cidFontType0C = "CIDFontType0C"

    /// OpenType font program.
    ///
    /// Referenced by the font descriptor's `/FontFile3` entry
    /// with Subtype `/OpenType`. Can contain CFF or TrueType outlines.
    case openType = "OpenType"

    /// Unknown font program type.
    case unknown = "Unknown"

    /// Creates a font program type from a `/FontFile3` subtype name.
    ///
    /// - Parameter subtypeName: The subtype name.
    public init(fromSubtype subtypeName: String?) {
        guard let name = subtypeName else {
            self = .unknown
            return
        }
        self = FontProgramType(rawValue: name) ?? .unknown
    }

    /// Whether this program type uses CFF (Compact Font Format).
    public var isCFF: Bool {
        self == .type1C || self == .cidFontType0C
    }

    /// Whether this program type uses TrueType outlines.
    public var isTrueTypeOutlines: Bool {
        self == .trueType
    }

    /// Whether this program type may contain either CFF or TrueType outlines.
    public var isOpenType: Bool {
        self == .openType
    }
}

// MARK: - Factory Methods

extension FontProgramValidation {

    /// Creates a minimal Type 1 font program for testing.
    ///
    /// - Parameters:
    ///   - dataSize: The data size.
    ///   - glyphCount: The number of glyphs.
    /// - Returns: A minimal Type 1 font program.
    public static func type1Program(
        dataSize: Int = 1024,
        glyphCount: Int = 228
    ) -> FontProgramValidation {
        FontProgramValidation(
            programType: .type1,
            dataSize: dataSize,
            glyphCount: glyphCount
        )
    }

    /// Creates a minimal TrueType font program for testing.
    ///
    /// - Parameters:
    ///   - dataSize: The data size.
    ///   - glyphCount: The number of glyphs.
    ///   - hasRequiredTables: Whether all required tables are present.
    /// - Returns: A minimal TrueType font program.
    public static func trueTypeProgram(
        dataSize: Int = 4096,
        glyphCount: Int = 256,
        hasRequiredTables: Bool = true
    ) -> FontProgramValidation {
        FontProgramValidation(
            programType: .trueType,
            dataSize: dataSize,
            glyphCount: glyphCount,
            hasRequiredTables: hasRequiredTables
        )
    }

    /// Creates a minimal CFF font program for testing.
    ///
    /// - Parameters:
    ///   - dataSize: The data size.
    ///   - glyphCount: The number of glyphs.
    ///   - isCID: Whether this is a CID program.
    /// - Returns: A minimal CFF font program.
    public static func cffProgram(
        dataSize: Int = 2048,
        glyphCount: Int = 228,
        isCID: Bool = false
    ) -> FontProgramValidation {
        FontProgramValidation(
            programType: isCID ? .cidFontType0C : .type1C,
            dataSize: dataSize,
            glyphCount: glyphCount,
            hasValidCFFStructure: true,
            hasCIDMappings: isCID,
            cidMappingCount: isCID ? glyphCount : 0
        )
    }
}
