import Testing
import Foundation
@testable import SwiftVerificarValidation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Mock PDF Object

struct MockPDFObject: PDFObject, Equatable {
    let id = UUID()
    let objectType: String
    let cosObject: COSValue?
    let objectKey: COSObjectKey?
    let properties: [String: PropertyValue]

    init(
        objectType: String,
        cosObject: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        properties: [String: PropertyValue] = [:]
    ) {
        self.objectType = objectType
        self.cosObject = cosObject
        self.objectKey = objectKey
        self.properties = properties
    }

    func property(named name: String) -> PropertyValue? {
        properties[name]
    }

    var propertyNames: [String] {
        Array(properties.keys).sorted()
    }

    static func == (lhs: MockPDFObject, rhs: MockPDFObject) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Property Value Tests

@Suite("PropertyValue Tests")
struct PropertyValueTests {

    @Test("PropertyValue null type checking")
    func nullTypeChecking() {
        let value = PropertyValue.null
        #expect(value.isNull)
        #expect(!value.isBoolean)
        #expect(!value.isInteger)
        #expect(!value.isReal)
        #expect(!value.isString)
        #expect(!value.isName)
        #expect(!value.isObject)
        #expect(!value.isObjectArray)
    }

    @Test("PropertyValue boolean type checking")
    func booleanTypeChecking() {
        let value = PropertyValue.boolean(true)
        #expect(!value.isNull)
        #expect(value.isBoolean)
        #expect(value.boolValue == true)
    }

    @Test("PropertyValue integer type checking")
    func integerTypeChecking() {
        let value = PropertyValue.integer(42)
        #expect(value.isInteger)
        #expect(value.integerValue == 42)
        #expect(value.numericValue == 42.0)
    }

    @Test("PropertyValue real type checking")
    func realTypeChecking() {
        let value = PropertyValue.real(3.14)
        #expect(value.isReal)
        #expect(value.realValue == 3.14)
        #expect(value.numericValue == 3.14)
    }

    @Test("PropertyValue string type checking")
    func stringTypeChecking() {
        let value = PropertyValue.string("Hello")
        #expect(value.isString)
        #expect(value.stringValue == "Hello")
    }

    @Test("PropertyValue name type checking")
    func nameTypeChecking() {
        let value = PropertyValue.name("Type")
        #expect(value.isName)
        #expect(value.stringValue == "Type")
    }

    @Test("PropertyValue object type checking")
    func objectTypeChecking() {
        let obj = MockPDFObject(objectType: "TestObject")
        let value = PropertyValue.object(AnyPDFObject(obj))
        #expect(value.isObject)
        #expect(value.objectValue != nil)
    }

    @Test("PropertyValue object array type checking")
    func objectArrayTypeChecking() {
        let obj1 = MockPDFObject(objectType: "Object1")
        let obj2 = MockPDFObject(objectType: "Object2")
        let value = PropertyValue.objectArray([AnyPDFObject(obj1), AnyPDFObject(obj2)])
        #expect(value.isObjectArray)
        #expect(value.objectArrayValue?.count == 2)
    }

    @Test("PropertyValue equality")
    func propertyValueEquality() {
        let int1 = PropertyValue.integer(42)
        let int2 = PropertyValue.integer(42)
        let int3 = PropertyValue.integer(43)

        #expect(int1 == int2)
        #expect(int1 != int3)

        let str1 = PropertyValue.string("hello")
        let str2 = PropertyValue.string("hello")
        let str3 = PropertyValue.string("world")

        #expect(str1 == str2)
        #expect(str1 != str3)
    }

    @Test("PropertyValue numeric conversion")
    func numericConversion() {
        let intValue = PropertyValue.integer(42)
        #expect(intValue.numericValue == 42.0)

        let realValue = PropertyValue.real(3.14)
        #expect(realValue.numericValue == 3.14)

        let stringValue = PropertyValue.string("not a number")
        #expect(stringValue.numericValue == nil)
    }
}

// MARK: - AnyPDFObject Tests

@Suite("AnyPDFObject Tests")
struct AnyPDFObjectTests {

    @Test("AnyPDFObject wraps concrete object")
    func wrapsConcreteObject() {
        let mockObject = MockPDFObject(
            objectType: "TestObject",
            properties: ["name": .string("test")]
        )

        let anyObject = AnyPDFObject(mockObject)

        #expect(anyObject.objectType == "TestObject")
        #expect(anyObject.property(named: "name") == .string("test"))
        #expect(anyObject.propertyNames == ["name"])
    }

