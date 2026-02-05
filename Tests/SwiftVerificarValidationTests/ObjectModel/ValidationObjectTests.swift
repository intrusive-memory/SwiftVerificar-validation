import Testing
import Foundation
@testable import SwiftVerificarValidation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Mock Objects

struct SimpleMockObject: PDFObject, Equatable {
    let id = UUID()
    let objectType: String
    let cosObject: COSValue?

    init(objectType: String, cosObject: COSValue? = nil) {
        self.objectType = objectType
        self.cosObject = cosObject
    }

    func property(named name: String) -> PropertyValue? {
        switch name {
        case "name":
            return .string(objectType)
        default:
            return nil
        }
    }

    var propertyNames: [String] {
        ["name"]
    }

    static func == (lhs: SimpleMockObject, rhs: SimpleMockObject) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - WrappedPDFObject Tests

@Suite("WrappedPDFObject Tests")
struct WrappedPDFObjectTests {

    @Test("WrappedPDFObject wraps a PDF object")
    func wrapsObject() {
        let mockObject = SimpleMockObject(objectType: "TestObject")
        let validationObject = WrappedPDFObject(wrapping: mockObject)

        #expect(validationObject.objectType == "TestObject")
        #expect(validationObject.parent == nil)
    }

    @Test("WrappedPDFObject preserves object properties")
    func preservesProperties() {
        let mockObject = SimpleMockObject(objectType: "PropertyTest")
        let validationObject = WrappedPDFObject(wrapping: mockObject)

        let nameProperty = validationObject.property(named: "name")
        #expect(nameProperty == .string("PropertyTest"))
    }

    @Test("WrappedPDFObject has parent relationship")
    func hasParentRelationship() {
        let parentMock = SimpleMockObject(objectType: "Parent")
        let parent = WrappedPDFObject(wrapping: parentMock)

        let childMock = SimpleMockObject(objectType: "Child")
        let child = WrappedPDFObject(wrapping: childMock, parent: parent)

        #expect(child.parent != nil)
        #expect(child.parent?.value.objectType == "Parent")
    }

    @Test("WrappedPDFObject has context")
    func hasContext() {
        let mockObject = SimpleMockObject(objectType: "ContextTest")
        let context = ObjectContext(pageNumber: 5, location: "ContentStream")
        let validationObject = WrappedPDFObject(wrapping: mockObject, context: context)

        #expect(validationObject.context.pageNumber == 5)
        #expect(validationObject.context.location == "ContentStream")
    }

    @Test("WrappedPDFObject wraps type-erased object")
    func wrapsTypeErasedObject() {
        let mockObject = SimpleMockObject(objectType: "TypeErased")
        let anyObject = AnyPDFObject(mockObject)
        let validationObject = WrappedPDFObject(wrapping: anyObject)

        #expect(validationObject.objectType == "TypeErased")
    }

    @Test("WrappedPDFObject preserves COS object")
    func preservesCOSObject() {
        let cosDict: COSValue = .dictionary([.type: .name(.page)])
        let mockObject = SimpleMockObject(objectType: "Page", cosObject: cosDict)
        let validationObject = WrappedPDFObject(wrapping: mockObject)

        #expect(validationObject.cosObject != nil)
        #expect(validationObject.cosObject?.isDictionary == true)
    }

    @Test("WrappedPDFObject object path with no parent")
    func objectPathWithNoParent() {
        let mockObject = SimpleMockObject(objectType: "Root")
        let validationObject = WrappedPDFObject(wrapping: mockObject)

        let path = validationObject.objectPath
        #expect(path == ["Root"])
    }

    @Test("WrappedPDFObject object path with parent chain")
    func objectPathWithParentChain() {
        let rootMock = SimpleMockObject(objectType: "Document")
        let root = WrappedPDFObject(wrapping: rootMock)

        let pageMock = SimpleMockObject(objectType: "Page")
        let page = WrappedPDFObject(wrapping: pageMock, parent: root)

        let contentMock = SimpleMockObject(objectType: "ContentStream")
        let content = WrappedPDFObject(wrapping: contentMock, parent: page)

        let path = content.objectPath
        #expect(path == ["Document", "Page", "ContentStream"])
    }

    @Test("WrappedPDFObject path string")
    func pathString() {
        let rootMock = SimpleMockObject(objectType: "Document")
        let root = WrappedPDFObject(wrapping: rootMock)

        let pageMock = SimpleMockObject(objectType: "Page")
        let page = WrappedPDFObject(wrapping: pageMock, parent: root)

        let pathStr = page.pathString
        #expect(pathStr == "Document > Page")
    }

    @Test("WrappedPDFObject equality is based on ID")
    func equalityBasedOnID() {
        let mockObject = SimpleMockObject(objectType: "Test")
        let validationObject1 = WrappedPDFObject(wrapping: mockObject)
        let validationObject2 = WrappedPDFObject(wrapping: mockObject)

        // Different validation objects wrapping the same mock should be different
        #expect(validationObject1 != validationObject2)
    }

