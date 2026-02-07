import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - SeparationValidation Tests

@Suite("SeparationValidation")
struct SeparationValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let cs = SeparationValidation()
            #expect(cs.colorSpaceFamily == .separation)
            #expect(cs.componentCount == 1)
            #expect(cs.colorantName == nil)
            #expect(cs.alternateColorSpaceName == nil)
            #expect(cs.alternateComponentCount == 3)
            #expect(!cs.hasTintTransform)
            #expect(!cs.isDeviceDependent)
            #expect(!cs.isCIEBased)
            #expect(cs.isSpecial)
        }

        @Test("Object type is PDSeparation")
        func objectType() {
            let cs = SeparationValidation()
            #expect(cs.objectType == "PDSeparation")
        }

        @Test("Full initialization")
        func fullInit() {
            let cs = SeparationValidation(
                colorantName: "PANTONE 185 C",
                alternateColorSpaceName: "DeviceCMYK",
                alternateComponentCount: 4,
                hasTintTransform: true
            )
            #expect(cs.colorantName == "PANTONE 185 C")
            #expect(cs.alternateColorSpaceName == "DeviceCMYK")
            #expect(cs.alternateComponentCount == 4)
            #expect(cs.hasTintTransform)
        }

        @Test("Default context is ColorSpace Separation")
        func defaultContext() {
            let cs = SeparationValidation()
            #expect(cs.validationContext.location == "ColorSpace")
            #expect(cs.validationContext.role == "Separation")
        }
    }

    // MARK: - Special Colorant Names

    @Suite("Special Colorant Names")
    struct SpecialColorantTests {

        @Test("isAllColorant for All")
        func allColorant() {
            let cs = SeparationValidation(colorantName: "All")
            #expect(cs.isAllColorant)
            #expect(!cs.isNoneColorant)
        }

        @Test("isNoneColorant for None")
        func noneColorant() {
            let cs = SeparationValidation(colorantName: "None")
            #expect(cs.isNoneColorant)
            #expect(!cs.isAllColorant)
        }

        @Test("Regular colorant is neither All nor None")
        func regularColorant() {
            let cs = SeparationValidation(colorantName: "PANTONE 185 C")
            #expect(!cs.isAllColorant)
            #expect(!cs.isNoneColorant)
        }

        @Test("Nil colorant is neither All nor None")
        func nilColorant() {
            let cs = SeparationValidation()
            #expect(!cs.isAllColorant)
            #expect(!cs.isNoneColorant)
        }
    }

    // MARK: - Colorant Name Validation

    @Suite("Colorant Name Validation")
    struct ColorantNameTests {

        @Test("Valid colorant name")
        func validName() {
            let cs = SeparationValidation(colorantName: "SpotColor1")
            #expect(cs.hasValidColorantName)
        }

        @Test("Valid special names")
        func specialNames() {
            #expect(SeparationValidation(colorantName: "All").hasValidColorantName)
            #expect(SeparationValidation(colorantName: "None").hasValidColorantName)
        }

        @Test("Invalid empty colorant name")
        func emptyName() {
            let cs = SeparationValidation(colorantName: "")
            #expect(!cs.hasValidColorantName)
        }

        @Test("Invalid nil colorant name")
        func nilName() {
            let cs = SeparationValidation()
            #expect(!cs.hasValidColorantName)
        }
    }

    // MARK: - Alternate Color Space Validation

    @Suite("Alternate Color Space Validation")
    struct AlternateColorSpaceTests {

        @Test("Valid alternate DeviceRGB")
        func validDeviceRGB() {
            let cs = SeparationValidation(alternateColorSpaceName: "DeviceRGB")
            #expect(cs.hasValidAlternateColorSpace)
        }

        @Test("Valid alternate DeviceCMYK")
        func validDeviceCMYK() {
            let cs = SeparationValidation(alternateColorSpaceName: "DeviceCMYK")
            #expect(cs.hasValidAlternateColorSpace)
        }

        @Test("Valid alternate ICCBased")
        func validICCBased() {
            let cs = SeparationValidation(alternateColorSpaceName: "ICCBased")
            #expect(cs.hasValidAlternateColorSpace)
        }

        @Test("Valid alternate CalRGB")
        func validCalRGB() {
            let cs = SeparationValidation(alternateColorSpaceName: "CalRGB")
            #expect(cs.hasValidAlternateColorSpace)
        }

        @Test("Invalid alternate Pattern")
        func invalidPattern() {
            let cs = SeparationValidation(alternateColorSpaceName: "Pattern")
            #expect(!cs.hasValidAlternateColorSpace)
        }

        @Test("Invalid alternate Indexed")
        func invalidIndexed() {
            let cs = SeparationValidation(alternateColorSpaceName: "Indexed")
            #expect(!cs.hasValidAlternateColorSpace)
        }

        @Test("Invalid alternate Separation")
        func invalidSeparation() {
            let cs = SeparationValidation(alternateColorSpaceName: "Separation")
            #expect(!cs.hasValidAlternateColorSpace)
        }

        @Test("Invalid alternate DeviceN")
        func invalidDeviceN() {
            let cs = SeparationValidation(alternateColorSpaceName: "DeviceN")
            #expect(!cs.hasValidAlternateColorSpace)
        }

        @Test("Invalid when nil")
        func nilAlternate() {
            let cs = SeparationValidation()
            #expect(!cs.hasValidAlternateColorSpace)
        }
    }

    // MARK: - Combined Validity

    @Suite("Combined Validity")
    struct CombinedValidityTests {

        @Test("Valid separation")
        func valid() {
            let cs = SeparationValidation(
                colorantName: "PANTONE 185 C",
                alternateColorSpaceName: "DeviceCMYK",
                hasTintTransform: true
            )
            #expect(cs.isValid)
        }

        @Test("Invalid without colorant name")
        func noColorant() {
            let cs = SeparationValidation(
                alternateColorSpaceName: "DeviceCMYK",
                hasTintTransform: true
            )
            #expect(!cs.isValid)
        }

        @Test("Invalid without alternate")
        func noAlternate() {
            let cs = SeparationValidation(
                colorantName: "Spot1",
                hasTintTransform: true
            )
            #expect(!cs.isValid)
        }

        @Test("Invalid without tint transform")
        func noTintTransform() {
            let cs = SeparationValidation(
                colorantName: "Spot1",
                alternateColorSpaceName: "DeviceCMYK"
            )
            #expect(!cs.isValid)
        }

        @Test("Invalid with forbidden alternate")
        func forbiddenAlternate() {
            let cs = SeparationValidation(
                colorantName: "Spot1",
                alternateColorSpaceName: "Pattern",
                hasTintTransform: true
            )
            #expect(!cs.isValid)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include Separation-specific properties")
        func propertyNames() {
            let cs = SeparationValidation()
            let names = cs.propertyNames
            #expect(names.contains("colorantName"))
            #expect(names.contains("alternateComponentCount"))
            #expect(names.contains("hasTintTransform"))
            #expect(names.contains("isAllColorant"))
            #expect(names.contains("isNoneColorant"))
            #expect(names.contains("hasValidColorantName"))
            #expect(names.contains("hasValidAlternateColorSpace"))
            #expect(names.contains("isValid"))
        }

        @Test("Property access for colorantName")
        func colorantNameProp() {
            let with = SeparationValidation(colorantName: "PANTONE 185 C")
            #expect(with.property(named: "colorantName") == .string("PANTONE 185 C"))

            let without = SeparationValidation()
            #expect(without.property(named: "colorantName") == .null)
        }

        @Test("Property access for alternateComponentCount")
        func alternateComponentCountProp() {
            let cs = SeparationValidation(alternateComponentCount: 4)
            #expect(cs.property(named: "alternateComponentCount") == .integer(4))
        }

        @Test("Property access for hasTintTransform")
        func tintTransformProp() {
            let with = SeparationValidation(hasTintTransform: true)
            #expect(with.property(named: "hasTintTransform") == .boolean(true))

            let without = SeparationValidation()
            #expect(without.property(named: "hasTintTransform") == .boolean(false))
        }

        @Test("Property access for special colorant booleans")
        func specialColorantProps() {
            let all = SeparationValidation(colorantName: "All")
            #expect(all.property(named: "isAllColorant") == .boolean(true))
            #expect(all.property(named: "isNoneColorant") == .boolean(false))

            let none = SeparationValidation(colorantName: "None")
            #expect(none.property(named: "isAllColorant") == .boolean(false))
            #expect(none.property(named: "isNoneColorant") == .boolean(true))
        }

        @Test("Property access for alternate color space name via base protocol")
        func alternateViaProtocol() {
            let cs = SeparationValidation(alternateColorSpaceName: "DeviceCMYK")
            #expect(cs.property(named: "alternateColorSpaceName") == .string("DeviceCMYK"))
        }

        @Test("Falls through to color space properties")
        func colorSpaceFallthrough() {
            let cs = SeparationValidation()
            #expect(cs.property(named: "colorSpaceFamily") == .string("Separation"))
            #expect(cs.property(named: "componentCount") == .integer(1))
            #expect(cs.property(named: "isSpecial") == .boolean(true))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let cs = SeparationValidation()
            #expect(cs.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let cs1 = SeparationValidation(id: id, colorantName: "A")
            let cs2 = SeparationValidation(id: id, colorantName: "B")
            #expect(cs1 == cs2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let cs1 = SeparationValidation()
            let cs2 = SeparationValidation()
            #expect(cs1 != cs2)
        }
    }
}
