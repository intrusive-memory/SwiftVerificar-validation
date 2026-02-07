import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Dublin Core Schema Tests

@Suite("Dublin Core Schema Tests")
struct DublinCoreSchemaTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicProperties {

        @Test("Namespace and prefix")
        func namespaceAndPrefix() throws {
            #expect(DublinCoreSchema.namespaceURI == "http://purl.org/dc/elements/1.1/")
            #expect(DublinCoreSchema.preferredPrefix == "dc")
        }

        @Test("Initialize with all properties")
        func initializeWithAllProperties() throws {
            let now = Date()
            let schema = DublinCoreSchema(
                contributor: ["Contributor 1"],
                coverage: "Global",
                creator: ["Author 1", "Author 2"],
                date: [now],
                descriptionText: ["x-default": "Test description"],
                format: "application/pdf",
                identifier: "ISBN:1234567890",
                language: ["en", "de"],
                publisher: ["Publisher Inc"],
                relation: ["related-doc"],
                rights: ["x-default": "Copyright 2023"],
                source: "Original Source",
                subject: ["pdf", "validation"],
                title: ["x-default": "Test Document"],
                type: ["Text"]
            )

            #expect(schema.contributor == ["Contributor 1"])
            #expect(schema.creator == ["Author 1", "Author 2"])
            #expect(schema.title?["x-default"] == "Test Document")
        }

        @Test("Default initialization")
        func defaultInitialization() throws {
            let schema = DublinCoreSchema()

            #expect(schema.title == nil)
            #expect(schema.creator == nil)
            #expect(schema.descriptionText == nil)
        }

