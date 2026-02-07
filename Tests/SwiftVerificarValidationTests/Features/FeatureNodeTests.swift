import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - FeatureNode Tests

@Suite("FeatureNode Tests")
struct FeatureNodeTests {

    // MARK: - Initialization

    @Test("FeatureNode creates with minimal parameters")
    func minimalInit() {
        let node = FeatureNode(featureType: .document)
        #expect(node.featureType == .document)
        #expect(node.name == nil)
        #expect(node.values.isEmpty)
        #expect(node.children.isEmpty)
        #expect(node.objectKey == nil)
        #expect(node.context == nil)
    }

    @Test("FeatureNode creates with all parameters")
    func fullInit() {
        let objectKey = COSObjectKey(objectNumber: 42, generation: 0)
        let context = ObjectContext.page(1)
        let node = FeatureNode(
            featureType: .font,
            name: "Helvetica",
            values: ["size": .int(12)],
            children: [],
            objectKey: objectKey,
            context: context
        )
        #expect(node.featureType == .font)
        #expect(node.name == "Helvetica")
        #expect(node.values.count == 1)
        #expect(node.objectKey == objectKey)
        #expect(node.context?.pageNumber == 1)
    }

    @Test("FeatureNode has unique ID")
    func uniqueID() {
        let node1 = FeatureNode(featureType: .document)
        let node2 = FeatureNode(featureType: .document)
        #expect(node1.id != node2.id)
    }

    // MARK: - Value Access

    @Test("FeatureNode value access by key")
    func valueAccess() {
        let node = FeatureNode(
            featureType: .font,
            values: [
                "name": .string("Arial"),
                "size": .int(12),
                "isEmbedded": .bool(true)
            ]
        )
        #expect(node.value(for: "name") == .string("Arial"))
        #expect(node.value(for: "size") == .int(12))
        #expect(node.value(for: "isEmbedded") == .bool(true))
        #expect(node.value(for: "missing") == nil)
    }

    @Test("FeatureNode typed value extraction")
    func typedValueExtraction() {
        let node = FeatureNode(
            featureType: .image,
            values: [
                "width": .int(100),
                "height": .int(200),
                "ratio": .double(0.5),
                "format": .string("PNG"),
                "isTransparent": .bool(true)
            ]
        )
        #expect(node.intValue(for: "width") == 100)
        #expect(node.intValue(for: "height") == 200)
        #expect(node.doubleValue(for: "ratio") == 0.5)
        #expect(node.stringValue(for: "format") == "PNG")
        #expect(node.boolValue(for: "isTransparent") == true)
    }

    @Test("FeatureNode typed value extraction returns nil for wrong type")
    func typedValueExtractionWrongType() {
        let node = FeatureNode(
            featureType: .font,
            values: ["name": .string("Arial")]
        )
        #expect(node.intValue(for: "name") == nil)
        #expect(node.boolValue(for: "name") == nil)
        #expect(node.doubleValue(for: "name") == nil)
    }

    // MARK: - Child Access

    @Test("FeatureNode children access by type")
    func childrenByType() {
        let fontChild = FeatureNode(featureType: .font, name: "Font1")
        let imageChild = FeatureNode(featureType: .image, name: "Image1")
        let fontChild2 = FeatureNode(featureType: .font, name: "Font2")

        let parent = FeatureNode(
            featureType: .page,
            children: [fontChild, imageChild, fontChild2]
        )

        let fonts = parent.children(ofType: .font)
        #expect(fonts.count == 2)
        #expect(fonts[0].name == "Font1")
        #expect(fonts[1].name == "Font2")

        let images = parent.children(ofType: .image)
        #expect(images.count == 1)
    }

    @Test("FeatureNode child access by name")
    func childByName() {
        let child1 = FeatureNode(featureType: .font, name: "Helvetica")
        let child2 = FeatureNode(featureType: .font, name: "Arial")

        let parent = FeatureNode(
            featureType: .page,
            children: [child1, child2]
        )

        let found = parent.child(named: "Arial")
        #expect(found != nil)
        #expect(found?.name == "Arial")

        let notFound = parent.child(named: "Times")
        #expect(notFound == nil)
    }

    @Test("FeatureNode children with predicate")
    func childrenWithPredicate() {
        let children = [
            FeatureNode(featureType: .font, values: ["size": .int(12)]),
            FeatureNode(featureType: .font, values: ["size": .int(14)]),
            FeatureNode(featureType: .font, values: ["size": .int(16)])
        ]

        let parent = FeatureNode(featureType: .page, children: children)

        let largeFont = parent.children { node in
            (node.intValue(for: "size") ?? 0) >= 14
        }
        #expect(largeFont.count == 2)
    }

    // MARK: - Descendants