    @Test("AnyPDFObject preserves COS object")
    func preservesCOSObject() {
        let cosDict: COSValue = .dictionary([.type: .name(.page)])
        let mockObject = MockPDFObject(objectType: "Page", cosObject: cosDict)

        let anyObject = AnyPDFObject(mockObject)

        #expect(anyObject.cosObject != nil)
        #expect(anyObject.cosObject?.isDictionary == true)
    }

    @Test("AnyPDFObject preserves object key")
    func preservesObjectKey() {
        let objectKey = COSObjectKey(objectNumber: 42, generation: 0)
        let mockObject = MockPDFObject(objectType: "Font", objectKey: objectKey)

        let anyObject = AnyPDFObject(mockObject)

        #expect(anyObject.objectKey == objectKey)
    }

    @Test("AnyPDFObject equality")
    func equality() {
        let mockObject1 = MockPDFObject(objectType: "Object1")
        let mockObject2 = MockPDFObject(objectType: "Object2")

        let anyObject1a = AnyPDFObject(mockObject1)
        let anyObject1b = AnyPDFObject(mockObject1)
        let anyObject2 = AnyPDFObject(mockObject2)

        #expect(anyObject1a == anyObject1b)
        #expect(anyObject1a != anyObject2)
    }

    @Test("AnyPDFObject with multiple properties")
    func multipleProperties() {
        let mockObject = MockPDFObject(
            objectType: "ComplexObject",
            properties: [
                "name": .string("test"),
                "count": .integer(42),
                "ratio": .real(3.14),
                "enabled": .boolean(true)
            ]
        )

        let anyObject = AnyPDFObject(mockObject)

        #expect(anyObject.property(named: "name") == .string("test"))
        #expect(anyObject.property(named: "count") == .integer(42))
        #expect(anyObject.property(named: "ratio") == .real(3.14))
        #expect(anyObject.property(named: "enabled") == .boolean(true))
        #expect(anyObject.propertyNames.count == 4)
    }
}

// MARK: - PDFObject Protocol Tests

@Suite("PDFObject Protocol Tests")
struct PDFObjectProtocolTests {

    @Test("PDFObject default object key is nil")
    func defaultObjectKeyIsNil() {
        let mockObject = MockPDFObject(objectType: "TestObject")
        #expect(mockObject.objectKey == nil)
    }

    @Test("PDFObject default property names is empty")
    func defaultPropertyNamesIsEmpty() {
        struct MinimalObject: PDFObject, Equatable {
            let id = UUID()
            let objectType = "Minimal"
            let cosObject: COSValue? = nil

            func property(named name: String) -> PropertyValue? {
                nil
            }
        }

        let obj = MinimalObject()
        #expect(obj.propertyNames.isEmpty)
    }

    @Test("PDFObject can have custom object key")
    func customObjectKey() {
        let key = COSObjectKey(objectNumber: 123, generation: 1)
        let mockObject = MockPDFObject(objectType: "IndirectObject", objectKey: key)

        #expect(mockObject.objectKey == key)
    }

    @Test("PDFObject property access")
    func propertyAccess() {
        let mockObject = MockPDFObject(
            objectType: "PropertyTest",
            properties: [
                "name": .string("value"),
                "missing": .null
            ]
        )

        #expect(mockObject.property(named: "name") == .string("value"))
        #expect(mockObject.property(named: "missing") == .null)
        #expect(mockObject.property(named: "nonexistent") == nil)
    }
}

// MARK: - CosValidationObject Tests

@Suite("CosValidationObject Tests")
struct CosValidationObjectTests {

    @Test("CosValidationObject wraps null")
    func wrapsNull() {
        let obj = CosValidationObject(cosValue: .null)
        #expect(obj.objectType == "CosNull")
        #expect(obj.cosObject?.isNull == true)
    }

    @Test("CosValidationObject wraps boolean")
    func wrapsBoolean() {
        let obj = CosValidationObject(cosValue: .boolean(true))
        #expect(obj.objectType == "CosBoolean")
        #expect(obj.cosObject?.boolValue == true)
    }

    @Test("CosValidationObject wraps integer")
    func wrapsInteger() {
        let obj = CosValidationObject(cosValue: .integer(42))
        #expect(obj.objectType == "CosInteger")
        #expect(obj.cosObject?.integerValue == 42)
    }

