import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Mock Objects for Testing

struct PropertyTestObject: PDFObject, Equatable {
    let id = UUID()
    let objectType = "PropertyTest"
    let cosObject: COSValue? = nil

    let properties: [String: PropertyValue]

    init(properties: [String: PropertyValue] = [:]) {
        self.properties = properties
    }

    func property(named name: String) -> PropertyValue? {
        properties[name]
    }

    var propertyNames: [String] {
        Array(properties.keys).sorted()
    }

    static func == (lhs: PropertyTestObject, rhs: PropertyTestObject) -> Bool {
        lhs.id == rhs.id
    }
}

struct NestedPropertyObject: PDFObject, Equatable {
    let id = UUID()
    let objectType = "NestedPropertyTest"
    let cosObject: COSValue? = nil

    let childObject: AnyPDFObject?

    init(childObject: AnyPDFObject? = nil) {
        self.childObject = childObject
    }

    func property(named name: String) -> PropertyValue? {
        if name == "child", let child = childObject {
            return .object(child)
        }
        return nil
    }

    var propertyNames: [String] {
        childObject != nil ? ["child"] : []
    }

    static func == (lhs: NestedPropertyObject, rhs: NestedPropertyObject) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - PropertyAccessor Basic Tests

@Suite("PropertyAccessor Basic Tests")
struct PropertyAccessorBasicTests {

    @Test("PropertyAccessor accesses simple property")
    func accessSimpleProperty() {
        let obj = PropertyTestObject(properties: [
            "name": .string("TestObject")
        ])
        let accessor = PropertyAccessor(object: obj)

        let value = accessor.value(forPath: "name")
        #expect(value == .string("TestObject"))
    }

    @Test("PropertyAccessor returns nil for missing property")
    func returnNilForMissingProperty() {
        let obj = PropertyTestObject(properties: [:])
        let accessor = PropertyAccessor(object: obj)

        let value = accessor.value(forPath: "missing")
        #expect(value == nil)
    }

    @Test("PropertyAccessor accesses boolean property")
    func accessBooleanProperty() {
        let obj = PropertyTestObject(properties: [
            "enabled": .boolean(true)
        ])
        let accessor = PropertyAccessor(object: obj)

        let value = accessor.value(forPath: "enabled")
        #expect(value == .boolean(true))
    }

    @Test("PropertyAccessor accesses integer property")
    func accessIntegerProperty() {
        let obj = PropertyTestObject(properties: [
            "count": .integer(42)
        ])
        let accessor = PropertyAccessor(object: obj)

        let value = accessor.value(forPath: "count")
        #expect(value == .integer(42))
    }

    @Test("PropertyAccessor accesses real property")
    func accessRealProperty() {
        let obj = PropertyTestObject(properties: [
            "ratio": .real(3.14)
        ])
        let accessor = PropertyAccessor(object: obj)

        let value = accessor.value(forPath: "ratio")
        #expect(value == .real(3.14))
    }

    @Test("PropertyAccessor accesses name property")
    func accessNameProperty() {
        let obj = PropertyTestObject(properties: [
            "type": .name("Font")
        ])
        let accessor = PropertyAccessor(object: obj)

        let value = accessor.value(forPath: "type")
        #expect(value == .name("Font"))
    }

    @Test("PropertyAccessor accesses null property")
    func accessNullProperty() {
        let obj = PropertyTestObject(properties: [
            "empty": .null
        ])
        let accessor = PropertyAccessor(object: obj)

        let value = accessor.value(forPath: "empty")
        #expect(value == .null)
    }
}

// MARK: - PropertyAccessor Nested Path Tests

@Suite("PropertyAccessor Nested Path Tests")
struct PropertyAccessorNestedPathTests {

    @Test("PropertyAccessor accesses nested property")
    func accessNestedProperty() {
        let childObj = PropertyTestObject(properties: [
            "name": .string("ChildObject")
        ])

        let parentObj = NestedPropertyObject(childObject: AnyPDFObject(childObj))
        let accessor = PropertyAccessor(object: parentObj)

        let value = accessor.value(forPath: "child.name")
        #expect(value == .string("ChildObject"))
    }

    @Test("PropertyAccessor returns nil for invalid nested path")
    func returnNilForInvalidNestedPath() {
        let childObj = PropertyTestObject(properties: [:])
        let parentObj = NestedPropertyObject(childObject: AnyPDFObject(childObj))
        let accessor = PropertyAccessor(object: parentObj)

        let value = accessor.value(forPath: "child.missing")
        #expect(value == nil)
    }

