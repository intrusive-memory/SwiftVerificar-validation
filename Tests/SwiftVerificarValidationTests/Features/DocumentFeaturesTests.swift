import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - DocumentFeatures Tests

@Suite("DocumentFeatures Tests")
struct DocumentFeaturesTests {

    // MARK: - Initialization

    @Test("DocumentFeatures creates with default values")
    func defaultInit() {
        let features = DocumentFeatures()
        #expect(features.title == nil)
        #expect(features.author == nil)
        #expect(features.pdfVersion == "1.4")
        #expect(features.isLinearized == false)
        #expect(features.isEncrypted == false)
        #expect(features.pageCount == 0)
        #expect(features.isTagged == false)
    }

    @Test("DocumentFeatures creates with all parameters")
    func fullInit() {
        let creationDate = Date()
        let modDate = Date()

        let features = DocumentFeatures(
            title: "Test Document",
            author: "John Doe",
            subject: "Testing",
            keywords: "test, pdf",
            creator: "Test App",
            producer: "SwiftVerificar",
            creationDate: creationDate,
            modificationDate: modDate,
            trapped: .trapped,
            pdfVersion: "2.0",
            isLinearized: true,
            isEncrypted: true,
            encryptionMethod: "AES-256",
            pageCount: 10,
            isTagged: true,
            hasXMPMetadata: true,
            hasAcroForm: true,
            hasXFA: false,
            embeddedFileCount: 3,
            hasOutlines: true,
            outputIntentCount: 1,
            claimedPDFAConformance: "3b",
            claimedPDFUAConformance: "1",
            claimedPDFXConformance: nil
        )

        #expect(features.title == "Test Document")
        #expect(features.author == "John Doe")
        #expect(features.subject == "Testing")
        #expect(features.keywords == "test, pdf")
        #expect(features.creator == "Test App")
        #expect(features.producer == "SwiftVerificar")
        #expect(features.creationDate == creationDate)
        #expect(features.modificationDate == modDate)
        #expect(features.trapped == .trapped)
        #expect(features.pdfVersion == "2.0")
        #expect(features.isLinearized == true)
        #expect(features.isEncrypted == true)
        #expect(features.encryptionMethod == "AES-256")
        #expect(features.pageCount == 10)
        #expect(features.isTagged == true)
        #expect(features.hasXMPMetadata == true)
        #expect(features.hasAcroForm == true)
        #expect(features.hasXFA == false)
        #expect(features.embeddedFileCount == 3)
        #expect(features.hasOutlines == true)
        #expect(features.outputIntentCount == 1)
        #expect(features.claimedPDFAConformance == "3b")
        #expect(features.claimedPDFUAConformance == "1")
        #expect(features.claimedPDFXConformance == nil)
    }

    // MARK: - Computed Properties

    @Test("DocumentFeatures major version extraction")
    func majorVersion() {
        #expect(DocumentFeatures(pdfVersion: "1.4").majorVersion == 1)
        #expect(DocumentFeatures(pdfVersion: "1.7").majorVersion == 1)
        #expect(DocumentFeatures(pdfVersion: "2.0").majorVersion == 2)
    }

    @Test("DocumentFeatures minor version extraction")
    func minorVersion() {
        #expect(DocumentFeatures(pdfVersion: "1.4").minorVersion == 4)
        #expect(DocumentFeatures(pdfVersion: "1.7").minorVersion == 7)
        #expect(DocumentFeatures(pdfVersion: "2.0").minorVersion == 0)
    }

    @Test("DocumentFeatures isPDF2 property")
    func isPDF2() {
        #expect(DocumentFeatures(pdfVersion: "1.4").isPDF2 == false)
        #expect(DocumentFeatures(pdfVersion: "1.7").isPDF2 == false)
        #expect(DocumentFeatures(pdfVersion: "2.0").isPDF2 == true)
    }

