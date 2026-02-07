import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Mock Objects for Testing

struct MockFontObject: PDFObject, Equatable {
    let id = UUID()
    let objectType = "PDFont"
    let cosObject: COSValue? = nil
    let objectKey: COSObjectKey?

    private let properties: [String: PropertyValue]

    init(
        name: String = "TestFont",
        subtype: String = "Type1",
        encoding: String? = nil,
        isEmbedded: Bool = false,
        isSubset: Bool = false,
        objectKey: COSObjectKey? = nil
    ) {
        var props: [String: PropertyValue] = [
            "baseFont": .string(name),
            "subtype": .string(subtype),
            "isEmbedded": .boolean(isEmbedded),
            "isSubset": .boolean(isSubset)
        ]
        if let encoding = encoding {
            props["encoding"] = .string(encoding)
        }
        self.properties = props
        self.objectKey = objectKey
    }

    func property(named name: String) -> PropertyValue? {
        properties[name]
    }

    var propertyNames: [String] {
        Array(properties.keys)
    }
}

struct MockImageObject: PDFObject, Equatable {
    let id = UUID()
    let objectType = "PDImage"
    let cosObject: COSValue? = nil
    let objectKey: COSObjectKey?

    private let properties: [String: PropertyValue]

    init(
        width: Int = 100,
        height: Int = 100,
        bitsPerComponent: Int = 8,
        colorSpace: String = "DeviceRGB",
        filter: String? = nil,
        objectKey: COSObjectKey? = nil
    ) {
        var props: [String: PropertyValue] = [
            "width": .integer(Int64(width)),
            "height": .integer(Int64(height)),
            "bitsPerComponent": .integer(Int64(bitsPerComponent)),
            "colorSpace": .string(colorSpace)
        ]
        if let filter = filter {
            props["filter"] = .string(filter)
        }
        self.properties = props
        self.objectKey = objectKey
    }

    func property(named name: String) -> PropertyValue? {
        properties[name]
    }

    var propertyNames: [String] {
        Array(properties.keys)
    }
}

struct MockColorSpaceObject: PDFObject, Equatable {
    let id = UUID()
    let objectType = "PDColorSpace"
    let cosObject: COSValue? = nil
    let objectKey: COSObjectKey? = nil

    private let properties: [String: PropertyValue]

    init(name: String = "DeviceRGB", numComponents: Int = 3) {
        self.properties = [
            "name": .string(name),
            "numComponents": .integer(Int64(numComponents))
        ]
    }

    func property(named name: String) -> PropertyValue? {
        properties[name]
    }

    var propertyNames: [String] {
        Array(properties.keys)
    }
}

struct MockAnnotationObject: PDFObject, Equatable {
    let id = UUID()
    let objectType = "PDAnnotation"
    let cosObject: COSValue? = nil
    let objectKey: COSObjectKey? = nil

    private let properties: [String: PropertyValue]

    init(subtype: String = "Link", contents: String? = nil) {
        var props: [String: PropertyValue] = [
            "subtype": .string(subtype),
            "isVisible": .boolean(true),
            "isPrintable": .boolean(true)
        ]
        if let contents = contents {
            props["contents"] = .string(contents)
        }
        self.properties = props
    }

    func property(named name: String) -> PropertyValue? {
        properties[name]
    }

    var propertyNames: [String] {
        Array(properties.keys)
    }
}

struct UnsupportedObject: PDFObject, Equatable {
    let id = UUID()
    let objectType = "UnsupportedType"
    let cosObject: COSValue? = nil

    func property(named name: String) -> PropertyValue? { nil }
    var propertyNames: [String] { [] }
}

// MARK: - FeatureAdapter Protocol Tests

@Suite("FeatureAdapter Protocol Tests")
struct FeatureAdapterProtocolTests {

    @Test("Adapter can extract returns true for supported types")
    func canExtractSupported() {
        let adapter = FontFeatureAdapter()
        let fontObject = MockFontObject()
        #expect(adapter.canExtract(from: fontObject))
    }

    @Test("Adapter can extract returns false for unsupported types")
    func canExtractUnsupported() {
        let adapter = FontFeatureAdapter()
        let unsupported = UnsupportedObject()
        #expect(!adapter.canExtract(from: unsupported))
    }
}

