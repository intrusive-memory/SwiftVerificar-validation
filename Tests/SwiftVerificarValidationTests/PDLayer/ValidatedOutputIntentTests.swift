import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Output Intent Subtype Tests

@Suite("OutputIntentSubtype Tests")
struct OutputIntentSubtypeTests {

    @Test("Raw values match PDF specification strings")
    func rawValues() {
        #expect(OutputIntentSubtype.gtspdFX.rawValue == "GTS_PDFX")
        #expect(OutputIntentSubtype.gtsPDFA.rawValue == "GTS_PDFA1")
        #expect(OutputIntentSubtype.iso.rawValue == "ISO_PDFE1")
        #expect(OutputIntentSubtype.unknown.rawValue == "Unknown")
    }

    @Test("Creates subtype from valid string")
    func fromValidString() {
        #expect(OutputIntentSubtype(fromString: "GTS_PDFX") == .gtspdFX)
        #expect(OutputIntentSubtype(fromString: "GTS_PDFA1") == .gtsPDFA)
        #expect(OutputIntentSubtype(fromString: "ISO_PDFE1") == .iso)
    }

    @Test("Creates unknown for invalid string")
    func fromInvalidString() {
        #expect(OutputIntentSubtype(fromString: "InvalidType") == .unknown)
        #expect(OutputIntentSubtype(fromString: nil) == .unknown)
        #expect(OutputIntentSubtype(fromString: "") == .unknown)
    }

    @Test("PDF/A relevance")
    func pdfARelevance() {
        #expect(OutputIntentSubtype.gtsPDFA.isPDFARelevant == true)
        #expect(OutputIntentSubtype.gtspdFX.isPDFARelevant == false)
        #expect(OutputIntentSubtype.iso.isPDFARelevant == false)
        #expect(OutputIntentSubtype.unknown.isPDFARelevant == false)
    }

    @Test("PDF/X relevance")
    func pdfXRelevance() {
        #expect(OutputIntentSubtype.gtspdFX.isPDFXRelevant == true)
        #expect(OutputIntentSubtype.gtsPDFA.isPDFXRelevant == false)
    }

    @Test("CaseIterable conformance")
    func caseIterable() {
        #expect(OutputIntentSubtype.allCases.count == 4)
    }
}

// MARK: - Validated Output Intent Tests

@Suite("ValidatedOutputIntent Tests")
struct ValidatedOutputIntentTests {

    @Test("Default initialization")
    func defaultInit() {
        let intent = ValidatedOutputIntent()
        #expect(intent.subtype == .gtsPDFA)
        #expect(intent.subtypeName == "GTS_PDFA1")
        #expect(intent.outputCondition == nil)
        #expect(intent.outputConditionIdentifier == nil)
        #expect(intent.info == nil)
        #expect(intent.registryName == nil)
        #expect(intent.hasDestOutputProfile == false)
        #expect(intent.destOutputProfileComponents == nil)
        #expect(intent.objectType == "PDOutputIntent")
        #expect(intent.isLoaded == true)
    }

    @Test("Full initialization with all properties")
    func fullInit() {
        let intent = ValidatedOutputIntent(
            subtypeName: "GTS_PDFA1",
            outputCondition: "sRGB",
            outputConditionIdentifier: "sRGB IEC61966-2.1",
            info: "Standard RGB color space",
            registryName: "http://www.color.org",
            hasDestOutputProfile: true,
            destOutputProfileComponents: 3,
            destOutputProfileColorSpace: "RGB",
            destOutputProfileVersion: "2.1.0"
        )
        #expect(intent.subtype == .gtsPDFA)
        #expect(intent.outputCondition == "sRGB")
        #expect(intent.outputConditionIdentifier == "sRGB IEC61966-2.1")
        #expect(intent.info == "Standard RGB color space")
        #expect(intent.registryName == "http://www.color.org")
        #expect(intent.hasDestOutputProfile == true)
        #expect(intent.destOutputProfileComponents == 3)
        #expect(intent.destOutputProfileColorSpace == "RGB")
        #expect(intent.destOutputProfileVersion == "2.1.0")
    }

    @Test("PDF/A compliance with well-known identifier")
    func pdfAComplianceWellKnown() {
        let intent = ValidatedOutputIntent.pdfA(identifier: "sRGB IEC61966-2.1", hasProfile: false)
        #expect(intent.isPDFACompliant == true)
        #expect(intent.isWellKnownIdentifier == true)
    }

    @Test("PDF/A compliance requires profile for unknown identifier")
    func pdfAComplianceUnknownIdentifier() {
        let withProfile = ValidatedOutputIntent(
            subtypeName: "GTS_PDFA1",
            outputConditionIdentifier: "CustomProfile",
            hasDestOutputProfile: true
        )
        #expect(withProfile.isPDFACompliant == true)

        let withoutProfile = ValidatedOutputIntent(
            subtypeName: "GTS_PDFA1",
            outputConditionIdentifier: "CustomProfile",
            hasDestOutputProfile: false
        )
        #expect(withoutProfile.isPDFACompliant == false)
    }

    @Test("PDF/A compliance fails for wrong subtype")
    func pdfAComplianceWrongSubtype() {
        let intent = ValidatedOutputIntent(
            subtypeName: "GTS_PDFX",
            outputConditionIdentifier: "sRGB IEC61966-2.1",
            hasDestOutputProfile: true
        )
        #expect(intent.isPDFACompliant == false)
    }

