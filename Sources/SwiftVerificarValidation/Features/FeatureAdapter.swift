import Foundation

/// Protocol for type-specific feature extraction.
///
/// A `FeatureAdapter` is responsible for extracting features from a specific
/// type of PDF object. Implementations provide specialized extraction logic
/// for different object types (fonts, images, pages, etc.).
///
/// Corresponds to feature adapters in veraPDF's feature reporting system.
public protocol FeatureAdapter: Sendable {

    /// The feature type that this adapter extracts.
    var featureType: FeatureType { get }

    /// The PDF object types this adapter can process.
    var supportedObjectTypes: [String] { get }

    /// Determines whether this adapter can extract features from the given object.
    ///
    /// - Parameter object: The PDF object to check.
    /// - Returns: `true` if this adapter can extract features from the object.
    func canExtract(from object: any PDFObject) -> Bool

    /// Extracts features from a PDF object.
    ///
    /// - Parameter object: The PDF object to extract features from.
    /// - Returns: A feature node containing the extracted data.
    /// - Throws: `FeatureExtractionError` if extraction fails.
    func extract(from object: any PDFObject) throws -> FeatureNode
}

// MARK: - Default Implementation

extension FeatureAdapter {

    /// Default implementation checks if the object type is in supportedObjectTypes.
    public func canExtract(from object: any PDFObject) -> Bool {
        supportedObjectTypes.contains(object.objectType)
    }
}

// MARK: - Feature Extraction Error

/// Errors that can occur during feature extraction.
public enum FeatureExtractionError: Error, Sendable, Equatable {

    /// The object type is not supported by this adapter.
    case unsupportedObjectType(String)

    /// A required property is missing from the object.
    case missingProperty(String)

    /// A property value has an invalid type.
    case invalidPropertyType(property: String, expected: String, actual: String)

    /// Feature extraction failed for an internal reason.
    case extractionFailed(String)

    /// Multiple errors occurred during extraction.
    case multipleErrors([FeatureExtractionError])
}

extension FeatureExtractionError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unsupportedObjectType(let type):
            return "Unsupported object type: \(type)"
        case .missingProperty(let property):
            return "Missing required property: \(property)"
        case .invalidPropertyType(let property, let expected, let actual):
            return "Invalid property type for '\(property)': expected \(expected), got \(actual)"
        case .extractionFailed(let reason):
            return "Feature extraction failed: \(reason)"
        case .multipleErrors(let errors):
            return "Multiple extraction errors: \(errors.map(\.description).joined(separator: "; "))"
        }
    }
}

// MARK: - Base Feature Adapter

/// A base implementation of `FeatureAdapter` that can be subclassed.
///
/// Provides common functionality for feature extraction including
/// value conversion and error handling.
open class BaseFeatureAdapter: FeatureAdapter, @unchecked Sendable {

    // MARK: - Properties

    /// The feature type that this adapter extracts.
    public let featureType: FeatureType

    /// The PDF object types this adapter can process.
    public let supportedObjectTypes: [String]

    // MARK: - Initialization

    /// Creates a new base feature adapter.
    ///
    /// - Parameters:
    ///   - featureType: The type of feature to extract.
    ///   - supportedObjectTypes: The object types this adapter supports.
    public init(featureType: FeatureType, supportedObjectTypes: [String]) {
        self.featureType = featureType
        self.supportedObjectTypes = supportedObjectTypes
    }

    // MARK: - Extraction

    /// Extracts features from a PDF object.
    ///
    /// Override this method in subclasses to provide specific extraction logic.
    ///
    /// - Parameter object: The PDF object to extract features from.
    /// - Returns: A feature node containing the extracted data.
    /// - Throws: `FeatureExtractionError` if extraction fails.
    open func extract(from object: any PDFObject) throws -> FeatureNode {
        guard canExtract(from: object) else {
            throw FeatureExtractionError.unsupportedObjectType(object.objectType)
        }
        return FeatureNode(featureType: featureType, name: object.objectType)
    }