// MARK: - FontFeatureAdapter Tests

@Suite("FontFeatureAdapter Tests")
struct FontFeatureAdapterTests {

    @Test("FontFeatureAdapter has correct feature type")
    func featureType() {
        let adapter = FontFeatureAdapter()
        #expect(adapter.featureType == .font)
    }

    @Test("FontFeatureAdapter supports font object types")
    func supportedTypes() {
        let adapter = FontFeatureAdapter()
        #expect(adapter.supportedObjectTypes.contains("PDFont"))
        #expect(adapter.supportedObjectTypes.contains("Font"))
        #expect(adapter.supportedObjectTypes.contains("TrueTypeFont"))
    }

    @Test("FontFeatureAdapter extracts font properties")
    func extractsFontProperties() throws {
        let adapter = FontFeatureAdapter()
        let fontObject = MockFontObject(
            name: "Helvetica",
            subtype: "TrueType",
            encoding: "WinAnsiEncoding",
            isEmbedded: true,
            isSubset: true
        )

        let node = try adapter.extract(from: fontObject)

        #expect(node.featureType == .font)
        #expect(node.name == "Helvetica")
        #expect(node.stringValue(for: "name") == "Helvetica")
        #expect(node.stringValue(for: "subtype") == "TrueType")
        #expect(node.stringValue(for: "encoding") == "WinAnsiEncoding")
        #expect(node.boolValue(for: "isEmbedded") == true)
        #expect(node.boolValue(for: "isSubset") == true)
    }

    @Test("FontFeatureAdapter throws for unsupported type")
    func throwsForUnsupported() {
        let adapter = FontFeatureAdapter()
        let unsupported = UnsupportedObject()

        #expect(throws: FeatureExtractionError.self) {
            try adapter.extract(from: unsupported)
        }
    }

    @Test("FontFeatureAdapter preserves object key")
    func preservesObjectKey() throws {
        let adapter = FontFeatureAdapter()
        let objectKey = COSObjectKey(objectNumber: 100, generation: 0)
        let fontObject = MockFontObject(objectKey: objectKey)

        let node = try adapter.extract(from: fontObject)
        #expect(node.objectKey == objectKey)
    }

    @Test("FontFeatureAdapter shared instance")
    func sharedInstance() {
        let shared1 = FontFeatureAdapter.shared
        let shared2 = FontFeatureAdapter.shared
        #expect(shared1 === shared2)
    }
}

// MARK: - ImageFeatureAdapter Tests

@Suite("ImageFeatureAdapter Tests")
struct ImageFeatureAdapterTests {

    @Test("ImageFeatureAdapter has correct feature type")
    func featureType() {
        let adapter = ImageFeatureAdapter()
        #expect(adapter.featureType == .image)
    }

    @Test("ImageFeatureAdapter supports image object types")
    func supportedTypes() {
        let adapter = ImageFeatureAdapter()
        #expect(adapter.supportedObjectTypes.contains("PDImage"))
        #expect(adapter.supportedObjectTypes.contains("Image"))
        #expect(adapter.supportedObjectTypes.contains("XObject"))
    }

    @Test("ImageFeatureAdapter extracts image properties")
    func extractsImageProperties() throws {
        let adapter = ImageFeatureAdapter()
        let imageObject = MockImageObject(
            width: 800,
            height: 600,
            bitsPerComponent: 8,
            colorSpace: "DeviceRGB",
            filter: "DCTDecode"
        )

        let node = try adapter.extract(from: imageObject)

        #expect(node.featureType == .image)
        #expect(node.intValue(for: "width") == 800)
        #expect(node.intValue(for: "height") == 600)
        #expect(node.intValue(for: "bitsPerComponent") == 8)
        #expect(node.stringValue(for: "colorSpace") == "DeviceRGB")
        #expect(node.stringValue(for: "filter") == "DCTDecode")
    }

    @Test("ImageFeatureAdapter throws for unsupported type")
    func throwsForUnsupported() {
        let adapter = ImageFeatureAdapter()
        let unsupported = UnsupportedObject()

        #expect(throws: FeatureExtractionError.self) {
            try adapter.extract(from: unsupported)
        }
    }
}

