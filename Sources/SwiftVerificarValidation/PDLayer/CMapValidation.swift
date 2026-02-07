import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - CMap Validation

/// Validation wrapper for a CMap (Character Map) resource.
///
/// CMaps define the mapping between character codes and CID (Character
/// Identifier) values for use with Type 0 composite fonts. They can be
/// either predefined (referenced by name) or embedded as a stream.
///
/// ## Key Properties
///
/// - **CMap Name**: The name identifying this CMap
/// - **CID System Info**: Registry, ordering, and supplement
/// - **Writing Mode**: Horizontal (0) or vertical (1)
/// - **Code Space Ranges**: Defines valid character code ranges
///
/// ## Validation Rules
///
/// CMaps are checked for:
/// - Valid CMap name matching the font's encoding entry
/// - Consistent CIDSystemInfo with the descendant CIDFont
/// - Valid code space range definitions
/// - Proper writing mode specification
/// - Well-formed mapping entries
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFCMapFile` from veraPDF-validation, which wraps
/// an embedded CMap stream for PDF/A and PDF/UA validation.
public struct CMapValidation: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the CMap stream.
    public let cosDictionary: COSValue?

    /// The object key for the CMap, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - CMap Properties

    /// The CMap name from the `/CMapName` entry.
    ///
    /// This is the name that identifies this CMap. For predefined CMaps,
    /// this matches the encoding name in the Type 0 font dictionary.
    public let cmapName: String?

    /// The CMap type (0 for CMap, 1 for CIDSystemInfo, 2 for codespace).
    ///
    /// Per the CMap specification, the `/CMapType` entry indicates the
    /// type of the CMap resource.
    public let cmapType: Int

    /// The CID system info registry (e.g., "Adobe").
    public let cidRegistry: String?

    /// The CID system info ordering (e.g., "Identity", "Japan1").
    public let cidOrdering: String?

    /// The CID system info supplement number.
    public let cidSupplement: Int?

    /// The writing mode.
    ///
    /// - 0: Horizontal writing mode
    /// - 1: Vertical writing mode
    public let writingMode: Int

    /// The number of code space ranges defined in the CMap.
    ///
    /// Code space ranges define the valid ranges of character codes.
    /// Each range specifies a lower and upper bound.
    public let codeSpaceRangeCount: Int

    /// The number of CID mapping entries.
    ///
    /// This includes entries from `beginbfchar`/`endbfchar` and
    /// `beginbfrange`/`endbfrange` sections.
    public let cidMappingCount: Int

    /// The number of notdef mapping entries.
    ///
    /// Notdef mappings specify the CID to use for undefined character codes.
    public let notdefMappingCount: Int

    /// Whether the CMap data is valid and parseable.
    public let isValid: Bool

    /// The size of the CMap data in bytes.
    public let dataSize: Int

    /// Whether the CMap uses a predefined CMap as its base.
    ///
    /// Embedded CMaps may reference a predefined CMap via the
    /// `/UseCMap` entry to inherit its mappings.
    public let usesBaseCMap: Bool

    /// The name of the base CMap, if any.
    public let baseCMapName: String?

    // MARK: - Computed Properties

    /// Whether the CIDSystemInfo dictionary is present and valid.
    public var hasCIDSystemInfo: Bool {
        cidRegistry != nil && cidOrdering != nil && cidSupplement != nil
    }

    /// The CID system info as a combined string.
    public var cidSystemInfoString: String? {
        guard let registry = cidRegistry,
              let ordering = cidOrdering,
              let supplement = cidSupplement else {
            return nil
        }
        return "\(registry)-\(ordering)-\(supplement)"
    }

    /// Whether the CMap uses horizontal writing mode.
    public var isHorizontal: Bool {
        writingMode == 0
    }

    /// Whether the CMap uses vertical writing mode.
    public var isVertical: Bool {
        writingMode == 1
    }

    /// Whether the CMap has any CID mappings.
    public var hasMappings: Bool {
        cidMappingCount > 0
    }

    /// Whether the CMap has code space ranges.
    public var hasCodeSpaceRanges: Bool {
        codeSpaceRangeCount > 0
    }

    /// Whether the CMap has non-zero data.
    public var hasData: Bool {
        dataSize > 0
    }

    /// Whether the CMap inherits from a base CMap.
    public var hasBaseCMap: Bool {
        usesBaseCMap && baseCMapName != nil
    }

    // MARK: - Initialization

    /// Creates a CMap validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - cosDictionary: The COS dictionary for the CMap stream.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - cmapName: The CMap name.
    ///   - cmapType: The CMap type.
    ///   - cidRegistry: The CID system info registry.
    ///   - cidOrdering: The CID system info ordering.
    ///   - cidSupplement: The CID system info supplement.
    ///   - writingMode: The writing mode (0=horizontal, 1=vertical).
    ///   - codeSpaceRangeCount: The number of code space ranges.
    ///   - cidMappingCount: The number of CID mappings.
    ///   - notdefMappingCount: The number of notdef mappings.
    ///   - isValid: Whether the CMap is valid.
    ///   - dataSize: The data size in bytes.
    ///   - usesBaseCMap: Whether a base CMap is used.
    ///   - baseCMapName: The base CMap name.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        cmapName: String? = nil,
        cmapType: Int = 0,
        cidRegistry: String? = nil,
        cidOrdering: String? = nil,
        cidSupplement: Int? = nil,
        writingMode: Int = 0,
        codeSpaceRangeCount: Int = 0,
        cidMappingCount: Int = 0,
        notdefMappingCount: Int = 0,
        isValid: Bool = true,
        dataSize: Int = 0,
        usesBaseCMap: Bool = false,
        baseCMapName: String? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? ObjectContext(location: "CMap", role: cmapName)
        self.cmapName = cmapName
        self.cmapType = cmapType
        self.cidRegistry = cidRegistry
        self.cidOrdering = cidOrdering
        self.cidSupplement = cidSupplement
        self.writingMode = writingMode
        self.codeSpaceRangeCount = codeSpaceRangeCount
        self.cidMappingCount = cidMappingCount
        self.notdefMappingCount = notdefMappingCount
        self.isValid = isValid
        self.dataSize = dataSize
        self.usesBaseCMap = usesBaseCMap
        self.baseCMapName = baseCMapName
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "CMap"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "cmapName", "cmapType", "cidRegistry", "cidOrdering",
            "cidSupplement", "cidSystemInfoString", "hasCIDSystemInfo",
            "writingMode", "isHorizontal", "isVertical",
            "codeSpaceRangeCount", "cidMappingCount", "notdefMappingCount",
            "isValid", "dataSize", "hasData",
            "hasMappings", "hasCodeSpaceRanges",
            "usesBaseCMap", "baseCMapName", "hasBaseCMap"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "cmapName":
            if let n = cmapName { return .string(n) }
            return .null
        case "cmapType":
            return .integer(Int64(cmapType))
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
        case "writingMode":
            return .integer(Int64(writingMode))
        case "isHorizontal":
            return .boolean(isHorizontal)
        case "isVertical":
            return .boolean(isVertical)
        case "codeSpaceRangeCount":
            return .integer(Int64(codeSpaceRangeCount))
        case "cidMappingCount":
            return .integer(Int64(cidMappingCount))
        case "notdefMappingCount":
            return .integer(Int64(notdefMappingCount))
        case "isValid":
            return .boolean(isValid)
        case "dataSize":
            return .integer(Int64(dataSize))
        case "hasData":
            return .boolean(hasData)
        case "hasMappings":
            return .boolean(hasMappings)
        case "hasCodeSpaceRanges":
            return .boolean(hasCodeSpaceRanges)
        case "usesBaseCMap":
            return .boolean(usesBaseCMap)
        case "baseCMapName":
            if let n = baseCMapName { return .string(n) }
            return .null
        case "hasBaseCMap":
            return .boolean(hasBaseCMap)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: CMapValidation, rhs: CMapValidation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Factory Methods

extension CMapValidation {

    /// Creates a minimal CMap for testing.
    ///
    /// - Parameters:
    ///   - name: The CMap name.
    ///   - writingMode: The writing mode.
    /// - Returns: A minimal CMap validation object.
    public static func minimal(
        name: String = "Identity-H",
        writingMode: Int = 0
    ) -> CMapValidation {
        CMapValidation(
            cmapName: name,
            writingMode: writingMode,
            isValid: true
        )
    }

    /// Creates an embedded CMap for testing.
    ///
    /// - Parameters:
    ///   - name: The CMap name.
    ///   - registry: The CID registry.
    ///   - ordering: The CID ordering.
    ///   - supplement: The CID supplement.
    ///   - mappingCount: The number of CID mappings.
    /// - Returns: An embedded CMap validation object.
    public static func embedded(
        name: String = "CustomCMap",
        registry: String = "Adobe",
        ordering: String = "Identity",
        supplement: Int = 0,
        mappingCount: Int = 100
    ) -> CMapValidation {
        CMapValidation(
            cmapName: name,
            cidRegistry: registry,
            cidOrdering: ordering,
            cidSupplement: supplement,
            codeSpaceRangeCount: 1,
            cidMappingCount: mappingCount,
            isValid: true,
            dataSize: 2048
        )
    }
}
