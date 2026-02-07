import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - ColorSpaceFamily Tests

@Suite("ColorSpaceFamily")
struct ColorSpaceFamilyTests {

    // MARK: - Raw Values

    @Suite("Raw Values")
    struct RawValueTests {

        @Test("All families have correct raw values")
        func rawValues() {
            #expect(ColorSpaceFamily.deviceGray.rawValue == "DeviceGray")
            #expect(ColorSpaceFamily.deviceRGB.rawValue == "DeviceRGB")
            #expect(ColorSpaceFamily.deviceCMYK.rawValue == "DeviceCMYK")
            #expect(ColorSpaceFamily.calGray.rawValue == "CalGray")
            #expect(ColorSpaceFamily.calRGB.rawValue == "CalRGB")
            #expect(ColorSpaceFamily.lab.rawValue == "Lab")
            #expect(ColorSpaceFamily.iccBased.rawValue == "ICCBased")
            #expect(ColorSpaceFamily.indexed.rawValue == "Indexed")
            #expect(ColorSpaceFamily.separation.rawValue == "Separation")
            #expect(ColorSpaceFamily.deviceN.rawValue == "DeviceN")
            #expect(ColorSpaceFamily.pattern.rawValue == "Pattern")
            #expect(ColorSpaceFamily.unknown.rawValue == "Unknown")
        }

        @Test("CaseIterable has all 12 cases")
        func caseCount() {
            #expect(ColorSpaceFamily.allCases.count == 12)
        }
    }

    // MARK: - Init from Name

    @Suite("Init from Name")
    struct InitFromNameTests {

        @Test("Creates family from valid name")
        func validName() {
            #expect(ColorSpaceFamily(fromName: "DeviceGray") == .deviceGray)
            #expect(ColorSpaceFamily(fromName: "DeviceRGB") == .deviceRGB)
            #expect(ColorSpaceFamily(fromName: "DeviceCMYK") == .deviceCMYK)
            #expect(ColorSpaceFamily(fromName: "CalGray") == .calGray)
            #expect(ColorSpaceFamily(fromName: "CalRGB") == .calRGB)
            #expect(ColorSpaceFamily(fromName: "Lab") == .lab)
            #expect(ColorSpaceFamily(fromName: "ICCBased") == .iccBased)
            #expect(ColorSpaceFamily(fromName: "Indexed") == .indexed)
            #expect(ColorSpaceFamily(fromName: "Separation") == .separation)
            #expect(ColorSpaceFamily(fromName: "DeviceN") == .deviceN)
            #expect(ColorSpaceFamily(fromName: "Pattern") == .pattern)
        }

        @Test("Creates unknown for nil name")
        func nilName() {
            #expect(ColorSpaceFamily(fromName: nil) == .unknown)
        }

        @Test("Creates unknown for invalid name")
        func invalidName() {
            #expect(ColorSpaceFamily(fromName: "Bogus") == .unknown)
            #expect(ColorSpaceFamily(fromName: "") == .unknown)
        }

        @Test("Creates family from ASAtom")
        func fromAtom() {
            #expect(ColorSpaceFamily(fromAtom: ASAtom("DeviceRGB")) == .deviceRGB)
            #expect(ColorSpaceFamily(fromAtom: nil) == .unknown)
        }
    }

    // MARK: - Classification

    @Suite("Classification")
    struct ClassificationTests {

        @Test("Device-dependent families")
        func deviceDependent() {
            #expect(ColorSpaceFamily.deviceGray.isDeviceDependent)
            #expect(ColorSpaceFamily.deviceRGB.isDeviceDependent)
            #expect(ColorSpaceFamily.deviceCMYK.isDeviceDependent)
            #expect(!ColorSpaceFamily.calGray.isDeviceDependent)
            #expect(!ColorSpaceFamily.iccBased.isDeviceDependent)
            #expect(!ColorSpaceFamily.indexed.isDeviceDependent)
        }

        @Test("CIE-based families")
        func cieBased() {
            #expect(ColorSpaceFamily.calGray.isCIEBased)
            #expect(ColorSpaceFamily.calRGB.isCIEBased)
            #expect(ColorSpaceFamily.lab.isCIEBased)
            #expect(ColorSpaceFamily.iccBased.isCIEBased)
            #expect(!ColorSpaceFamily.deviceGray.isCIEBased)
            #expect(!ColorSpaceFamily.indexed.isCIEBased)
        }

        @Test("Special families")
        func special() {
            #expect(ColorSpaceFamily.indexed.isSpecial)
            #expect(ColorSpaceFamily.separation.isSpecial)
            #expect(ColorSpaceFamily.deviceN.isSpecial)
            #expect(ColorSpaceFamily.pattern.isSpecial)
            #expect(!ColorSpaceFamily.deviceRGB.isSpecial)
            #expect(!ColorSpaceFamily.calRGB.isSpecial)
        }
    }

    // MARK: - Component Counts

    @Suite("Component Counts")
    struct ComponentCountTests {

        @Test("Standard component counts")
        func standardCounts() {
            #expect(ColorSpaceFamily.deviceGray.standardComponentCount == 1)
            #expect(ColorSpaceFamily.calGray.standardComponentCount == 1)
            #expect(ColorSpaceFamily.separation.standardComponentCount == 1)
            #expect(ColorSpaceFamily.indexed.standardComponentCount == 1)
            #expect(ColorSpaceFamily.deviceRGB.standardComponentCount == 3)
            #expect(ColorSpaceFamily.calRGB.standardComponentCount == 3)
            #expect(ColorSpaceFamily.lab.standardComponentCount == 3)
            #expect(ColorSpaceFamily.deviceCMYK.standardComponentCount == 4)
        }

        @Test("Variable component counts return nil")
        func variableCounts() {
            #expect(ColorSpaceFamily.iccBased.standardComponentCount == nil)
            #expect(ColorSpaceFamily.deviceN.standardComponentCount == nil)
            #expect(ColorSpaceFamily.pattern.standardComponentCount == nil)
            #expect(ColorSpaceFamily.unknown.standardComponentCount == nil)
        }
    }

    // MARK: - Classification Mutual Exclusivity

    @Suite("Mutual Exclusivity")
    struct MutualExclusivityTests {

        @Test("Each family belongs to at most one classification")
        func mutuallyExclusive() {
            for family in ColorSpaceFamily.allCases {
                let count = [
                    family.isDeviceDependent,
                    family.isCIEBased,
                    family.isSpecial
                ].filter { $0 }.count
                #expect(count <= 1, "Family \(family) belongs to \(count) classifications (expected 0 or 1)")
            }
        }

        @Test("Unknown belongs to no classification")
        func unknownNone() {
            #expect(!ColorSpaceFamily.unknown.isDeviceDependent)
            #expect(!ColorSpaceFamily.unknown.isCIEBased)
            #expect(!ColorSpaceFamily.unknown.isSpecial)
        }
    }
}
