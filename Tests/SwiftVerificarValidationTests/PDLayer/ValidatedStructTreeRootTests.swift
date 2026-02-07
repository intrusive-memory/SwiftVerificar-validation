import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - ValidatedStructTreeRoot Tests

@Suite("ValidatedStructTreeRoot")
struct ValidatedStructTreeRootTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization creates empty root")
        func defaultInit() {
            let root = ValidatedStructTreeRoot()
            #expect(root.children.isEmpty)
            #expect(root.childCount == 0)
            #expect(root.roleMap.isEmpty)
            #expect(root.classMap.isEmpty)
            #expect(!root.hasRoleMap)
            #expect(!root.hasClassMap)
            #expect(!root.hasIDTree)
            #expect(!root.hasParentTree)
            #expect(root.parentTreeNextKey == nil)
            #expect(root.namespaces.isEmpty)
            #expect(!root.hasNamespaces)
            #expect(root.totalElementCount == 0)
            #expect(root.maxDepth == 0)
        }

        @Test("Custom initialization sets all properties")
        func customInit() {
            let child = ValidatedStructElem.minimal(typeName: "P")
            let root = ValidatedStructTreeRoot(
                children: [child],
                roleMap: ["MyP": "P"],
                classMap: ["cls1": .boolean(true)],
                hasIDTree: true,
                hasParentTree: true,
                parentTreeNextKey: 42,
                namespaces: [.pdf2Namespace],
                totalElementCount: 10,
                maxDepth: 3
            )

            #expect(root.children.count == 1)
            #expect(root.childCount == 1)
            #expect(root.roleMap["MyP"] == "P")
            #expect(root.hasRoleMap)
            #expect(root.hasClassMap)
            #expect(root.hasIDTree)
            #expect(root.hasParentTree)
            #expect(root.parentTreeNextKey == 42)
            #expect(root.hasNamespaces)
            #expect(root.totalElementCount == 10)
            #expect(root.maxDepth == 3)
        }

        @Test("Object type is PDStructTreeRoot")
        func objectType() {
            let root = ValidatedStructTreeRoot()
            #expect(root.objectType == "PDStructTreeRoot")
        }

        @Test("Validation context is structureTreeRoot")
        func validationContextDefault() {
            let root = ValidatedStructTreeRoot()
            #expect(root.validationContext.location == "StructTreeRoot")
        }

        @Test("Custom context is preserved")
        func customContext() {
            let ctx = ObjectContext(location: "CustomRoot")
            let root = ValidatedStructTreeRoot(context: ctx)
            #expect(root.validationContext.location == "CustomRoot")
        }
    }

    // MARK: - PDFObject Conformance

    @Suite("PDFObject Conformance")
    struct PDFObjectTests {

        @Test("Property names are complete")
        func propertyNames() {
            let root = ValidatedStructTreeRoot()
            let names = root.propertyNames
            #expect(names.contains("childCount"))
            #expect(names.contains("hasRoleMap"))
            #expect(names.contains("hasClassMap"))
            #expect(names.contains("hasIDTree"))
            #expect(names.contains("hasParentTree"))
            #expect(names.contains("parentTreeNextKey"))
            #expect(names.contains("hasNamespaces"))
            #expect(names.contains("totalElementCount"))
            #expect(names.contains("maxDepth"))
        }

        @Test("Property access returns correct values")
        func propertyAccess() {
            let root = ValidatedStructTreeRoot(
                roleMap: ["X": "Y"],
                hasIDTree: true,
                hasParentTree: true,
                parentTreeNextKey: 7,
                namespaces: [.pdf1Namespace],
                totalElementCount: 15,
                maxDepth: 4
            )

            #expect(root.property(named: "childCount") == .integer(0))
            #expect(root.property(named: "hasRoleMap") == .boolean(true))
            #expect(root.property(named: "hasClassMap") == .boolean(false))
            #expect(root.property(named: "hasIDTree") == .boolean(true))
            #expect(root.property(named: "hasParentTree") == .boolean(true))
            #expect(root.property(named: "parentTreeNextKey") == .integer(7))
            #expect(root.property(named: "hasNamespaces") == .boolean(true))
            #expect(root.property(named: "totalElementCount") == .integer(15))
            #expect(root.property(named: "maxDepth") == .integer(4))
        }

        @Test("parentTreeNextKey returns null when nil")
        func parentTreeNextKeyNull() {
            let root = ValidatedStructTreeRoot()
            #expect(root.property(named: "parentTreeNextKey") == .null)
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let root = ValidatedStructTreeRoot()
            #expect(root.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Role Map Resolution

    @Suite("Role Map Resolution")
    struct RoleMapTests {

        @Test("Direct role map resolution")
        func directResolution() {
            let root = ValidatedStructTreeRoot(roleMap: ["MyParagraph": "P"])
            #expect(root.resolveRole("MyParagraph") == "P")
        }

        @Test("Standard type passes through unchanged")
        func standardPassthrough() {
            let root = ValidatedStructTreeRoot(roleMap: ["MyP": "P"])
            #expect(root.resolveRole("P") == "P")
        }

        @Test("Unmapped type passes through unchanged")
        func unmappedPassthrough() {
            let root = ValidatedStructTreeRoot(roleMap: ["MyP": "P"])
            #expect(root.resolveRole("Unknown") == "Unknown")
        }

        @Test("Chained role map resolution")
        func chainedResolution() {
            let root = ValidatedStructTreeRoot(roleMap: [
                "Custom": "MyP",
                "MyP": "P"
            ])
            #expect(root.resolveRole("Custom") == "P")
        }

        @Test("Circular role map does not loop infinitely")
        func circularResolution() {
            let root = ValidatedStructTreeRoot(roleMap: [
                "A": "B",
                "B": "A"
            ])
            // Should terminate (cycle detected)
            let result = root.resolveRole("A")
            #expect(result == "A" || result == "B")
        }

        @Test("resolveElementType returns correct type")
        func resolveElementType() {
            let root = ValidatedStructTreeRoot(roleMap: ["MyP": "P"])
            #expect(root.resolveElementType("MyP") == .paragraph)
        }

        @Test("resolveElementType returns nil for unknown")
        func resolveElementTypeUnknown() {
            let root = ValidatedStructTreeRoot()
            #expect(root.resolveElementType("CustomUnknown") == nil)
        }

        @Test("resolveElementType for standard type")
        func resolveElementTypeStandard() {
            let root = ValidatedStructTreeRoot()
            #expect(root.resolveElementType("Table") == .table)
            #expect(root.resolveElementType("Figure") == .figure)
        }
    }

    // MARK: - Tree Traversal

    @Suite("Tree Traversal")
    struct TraversalTests {

        @Test("allElements returns all elements in depth-first order")
        func allElements() {
            let leaf1 = ValidatedStructElem.minimal(typeName: "P")
            let leaf2 = ValidatedStructElem.minimal(typeName: "P")
            let h1 = ValidatedStructElem.heading(level: 1)
            let section = ValidatedStructElem.minimal(typeName: "Sect", children: [h1, leaf1])
            let root = ValidatedStructTreeRoot(children: [section, leaf2])

            let all = root.allElements
            #expect(all.count == 4)
            #expect(all[0].structureTypeName == "Sect")
            #expect(all[1].structureTypeName == "H1")
            #expect(all[2].structureTypeName == "P")
            #expect(all[3].structureTypeName == "P")
        }

        @Test("allElements empty for empty root")
        func allElementsEmpty() {
            let root = ValidatedStructTreeRoot()
            #expect(root.allElements.isEmpty)
        }

        @Test("elements(ofType:) filters correctly")
        func elementsOfType() {
            let p1 = ValidatedStructElem.paragraph()
            let p2 = ValidatedStructElem.paragraph()
            let h1 = ValidatedStructElem.heading(level: 1)
            let root = ValidatedStructTreeRoot(children: [p1, h1, p2])

            let paragraphs = root.elements(ofType: .paragraph)
            #expect(paragraphs.count == 2)
        }

        @Test("headings returns only heading elements")
        func headings() {
            let h1 = ValidatedStructElem.heading(level: 1)
            let h2 = ValidatedStructElem.heading(level: 2)
            let p = ValidatedStructElem.paragraph()
            let root = ValidatedStructTreeRoot(children: [h1, p, h2])

            #expect(root.headings.count == 2)
        }

        @Test("tables returns only table elements")
        func tables() {
            let table = ValidatedStructElem.table()
            let p = ValidatedStructElem.paragraph()
            let root = ValidatedStructTreeRoot(children: [table, p])

            #expect(root.tables.count == 1)
        }

        @Test("figures returns only figure elements")
        func figures() {
            let fig = ValidatedStructElem.figure(altText: "A figure")
            let p = ValidatedStructElem.paragraph()
            let root = ValidatedStructTreeRoot(children: [fig, p])

            #expect(root.figures.count == 1)
        }

        @Test("lists returns only list elements")
        func lists() {
            let li = ValidatedStructElem.list()
            let p = ValidatedStructElem.paragraph()
            let root = ValidatedStructTreeRoot(children: [li, p])

            #expect(root.lists.count == 1)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let root1 = ValidatedStructTreeRoot(id: id)
            let root2 = ValidatedStructTreeRoot(id: id, totalElementCount: 100)
            #expect(root1 == root2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let root1 = ValidatedStructTreeRoot()
            let root2 = ValidatedStructTreeRoot()
            #expect(root1 != root2)
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("minimal creates correct root")
        func minimal() {
            let child = ValidatedStructElem.paragraph()
            let root = ValidatedStructTreeRoot.minimal(
                children: [child],
                roleMap: ["X": "P"]
            )
            #expect(root.childCount == 1)
            #expect(root.hasRoleMap)
            #expect(root.totalElementCount == 1)
        }

        @Test("minimal with defaults")
        func minimalDefaults() {
            let root = ValidatedStructTreeRoot.minimal()
            #expect(root.childCount == 0)
            #expect(!root.hasRoleMap)
        }
    }

    // MARK: - Structure Namespace

    @Suite("Structure Namespace")
    struct NamespaceTests {

        @Test("PDF 1.x namespace has correct URI")
        func pdf1Namespace() {
            #expect(StructureNamespace.pdf1Namespace.namespaceURI == "http://iso.org/pdf/ssn")
            #expect(StructureNamespace.pdf1Namespace.schemaURL == nil)
            #expect(StructureNamespace.pdf1Namespace.roleMapNS.isEmpty)
        }

        @Test("PDF 2.0 namespace has correct URI")
        func pdf2Namespace() {
            #expect(StructureNamespace.pdf2Namespace.namespaceURI == "http://iso.org/pdf2/ssn")
        }

        @Test("MathML namespace has correct URI")
        func mathMLNamespace() {
            #expect(StructureNamespace.mathMLNamespace.namespaceURI == "http://www.w3.org/1998/Math/MathML")
        }

        @Test("Custom namespace initialization")
        func customNamespace() {
            let ns = StructureNamespace(
                namespaceURI: "http://example.com/ns",
                schemaURL: "http://example.com/schema.xsd",
                roleMapNS: ["Custom": "P"]
            )
            #expect(ns.namespaceURI == "http://example.com/ns")
            #expect(ns.schemaURL == "http://example.com/schema.xsd")
            #expect(ns.roleMapNS["Custom"] == "P")
        }

        @Test("Namespace is Hashable")
        func hashable() {
            let ns1 = StructureNamespace.pdf1Namespace
            let ns2 = StructureNamespace.pdf2Namespace
            let set: Set<StructureNamespace> = [ns1, ns2, ns1]
            #expect(set.count == 2)
        }

        @Test("Namespace is Codable")
        func codable() throws {
            let ns = StructureNamespace(
                namespaceURI: "http://example.com",
                schemaURL: "http://example.com/schema",
                roleMapNS: ["A": "B"]
            )
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let data = try encoder.encode(ns)
            let decoded = try decoder.decode(StructureNamespace.self, from: data)
            #expect(decoded == ns)
        }
    }
}