    // MARK: - Helper Methods

    /// Converts a PropertyValue to a FeatureValue.
    ///
    /// - Parameter propertyValue: The property value to convert.
    /// - Returns: The converted feature value.
    public func convertToFeatureValue(_ propertyValue: PropertyValue) -> FeatureValue {
        switch propertyValue {
        case .null:
            return .null
        case .boolean(let v):
            return .bool(v)
        case .integer(let v):
            return .int(Int(v))
        case .real(let v):
            return .double(v)
        case .string(let v), .name(let v):
            return .string(v)
        case .object, .objectArray:
            // For objects, return a placeholder
            return .string("<object>")
        }
    }

    /// Extracts a string property from an object.
    ///
    /// - Parameters:
    ///   - name: The property name.
    ///   - object: The PDF object.
    /// - Returns: The string value, or nil if not found.
    public func getString(_ name: String, from object: any PDFObject) -> String? {
        object.property(named: name)?.stringValue
    }

    /// Extracts an integer property from an object.
    ///
    /// - Parameters:
    ///   - name: The property name.
    ///   - object: The PDF object.
    /// - Returns: The integer value, or nil if not found.
    public func getInt(_ name: String, from object: any PDFObject) -> Int? {
        guard let prop = object.property(named: name) else { return nil }
        switch prop {
        case .integer(let v): return Int(v)
        default: return nil
        }
    }

    /// Extracts a double property from an object.
    ///
    /// - Parameters:
    ///   - name: The property name.
    ///   - object: The PDF object.
    /// - Returns: The double value, or nil if not found.
    public func getDouble(_ name: String, from object: any PDFObject) -> Double? {
        object.property(named: name)?.numericValue
    }

    /// Extracts a boolean property from an object.
    ///
    /// - Parameters:
    ///   - name: The property name.
    ///   - object: The PDF object.
    /// - Returns: The boolean value, or nil if not found.
    public func getBool(_ name: String, from object: any PDFObject) -> Bool? {
        object.property(named: name)?.boolValue
    }

    /// Extracts a required string property, throwing if not found.
    ///
    /// - Parameters:
    ///   - name: The property name.
    ///   - object: The PDF object.
    /// - Returns: The string value.
    /// - Throws: `FeatureExtractionError.missingProperty` if not found.
    public func requireString(_ name: String, from object: any PDFObject) throws -> String {
        guard let value = getString(name, from: object) else {
            throw FeatureExtractionError.missingProperty(name)
        }
        return value
    }

    /// Extracts a required integer property, throwing if not found.
    ///
    /// - Parameters:
    ///   - name: The property name.
    ///   - object: The PDF object.
    /// - Returns: The integer value.
    /// - Throws: `FeatureExtractionError.missingProperty` if not found.
    public func requireInt(_ name: String, from object: any PDFObject) throws -> Int {
        guard let value = getInt(name, from: object) else {
            throw FeatureExtractionError.missingProperty(name)
        }
        return value
    }
}

// MARK: - Concrete Adapters

/// Adapter for extracting font features.
public final class FontFeatureAdapter: BaseFeatureAdapter, @unchecked Sendable {

    /// Shared instance of the font feature adapter.
    public static let shared = FontFeatureAdapter()

    /// Creates a new font feature adapter.
    public init() {
        super.init(
            featureType: .font,
            supportedObjectTypes: ["PDFont", "Font", "CIDFont", "Type0Font", "Type1Font", "TrueTypeFont", "Type3Font"]
        )
    }

