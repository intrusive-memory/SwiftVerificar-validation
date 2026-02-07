import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Test Helper: Concrete PDValidationObject

/// A concrete implementation of PDValidationObject for testing.
struct TestPDValidationObject: PDValidationObject, Equatable {
    let id: UUID
    let cosDictionary: COSValue?
    let objectKey: COSObjectKey?
    let validationContext: ObjectContext
    let isLoaded: Bool
    let parentRef: (any PDValidationObject)?

    var parentObject: (any PDValidationObject)? {
        parentRef
    }

    var objectType: String { "TestPDObject" }

    var propertyNames: [String] { ["testProp"] }

    func property(named name: String) -> PropertyValue? {
        if name == "testProp" { return .string("testValue") }
        return nil
    }

    init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(),
        isLoaded: Bool = true,
        parent: (any PDValidationObject)? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.isLoaded = isLoaded
        self.parentRef = parent
    }

    static func == (lhs: TestPDValidationObject, rhs: TestPDValidationObject) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - PDValidationObject Protocol Tests

@Suite("PDValidationObject Protocol")
struct PDValidationObjectProtocolTests {

    @Test("Protocol requires cosDictionary")
    func protocolRequiresCosDictionary() {
        let dict: COSValue = .dictionary([.type: .name(ASAtom("Page"))])
        let obj = TestPDValidationObject(cosDictionary: dict)
        #expect(obj.cosDictionary != nil)
        #expect(obj.cosDictionary == dict)
    }

    @Test("Protocol provides default cosObject from cosDictionary")
    func defaultCosObject() {
        let dict: COSValue = .dictionary([.type: .name(ASAtom("Page"))])
        let obj = TestPDValidationObject(cosDictionary: dict)
        #expect(obj.cosObject == dict)
    }

    @Test("Protocol provides default nil parentObject")
    func defaultParentObject() {
        let obj = TestPDValidationObject()
        #expect(obj.parentObject == nil)
    }

    @Test("Protocol provides default empty context")
    func defaultContext() {
        let defaultObj = TestPDValidationObject()
        #expect(defaultObj.validationContext.pageNumber == nil)
    }

    @Test("Protocol provides default isLoaded true")
    func defaultIsLoaded() {
        let obj = TestPDValidationObject()
        #expect(obj.isLoaded == true)
    }

    @Test("Custom isLoaded value")
    func customIsLoaded() {
        let obj = TestPDValidationObject(isLoaded: false)
        #expect(obj.isLoaded == false)
    }

    @Test("Parent object can be set")
    func parentObjectSet() {
        let parent = TestPDValidationObject()
        let child = TestPDValidationObject(parent: parent)
        #expect(child.parentObject != nil)
    }
}

// MARK: - Dictionary Access Tests

@Suite("PDValidationObject Dictionary Access")
struct PDValidationObjectDictionaryAccessTests {

    let sampleDict: COSValue = .dictionary([
        ASAtom("Type"): .name(ASAtom("Page")),
        ASAtom("Subtype"): .name(ASAtom("Form")),
        ASAtom("Width"): .integer(612),
        ASAtom("Height"): .real(792.5),
        ASAtom("Title"): .string(COSString(string: "Test Title")),
        ASAtom("Hidden"): .boolean(false),
        ASAtom("Items"): .array([.integer(1), .integer(2), .integer(3)]),
        ASAtom("Inner"): .dictionary([ASAtom("Key"): .name(ASAtom("Value"))])
    ])