        @Test("Property names")
        func propertyNames() throws {
            let schema = DublinCoreSchema()
            let names = schema.propertyNames

            #expect(names.contains("title"))
            #expect(names.contains("creator"))
            #expect(names.contains("description"))
            #expect(names.contains("subject"))
        }
    }

    // MARK: - Convenience Accessors

    @Suite("Convenience Accessors")
    struct ConvenienceAccessors {

        @Test("Default title")
        func defaultTitle() throws {
            let schema = DublinCoreSchema(
                title: ["x-default": "Default Title", "en": "English Title"]
            )

            #expect(schema.defaultTitle == "Default Title")
        }

        @Test("Default title fallback")
        func defaultTitleFallback() throws {
            let schema = DublinCoreSchema(
                title: ["en": "English Title"]
            )

            #expect(schema.defaultTitle == "English Title")
        }

        @Test("Default description")
        func defaultDescription() throws {
            let schema = DublinCoreSchema(
                descriptionText: ["x-default": "Test description"]
            )

            #expect(schema.defaultDescription == "Test description")
        }

        @Test("Primary creator")
        func primaryCreator() throws {
            let schema = DublinCoreSchema(
                creator: ["First Author", "Second Author"]
            )

            #expect(schema.primaryCreator == "First Author")
        }

        @Test("Creators string")
        func creatorsString() throws {
            let schema = DublinCoreSchema(
                creator: ["Author 1", "Author 2"]
            )

            #expect(schema.creatorsString == "Author 1, Author 2")
        }

        @Test("Single creator string")
        func singleCreatorString() throws {
            let schema = DublinCoreSchema(
                creator: ["Single Author"]
            )

            #expect(schema.creatorsString == "Single Author")
        }

        @Test("Empty creators returns nil")
        func emptyCreatorsReturnsNil() throws {
            let schema = DublinCoreSchema()

            #expect(schema.creatorsString == nil)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccess {

        @Test("Get property by name")
        func getPropertyByName() throws {
            let schema = DublinCoreSchema(
                creator: ["Test Author"],
                title: ["x-default": "Test Title"]
            )

            let creatorValue = schema.property(named: "creator")
            #expect(creatorValue?.seqValues?.first?.textValue == "Test Author")

            let titleValue = schema.property(named: "title")
            #expect(titleValue?.langAltValue?["x-default"] == "Test Title")
        }

        @Test("Set property by name")
        func setPropertyByName() throws {
            var schema = DublinCoreSchema()

            schema.setProperty(named: "title", to: .langAlt(["x-default": "New Title"]))
            schema.setProperty(named: "creator", to: .seq([.text("New Author")]))
            schema.setProperty(named: "format", to: .text("application/pdf"))

            #expect(schema.title?["x-default"] == "New Title")
            #expect(schema.creator == ["New Author"])
            #expect(schema.format == "application/pdf")
        }

        @Test("Set text property from text value")
        func setTextPropertyFromTextValue() throws {
            var schema = DublinCoreSchema()

            schema.setProperty(named: "coverage", to: .text("Global"))

            #expect(schema.coverage == "Global")
        }

        @Test("Set array from single text")
        func setArrayFromSingleText() throws {
            var schema = DublinCoreSchema()

            schema.setProperty(named: "creator", to: .text("Single Author"))

            #expect(schema.creator == ["Single Author"])
        }
    }

    // MARK: - Validation

    @Suite("Validation")
    struct ValidationTests {

        @Test("Valid schema passes validation")
        func validSchemaPassesValidation() throws {
            let schema = DublinCoreSchema(
                creator: ["Author"],
                title: ["x-default": "Title"]
            )

            let issues = schema.validate()

            #expect(issues.filter { $0.severity == .error }.isEmpty)
        }

        @Test("Empty title warning")
        func emptyTitleWarning() throws {
            let schema = DublinCoreSchema(
                title: [:]  // Empty dictionary
            )

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "title" })
        }

        @Test("Empty creator warning")
        func emptyCreatorWarning() throws {
            let schema = DublinCoreSchema(
                creator: []  // Empty array
            )

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "creator" })
        }

        @Test("Invalid language code warning")
        func invalidLanguageCodeWarning() throws {
            let schema = DublinCoreSchema(
                language: ["invalid-language-code-too-long"]
            )

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "language" })
        }

        @Test("Valid language codes pass")
        func validLanguageCodesPass() throws {
            let schema = DublinCoreSchema(
                language: ["en", "de", "en-US", "zh-Hans"]
            )

            let issues = schema.validate()
            let languageIssues = issues.filter { $0.propertyName == "language" }

            #expect(languageIssues.isEmpty)
        }

        @Test("Invalid MIME type info")
        func invalidMIMETypeInfo() throws {
            let schema = DublinCoreSchema(
                format: "not a mime type"
            )

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "format" })
        }

        @Test("Valid MIME type passes")
        func validMIMETypePasses() throws {
            let schema = DublinCoreSchema(
                format: "application/pdf"
            )

            let issues = schema.validate()
            let formatIssues = issues.filter {
                $0.propertyName == "format" && $0.severity == .warning
            }

            #expect(formatIssues.isEmpty)
        }
    }

    // MARK: - XML Generation

    @Suite("XML Generation")
    struct XMLGenerationTests {

        @Test("Generate XML with title")
        func generateXMLWithTitle() throws {
            let schema = DublinCoreSchema(
                title: ["x-default": "Test Title", "en": "English Title"]
            )

            let xml = schema.toXML()

            #expect(xml.contains("<dc:title>"))
            #expect(xml.contains("rdf:Alt"))
            #expect(xml.contains("xml:lang=\"x-default\""))
        }

        @Test("Generate XML with creator")
        func generateXMLWithCreator() throws {
            let schema = DublinCoreSchema(
                creator: ["Author 1", "Author 2"]
            )

            let xml = schema.toXML()

            #expect(xml.contains("<dc:creator>"))
            #expect(xml.contains("rdf:Seq"))
            #expect(xml.contains("<rdf:li>Author 1</rdf:li>"))
        }

        @Test("Generate XML with subject bag")
        func generateXMLWithSubjectBag() throws {
            let schema = DublinCoreSchema(
                subject: ["pdf", "validation", "testing"]
            )

            let xml = schema.toXML()

            #expect(xml.contains("<dc:subject>"))
            #expect(xml.contains("rdf:Bag"))
        }

        @Test("XML escapes special characters")
        func xmlEscapesSpecialCharacters() throws {
            let schema = DublinCoreSchema(
                title: ["x-default": "Test <Title> & More"]
            )

            let xml = schema.toXML()

            #expect(xml.contains("&lt;"))
            #expect(xml.contains("&gt;"))
            #expect(xml.contains("&amp;"))
        }

        @Test("Empty schema generates no XML")
        func emptySchemaGeneratesNoXML() throws {
            let schema = DublinCoreSchema()

            let xml = schema.toXML()

            #expect(xml.isEmpty)
        }

        @Test("x-default comes first in langAlt")
        func xDefaultComesFirst() throws {
            let schema = DublinCoreSchema(
                title: ["en": "English", "x-default": "Default", "de": "German"]
            )

            let xml = schema.toXML()

            let xDefaultIndex = xml.range(of: "x-default")?.lowerBound
            let enIndex = xml.range(of: "\"en\"")?.lowerBound

            #expect(xDefaultIndex != nil)
            #expect(enIndex != nil)
            #expect(xDefaultIndex! < enIndex!)
        }
    }

    // MARK: - Property Descriptors

    @Suite("Property Descriptors")
    struct PropertyDescriptorTests {

        @Test("Property descriptors exist")
        func propertyDescriptorsExist() throws {
            let descriptors = DublinCoreSchema.propertyDescriptors

            #expect(descriptors.count == 15)
            #expect(descriptors.contains { $0.name == "title" })
            #expect(descriptors.contains { $0.name == "creator" })
            #expect(descriptors.contains { $0.name == "description" })
        }

        @Test("Info dict key mapping")
        func infoDictKeyMapping() throws {
            let descriptors = DublinCoreSchema.propertyDescriptors

            let titleDesc = descriptors.first { $0.name == "title" }
            #expect(titleDesc?.infoDictKey == "Title")

            let creatorDesc = descriptors.first { $0.name == "creator" }
            #expect(creatorDesc?.infoDictKey == "Author")

            let descDesc = descriptors.first { $0.name == "description" }
            #expect(descDesc?.infoDictKey == "Subject")
        }
    }

    // MARK: - Synchronization

    @Suite("Synchronization")
    struct SynchronizationTests {

        @Test("Synchronized properties list")
        func synchronizedPropertiesList() throws {
            let synced = DublinCoreSchema.synchronizedProperties

            #expect(synced.count == 3)
            #expect(synced.contains { $0.xmpProperty == "title" && $0.infoDictKey == "Title" })
            #expect(synced.contains { $0.xmpProperty == "creator" && $0.infoDictKey == "Author" })
            #expect(synced.contains { $0.xmpProperty == "description" && $0.infoDictKey == "Subject" })
        }

        @Test("Create from Info dictionary")
        func createFromInfoDictionary() throws {
            let schema = DublinCoreSchema.fromInfoDictionary(
                title: "Test Title",
                author: "Test Author",
                subject: "Test Subject"
            )

            #expect(schema.defaultTitle == "Test Title")
            #expect(schema.primaryCreator == "Test Author")
            #expect(schema.defaultDescription == "Test Subject")
        }

        @Test("Check synchronization - matching values")
        func checkSynchronizationMatching() throws {
            let schema = DublinCoreSchema(
                creator: ["Test Author"],
                descriptionText: ["x-default": "Test Subject"],
                title: ["x-default": "Test Title"]
            )

            let issues = schema.checkSynchronization(
                infoTitle: "Test Title",
                infoAuthor: "Test Author",
                infoSubject: "Test Subject"
            )

            #expect(issues.isEmpty)
        }

        @Test("Check synchronization - mismatched values")
        func checkSynchronizationMismatched() throws {
            let schema = DublinCoreSchema(
                creator: ["XMP Author"],
                title: ["x-default": "XMP Title"]
            )

            let issues = schema.checkSynchronization(
                infoTitle: "Info Title",
                infoAuthor: "Info Author",
                infoSubject: nil
            )

            #expect(issues.count == 2)
        }

        @Test("Check synchronization - missing XMP values")
        func checkSynchronizationMissingXMP() throws {
            let schema = DublinCoreSchema()

            let issues = schema.checkSynchronization(
                infoTitle: "Title",
                infoAuthor: nil,
                infoSubject: nil
            )

            #expect(issues.count == 1)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Equal schemas")
        func equalSchemas() throws {
            let schema1 = DublinCoreSchema(
                creator: ["Author"],
                title: ["x-default": "Title"]
            )
            let schema2 = DublinCoreSchema(
                creator: ["Author"],
                title: ["x-default": "Title"]
            )

            #expect(schema1 == schema2)
        }

        @Test("Unequal schemas")
        func unequalSchemas() throws {
            let schema1 = DublinCoreSchema(title: ["x-default": "Title 1"])
            let schema2 = DublinCoreSchema(title: ["x-default": "Title 2"])

            #expect(schema1 != schema2)
        }
    }
}