    public override func extract(from object: any PDFObject) throws -> FeatureNode {
        guard canExtract(from: object) else {
            throw FeatureExtractionError.unsupportedObjectType(object.objectType)
        }

        var values: [String: FeatureValue] = [:]

        // Extract common font properties
        if let name = getString("baseFont", from: object) ?? getString("name", from: object) {
            values["name"] = .string(name)
        }

        if let subtype = getString("subtype", from: object) {
            values["subtype"] = .string(subtype)
        }

        if let encoding = getString("encoding", from: object) {
            values["encoding"] = .string(encoding)
        }

        if let isEmbedded = getBool("isEmbedded", from: object) {
            values["isEmbedded"] = .bool(isEmbedded)
        }

        if let isSubset = getBool("isSubset", from: object) {
            values["isSubset"] = .bool(isSubset)
        }

        return FeatureNode(
            featureType: .font,
            name: values["name"]?.stringValue,
            values: values,
            objectKey: object.objectKey
        )
    }
}

/// Adapter for extracting image features.
public final class ImageFeatureAdapter: BaseFeatureAdapter, @unchecked Sendable {

    /// Shared instance of the image feature adapter.
    public static let shared = ImageFeatureAdapter()

    /// Creates a new image feature adapter.
    public init() {
        super.init(
            featureType: .image,
            supportedObjectTypes: ["PDImage", "Image", "XObject", "PDImageXObject"]
        )
    }

    public override func extract(from object: any PDFObject) throws -> FeatureNode {
        guard canExtract(from: object) else {
            throw FeatureExtractionError.unsupportedObjectType(object.objectType)
        }

        var values: [String: FeatureValue] = [:]

        // Extract image properties
        if let width = getInt("width", from: object) {
            values["width"] = .int(width)
        }

        if let height = getInt("height", from: object) {
            values["height"] = .int(height)
        }

        if let bitsPerComponent = getInt("bitsPerComponent", from: object) {
            values["bitsPerComponent"] = .int(bitsPerComponent)
        }

        if let colorSpace = getString("colorSpace", from: object) {
            values["colorSpace"] = .string(colorSpace)
        }

        if let filter = getString("filter", from: object) {
            values["filter"] = .string(filter)
        }

        if let isInterpolate = getBool("interpolate", from: object) {
            values["interpolate"] = .bool(isInterpolate)
        }

        if let isMask = getBool("imageMask", from: object) {
            values["imageMask"] = .bool(isMask)
        }

        return FeatureNode(
            featureType: .image,
            values: values,
            objectKey: object.objectKey
        )
    }
}

/// Adapter for extracting color space features.
public final class ColorSpaceFeatureAdapter: BaseFeatureAdapter, @unchecked Sendable {

    /// Shared instance of the color space feature adapter.
    public static let shared = ColorSpaceFeatureAdapter()

    /// Creates a new color space feature adapter.
    public init() {
        super.init(
            featureType: .colorSpace,
            supportedObjectTypes: ["PDColorSpace", "ColorSpace", "ICCBased", "DeviceRGB", "DeviceCMYK", "DeviceGray"]
        )
    }

    public override func extract(from object: any PDFObject) throws -> FeatureNode {
        guard canExtract(from: object) else {
            throw FeatureExtractionError.unsupportedObjectType(object.objectType)
        }

        var values: [String: FeatureValue] = [:]

        // Extract color space properties
        if let name = getString("name", from: object) ?? getString("type", from: object) {
            values["name"] = .string(name)
        }

        if let numComponents = getInt("numComponents", from: object) ?? getInt("numberOfComponents", from: object) {
            values["numComponents"] = .int(numComponents)
        }

        if let iccProfileName = getString("iccProfileName", from: object) {
            values["iccProfileName"] = .string(iccProfileName)
        }

        return FeatureNode(
            featureType: .colorSpace,
            name: values["name"]?.stringValue,
            values: values,
            objectKey: object.objectKey
        )
    }
}

/// Adapter for extracting annotation features.
public final class AnnotationFeatureAdapter: BaseFeatureAdapter, @unchecked Sendable {

    /// Shared instance of the annotation feature adapter.
    public static let shared = AnnotationFeatureAdapter()

