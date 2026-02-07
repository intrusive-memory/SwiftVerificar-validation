import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - SAStructureRoot Tests

@Suite("SAStructureRoot")
struct SAStructureRootTests {

    // MARK: - Initialization Tests

    @Test("Default initialization with validated structure tree root")
    func defaultInit() {
        let root = ValidatedStructTreeRoot.minimal()
        let saRoot = SAStructureRoot(structTreeRoot: root)

        #expect(saRoot.structTreeRoot == root)
        #expect(saRoot.children.isEmpty)
    }

    @Test("Full initialization with children")
    func fullInit() {
        let root = ValidatedStructTreeRoot.minimal(
            roleMap: ["MyParagraph": "P"]
        )
        let child1 = SANode.minimal(typeName: "P")
        let child2 = SANode.heading(level: 1)

        let saRoot = SAStructureRoot(
            structTreeRoot: root,
            children: [child1, child2]
        )

        #expect(saRoot.children.count == 2)
        #expect(saRoot.structTreeRoot.roleMap["MyParagraph"] == "P")
    }

    // MARK: - SAObject Conformance Tests

    @Test("saObjectType is SAStructureRoot")
    func saObjectType() {
        let saRoot = SAStructureRoot.minimal()
        #expect(saRoot.saObjectType == "SAStructureRoot")
    }

    @Test("validationContext is SA structure root context")
    func validationContextTest() {
        let saRoot = SAStructureRoot.minimal()
        #expect(saRoot.validationContext.location == "SAStructureRoot")
    }

    @Test("accessibilityPropertyNames includes all expected names")
    func propertyNamesComplete() {
        let saRoot = SAStructureRoot.minimal()
        let names = saRoot.accessibilityPropertyNames
        #expect(names.contains("childCount"))
        #expect(names.contains("hasRoleMap"))
        #expect(names.contains("hasParentTree"))
        #expect(names.contains("hasIDTree"))
        #expect(names.contains("hasNamespaces"))
        #expect(names.contains("totalElementCount"))
        #expect(names.contains("maxDepth"))
        #expect(names.contains("headingCount"))
        #expect(names.contains("tableCount"))
        #expect(names.contains("figureCount"))
        #expect(names.contains("listCount"))
        #expect(names.contains("hasChildren"))
    }

    // MARK: - Accessibility Property Access Tests

    @Test("accessibilityProperty returns childCount")
    func propertyChildCount() {
        let saRoot = SAStructureRoot.minimal(
            children: [SANode.minimal(typeName: "P")]
        )
        #expect(saRoot.accessibilityProperty(named: "childCount") == .integer(1))
    }

    @Test("accessibilityProperty returns hasRoleMap")
    func propertyHasRoleMap() {
        let withMap = SAStructureRoot.minimal(roleMap: ["Custom": "P"])
        #expect(withMap.accessibilityProperty(named: "hasRoleMap") == .boolean(true))

        let withoutMap = SAStructureRoot.minimal()
        #expect(withoutMap.accessibilityProperty(named: "hasRoleMap") == .boolean(false))
    }

    @Test("accessibilityProperty returns totalElementCount")
    func propertyTotalElementCount() {
        let root = ValidatedStructTreeRoot(totalElementCount: 42)
        let saRoot = SAStructureRoot(structTreeRoot: root)
        #expect(saRoot.accessibilityProperty(named: "totalElementCount") == .integer(42))
    }

    @Test("accessibilityProperty returns maxDepth")
    func propertyMaxDepth() {
        let root = ValidatedStructTreeRoot(maxDepth: 7)
        let saRoot = SAStructureRoot(structTreeRoot: root)
        #expect(saRoot.accessibilityProperty(named: "maxDepth") == .integer(7))
    }

    @Test("accessibilityProperty returns hasChildren")
    func propertyHasChildren() {
        let withChildren = SAStructureRoot.minimal(children: [SANode.minimal(typeName: "P")])
        #expect(withChildren.accessibilityProperty(named: "hasChildren") == .boolean(true))

        let empty = SAStructureRoot.minimal()
        #expect(empty.accessibilityProperty(named: "hasChildren") == .boolean(false))
    }