    @Test("PDF/A compliance fails without identifier")
    func pdfAComplianceNoIdentifier() {
        let intent = ValidatedOutputIntent(
            subtypeName: "GTS_PDFA1",
            hasDestOutputProfile: true
        )
        #expect(intent.isPDFACompliant == false)
        #expect(intent.hasRequiredIdentifier == false)
    }

    @Test("Required identifier check")
    func hasRequiredIdentifier() {
        let withId = ValidatedOutputIntent(outputConditionIdentifier: "sRGB")
        #expect(withId.hasRequiredIdentifier == true)

        let emptyId = ValidatedOutputIntent(outputConditionIdentifier: "")
        #expect(emptyId.hasRequiredIdentifier == false)

        let noId = ValidatedOutputIntent()
        #expect(noId.hasRequiredIdentifier == false)
    }

    @Test("Color.org registry detection")
    func isColorOrg() {
        let colorOrg = ValidatedOutputIntent(registryName: "http://www.color.org")
        #expect(colorOrg.isColorOrg == true)

        let upperCase = ValidatedOutputIntent(registryName: "HTTP://WWW.COLOR.ORG")
        #expect(upperCase.isColorOrg == true)

        let other = ValidatedOutputIntent(registryName: "http://example.com")
        #expect(other.isColorOrg == false)

        let noRegistry = ValidatedOutputIntent()
        #expect(noRegistry.isColorOrg == false)
    }

    @Test("Well-known identifiers")
    func wellKnownIdentifiers() {
        let wellKnown = [
            "sRGB IEC61966-2.1", "sRGB", "Adobe RGB (1998)",
            "FOGRA39", "FOGRA51", "FOGRA52",
            "GRACoL2006_Coated1v2"
        ]
        for id in wellKnown {
            let intent = ValidatedOutputIntent(outputConditionIdentifier: id)
            #expect(intent.isWellKnownIdentifier == true)
        }

        let custom = ValidatedOutputIntent(outputConditionIdentifier: "MyCustomProfile")
        #expect(custom.isWellKnownIdentifier == false)
    }

    @Test("Property access")
    func propertyAccess() {
        let intent = ValidatedOutputIntent.pdfA()
        #expect(intent.property(named: "subtype")?.stringValue == "GTS_PDFA1")
        #expect(intent.property(named: "subtypeName")?.stringValue == "GTS_PDFA1")
        #expect(intent.property(named: "outputConditionIdentifier")?.stringValue == "sRGB IEC61966-2.1")
        #expect(intent.property(named: "hasDestOutputProfile")?.boolValue == true)
        #expect(intent.property(named: "destOutputProfileComponents")?.integerValue == 3)
        #expect(intent.property(named: "destOutputProfileColorSpace")?.stringValue == "RGB")
        #expect(intent.property(named: "isPDFACompliant")?.boolValue == true)
        #expect(intent.property(named: "hasRequiredIdentifier")?.boolValue == true)
        #expect(intent.property(named: "isColorOrg")?.boolValue == true)
        #expect(intent.property(named: "nonexistent") == nil)
    }

    @Test("Null property values for absent optional fields")
    func nullProperties() {
        let intent = ValidatedOutputIntent()
        #expect(intent.property(named: "outputCondition")?.isNull == true)
        #expect(intent.property(named: "outputConditionIdentifier")?.isNull == true)
        #expect(intent.property(named: "info")?.isNull == true)
        #expect(intent.property(named: "registryName")?.isNull == true)
        #expect(intent.property(named: "destOutputProfileComponents")?.isNull == true)
        #expect(intent.property(named: "destOutputProfileColorSpace")?.isNull == true)
        #expect(intent.property(named: "destOutputProfileVersion")?.isNull == true)
    }

    @Test("Factory methods")
    func factoryMethods() {
        let pdfA = ValidatedOutputIntent.pdfA()
        #expect(pdfA.subtype == .gtsPDFA)
        #expect(pdfA.hasDestOutputProfile == true)
        #expect(pdfA.destOutputProfileComponents == 3)
        #expect(pdfA.registryName == "http://www.color.org")

        let pdfX = ValidatedOutputIntent.pdfX()
        #expect(pdfX.subtype == .gtspdFX)
        #expect(pdfX.hasDestOutputProfile == true)
        #expect(pdfX.destOutputProfileComponents == 4)
        #expect(pdfX.destOutputProfileColorSpace == "CMYK")
    }

    @Test("Summary description")
    func summary() {
        let intent = ValidatedOutputIntent.pdfA()
        let s = intent.summary
        #expect(s.contains("GTS_PDFA1"))
        #expect(s.contains("sRGB IEC61966-2.1"))
        #expect(s.contains("has profile"))
    }

    @Test("Equatable by ID")
    func equatable() {
        let id = UUID()
        let a = ValidatedOutputIntent(id: id, subtypeName: "GTS_PDFA1")
        let b = ValidatedOutputIntent(id: id, subtypeName: "GTS_PDFX")
        let c = ValidatedOutputIntent(subtypeName: "GTS_PDFA1")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("PropertyNames coverage")
    func propertyNames() {
        let intent = ValidatedOutputIntent.pdfA()
        let names = intent.propertyNames
        #expect(names.contains("subtype"))
        #expect(names.contains("isPDFACompliant"))
        #expect(names.contains("hasRequiredIdentifier"))
        #expect(names.contains("isColorOrg"))
        for propName in names {
            // Every declared property name should return a non-nil value
            let value = intent.property(named: propName)
            #expect(value != nil)
        }
    }
}