    /// Creates a new annotation feature adapter.
    public init() {
        super.init(
            featureType: .annotation,
            supportedObjectTypes: ["PDAnnotation", "Annotation", "PDAnnotationLink", "PDAnnotationWidget", "PDAnnotationMarkup"]
        )
    }

    public override func extract(from object: any PDFObject) throws -> FeatureNode {
        guard canExtract(from: object) else {
            throw FeatureExtractionError.unsupportedObjectType(object.objectType)
        }

        var values: [String: FeatureValue] = [:]

        // Extract annotation properties
        if let subtype = getString("subtype", from: object) {
            values["subtype"] = .string(subtype)
        }

        if let contents = getString("contents", from: object) {
            values["contents"] = .string(contents)
        }

        if let isVisible = getBool("isVisible", from: object) {
            values["isVisible"] = .bool(isVisible)
        }

        if let isPrintable = getBool("isPrintable", from: object) {
            values["isPrintable"] = .bool(isPrintable)
        }

        return FeatureNode(
            featureType: .annotation,
            name: values["subtype"]?.stringValue,
            values: values,
            objectKey: object.objectKey
        )
    }
}

// MARK: - Feature Adapter Registry

/// Registry for managing feature adapters.
///
/// The registry provides a central location to look up adapters
/// for different feature types and object types.
public final class FeatureAdapterRegistry: @unchecked Sendable {

    /// The shared registry instance.
    public static let shared = FeatureAdapterRegistry()

    /// Registered adapters by feature type.
    private var adaptersByFeatureType: [FeatureType: [any FeatureAdapter]]

    /// Registered adapters by object type.
    private var adaptersByObjectType: [String: [any FeatureAdapter]]

    /// Creates a new adapter registry with default adapters.
    public init() {
        self.adaptersByFeatureType = [:]
        self.adaptersByObjectType = [:]

        // Register default adapters
        register(FontFeatureAdapter.shared)
        register(ImageFeatureAdapter.shared)
        register(ColorSpaceFeatureAdapter.shared)
        register(AnnotationFeatureAdapter.shared)
    }

    /// Registers a feature adapter.
    ///
    /// - Parameter adapter: The adapter to register.
    public func register(_ adapter: any FeatureAdapter) {
        // Register by feature type
        var typeAdapters = adaptersByFeatureType[adapter.featureType] ?? []
        typeAdapters.append(adapter)
        adaptersByFeatureType[adapter.featureType] = typeAdapters

        // Register by object type
        for objectType in adapter.supportedObjectTypes {
            var objectAdapters = adaptersByObjectType[objectType] ?? []
            objectAdapters.append(adapter)
            adaptersByObjectType[objectType] = objectAdapters
        }
    }

    /// Returns adapters for a specific feature type.
    ///
    /// - Parameter featureType: The feature type.
    /// - Returns: Array of registered adapters.
    public func adapters(for featureType: FeatureType) -> [any FeatureAdapter] {
        adaptersByFeatureType[featureType] ?? []
    }

    /// Returns adapters that can extract from a specific object type.
    ///
    /// - Parameter objectType: The PDF object type.
    /// - Returns: Array of registered adapters.
    public func adapters(forObjectType objectType: String) -> [any FeatureAdapter] {
        adaptersByObjectType[objectType] ?? []
    }

    /// Finds an adapter that can extract features from the given object.
    ///
    /// - Parameter object: The PDF object.
    /// - Returns: An adapter that can extract from the object, or nil.
    public func findAdapter(for object: any PDFObject) -> (any FeatureAdapter)? {
        adapters(forObjectType: object.objectType).first { $0.canExtract(from: object) }
    }

    /// Returns all registered feature types.
    public var registeredFeatureTypes: [FeatureType] {
        Array(adaptersByFeatureType.keys).sorted { $0.rawValue < $1.rawValue }
    }

    /// Returns all registered object types.
    public var registeredObjectTypes: [String] {
        Array(adaptersByObjectType.keys).sorted()
    }
}