    @Test("FeatureNode all descendants")
    func allDescendants() {
        let grandchild = FeatureNode(featureType: .fontDescriptor, name: "Desc")
        let child = FeatureNode(featureType: .font, name: "Font", children: [grandchild])
        let parent = FeatureNode(featureType: .page, children: [child])

        let descendants = parent.allDescendants
        #expect(descendants.count == 2)
        #expect(descendants.contains { $0.name == "Font" })
        #expect(descendants.contains { $0.name == "Desc" })
    }

    @Test("FeatureNode descendants by type")
    func descendantsByType() {
        let font1 = FeatureNode(featureType: .font)
        let font2 = FeatureNode(featureType: .font)
        let image = FeatureNode(featureType: .image)
        let page = FeatureNode(featureType: .page, children: [font1, image])
        let doc = FeatureNode(featureType: .document, children: [page, font2])

        let fonts = doc.descendants(ofType: .font)
        #expect(fonts.count == 2)
    }

    // MARK: - Statistics

    @Test("FeatureNode child count")
    func childCount() {
        let children = [
            FeatureNode(featureType: .font),
            FeatureNode(featureType: .image),
            FeatureNode(featureType: .colorSpace)
        ]
        let parent = FeatureNode(featureType: .page, children: children)
        #expect(parent.childCount == 3)
    }

    @Test("FeatureNode descendant count")
    func descendantCount() {
        let grandchild = FeatureNode(featureType: .fontDescriptor)
        let child1 = FeatureNode(featureType: .font, children: [grandchild])
        let child2 = FeatureNode(featureType: .image)
        let parent = FeatureNode(featureType: .page, children: [child1, child2])

        #expect(parent.descendantCount == 3)  // child1 + grandchild + child2
    }

    @Test("FeatureNode depth calculation")
    func depthCalculation() {
        let leaf = FeatureNode(featureType: .fontDescriptor)
        #expect(leaf.depth == 0)

        let oneLevel = FeatureNode(featureType: .font, children: [leaf])
        #expect(oneLevel.depth == 1)

        let twoLevel = FeatureNode(featureType: .page, children: [oneLevel])
        #expect(twoLevel.depth == 2)
    }

    // MARK: - Modification

    @Test("FeatureNode with value")
    func withValue() {
        let node = FeatureNode(featureType: .font)
        let modified = node.withValue("size", .int(12))

        #expect(node.values.isEmpty)  // Original unchanged
        #expect(modified.intValue(for: "size") == 12)
        #expect(modified.id == node.id)  // Same ID
    }

    @Test("FeatureNode with values")
    func withValues() {
        let node = FeatureNode(featureType: .font, values: ["name": .string("Arial")])
        let modified = node.withValues(["size": .int(12), "bold": .bool(true)])

        #expect(modified.stringValue(for: "name") == "Arial")
        #expect(modified.intValue(for: "size") == 12)
        #expect(modified.boolValue(for: "bold") == true)
    }

    @Test("FeatureNode with child")
    func withChild() {
        let parent = FeatureNode(featureType: .page)
        let child = FeatureNode(featureType: .font)
        let modified = parent.withChild(child)

        #expect(parent.children.isEmpty)  // Original unchanged
        #expect(modified.children.count == 1)
        #expect(modified.children[0].featureType == .font)
    }

    @Test("FeatureNode with children")
    func withChildren() {
        let parent = FeatureNode(featureType: .page, children: [
            FeatureNode(featureType: .font)
        ])
        let newChildren = [
            FeatureNode(featureType: .image),
            FeatureNode(featureType: .colorSpace)
        ]
        let modified = parent.withChildren(newChildren)

        #expect(modified.children.count == 3)
    }

    @Test("FeatureNode replacing children")
    func replacingChildren() {
        let parent = FeatureNode(featureType: .page, children: [
            FeatureNode(featureType: .font),
            FeatureNode(featureType: .image)
        ])
        let newChildren = [FeatureNode(featureType: .colorSpace)]
        let modified = parent.replacingChildren(newChildren)

        #expect(modified.children.count == 1)
        #expect(modified.children[0].featureType == .colorSpace)
    }

    // MARK: - Equatable

    @Test("FeatureNode equality based on ID")
    func equalityBasedOnID() {
        let node1 = FeatureNode(featureType: .document, name: "Doc1")
        let node2 = FeatureNode(featureType: .document, name: "Doc1")

        #expect(node1 != node2)  // Different IDs
        #expect(node1 == node1)  // Same ID
    }

    // MARK: - CustomStringConvertible

    @Test("FeatureNode description")
    func description() {
        let node = FeatureNode(
            featureType: .font,
            name: "Arial",
            values: ["size": .int(12), "bold": .bool(true)],
            children: [FeatureNode(featureType: .fontDescriptor)]
        )

        let desc = node.description
        #expect(desc.contains("Font"))
        #expect(desc.contains("Arial"))
        #expect(desc.contains("2 values"))
        #expect(desc.contains("1 children"))
    }
}

// MARK: - FeatureValue Tests