    @Test("PropertyAccessor handles deeply nested paths")
    func handleDeeplyNestedPaths() {
        let grandchildObj = PropertyTestObject(properties: [
            "value": .integer(100)
        ])

        let childObj = NestedPropertyObject(childObject: AnyPDFObject(grandchildObj))
        let parentObj = NestedPropertyObject(childObject: AnyPDFObject(childObj))
        let accessor = PropertyAccessor(object: parentObj)

        let value = accessor.value(forPath: "child.child.value")
        #expect(value == .integer(100))
    }

    @Test("PropertyAccessor stops at primitive values in path")
    func stopsAtPrimitiveValues() {
        let obj = PropertyTestObject(properties: [
            "name": .string("test")
        ])
        let accessor = PropertyAccessor(object: obj)

        // Can't navigate into a string
        let value = accessor.value(forPath: "name.invalid")
        #expect(value == nil)
    }
}

// MARK: - PropertyAccessor Type Conversion Tests

@Suite("PropertyAccessor Type Conversion Tests")
struct PropertyAccessorTypeConversionTests {

    @Test("boolValue extracts boolean")
    func boolValueExtractsBoolean() {
        let obj = PropertyTestObject(properties: [
            "enabled": .boolean(true)
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.boolValue(forPath: "enabled") == true)
    }

    @Test("boolValue returns nil for non-boolean")
    func boolValueReturnsNilForNonBoolean() {
        let obj = PropertyTestObject(properties: [
            "count": .integer(42)
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.boolValue(forPath: "count") == nil)
    }

    @Test("integerValue extracts integer")
    func integerValueExtractsInteger() {
        let obj = PropertyTestObject(properties: [
            "count": .integer(42)
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.integerValue(forPath: "count") == 42)
    }

    @Test("integerValue returns nil for non-integer")
    func integerValueReturnsNilForNonInteger() {
        let obj = PropertyTestObject(properties: [
            "name": .string("test")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.integerValue(forPath: "name") == nil)
    }

    @Test("realValue extracts real")
    func realValueExtractsReal() {
        let obj = PropertyTestObject(properties: [
            "ratio": .real(3.14)
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.realValue(forPath: "ratio") == 3.14)
    }

    @Test("numericValue converts integer to double")
    func numericValueConvertsInteger() {
        let obj = PropertyTestObject(properties: [
            "count": .integer(42)
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.numericValue(forPath: "count") == 42.0)
    }

    @Test("numericValue extracts real directly")
    func numericValueExtractsReal() {
        let obj = PropertyTestObject(properties: [
            "ratio": .real(3.14)
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.numericValue(forPath: "ratio") == 3.14)
    }

    @Test("stringValue extracts string")
    func stringValueExtractsString() {
        let obj = PropertyTestObject(properties: [
            "name": .string("test")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.stringValue(forPath: "name") == "test")
    }

    @Test("stringValue extracts name as string")
    func stringValueExtractsName() {
        let obj = PropertyTestObject(properties: [
            "type": .name("Font")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.stringValue(forPath: "type") == "Font")
    }

    @Test("objectValue extracts object")
    func objectValueExtractsObject() {
        let childObj = PropertyTestObject(properties: [:])
        let parentObj = NestedPropertyObject(childObject: AnyPDFObject(childObj))
        let accessor = PropertyAccessor(object: parentObj)

        let value = accessor.objectValue(forPath: "child")
        #expect(value != nil)
    }

    @Test("objectArrayValue extracts array")
    func objectArrayValueExtractsArray() {
        let obj1 = PropertyTestObject(properties: [:])
        let obj2 = PropertyTestObject(properties: [:])

        let containerObj = PropertyTestObject(properties: [
            "children": .objectArray([AnyPDFObject(obj1), AnyPDFObject(obj2)])
        ])
        let accessor = PropertyAccessor(object: containerObj)

        let value = accessor.objectArrayValue(forPath: "children")
        #expect(value?.count == 2)
    }
}

// MARK: - PropertyAccessor Existence Checking Tests

@Suite("PropertyAccessor Existence Checking Tests")
struct PropertyAccessorExistenceCheckingTests {

    @Test("hasProperty returns true for existing property")
    func hasPropertyReturnsTrueForExisting() {
        let obj = PropertyTestObject(properties: [
            "name": .string("test")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasProperty("name") == true)
    }

    @Test("hasProperty returns false for missing property")
    func hasPropertyReturnsFalseForMissing() {
        let obj = PropertyTestObject(properties: [:])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasProperty("missing") == false)
    }

    @Test("hasNonNullValue returns true for non-null")
    func hasNonNullValueReturnsTrueForNonNull() {
        let obj = PropertyTestObject(properties: [
            "name": .string("test")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasNonNullValue("name") == true)
    }

    @Test("hasNonNullValue returns false for null")
    func hasNonNullValueReturnsFalseForNull() {
        let obj = PropertyTestObject(properties: [
            "empty": .null
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasNonNullValue("empty") == false)
    }

    @Test("hasNonNullValue returns false for missing")
    func hasNonNullValueReturnsFalseForMissing() {
        let obj = PropertyTestObject(properties: [:])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasNonNullValue("missing") == false)
    }
}

// MARK: - PropertyAccessor Collection Operations Tests

@Suite("PropertyAccessor Collection Operations Tests")
struct PropertyAccessorCollectionOperationsTests {

    @Test("count returns array length")
    func countReturnsArrayLength() {
        let obj1 = PropertyTestObject(properties: [:])
        let obj2 = PropertyTestObject(properties: [:])
        let obj3 = PropertyTestObject(properties: [:])

        let containerObj = PropertyTestObject(properties: [
            "items": .objectArray([AnyPDFObject(obj1), AnyPDFObject(obj2), AnyPDFObject(obj3)])
        ])
        let accessor = PropertyAccessor(object: containerObj)

        #expect(accessor.count(forPath: "items") == 3)
    }

    @Test("count returns zero for missing array")
    func countReturnsZeroForMissing() {
        let obj = PropertyTestObject(properties: [:])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.count(forPath: "items") == 0)
    }

    @Test("count returns zero for non-array")
    func countReturnsZeroForNonArray() {
        let obj = PropertyTestObject(properties: [
            "name": .string("test")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.count(forPath: "name") == 0)
    }

    @Test("isEmpty returns true for empty array")
    func isEmptyReturnsTrueForEmptyArray() {
        let obj = PropertyTestObject(properties: [
            "items": .objectArray([])
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.isEmpty(forPath: "items") == true)
    }

    @Test("isEmpty returns false for non-empty array")
    func isEmptyReturnsFalseForNonEmptyArray() {
        let obj1 = PropertyTestObject(properties: [:])
        let containerObj = PropertyTestObject(properties: [
            "items": .objectArray([AnyPDFObject(obj1)])
        ])
        let accessor = PropertyAccessor(object: containerObj)

        #expect(accessor.isEmpty(forPath: "items") == false)
    }

    @Test("hasElements returns true for non-empty array")
    func hasElementsReturnsTrueForNonEmptyArray() {
        let obj1 = PropertyTestObject(properties: [:])
        let containerObj = PropertyTestObject(properties: [
            "items": .objectArray([AnyPDFObject(obj1)])
        ])
        let accessor = PropertyAccessor(object: containerObj)

        #expect(accessor.hasElements(forPath: "items") == true)
    }

    @Test("hasElements returns false for empty array")
    func hasElementsReturnsFalseForEmptyArray() {
        let obj = PropertyTestObject(properties: [
            "items": .objectArray([])
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasElements(forPath: "items") == false)
    }
}

// MARK: - PropertyAccessor Comparison Operations Tests

@Suite("PropertyAccessor Comparison Operations Tests")
struct PropertyAccessorComparisonOperationsTests {

    @Test("compare numeric property")
    func compareNumericProperty() {
        let obj = PropertyTestObject(properties: [
            "value": .real(5.0)
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.compare(path: "value", to: 3.0) == .orderedDescending)
        #expect(accessor.compare(path: "value", to: 5.0) == .orderedSame)
        #expect(accessor.compare(path: "value", to: 7.0) == .orderedAscending)
    }

    @Test("compare returns nil for non-numeric")
    func compareReturnsNilForNonNumeric() {
        let obj = PropertyTestObject(properties: [
            "name": .string("test")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.compare(path: "name", to: 5.0) == nil)
    }

    @Test("equals numeric property with tolerance")
    func equalsNumericPropertyWithTolerance() {
        let obj = PropertyTestObject(properties: [
            "value": .real(3.14159)
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.equals(path: "value", value: 3.14159) == true)
        #expect(accessor.equals(path: "value", value: 3.14160, tolerance: 0.0001) == true)
        #expect(accessor.equals(path: "value", value: 3.15, tolerance: 0.001) == false)
    }

    @Test("equals string property case sensitive")
    func equalsStringPropertyCaseSensitive() {
        let obj = PropertyTestObject(properties: [
            "name": .string("Test")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.equals(path: "name", value: "Test", caseSensitive: true) == true)
        #expect(accessor.equals(path: "name", value: "test", caseSensitive: true) == false)
    }

    @Test("equals string property case insensitive")
    func equalsStringPropertyCaseInsensitive() {
        let obj = PropertyTestObject(properties: [
            "name": .string("Test")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.equals(path: "name", value: "test", caseSensitive: false) == true)
        #expect(accessor.equals(path: "name", value: "TEST", caseSensitive: false) == true)
        #expect(accessor.equals(path: "name", value: "Other", caseSensitive: false) == false)
    }

    @Test("equals boolean property")
    func equalsBooleanProperty() {
        let obj = PropertyTestObject(properties: [
            "enabled": .boolean(true)
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.equals(path: "enabled", value: true) == true)
        #expect(accessor.equals(path: "enabled", value: false) == false)
    }
}

// MARK: - PropertyAccessor String Operations Tests

@Suite("PropertyAccessor String Operations Tests")
struct PropertyAccessorStringOperationsTests {

    @Test("contains checks substring case sensitive")
    func containsCheckSubstringCaseSensitive() {
        let obj = PropertyTestObject(properties: [
            "text": .string("Hello World")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.contains(path: "text", substring: "World", caseSensitive: true) == true)
        #expect(accessor.contains(path: "text", substring: "world", caseSensitive: true) == false)
        #expect(accessor.contains(path: "text", substring: "Missing", caseSensitive: true) == false)
    }

    @Test("contains checks substring case insensitive")
    func containsCheckSubstringCaseInsensitive() {
        let obj = PropertyTestObject(properties: [
            "text": .string("Hello World")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.contains(path: "text", substring: "world", caseSensitive: false) == true)
        #expect(accessor.contains(path: "text", substring: "HELLO", caseSensitive: false) == true)
    }

    @Test("hasPrefix checks prefix case sensitive")
    func hasPrefixCheckPrefixCaseSensitive() {
        let obj = PropertyTestObject(properties: [
            "name": .string("HelloWorld")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasPrefix(path: "name", prefix: "Hello", caseSensitive: true) == true)
        #expect(accessor.hasPrefix(path: "name", prefix: "hello", caseSensitive: true) == false)
        #expect(accessor.hasPrefix(path: "name", prefix: "World", caseSensitive: true) == false)
    }

    @Test("hasPrefix checks prefix case insensitive")
    func hasPrefixCheckPrefixCaseInsensitive() {
        let obj = PropertyTestObject(properties: [
            "name": .string("HelloWorld")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasPrefix(path: "name", prefix: "hello", caseSensitive: false) == true)
        #expect(accessor.hasPrefix(path: "name", prefix: "HELLO", caseSensitive: false) == true)
    }

    @Test("hasSuffix checks suffix case sensitive")
    func hasSuffixCheckSuffixCaseSensitive() {
        let obj = PropertyTestObject(properties: [
            "filename": .string("document.pdf")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasSuffix(path: "filename", suffix: ".pdf", caseSensitive: true) == true)
        #expect(accessor.hasSuffix(path: "filename", suffix: ".PDF", caseSensitive: true) == false)
        #expect(accessor.hasSuffix(path: "filename", suffix: ".doc", caseSensitive: true) == false)
    }

    @Test("hasSuffix checks suffix case insensitive")
    func hasSuffixCheckSuffixCaseInsensitive() {
        let obj = PropertyTestObject(properties: [
            "filename": .string("document.pdf")
        ])
        let accessor = PropertyAccessor(object: obj)

        #expect(accessor.hasSuffix(path: "filename", suffix: ".PDF", caseSensitive: false) == true)
        #expect(accessor.hasSuffix(path: "filename", suffix: ".pdf", caseSensitive: false) == true)
    }
}