    @Test("WrappedPDFObject with full hierarchy and context")
    func fullHierarchyWithContext() {
        let docContext = ObjectContext.document
        let docMock = SimpleMockObject(objectType: "Document")
        let doc = WrappedPDFObject(wrapping: docMock, context: docContext)

        let pageContext = ObjectContext.page(3)
        let pageMock = SimpleMockObject(objectType: "Page")
        let page = WrappedPDFObject(wrapping: pageMock, parent: doc, context: pageContext)

        let fontContext = ObjectContext.font("Helvetica", page: 3)
        let fontMock = SimpleMockObject(objectType: "Font")
        let font = WrappedPDFObject(wrapping: fontMock, parent: page, context: fontContext)

        #expect(font.objectPath == ["Document", "Page", "Font"])
        #expect(font.context.pageNumber == 3)
        #expect(font.context.location == "Font")
        #expect(font.context.role == "Helvetica")
    }
}

// MARK: - CosValidationObject Integration Tests

@Suite("CosValidationObject Integration Tests")
struct CosValidationObjectIntegrationTests {

    @Test("Wrap CosValidationObject in WrappedPDFObject")
    func wrapCosValidationObject() {
        let cosValue: COSValue = .dictionary([.type: .name(.page)])
        let cosObject = CosValidationObject(cosValue: cosValue)
        let validationObject = WrappedPDFObject(wrapping: cosObject)

        #expect(validationObject.objectType == "CosDict")
        #expect(validationObject.cosObject?.isDictionary == true)
    }

    @Test("CosValidationObject properties accessible through WrappedPDFObject")
    func cosPropertiesAccessible() {
        let cosValue: COSValue = .dictionary([.type: .name(.font), .subtype: .name(.type1)])
        let cosObject = CosValidationObject(cosValue: cosValue)
        let validationObject = WrappedPDFObject(wrapping: cosObject)

        let typeProperty = validationObject.property(named: "type")
        let subtypeProperty = validationObject.property(named: "subtype")

        #expect(typeProperty == .name("Font"))
        #expect(subtypeProperty == .name("Type1"))
    }

    @Test("CosValidationObject with object key")
    func cosObjectWithKey() {
        let objectKey = COSObjectKey(objectNumber: 42, generation: 0)
        let cosValue: COSValue = .integer(100)
        let cosObject = CosValidationObject(cosValue: cosValue, objectKey: objectKey)
        let validationObject = WrappedPDFObject(wrapping: cosObject)

        #expect(validationObject.objectKey == objectKey)
    }

    @Test("Nested CosValidationObjects with context")
    func nestedCosObjects() {
        let parentValue: COSValue = .dictionary([.type: .name(.catalog)])
        let parentCos = CosValidationObject(cosValue: parentValue)
        let parent = WrappedPDFObject(
            wrapping: parentCos,
            context: ObjectContext.catalog
        )

        let childValue: COSValue = .dictionary([.type: .name(.pages)])
        let childCos = CosValidationObject(cosValue: childValue)
        let child = WrappedPDFObject(
            wrapping: childCos,
            parent: parent,
            context: ObjectContext(location: "Pages")
        )

        #expect(child.objectPath == ["CosDict", "CosDict"])
        #expect(child.parent?.value.objectType == "CosDict")
        #expect(child.context.location == "Pages")
    }
}

// MARK: - WrappedPDFObject Property Access Tests

@Suite("WrappedPDFObject Property Access Tests")
struct WrappedPDFObjectPropertyAccessTests {

    @Test("Access properties through WrappedPDFObject")
    func accessProperties() {
        struct PropertyMock: PDFObject, Equatable {
            let id = UUID()
            let objectType = "PropertyMock"
            let cosObject: COSValue? = nil

            func property(named name: String) -> PropertyValue? {
                switch name {
                case "name": return .string("test")
                case "count": return .integer(42)
                case "ratio": return .real(3.14)
                case "enabled": return .boolean(true)
                default: return nil
                }
            }

            var propertyNames: [String] {
                ["name", "count", "ratio", "enabled"]
            }

            static func == (lhs: PropertyMock, rhs: PropertyMock) -> Bool {
                lhs.id == rhs.id
            }
        }

        let mockObject = PropertyMock()
        let validationObject = WrappedPDFObject(wrapping: mockObject)

        #expect(validationObject.property(named: "name") == .string("test"))
        #expect(validationObject.property(named: "count") == .integer(42))
        #expect(validationObject.property(named: "ratio") == .real(3.14))
        #expect(validationObject.property(named: "enabled") == .boolean(true))
        #expect(validationObject.property(named: "missing") == nil)
    }

    @Test("Property names accessible through WrappedPDFObject")
    func propertyNamesAccessible() {
        struct MultiPropertyMock: PDFObject, Equatable {
            let id = UUID()
            let objectType = "MultiPropertyMock"
            let cosObject: COSValue? = nil

            func property(named name: String) -> PropertyValue? {
                nil
            }

            var propertyNames: [String] {
                ["prop1", "prop2", "prop3"]
            }

            static func == (lhs: MultiPropertyMock, rhs: MultiPropertyMock) -> Bool {
                lhs.id == rhs.id
            }
        }

        let mockObject = MultiPropertyMock()
        let validationObject = WrappedPDFObject(wrapping: mockObject)

        #expect(validationObject.propertyNames == ["prop1", "prop2", "prop3"])
    }
}
