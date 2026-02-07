import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - XMP Metadata Model Tests

@Suite("XMP Metadata Model Tests")
struct XMPMetadataModelTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicProperties {

        @Test("Default initialization")
        func defaultInitialization() throws {
            let model = XMPMetadataModel()

            #expect(model.title == nil)
            #expect(model.creator == nil)
            #expect(model.pdfaPart == nil)
        }

        @Test("Initialize with schemas")
        func initializeWithSchemas() throws {
            let dc = DublinCoreSchema(
                creator: ["Test Author"],
                title: ["x-default": "Test Title"]
            )
            let xmpBasic = XMPBasicSchema(creatorTool: "SwiftVerificar")
            let adobePDF = AdobePDFSchema(producer: "Producer")

            let model = XMPMetadataModel(
                dublinCore: dc,
                xmpBasic: xmpBasic,
                adobePDF: adobePDF
            )

            #expect(model.title == "Test Title")
            #expect(model.creator == "Test Author")
            #expect(model.creatorTool == "SwiftVerificar")
            #expect(model.producer == "Producer")
        }
    }

    // MARK: - Convenience Accessors

    @Suite("Convenience Accessors")
    struct ConvenienceAccessors {

        @Test("Title accessor")
        func titleAccessor() throws {
            var model = XMPMetadataModel()
            model.dublinCore.title = ["x-default": "Test Title"]

            #expect(model.title == "Test Title")
        }

        @Test("Creator accessor")
        func creatorAccessor() throws {
            var model = XMPMetadataModel()
            model.dublinCore.creator = ["Author 1", "Author 2"]

            #expect(model.creator == "Author 1, Author 2")
        }

        @Test("Description accessor")
        func descriptionAccessor() throws {
            var model = XMPMetadataModel()
            model.dublinCore.descriptionText = ["x-default": "Test Desc"]

            #expect(model.description == "Test Desc")
        }

        @Test("Keywords accessor")
        func keywordsAccessor() throws {
            var model = XMPMetadataModel()
            model.adobePDF.keywords = "test, keywords"

            #expect(model.keywords == "test, keywords")
        }

        @Test("CreatorTool accessor")
        func creatorToolAccessor() throws {
            var model = XMPMetadataModel()
            model.xmpBasic.creatorTool = "Test Tool"

            #expect(model.creatorTool == "Test Tool")
        }

        @Test("Producer accessor")
        func producerAccessor() throws {
            var model = XMPMetadataModel()
            model.adobePDF.producer = "Test Producer"

            #expect(model.producer == "Test Producer")
        }

        @Test("Date accessors")
        func dateAccessors() throws {
            let now = Date()
            var model = XMPMetadataModel()
            model.xmpBasic.createDate = now
            model.xmpBasic.modifyDate = now

            #expect(model.createDate == now)
            #expect(model.modifyDate == now)
        }

        @Test("PDF/A identification accessors")
        func pdfaIdentificationAccessors() throws {
            var model = XMPMetadataModel()
            model.pdfaIdentification.part = 2
            model.pdfaIdentification.conformance = "B"

            #expect(model.pdfaPart == 2)
            #expect(model.pdfaConformance == "B")
        }
    }

    // MARK: - Validation

    @Suite("Validation")
    struct ValidationTests {

        @Test("Valid model passes validation")
        func validModelPassesValidation() throws {
            let model = XMPMetadataModel(
                dublinCore: DublinCoreSchema(
                    creator: ["Author"],
                    title: ["x-default": "Title"]
                ),
                pdfaIdentification: PDFAIdentificationSchema(
                    part: 2,
                    conformance: "B"
                )
            )

            let issues = model.validate()
            let errors = issues.filter { $0.severity == .error }

            #expect(errors.isEmpty)
        }

        @Test("Custom schemas warning")
        func customSchemasWarning() throws {
            var model = XMPMetadataModel()
            model.customSchemas["http://unknown.ns/"] = ["property": .text("value")]

            let issues = model.validate()

            #expect(issues.contains { $0.message.contains("extension schema") })
        }
    }

    // MARK: - PDF/A Identification Validation

    @Suite("PDF/A Identification Validation")
    struct PDFAIdentificationValidationTests {

        @Test("Valid PDF/A identification")
        func validPDFAIdentification() throws {
            let model = XMPMetadataModel(
                pdfaIdentification: PDFAIdentificationSchema(part: 2, conformance: "B")
            )

            let issues = model.validatePDFAIdentification(expectedPart: 2, expectedLevel: "B")

            #expect(issues.isEmpty)
        }

        @Test("Missing PDF/A part")
        func missingPDFAPart() throws {
            let model = XMPMetadataModel(
                pdfaIdentification: PDFAIdentificationSchema()
            )

            let issues = model.validatePDFAIdentification()

            #expect(issues.contains { $0.propertyName == "part" })
        }

        @Test("Missing PDF/A conformance")
        func missingPDFAConformance() throws {
            let model = XMPMetadataModel(
                pdfaIdentification: PDFAIdentificationSchema(part: 2)
            )

            let issues = model.validatePDFAIdentification()

            #expect(issues.contains { $0.propertyName == "conformance" })
        }

        @Test("Wrong PDF/A part")
        func wrongPDFAPart() throws {
            let model = XMPMetadataModel(
                pdfaIdentification: PDFAIdentificationSchema(part: 2, conformance: "B")
            )

            let issues = model.validatePDFAIdentification(expectedPart: 3)

            #expect(issues.contains { $0.propertyName == "part" })
        }

        @Test("Wrong PDF/A conformance")
        func wrongPDFAConformance() throws {
            let model = XMPMetadataModel(
                pdfaIdentification: PDFAIdentificationSchema(part: 2, conformance: "B")
            )

            let issues = model.validatePDFAIdentification(expectedLevel: "A")

            #expect(issues.contains { $0.propertyName == "conformance" })
        }
    }

    // MARK: - XML Generation

    @Suite("XML Generation")
    struct XMLGenerationTests {

        @Test("Generate XML with wrapper")
        func generateXMLWithWrapper() throws {
            let model = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test"])
            )

            let xml = model.toXML(includeWrapper: true)

            #expect(xml.contains("<?xpacket begin"))
            #expect(xml.contains("<?xpacket end"))
            #expect(xml.contains("x:xmpmeta"))
        }

        @Test("Generate XML without wrapper")
        func generateXMLWithoutWrapper() throws {
            let model = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test"])
            )

            let xml = model.toXML(includeWrapper: false)

            #expect(!xml.contains("<?xpacket"))
            #expect(xml.contains("x:xmpmeta"))
        }

        @Test("XML includes all namespaces")
        func xmlIncludesAllNamespaces() throws {
            let model = XMPMetadataModel()

            let xml = model.toXML()

            #expect(xml.contains(DublinCoreSchema.namespaceURI))
            #expect(xml.contains(XMPBasicSchema.namespaceURI))
            #expect(xml.contains(AdobePDFSchema.namespaceURI))
        }

        @Test("XML includes schema content")
        func xmlIncludesSchemaContent() throws {
            let model = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test Title"]),
                xmpBasic: XMPBasicSchema(creatorTool: "SwiftVerificar"),
                pdfaIdentification: PDFAIdentificationSchema(part: 2, conformance: "B")
            )

            let xml = model.toXML()

            #expect(xml.contains("Test Title"))
            #expect(xml.contains("SwiftVerificar"))
            #expect(xml.contains("<pdfaid:part>2</pdfaid:part>"))
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryMethodTests {

        @Test("Create from Info dictionary")
        func createFromInfoDictionary() throws {
            let info = InfoDictionary(
                title: "Test Title",
                author: "Test Author",
                subject: "Test Subject",
                keywords: "test, keywords",
                creator: "Test Creator",
                producer: "Test Producer",
                creationDate: "D:20230615120000Z",
                modDate: "D:20230615130000Z"
            )

            let model = XMPMetadataModel.fromInfoDictionary(info)

            #expect(model.title == "Test Title")
            #expect(model.creator == "Test Author")
            #expect(model.description == "Test Subject")
            #expect(model.keywords == "test, keywords")
            #expect(model.creatorTool == "Test Creator")
            #expect(model.producer == "Test Producer")
        }

        @Test("Create with PDF/A identification")
        func createWithPDFAIdentification() throws {
            let model = XMPMetadataModel.withPDFAIdentification(part: 3, conformance: "U")

            #expect(model.pdfaPart == 3)
            #expect(model.pdfaConformance == "U")
        }

        @Test("Create minimal PDF/A")
        func createMinimalPDFA() throws {
            let model = XMPMetadataModel.minimalPDFA(
                title: "Test",
                creator: "Author",
                pdfaPart: 2,
                pdfaConformance: "B"
            )

            #expect(model.title == "Test")
            #expect(model.creator == "Author")
            #expect(model.pdfaPart == 2)
            #expect(model.pdfaConformance == "B")
            #expect(model.createDate != nil)
            #expect(model.modifyDate != nil)
        }
    }

    // MARK: - PDF/A Identification Schema

    @Suite("PDF/A Identification Schema")
    struct PDFAIdentificationSchemaTests {

        @Test("Namespace and prefix")
        func namespaceAndPrefix() throws {
            #expect(PDFAIdentificationSchema.namespaceURI == "http://www.aiim.org/pdfa/ns/id/")
            #expect(PDFAIdentificationSchema.preferredPrefix == "pdfaid")
        }

        @Test("Valid PDF/A-1 levels")
        func validPDFA1Levels() throws {
            let issues1a = PDFAIdentificationSchema(part: 1, conformance: "A").validate()
            let issues1b = PDFAIdentificationSchema(part: 1, conformance: "B").validate()

            #expect(issues1a.filter { $0.propertyName == "conformance" }.isEmpty)
            #expect(issues1b.filter { $0.propertyName == "conformance" }.isEmpty)
        }

        @Test("Valid PDF/A-2 levels")
        func validPDFA2Levels() throws {
            let issues2a = PDFAIdentificationSchema(part: 2, conformance: "A").validate()
            let issues2b = PDFAIdentificationSchema(part: 2, conformance: "B").validate()
            let issues2u = PDFAIdentificationSchema(part: 2, conformance: "U").validate()

            #expect(issues2a.filter { $0.propertyName == "conformance" }.isEmpty)
            #expect(issues2b.filter { $0.propertyName == "conformance" }.isEmpty)
            #expect(issues2u.filter { $0.propertyName == "conformance" }.isEmpty)
        }

        @Test("Invalid part value")
        func invalidPartValue() throws {
            let schema = PDFAIdentificationSchema(part: 5, conformance: "B")

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "part" && $0.severity == .error })
        }

        @Test("Generate XML")
        func generateXML() throws {
            let schema = PDFAIdentificationSchema(
                part: 2,
                conformance: "B",
                amd: "1",
                rev: 2020
            )

            let xml = schema.toXML()

            #expect(xml.contains("<pdfaid:part>2</pdfaid:part>"))
            #expect(xml.contains("<pdfaid:conformance>B</pdfaid:conformance>"))
            #expect(xml.contains("<pdfaid:amd>1</pdfaid:amd>"))
            #expect(xml.contains("<pdfaid:rev>2020</pdfaid:rev>"))
        }
    }

    // MARK: - XMP Media Management Schema

    @Suite("XMP Media Management Schema")
    struct XMPMediaManagementSchemaTests {

        @Test("Namespace and prefix")
        func namespaceAndPrefix() throws {
            #expect(XMPMediaManagementSchema.namespaceURI == "http://ns.adobe.com/xap/1.0/mm/")
            #expect(XMPMediaManagementSchema.preferredPrefix == "xmpMM")
        }

        @Test("Initialize with properties")
        func initializeWithProperties() throws {
            let schema = XMPMediaManagementSchema(
                documentID: "doc-123",
                instanceID: "inst-456",
                originalDocumentID: "orig-789",
                versionID: "1.0"
            )

            #expect(schema.documentID == "doc-123")
            #expect(schema.instanceID == "inst-456")
            #expect(schema.originalDocumentID == "orig-789")
            #expect(schema.versionID == "1.0")
        }

        @Test("Validation recommends documentID")
        func validationRecommendsDocumentID() throws {
            let schema = XMPMediaManagementSchema()

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "DocumentID" })
        }

        @Test("Generate XML")
        func generateXML() throws {
            let schema = XMPMediaManagementSchema(
                documentID: "doc-123",
                instanceID: "inst-456"
            )

            let xml = schema.toXML()

            #expect(xml.contains("<xmpMM:DocumentID>doc-123</xmpMM:DocumentID>"))
            #expect(xml.contains("<xmpMM:InstanceID>inst-456</xmpMM:InstanceID>"))
        }
    }

    // MARK: - Resource Event

    @Suite("Resource Event")
    struct ResourceEventTests {

        @Test("Create resource event")
        func createResourceEvent() throws {
            let event = ResourceEvent(
                action: "created",
                when: Date(),
                instanceID: "inst-123",
                softwareAgent: "SwiftVerificar"
            )

            #expect(event.action == "created")
            #expect(event.instanceID == "inst-123")
            #expect(event.softwareAgent == "SwiftVerificar")
        }
    }

    // MARK: - Resource Ref

    @Suite("Resource Ref")
    struct ResourceRefTests {

        @Test("Create resource ref")
        func createResourceRef() throws {
            let ref = ResourceRef(
                documentID: "doc-123",
                instanceID: "inst-456",
                renditionClass: "proof"
            )

            #expect(ref.documentID == "doc-123")
            #expect(ref.instanceID == "inst-456")
            #expect(ref.renditionClass == "proof")
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Equal models")
        func equalModels() throws {
            let model1 = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test"]),
                pdfaIdentification: PDFAIdentificationSchema(part: 2, conformance: "B")
            )
            let model2 = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test"]),
                pdfaIdentification: PDFAIdentificationSchema(part: 2, conformance: "B")
            )

            #expect(model1 == model2)
        }

        @Test("Unequal models")
        func unequalModels() throws {
            let model1 = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test 1"])
            )
            let model2 = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test 2"])
            )

            #expect(model1 != model2)
        }
    }
}
