import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - SAObject Protocol Tests

@Suite("SAObject Protocol")
struct SAObjectTests {

    // MARK: - SAObjectType Enum Tests

    @Test("SAObjectType raw values are correct")
    func saObjectTypeRawValues() {
        #expect(SAObjectType.document.rawValue == "SADocument")
        #expect(SAObjectType.page.rawValue == "SAPage")
        #expect(SAObjectType.structureRoot.rawValue == "SAStructureRoot")
        #expect(SAObjectType.node.rawValue == "SANode")
        #expect(SAObjectType.structureElement.rawValue == "SAStructureElement")
    }

    @Test("SAObjectType has all expected cases")
    func saObjectTypeAllCases() {
        #expect(SAObjectType.allCases.count == 5)
    }

    @Test("SAObjectType is Hashable and can be used in sets")
    func saObjectTypeHashable() {
        let types: Set<SAObjectType> = [.document, .page, .structureRoot, .node, .structureElement]
        #expect(types.count == 5)
        #expect(types.contains(.document))
        #expect(types.contains(.page))
        #expect(types.contains(.structureRoot))
        #expect(types.contains(.node))
        #expect(types.contains(.structureElement))
    }

    @Test("SAObjectType init from raw value")
    func saObjectTypeFromRawValue() {
        #expect(SAObjectType(rawValue: "SADocument") == .document)
        #expect(SAObjectType(rawValue: "SAPage") == .page)
        #expect(SAObjectType(rawValue: "SAStructureRoot") == .structureRoot)
        #expect(SAObjectType(rawValue: "SANode") == .node)
        #expect(SAObjectType(rawValue: "SAStructureElement") == .structureElement)
        #expect(SAObjectType(rawValue: "invalid") == nil)
    }

    // MARK: - ObjectContext SA Extension Tests

    @Test("SA document context is correct")
    func saDocumentContext() {
        let ctx = ObjectContext.saDocument
        #expect(ctx.location == "SADocument")
        #expect(ctx.pageNumber == nil)
    }

    @Test("SA page context includes page number")
    func saPageContext() {
        let ctx = ObjectContext.saPage(3)
        #expect(ctx.location == "SAPage")
        #expect(ctx.pageNumber == 3)
    }

    @Test("SA structure root context is correct")
    func saStructureRootContext() {
        let ctx = ObjectContext.saStructureRoot
        #expect(ctx.location == "SAStructureRoot")
        #expect(ctx.pageNumber == nil)
    }

    @Test("SA node context includes role")
    func saNodeContext() {
        let ctx = ObjectContext.saNode("P")
        #expect(ctx.location == "SANode")
        #expect(ctx.role == "P")
    }

    @Test("SA node context with different roles")
    func saNodeContextRoles() {
        let heading = ObjectContext.saNode("H1")
        #expect(heading.role == "H1")

        let figure = ObjectContext.saNode("Figure")
        #expect(figure.role == "Figure")

        let table = ObjectContext.saNode("Table")
        #expect(table.role == "Table")
    }

    // MARK: - SAObject Protocol Default Implementations

    @Test("SAObject conforming type gets default property names")
    func defaultPropertyNames() {
        // SANode.minimal provides a concrete SAObject
        let node = SANode.minimal(typeName: "P")
        // SANode overrides accessibilityPropertyNames, so check it's non-empty
        #expect(!node.accessibilityPropertyNames.isEmpty)
    }

    @Test("SAObject protocol provides Identifiable conformance via id")
    func identifiableConformance() {
        let node = SANode.minimal(typeName: "P")
        // Identifiable protocol requires id property
        let _: UUID = node.id
        #expect(node.id == node.id)
    }

    @Test("SAObject types are Sendable")
    func sendableConformance() {
        let node = SANode.minimal(typeName: "P")
        // Verify we can capture in a sendable closure
        let _: @Sendable () -> String = { node.saObjectType }
    }

    @Test("SAObject types are Equatable")
    func equatableConformance() {
        let node1 = SANode.minimal(typeName: "P")
        let node2 = SANode.minimal(typeName: "P")
        #expect(node1 == node1)
        #expect(node1 != node2) // Different UUIDs
    }
}
