import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - OCG Usage Category Tests

@Suite("OCGUsageCategory Tests")
struct OCGUsageCategoryTests {

    @Test("Raw values match PDF specification")
    func rawValues() {
        #expect(OCGUsageCategory.print.rawValue == "Print")
        #expect(OCGUsageCategory.view.rawValue == "View")
        #expect(OCGUsageCategory.user.rawValue == "User")
        #expect(OCGUsageCategory.design.rawValue == "Design")
        #expect(OCGUsageCategory.language.rawValue == "Language")
        #expect(OCGUsageCategory.pageElement.rawValue == "PageElement")
        #expect(OCGUsageCategory.export.rawValue == "Export")
        #expect(OCGUsageCategory.zoom.rawValue == "Zoom")
        #expect(OCGUsageCategory.unknown.rawValue == "Unknown")
    }

    @Test("Creates category from valid string")
    func fromValidString() {
        #expect(OCGUsageCategory(fromString: "Print") == .print)
        #expect(OCGUsageCategory(fromString: "View") == .view)
        #expect(OCGUsageCategory(fromString: "Language") == .language)
    }

    @Test("Creates unknown for invalid string")
    func fromInvalidString() {
        #expect(OCGUsageCategory(fromString: "Invalid") == .unknown)
        #expect(OCGUsageCategory(fromString: nil) == .unknown)
    }

    @Test("CaseIterable conformance")
    func caseIterable() {
        #expect(OCGUsageCategory.allCases.count == 9)
    }
}

// MARK: - Validated Optional Content Group Tests

@Suite("ValidatedOptionalContentGroup Tests")
struct ValidatedOptionalContentGroupTests {

    @Test("Default initialization")
    func defaultInit() {
        let ocg = ValidatedOptionalContentGroup()
        #expect(ocg.name == nil)
        #expect(ocg.intents == ["View"])
        #expect(ocg.isDefaultOn == true)
        #expect(ocg.usageCategories.isEmpty)
        #expect(ocg.isListedInOCProperties == true)
        #expect(ocg.hasCreatorInfo == false)
        #expect(ocg.hasLanguage == false)
        #expect(ocg.objectType == "PDOptionalContentGroup")
    }

    @Test("Layer factory")
    func layerFactory() {
        let layer = ValidatedOptionalContentGroup.layer(name: "Watermark", isDefaultOn: false)
        #expect(layer.name == "Watermark")
        #expect(layer.isDefaultOn == false)
        #expect(layer.isListedInOCProperties == true)
        #expect(layer.hasName == true)
    }

    @Test("Language factory")
    func languageFactory() {
        let lang = ValidatedOptionalContentGroup.language(
            name: "French",
            languageCode: "fr",
            isPreferred: false
        )
        #expect(lang.name == "French")
        #expect(lang.hasLanguage == true)
        #expect(lang.languageCode == "fr")
        #expect(lang.isPreferredLanguage == false)
    }

    @Test("Name detection")
    func nameDetection() {
        let withName = ValidatedOptionalContentGroup(name: "Layer 1")
        #expect(withName.hasName == true)

        let emptyName = ValidatedOptionalContentGroup(name: "")
        #expect(emptyName.hasName == false)

        let noName = ValidatedOptionalContentGroup(name: nil)
        #expect(noName.hasName == false)
    }

    @Test("Intent detection")
    func intentDetection() {
        let viewOnly = ValidatedOptionalContentGroup(intents: ["View"])
        #expect(viewOnly.hasViewIntent == true)
        #expect(viewOnly.hasDesignIntent == false)

        let designOnly = ValidatedOptionalContentGroup(intents: ["Design"])
        #expect(designOnly.hasViewIntent == false)
        #expect(designOnly.hasDesignIntent == true)

        let both = ValidatedOptionalContentGroup(intents: ["View", "Design"])
        #expect(both.hasViewIntent == true)
        #expect(both.hasDesignIntent == true)

        let empty = ValidatedOptionalContentGroup(intents: [])
        #expect(empty.hasViewIntent == false)
        #expect(empty.hasDesignIntent == false)
    }