    @Test("dictionaryEntry by String key")
    func dictionaryEntryByString() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let entry = obj.dictionaryEntry("Width")
        #expect(entry != nil)
        #expect(entry?.integerValue == 612)
    }

    @Test("dictionaryEntry by ASAtom key")
    func dictionaryEntryByAtom() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let entry = obj.dictionaryEntry(ASAtom("Height"))
        #expect(entry != nil)
        #expect(entry?.numericValue == 792.5)
    }

    @Test("dictionaryEntry for missing key returns nil")
    func dictionaryEntryMissingKey() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let entry = obj.dictionaryEntry("NonExistent")
        #expect(entry == nil)
    }

    @Test("dictionaryEntry when no dictionary returns nil")
    func dictionaryEntryNoDictionary() {
        let obj = TestPDValidationObject()
        let entry = obj.dictionaryEntry("Type")
        #expect(entry == nil)
    }

    @Test("stringValue for key")
    func stringValueForKey() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.stringValue(forKey: "Title")
        #expect(value == "Test Title")
    }

    @Test("stringValue for missing key returns nil")
    func stringValueMissing() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.stringValue(forKey: "Missing")
        #expect(value == nil)
    }

    @Test("intValue for key")
    func intValueForKey() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.intValue(forKey: "Width")
        #expect(value == 612)
    }

    @Test("intValue for non-integer key returns nil")
    func intValueNonInteger() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.intValue(forKey: "Title")
        #expect(value == nil)
    }

    @Test("doubleValue for key")
    func doubleValueForKey() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.doubleValue(forKey: "Height")
        #expect(value == 792.5)
    }

    @Test("doubleValue for integer key converts")
    func doubleValueFromInteger() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.doubleValue(forKey: "Width")
        #expect(value == 612.0)
    }

    @Test("boolValue for key")
    func boolValueForKey() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.boolValue(forKey: "Hidden")
        #expect(value == false)
    }

    @Test("boolValue for non-boolean returns nil")
    func boolValueNonBoolean() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.boolValue(forKey: "Width")
        #expect(value == nil)
    }

    @Test("nameValue for key")
    func nameValueForKey() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.nameValue(forKey: "Type")
        #expect(value == ASAtom("Page"))
    }

    @Test("arrayValue for key")
    func arrayValueForKey() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.arrayValue(forKey: "Items")
        #expect(value?.count == 3)
    }

    @Test("dictValue for key")
    func dictValueForKey() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        let value = obj.dictValue(forKey: "Inner")
        #expect(value?.count == 1)
    }

    @Test("hasEntry returns true for existing key")
    func hasEntryTrue() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        #expect(obj.hasEntry("Type") == true)
    }

    @Test("hasEntry returns false for missing key")
    func hasEntryFalse() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        #expect(obj.hasEntry("Missing") == false)
    }

    @Test("typeEntry property")
    func typeEntryProperty() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        #expect(obj.typeEntry == ASAtom("Page"))
    }

    @Test("subtypeEntry property")
    func subtypeEntryProperty() {
        let obj = TestPDValidationObject(cosDictionary: sampleDict)
        #expect(obj.subtypeEntry == ASAtom("Form"))
    }

    @Test("typeEntry when no Type returns nil")
    func typeEntryNil() {
        let dict: COSValue = .dictionary([ASAtom("Width"): .integer(100)])
        let obj = TestPDValidationObject(cosDictionary: dict)
        #expect(obj.typeEntry == nil)
    }
}

// MARK: - PDObjectType Tests

@Suite("PDObjectType Enum")
struct PDObjectTypeTests {

    @Test("All cases have valid raw values")
    func allCasesHaveRawValues() {
        for caseValue in PDObjectType.allCases {
            #expect(!caseValue.rawValue.isEmpty)
        }
    }

    @Test("CaseIterable returns all cases")
    func caseIterableReturnsAllCases() {
        #expect(PDObjectType.allCases.count == 28)
    }

    @Test("Init from type name")
    func initFromTypeName() {
        let type = PDObjectType(fromType: "Page")
        #expect(type == .page)
    }

    @Test("Init from nil type name returns unknown")
    func initFromNilTypeName() {
        let type = PDObjectType(fromType: nil)
        #expect(type == .unknown)
    }

