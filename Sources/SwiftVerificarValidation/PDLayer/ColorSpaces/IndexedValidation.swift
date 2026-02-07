import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Indexed Validation

/// Validation wrapper for the Indexed color space.
///
/// Indexed is a special color space that maps single-byte index values to
/// colors in a base color space. It uses a lookup table with up to 256
/// entries, each entry being a set of component values in the base space.
///
/// ## Key Properties
///
/// - **Base Color Space**: The underlying color space for the lookup entries
/// - **HiVal**: The maximum valid index value (0-255)
/// - **Lookup Table Size**: The number of bytes in the lookup table
///
/// ## Validation Rules
///
/// Indexed color spaces are checked for:
/// - Valid base color space (cannot be Pattern or another Indexed)
/// - HiVal in range 0-255
/// - Lookup table size matching `(HiVal + 1) * baseComponents`
/// - Base color space compliance for PDF/A
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDIndexed` from veraPDF-validation.
public struct IndexedValidation: ColorSpaceValidation, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for this color space (the array definition).
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    /// The resource name.
    public let resourceName: ASAtom

    // MARK: - Color Space Properties

    /// The color space family. Always `.indexed`.
    public let colorSpaceFamily: ColorSpaceFamily = .indexed

    /// The number of components. Always 1 (the index value).
    public let componentCount: Int = 1

    // MARK: - Indexed Specific Properties

    /// The name or family of the base color space.
    ///
    /// The base color space defines the actual colors that the index values
    /// map to. It must not be Pattern or Indexed.
    public let baseColorSpaceName: String?

    /// The number of components in the base color space.
    public let baseComponentCount: Int

    /// The maximum valid index value (0-255).
    ///
    /// This corresponds to the HiVal entry in the Indexed color space
    /// definition array.
    public let hiVal: Int

    /// The size of the lookup table in bytes.
    public let lookupTableSize: Int

    /// Whether the lookup table is embedded as a string (vs. a stream).
    public let isLookupString: Bool

    /// Whether the base color space is valid.
    ///
    /// The base color space cannot be Pattern or Indexed.
    public var hasValidBaseColorSpace: Bool {
        guard let name = baseColorSpaceName else { return false }
        return name != "Pattern" && name != "Indexed"
    }

    /// Whether the HiVal is in the valid range (0-255).
    public var hasValidHiVal: Bool {
        hiVal >= 0 && hiVal <= 255
    }

    /// The expected lookup table size based on HiVal and base component count.
    ///
    /// The table should contain `(hiVal + 1) * baseComponentCount` bytes.
    public var expectedLookupSize: Int {
        (hiVal + 1) * baseComponentCount
    }

    /// Whether the lookup table size matches the expected size.
    public var hasMatchingLookupSize: Bool {
        lookupTableSize == expectedLookupSize
    }

    /// Whether the Indexed color space definition is valid.
    public var isValid: Bool {
        hasValidBaseColorSpace && hasValidHiVal && hasMatchingLookupSize
    }

    // MARK: - Initialization

    /// Creates an Indexed validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS value for the color space definition.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - baseColorSpaceName: The base color space name.
    ///   - baseComponentCount: The base color space component count.
    ///   - hiVal: The maximum index value.
    ///   - lookupTableSize: The lookup table size in bytes.
    ///   - isLookupString: Whether the lookup is a string (vs. stream).
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resourceName: ASAtom = ASAtom("CS0"),
        baseColorSpaceName: String? = nil,
        baseComponentCount: Int = 3,
        hiVal: Int = 255,
        lookupTableSize: Int = 0,
        isLookupString: Bool = true
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .colorSpace("Indexed")
        self.resourceName = resourceName
        self.baseColorSpaceName = baseColorSpaceName
        self.baseComponentCount = baseComponentCount
        self.hiVal = hiVal
        self.lookupTableSize = lookupTableSize
        self.isLookupString = isLookupString
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDIndexed"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = colorSpacePropertyNames
        names.append(contentsOf: [
            "baseColorSpaceName", "baseComponentCount",
            "hiVal", "lookupTableSize", "isLookupString",
            "hasValidBaseColorSpace", "hasValidHiVal",
            "expectedLookupSize", "hasMatchingLookupSize", "isValid"
        ])
        return names
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "baseColorSpaceName":
            if let n = baseColorSpaceName {
                return .string(n)
            }
            return .null
        case "baseComponentCount":
            return .integer(Int64(baseComponentCount))
        case "hiVal":
            return .integer(Int64(hiVal))
        case "lookupTableSize":
            return .integer(Int64(lookupTableSize))
        case "isLookupString":
            return .boolean(isLookupString)
        case "hasValidBaseColorSpace":
            return .boolean(hasValidBaseColorSpace)
        case "hasValidHiVal":
            return .boolean(hasValidHiVal)
        case "expectedLookupSize":
            return .integer(Int64(expectedLookupSize))
        case "hasMatchingLookupSize":
            return .boolean(hasMatchingLookupSize)
        case "isValid":
            return .boolean(isValid)
        default:
            if let csProp = colorSpaceProperty(named: name) {
                return csProp
            }
            return resourceProperty(named: name)
        }
    }

    // MARK: - Equatable

    public static func == (lhs: IndexedValidation, rhs: IndexedValidation) -> Bool {
        lhs.id == rhs.id
    }
}
