import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - CalRGBValidation Tests

@Suite("CalRGBValidation")
struct CalRGBValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let cs = CalRGBValidation()
            #expect(cs.colorSpaceFamily == .calRGB)
            #expect(cs.componentCount == 3)
            #expect(cs.whitePoint == nil)
            #expect(cs.blackPoint == nil)
            #expect(cs.gammaValues == nil)
            #expect(cs.matrix == nil)
            #expect(!cs.isDeviceDependent)
            #expect(cs.isCIEBased)
            #expect(!cs.isSpecial)
        }

        @Test("Object type is PDCalRGB")
        func objectType() {
            let cs = CalRGBValidation()
            #expect(cs.objectType == "PDCalRGB")
        }

        @Test("Full initialization")
        func fullInit() {
            let cs = CalRGBValidation(
                whitePoint: [0.9505, 1.0, 1.089],
                blackPoint: [0.0, 0.0, 0.0],
                gammaValues: [2.2, 2.2, 2.2],
                matrix: [0.4124, 0.2126, 0.0193,
                         0.3576, 0.7152, 0.1192,
                         0.1805, 0.0722, 0.9505]
            )
            #expect(cs.whitePoint?.count == 3)
            #expect(cs.blackPoint?.count == 3)
            #expect(cs.gammaValues?.count == 3)
            #expect(cs.matrix?.count == 9)
        }

        @Test("Default context is ColorSpace CalRGB")
        func defaultContext() {
            let cs = CalRGBValidation()
            #expect(cs.validationContext.location == "ColorSpace")
            #expect(cs.validationContext.role == "CalRGB")
        }
    }

    // MARK: - White Point Validation

    @Suite("White Point Validation")
    struct WhitePointTests {

        @Test("Valid white point")
        func validWhitePoint() {
            let cs = CalRGBValidation(whitePoint: [0.9505, 1.0, 1.089])
            #expect(cs.hasValidWhitePoint)
        }

        @Test("Invalid when nil")
        func nilWhitePoint() {
            let cs = CalRGBValidation()
            #expect(!cs.hasValidWhitePoint)
        }

        @Test("Invalid when Y is not 1.0")
        func invalidY() {
            let cs = CalRGBValidation(whitePoint: [0.9505, 0.5, 1.089])
            #expect(!cs.hasValidWhitePoint)
        }

        @Test("Invalid when wrong count")
        func wrongCount() {
            let cs = CalRGBValidation(whitePoint: [1.0, 1.0])
            #expect(!cs.hasValidWhitePoint)
        }
    }

    // MARK: - Black Point Validation

    @Suite("Black Point Validation")
    struct BlackPointTests {

        @Test("Valid black point")
        func validBlackPoint() {
            let cs = CalRGBValidation(blackPoint: [0.0, 0.0, 0.0])
            #expect(cs.hasValidBlackPoint)
        }

        @Test("Valid when nil")
        func nilBlackPoint() {
            let cs = CalRGBValidation()
            #expect(cs.hasValidBlackPoint)
        }

        @Test("Invalid when negative")
        func negativeValues() {
            let cs = CalRGBValidation(blackPoint: [0.0, -0.01, 0.0])
            #expect(!cs.hasValidBlackPoint)
        }

        @Test("Invalid when wrong count")
        func wrongCount() {
            let cs = CalRGBValidation(blackPoint: [0.0])
            #expect(!cs.hasValidBlackPoint)
        }
    }

    // MARK: - Gamma Validation

    @Suite("Gamma Validation")
    struct GammaTests {

        @Test("Valid gamma values")
        func validGamma() {
            let cs = CalRGBValidation(gammaValues: [2.2, 2.2, 2.2])
            #expect(cs.hasValidGamma)
        }

        @Test("Valid when nil")
        func nilGamma() {
            let cs = CalRGBValidation()
            #expect(cs.hasValidGamma)
        }

        @Test("Invalid when any value is zero")
        func zeroGamma() {
            let cs = CalRGBValidation(gammaValues: [2.2, 0.0, 2.2])
            #expect(!cs.hasValidGamma)
        }

        @Test("Invalid when any value is negative")
        func negativeGamma() {
            let cs = CalRGBValidation(gammaValues: [2.2, 2.2, -1.0])
            #expect(!cs.hasValidGamma)
        }

        @Test("Invalid when wrong count")
        func wrongCount() {
            let cs = CalRGBValidation(gammaValues: [2.2, 2.2])
            #expect(!cs.hasValidGamma)
        }
    }

    // MARK: - Matrix Validation

    @Suite("Matrix Validation")
    struct MatrixTests {

        @Test("Valid 3x3 matrix (9 values)")
        func validMatrix() {
            let cs = CalRGBValidation(matrix: [1, 0, 0, 0, 1, 0, 0, 0, 1])
            #expect(cs.hasValidMatrix)
        }

        @Test("Valid when nil")
        func nilMatrix() {
            let cs = CalRGBValidation()
            #expect(cs.hasValidMatrix)
        }

        @Test("Invalid when wrong count")
        func wrongCount() {
            let cs = CalRGBValidation(matrix: [1, 0, 0, 0, 1, 0])
            #expect(!cs.hasValidMatrix)
        }
    }

    // MARK: - Combined Validity

    @Suite("Combined Validity")
    struct CombinedValidityTests {

        @Test("Valid with all parameters")
        func allValid() {
            let cs = CalRGBValidation(
                whitePoint: [0.9505, 1.0, 1.089],
                blackPoint: [0.0, 0.0, 0.0],
                gammaValues: [2.2, 2.2, 2.2],
                matrix: [1, 0, 0, 0, 1, 0, 0, 0, 1]
            )
            #expect(cs.isValid)
        }

        @Test("Invalid when white point missing")
        func noWhitePoint() {
            let cs = CalRGBValidation(gammaValues: [2.2, 2.2, 2.2])
            #expect(!cs.isValid)
        }

        @Test("Invalid when gamma is bad")
        func badGamma() {
            let cs = CalRGBValidation(
                whitePoint: [0.9505, 1.0, 1.089],
                gammaValues: [2.2, 0.0, 2.2]
            )
            #expect(!cs.isValid)
        }

        @Test("Invalid when matrix wrong size")
        func badMatrix() {
            let cs = CalRGBValidation(
                whitePoint: [0.9505, 1.0, 1.089],
                matrix: [1, 0, 0]
            )
            #expect(!cs.isValid)
        }

        @Test("Valid with white point only")
        func whitePointOnly() {
            let cs = CalRGBValidation(whitePoint: [0.9505, 1.0, 1.089])
            #expect(cs.isValid)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include CalRGB-specific properties")
        func propertyNames() {
            let cs = CalRGBValidation()
            let names = cs.propertyNames
            #expect(names.contains("hasWhitePoint"))
            #expect(names.contains("hasBlackPoint"))
            #expect(names.contains("hasGamma"))
            #expect(names.contains("hasMatrix"))
            #expect(names.contains("hasValidWhitePoint"))
            #expect(names.contains("hasValidBlackPoint"))
            #expect(names.contains("hasValidGamma"))
            #expect(names.contains("hasValidMatrix"))
            #expect(names.contains("isValid"))
        }

        @Test("Property access for hasWhitePoint")
        func hasWhitePoint() {
            let with = CalRGBValidation(whitePoint: [0.9505, 1.0, 1.089])
            #expect(with.property(named: "hasWhitePoint") == .boolean(true))

            let without = CalRGBValidation()
            #expect(without.property(named: "hasWhitePoint") == .boolean(false))
        }

        @Test("Property access for hasGamma")
        func hasGamma() {
            let with = CalRGBValidation(gammaValues: [2.2, 2.2, 2.2])
            #expect(with.property(named: "hasGamma") == .boolean(true))

            let without = CalRGBValidation()
            #expect(without.property(named: "hasGamma") == .boolean(false))
        }

        @Test("Property access for hasMatrix")
        func hasMatrix() {
            let with = CalRGBValidation(matrix: [1, 0, 0, 0, 1, 0, 0, 0, 1])
            #expect(with.property(named: "hasMatrix") == .boolean(true))

            let without = CalRGBValidation()
            #expect(without.property(named: "hasMatrix") == .boolean(false))
        }

        @Test("Falls through to color space properties")
        func colorSpaceFallthrough() {
            let cs = CalRGBValidation()
            #expect(cs.property(named: "colorSpaceFamily") == .string("CalRGB"))
            #expect(cs.property(named: "componentCount") == .integer(3))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let cs = CalRGBValidation()
            #expect(cs.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let cs1 = CalRGBValidation(id: id, gammaValues: [1.0, 1.0, 1.0])
            let cs2 = CalRGBValidation(id: id, gammaValues: [2.2, 2.2, 2.2])
            #expect(cs1 == cs2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let cs1 = CalRGBValidation()
            let cs2 = CalRGBValidation()
            #expect(cs1 != cs2)
        }
    }
}
