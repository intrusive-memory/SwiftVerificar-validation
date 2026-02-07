import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - ICC Profile Validation Tests

@Suite("ICCProfileValidation")
struct ICCProfileValidationTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let profile = ICCProfileValidation()
        #expect(profile.profileVersion == nil)
        #expect(profile.colorSpace == nil)
        #expect(profile.componentCount == 3)
        #expect(profile.deviceClass == nil)
        #expect(profile.profileType == .output)
        #expect(profile.renderingIntent == nil)
        #expect(profile.dataSize == 0)
        #expect(profile.isValid == true)
        #expect(profile.hasValidHeader == true)
        #expect(profile.hasRequiredTags == true)
        #expect(profile.missingRequiredTags.isEmpty)
        #expect(profile.tagCount == 0)
        #expect(profile.creatorSignature == nil)
    }

    @Test("Custom initialization with all parameters")
    func customInit() {
        let profile = ICCProfileValidation(
            profileVersion: "2.1.0",
            colorSpace: "RGB",
            componentCount: 3,
            deviceClass: "mntr",
            profileType: .display,
            renderingIntent: 1,
            dataSize: 3144,
            isValid: true,
            hasValidHeader: true,
            hasRequiredTags: true,
            missingRequiredTags: [],
            tagCount: 17,
            creatorSignature: "APPL"
        )
        #expect(profile.profileVersion == "2.1.0")
        #expect(profile.colorSpace == "RGB")
        #expect(profile.componentCount == 3)
        #expect(profile.deviceClass == "mntr")
        #expect(profile.profileType == .display)
        #expect(profile.renderingIntent == 1)
        #expect(profile.dataSize == 3144)
        #expect(profile.isValid == true)
        #expect(profile.hasValidHeader == true)
        #expect(profile.hasRequiredTags == true)
        #expect(profile.missingRequiredTags.isEmpty)
        #expect(profile.tagCount == 17)
        #expect(profile.creatorSignature == "APPL")
    }

    // MARK: - Version Parsing Tests

    @Test("Major version extraction")
    func majorVersion() {
        let profile = ICCProfileValidation(profileVersion: "2.1.0")
        #expect(profile.majorVersion == 2)
    }

    @Test("Minor version extraction")
    func minorVersion() {
        let profile = ICCProfileValidation(profileVersion: "4.3.0")
        #expect(profile.minorVersion == 3)
    }

    @Test("Version extraction with nil version")
    func nilVersion() {
        let profile = ICCProfileValidation(profileVersion: nil)
        #expect(profile.majorVersion == nil)
        #expect(profile.minorVersion == nil)
    }

    @Test("Version extraction with single component")
    func singleComponentVersion() {
        let profile = ICCProfileValidation(profileVersion: "4")
        #expect(profile.majorVersion == 4)
        #expect(profile.minorVersion == nil)
    }

    // MARK: - PDF/A Compliance Tests

    @Test("PDF/A-1 compliance with version 2.1.0")
    func pdfa1ComplianceV2() {
        let profile = ICCProfileValidation(profileVersion: "2.1.0")
        #expect(profile.isPDFA1Compliant == true)
    }

    @Test("PDF/A-1 non-compliance with version 4.3.0")
    func pdfa1NonComplianceV4() {
        let profile = ICCProfileValidation(profileVersion: "4.3.0")
        #expect(profile.isPDFA1Compliant == false)
    }

    @Test("PDF/A-2 compliance with version 4.3.0")
    func pdfa2ComplianceV4() {
        let profile = ICCProfileValidation(profileVersion: "4.3.0")
        #expect(profile.isPDFA2Compliant == true)
    }

    @Test("PDF/A-2 non-compliance with version 5.0.0")
    func pdfa2NonComplianceV5() {
        let profile = ICCProfileValidation(profileVersion: "5.0.0")
        #expect(profile.isPDFA2Compliant == false)
    }

    @Test("PDF/A compliance with nil version")
    func pdfaComplianceNilVersion() {
        let profile = ICCProfileValidation(profileVersion: nil)
        #expect(profile.isPDFA1Compliant == false)
        #expect(profile.isPDFA2Compliant == false)
    }

    // MARK: - Component Consistency Tests

    @Test("Consistent components for GRAY profile")
    func grayConsistency() {
        let profile = ICCProfileValidation(colorSpace: "GRAY", componentCount: 1)
        #expect(profile.hasConsistentComponents == true)
    }

    @Test("Inconsistent components for GRAY profile")
    func grayInconsistency() {
        let profile = ICCProfileValidation(colorSpace: "GRAY", componentCount: 3)
        #expect(profile.hasConsistentComponents == false)
    }

    @Test("Consistent components for RGB profile")
    func rgbConsistency() {
        let profile = ICCProfileValidation(colorSpace: "RGB", componentCount: 3)
        #expect(profile.hasConsistentComponents == true)
    }

    @Test("Consistent components for CMYK profile")
    func cmykConsistency() {
        let profile = ICCProfileValidation(colorSpace: "CMYK", componentCount: 4)
        #expect(profile.hasConsistentComponents == true)
    }

    @Test("Inconsistent components for CMYK profile")
    func cmykInconsistency() {
        let profile = ICCProfileValidation(colorSpace: "CMYK", componentCount: 3)
        #expect(profile.hasConsistentComponents == false)
    }

    @Test("Consistent components for Lab profile")
    func labConsistency() {
        let profile = ICCProfileValidation(colorSpace: "Lab", componentCount: 3)
        #expect(profile.hasConsistentComponents == true)
    }

    @Test("Consistent with nil color space")
    func nilColorSpaceConsistency() {
        let profile = ICCProfileValidation(colorSpace: nil, componentCount: 3)
        #expect(profile.hasConsistentComponents == true)
    }

    @Test("Consistent with unknown color space")
    func unknownColorSpaceConsistency() {
        let profile = ICCProfileValidation(colorSpace: "XYZ", componentCount: 3)
        #expect(profile.hasConsistentComponents == true)
    }

    @Test("Color space with whitespace trimming")
    func colorSpaceWhitespace() {
        let profile = ICCProfileValidation(colorSpace: "RGB ", componentCount: 3)
        #expect(profile.hasConsistentComponents == true)
    }

    // MARK: - Rendering Intent Tests

    @Test("Valid rendering intent 0 (perceptual)")
    func validRenderingIntent0() {
        let profile = ICCProfileValidation(renderingIntent: 0)
        #expect(profile.hasValidRenderingIntent == true)
    }

    @Test("Valid rendering intent 3 (absolute)")
    func validRenderingIntent3() {
        let profile = ICCProfileValidation(renderingIntent: 3)
        #expect(profile.hasValidRenderingIntent == true)
    }

    @Test("Invalid rendering intent -1")
    func invalidRenderingIntentNegative() {
        let profile = ICCProfileValidation(renderingIntent: -1)
        #expect(profile.hasValidRenderingIntent == false)
    }

    @Test("Invalid rendering intent 4")
    func invalidRenderingIntent4() {
        let profile = ICCProfileValidation(renderingIntent: 4)
        #expect(profile.hasValidRenderingIntent == false)
    }

    @Test("Nil rendering intent is valid")
    func nilRenderingIntentValid() {
        let profile = ICCProfileValidation(renderingIntent: nil)
        #expect(profile.hasValidRenderingIntent == true)
    }

    // MARK: - Computed Property Tests

    @Test("hasData with non-zero size")
    func hasDataTrue() {
        let profile = ICCProfileValidation(dataSize: 1024)
        #expect(profile.hasData == true)
    }

    @Test("hasData with zero size")
    func hasDataFalse() {
        let profile = ICCProfileValidation(dataSize: 0)
        #expect(profile.hasData == false)
    }

    @Test("hasMissingTags with missing tags")
    func hasMissingTagsTrue() {
        let profile = ICCProfileValidation(missingRequiredTags: ["profileDescriptionTag"])
        #expect(profile.hasMissingTags == true)
    }

    @Test("hasMissingTags with no missing tags")
    func hasMissingTagsFalse() {
        let profile = ICCProfileValidation(missingRequiredTags: [])
        #expect(profile.hasMissingTags == false)
    }

    // MARK: - PDFObject Conformance Tests

    @Test("Object type is ICCProfile")
    func objectType() {
        let profile = ICCProfileValidation()
        #expect(profile.objectType == "ICCProfile")
    }

    @Test("Property names are populated")
    func propertyNames() {
        let profile = ICCProfileValidation()
        #expect(profile.propertyNames.contains("profileVersion"))
        #expect(profile.propertyNames.contains("colorSpace"))
        #expect(profile.propertyNames.contains("isPDFA1Compliant"))
        #expect(profile.propertyNames.contains("hasConsistentComponents"))
    }

    @Test("Property access for string values")
    func propertyAccessStrings() {
        let profile = ICCProfileValidation(
            profileVersion: "2.1.0",
            colorSpace: "RGB",
            deviceClass: "mntr",
            creatorSignature: "APPL"
        )
        #expect(profile.property(named: "profileVersion")?.stringValue == "2.1.0")
        #expect(profile.property(named: "colorSpace")?.stringValue == "RGB")
        #expect(profile.property(named: "deviceClass")?.stringValue == "mntr")
        #expect(profile.property(named: "creatorSignature")?.stringValue == "APPL")
    }

    @Test("Property access for integer values")
    func propertyAccessIntegers() {
        let profile = ICCProfileValidation(
            profileVersion: "4.3.0",
            componentCount: 3,
            renderingIntent: 1,
            dataSize: 3144,
            tagCount: 17
        )
        #expect(profile.property(named: "majorVersion")?.integerValue == 4)
        #expect(profile.property(named: "minorVersion")?.integerValue == 3)
        #expect(profile.property(named: "componentCount")?.integerValue == 3)
        #expect(profile.property(named: "renderingIntent")?.integerValue == 1)
        #expect(profile.property(named: "dataSize")?.integerValue == 3144)
        #expect(profile.property(named: "tagCount")?.integerValue == 17)
        #expect(profile.property(named: "missingRequiredTagCount")?.integerValue == 0)
    }

    @Test("Property access for boolean values")
    func propertyAccessBooleans() {
        let profile = ICCProfileValidation(
            isValid: true,
            hasValidHeader: true,
            hasRequiredTags: false
        )
        #expect(profile.property(named: "isValid")?.boolValue == true)
        #expect(profile.property(named: "hasValidHeader")?.boolValue == true)
        #expect(profile.property(named: "hasRequiredTags")?.boolValue == false)
    }

    @Test("Property access for null values")
    func propertyAccessNulls() {
        let profile = ICCProfileValidation()
        #expect(profile.property(named: "profileVersion")?.isNull == true)
        #expect(profile.property(named: "colorSpace")?.isNull == true)
        #expect(profile.property(named: "deviceClass")?.isNull == true)
        #expect(profile.property(named: "renderingIntent")?.isNull == true)
        #expect(profile.property(named: "creatorSignature")?.isNull == true)
    }

    @Test("Property access for unknown property returns nil")
    func propertyAccessUnknown() {
        let profile = ICCProfileValidation()
        #expect(profile.property(named: "unknownProperty") == nil)
    }

    // MARK: - ICCProfileType Tests

    @Test("ICCProfileType from device class signatures")
    func profileTypeFromDeviceClass() {
        #expect(ICCProfileType(fromDeviceClass: "scnr") == .input)
        #expect(ICCProfileType(fromDeviceClass: "mntr") == .display)
        #expect(ICCProfileType(fromDeviceClass: "prtr") == .output)
        #expect(ICCProfileType(fromDeviceClass: "link") == .deviceLink)
        #expect(ICCProfileType(fromDeviceClass: "spac") == .colorSpace)
        #expect(ICCProfileType(fromDeviceClass: "abst") == .abstract)
        #expect(ICCProfileType(fromDeviceClass: "nmcl") == .namedColor)
        #expect(ICCProfileType(fromDeviceClass: "xxxx") == .unknown)
        #expect(ICCProfileType(fromDeviceClass: nil) == .unknown)
    }

    @Test("ICCProfileType output intent validity")
    func profileTypeOutputIntentValidity() {
        #expect(ICCProfileType.output.isValidForOutputIntent == true)
        #expect(ICCProfileType.display.isValidForOutputIntent == true)
        #expect(ICCProfileType.input.isValidForOutputIntent == false)
        #expect(ICCProfileType.deviceLink.isValidForOutputIntent == false)
    }

    @Test("ICCProfileType embeddability")
    func profileTypeEmbeddability() {
        #expect(ICCProfileType.input.isEmbeddable == true)
        #expect(ICCProfileType.display.isEmbeddable == true)
        #expect(ICCProfileType.output.isEmbeddable == true)
        #expect(ICCProfileType.colorSpace.isEmbeddable == true)
        #expect(ICCProfileType.deviceLink.isEmbeddable == false)
        #expect(ICCProfileType.abstract.isEmbeddable == false)
        #expect(ICCProfileType.namedColor.isEmbeddable == false)
        #expect(ICCProfileType.unknown.isEmbeddable == false)
    }

    @Test("ICCProfileType CaseIterable")
    func profileTypeCaseIterable() {
        #expect(ICCProfileType.allCases.count == 8)
    }

    // MARK: - Factory Method Tests

    @Test("sRGB profile factory")
    func srgbProfileFactory() {
        let profile = ICCProfileValidation.sRGBProfile()
        #expect(profile.profileVersion == "2.1.0")
        #expect(profile.colorSpace == "RGB")
        #expect(profile.componentCount == 3)
        #expect(profile.profileType == .display)
        #expect(profile.dataSize == 3144)
        #expect(profile.tagCount == 17)
        #expect(profile.hasConsistentComponents == true)
    }

    @Test("CMYK profile factory")
    func cmykProfileFactory() {
        let profile = ICCProfileValidation.cmykProfile()
        #expect(profile.profileVersion == "2.1.0")
        #expect(profile.colorSpace == "CMYK")
        #expect(profile.componentCount == 4)
        #expect(profile.profileType == .output)
        #expect(profile.hasConsistentComponents == true)
    }

    @Test("Gray profile factory")
    func grayProfileFactory() {
        let profile = ICCProfileValidation.grayProfile()
        #expect(profile.profileVersion == "2.1.0")
        #expect(profile.colorSpace == "GRAY")
        #expect(profile.componentCount == 1)
        #expect(profile.profileType == .display)
        #expect(profile.hasConsistentComponents == true)
    }

    // MARK: - Equatable Tests

    @Test("Equatable by id")
    func equatable() {
        let id = UUID()
        let p1 = ICCProfileValidation(id: id, profileVersion: "2.1.0")
        let p2 = ICCProfileValidation(id: id, profileVersion: "4.3.0")
        #expect(p1 == p2)
    }

    @Test("Not equal with different ids")
    func notEqual() {
        let p1 = ICCProfileValidation(profileVersion: "2.1.0")
        let p2 = ICCProfileValidation(profileVersion: "2.1.0")
        #expect(p1 != p2)
    }

    // MARK: - Sendable and Protocol Conformance Tests

    @Test("Conforms to PDValidationObject")
    func conformsToPDValidationObject() {
        let profile = ICCProfileValidation()
        let _: any PDValidationObject = profile
        // Verifies protocol conformance compiles
        #expect(profile.objectType == "ICCProfile")
    }

    @Test("Validation context is set correctly")
    func validationContext() {
        let profile = ICCProfileValidation(profileType: .display)
        #expect(profile.validationContext.location == "ICCProfile")
        #expect(profile.validationContext.role == "Display")
    }

    @Test("Custom validation context")
    func customValidationContext() {
        let ctx = ObjectContext(pageNumber: 1, location: "OutputIntent")
        let profile = ICCProfileValidation(context: ctx)
        #expect(profile.validationContext.pageNumber == 1)
        #expect(profile.validationContext.location == "OutputIntent")
    }
}
