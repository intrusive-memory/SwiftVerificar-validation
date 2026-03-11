import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarParser

// MARK: - ValidatedDocument Tests

@Suite("ValidatedDocument")
struct ValidatedDocumentTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let doc = ValidatedDocument()
        #expect(doc.pdfVersion == "1.7")
        #expect(doc.versionMismatch == false)
        #expect(doc.pageCount == 0)
        #expect(doc.isLinearized == false)
        #expect(doc.isEncrypted == false)
        #expect(doc.encryptionFilter == nil)
        #expect(doc.hasMarkInfo == false)
        #expect(doc.isMarked == false)
        #expect(doc.hasStructTreeRoot == false)
        #expect(doc.hasOutlines == false)
        #expect(doc.hasAcroForm == false)
        #expect(doc.hasMetadata == false)
        #expect(doc.hasOutputIntents == false)
        #expect(doc.outputIntentCount == 0)
        #expect(doc.language == nil)
        #expect(doc.hasSuspects == false)
        #expect(doc.structureElementCount == 0)
        #expect(doc.pages.isEmpty)
    }

    @Test("Full initialization")
    func fullInit() {
        let catalogDict: COSValue = .dictionary([.type: .name(ASAtom("Catalog"))])
        let objectKey = COSObjectKey(objectNumber: 1, generation: 0)
        let page = ValidatedPage.minimal(pageNumber: 1)

        let doc = ValidatedDocument(
            cosDictionary: catalogDict,
            objectKey: objectKey,
            context: .document,
            pdfVersion: "2.0",
            versionMismatch: true,
            pageCount: 5,
            isLinearized: true,
            isEncrypted: true,
            encryptionFilter: ASAtom("Standard"),
            hasMarkInfo: true,
            isMarked: true,
            hasStructTreeRoot: true,
            hasOutlines: true,
            hasAcroForm: true,
            hasMetadata: true,
            hasOutputIntents: true,
            outputIntentCount: 2,
            language: "en-US",
            hasSuspects: true,
            structureElementCount: 42,
            pages: [page]
        )

        #expect(doc.cosDictionary != nil)
        #expect(doc.objectKey == objectKey)
        #expect(doc.pdfVersion == "2.0")
        #expect(doc.versionMismatch == true)
        #expect(doc.pageCount == 5)
        #expect(doc.isLinearized == true)
        #expect(doc.isEncrypted == true)
        #expect(doc.encryptionFilter == ASAtom("Standard"))
        #expect(doc.hasMarkInfo == true)
        #expect(doc.isMarked == true)
        #expect(doc.hasStructTreeRoot == true)
        #expect(doc.hasOutlines == true)
        #expect(doc.hasAcroForm == true)
        #expect(doc.hasMetadata == true)
        #expect(doc.hasOutputIntents == true)
        #expect(doc.outputIntentCount == 2)
        #expect(doc.language == "en-US")
        #expect(doc.hasSuspects == true)
        #expect(doc.structureElementCount == 42)
        #expect(doc.pages.count == 1)
    }

    // MARK: - PDFObject Conformance Tests

    @Test("Object type is PDDocument")
    func objectType() {
        let doc = ValidatedDocument()
        #expect(doc.objectType == "PDDocument")
    }

    @Test("Property names list")
    func propertyNamesList() {
        let doc = ValidatedDocument()
        let names = doc.propertyNames
        #expect(names.contains("pdfVersion"))
        #expect(names.contains("pageCount"))
        #expect(names.contains("isEncrypted"))
        #expect(names.contains("hasStructTreeRoot"))
        #expect(names.contains("language"))
    }

    @Test("Property access - string values")
    func propertyAccessStrings() {
        let doc = ValidatedDocument(pdfVersion: "2.0", language: "fr")
        #expect(doc.property(named: "pdfVersion")?.stringValue == "2.0")
        #expect(doc.property(named: "language")?.stringValue == "fr")
    }

    @Test("Property access - boolean values")
    func propertyAccessBooleans() {
        let doc = ValidatedDocument(
            isLinearized: true,
            isEncrypted: false,
            hasMarkInfo: true,
            isMarked: true,
            hasStructTreeRoot: true
        )
        #expect(doc.property(named: "isLinearized")?.boolValue == true)
        #expect(doc.property(named: "isEncrypted")?.boolValue == false)
        #expect(doc.property(named: "hasMarkInfo")?.boolValue == true)
        #expect(doc.property(named: "isMarked")?.boolValue == true)
        #expect(doc.property(named: "hasStructTreeRoot")?.boolValue == true)
    }

    @Test("Property access - integer values")
    func propertyAccessIntegers() {
        let doc = ValidatedDocument(pageCount: 10, outputIntentCount: 3, structureElementCount: 50)
        #expect(doc.property(named: "pageCount")?.integerValue == 10)
        #expect(doc.property(named: "outputIntentCount")?.integerValue == 3)
        #expect(doc.property(named: "structureElementCount")?.integerValue == 50)
    }

    @Test("Property access - null values for nil optionals")
    func propertyAccessNullValues() {
        let doc = ValidatedDocument(encryptionFilter: nil, language: nil)
        #expect(doc.property(named: "encryptionFilter")?.isNull == true)
        #expect(doc.property(named: "language")?.isNull == true)
    }

    @Test("Property access - encryption filter when set")
    func propertyAccessEncryptionFilter() {
        let doc = ValidatedDocument(encryptionFilter: ASAtom("AES"))
        let value = doc.property(named: "encryptionFilter")
        #expect(value?.isNull == false)
        #expect(value?.stringValue == "AES")
    }

    @Test("Property access - unknown property returns nil")
    func propertyAccessUnknown() {
        let doc = ValidatedDocument()
        #expect(doc.property(named: "nonExistent") == nil)
    }

    // MARK: - PDValidationObject Conformance Tests

    @Test("cosObject is the cosDictionary")
    func cosObjectIsDictionary() {
        let dict: COSValue = .dictionary([.type: .name(ASAtom("Catalog"))])
        let doc = ValidatedDocument(cosDictionary: dict)
        #expect(doc.cosObject == dict)
    }

    @Test("Default context is document")
    func defaultContext() {
        let doc = ValidatedDocument()
        #expect(doc.validationContext.location == "Document")
    }

    @Test("isLoaded defaults to true")
    func isLoadedDefault() {
        let doc = ValidatedDocument()
        #expect(doc.isLoaded == true)
    }

    // MARK: - Computed Property Tests

    @Test("isTagged requires both marked and structTreeRoot")
    func isTagged() {
        let notTagged1 = ValidatedDocument(isMarked: true, hasStructTreeRoot: false)
        #expect(notTagged1.isTagged == false)

        let notTagged2 = ValidatedDocument(isMarked: false, hasStructTreeRoot: true)
        #expect(notTagged2.isTagged == false)

        let tagged = ValidatedDocument(isMarked: true, hasStructTreeRoot: true)
        #expect(tagged.isTagged == true)
    }

    @Test("isAccessible requires tagged and language")
    func isAccessible() {
        let notAccessible = ValidatedDocument(isMarked: true, hasStructTreeRoot: true)
        #expect(notAccessible.isAccessible == false)

        let accessible = ValidatedDocument(
            isMarked: true,
            hasStructTreeRoot: true,
            language: "en"
        )
        #expect(accessible.isAccessible == true)
    }

    @Test("Major and minor version parsing")
    func versionParsing() {
        let doc17 = ValidatedDocument(pdfVersion: "1.7")
        #expect(doc17.majorVersion == 1)
        #expect(doc17.minorVersion == 7)

        let doc20 = ValidatedDocument(pdfVersion: "2.0")
        #expect(doc20.majorVersion == 2)
        #expect(doc20.minorVersion == 0)
    }

    @Test("isPDF2 check")
    func isPDF2Check() {
        let doc17 = ValidatedDocument(pdfVersion: "1.7")
        #expect(doc17.isPDF2 == false)

        let doc20 = ValidatedDocument(pdfVersion: "2.0")
        #expect(doc20.isPDF2 == true)
    }

    @Test("Summary string includes key info")
    func summaryString() {
        let doc = ValidatedDocument(
            pdfVersion: "2.0",
            pageCount: 10,
            isLinearized: true,
            isEncrypted: true,
            isMarked: true,
            hasStructTreeRoot: true,
            language: "en-US"
        )
        let summary = doc.summary
        #expect(summary.contains("PDF 2.0"))
        #expect(summary.contains("10 pages"))
        #expect(summary.contains("tagged"))
        #expect(summary.contains("encrypted"))
        #expect(summary.contains("linearized"))
        #expect(summary.contains("lang=en-US"))
    }

    @Test("Summary for minimal document")
    func summaryMinimal() {
        let doc = ValidatedDocument(pdfVersion: "1.4", pageCount: 1)
        let summary = doc.summary
        #expect(summary.contains("PDF 1.4"))
        #expect(summary.contains("1 pages"))
        #expect(!summary.contains("tagged"))
    }

    // MARK: - Equatable Tests

    @Test("Documents with same ID are equal")
    func equalityById() {
        let id = UUID()
        let doc1 = ValidatedDocument(id: id, pdfVersion: "1.4")
        let doc2 = ValidatedDocument(id: id, pdfVersion: "2.0")
        #expect(doc1 == doc2)
    }

    @Test("Documents with different IDs are not equal")
    func inequalityById() {
        let doc1 = ValidatedDocument(pdfVersion: "1.7")
        let doc2 = ValidatedDocument(pdfVersion: "1.7")
        #expect(doc1 != doc2)
    }

    // MARK: - Factory Method Tests

    @Test("Minimal factory")
    func minimalFactory() {
        let doc = ValidatedDocument.minimal(
            pdfVersion: "2.0",
            pageCount: 5,
            isTagged: true,
            language: "de"
        )
        #expect(doc.pdfVersion == "2.0")
        #expect(doc.pageCount == 5)
        #expect(doc.isTagged == true)
        #expect(doc.language == "de")
    }

    @Test("Minimal factory defaults")
    func minimalFactoryDefaults() {
        let doc = ValidatedDocument.minimal()
        #expect(doc.pdfVersion == "1.7")
        #expect(doc.pageCount == 1)
        #expect(doc.isTagged == false)
        #expect(doc.language == nil)
    }

    // MARK: - Sendable Tests

    @Test("ValidatedDocument is Sendable")
    func isSendable() {
        let doc = ValidatedDocument.minimal(pdfVersion: "1.7", pageCount: 1)
        let sendableRef: any Sendable = doc
        #expect(sendableRef is ValidatedDocument)
    }

    // MARK: - Dictionary Helper Tests

    @Test("Dictionary entry access through PDValidationObject")
    func dictionaryEntryAccess() {
        let catalogDict: COSValue = .dictionary([
            ASAtom("Type"): .name(ASAtom("Catalog")),
            ASAtom("Lang"): .string(COSString(string: "en-US"))
        ])
        let doc = ValidatedDocument(cosDictionary: catalogDict)
        #expect(doc.hasEntry("Type"))
        #expect(doc.typeEntry == ASAtom("Catalog"))
        #expect(doc.stringValue(forKey: "Lang") == "en-US")
    }

    // MARK: - Version Edge Cases

    @Test("Version parsing with invalid version string")
    func invalidVersionString() {
        let doc = ValidatedDocument(pdfVersion: "invalid")
        #expect(doc.majorVersion == 1) // fallback
        #expect(doc.minorVersion == 0) // fallback
    }

    @Test("Version parsing with single number")
    func singleNumberVersion() {
        let doc = ValidatedDocument(pdfVersion: "2")
        #expect(doc.majorVersion == 2)
        #expect(doc.minorVersion == 0)
    }
}