// MARK: - ColorSpaceFeatureAdapter Tests

@Suite("ColorSpaceFeatureAdapter Tests")
struct ColorSpaceFeatureAdapterTests {

    @Test("ColorSpaceFeatureAdapter has correct feature type")
    func featureType() {
        let adapter = ColorSpaceFeatureAdapter()
        #expect(adapter.featureType == .colorSpace)
    }

    @Test("ColorSpaceFeatureAdapter extracts color space properties")
    func extractsColorSpaceProperties() throws {
        let adapter = ColorSpaceFeatureAdapter()
        let csObject = MockColorSpaceObject(name: "ICCBased", numComponents: 4)

        let node = try adapter.extract(from: csObject)

        #expect(node.featureType == .colorSpace)
        #expect(node.name == "ICCBased")
        #expect(node.intValue(for: "numComponents") == 4)
    }
}

// MARK: - AnnotationFeatureAdapter Tests

@Suite("AnnotationFeatureAdapter Tests")
struct AnnotationFeatureAdapterTests {

    @Test("AnnotationFeatureAdapter has correct feature type")
    func featureType() {
        let adapter = AnnotationFeatureAdapter()
        #expect(adapter.featureType == .annotation)
    }

    @Test("AnnotationFeatureAdapter extracts annotation properties")
    func extractsAnnotationProperties() throws {
        let adapter = AnnotationFeatureAdapter()
        let annotObject = MockAnnotationObject(subtype: "Link", contents: "Click here")

        let node = try adapter.extract(from: annotObject)

        #expect(node.featureType == .annotation)
        #expect(node.name == "Link")
        #expect(node.stringValue(for: "subtype") == "Link")
        #expect(node.stringValue(for: "contents") == "Click here")
    }
}

// MARK: - FeatureAdapterRegistry Tests

@Suite("FeatureAdapterRegistry Tests")
struct FeatureAdapterRegistryTests {

    @Test("Registry has default adapters")
    func hasDefaultAdapters() {
        let registry = FeatureAdapterRegistry()

        let fontAdapters = registry.adapters(for: .font)
        #expect(!fontAdapters.isEmpty)

        let imageAdapters = registry.adapters(for: .image)
        #expect(!imageAdapters.isEmpty)

        let csAdapters = registry.adapters(for: .colorSpace)
        #expect(!csAdapters.isEmpty)
    }

    @Test("Registry finds adapter for object")
    func findsAdapterForObject() {
        let registry = FeatureAdapterRegistry()
        let fontObject = MockFontObject()

        let adapter = registry.findAdapter(for: fontObject)
        #expect(adapter != nil)
        #expect(adapter?.featureType == .font)
    }

    @Test("Registry returns nil for unsupported object")
    func returnsNilForUnsupported() {
        let registry = FeatureAdapterRegistry()
        let unsupported = UnsupportedObject()

        let adapter = registry.findAdapter(for: unsupported)
        #expect(adapter == nil)
    }

    @Test("Registry can register custom adapter")
    func registerCustomAdapter() {
        let registry = FeatureAdapterRegistry()

        class CustomAdapter: BaseFeatureAdapter, @unchecked Sendable {
            init() {
                super.init(featureType: .stream, supportedObjectTypes: ["CustomStream"])
            }
        }

        let custom = CustomAdapter()
        registry.register(custom)

        let adapters = registry.adapters(for: .stream)
        #expect(!adapters.isEmpty)
    }

    @Test("Registry lists registered feature types")
    func registeredFeatureTypes() {
        let registry = FeatureAdapterRegistry()
        let types = registry.registeredFeatureTypes

        #expect(types.contains(.font))
        #expect(types.contains(.image))
        #expect(types.contains(.colorSpace))
        #expect(types.contains(.annotation))
    }

    @Test("Registry lists registered object types")
    func registeredObjectTypes() {
        let registry = FeatureAdapterRegistry()
        let types = registry.registeredObjectTypes

        #expect(types.contains("PDFont"))
        #expect(types.contains("PDImage"))
        #expect(types.contains("PDColorSpace"))
        #expect(types.contains("PDAnnotation"))
    }