    @Test("CosValidationObject wraps real")
    func wrapsReal() {
        let obj = CosValidationObject(cosValue: .real(3.14))
        #expect(obj.objectType == "CosReal")
        #expect(obj.cosObject?.realValue == 3.14)
    }

    @Test("CosValidationObject wraps string")
    func wrapsString() {
        let cosString = COSString(string: "Hello")
        let obj = CosValidationObject(cosValue: .string(cosString))
        #expect(obj.objectType == "CosString")
        #expect(obj.cosObject?.isString == true)
    }

    @Test("CosValidationObject wraps name")
    func wrapsName() {
        let obj = CosValidationObject(cosValue: .name(.type))
        #expect(obj.objectType == "CosName")
        #expect(obj.cosObject?.nameValue == .type)
    }

    @Test("CosValidationObject wraps array")
    func wrapsArray() {
        let obj = CosValidationObject(cosValue: .array([.integer(1), .integer(2)]))
        #expect(obj.objectType == "CosArray")
        #expect(obj.cosObject?.arrayValue?.count == 2)
    }

    @Test("CosValidationObject wraps dictionary")
    func wrapsDictionary() {
        let obj = CosValidationObject(cosValue: .dictionary([.type: .name(.page)]))
        #expect(obj.objectType == "CosDict")
        #expect(obj.cosObject?.isDictionary == true)
    }

    @Test("CosValidationObject wraps reference")
    func wrapsReference() {
        let ref = COSReference(objectNumber: 10, generation: 0)
        let obj = CosValidationObject(cosValue: .reference(ref))
        #expect(obj.objectType == "CosReference")
        #expect(obj.cosObject?.isReference == true)
    }

    @Test("CosValidationObject size property for dictionary")
    func sizePropertyForDictionary() {
        let dict: COSValue = .dictionary([.type: .name(.page), .parent: .null])
        let obj = CosValidationObject(cosValue: dict)

        let sizeValue = obj.property(named: "size")
        #expect(sizeValue == .integer(2))
    }

    @Test("CosValidationObject size property for array")
    func sizePropertyForArray() {
        let array: COSValue = .array([.integer(1), .integer(2), .integer(3)])
        let obj = CosValidationObject(cosValue: array)

        let sizeValue = obj.property(named: "size")
        #expect(sizeValue == .integer(3))
    }

    @Test("CosValidationObject type property")
    func typeProperty() {
        let dict: COSValue = .dictionary([.type: .name(.page)])
        let obj = CosValidationObject(cosValue: dict)

        let typeValue = obj.property(named: "type")
        #expect(typeValue == .name("Page"))
    }

    @Test("CosValidationObject subtype property")
    func subtypeProperty() {
        let dict: COSValue = .dictionary([.subtype: .name(.image)])
        let obj = CosValidationObject(cosValue: dict)

        let subtypeValue = obj.property(named: "subtype")
        #expect(subtypeValue == .name("Image"))
    }

    @Test("CosValidationObject type checking properties")
    func typeCheckingProperties() {
        let obj = CosValidationObject(cosValue: .integer(42))

        #expect(obj.property(named: "isInteger") == .boolean(true))
        #expect(obj.property(named: "isBoolean") == .boolean(false))
        #expect(obj.property(named: "isNumeric") == .boolean(true))
        #expect(obj.property(named: "isString") == .boolean(false))
    }

    @Test("CosValidationObject property names")
    func propertyNames() {
        let obj = CosValidationObject(cosValue: .integer(42))
        let names = obj.propertyNames

        #expect(names.contains("size"))
        #expect(names.contains("type"))
        #expect(names.contains("subtype"))
        #expect(names.contains("isInteger"))
        #expect(names.contains("isBoolean"))
        #expect(names.contains("isDictionary"))
        #expect(names.count > 10)
    }

    @Test("CosValidationObject with object key")
    func withObjectKey() {
        let key = COSObjectKey(objectNumber: 42, generation: 0)
        let obj = CosValidationObject(cosValue: .integer(100), objectKey: key)

        #expect(obj.objectKey == key)
    }

    @Test("CosValidationObject equality")
    func equality() {
        let obj1 = CosValidationObject(cosValue: .integer(42))
        let obj2 = CosValidationObject(cosValue: .integer(42))

        // Different instances should have different IDs
        #expect(obj1 != obj2)
    }
}