    @Test("DocumentFeatures hasConformance property")
    func hasConformance() {
        #expect(DocumentFeatures().hasConformance == false)
        #expect(DocumentFeatures(claimedPDFAConformance: "1b").hasConformance == true)
        #expect(DocumentFeatures(claimedPDFUAConformance: "1").hasConformance == true)
        #expect(DocumentFeatures(claimedPDFXConformance: "3").hasConformance == true)
    }

    @Test("DocumentFeatures hasInfoDictionary property")
    func hasInfoDictionary() {
        #expect(DocumentFeatures().hasInfoDictionary == false)
        #expect(DocumentFeatures(title: "Test").hasInfoDictionary == true)
        #expect(DocumentFeatures(author: "Author").hasInfoDictionary == true)
        #expect(DocumentFeatures(creationDate: Date()).hasInfoDictionary == true)
    }

    @Test("DocumentFeatures hasEmbeddedFiles property")
    func hasEmbeddedFiles() {
        #expect(DocumentFeatures(embeddedFileCount: 0).hasEmbeddedFiles == false)
        #expect(DocumentFeatures(embeddedFileCount: 1).hasEmbeddedFiles == true)
        #expect(DocumentFeatures(embeddedFileCount: 5).hasEmbeddedFiles == true)
    }

    @Test("DocumentFeatures hasForms property")
    func hasForms() {
        #expect(DocumentFeatures().hasForms == false)
        #expect(DocumentFeatures(hasAcroForm: true).hasForms == true)
        #expect(DocumentFeatures(hasXFA: true).hasForms == true)
        #expect(DocumentFeatures(hasAcroForm: true, hasXFA: true).hasForms == true)
    }

    // MARK: - Conversion to FeatureNode

    @Test("DocumentFeatures converts to FeatureNode")
    func toFeatureNode() {
        let features = DocumentFeatures(
            title: "Test",
            pdfVersion: "1.7",
            pageCount: 5,
            isTagged: true
        )

        let node = features.toFeatureNode()

        #expect(node.featureType == .document)
        #expect(node.name == "Document")
        #expect(node.stringValue(for: "title") == "Test")
        #expect(node.stringValue(for: "pdfVersion") == "1.7")
        #expect(node.intValue(for: "pageCount") == 5)
        #expect(node.boolValue(for: "isTagged") == true)
    }

    @Test("DocumentFeatures FeatureNode includes dates")
    func featureNodeIncludesDates() {
        let date = Date()
        let features = DocumentFeatures(
            creationDate: date,
            modificationDate: date
        )

        let node = features.toFeatureNode()

        #expect(node.value(for: "creationDate")?.isDate == true)
        #expect(node.value(for: "modificationDate")?.isDate == true)
    }

    // MARK: - Equatable

    @Test("DocumentFeatures is equatable")
    func equatable() {
        let features1 = DocumentFeatures(title: "Test", pdfVersion: "1.7")
        let features2 = DocumentFeatures(title: "Test", pdfVersion: "1.7")
        let features3 = DocumentFeatures(title: "Other", pdfVersion: "1.7")

        #expect(features1 == features2)
        #expect(features1 != features3)
    }

    // MARK: - CustomStringConvertible

    @Test("DocumentFeatures description")
    func description() {
        let features = DocumentFeatures(
            title: "My Document",
            pdfVersion: "1.7",
            isEncrypted: true,
            pageCount: 10,
            isTagged: true,
            claimedPDFAConformance: "2b"
        )

        let desc = features.description
        #expect(desc.contains("My Document"))
        #expect(desc.contains("1.7"))
        #expect(desc.contains("10 pages"))
        #expect(desc.contains("tagged"))
        #expect(desc.contains("encrypted"))
        #expect(desc.contains("PDF/A"))
    }
}

// MARK: - TrappedStatus Tests

@Suite("TrappedStatus Tests")
struct TrappedStatusTests {

    @Test("TrappedStatus raw values")
    func rawValues() {
        #expect(TrappedStatus.trapped.rawValue == "True")
        #expect(TrappedStatus.notTrapped.rawValue == "False")
        #expect(TrappedStatus.unknown.rawValue == "Unknown")
    }

