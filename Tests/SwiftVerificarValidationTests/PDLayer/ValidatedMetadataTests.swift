import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Validated Metadata Tests

@Suite("ValidatedMetadata")
struct ValidatedMetadataTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let meta = ValidatedMetadata()
        #expect(meta.isWellFormed == true)
        #expect(meta.dataSize == 0)
        #expect(meta.hasXMPMetaWrapper == true)
        #expect(meta.xmpToolkitVersion == nil)
        #expect(meta.hasDublinCoreSchema == false)
        #expect(meta.hasXMPBasicSchema == false)
        #expect(meta.hasAdobePDFSchema == false)
        #expect(meta.hasPDFAIdSchema == false)
        #expect(meta.hasPDFUAIdSchema == false)
        #expect(meta.hasExtensionSchemas == false)
        #expect(meta.schemaCount == 0)
        #expect(meta.pdfaPart == nil)
        #expect(meta.pdfaConformance == nil)
        #expect(meta.pdfaAmendment == nil)
        #expect(meta.pdfuaPart == nil)
        #expect(meta.isTitleSynchronized == true)
        #expect(meta.isAuthorSynchronized == true)
        #expect(meta.isSubjectSynchronized == true)
        #expect(meta.isKeywordsSynchronized == true)
        #expect(meta.isProducerSynchronized == true)
        #expect(meta.isCreatorToolSynchronized == true)
        #expect(meta.isCreateDateSynchronized == true)
        #expect(meta.isModDateSynchronized == true)
        #expect(meta.hasAllRequiredPDFASchemas == false)
        #expect(meta.hasValidExtensionSchemas == true)
    }

    @Test("Custom initialization with PDF/A identification")
    func customInitPDFA() {
        let meta = ValidatedMetadata(
            isWellFormed: true,
            dataSize: 2048,
            hasDublinCoreSchema: true,
            hasXMPBasicSchema: true,
            hasAdobePDFSchema: true,
            hasPDFAIdSchema: true,
            schemaCount: 4,
            pdfaPart: 2,
            pdfaConformance: "B",
            hasAllRequiredPDFASchemas: true
        )
        #expect(meta.hasDublinCoreSchema == true)
        #expect(meta.hasXMPBasicSchema == true)
        #expect(meta.hasAdobePDFSchema == true)
        #expect(meta.hasPDFAIdSchema == true)
        #expect(meta.schemaCount == 4)
        #expect(meta.pdfaPart == 2)
        #expect(meta.pdfaConformance == "B")
    }

    // MARK: - Synchronization Tests

    @Test("Fully synchronized metadata")
    func fullySynchronized() {
        let meta = ValidatedMetadata()
        #expect(meta.isFullySynchronized == true)
        #expect(meta.synchronizationIssueCount == 0)
    }

    @Test("Synchronization issue count with mismatches")
    func syncIssueCount() {
        let meta = ValidatedMetadata(
            isTitleSynchronized: false,
            isAuthorSynchronized: false,
            isCreateDateSynchronized: false
        )
        #expect(meta.synchronizationIssueCount == 3)
        #expect(meta.isFullySynchronized == false)
    }

    @Test("Synchronization issue count with all mismatches")
    func allSyncMismatches() {
        let meta = ValidatedMetadata(
            isTitleSynchronized: false,
            isAuthorSynchronized: false,
            isSubjectSynchronized: false,
            isKeywordsSynchronized: false,
            isProducerSynchronized: false,
            isCreatorToolSynchronized: false,
            isCreateDateSynchronized: false,
            isModDateSynchronized: false
        )
        #expect(meta.synchronizationIssueCount == 8)
        #expect(meta.isFullySynchronized == false)
    }

    @Test("Single synchronization mismatch")
    func singleSyncMismatch() {
        let meta = ValidatedMetadata(isProducerSynchronized: false)
        #expect(meta.synchronizationIssueCount == 1)
        #expect(meta.isFullySynchronized == false)
    }

    // MARK: - PDF/A Identification Tests

    @Test("Has PDF/A identification with both part and conformance")
    func hasPDFAId() {
        let meta = ValidatedMetadata(pdfaPart: 2, pdfaConformance: "B")
        #expect(meta.hasPDFAIdentification == true)
    }

    @Test("No PDF/A identification without part")
    func noPDFAIdNoPart() {
        let meta = ValidatedMetadata(pdfaConformance: "B")
        #expect(meta.hasPDFAIdentification == false)
    }

    @Test("No PDF/A identification without conformance")
    func noPDFAIdNoConf() {
        let meta = ValidatedMetadata(pdfaPart: 2)
        #expect(meta.hasPDFAIdentification == false)
    }

    @Test("No PDF/A identification with neither")
    func noPDFAIdNeither() {
        let meta = ValidatedMetadata()
        #expect(meta.hasPDFAIdentification == false)
    }

    // MARK: - PDF/UA Identification Tests

    @Test("Has PDF/UA identification")
    func hasPDFUAId() {
        let meta = ValidatedMetadata(pdfuaPart: 1)
        #expect(meta.hasPDFUAIdentification == true)
    }

    @Test("No PDF/UA identification")
    func noPDFUAId() {
        let meta = ValidatedMetadata()
        #expect(meta.hasPDFUAIdentification == false)
    }

    // MARK: - Computed Property Tests

    @Test("hasData with non-zero size")
    func hasDataTrue() {
        let meta = ValidatedMetadata(dataSize: 1024)
        #expect(meta.hasData == true)
    }

    @Test("hasData with zero size")
    func hasDataFalse() {
        let meta = ValidatedMetadata(dataSize: 0)
        #expect(meta.hasData == false)
    }

    // MARK: - PDF/A Compliance Tests

    @Test("Full PDF/A compliance")
    func pdfaCompliant() {
        let meta = ValidatedMetadata(
            isWellFormed: true,
            pdfaPart: 2,
            pdfaConformance: "B",
            hasAllRequiredPDFASchemas: true,
            hasValidExtensionSchemas: true
        )
        #expect(meta.isPDFACompliant == true)
    }

    @Test("PDF/A non-compliant: not well-formed")
    func pdfaNonCompliantNotWellFormed() {
        let meta = ValidatedMetadata(
            isWellFormed: false,
            pdfaPart: 2,
            pdfaConformance: "B",
            hasAllRequiredPDFASchemas: true,
            hasValidExtensionSchemas: true
        )
        #expect(meta.isPDFACompliant == false)
    }

    @Test("PDF/A non-compliant: missing required schemas")
    func pdfaNonCompliantNoSchemas() {
        let meta = ValidatedMetadata(
            isWellFormed: true,
            pdfaPart: 2,
            pdfaConformance: "B",
            hasAllRequiredPDFASchemas: false,
            hasValidExtensionSchemas: true
        )
        #expect(meta.isPDFACompliant == false)
    }

    @Test("PDF/A non-compliant: no identification")
    func pdfaNonCompliantNoId() {
        let meta = ValidatedMetadata(
            isWellFormed: true,
            hasAllRequiredPDFASchemas: true,
            hasValidExtensionSchemas: true
        )
        #expect(meta.isPDFACompliant == false)
    }

    @Test("PDF/A non-compliant: sync issues")
    func pdfaNonCompliantSyncIssues() {
        let meta = ValidatedMetadata(
            isWellFormed: true,
            pdfaPart: 2,
            pdfaConformance: "B",
            isTitleSynchronized: false,
            hasAllRequiredPDFASchemas: true,
            hasValidExtensionSchemas: true
        )
        #expect(meta.isPDFACompliant == false)
    }

    @Test("PDF/A non-compliant: invalid extension schemas")
    func pdfaNonCompliantInvalidExtSchemas() {
        let meta = ValidatedMetadata(
            isWellFormed: true,
            pdfaPart: 2,
            pdfaConformance: "B",
            hasAllRequiredPDFASchemas: true,
            hasValidExtensionSchemas: false
        )
        #expect(meta.isPDFACompliant == false)
    }

    // MARK: - PDFObject Conformance Tests

    @Test("Object type is PDMetadata")
    func objectType() {
        let meta = ValidatedMetadata()
        #expect(meta.objectType == "PDMetadata")
    }

    @Test("Property names are populated")
    func propertyNames() {
        let meta = ValidatedMetadata()
        #expect(meta.propertyNames.contains("isWellFormed"))
        #expect(meta.propertyNames.contains("pdfaPart"))
        #expect(meta.propertyNames.contains("isTitleSynchronized"))
        #expect(meta.propertyNames.contains("isPDFACompliant"))
        #expect(meta.propertyNames.contains("synchronizationIssueCount"))
    }

    @Test("Property access for boolean schema presence")
    func propertyAccessSchemaPresence() {
        let meta = ValidatedMetadata(
            hasDublinCoreSchema: true,
            hasXMPBasicSchema: true,
            hasAdobePDFSchema: false,
            hasPDFAIdSchema: true,
            hasPDFUAIdSchema: false,
            hasExtensionSchemas: true
        )
        #expect(meta.property(named: "hasDublinCoreSchema")?.boolValue == true)
        #expect(meta.property(named: "hasXMPBasicSchema")?.boolValue == true)
        #expect(meta.property(named: "hasAdobePDFSchema")?.boolValue == false)
        #expect(meta.property(named: "hasPDFAIdSchema")?.boolValue == true)
        #expect(meta.property(named: "hasPDFUAIdSchema")?.boolValue == false)
        #expect(meta.property(named: "hasExtensionSchemas")?.boolValue == true)
    }

    @Test("Property access for synchronization values")
    func propertyAccessSync() {
        let meta = ValidatedMetadata(
            isTitleSynchronized: true,
            isAuthorSynchronized: false,
            isSubjectSynchronized: true,
            isKeywordsSynchronized: false,
            isProducerSynchronized: true,
            isCreatorToolSynchronized: false,
            isCreateDateSynchronized: true,
            isModDateSynchronized: false
        )
        #expect(meta.property(named: "isTitleSynchronized")?.boolValue == true)
        #expect(meta.property(named: "isAuthorSynchronized")?.boolValue == false)
        #expect(meta.property(named: "isSubjectSynchronized")?.boolValue == true)
        #expect(meta.property(named: "isKeywordsSynchronized")?.boolValue == false)
        #expect(meta.property(named: "isProducerSynchronized")?.boolValue == true)
        #expect(meta.property(named: "isCreatorToolSynchronized")?.boolValue == false)
        #expect(meta.property(named: "isCreateDateSynchronized")?.boolValue == true)
        #expect(meta.property(named: "isModDateSynchronized")?.boolValue == false)
    }

    @Test("Property access for integer values")
    func propertyAccessIntegers() {
        let meta = ValidatedMetadata(
            dataSize: 2048,
            schemaCount: 5,
            pdfaPart: 2,
            pdfuaPart: 1
        )
        #expect(meta.property(named: "dataSize")?.integerValue == 2048)
        #expect(meta.property(named: "schemaCount")?.integerValue == 5)
        #expect(meta.property(named: "pdfaPart")?.integerValue == 2)
        #expect(meta.property(named: "pdfuaPart")?.integerValue == 1)
    }

    @Test("Property access for string values")
    func propertyAccessStrings() {
        let meta = ValidatedMetadata(
            xmpToolkitVersion: "Adobe XMP Core 5.6",
            pdfaConformance: "B",
            pdfaAmendment: "2005"
        )
        #expect(meta.property(named: "xmpToolkitVersion")?.stringValue == "Adobe XMP Core 5.6")
        #expect(meta.property(named: "pdfaConformance")?.stringValue == "B")
        #expect(meta.property(named: "pdfaAmendment")?.stringValue == "2005")
    }

    @Test("Property access for null values")
    func propertyAccessNulls() {
        let meta = ValidatedMetadata()
        #expect(meta.property(named: "xmpToolkitVersion")?.isNull == true)
        #expect(meta.property(named: "pdfaPart")?.isNull == true)
        #expect(meta.property(named: "pdfaConformance")?.isNull == true)
        #expect(meta.property(named: "pdfaAmendment")?.isNull == true)
        #expect(meta.property(named: "pdfuaPart")?.isNull == true)
    }

    @Test("Property access for computed values")
    func propertyAccessComputed() {
        let meta = ValidatedMetadata(
            pdfaPart: 2,
            pdfaConformance: "B",
            isTitleSynchronized: false,
            isAuthorSynchronized: false
        )
        #expect(meta.property(named: "synchronizationIssueCount")?.integerValue == 2)
        #expect(meta.property(named: "isFullySynchronized")?.boolValue == false)
        #expect(meta.property(named: "hasPDFAIdentification")?.boolValue == true)
        #expect(meta.property(named: "hasPDFUAIdentification")?.boolValue == false)
    }

    @Test("Property access for unknown property returns nil")
    func propertyAccessUnknown() {
        let meta = ValidatedMetadata()
        #expect(meta.property(named: "unknownProperty") == nil)
    }

    // MARK: - Factory Method Tests

    @Test("PDF/A compliant factory")
    func pdfaCompliantFactory() {
        let meta = ValidatedMetadata.pdfaCompliant()
        #expect(meta.isWellFormed == true)
        #expect(meta.hasDublinCoreSchema == true)
        #expect(meta.hasXMPBasicSchema == true)
        #expect(meta.hasAdobePDFSchema == true)
        #expect(meta.hasPDFAIdSchema == true)
        #expect(meta.pdfaPart == 2)
        #expect(meta.pdfaConformance == "B")
        #expect(meta.isPDFACompliant == true)
    }

    @Test("PDF/A compliant factory with custom values")
    func pdfaCompliantFactoryCustom() {
        let meta = ValidatedMetadata.pdfaCompliant(part: 3, conformance: "A")
        #expect(meta.pdfaPart == 3)
        #expect(meta.pdfaConformance == "A")
    }

    @Test("PDF/UA compliant factory")
    func pdfuaCompliantFactory() {
        let meta = ValidatedMetadata.pdfuaCompliant()
        #expect(meta.isWellFormed == true)
        #expect(meta.hasPDFUAIdSchema == true)
        #expect(meta.pdfuaPart == 1)
        #expect(meta.hasPDFUAIdentification == true)
    }

    @Test("PDF/UA compliant factory with part 2")
    func pdfuaCompliantFactoryPart2() {
        let meta = ValidatedMetadata.pdfuaCompliant(part: 2)
        #expect(meta.pdfuaPart == 2)
    }

    @Test("Sync issues factory")
    func syncIssuesFactory() {
        let meta = ValidatedMetadata.withSyncIssues()
        #expect(meta.isWellFormed == true)
        #expect(meta.isTitleSynchronized == false)
        #expect(meta.isAuthorSynchronized == false)
        #expect(meta.isCreateDateSynchronized == false)
        #expect(meta.synchronizationIssueCount == 3)
        #expect(meta.isFullySynchronized == false)
    }

    // MARK: - Equatable Tests

    @Test("Equatable by id")
    func equatable() {
        let id = UUID()
        let m1 = ValidatedMetadata(id: id, pdfaPart: 1)
        let m2 = ValidatedMetadata(id: id, pdfaPart: 2)
        #expect(m1 == m2)
    }

    @Test("Not equal with different ids")
    func notEqual() {
        let m1 = ValidatedMetadata()
        let m2 = ValidatedMetadata()
        #expect(m1 != m2)
    }

    // MARK: - Protocol Conformance Tests

    @Test("Conforms to PDValidationObject")
    func conformsToPDValidationObject() {
        let meta = ValidatedMetadata()
        let _: any PDValidationObject = meta
        #expect(meta.objectType == "PDMetadata")
    }

    @Test("Validation context defaults to metadata")
    func validationContextDefaults() {
        let meta = ValidatedMetadata()
        #expect(meta.validationContext.location == "Metadata")
    }

    @Test("Custom validation context")
    func customValidationContext() {
        let ctx = ObjectContext(location: "DocumentMetadata", role: "XMP")
        let meta = ValidatedMetadata(context: ctx)
        #expect(meta.validationContext.location == "DocumentMetadata")
        #expect(meta.validationContext.role == "XMP")
    }

    // MARK: - Edge Case Tests

    @Test("PDF/A-4 identification")
    func pdfa4Identification() {
        let meta = ValidatedMetadata(pdfaPart: 4, pdfaConformance: "F")
        #expect(meta.hasPDFAIdentification == true)
        #expect(meta.pdfaPart == 4)
        #expect(meta.pdfaConformance == "F")
    }

    @Test("Multiple schemas present")
    func multipleSchemasPresent() {
        let meta = ValidatedMetadata(
            hasDublinCoreSchema: true,
            hasXMPBasicSchema: true,
            hasAdobePDFSchema: true,
            hasPDFAIdSchema: true,
            hasPDFUAIdSchema: true,
            hasExtensionSchemas: true,
            schemaCount: 7
        )
        #expect(meta.schemaCount == 7)
        #expect(meta.hasDublinCoreSchema == true)
        #expect(meta.hasPDFUAIdSchema == true)
    }

    @Test("Large metadata data size")
    func largeDataSize() {
        let meta = ValidatedMetadata(dataSize: 1_000_000)
        #expect(meta.hasData == true)
        #expect(meta.property(named: "dataSize")?.integerValue == 1_000_000)
    }
}
