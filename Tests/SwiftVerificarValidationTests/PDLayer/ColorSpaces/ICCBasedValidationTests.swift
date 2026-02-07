import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - ICCBasedValidation Tests

@Suite("ICCBasedValidation")
struct ICCBasedValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let cs = ICCBasedValidation()
            #expect(cs.colorSpaceFamily == .iccBased)
            #expect(cs.componentCount == 3)
            #expect(cs.alternateColorSpaceName == nil)
            #expect(cs.iccProfileVersion == nil)
            #expect(cs.profileColorSpaceType == nil)
            #expect(cs.profileDeviceClass == nil)
            #expect(cs.isProfileValid)
            #expect(cs.renderingIntent == nil)
            #expect(cs.ranges.isEmpty)
            #expect(!cs.isDeviceDependent)
            #expect(cs.isCIEBased)
            #expect(!cs.isSpecial)
        }

        @Test("Object type is PDICCBased")
        func objectType() {
            let cs = ICCBasedValidation()
            #expect(cs.objectType == "PDICCBased")
        }

        @Test("Resource type is colorSpace")
        func resourceType() {
            let cs = ICCBasedValidation()
            #expect(cs.resourceType == .colorSpace)
        }

        @Test("Full initialization")
        func fullInit() {
            let cs = ICCBasedValidation(
                componentCount: 4,
                alternateColorSpaceName: "DeviceCMYK",
                iccProfileVersion: "2.1.0",
                profileColorSpaceType: "CMYK",
                profileDeviceClass: "prtr",
                isProfileValid: true,
                renderingIntent: 0,
                ranges: [0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0]
            )
            #expect(cs.componentCount == 4)
            #expect(cs.alternateColorSpaceName == "DeviceCMYK")
            #expect(cs.iccProfileVersion == "2.1.0")
            #expect(cs.profileColorSpaceType == "CMYK")
            #expect(cs.profileDeviceClass == "prtr")
            #expect(cs.isProfileValid)
            #expect(cs.renderingIntent == 0)
            #expect(cs.ranges.count == 8)
        }

        @Test("Default context is ColorSpace ICCBased")
        func defaultContext() {
            let cs = ICCBasedValidation()
            #expect(cs.validationContext.location == "ColorSpace")
            #expect(cs.validationContext.role == "ICCBased")
        }
    }

    // MARK: - Component Matching

    @Suite("Component Matching")
    struct ComponentMatchingTests {

        @Test("Matching GRAY component count")
        func grayMatching() {
            let cs = ICCBasedValidation(componentCount: 1, profileColorSpaceType: "GRAY")
            #expect(cs.hasMatchingComponentCount)
        }

        @Test("Non-matching GRAY component count")
        func grayNonMatching() {
            let cs = ICCBasedValidation(componentCount: 3, profileColorSpaceType: "GRAY")
            #expect(!cs.hasMatchingComponentCount)
        }

        @Test("Matching RGB component count")
        func rgbMatching() {
            let cs = ICCBasedValidation(componentCount: 3, profileColorSpaceType: "RGB")
            #expect(cs.hasMatchingComponentCount)
        }

        @Test("Non-matching RGB component count")
        func rgbNonMatching() {
            let cs = ICCBasedValidation(componentCount: 4, profileColorSpaceType: "RGB")
            #expect(!cs.hasMatchingComponentCount)
        }

        @Test("Matching CMYK component count")
        func cmykMatching() {
            let cs = ICCBasedValidation(componentCount: 4, profileColorSpaceType: "CMYK")
            #expect(cs.hasMatchingComponentCount)
        }

        @Test("Matching Lab component count")
        func labMatching() {
            let cs = ICCBasedValidation(componentCount: 3, profileColorSpaceType: "Lab")
            #expect(cs.hasMatchingComponentCount)
        }

        @Test("Matching with whitespace-padded type")
        func paddedType() {
            let cs = ICCBasedValidation(componentCount: 3, profileColorSpaceType: "RGB ")
            #expect(cs.hasMatchingComponentCount)
        }

        @Test("No profile type means matching")
        func noProfileType() {
            let cs = ICCBasedValidation(componentCount: 3)
            #expect(cs.hasMatchingComponentCount)
        }

        @Test("Unknown profile type means matching")
        func unknownProfileType() {
            let cs = ICCBasedValidation(componentCount: 2, profileColorSpaceType: "XYZ")
            #expect(cs.hasMatchingComponentCount)
        }
    }

    // MARK: - Range Validation

    @Suite("Range Validation")
    struct RangeValidationTests {

        @Test("Empty ranges are valid")
        func emptyRanges() {
            let cs = ICCBasedValidation(componentCount: 3, ranges: [])
            #expect(cs.hasValidRanges)
        }

        @Test("Correct range count is valid")
        func correctRangeCount() {
            let cs = ICCBasedValidation(componentCount: 3, ranges: [0, 1, 0, 1, 0, 1])
            #expect(cs.hasValidRanges)
        }

        @Test("Wrong range count is invalid")
        func wrongRangeCount() {
            let cs = ICCBasedValidation(componentCount: 3, ranges: [0, 1, 0, 1])
            #expect(!cs.hasValidRanges)
        }

        @Test("Range count for 4-component space")
        func fourComponentRange() {
            let cs = ICCBasedValidation(
                componentCount: 4,
                ranges: [0, 1, 0, 1, 0, 1, 0, 1]
            )
            #expect(cs.hasValidRanges)
        }
    }

    // MARK: - PDF/A Profile Version

    @Suite("PDF/A Profile Version")
    struct ProfileVersionTests {

        @Test("Version 2.1.0 valid for PDF/A-1")
        func v2ValidForPDFA1() {
            let cs = ICCBasedValidation(iccProfileVersion: "2.1.0")
            #expect(cs.isPDFA1ProfileVersionValid)
        }

        @Test("Version 4.3.0 invalid for PDF/A-1")
        func v4InvalidForPDFA1() {
            let cs = ICCBasedValidation(iccProfileVersion: "4.3.0")
            #expect(!cs.isPDFA1ProfileVersionValid)
        }

        @Test("Version 4.3.0 valid for PDF/A-2")
        func v4ValidForPDFA2() {
            let cs = ICCBasedValidation(iccProfileVersion: "4.3.0")
            #expect(cs.isPDFA2ProfileVersionValid)
        }

        @Test("Version 5.0.0 invalid for PDF/A-2")
        func v5InvalidForPDFA2() {
            let cs = ICCBasedValidation(iccProfileVersion: "5.0.0")
            #expect(!cs.isPDFA2ProfileVersionValid)
        }

        @Test("Nil version invalid for both")
        func nilVersion() {
            let cs = ICCBasedValidation()
            #expect(!cs.isPDFA1ProfileVersionValid)
            #expect(!cs.isPDFA2ProfileVersionValid)
        }

        @Test("Invalid version string")
        func invalidVersion() {
            let cs = ICCBasedValidation(iccProfileVersion: "abc")
            #expect(!cs.isPDFA1ProfileVersionValid)
            #expect(!cs.isPDFA2ProfileVersionValid)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include ICC-specific properties")
        func propertyNames() {
            let cs = ICCBasedValidation()
            let names = cs.propertyNames
            #expect(names.contains("iccProfileVersion"))
            #expect(names.contains("profileColorSpaceType"))
            #expect(names.contains("profileDeviceClass"))
            #expect(names.contains("isProfileValid"))
            #expect(names.contains("renderingIntent"))
            #expect(names.contains("rangeCount"))
            #expect(names.contains("hasMatchingComponentCount"))
            #expect(names.contains("hasValidRanges"))
            #expect(names.contains("isPDFA1ProfileVersionValid"))
            #expect(names.contains("isPDFA2ProfileVersionValid"))
        }

        @Test("Property access for ICC profile version")
        func profileVersion() {
            let cs = ICCBasedValidation(iccProfileVersion: "2.1.0")
            #expect(cs.property(named: "iccProfileVersion") == .string("2.1.0"))
        }

        @Test("Property access for null profile version")
        func nullProfileVersion() {
            let cs = ICCBasedValidation()
            #expect(cs.property(named: "iccProfileVersion") == .null)
        }

        @Test("Property access for profile color space type")
        func profileColorSpace() {
            let cs = ICCBasedValidation(profileColorSpaceType: "RGB")
            #expect(cs.property(named: "profileColorSpaceType") == .string("RGB"))
        }

        @Test("Property access for null profile color space type")
        func nullProfileColorSpace() {
            let cs = ICCBasedValidation()
            #expect(cs.property(named: "profileColorSpaceType") == .null)
        }

        @Test("Property access for profile device class")
        func deviceClass() {
            let cs = ICCBasedValidation(profileDeviceClass: "mntr")
            #expect(cs.property(named: "profileDeviceClass") == .string("mntr"))
        }

        @Test("Property access for null device class")
        func nullDeviceClass() {
            let cs = ICCBasedValidation()
            #expect(cs.property(named: "profileDeviceClass") == .null)
        }

        @Test("Property access for isProfileValid")
        func profileValid() {
            let valid = ICCBasedValidation(isProfileValid: true)
            #expect(valid.property(named: "isProfileValid") == .boolean(true))

            let invalid = ICCBasedValidation(isProfileValid: false)
            #expect(invalid.property(named: "isProfileValid") == .boolean(false))
        }

        @Test("Property access for rendering intent")
        func renderingIntent() {
            let cs = ICCBasedValidation(renderingIntent: 1)
            #expect(cs.property(named: "renderingIntent") == .integer(1))
        }

        @Test("Property access for null rendering intent")
        func nullRenderingIntent() {
            let cs = ICCBasedValidation()
            #expect(cs.property(named: "renderingIntent") == .null)
        }

        @Test("Property access for range count")
        func rangeCount() {
            let cs = ICCBasedValidation(ranges: [0, 1, 0, 1, 0, 1])
            #expect(cs.property(named: "rangeCount") == .integer(6))
        }

        @Test("Falls through to color space properties")
        func colorSpaceFallthrough() {
            let cs = ICCBasedValidation()
            #expect(cs.property(named: "colorSpaceFamily") == .string("ICCBased"))
            #expect(cs.property(named: "isCIEBased") == .boolean(true))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let cs = ICCBasedValidation()
            #expect(cs.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let cs1 = ICCBasedValidation(id: id, componentCount: 3)
            let cs2 = ICCBasedValidation(id: id, componentCount: 4)
            #expect(cs1 == cs2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let cs1 = ICCBasedValidation()
            let cs2 = ICCBasedValidation()
            #expect(cs1 != cs2)
        }
    }
}
