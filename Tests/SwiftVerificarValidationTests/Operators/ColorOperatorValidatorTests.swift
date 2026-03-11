import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarParser

/// Tests for ColorOperatorValidator.
@Suite("ColorOperatorValidator Tests")
struct ColorOperatorValidatorTests {

    // MARK: - Initialization Tests

    @Test("Default validator allows device color spaces")
    func defaultValidatorConfiguration() {
        let validator = ColorOperatorValidator()
        #expect(validator.allowDeviceColorSpaces == true)
        #expect(validator.strictRangeValidation == true)
    }

    @Test("Custom validator configuration")
    func customValidatorConfiguration() {
        let validator = ColorOperatorValidator(
            allowDeviceColorSpaces: false,
            strictRangeValidation: false
        )
        #expect(validator.allowDeviceColorSpaces == false)
        #expect(validator.strictRangeValidation == false)
    }

    // MARK: - Gray Operator Validation Tests

    @Test("Valid gray stroke value passes")
    func validGrayStroke() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setGrayStroke(0.5), in: context)
        #expect(result.isValid == true)
        #expect(result.colorSpace == .deviceGray)
        #expect(result.components == [0.5])
    }

    @Test("Valid gray fill value passes")
    func validGrayFill() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setGrayFill(0.0), in: context)
        #expect(result.isValid == true)
    }

    @Test("Gray value at boundary passes")
    func grayValueAtBoundary() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()

        let result0 = validator.validate(.setGrayFill(0.0), in: context)
        #expect(result0.isValid == true)

        let result1 = validator.validate(.setGrayFill(1.0), in: context)
        #expect(result1.isValid == true)
    }

    @Test("Gray value out of range fails with strict validation")
    func grayValueOutOfRange() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()

        let resultNegative = validator.validate(.setGrayFill(-0.1), in: context)
        #expect(resultNegative.isValid == false)
        #expect(resultNegative.issues.contains { issue in
            if case .componentOutOfRange = issue { return true }
            return false
        })

        let resultOver = validator.validate(.setGrayFill(1.1), in: context)
        #expect(resultOver.isValid == false)
    }

    @Test("Gray value out of range passes with relaxed validation")
    func grayValueRelaxedValidation() {
        let validator = ColorOperatorValidator(
            allowDeviceColorSpaces: true,
            strictRangeValidation: false
        )
        let context = OperatorValidationContext()
        let result = validator.validate(.setGrayFill(1.5), in: context)
        #expect(result.isValid == true)
    }

    // MARK: - RGB Operator Validation Tests

    @Test("Valid RGB stroke value passes")
    func validRGBStroke() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setRGBStroke(r: 1.0, g: 0.0, b: 0.0), in: context)
        #expect(result.isValid == true)
        #expect(result.colorSpace == .deviceRGB)
        #expect(result.components == [1.0, 0.0, 0.0])
    }

    @Test("Valid RGB fill value passes")
    func validRGBFill() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setRGBFill(r: 0.5, g: 0.5, b: 0.5), in: context)
        #expect(result.isValid == true)
    }

    @Test("RGB component out of range fails")
    func rgbComponentOutOfRange() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setRGBFill(r: 1.5, g: 0.0, b: 0.0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.count >= 1)
    }

    @Test("Multiple RGB components out of range reports all")
    func multipleRGBComponentsOutOfRange() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setRGBFill(r: -0.1, g: 1.5, b: 2.0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.count >= 3)
    }

    // MARK: - CMYK Operator Validation Tests

    @Test("Valid CMYK stroke value passes")
    func validCMYKStroke() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setCMYKStroke(c: 0.0, m: 1.0, y: 1.0, k: 0.0), in: context)
        #expect(result.isValid == true)
        #expect(result.colorSpace == .deviceCMYK)
        #expect(result.components == [0.0, 1.0, 1.0, 0.0])
    }

    @Test("Valid CMYK fill value passes")
    func validCMYKFill() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setCMYKFill(c: 0.1, m: 0.2, y: 0.3, k: 0.4), in: context)
        #expect(result.isValid == true)
    }

    @Test("CMYK component out of range fails")
    func cmykComponentOutOfRange() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setCMYKFill(c: 0.0, m: 0.0, y: 0.0, k: 1.5), in: context)
        #expect(result.isValid == false)
    }

    // MARK: - Device Color Space Restriction Tests

    @Test("Device gray not allowed when restricted")
    func deviceGrayNotAllowed() {
        let validator = ColorOperatorValidator(allowDeviceColorSpaces: false)
        let context = OperatorValidationContext()
        let result = validator.validate(.setGrayFill(0.5), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .deviceColorSpaceNotPermitted(.deviceGray) = issue { return true }
            return false
        })
    }

    @Test("Device RGB not allowed when restricted")
    func deviceRGBNotAllowed() {
        let validator = ColorOperatorValidator(allowDeviceColorSpaces: false)
        let context = OperatorValidationContext()
        let result = validator.validate(.setRGBFill(r: 1, g: 0, b: 0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .deviceColorSpaceNotPermitted(.deviceRGB) = issue { return true }
            return false
        })
    }

    @Test("Device CMYK not allowed when restricted")
    func deviceCMYKNotAllowed() {
        let validator = ColorOperatorValidator(allowDeviceColorSpaces: false)
        let context = OperatorValidationContext()
        let result = validator.validate(.setCMYKFill(c: 0, m: 0, y: 0, k: 0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .deviceColorSpaceNotPermitted(.deviceCMYK) = issue { return true }
            return false
        })
    }

    // MARK: - Color Space Selection Validation Tests

    @Test("Valid color space selection passes")
    func validColorSpaceSelection() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setColorSpaceFill(ASAtom("DeviceRGB")), in: context)
        #expect(result.isValid == true)
        #expect(result.colorSpace == .deviceRGB)
    }

    @Test("Unknown color space reported")
    func unknownColorSpace() {
        let validator = ColorOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setColorSpaceFill(ASAtom("CustomCS")), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .unknownColorSpace = issue { return true }
            return false
        })
    }

    @Test("Device color space selection fails when restricted")
    func deviceColorSpaceSelectionRestricted() {
        let validator = ColorOperatorValidator(allowDeviceColorSpaces: false)
        let context = OperatorValidationContext()
        let result = validator.validate(.setColorSpaceStroke(ASAtom("DeviceGray")), in: context)
        #expect(result.isValid == false)
    }

    // MARK: - SC/sc Operator Validation Tests

    @Test("SC with correct component count passes")
    func scWithCorrectComponentCount() {
        var context = OperatorValidationContext()
        context.currentGraphicsState.strokeColorSpace = ASAtom("DeviceRGB")

        let validator = ColorOperatorValidator()
        let result = validator.validate(.setColorStroke([1.0, 0.5, 0.0]), in: context)
        #expect(result.isValid == true)
    }

    @Test("SC with wrong component count fails")
    func scWithWrongComponentCount() {
        var context = OperatorValidationContext()
        context.currentGraphicsState.strokeColorSpace = ASAtom("DeviceRGB")

        let validator = ColorOperatorValidator()
        let result = validator.validate(.setColorStroke([1.0, 0.5]), in: context)  // Only 2 components
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .wrongComponentCount = issue { return true }
            return false
        })
    }

    @Test("SC without color space set fails")
    func scWithoutColorSpace() {
        var context = OperatorValidationContext()
        context.currentGraphicsState.strokeColorSpace = nil

        let validator = ColorOperatorValidator()
        let result = validator.validate(.setColorStroke([0.5]), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .colorSpaceNotSet = issue { return true }
            return false
        })
    }

    // MARK: - SCN/scn Operator Validation Tests

    @Test("SCN with pattern passes for pattern color space")
    func scnWithPattern() {
        var context = OperatorValidationContext()
        context.currentGraphicsState.strokeColorSpace = ASAtom("Pattern")

        let validator = ColorOperatorValidator()
        let result = validator.validate(
            .setColorStrokeN(components: [], pattern: ASAtom("P1")),
            in: context
        )
        #expect(result.isValid == true)
    }

    @Test("SCN with pattern for non-pattern color space warns")
    func scnWithPatternWrongColorSpace() {
        var context = OperatorValidationContext()
        context.currentGraphicsState.strokeColorSpace = ASAtom("DeviceRGB")

        let validator = ColorOperatorValidator()
        let result = validator.validate(
            .setColorStrokeN(components: [1, 0, 0], pattern: ASAtom("P1")),
            in: context
        )
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .patternWithoutPatternColorSpace = issue { return true }
            return false
        })
    }

    // MARK: - ColorSpaceType Tests

    @Test("ColorSpaceType from ASAtom")
    func colorSpaceTypeFromAtom() {
        #expect(ColorSpaceType(from: ASAtom("DeviceGray")) == .deviceGray)
        #expect(ColorSpaceType(from: ASAtom("DeviceRGB")) == .deviceRGB)
        #expect(ColorSpaceType(from: ASAtom("DeviceCMYK")) == .deviceCMYK)
        #expect(ColorSpaceType(from: ASAtom("CalGray")) == .calGray)
        #expect(ColorSpaceType(from: ASAtom("CalRGB")) == .calRGB)
        #expect(ColorSpaceType(from: ASAtom("Lab")) == .lab)
        #expect(ColorSpaceType(from: ASAtom("ICCBased")) == .iccBased)
        #expect(ColorSpaceType(from: ASAtom("Indexed")) == .indexed)
        #expect(ColorSpaceType(from: ASAtom("Pattern")) == .pattern)
        #expect(ColorSpaceType(from: ASAtom("Separation")) == .separation)
        #expect(ColorSpaceType(from: ASAtom("DeviceN")) == .deviceN)
        #expect(ColorSpaceType(from: ASAtom("Unknown")) == .unknown)
    }

    @Test("ColorSpaceType abbreviations")
    func colorSpaceTypeAbbreviations() {
        #expect(ColorSpaceType(from: ASAtom("G")) == .deviceGray)
        #expect(ColorSpaceType(from: ASAtom("RGB")) == .deviceRGB)
        #expect(ColorSpaceType(from: ASAtom("CMYK")) == .deviceCMYK)
        #expect(ColorSpaceType(from: ASAtom("I")) == .indexed)
    }

    @Test("ColorSpaceType expected component counts")
    func colorSpaceTypeComponentCounts() {
        #expect(ColorSpaceType.deviceGray.expectedComponentCount == 1)
        #expect(ColorSpaceType.deviceRGB.expectedComponentCount == 3)
        #expect(ColorSpaceType.deviceCMYK.expectedComponentCount == 4)
        #expect(ColorSpaceType.lab.expectedComponentCount == 3)
        #expect(ColorSpaceType.iccBased.expectedComponentCount == nil)
        #expect(ColorSpaceType.pattern.expectedComponentCount == nil)
    }

    @Test("ColorSpaceType classification")
    func colorSpaceTypeClassification() {
        #expect(ColorSpaceType.deviceGray.isDeviceColorSpace == true)
        #expect(ColorSpaceType.deviceRGB.isDeviceColorSpace == true)
        #expect(ColorSpaceType.calRGB.isDeviceColorSpace == false)

        #expect(ColorSpaceType.calGray.isCIEBased == true)
        #expect(ColorSpaceType.lab.isCIEBased == true)
        #expect(ColorSpaceType.deviceGray.isCIEBased == false)

        #expect(ColorSpaceType.pattern.isSpecialColorSpace == true)
        #expect(ColorSpaceType.separation.isSpecialColorSpace == true)
        #expect(ColorSpaceType.deviceRGB.isSpecialColorSpace == false)
    }

    // MARK: - ColorValidationIssue Tests

    @Test("ColorValidationIssue descriptions are meaningful")
    func colorValidationIssueDescriptions() {
        let issue1 = ColorValidationIssue.componentOutOfRange(index: 0, value: 1.5, expected: 0.0...1.0)
        #expect(issue1.description.contains("out of range"))

        let issue2 = ColorValidationIssue.wrongComponentCount(expected: 3, actual: 4)
        #expect(issue2.description.contains("Wrong"))

        let issue3 = ColorValidationIssue.deviceColorSpaceNotPermitted(.deviceRGB)
        #expect(issue3.description.contains("not permitted"))
    }

    // MARK: - ICCProfileInfo Tests

    @Test("ICCProfileInfo creation")
    func iccProfileInfoCreation() {
        let info = ICCProfileInfo(
            version: "4.3.0.0",
            colorSpaceSignature: "RGB ",
            componentCount: 3,
            profileClass: "display"
        )
        #expect(info.version == "4.3.0.0")
        #expect(info.componentCount == 3)
        #expect(info.isOutputProfile == false)
    }

    @Test("ICCProfileInfo output profile detection")
    func iccProfileInfoOutputProfile() {
        let outputProfile = ICCProfileInfo(
            version: "4.3.0.0",
            colorSpaceSignature: "CMYK",
            componentCount: 4,
            profileClass: "output"
        )
        #expect(outputProfile.isOutputProfile == true)

        let printerProfile = ICCProfileInfo(
            version: "4.3.0.0",
            colorSpaceSignature: "CMYK",
            componentCount: 4,
            profileClass: "prtr"
        )
        #expect(printerProfile.isOutputProfile == true)
    }

    @Test("ICCProfileInfo color space type")
    func iccProfileInfoColorSpaceType() {
        let rgbProfile = ICCProfileInfo(
            version: "4.3.0.0",
            colorSpaceSignature: "RGB ",
            componentCount: 3,
            profileClass: "display"
        )
        #expect(rgbProfile.colorSpaceType == .deviceRGB)

        let cmykProfile = ICCProfileInfo(
            version: "4.3.0.0",
            colorSpaceSignature: "CMYK",
            componentCount: 4,
            profileClass: "output"
        )
        #expect(cmykProfile.colorSpaceType == .deviceCMYK)

        let grayProfile = ICCProfileInfo(
            version: "4.3.0.0",
            colorSpaceSignature: "GRAY",
            componentCount: 1,
            profileClass: "display"
        )
        #expect(grayProfile.colorSpaceType == .deviceGray)
    }

    // MARK: - PDF/A Color Validator Tests

    @Test("PDFAColorValidator rejects device color spaces")
    func pdfaColorValidatorRejectsDevice() {
        let validator = PDFAColorValidator(conformanceLevel: .pdfa1a)
        let context = OperatorValidationContext()
        let result = validator.validate(.setRGBFill(r: 1, g: 0, b: 0), in: context)
        #expect(result.isValid == false)
    }

    @Test("PDFAColorConformance levels")
    func pdfaColorConformanceLevels() {
        for level in PDFAColorConformance.allCases {
            #expect(level.allowsDeviceColorSpaces == false)
            #expect(level.allowsUncalibratedColor == false)
        }
    }

    // MARK: - Utility Methods Tests

    @Test("Expected component count utility")
    func expectedComponentCountUtility() {
        let validator = ColorOperatorValidator()
        #expect(validator.expectedComponentCount(for: ASAtom("DeviceGray")) == 1)
        #expect(validator.expectedComponentCount(for: ASAtom("DeviceRGB")) == 3)
        #expect(validator.expectedComponentCount(for: ASAtom("DeviceCMYK")) == 4)
        #expect(validator.expectedComponentCount(for: ASAtom("ICCBased")) == nil)
    }

    @Test("Validate component ranges utility")
    func validateComponentRangesUtility() {
        let validator = ColorOperatorValidator()

        let validIssues = validator.validateComponentRanges([0.5, 0.5, 0.5])
        #expect(validIssues.isEmpty)

        let invalidIssues = validator.validateComponentRanges([0.5, 1.5, -0.5])
        #expect(invalidIssues.count == 2)
    }
}
