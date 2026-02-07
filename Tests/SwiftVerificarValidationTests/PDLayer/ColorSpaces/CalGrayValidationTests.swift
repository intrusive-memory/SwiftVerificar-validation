import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - CalGrayValidation Tests

@Suite("CalGrayValidation")
struct CalGrayValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let cs = CalGrayValidation()
            #expect(cs.colorSpaceFamily == .calGray)
            #expect(cs.componentCount == 1)
            #expect(cs.whitePoint == nil)
            #expect(cs.blackPoint == nil)
            #expect(cs.gamma == nil)
            #expect(!cs.isDeviceDependent)
            #expect(cs.isCIEBased)
            #expect(!cs.isSpecial)
        }

        @Test("Object type is PDCalGray")
        func objectType() {
            let cs = CalGrayValidation()
            #expect(cs.objectType == "PDCalGray")
        }

        @Test("Resource type is colorSpace")
        func resourceType() {
            let cs = CalGrayValidation()
            #expect(cs.resourceType == .colorSpace)
        }

        @Test("Full initialization")
        func fullInit() {
            let cs = CalGrayValidation(
                whitePoint: [0.9505, 1.0, 1.089],
                blackPoint: [0.0, 0.0, 0.0],
                gamma: 2.2
            )
            #expect(cs.whitePoint == [0.9505, 1.0, 1.089])
            #expect(cs.blackPoint == [0.0, 0.0, 0.0])
            #expect(cs.gamma == 2.2)
        }

        @Test("Default context is ColorSpace CalGray")
        func defaultContext() {
            let cs = CalGrayValidation()
            #expect(cs.validationContext.location == "ColorSpace")
            #expect(cs.validationContext.role == "CalGray")
        }
    }

    // MARK: - White Point Validation

    @Suite("White Point Validation")
    struct WhitePointTests {

        @Test("Valid white point (D65)")
        func validD65() {
            let cs = CalGrayValidation(whitePoint: [0.9505, 1.0, 1.089])
            #expect(cs.hasValidWhitePoint)
        }

        @Test("Valid white point (D50)")
        func validD50() {
            let cs = CalGrayValidation(whitePoint: [0.9642, 1.0, 0.8249])
            #expect(cs.hasValidWhitePoint)
        }

        @Test("Invalid when Y is not 1.0")
        func invalidYNotOne() {
            let cs = CalGrayValidation(whitePoint: [0.9505, 0.9, 1.089])
            #expect(!cs.hasValidWhitePoint)
        }

        @Test("Invalid when X is zero")
        func invalidXZero() {
            let cs = CalGrayValidation(whitePoint: [0.0, 1.0, 1.089])
            #expect(!cs.hasValidWhitePoint)
        }

        @Test("Invalid when Z is zero")
        func invalidZZero() {
            let cs = CalGrayValidation(whitePoint: [0.9505, 1.0, 0.0])
            #expect(!cs.hasValidWhitePoint)
        }

        @Test("Invalid when nil")
        func nilWhitePoint() {
            let cs = CalGrayValidation()
            #expect(!cs.hasValidWhitePoint)
        }

        @Test("Invalid when wrong count")
        func wrongCount() {
            let cs = CalGrayValidation(whitePoint: [1.0, 1.0])
            #expect(!cs.hasValidWhitePoint)
        }
    }

    // MARK: - Black Point Validation

    @Suite("Black Point Validation")
    struct BlackPointTests {

        @Test("Valid black point (all zeros)")
        func validAllZeros() {
            let cs = CalGrayValidation(blackPoint: [0.0, 0.0, 0.0])
            #expect(cs.hasValidBlackPoint)
        }

        @Test("Valid black point (non-zero)")
        func validNonZero() {
            let cs = CalGrayValidation(blackPoint: [0.01, 0.01, 0.01])
            #expect(cs.hasValidBlackPoint)
        }

        @Test("Valid when nil (optional)")
        func nilBlackPoint() {
            let cs = CalGrayValidation()
            #expect(cs.hasValidBlackPoint)
        }

        @Test("Invalid when negative values")
        func negativeValues() {
            let cs = CalGrayValidation(blackPoint: [-0.01, 0.0, 0.0])
            #expect(!cs.hasValidBlackPoint)
        }

        @Test("Invalid when wrong count")
        func wrongCount() {
            let cs = CalGrayValidation(blackPoint: [0.0, 0.0])
            #expect(!cs.hasValidBlackPoint)
        }
    }

    // MARK: - Gamma Validation

    @Suite("Gamma Validation")
    struct GammaTests {

        @Test("Valid gamma 2.2")
        func validGamma() {
            let cs = CalGrayValidation(gamma: 2.2)
            #expect(cs.hasValidGamma)
        }

        @Test("Valid gamma 1.0")
        func gammaOne() {
            let cs = CalGrayValidation(gamma: 1.0)
            #expect(cs.hasValidGamma)
        }

        @Test("Valid when nil (optional)")
        func nilGamma() {
            let cs = CalGrayValidation()
            #expect(cs.hasValidGamma)
        }

        @Test("Invalid when zero")
        func zeroGamma() {
            let cs = CalGrayValidation(gamma: 0.0)
            #expect(!cs.hasValidGamma)
        }

        @Test("Invalid when negative")
        func negativeGamma() {
            let cs = CalGrayValidation(gamma: -1.0)
            #expect(!cs.hasValidGamma)
        }
    }

    // MARK: - Combined Validity

    @Suite("Combined Validity")
    struct CombinedValidityTests {

        @Test("Valid with all parameters set")
        func allValid() {
            let cs = CalGrayValidation(
                whitePoint: [0.9505, 1.0, 1.089],
                blackPoint: [0.0, 0.0, 0.0],
                gamma: 2.2
            )
            #expect(cs.isValid)
        }

        @Test("Invalid when white point missing")
        func invalidNoWhitePoint() {
            let cs = CalGrayValidation(gamma: 2.2)
            #expect(!cs.isValid)
        }

        @Test("Invalid when gamma is zero")
        func invalidBadGamma() {
            let cs = CalGrayValidation(
                whitePoint: [0.9505, 1.0, 1.089],
                gamma: 0.0
            )
            #expect(!cs.isValid)
        }

        @Test("Valid with white point only (optional params)")
        func validWhitePointOnly() {
            let cs = CalGrayValidation(whitePoint: [0.9505, 1.0, 1.089])
            #expect(cs.isValid)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include CalGray-specific properties")
        func propertyNames() {
            let cs = CalGrayValidation()
            let names = cs.propertyNames
            #expect(names.contains("hasWhitePoint"))
            #expect(names.contains("hasBlackPoint"))
            #expect(names.contains("gamma"))
            #expect(names.contains("hasValidWhitePoint"))
            #expect(names.contains("hasValidBlackPoint"))
            #expect(names.contains("hasValidGamma"))
            #expect(names.contains("isValid"))
        }

        @Test("Property access for hasWhitePoint")
        func hasWhitePoint() {
            let with = CalGrayValidation(whitePoint: [0.9505, 1.0, 1.089])
            #expect(with.property(named: "hasWhitePoint") == .boolean(true))

            let without = CalGrayValidation()
            #expect(without.property(named: "hasWhitePoint") == .boolean(false))
        }

        @Test("Property access for gamma")
        func gammaProperty() {
            let with = CalGrayValidation(gamma: 2.2)
            #expect(with.property(named: "gamma") == .real(2.2))

            let without = CalGrayValidation()
            #expect(without.property(named: "gamma") == .null)
        }

        @Test("Property access for validation computed properties")
        func validationProperties() {
            let valid = CalGrayValidation(whitePoint: [0.9505, 1.0, 1.089], gamma: 2.2)
            #expect(valid.property(named: "hasValidWhitePoint") == .boolean(true))
            #expect(valid.property(named: "hasValidGamma") == .boolean(true))
            #expect(valid.property(named: "isValid") == .boolean(true))
        }

        @Test("Falls through to color space properties")
        func colorSpaceFallthrough() {
            let cs = CalGrayValidation()
            #expect(cs.property(named: "colorSpaceFamily") == .string("CalGray"))
            #expect(cs.property(named: "componentCount") == .integer(1))
            #expect(cs.property(named: "isCIEBased") == .boolean(true))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let cs = CalGrayValidation()
            #expect(cs.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let cs1 = CalGrayValidation(id: id, gamma: 1.0)
            let cs2 = CalGrayValidation(id: id, gamma: 2.2)
            #expect(cs1 == cs2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let cs1 = CalGrayValidation()
            let cs2 = CalGrayValidation()
            #expect(cs1 != cs2)
        }
    }
}
