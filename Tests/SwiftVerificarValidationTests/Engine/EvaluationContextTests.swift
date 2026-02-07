import Foundation
import Testing
// Import only the ExpressionPropertyValue typealias from profiles to avoid ambiguity
import typealias SwiftVerificarValidationProfiles.ExpressionPropertyValue
@testable import SwiftVerificarValidation


@Suite("EvaluationContext Tests")
struct EvaluationContextTests {

    // MARK: - Test Helper

    struct MockPDFObject: PDFObject, Equatable {
        let id = UUID()
        let objectType: String
        let cosObject: COSValue? = nil

        var propertyNames: [String] { [] }
        func property(named name: String) -> PropertyValue? { nil }

        static func == (lhs: MockPDFObject, rhs: MockPDFObject) -> Bool {
            lhs.id == rhs.id
        }
    }

    // MARK: - Initialization Tests

    @Test("Create empty evaluation context")
    func createEmpty() {
        let context = EvaluationContext.empty

        #expect(context.documentLocation == nil)
        #expect(context.additionalProperties.isEmpty)
        #expect(context.metadata.isEmpty)
        #expect(context.parentObject == nil)
        #expect(context.profileVariables.isEmpty)
    }

    @Test("Create context with location")
    func createWithLocation() {
        let context = EvaluationContext(documentLocation: "Page 5")

        #expect(context.documentLocation == "Page 5")
        #expect(context.additionalProperties.isEmpty)
        #expect(context.metadata.isEmpty)
    }

    @Test("Create context with additional properties")
    func createWithProperties() {
        let properties: [String: ExpressionPropertyValue] = [
            "pageNumber": .int(5),
            "totalPages": .int(10)
        ]
        let context = EvaluationContext(additionalProperties: properties)

        #expect(context.additionalProperties.count == 2)
        #expect(context.property(named: "pageNumber") == .int(5))
        #expect(context.property(named: "totalPages") == .int(10))
    }

    @Test("Create context with metadata")
    func createWithMetadata() {
        let metadata = [
            "fileName": "document.pdf",
            "profileName": "PDF/A-1b"
        ]
        let context = EvaluationContext(metadata: metadata)

        #expect(context.metadata.count == 2)
        #expect(context.metadata(for: "fileName") == "document.pdf")
        #expect(context.metadata(for: "profileName") == "PDF/A-1b")
    }

    @Test("Create context with parent object")
    func createWithParent() {
        let parent = MockPDFObject(objectType: "ParentObject")
        let context = EvaluationContext(parentObject: parent)

        #expect(context.parentObject != nil)
    }

    @Test("Create context with profile variables")
    func createWithVariables() {
        let variables: [String: ExpressionPropertyValue] = [
            "minVersion": .int(1),
            "maxVersion": .int(5)
        ]
        let context = EvaluationContext(profileVariables: variables)

        #expect(context.profileVariables.count == 2)
        #expect(context.property(named: "minVersion") == .int(1))
        #expect(context.property(named: "maxVersion") == .int(5))
    }

    @Test("Create context with all parameters")
    func createWithAllParameters() {
        let parent = MockPDFObject(objectType: "ParentObject")
        let context = EvaluationContext(
            documentLocation: "Page 3",
            additionalProperties: ["prop": .bool(true)],
            metadata: ["key": "value"],
            parentObject: parent,
            profileVariables: ["var": .int(42)]
        )

        #expect(context.documentLocation == "Page 3")
        #expect(context.additionalProperties.count == 1)
        #expect(context.metadata.count == 1)
        #expect(context.parentObject != nil)
        #expect(context.profileVariables.count == 1)
    }

    // MARK: - Context Building Tests

    @Test("Update context with new location")
    func updateLocation() {
        let original = EvaluationContext(documentLocation: "Page 1")
        let updated = original.with(location: "Page 2")

        #expect(original.documentLocation == "Page 1")
        #expect(updated.documentLocation == "Page 2")
    }

    @Test("Add properties to context")
    func addProperties() {
        let original = EvaluationContext(
            additionalProperties: ["existing": .int(1)]
        )

        let updated = original.with(properties: [
            "new": .int(2),
            "another": .bool(true)
        ])

        #expect(original.additionalProperties.count == 1)
        #expect(updated.additionalProperties.count == 3)
        #expect(updated.property(named: "existing") == .int(1))
        #expect(updated.property(named: "new") == .int(2))
        #expect(updated.property(named: "another") == .bool(true))
    }

    @Test("Override existing properties")
    func overrideProperties() {
        let original = EvaluationContext(
            additionalProperties: ["value": .int(1)]
        )

        let updated = original.with(properties: ["value": .int(2)])

        #expect(original.property(named: "value") == .int(1))
        #expect(updated.property(named: "value") == .int(2))
    }