    @Test("PDF/A-2 compliance")
    func pdfA2Compliance() {
        let compliant = ValidatedOptionalContentGroup(
            name: "Layer 1",
            isListedInOCProperties: true
        )
        #expect(compliant.isPDFA2Compliant == true)

        let noName = ValidatedOptionalContentGroup(
            name: nil,
            isListedInOCProperties: true
        )
        #expect(noName.isPDFA2Compliant == false)

        let notListed = ValidatedOptionalContentGroup(
            name: "Layer 1",
            isListedInOCProperties: false
        )
        #expect(notListed.isPDFA2Compliant == false)
    }

    @Test("Full initialization")
    func fullInit() {
        let ocg = ValidatedOptionalContentGroup(
            name: "Print Only",
            intents: ["View", "Design"],
            isDefaultOn: false,
            usageCategories: [.print, .export],
            isListedInOCProperties: true,
            hasCreatorInfo: true,
            creatorName: "Adobe Illustrator",
            hasLanguage: true,
            languageCode: "en-US",
            isPreferredLanguage: true,
            hasExportUsage: true,
            hasPrintUsage: true,
            hasViewUsage: false,
            hasZoomUsage: false
        )
        #expect(ocg.name == "Print Only")
        #expect(ocg.intents.count == 2)
        #expect(ocg.isDefaultOn == false)
        #expect(ocg.usageCategories.count == 2)
        #expect(ocg.hasCreatorInfo == true)
        #expect(ocg.creatorName == "Adobe Illustrator")
        #expect(ocg.hasLanguage == true)
        #expect(ocg.languageCode == "en-US")
        #expect(ocg.isPreferredLanguage == true)
        #expect(ocg.hasExportUsage == true)
        #expect(ocg.hasPrintUsage == true)
        #expect(ocg.hasViewUsage == false)
        #expect(ocg.hasZoomUsage == false)
    }

    @Test("Property access")
    func propertyAccess() {
        let ocg = ValidatedOptionalContentGroup.layer(name: "Test Layer")
        #expect(ocg.property(named: "name")?.stringValue == "Test Layer")
        #expect(ocg.property(named: "isDefaultOn")?.boolValue == true)
        #expect(ocg.property(named: "isListedInOCProperties")?.boolValue == true)
        #expect(ocg.property(named: "hasName")?.boolValue == true)
        #expect(ocg.property(named: "isPDFA2Compliant")?.boolValue == true)
        #expect(ocg.property(named: "hasViewIntent")?.boolValue == true)
        #expect(ocg.property(named: "hasDesignIntent")?.boolValue == false)
        #expect(ocg.property(named: "intentCount")?.integerValue == 1)
        #expect(ocg.property(named: "nonexistent") == nil)
    }

    @Test("Null property values for absent optional fields")
    func nullProperties() {
        let ocg = ValidatedOptionalContentGroup()
        #expect(ocg.property(named: "name")?.isNull == true)
        #expect(ocg.property(named: "creatorName")?.isNull == true)
        #expect(ocg.property(named: "languageCode")?.isNull == true)
    }

    @Test("Intents and usage categories as comma-separated strings")
    func commaProperties() {
        let ocg = ValidatedOptionalContentGroup(
            intents: ["View", "Design"],
            usageCategories: [.print, .view]
        )
        #expect(ocg.property(named: "intents")?.stringValue == "View,Design")
        #expect(ocg.property(named: "usageCategories")?.stringValue == "Print,View")
    }

    @Test("Summary description")
    func summary() {
        let ocg = ValidatedOptionalContentGroup.layer(name: "Watermark", isDefaultOn: false)
        let s = ocg.summary
        #expect(s.contains("'Watermark'"))
        #expect(s.contains("OFF"))
    }

    @Test("Equatable by ID")
    func equatable() {
        let id = UUID()
        let a = ValidatedOptionalContentGroup(id: id, name: "A")
        let b = ValidatedOptionalContentGroup(id: id, name: "B")
        let c = ValidatedOptionalContentGroup(name: "A")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("PropertyNames coverage")
    func propertyNames() {
        let ocg = ValidatedOptionalContentGroup.layer(name: "Layer 1")
        let names = ocg.propertyNames
        #expect(names.contains("name"))
        #expect(names.contains("isPDFA2Compliant"))
        #expect(names.contains("hasViewIntent"))
        for propName in names {
            let value = ocg.property(named: propName)
            #expect(value != nil)
        }
    }
}