    @Test("accessibilityProperty returns heading/table/figure/list counts")
    func propertyElementCounts() {
        let children = [
            SANode.heading(level: 1),
            SANode.heading(level: 2),
            SANode.figure(altText: "test"),
            SANode.minimal(typeName: "Table"),
            SANode.minimal(typeName: "L"),
        ]
        let saRoot = SAStructureRoot.minimal(children: children)

        #expect(saRoot.accessibilityProperty(named: "headingCount") == .integer(2))
        #expect(saRoot.accessibilityProperty(named: "figureCount") == .integer(1))
        #expect(saRoot.accessibilityProperty(named: "tableCount") == .integer(1))
        #expect(saRoot.accessibilityProperty(named: "listCount") == .integer(1))
    }

    @Test("accessibilityProperty returns nil for unknown property")
    func propertyUnknown() {
        let saRoot = SAStructureRoot.minimal()
        #expect(saRoot.accessibilityProperty(named: "nonexistent") == nil)
    }

    // MARK: - Computed Properties Tests

    @Test("childCount computed property")
    func childCountComputed() {
        let saRoot = SAStructureRoot.minimal(
            children: [SANode.minimal(typeName: "P"), SANode.minimal(typeName: "H1")]
        )
        #expect(saRoot.childCount == 2)
    }

    @Test("hasChildren computed property")
    func hasChildrenComputed() {
        let withChildren = SAStructureRoot.minimal(children: [SANode.minimal(typeName: "P")])
        #expect(withChildren.hasChildren == true)

        let empty = SAStructureRoot.minimal()
        #expect(empty.hasChildren == false)
    }

    // MARK: - Tree Traversal Tests

    @Test("allNodes returns all nodes in depth-first order")
    func allNodesDepthFirst() {
        let grandchild = SANode.minimal(typeName: "Span")
        let child1 = SANode.minimal(typeName: "P", children: [grandchild])
        let child2 = SANode.heading(level: 1)

        let saRoot = SAStructureRoot.minimal(children: [child1, child2])
        let allNodes = saRoot.allNodes

        #expect(allNodes.count == 3)
        #expect(allNodes[0].structureTypeName == "P")
        #expect(allNodes[1].structureTypeName == "Span")
        #expect(allNodes[2].structureTypeName == "H1")
    }

    @Test("allNodes returns empty for empty tree")
    func allNodesEmpty() {
        let saRoot = SAStructureRoot.minimal()
        #expect(saRoot.allNodes.isEmpty)
    }

    @Test("nodes(ofType:) filters correctly")
    func nodesOfType() {
        let children = [
            SANode.minimal(typeName: "P"),
            SANode.heading(level: 1),
            SANode.minimal(typeName: "P"),
            SANode.heading(level: 2),
        ]
        let saRoot = SAStructureRoot.minimal(children: children)

        let paragraphs = saRoot.nodes(ofType: .paragraph)
        #expect(paragraphs.count == 2)
    }

    @Test("headings returns all heading nodes")
    func headingsTraversal() {
        let children = [
            SANode.heading(level: 1),
            SANode.minimal(typeName: "P"),
            SANode.heading(level: 2),
            SANode.minimal(typeName: "P"),
            SANode.heading(level: 3),
        ]
        let saRoot = SAStructureRoot.minimal(children: children)

        #expect(saRoot.headings.count == 3)
        #expect(saRoot.headingCount == 3)
    }

    @Test("figures returns all figure nodes")
    func figuresTraversal() {
        let children = [
            SANode.figure(altText: "img1"),
            SANode.minimal(typeName: "P"),
            SANode.figure(altText: "img2"),
        ]
        let saRoot = SAStructureRoot.minimal(children: children)

        #expect(saRoot.figures.count == 2)
        #expect(saRoot.figureCount == 2)
    }

    @Test("tables returns all table nodes")
    func tablesTraversal() {
        let children = [
            SANode.minimal(typeName: "Table"),
            SANode.minimal(typeName: "P"),
        ]
        let saRoot = SAStructureRoot.minimal(children: children)

        #expect(saRoot.tables.count == 1)
        #expect(saRoot.tableCount == 1)
    }

