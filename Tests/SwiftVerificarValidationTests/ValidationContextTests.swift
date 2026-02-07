import Testing
@testable import SwiftVerificarValidation

@Suite("ValidationContext Tests")
struct ValidationContextTests {

    // MARK: - Initialization Tests

    @Test("Create ValidationContext with all parameters")
    func createWithAllParameters() {
        let context = ValidationContext(
            objectIdentifier: "Page 5",
            ruleId: "rule-42",
            location: "page:5,obj:123",
            metadata: ["key1": "value1", "key2": "value2"]
        )

        #expect(context.objectIdentifier == "Page 5")
        #expect(context.ruleId == "rule-42")
        #expect(context.location == "page:5,obj:123")
        #expect(context.metadata.count == 2)
        #expect(context.metadata["key1"] == "value1")
        #expect(context.metadata["key2"] == "value2")
    }

    @Test("Create ValidationContext with minimal parameters")
    func createWithMinimalParameters() {
        let context = ValidationContext(objectIdentifier: "Document")

        #expect(context.objectIdentifier == "Document")
        #expect(context.ruleId == nil)
        #expect(context.location == nil)
        #expect(context.metadata.isEmpty)
    }

    @Test("Create ValidationContext with object identifier only")
    func createWithObjectIdentifierOnly() {
        let context = ValidationContext(objectIdentifier: "Font /F1")

        #expect(context.objectIdentifier == "Font /F1")
        #expect(context.ruleId == nil)
        #expect(context.location == nil)
    }

    // MARK: - Description Tests

    @Test("Description includes object identifier")
    func descriptionWithObjectIdentifier() {
        let context = ValidationContext(objectIdentifier: "Page 1")

        let description = context.description
        #expect(description.contains("Page 1"))
    }

    @Test("Description includes rule ID when provided")
    func descriptionWithRuleId() {
        let context = ValidationContext(
            objectIdentifier: "Annotation",
            ruleId: "rule-123"
        )

        let description = context.description
        #expect(description.contains("Annotation"))
        #expect(description.contains("rule=rule-123"))
    }

    @Test("Description includes location when provided")
    func descriptionWithLocation() {
        let context = ValidationContext(
            objectIdentifier: "Image",
            location: "page:10"
        )

        let description = context.description
        #expect(description.contains("Image"))
        #expect(description.contains("location=page:10"))
    }

    @Test("Description includes metadata when provided")
    func descriptionWithMetadata() {
        let context = ValidationContext(
            objectIdentifier: "Stream",
            metadata: ["filter": "FlateDecode", "length": "1024"]
        )

        let description = context.description
        #expect(description.contains("Stream"))
        #expect(description.contains("filter=FlateDecode") || description.contains("length=1024"))
    }

    @Test("Description with all components")
    func descriptionComplete() {
        let context = ValidationContext(
            objectIdentifier: "Font /F1",
            ruleId: "rule-font-001",
            location: "page:5,obj:42",
            metadata: ["type": "Type1", "encoding": "WinAnsiEncoding"]
        )

        let description = context.description
        #expect(description.contains("Font /F1"))
        #expect(description.contains("rule=rule-font-001"))
        #expect(description.contains("location=page:5,obj:42"))
        // Metadata order is not guaranteed, just check one is present
        #expect(description.contains("type=Type1") || description.contains("encoding=WinAnsiEncoding"))
    }

    @Test("Description formats parts correctly with commas")
    func descriptionFormattingWithCommas() {
        let context = ValidationContext(
            objectIdentifier: "Object",
            ruleId: "rule-1",
            location: "loc-1"
        )

        let description = context.description
        let commaCount = description.filter { $0 == "," }.count
        #expect(commaCount == 2) // Object, rule=rule-1, location=loc-1
    }

    // MARK: - Sendable Conformance

    @Test("ValidationContext is Sendable")
    func isSendable() {
        let context = ValidationContext(objectIdentifier: "Test")

        Task {
            let _ = context
            #expect(true)
        }
    }

    // MARK: - Metadata Tests

    @Test("Empty metadata dictionary works correctly")
    func emptyMetadata() {
        let context = ValidationContext(
            objectIdentifier: "Object",
            metadata: [:]
        )

        #expect(context.metadata.isEmpty)
        #expect(!context.description.contains("="))
    }

    @Test("Single metadata entry")
    func singleMetadataEntry() {
        let context = ValidationContext(
            objectIdentifier: "Object",
            metadata: ["key": "value"]
        )

        #expect(context.metadata.count == 1)
        #expect(context.metadata["key"] == "value")
        #expect(context.description.contains("key=value"))
    }

    @Test("Multiple metadata entries")
    func multipleMetadataEntries() {
        let context = ValidationContext(
            objectIdentifier: "Object",
            metadata: [
                "key1": "value1",
                "key2": "value2",
                "key3": "value3"
            ]
        )

        #expect(context.metadata.count == 3)
        #expect(context.metadata["key1"] == "value1")
        #expect(context.metadata["key2"] == "value2")
        #expect(context.metadata["key3"] == "value3")
    }
}
