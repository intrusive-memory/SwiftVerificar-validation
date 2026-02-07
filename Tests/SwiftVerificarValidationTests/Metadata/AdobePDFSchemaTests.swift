import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Adobe PDF Schema Tests

@Suite("Adobe PDF Schema Tests")
struct AdobePDFSchemaTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicProperties {

        @Test("Namespace and prefix")
        func namespaceAndPrefix() throws {
            #expect(AdobePDFSchema.namespaceURI == "http://ns.adobe.com/pdf/1.3/")
            #expect(AdobePDFSchema.preferredPrefix == "pdf")
        }

        @Test("Initialize with all properties")
        func initializeWithAllProperties() throws {
            let schema = AdobePDFSchema(
                keywords: "swift, pdf, validation",
                pdfVersion: "1.7",
                producer: "SwiftVerificar",
                trapped: .true
            )

            #expect(schema.keywords == "swift, pdf, validation")
            #expect(schema.pdfVersion == "1.7")
            #expect(schema.producer == "SwiftVerificar")
            #expect(schema.trapped == .true)
        }

        @Test("Default initialization")
        func defaultInitialization() throws {
            let schema = AdobePDFSchema()

            #expect(schema.keywords == nil)
            #expect(schema.pdfVersion == nil)
            #expect(schema.producer == nil)
            #expect(schema.trapped == nil)
        }

        @Test("Property names")
        func propertyNames() throws {
            let schema = AdobePDFSchema()
            let names = schema.propertyNames

            #expect(names.contains("Keywords"))
            #expect(names.contains("PDFVersion"))
            #expect(names.contains("Producer"))
            #expect(names.contains("Trapped"))
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccess {

        @Test("Get property by name")
        func getPropertyByName() throws {
            let schema = AdobePDFSchema(
                keywords: "test keywords",
                producer: "Test Producer"
            )

            #expect(schema.property(named: "Keywords")?.textValue == "test keywords")
            #expect(schema.property(named: "Producer")?.textValue == "Test Producer")
            #expect(schema.property(named: "PDFVersion") == nil)
        }

        @Test("Set property by name")
        func setPropertyByName() throws {
            var schema = AdobePDFSchema()

            schema.setProperty(named: "Keywords", to: .text("new keywords"))
            schema.setProperty(named: "Producer", to: .text("New Producer"))
            schema.setProperty(named: "PDFVersion", to: .text("2.0"))
            schema.setProperty(named: "Trapped", to: .text("True"))

            #expect(schema.keywords == "new keywords")
            #expect(schema.producer == "New Producer")
            #expect(schema.pdfVersion == "2.0")
            #expect(schema.trapped == .true)
        }

        @Test("Remove property")
        func removeProperty() throws {
            var schema = AdobePDFSchema(keywords: "test")

            schema.setProperty(named: "Keywords", to: nil)

            #expect(schema.keywords == nil)
        }
    }

    // MARK: - Trapped Value

    @Suite("Trapped Value")
    struct TrappedValueTests {

        @Test("Trapped value cases")
        func trappedValueCases() throws {
            #expect(TrappedValue.true.rawValue == "True")
            #expect(TrappedValue.false.rawValue == "False")
            #expect(TrappedValue.unknown.rawValue == "Unknown")
        }

        @Test("Create from PDF name")
        func createFromPDFName() throws {
            #expect(TrappedValue(pdfName: "true") == .true)
            #expect(TrappedValue(pdfName: "True") == .true)
            #expect(TrappedValue(pdfName: "false") == .false)
            #expect(TrappedValue(pdfName: "unknown") == .unknown)
            #expect(TrappedValue(pdfName: "invalid") == nil)
        }

        @Test("PDF name property")
        func pdfNameProperty() throws {
            #expect(TrappedValue.true.pdfName == "True")
            #expect(TrappedValue.false.pdfName == "False")
            #expect(TrappedValue.unknown.pdfName == "Unknown")
        }
    }

    // MARK: - Validation

    @Suite("Validation")
    struct ValidationTests {

        @Test("Valid schema passes validation")
        func validSchemaPassesValidation() throws {
            let schema = AdobePDFSchema(
                pdfVersion: "1.7",
                producer: "Test"
            )

            let issues = schema.validate()

            #expect(issues.filter { $0.severity == .error }.isEmpty)
        }

        @Test("Invalid PDF version warning")
        func invalidPDFVersionWarning() throws {
            let schema = AdobePDFSchema(pdfVersion: "invalid")

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "PDFVersion" })
        }