    @Test("lists returns all list nodes")
    func listsTraversal() {
        let children = [
            SANode.minimal(typeName: "L"),
            SANode.minimal(typeName: "P"),
            SANode.minimal(typeName: "L"),
        ]
        let saRoot = SAStructureRoot.minimal(children: children)

        #expect(saRoot.lists.count == 2)
        #expect(saRoot.listCount == 2)
    }

    @Test("Deeply nested traversal")
    func deepTraversal() {
        let level3 = SANode.figure(altText: "deep")
        let level2 = SANode.minimal(typeName: "Div", children: [level3])
        let level1 = SANode.minimal(typeName: "Sect", children: [level2])

        let saRoot = SAStructureRoot.minimal(children: [level1])

        #expect(saRoot.allNodes.count == 3)
        #expect(saRoot.figureCount == 1)
    }

    // MARK: - Role Map Resolution Tests

    @Test("resolveRole delegates to structure tree root")
    func resolveRole() {
        let saRoot = SAStructureRoot.minimal(roleMap: ["MyParagraph": "P", "MyHeading": "H1"])

        #expect(saRoot.resolveRole("MyParagraph") == "P")
        #expect(saRoot.resolveRole("MyHeading") == "H1")
        #expect(saRoot.resolveRole("P") == "P") // Standard type returns itself
    }

    @Test("resolveElementType delegates to structure tree root")
    func resolveElementType() {
        let saRoot = SAStructureRoot.minimal(roleMap: ["Custom": "Figure"])

        let resolved = saRoot.resolveElementType("Custom")
        #expect(resolved == .figure)

        let standard = saRoot.resolveElementType("P")
        #expect(standard == .paragraph)

        let unknown = saRoot.resolveElementType("TotallyUnknown")
        #expect(unknown == nil)
    }

    // MARK: - Summary Tests

    @Test("summary contains relevant information")
    func summaryTest() {
        let children = [
            SANode.heading(level: 1),
            SANode.figure(altText: "test"),
            SANode.minimal(typeName: "Table"),
        ]
        let root = ValidatedStructTreeRoot(totalElementCount: 15, maxDepth: 4)
        let saRoot = SAStructureRoot(structTreeRoot: root, children: children)

        let summary = saRoot.summary
        #expect(summary.contains("SAStructureRoot"))
        #expect(summary.contains("15 elements"))
        #expect(summary.contains("depth=4"))
        #expect(summary.contains("1 headings"))
        #expect(summary.contains("1 figures"))
        #expect(summary.contains("1 tables"))
    }

    // MARK: - Factory Methods Tests

    @Test("minimal factory creates basic structure root")
    func factoryMinimal() {
        let saRoot = SAStructureRoot.minimal()
        #expect(saRoot.children.isEmpty)
        #expect(saRoot.structTreeRoot.roleMap.isEmpty)
    }

    @Test("minimal factory with children and role map")
    func factoryMinimalWithArgs() {
        let children = [SANode.minimal(typeName: "P")]
        let roleMap = ["Custom": "P"]
        let saRoot = SAStructureRoot.minimal(children: children, roleMap: roleMap)
        #expect(saRoot.childCount == 1)
        #expect(saRoot.structTreeRoot.roleMap["Custom"] == "P")
    }

    // MARK: - Equatable Tests

    @Test("Equal SAStructureRoots have same id")
    func equatable() {
        let root = ValidatedStructTreeRoot.minimal()
        let id = UUID()
        let saRoot1 = SAStructureRoot(id: id, structTreeRoot: root)
        let saRoot2 = SAStructureRoot(id: id, structTreeRoot: root)
        #expect(saRoot1 == saRoot2)
    }

    @Test("Different SAStructureRoots have different ids")
    func notEqual() {
        let root = ValidatedStructTreeRoot.minimal()
        let saRoot1 = SAStructureRoot(structTreeRoot: root)
        let saRoot2 = SAStructureRoot(structTreeRoot: root)
        #expect(saRoot1 != saRoot2)
    }
}