    @Test("Init from unrecognized type name returns unknown")
    func initFromUnrecognizedTypeName() {
        let type = PDObjectType(fromType: "SomethingWeird")
        #expect(type == .unknown)
    }

    @Test("Init from ASAtom")
    func initFromAtom() {
        let type = PDObjectType(fromAtom: ASAtom("Font"))
        #expect(type == .font)
    }

    @Test("Init from nil ASAtom returns unknown")
    func initFromNilAtom() {
        let type = PDObjectType(fromAtom: nil)
        #expect(type == .unknown)
    }

    @Test("Known type values")
    func knownTypeValues() {
        #expect(PDObjectType.catalog.rawValue == "Catalog")
        #expect(PDObjectType.page.rawValue == "Page")
        #expect(PDObjectType.font.rawValue == "Font")
        #expect(PDObjectType.image.rawValue == "Image")
        #expect(PDObjectType.metadata.rawValue == "Metadata")
        #expect(PDObjectType.structTreeRoot.rawValue == "StructTreeRoot")
        #expect(PDObjectType.structElem.rawValue == "StructElem")
        #expect(PDObjectType.annotation.rawValue == "Annot")
        #expect(PDObjectType.acroForm.rawValue == "AcroForm")
    }
}

// MARK: - LazyPDObject Tests

@Suite("LazyPDObject Property Wrapper")
struct LazyPDObjectTests {

    @Test("Lazy value is not loaded initially")
    func notLoadedInitially() {
        var lazy = LazyPDObject<Int>(wrappedValue: 42)
        #expect(lazy.isLoaded == false)
        _ = lazy.wrappedValue
        #expect(lazy.isLoaded == true)
    }

    @Test("Lazy value returns correct result")
    func returnsCorrectResult() {
        var lazy = LazyPDObject<String>(wrappedValue: "hello")
        #expect(lazy.wrappedValue == "hello")
    }

    @Test("Lazy value is only computed once")
    func computedOnce() {
        var counter = 0
        nonisolated(unsafe) let counterRef = { counter += 1; return counter }
        var lazy = LazyPDObject<Int>(wrappedValue: counterRef())
        let first = lazy.wrappedValue
        let second = lazy.wrappedValue
        #expect(first == second)
    }

    @Test("Lazy value works with arrays")
    func worksWithArrays() {
        var lazy = LazyPDObject<[Int]>(wrappedValue: [1, 2, 3])
        #expect(lazy.wrappedValue.count == 3)
    }
}

// MARK: - ResourceResolver Tests

@Suite("ResourceResolver Protocol")
struct ResourceResolverTests {

    struct MockResourceResolver: ResourceResolver {
        let fonts: [ASAtom: COSValue]
        let xObjects: [ASAtom: COSValue]
        let colorSpaces: [ASAtom: COSValue]
        let extGStates: [ASAtom: COSValue]
        let patterns: [ASAtom: COSValue]
        let shadings: [ASAtom: COSValue]
        let properties: [ASAtom: COSValue]

        init(
            fonts: [ASAtom: COSValue] = [:],
            xObjects: [ASAtom: COSValue] = [:],
            colorSpaces: [ASAtom: COSValue] = [:],
            extGStates: [ASAtom: COSValue] = [:],
            patterns: [ASAtom: COSValue] = [:],
            shadings: [ASAtom: COSValue] = [:],
            properties: [ASAtom: COSValue] = [:]
        ) {
            self.fonts = fonts
            self.xObjects = xObjects
            self.colorSpaces = colorSpaces
            self.extGStates = extGStates
            self.patterns = patterns
            self.shadings = shadings
            self.properties = properties
        }

        func resolveFont(named name: ASAtom) -> COSValue? { fonts[name] }
        func resolveXObject(named name: ASAtom) -> COSValue? { xObjects[name] }
        func resolveColorSpace(named name: ASAtom) -> COSValue? { colorSpaces[name] }
        func resolveExtGState(named name: ASAtom) -> COSValue? { extGStates[name] }
        func resolvePattern(named name: ASAtom) -> COSValue? { patterns[name] }
        func resolveShading(named name: ASAtom) -> COSValue? { shadings[name] }
        func resolveProperties(named name: ASAtom) -> COSValue? { properties[name] }
    }