        @Test("Unknown trapped status info")
        func unknownTrappedStatusInfo() throws {
            let schema = AdobePDFSchema(trapped: .unknown)

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "Trapped" })
        }
    }

    // MARK: - XML Generation

    @Suite("XML Generation")
    struct XMLGenerationTests {

        @Test("Generate XML with all properties")
        func generateXMLWithAllProperties() throws {
            let schema = AdobePDFSchema(
                keywords: "test, xml",
                pdfVersion: "1.7",
                producer: "SwiftVerificar",
                trapped: .true
            )

            let xml = schema.toXML()

            #expect(xml.contains("<pdf:Keywords>"))
            #expect(xml.contains("<pdf:PDFVersion>1.7</pdf:PDFVersion>"))
            #expect(xml.contains("<pdf:Producer>SwiftVerificar</pdf:Producer>"))
            #expect(xml.contains("<pdf:Trapped>True</pdf:Trapped>"))
        }

        @Test("XML escapes special characters")
        func xmlEscapesSpecialCharacters() throws {
            let schema = AdobePDFSchema(keywords: "test <&> special")

            let xml = schema.toXML()

            #expect(xml.contains("&lt;"))
            #expect(xml.contains("&amp;"))
            #expect(xml.contains("&gt;"))
        }

        @Test("Empty schema generates no XML")
        func emptySchemaGeneratesNoXML() throws {
            let schema = AdobePDFSchema()

            let xml = schema.toXML()

            #expect(xml.isEmpty)
        }
    }

    // MARK: - Property Descriptors

    @Suite("Property Descriptors")
    struct PropertyDescriptorTests {

        @Test("Property descriptors exist")
        func propertyDescriptorsExist() throws {
            let descriptors = AdobePDFSchema.propertyDescriptors

            #expect(descriptors.count == 4)
            #expect(descriptors.contains { $0.name == "Keywords" })
            #expect(descriptors.contains { $0.name == "Producer" })
        }

        @Test("Info dict key mapping")
        func infoDictKeyMapping() throws {
            let descriptors = AdobePDFSchema.propertyDescriptors

            let keywordsDesc = descriptors.first { $0.name == "Keywords" }
            #expect(keywordsDesc?.infoDictKey == "Keywords")

            let producerDesc = descriptors.first { $0.name == "Producer" }
            #expect(producerDesc?.infoDictKey == "Producer")
        }
    }

    // MARK: - Synchronization

    @Suite("Synchronization")
    struct SynchronizationTests {

        @Test("Synchronized properties list")
        func synchronizedPropertiesList() throws {
            let synced = AdobePDFSchema.synchronizedProperties

            #expect(synced.count == 2)
            #expect(synced.contains { $0.xmpProperty == "Keywords" && $0.infoDictKey == "Keywords" })
            #expect(synced.contains { $0.xmpProperty == "Producer" && $0.infoDictKey == "Producer" })
        }

        @Test("Create from Info dictionary")
        func createFromInfoDictionary() throws {
            let schema = AdobePDFSchema.fromInfoDictionary(
                keywords: "test keywords",
                producer: "Test Producer",
                trapped: .true
            )

            #expect(schema.keywords == "test keywords")
            #expect(schema.producer == "Test Producer")
            #expect(schema.trapped == .true)
        }

        @Test("Check synchronization - matching values")
        func checkSynchronizationMatching() throws {
            let schema = AdobePDFSchema(
                keywords: "test",
                producer: "Producer"
            )

            let issues = schema.checkSynchronization(
                infoKeywords: "test",
                infoProducer: "Producer"
            )

            #expect(issues.isEmpty)
        }

        @Test("Check synchronization - mismatched values")
        func checkSynchronizationMismatched() throws {
            let schema = AdobePDFSchema(
                keywords: "xmp keywords",
                producer: "XMP Producer"
            )

            let issues = schema.checkSynchronization(
                infoKeywords: "info keywords",
                infoProducer: "Info Producer"
            )

            #expect(issues.count == 2)
            #expect(issues.allSatisfy { $0.severity == .error })
        }

        @Test("Check synchronization - missing XMP values")
        func checkSynchronizationMissingXMP() throws {
            let schema = AdobePDFSchema()

            let issues = schema.checkSynchronization(
                infoKeywords: "test",
                infoProducer: nil
            )

            #expect(issues.count == 1)
        }

        @Test("Check synchronization - missing Info values")
        func checkSynchronizationMissingInfo() throws {
            let schema = AdobePDFSchema(keywords: "test")

            let issues = schema.checkSynchronization(
                infoKeywords: nil,
                infoProducer: nil
            )

            #expect(issues.count == 1)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Equal schemas")
        func equalSchemas() throws {
            let schema1 = AdobePDFSchema(keywords: "test", producer: "Producer")
            let schema2 = AdobePDFSchema(keywords: "test", producer: "Producer")

            #expect(schema1 == schema2)
        }

        @Test("Unequal schemas")
        func unequalSchemas() throws {
            let schema1 = AdobePDFSchema(keywords: "test1")
            let schema2 = AdobePDFSchema(keywords: "test2")

            #expect(schema1 != schema2)
        }
    }
}