    @Test("Add metadata to context")
    func addMetadata() {
        let original = EvaluationContext(
            metadata: ["existing": "value1"]
        )

        let updated = original.with(metadata: [
            "new": "value2",
            "another": "value3"
        ])

        #expect(original.metadata.count == 1)
        #expect(updated.metadata.count == 3)
        #expect(updated.metadata(for: "existing") == "value1")
        #expect(updated.metadata(for: "new") == "value2")
    }

    @Test("Set parent object")
    func setParent() {
        let original = EvaluationContext.empty
        let parent = MockPDFObject(objectType: "Parent")
        let updated = original.with(parent: parent)

        #expect(original.parentObject == nil)
        #expect(updated.parentObject != nil)
    }

    @Test("Add profile variables")
    func addVariables() {
        let original = EvaluationContext(
            profileVariables: ["existing": .int(1)]
        )

        let updated = original.with(variables: [
            "new": .int(2),
            "another": .bool(true)
        ])

        #expect(original.profileVariables.count == 1)
        #expect(updated.profileVariables.count == 3)
        #expect(updated.property(named: "existing") == .int(1))
        #expect(updated.property(named: "new") == .int(2))
    }

    // MARK: - Property Access Tests

    @Test("Access additional property by name")
    func accessAdditionalProperty() {
        let context = EvaluationContext(
            additionalProperties: ["test": .string("value")]
        )

        #expect(context.property(named: "test") == .string("value"))
        #expect(context.hasProperty("test") == true)
    }

    @Test("Access profile variable by name")
    func accessProfileVariable() {
        let context = EvaluationContext(
            profileVariables: ["test": .string("value")]
        )

        #expect(context.property(named: "test") == .string("value"))
        #expect(context.hasProperty("test") == true)
    }

    @Test("Additional properties take precedence over profile variables")
    func propertyPrecedence() {
        let context = EvaluationContext(
            additionalProperties: ["test": .string("additional")],
            profileVariables: ["test": .string("variable")]
        )

        #expect(context.property(named: "test") == .string("additional"))
    }

    @Test("Access non-existent property")
    func accessNonExistent() {
        let context = EvaluationContext.empty

        #expect(context.property(named: "nonexistent") == nil)
        #expect(context.hasProperty("nonexistent") == false)
    }

    @Test("Get all properties")
    func getAllProperties() {
        let context = EvaluationContext(
            additionalProperties: ["add1": .int(1), "add2": .int(2)],
            profileVariables: ["var1": .int(3), "var2": .int(4)]
        )

        let all = context.allProperties

        #expect(all.count == 4)
        #expect(all["add1"] == .int(1))
        #expect(all["add2"] == .int(2))
        #expect(all["var1"] == .int(3))
        #expect(all["var2"] == .int(4))
    }

    @Test("All properties handles conflicts")
    func allPropertiesConflicts() {
        let context = EvaluationContext(
            additionalProperties: ["test": .int(1)],
            profileVariables: ["test": .int(2)]
        )

        let all = context.allProperties

        // Additional properties should override profile variables
        #expect(all["test"] == .int(1))
    }

    // MARK: - Metadata Access Tests

    @Test("Access metadata by key")
    func accessMetadata() {
        let context = EvaluationContext(
            metadata: ["key": "value"]
        )

        #expect(context.metadata(for: "key") == "value")
    }

    @Test("Access non-existent metadata")
    func accessNonExistentMetadata() {
        let context = EvaluationContext.empty

        #expect(context.metadata(for: "nonexistent") == nil)
    }

    // MARK: - Builder Tests

    @Test("Build context with builder - location")
    func buildWithLocation() {
        let context = EvaluationContext.Builder()
            .location("Page 5")
            .build()

        #expect(context.documentLocation == "Page 5")
    }

    @Test("Build context with builder - single property")
    func buildWithSingleProperty() {
        let context = EvaluationContext.Builder()
            .property("test", value: .int(42))
            .build()

        #expect(context.property(named: "test") == .int(42))
    }

    @Test("Build context with builder - multiple properties")
    func buildWithMultipleProperties() {
        let context = EvaluationContext.Builder()
            .property("prop1", value: .int(1))
            .property("prop2", value: .bool(true))
            .property("prop3", value: .string("test"))
            .build()

        #expect(context.additionalProperties.count == 3)
        #expect(context.property(named: "prop1") == .int(1))
        #expect(context.property(named: "prop2") == .bool(true))
        #expect(context.property(named: "prop3") == .string("test"))
    }

