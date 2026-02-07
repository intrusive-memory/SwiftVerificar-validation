import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - XMP Schema Tests

@Suite("XMP Schema Tests")
struct XMPSchemaTests {

    // MARK: - XMP Value Tests

    @Suite("XMP Value")
    struct XMPValueTests {

        @Test("Text value")
        func textValue() throws {
            let value = XMPValue.text("Hello")
            #expect(value.textValue == "Hello")
            #expect(value.isSimple)
            #expect(!value.isArray)
        }

        @Test("URI value")
        func uriValue() throws {
            let value = XMPValue.uri("http://example.com")
            #expect(value.textValue == "http://example.com")
        }

        @Test("Date value")
        func dateValue() throws {
            let date = Date()
            let value = XMPValue.date(date)
            #expect(value.dateValue == date)
            #expect(value.isSimple)
        }

        @Test("Integer value")
        func integerValue() throws {
            let value = XMPValue.integer(42)
            #expect(value.integerValue == 42)
            #expect(value.realValue == 42.0)
        }

        @Test("Boolean value")
        func booleanValue() throws {
            let value = XMPValue.boolean(true)
            #expect(value.booleanValue == true)
        }

        @Test("Real value")
        func realValue() throws {
            let value = XMPValue.real(3.14)
            #expect(value.realValue == 3.14)
        }

        @Test("LangAlt value")
        func langAltValue() throws {
            let value = XMPValue.langAlt([
                "x-default": "Default Text",
                "en": "English Text"
            ])
            #expect(value.langAltValue?["x-default"] == "Default Text")
            #expect(value.defaultLanguageText == "Default Text")
            #expect(value.isLangAlt)
        }

        @Test("Bag value")
        func bagValue() throws {
            let value = XMPValue.bag([.text("one"), .text("two")])
            #expect(value.bagValues?.count == 2)
            #expect(value.arrayValues?.count == 2)
            #expect(value.isArray)
        }

        @Test("Seq value")
        func seqValue() throws {
            let value = XMPValue.seq([.text("first"), .text("second")])
            #expect(value.seqValues?.count == 2)
        }

        @Test("Alt value")
        func altValue() throws {
            let value = XMPValue.alt([.text("option1")])
            #expect(value.altValues?.count == 1)
        }

        @Test("Structure value")
        func structureValue() throws {
            let value = XMPValue.structure([
                "name": .text("John"),
                "age": .integer(30)
            ])
            #expect(value.structureValue?["name"]?.textValue == "John")
            #expect(value.isStructure)
        }

        @Test("String literal expressibility")
        func stringLiteralExpressibility() throws {
            let value: XMPValue = "Hello"
            #expect(value.textValue == "Hello")
        }

        @Test("Integer literal expressibility")
        func integerLiteralExpressibility() throws {
            let value: XMPValue = 42
            #expect(value.integerValue == 42)
        }

        @Test("Float literal expressibility")
        func floatLiteralExpressibility() throws {
            let value: XMPValue = 3.14
            #expect(value.realValue == 3.14)
        }

        @Test("Boolean literal expressibility")
        func booleanLiteralExpressibility() throws {
            let value: XMPValue = true
            #expect(value.booleanValue == true)
        }

        @Test("Description")
        func description() throws {
            #expect(XMPValue.text("test").description == "test")
            #expect(XMPValue.integer(42).description == "42")
            #expect(XMPValue.boolean(true).description == "True")
        }
    }

    // MARK: - XMP Validation Issue Tests

    @Suite("XMP Validation Issue")
    struct XMPValidationIssueTests {

        @Test("Create validation issue")
        func createValidationIssue() throws {
            let issue = XMPValidationIssue(
                severity: .error,
                namespace: "http://test.ns/",
                propertyName: "testProperty",
                message: "Test error message",
                ruleId: "TEST-001"
            )

            #expect(issue.severity == .error)
            #expect(issue.namespace == "http://test.ns/")
            #expect(issue.propertyName == "testProperty")
            #expect(issue.message == "Test error message")
            #expect(issue.ruleId == "TEST-001")
        }

        @Test("Severity levels")
        func severityLevels() throws {
            #expect(XMPValidationIssue.Severity.error.rawValue == "error")
            #expect(XMPValidationIssue.Severity.warning.rawValue == "warning")
            #expect(XMPValidationIssue.Severity.info.rawValue == "info")
        }
    }