    @Test("Registry shared instance")
    func sharedInstance() {
        let shared1 = FeatureAdapterRegistry.shared
        let shared2 = FeatureAdapterRegistry.shared
        #expect(shared1 === shared2)
    }
}

// MARK: - FeatureExtractionError Tests

@Suite("FeatureExtractionError Tests")
struct FeatureExtractionErrorTests {

    @Test("Unsupported object type error")
    func unsupportedObjectTypeError() {
        let error = FeatureExtractionError.unsupportedObjectType("Unknown")
        #expect(error.description.contains("Unsupported"))
        #expect(error.description.contains("Unknown"))
    }

    @Test("Missing property error")
    func missingPropertyError() {
        let error = FeatureExtractionError.missingProperty("width")
        #expect(error.description.contains("Missing"))
        #expect(error.description.contains("width"))
    }

    @Test("Invalid property type error")
    func invalidPropertyTypeError() {
        let error = FeatureExtractionError.invalidPropertyType(
            property: "size",
            expected: "Int",
            actual: "String"
        )
        #expect(error.description.contains("Invalid"))
        #expect(error.description.contains("size"))
        #expect(error.description.contains("Int"))
        #expect(error.description.contains("String"))
    }

    @Test("Extraction failed error")
    func extractionFailedError() {
        let error = FeatureExtractionError.extractionFailed("Internal error")
        #expect(error.description.contains("failed"))
        #expect(error.description.contains("Internal error"))
    }

    @Test("Multiple errors")
    func multipleErrors() {
        let errors: [FeatureExtractionError] = [
            .missingProperty("width"),
            .missingProperty("height")
        ]
        let error = FeatureExtractionError.multipleErrors(errors)
        #expect(error.description.contains("Multiple"))
        #expect(error.description.contains("width"))
        #expect(error.description.contains("height"))
    }

    @Test("Errors are equatable")
    func errorsAreEquatable() {
        let error1 = FeatureExtractionError.missingProperty("width")
        let error2 = FeatureExtractionError.missingProperty("width")
        let error3 = FeatureExtractionError.missingProperty("height")

        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}

// MARK: - BaseFeatureAdapter Tests

@Suite("BaseFeatureAdapter Tests")
struct BaseFeatureAdapterTests {

    @Test("Base adapter converts property values")
    func convertsPropertyValues() {
        class TestAdapter: BaseFeatureAdapter, @unchecked Sendable {
            init() {
                super.init(featureType: .object, supportedObjectTypes: ["Test"])
            }
        }

        let adapter = TestAdapter()

        #expect(adapter.convertToFeatureValue(.null) == .null)
        #expect(adapter.convertToFeatureValue(.boolean(true)) == .bool(true))
        #expect(adapter.convertToFeatureValue(.integer(42)) == .int(42))
        #expect(adapter.convertToFeatureValue(.real(3.14)) == .double(3.14))
        #expect(adapter.convertToFeatureValue(.string("test")) == .string("test"))
        #expect(adapter.convertToFeatureValue(.name("Name")) == .string("Name"))
    }

    @Test("Base adapter helper methods")
    func helperMethods() {
        class TestAdapter: BaseFeatureAdapter, @unchecked Sendable {
            init() {
                super.init(featureType: .object, supportedObjectTypes: ["PDFont"])
            }
        }

        let adapter = TestAdapter()
        let fontObject = MockFontObject(name: "Test", isEmbedded: true)

        #expect(adapter.getString("baseFont", from: fontObject) == "Test")
        #expect(adapter.getBool("isEmbedded", from: fontObject) == true)
    }

    @Test("Base adapter require methods throw for missing")
    func requireMethodsThrow() {
        class TestAdapter: BaseFeatureAdapter, @unchecked Sendable {
            init() {
                super.init(featureType: .object, supportedObjectTypes: ["Test"])
            }
        }

        let adapter = TestAdapter()
        let object = UnsupportedObject()

        #expect(throws: FeatureExtractionError.self) {
            _ = try adapter.requireString("missing", from: object)
        }

        #expect(throws: FeatureExtractionError.self) {
            _ = try adapter.requireInt("missing", from: object)
        }
    }
}