    @Test("Build context with builder - properties dictionary")
    func buildWithPropertiesDictionary() {
        let context = EvaluationContext.Builder()
            .properties([
                "prop1": .int(1),
                "prop2": .bool(true)
            ])
            .build()

        #expect(context.additionalProperties.count == 2)
    }

    @Test("Build context with builder - single metadata")
    func buildWithSingleMetadata() {
        let context = EvaluationContext.Builder()
            .metadata("key", value: "value")
            .build()

        #expect(context.metadata(for: "key") == "value")
    }

    @Test("Build context with builder - multiple metadata")
    func buildWithMultipleMetadata() {
        let context = EvaluationContext.Builder()
            .metadata("key1", value: "value1")
            .metadata("key2", value: "value2")
            .build()

        #expect(context.metadata.count == 2)
        #expect(context.metadata(for: "key1") == "value1")
        #expect(context.metadata(for: "key2") == "value2")
    }

    @Test("Build context with builder - metadata dictionary")
    func buildWithMetadataDictionary() {
        let context = EvaluationContext.Builder()
            .metadata(["key1": "value1", "key2": "value2"])
            .build()

        #expect(context.metadata.count == 2)
    }

    @Test("Build context with builder - parent")
    func buildWithParent() {
        let parent = MockPDFObject(objectType: "Parent")
        let context = EvaluationContext.Builder()
            .parent(parent)
            .build()

        #expect(context.parentObject != nil)
    }

    @Test("Build context with builder - single variable")
    func buildWithSingleVariable() {
        let context = EvaluationContext.Builder()
            .variable("var", value: .int(42))
            .build()

        #expect(context.property(named: "var") == .int(42))
    }

    @Test("Build context with builder - multiple variables")
    func buildWithMultipleVariables() {
        let context = EvaluationContext.Builder()
            .variable("var1", value: .int(1))
            .variable("var2", value: .bool(true))
            .build()

        #expect(context.profileVariables.count == 2)
    }

    @Test("Build context with builder - variables dictionary")
    func buildWithVariablesDictionary() {
        let context = EvaluationContext.Builder()
            .variables([
                "var1": .int(1),
                "var2": .bool(true)
            ])
            .build()

        #expect(context.profileVariables.count == 2)
    }

    @Test("Build complex context with builder")
    func buildComplexContext() {
        let parent = MockPDFObject(objectType: "Parent")

        let context = EvaluationContext.Builder()
            .location("Page 5")
            .property("pageNumber", value: .int(5))
            .property("totalPages", value: .int(10))
            .metadata("fileName", value: "document.pdf")
            .metadata("profileName", value: "PDF/A-1b")
            .parent(parent)
            .variable("minVersion", value: .int(1))
            .variable("maxVersion", value: .int(5))
            .build()

        #expect(context.documentLocation == "Page 5")
        #expect(context.additionalProperties.count == 2)
        #expect(context.metadata.count == 2)
        #expect(context.parentObject != nil)
        #expect(context.profileVariables.count == 2)
    }

    @Test("Builder creates new instances")
    func builderCreatesNewInstances() {
        let builder = EvaluationContext.Builder()

        let context1 = builder
            .location("Page 1")
            .build()

        let context2 = builder
            .location("Page 2")
            .build()

        // Builder is a value type — each .location() call returns a new copy
        #expect(context1.documentLocation == "Page 1")
        #expect(context2.documentLocation == "Page 2")
    }

    // MARK: - Sendable Conformance Tests

    @Test("EvaluationContext is Sendable")
    func isSendable() {
        let context = EvaluationContext(documentLocation: "Page 1")

        Task {
            let _ = context
            #expect(true)
        }
    }

    // MARK: - Integration Tests

    @Test("Chain multiple context updates")
    func chainUpdates() {
        let context = EvaluationContext.empty
            .with(location: "Page 5")
            .with(properties: ["pageNumber": .int(5)])
            .with(metadata: ["fileName": "test.pdf"])
            .with(variables: ["minVersion": .int(1)])

        #expect(context.documentLocation == "Page 5")
        #expect(context.property(named: "pageNumber") == .int(5))
        #expect(context.metadata(for: "fileName") == "test.pdf")
        #expect(context.property(named: "minVersion") == .int(1))
    }

    @Test("Context immutability")
    func contextImmutability() {
        let original = EvaluationContext(
            documentLocation: "Page 1",
            additionalProperties: ["test": .int(1)]
        )

        let updated = original.with(location: "Page 2")

        #expect(original.documentLocation == "Page 1")
        #expect(updated.documentLocation == "Page 2")
        #expect(original.property(named: "test") == .int(1))
        #expect(updated.property(named: "test") == .int(1))
    }
}
