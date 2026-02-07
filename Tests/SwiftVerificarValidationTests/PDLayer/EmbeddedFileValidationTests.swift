import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Embedded File Validation Tests

@Suite("EmbeddedFileValidation")
struct EmbeddedFileValidationTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let ef = EmbeddedFileValidation()
        #expect(ef.mimeType == nil)
        #expect(ef.fileName == nil)
        #expect(ef.unicodeFileName == nil)
        #expect(ef.fileDescription == nil)
        #expect(ef.fileSize == 0)
        #expect(ef.creationDate == nil)
        #expect(ef.modificationDate == nil)
        #expect(ef.checksum == nil)
        #expect(ef.afRelationship == nil)
        #expect(ef.hasFileSpec == true)
        #expect(ef.isClaimedPDFACompliant == false)
        #expect(ef.hasAssociatedFile == false)
    }

    @Test("Custom initialization with all parameters")
    func customInit() {
        let ef = EmbeddedFileValidation(
            mimeType: "application/xml",
            fileName: "invoice.xml",
            unicodeFileName: "invoice.xml",
            fileDescription: "ZUGFeRD invoice data",
            fileSize: 2048,
            creationDate: "D:20240101120000Z",
            modificationDate: "D:20240615150000Z",
            checksum: "abc123",
            afRelationship: .data,
            hasFileSpec: true,
            isClaimedPDFACompliant: false,
            hasAssociatedFile: true
        )
        #expect(ef.mimeType == "application/xml")
        #expect(ef.fileName == "invoice.xml")
        #expect(ef.unicodeFileName == "invoice.xml")
        #expect(ef.fileDescription == "ZUGFeRD invoice data")
        #expect(ef.fileSize == 2048)
        #expect(ef.creationDate == "D:20240101120000Z")
        #expect(ef.modificationDate == "D:20240615150000Z")
        #expect(ef.checksum == "abc123")
        #expect(ef.afRelationship == .data)
        #expect(ef.hasFileSpec == true)
        #expect(ef.isClaimedPDFACompliant == false)
        #expect(ef.hasAssociatedFile == true)
    }

    // MARK: - Computed Property Tests

    @Test("hasMimeType with non-empty MIME type")
    func hasMimeTypeTrue() {
        let ef = EmbeddedFileValidation(mimeType: "application/pdf")
        #expect(ef.hasMimeType == true)
    }

    @Test("hasMimeType with nil MIME type")
    func hasMimeTypeNil() {
        let ef = EmbeddedFileValidation(mimeType: nil)
        #expect(ef.hasMimeType == false)
    }

    @Test("hasMimeType with empty MIME type")
    func hasMimeTypeEmpty() {
        let ef = EmbeddedFileValidation(mimeType: "")
        #expect(ef.hasMimeType == false)
    }

    @Test("hasFileName with basic file name")
    func hasFileNameBasic() {
        let ef = EmbeddedFileValidation(fileName: "test.pdf")
        #expect(ef.hasFileName == true)
    }

    @Test("hasFileName with Unicode file name")
    func hasFileNameUnicode() {
        let ef = EmbeddedFileValidation(unicodeFileName: "test.pdf")
        #expect(ef.hasFileName == true)
    }

    @Test("hasFileName with no file names")
    func hasFileNameFalse() {
        let ef = EmbeddedFileValidation()
        #expect(ef.hasFileName == false)
    }

    @Test("effectiveFileName prefers Unicode")
    func effectiveFileNamePrefersUnicode() {
        let ef = EmbeddedFileValidation(fileName: "basic.pdf", unicodeFileName: "unicode.pdf")
        #expect(ef.effectiveFileName == "unicode.pdf")
    }

    @Test("effectiveFileName falls back to basic")
    func effectiveFileNameFallback() {
        let ef = EmbeddedFileValidation(fileName: "basic.pdf")
        #expect(ef.effectiveFileName == "basic.pdf")
    }

    @Test("effectiveFileName returns nil when no names")
    func effectiveFileNameNil() {
        let ef = EmbeddedFileValidation()
        #expect(ef.effectiveFileName == nil)
    }

    @Test("hasAFRelationship with relationship")
    func hasAFRelationshipTrue() {
        let ef = EmbeddedFileValidation(afRelationship: .data)
        #expect(ef.hasAFRelationship == true)
    }

    @Test("hasAFRelationship without relationship")
    func hasAFRelationshipFalse() {
        let ef = EmbeddedFileValidation(afRelationship: nil)
        #expect(ef.hasAFRelationship == false)
    }

    @Test("hasData with non-zero size")
    func hasDataTrue() {
        let ef = EmbeddedFileValidation(fileSize: 1024)
        #expect(ef.hasData == true)
    }

    @Test("hasData with zero size")
    func hasDataFalse() {
        let ef = EmbeddedFileValidation(fileSize: 0)
        #expect(ef.hasData == false)
    }

    @Test("fileExtension extraction")
    func fileExtension() {
        let ef1 = EmbeddedFileValidation(fileName: "invoice.xml")
        #expect(ef1.fileExtension == "xml")

        let ef2 = EmbeddedFileValidation(fileName: "document.pdf")
        #expect(ef2.fileExtension == "pdf")

        let ef3 = EmbeddedFileValidation(fileName: "archive.tar.gz")
        #expect(ef3.fileExtension == "gz")

        let ef4 = EmbeddedFileValidation(fileName: "noextension")
        #expect(ef4.fileExtension == nil)

        let ef5 = EmbeddedFileValidation()
        #expect(ef5.fileExtension == nil)
    }

    // MARK: - PDF/A Compliance Tests

    @Test("PDF/A-1 compliance is always false")
    func pdfa1AlwaysFalse() {
        let ef = EmbeddedFileValidation(
            mimeType: "application/pdf",
            hasFileSpec: true,
            isClaimedPDFACompliant: true
        )
        #expect(ef.isPDFA1Compliant == false)
    }

    @Test("PDF/A-2 compliance with compliant embedded file")
    func pdfa2Compliant() {
        let ef = EmbeddedFileValidation(
            mimeType: "application/pdf",
            hasFileSpec: true,
            isClaimedPDFACompliant: true
        )
        #expect(ef.isPDFA2Compliant == true)
    }

    @Test("PDF/A-2 non-compliant without MIME type")
    func pdfa2NonCompliantNoMime() {
        let ef = EmbeddedFileValidation(
            hasFileSpec: true,
            isClaimedPDFACompliant: true
        )
        #expect(ef.isPDFA2Compliant == false)
    }

    @Test("PDF/A-2 non-compliant without file spec")
    func pdfa2NonCompliantNoFileSpec() {
        let ef = EmbeddedFileValidation(
            mimeType: "application/pdf",
            hasFileSpec: false,
            isClaimedPDFACompliant: true
        )
        #expect(ef.isPDFA2Compliant == false)
    }

    @Test("PDF/A-2 non-compliant without PDF/A claim")
    func pdfa2NonCompliantNoClaim() {
        let ef = EmbeddedFileValidation(
            mimeType: "application/pdf",
            hasFileSpec: true,
            isClaimedPDFACompliant: false
        )
        #expect(ef.isPDFA2Compliant == false)
    }

    @Test("PDF/A-3 compliance with all requirements")
    func pdfa3Compliant() {
        let ef = EmbeddedFileValidation(
            mimeType: "application/xml",
            afRelationship: .data,
            hasFileSpec: true
        )
        #expect(ef.isPDFA3Compliant == true)
    }

    @Test("PDF/A-3 non-compliant without MIME type")
    func pdfa3NonCompliantNoMime() {
        let ef = EmbeddedFileValidation(
            afRelationship: .data,
            hasFileSpec: true
        )
        #expect(ef.isPDFA3Compliant == false)
    }

    @Test("PDF/A-3 non-compliant without AFRelationship")
    func pdfa3NonCompliantNoRelationship() {
        let ef = EmbeddedFileValidation(
            mimeType: "application/xml",
            hasFileSpec: true
        )
        #expect(ef.isPDFA3Compliant == false)
    }

    @Test("PDF/A-3 non-compliant without file spec")
    func pdfa3NonCompliantNoFileSpec() {
        let ef = EmbeddedFileValidation(
            mimeType: "application/xml",
            afRelationship: .data,
            hasFileSpec: false
        )
        #expect(ef.isPDFA3Compliant == false)
    }

    // MARK: - EmbeddedFileRelationship Tests

    @Test("Relationship from string values")
    func relationshipFromString() {
        #expect(EmbeddedFileRelationship(fromString: "Source") == .source)
        #expect(EmbeddedFileRelationship(fromString: "Data") == .data)
        #expect(EmbeddedFileRelationship(fromString: "Alternative") == .alternative)
        #expect(EmbeddedFileRelationship(fromString: "Supplement") == .supplement)
        #expect(EmbeddedFileRelationship(fromString: "EncryptedPayload") == .encryptedPayload)
        #expect(EmbeddedFileRelationship(fromString: "FormData") == .formData)
        #expect(EmbeddedFileRelationship(fromString: "Schema") == .schema)
        #expect(EmbeddedFileRelationship(fromString: "Unspecified") == .unspecified)
        #expect(EmbeddedFileRelationship(fromString: "InvalidValue") == .unknown)
        #expect(EmbeddedFileRelationship(fromString: nil) == .unknown)
    }

    @Test("Relationship PDF/A-3 validity")
    func relationshipPDFA3Validity() {
        #expect(EmbeddedFileRelationship.source.isPDFA3Valid == true)
        #expect(EmbeddedFileRelationship.data.isPDFA3Valid == true)
        #expect(EmbeddedFileRelationship.alternative.isPDFA3Valid == true)
        #expect(EmbeddedFileRelationship.supplement.isPDFA3Valid == true)
        #expect(EmbeddedFileRelationship.unspecified.isPDFA3Valid == true)
        #expect(EmbeddedFileRelationship.encryptedPayload.isPDFA3Valid == false)
        #expect(EmbeddedFileRelationship.formData.isPDFA3Valid == false)
        #expect(EmbeddedFileRelationship.schema.isPDFA3Valid == false)
        #expect(EmbeddedFileRelationship.unknown.isPDFA3Valid == false)
    }

    @Test("Relationship CaseIterable")
    func relationshipCaseIterable() {
        #expect(EmbeddedFileRelationship.allCases.count == 9)
    }

    // MARK: - PDFObject Conformance Tests

    @Test("Object type is EmbeddedFile")
    func objectType() {
        let ef = EmbeddedFileValidation()
        #expect(ef.objectType == "EmbeddedFile")
    }

    @Test("Property names are populated")
    func propertyNames() {
        let ef = EmbeddedFileValidation()
        #expect(ef.propertyNames.contains("mimeType"))
        #expect(ef.propertyNames.contains("fileName"))
        #expect(ef.propertyNames.contains("isPDFA3Compliant"))
        #expect(ef.propertyNames.contains("fileExtension"))
    }

    @Test("Property access for string values")
    func propertyAccessStrings() {
        let ef = EmbeddedFileValidation(
            mimeType: "application/xml",
            fileName: "data.xml",
            unicodeFileName: "data.xml",
            fileDescription: "Invoice data",
            creationDate: "D:20240101",
            modificationDate: "D:20240615",
            checksum: "abc123"
        )
        #expect(ef.property(named: "mimeType")?.stringValue == "application/xml")
        #expect(ef.property(named: "fileName")?.stringValue == "data.xml")
        #expect(ef.property(named: "unicodeFileName")?.stringValue == "data.xml")
        #expect(ef.property(named: "fileDescription")?.stringValue == "Invoice data")
        #expect(ef.property(named: "creationDate")?.stringValue == "D:20240101")
        #expect(ef.property(named: "modificationDate")?.stringValue == "D:20240615")
        #expect(ef.property(named: "checksum")?.stringValue == "abc123")
    }

    @Test("Property access for relationship")
    func propertyAccessRelationship() {
        let ef = EmbeddedFileValidation(afRelationship: .data)
        #expect(ef.property(named: "afRelationship")?.stringValue == "Data")
    }

    @Test("Property access for null relationship")
    func propertyAccessNullRelationship() {
        let ef = EmbeddedFileValidation()
        #expect(ef.property(named: "afRelationship")?.isNull == true)
    }

    @Test("Property access for file extension")
    func propertyAccessFileExtension() {
        let ef = EmbeddedFileValidation(fileName: "document.pdf")
        #expect(ef.property(named: "fileExtension")?.stringValue == "pdf")
    }

    @Test("Property access for null file extension")
    func propertyAccessNullFileExtension() {
        let ef = EmbeddedFileValidation()
        #expect(ef.property(named: "fileExtension")?.isNull == true)
    }

    @Test("Property access for boolean values")
    func propertyAccessBooleans() {
        let ef = EmbeddedFileValidation(
            hasFileSpec: true,
            isClaimedPDFACompliant: true,
            hasAssociatedFile: true
        )
        #expect(ef.property(named: "hasFileSpec")?.boolValue == true)
        #expect(ef.property(named: "isClaimedPDFACompliant")?.boolValue == true)
        #expect(ef.property(named: "hasAssociatedFile")?.boolValue == true)
        #expect(ef.property(named: "isPDFA1Compliant")?.boolValue == false)
    }

    @Test("Property access for integer values")
    func propertyAccessIntegers() {
        let ef = EmbeddedFileValidation(fileSize: 2048)
        #expect(ef.property(named: "fileSize")?.integerValue == 2048)
    }

    @Test("Property access for null values")
    func propertyAccessNulls() {
        let ef = EmbeddedFileValidation()
        #expect(ef.property(named: "mimeType")?.isNull == true)
        #expect(ef.property(named: "fileName")?.isNull == true)
        #expect(ef.property(named: "unicodeFileName")?.isNull == true)
        #expect(ef.property(named: "fileDescription")?.isNull == true)
        #expect(ef.property(named: "creationDate")?.isNull == true)
        #expect(ef.property(named: "modificationDate")?.isNull == true)
        #expect(ef.property(named: "checksum")?.isNull == true)
        #expect(ef.property(named: "effectiveFileName")?.isNull == true)
    }

    @Test("Property access for unknown property returns nil")
    func propertyAccessUnknown() {
        let ef = EmbeddedFileValidation()
        #expect(ef.property(named: "unknownProperty") == nil)
    }

    // MARK: - Factory Method Tests

    @Test("PDF/A-3 compliant factory")
    func pdfa3CompliantFactory() {
        let ef = EmbeddedFileValidation.pdfa3Compliant()
        #expect(ef.mimeType == "application/xml")
        #expect(ef.fileName == "invoice.xml")
        #expect(ef.afRelationship == .data)
        #expect(ef.hasFileSpec == true)
        #expect(ef.isPDFA3Compliant == true)
    }

    @Test("PDF/A-3 compliant factory with custom values")
    func pdfa3CompliantFactoryCustom() {
        let ef = EmbeddedFileValidation.pdfa3Compliant(
            mimeType: "text/csv",
            fileName: "data.csv",
            relationship: .supplement
        )
        #expect(ef.mimeType == "text/csv")
        #expect(ef.fileName == "data.csv")
        #expect(ef.afRelationship == .supplement)
    }

    @Test("Non-compliant factory")
    func nonCompliantFactory() {
        let ef = EmbeddedFileValidation.nonCompliant()
        #expect(ef.hasFileSpec == false)
        #expect(ef.isPDFA1Compliant == false)
        #expect(ef.isPDFA2Compliant == false)
        #expect(ef.isPDFA3Compliant == false)
    }

    // MARK: - Equatable Tests

    @Test("Equatable by id")
    func equatable() {
        let id = UUID()
        let e1 = EmbeddedFileValidation(id: id, mimeType: "text/xml")
        let e2 = EmbeddedFileValidation(id: id, mimeType: "application/pdf")
        #expect(e1 == e2)
    }

    @Test("Not equal with different ids")
    func notEqual() {
        let e1 = EmbeddedFileValidation(mimeType: "text/xml")
        let e2 = EmbeddedFileValidation(mimeType: "text/xml")
        #expect(e1 != e2)
    }

    // MARK: - Protocol Conformance Tests

    @Test("Conforms to PDValidationObject")
    func conformsToPDValidationObject() {
        let ef = EmbeddedFileValidation()
        let _: any PDValidationObject = ef
        #expect(ef.objectType == "EmbeddedFile")
    }

    @Test("Validation context defaults")
    func validationContextDefaults() {
        let ef = EmbeddedFileValidation(mimeType: "application/xml")
        #expect(ef.validationContext.location == "EmbeddedFile")
        #expect(ef.validationContext.role == "application/xml")
    }

    @Test("Validation context with unknown MIME type")
    func validationContextUnknownMime() {
        let ef = EmbeddedFileValidation()
        #expect(ef.validationContext.location == "EmbeddedFile")
        #expect(ef.validationContext.role == "Unknown")
    }
}