@Suite("FeatureValue Tests")
struct FeatureValueTests {

    // MARK: - Type Creation

    @Test("FeatureValue null type")
    func nullType() {
        let value: FeatureValue = .null
        #expect(value.isNull)
        #expect(!value.isBool)
        #expect(!value.isInt)
    }

    @Test("FeatureValue bool type")
    func boolType() {
        let value: FeatureValue = .bool(true)
        #expect(value.isBool)
        #expect(value.boolValue == true)
    }

    @Test("FeatureValue int type")
    func intType() {
        let value: FeatureValue = .int(42)
        #expect(value.isInt)
        #expect(value.intValue == 42)
        #expect(value.doubleValue == 42.0)  // Int can be converted to double
    }

    @Test("FeatureValue double type")
    func doubleType() {
        let value: FeatureValue = .double(3.14)
        #expect(value.isDouble)
        #expect(value.doubleValue == 3.14)
    }

    @Test("FeatureValue string type")
    func stringType() {
        let value: FeatureValue = .string("hello")
        #expect(value.isString)
        #expect(value.stringValue == "hello")
    }

    @Test("FeatureValue data type")
    func dataType() {
        let data = Data([0x00, 0x01, 0x02])
        let value: FeatureValue = .data(data)
        #expect(value.isData)
        #expect(value.dataValue == data)
    }

    @Test("FeatureValue array type")
    func arrayType() {
        let value: FeatureValue = .array([.int(1), .int(2), .int(3)])
        #expect(value.isArray)
        #expect(value.arrayValue?.count == 3)
    }

    @Test("FeatureValue dictionary type")
    func dictionaryType() {
        let value: FeatureValue = .dictionary(["key": .string("value")])
        #expect(value.isDictionary)
        #expect(value.dictionaryValue?["key"] == .string("value"))
    }

    @Test("FeatureValue date type")
    func dateType() {
        let date = Date()
        let value: FeatureValue = .date(date)
        #expect(value.isDate)
        #expect(value.dateValue == date)
    }

    // MARK: - Literals

    @Test("FeatureValue from boolean literal")
    func booleanLiteral() {
        let value: FeatureValue = true
        #expect(value == .bool(true))
    }

    @Test("FeatureValue from integer literal")
    func integerLiteral() {
        let value: FeatureValue = 42
        #expect(value == .int(42))
    }

    @Test("FeatureValue from float literal")
    func floatLiteral() {
        let value: FeatureValue = 3.14
        #expect(value == .double(3.14))
    }

    @Test("FeatureValue from string literal")
    func stringLiteral() {
        let value: FeatureValue = "hello"
        #expect(value == .string("hello"))
    }

    @Test("FeatureValue from array literal")
    func arrayLiteral() {
        let value: FeatureValue = [1, 2, 3]
        #expect(value.arrayValue?.count == 3)
    }

    @Test("FeatureValue from dictionary literal")
    func dictionaryLiteral() {
        let value: FeatureValue = ["key": "value"]
        #expect(value.dictionaryValue?["key"] == .string("value"))
    }

    @Test("FeatureValue from nil literal")
    func nilLiteral() {
        let value: FeatureValue = nil
        #expect(value == .null)
    }

    // MARK: - Equatable

    @Test("FeatureValue equality")
    func equality() {
        #expect(FeatureValue.null == FeatureValue.null)
        #expect(FeatureValue.bool(true) == FeatureValue.bool(true))
        #expect(FeatureValue.int(42) == FeatureValue.int(42))
        #expect(FeatureValue.double(3.14) == FeatureValue.double(3.14))
        #expect(FeatureValue.string("hello") == FeatureValue.string("hello"))
    }

    @Test("FeatureValue inequality")
    func inequality() {
        #expect(FeatureValue.bool(true) != FeatureValue.bool(false))
        #expect(FeatureValue.int(42) != FeatureValue.int(43))
        #expect(FeatureValue.string("hello") != FeatureValue.string("world"))
    }

    // MARK: - Hashable

    @Test("FeatureValue is hashable")
    func hashable() {
        let values: Set<FeatureValue> = [.int(1), .int(2), .int(1)]
        #expect(values.count == 2)
    }

    // MARK: - CustomStringConvertible

    @Test("FeatureValue descriptions")
    func descriptions() {
        #expect(FeatureValue.null.description == "null")
        #expect(FeatureValue.bool(true).description == "true")
        #expect(FeatureValue.bool(false).description == "false")
        #expect(FeatureValue.int(42).description == "42")
        #expect(FeatureValue.double(3.14).description == "3.14")
        #expect(FeatureValue.string("hello").description == "\"hello\"")
        #expect(FeatureValue.data(Data([0, 1, 2])).description == "<3 bytes>")
        #expect(FeatureValue.array([.int(1), .int(2)]).description == "[2 items]")
        #expect(FeatureValue.dictionary(["a": .int(1)]).description == "{1 entries}")
    }
}