    @Test("TrappedStatus from string")
    func fromString() {
        #expect(TrappedStatus(string: "true") == .trapped)
        #expect(TrappedStatus(string: "True") == .trapped)
        #expect(TrappedStatus(string: "yes") == .trapped)
        #expect(TrappedStatus(string: "false") == .notTrapped)
        #expect(TrappedStatus(string: "False") == .notTrapped)
        #expect(TrappedStatus(string: "no") == .notTrapped)
        #expect(TrappedStatus(string: "unknown") == .unknown)
        #expect(TrappedStatus(string: "Unknown") == .unknown)
        #expect(TrappedStatus(string: "invalid") == nil)
    }

    @Test("TrappedStatus is codable")
    func codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in TrappedStatus.allCases {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(TrappedStatus.self, from: data)
            #expect(decoded == status)
        }
    }
}

// MARK: - DocumentFeaturesBuilder Tests

@Suite("DocumentFeaturesBuilder Tests")
struct DocumentFeaturesBuilderTests {

    @Test("Builder creates empty features by default")
    func emptyDefault() {
        var builder = DocumentFeaturesBuilder()
        let features = builder.build()

        #expect(features.title == nil)
        #expect(features.author == nil)
        #expect(features.pdfVersion == "1.4")
    }

    @Test("Builder sets all properties")
    func setsAllProperties() {
        var builder = DocumentFeaturesBuilder()
        builder.title("Test Title")
        builder.author("Test Author")
        builder.subject("Test Subject")
        builder.keywords("test, keywords")
        builder.creator("Test Creator")
        builder.producer("Test Producer")
        builder.pdfVersion("2.0")
        builder.isLinearized(true)
        builder.isEncrypted(true)
        builder.encryptionMethod("AES-256")
        builder.pageCount(100)
        builder.isTagged(true)
        builder.hasXMPMetadata(true)
        builder.hasAcroForm(true)
        builder.hasXFA(true)
        builder.embeddedFileCount(5)
        builder.hasOutlines(true)
        builder.outputIntentCount(2)
        builder.claimedPDFAConformance("4")
        builder.claimedPDFUAConformance("2")
        builder.claimedPDFXConformance("6")
        builder.trapped(.trapped)

        let features = builder.build()

        #expect(features.title == "Test Title")
        #expect(features.author == "Test Author")
        #expect(features.subject == "Test Subject")
        #expect(features.keywords == "test, keywords")
        #expect(features.creator == "Test Creator")
        #expect(features.producer == "Test Producer")
        #expect(features.pdfVersion == "2.0")
        #expect(features.isLinearized == true)
        #expect(features.isEncrypted == true)
        #expect(features.encryptionMethod == "AES-256")
        #expect(features.pageCount == 100)
        #expect(features.isTagged == true)
        #expect(features.hasXMPMetadata == true)
        #expect(features.hasAcroForm == true)
        #expect(features.hasXFA == true)
        #expect(features.embeddedFileCount == 5)
        #expect(features.hasOutlines == true)
        #expect(features.outputIntentCount == 2)
        #expect(features.claimedPDFAConformance == "4")
        #expect(features.claimedPDFUAConformance == "2")
        #expect(features.claimedPDFXConformance == "6")
        #expect(features.trapped == .trapped)
    }

    @Test("Builder sets dates")
    func setsDates() {
        var builder = DocumentFeaturesBuilder()
        let date1 = Date()
        let date2 = Date().addingTimeInterval(3600)

        builder.creationDate(date1)
        builder.modificationDate(date2)

        let features = builder.build()

        #expect(features.creationDate == date1)
        #expect(features.modificationDate == date2)
    }

    @Test("Builder is Sendable")
    func sendable() {
        var builder = DocumentFeaturesBuilder()
        builder.title("Test")

        // This should compile without issues
        Task {
            let features = builder.build()
            _ = features.title
        }
    }
}