    // MARK: - XMP Schema Registry Tests

    @Suite("XMP Schema Registry")
    struct XMPSchemaRegistryTests {

        @Test("Get prefix for namespace")
        func getPrefixForNamespace() throws {
            let registry = XMPSchemaRegistry.shared

            #expect(registry.prefix(for: "http://purl.org/dc/elements/1.1/") == "dc")
            #expect(registry.prefix(for: "http://ns.adobe.com/xap/1.0/") == "xmp")
            #expect(registry.prefix(for: "http://ns.adobe.com/pdf/1.3/") == "pdf")
        }

        @Test("Get namespace for prefix")
        func getNamespaceForPrefix() throws {
            let registry = XMPSchemaRegistry.shared

            #expect(registry.namespaceURI(for: "dc") == "http://purl.org/dc/elements/1.1/")
            #expect(registry.namespaceURI(for: "xmp") == "http://ns.adobe.com/xap/1.0/")
        }

        @Test("Unknown namespace returns nil")
        func unknownNamespaceReturnsNil() throws {
            let registry = XMPSchemaRegistry.shared

            #expect(registry.prefix(for: "http://unknown.ns/") == nil)
            #expect(registry.namespaceURI(for: "unknown") == nil)
        }

        @Test("All namespaces and prefixes")
        func allNamespacesAndPrefixes() throws {
            let registry = XMPSchemaRegistry.shared

            #expect(registry.allNamespaceURIs.count > 0)
            #expect(registry.allPrefixes.count > 0)
            #expect(registry.allNamespaceURIs.contains("http://purl.org/dc/elements/1.1/"))
            #expect(registry.allPrefixes.contains("dc"))
        }
    }

    // MARK: - XMP Property Type Tests

    @Suite("XMP Property Type")
    struct XMPPropertyTypeTests {

        @Test("Property type raw values")
        func propertyTypeRawValues() throws {
            #expect(XMPPropertyType.text.rawValue == "Text")
            #expect(XMPPropertyType.date.rawValue == "Date")
            #expect(XMPPropertyType.langAlt.rawValue == "Lang Alt")
            #expect(XMPPropertyType.bag.rawValue == "bag")
            #expect(XMPPropertyType.seq.rawValue == "seq")
        }
    }

    // MARK: - XMP Property Descriptor Tests

    @Suite("XMP Property Descriptor")
    struct XMPPropertyDescriptorTests {

        @Test("Create property descriptor")
        func createPropertyDescriptor() throws {
            let descriptor = XMPPropertyDescriptor(
                name: "Title",
                type: .langAlt,
                description: "Document title",
                isRequired: true,
                infoDictKey: "Title"
            )

            #expect(descriptor.name == "Title")
            #expect(descriptor.type == .langAlt)
            #expect(descriptor.description == "Document title")
            #expect(descriptor.isRequired)
            #expect(descriptor.infoDictKey == "Title")
        }
    }

    // MARK: - XMP Extension Schema Tests

    @Suite("XMP Extension Schema")
    struct XMPExtensionSchemaTests {

        @Test("Create extension schema")
        func createExtensionSchema() throws {
            let property = XMPPropertyDescriptor(
                name: "CustomProp",
                type: .text,
                description: "A custom property"
            )

            let schema = XMPExtensionSchema(
                namespaceURI: "http://custom.ns/",
                prefix: "custom",
                schemaDescription: "Custom Schema",
                properties: [property]
            )

            #expect(schema.namespaceURI == "http://custom.ns/")
            #expect(schema.prefix == "custom")
            #expect(schema.properties.count == 1)
        }

        @Test("Generate extension XML")
        func generateExtensionXML() throws {
            let property = XMPPropertyDescriptor(
                name: "CustomProp",
                type: .text,
                description: "A custom property"
            )

            let schema = XMPExtensionSchema(
                namespaceURI: "http://custom.ns/",
                prefix: "custom",
                schemaDescription: "Custom Schema",
                properties: [property]
            )

            let xml = schema.toExtensionXML()

            #expect(xml.contains("pdfaSchema:schema"))
            #expect(xml.contains("Custom Schema"))
            #expect(xml.contains("http://custom.ns/"))
            #expect(xml.contains("CustomProp"))
        }
    }
}
