import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - IndexedValidation Tests

@Suite("IndexedValidation")
struct IndexedValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let cs = IndexedValidation()
            #expect(cs.colorSpaceFamily == .indexed)
            #expect(cs.componentCount == 1)
            #expect(cs.baseColorSpaceName == nil)
            #expect(cs.baseComponentCount == 3)
            #expect(cs.hiVal == 255)
            #expect(cs.lookupTableSize == 0)
            #expect(cs.isLookupString)
            #expect(!cs.isDeviceDependent)
            #expect(!cs.isCIEBased)
            #expect(cs.isSpecial)
        }

        @Test("Object type is PDIndexed")
        func objectType() {
            let cs = IndexedValidation()
            #expect(cs.objectType == "PDIndexed")
        }

        @Test("Full initialization")
        func fullInit() {
            let cs = IndexedValidation(
                baseColorSpaceName: "DeviceRGB",
                baseComponentCount: 3,
                hiVal: 127,
                lookupTableSize: 384,
                isLookupString: false
            )
            #expect(cs.baseColorSpaceName == "DeviceRGB")
            #expect(cs.baseComponentCount == 3)
            #expect(cs.hiVal == 127)
            #expect(cs.lookupTableSize == 384)
            #expect(!cs.isLookupString)
        }

        @Test("Default context is ColorSpace Indexed")
        func defaultContext() {
            let cs = IndexedValidation()
            #expect(cs.validationContext.location == "ColorSpace")
            #expect(cs.validationContext.role == "Indexed")
        }
    }

    // MARK: - Base Color Space Validation

    @Suite("Base Color Space Validation")
    struct BaseColorSpaceTests {

        @Test("Valid base color space DeviceRGB")
        func validDeviceRGB() {
            let cs = IndexedValidation(baseColorSpaceName: "DeviceRGB")
            #expect(cs.hasValidBaseColorSpace)
        }

        @Test("Valid base color space DeviceCMYK")
        func validDeviceCMYK() {
            let cs = IndexedValidation(baseColorSpaceName: "DeviceCMYK")
            #expect(cs.hasValidBaseColorSpace)
        }

        @Test("Valid base color space ICCBased")
        func validICCBased() {
            let cs = IndexedValidation(baseColorSpaceName: "ICCBased")
            #expect(cs.hasValidBaseColorSpace)
        }

        @Test("Invalid base color space Pattern")
        func invalidPattern() {
            let cs = IndexedValidation(baseColorSpaceName: "Pattern")
            #expect(!cs.hasValidBaseColorSpace)
        }

        @Test("Invalid base color space Indexed")
        func invalidIndexed() {
            let cs = IndexedValidation(baseColorSpaceName: "Indexed")
            #expect(!cs.hasValidBaseColorSpace)
        }

        @Test("Invalid when nil")
        func nilBase() {
            let cs = IndexedValidation()
            #expect(!cs.hasValidBaseColorSpace)
        }
    }

    // MARK: - HiVal Validation

    @Suite("HiVal Validation")
    struct HiValTests {

        @Test("Valid HiVal 0")
        func validZero() {
            let cs = IndexedValidation(hiVal: 0)
            #expect(cs.hasValidHiVal)
        }

        @Test("Valid HiVal 255")
        func valid255() {
            let cs = IndexedValidation(hiVal: 255)
            #expect(cs.hasValidHiVal)
        }

        @Test("Valid HiVal 127")
        func valid127() {
            let cs = IndexedValidation(hiVal: 127)
            #expect(cs.hasValidHiVal)
        }

        @Test("Invalid negative HiVal")
        func negativeHiVal() {
            let cs = IndexedValidation(hiVal: -1)
            #expect(!cs.hasValidHiVal)
        }

        @Test("Invalid HiVal > 255")
        func tooLargeHiVal() {
            let cs = IndexedValidation(hiVal: 256)
            #expect(!cs.hasValidHiVal)
        }
    }

    // MARK: - Lookup Table Validation

    @Suite("Lookup Table Validation")
    struct LookupTableTests {

        @Test("Expected lookup size calculation")
        func expectedSize() {
            // HiVal=255, baseComponents=3 -> (255+1)*3 = 768
            let cs = IndexedValidation(baseComponentCount: 3, hiVal: 255)
            #expect(cs.expectedLookupSize == 768)
        }

        @Test("Expected lookup size for CMYK base")
        func expectedSizeCMYK() {
            // HiVal=127, baseComponents=4 -> (127+1)*4 = 512
            let cs = IndexedValidation(baseComponentCount: 4, hiVal: 127)
            #expect(cs.expectedLookupSize == 512)
        }

        @Test("Expected lookup size for single entry")
        func expectedSizeSingle() {
            // HiVal=0, baseComponents=3 -> (0+1)*3 = 3
            let cs = IndexedValidation(baseComponentCount: 3, hiVal: 0)
            #expect(cs.expectedLookupSize == 3)
        }

        @Test("Matching lookup table size")
        func matchingSize() {
            let cs = IndexedValidation(
                baseComponentCount: 3,
                hiVal: 255,
                lookupTableSize: 768
            )
            #expect(cs.hasMatchingLookupSize)
        }

        @Test("Non-matching lookup table size")
        func nonMatchingSize() {
            let cs = IndexedValidation(
                baseComponentCount: 3,
                hiVal: 255,
                lookupTableSize: 500
            )
            #expect(!cs.hasMatchingLookupSize)
        }
    }

    // MARK: - Combined Validity

    @Suite("Combined Validity")
    struct CombinedValidityTests {

        @Test("Valid indexed color space")
        func valid() {
            let cs = IndexedValidation(
                baseColorSpaceName: "DeviceRGB",
                baseComponentCount: 3,
                hiVal: 255,
                lookupTableSize: 768
            )
            #expect(cs.isValid)
        }

        @Test("Invalid when no base color space")
        func noBase() {
            let cs = IndexedValidation(
                baseComponentCount: 3,
                hiVal: 255,
                lookupTableSize: 768
            )
            #expect(!cs.isValid)
        }

        @Test("Invalid when lookup size wrong")
        func wrongLookup() {
            let cs = IndexedValidation(
                baseColorSpaceName: "DeviceRGB",
                baseComponentCount: 3,
                hiVal: 255,
                lookupTableSize: 100
            )
            #expect(!cs.isValid)
        }

        @Test("Invalid when HiVal out of range")
        func badHiVal() {
            let cs = IndexedValidation(
                baseColorSpaceName: "DeviceRGB",
                baseComponentCount: 3,
                hiVal: 300,
                lookupTableSize: 903
            )
            #expect(!cs.isValid)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include Indexed-specific properties")
        func propertyNames() {
            let cs = IndexedValidation()
            let names = cs.propertyNames
            #expect(names.contains("baseColorSpaceName"))
            #expect(names.contains("baseComponentCount"))
            #expect(names.contains("hiVal"))
            #expect(names.contains("lookupTableSize"))
            #expect(names.contains("isLookupString"))
            #expect(names.contains("hasValidBaseColorSpace"))
            #expect(names.contains("hasValidHiVal"))
            #expect(names.contains("expectedLookupSize"))
            #expect(names.contains("hasMatchingLookupSize"))
            #expect(names.contains("isValid"))
        }

        @Test("Property access for baseColorSpaceName")
        func baseColorSpace() {
            let with = IndexedValidation(baseColorSpaceName: "DeviceRGB")
            #expect(with.property(named: "baseColorSpaceName") == .string("DeviceRGB"))

            let without = IndexedValidation()
            #expect(without.property(named: "baseColorSpaceName") == .null)
        }

        @Test("Property access for numeric properties")
        func numericProperties() {
            let cs = IndexedValidation(
                baseComponentCount: 3,
                hiVal: 127,
                lookupTableSize: 384
            )
            #expect(cs.property(named: "baseComponentCount") == .integer(3))
            #expect(cs.property(named: "hiVal") == .integer(127))
            #expect(cs.property(named: "lookupTableSize") == .integer(384))
            #expect(cs.property(named: "expectedLookupSize") == .integer(384))
        }

        @Test("Property access for boolean properties")
        func booleanProperties() {
            let cs = IndexedValidation(
                baseColorSpaceName: "DeviceRGB",
                baseComponentCount: 3,
                hiVal: 255,
                lookupTableSize: 768,
                isLookupString: true
            )
            #expect(cs.property(named: "isLookupString") == .boolean(true))
            #expect(cs.property(named: "hasValidBaseColorSpace") == .boolean(true))
            #expect(cs.property(named: "hasValidHiVal") == .boolean(true))
            #expect(cs.property(named: "hasMatchingLookupSize") == .boolean(true))
            #expect(cs.property(named: "isValid") == .boolean(true))
        }

        @Test("Falls through to color space properties")
        func colorSpaceFallthrough() {
            let cs = IndexedValidation()
            #expect(cs.property(named: "colorSpaceFamily") == .string("Indexed"))
            #expect(cs.property(named: "componentCount") == .integer(1))
            #expect(cs.property(named: "isSpecial") == .boolean(true))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let cs = IndexedValidation()
            #expect(cs.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let cs1 = IndexedValidation(id: id, hiVal: 127)
            let cs2 = IndexedValidation(id: id, hiVal: 255)
            #expect(cs1 == cs2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let cs1 = IndexedValidation()
            let cs2 = IndexedValidation()
            #expect(cs1 != cs2)
        }
    }
}