    @Test("Resolve existing font")
    func resolveExistingFont() {
        let fontDict: COSValue = .dictionary([.type: .name(.font)])
        let resolver = MockResourceResolver(fonts: [ASAtom("F1"): fontDict])
        #expect(resolver.resolveFont(named: ASAtom("F1")) != nil)
    }

    @Test("Resolve missing font returns nil")
    func resolveMissingFont() {
        let resolver = MockResourceResolver()
        #expect(resolver.resolveFont(named: ASAtom("F1")) == nil)
    }

    @Test("Resolve XObject")
    func resolveXObject() {
        let xObj: COSValue = .dictionary([.subtype: .name(ASAtom("Image"))])
        let resolver = MockResourceResolver(xObjects: [ASAtom("Im1"): xObj])
        #expect(resolver.resolveXObject(named: ASAtom("Im1")) != nil)
    }

    @Test("Resolve color space")
    func resolveColorSpace() {
        let cs: COSValue = .name(ASAtom("DeviceRGB"))
        let resolver = MockResourceResolver(colorSpaces: [ASAtom("CS1"): cs])
        #expect(resolver.resolveColorSpace(named: ASAtom("CS1")) != nil)
    }

    @Test("Resolve ExtGState")
    func resolveExtGState() {
        let gs: COSValue = .dictionary([:])
        let resolver = MockResourceResolver(extGStates: [ASAtom("GS1"): gs])
        #expect(resolver.resolveExtGState(named: ASAtom("GS1")) != nil)
    }

    @Test("Resolve pattern")
    func resolvePattern() {
        let pat: COSValue = .dictionary([:])
        let resolver = MockResourceResolver(patterns: [ASAtom("P1"): pat])
        #expect(resolver.resolvePattern(named: ASAtom("P1")) != nil)
    }

    @Test("Resolve shading")
    func resolveShading() {
        let shading: COSValue = .dictionary([:])
        let resolver = MockResourceResolver(shadings: [ASAtom("Sh1"): shading])
        #expect(resolver.resolveShading(named: ASAtom("Sh1")) != nil)
    }

    @Test("Resolve properties")
    func resolveProperties() {
        let props: COSValue = .dictionary([:])
        let resolver = MockResourceResolver(properties: [ASAtom("MC0"): props])
        #expect(resolver.resolveProperties(named: ASAtom("MC0")) != nil)
    }
}

// MARK: - ResourceType Tests

@Suite("ResourceType Enum")
struct ResourceTypeTests {

    @Test("All cases have raw values")
    func allCasesHaveRawValues() {
        for caseValue in ResourceType.allCases {
            #expect(!caseValue.rawValue.isEmpty)
        }
    }

    @Test("CaseIterable count")
    func caseIterableCount() {
        #expect(ResourceType.allCases.count == 9)
    }

    @Test("Init from known key")
    func initFromKnownKey() {
        #expect(ResourceType(fromKey: "Font") == .font)
        #expect(ResourceType(fromKey: "XObject") == .xObject)
        #expect(ResourceType(fromKey: "ColorSpace") == .colorSpace)
        #expect(ResourceType(fromKey: "ExtGState") == .extGState)
        #expect(ResourceType(fromKey: "Pattern") == .pattern)
        #expect(ResourceType(fromKey: "Shading") == .shading)
        #expect(ResourceType(fromKey: "Properties") == .properties)
        #expect(ResourceType(fromKey: "ProcSet") == .procSet)
    }

    @Test("Init from unknown key")
    func initFromUnknownKey() {
        #expect(ResourceType(fromKey: "Something") == .unknown)
    }
}
