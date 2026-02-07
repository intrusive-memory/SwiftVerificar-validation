import Testing
import Foundation
@testable import SwiftVerificarValidation

/// Tests for TextOperatorValidator.
@Suite("TextOperatorValidator Tests")
struct TextOperatorValidatorTests {

    // MARK: - Initialization Tests

    @Test("Default validator configuration")
    func defaultValidatorConfiguration() {
        let validator = TextOperatorValidator()
        #expect(validator.requireFontEmbedding == false)
        #expect(validator.requireUnicodeMappings == false)
        #expect(validator.allowEmptyText == true)
    }

    @Test("Custom validator configuration")
    func customValidatorConfiguration() {
        let validator = TextOperatorValidator(
            requireFontEmbedding: true,
            requireUnicodeMappings: true,
            allowEmptyText: false,
            knownFonts: ["Helvetica", "Times"],
            embeddedFonts: ["Helvetica"]
        )
        #expect(validator.requireFontEmbedding == true)
        #expect(validator.requireUnicodeMappings == true)
        #expect(validator.allowEmptyText == false)
        #expect(validator.knownFonts.count == 2)
    }

    // MARK: - BT/ET Validation Tests

    @Test("BT in initial state passes")
    func btInInitialState() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.beginText, in: context)
        #expect(result.isValid == true)
    }

    @Test("BT while already in text object fails")
    func btWhileInTextObject() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        let result = validator.validate(.beginText, in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { $0 == .nestedBeginText })
    }

    @Test("ET while in text object passes")
    func etWhileInTextObject() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        let result = validator.validate(.endText, in: context)
        #expect(result.isValid == true)
    }

    @Test("ET without BT fails")
    func etWithoutBt() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.endText, in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { $0 == .unmatchedEndText })
    }

    // MARK: - Tf Validation Tests

    @Test("Tf with valid font and size passes")
    func tfWithValidFontAndSize() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setFont(name: ASAtom("Helvetica"), size: 12), in: context)
        #expect(result.isValid == true)
    }

    @Test("Tf with zero size fails")
    func tfWithZeroSize() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setFont(name: ASAtom("Helvetica"), size: 0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .invalidFontSize = issue { return true }
            return false
        })
    }

    @Test("Tf with negative size fails")
    func tfWithNegativeSize() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setFont(name: ASAtom("Helvetica"), size: -12), in: context)
        #expect(result.isValid == false)
    }

    @Test("Tf with unknown font fails when fonts are tracked")
    func tfWithUnknownFont() {
        let validator = TextOperatorValidator(
            requireFontEmbedding: false,
            requireUnicodeMappings: false,
            knownFonts: ["Helvetica", "Times"]
        )
        let context = OperatorValidationContext()
        let result = validator.validate(.setFont(name: ASAtom("Arial"), size: 12), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .undefinedFont = issue { return true }
            return false
        })
    }

    @Test("Tf with non-embedded font fails when embedding required")
    func tfWithNonEmbeddedFont() {
        let validator = TextOperatorValidator(
            requireFontEmbedding: true,
            requireUnicodeMappings: false,
            knownFonts: ["Helvetica", "Times"],
            embeddedFonts: ["Helvetica"]
        )
        let context = OperatorValidationContext()
        let result = validator.validate(.setFont(name: ASAtom("Times"), size: 12), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .fontNotEmbedded = issue { return true }
            return false
        })
    }

    // MARK: - Text State Operator Tests

    @Test("Tc with normal value passes")
    func tcWithNormalValue() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setCharacterSpacing(0.5), in: context)
        #expect(result.isValid == true)
    }

    @Test("Tc with extreme value fails")
    func tcWithExtremeValue() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setCharacterSpacing(50000), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .invalidCharacterSpacing = issue { return true }
            return false
        })
    }

    @Test("Tw with normal value passes")
    func twWithNormalValue() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setWordSpacing(-2.0), in: context)
        #expect(result.isValid == true)
    }

    @Test("Tz with normal value passes")
    func tzWithNormalValue() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setHorizontalScaling(100), in: context)
        #expect(result.isValid == true)
    }

    @Test("Tz with zero value fails")
    func tzWithZeroValue() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setHorizontalScaling(0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .invalidHorizontalScaling = issue { return true }
            return false
        })
    }

    @Test("Tr with valid mode passes")
    func trWithValidMode() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        for mode in 0...7 {
            let result = validator.validate(.setTextRenderingMode(mode), in: context)
            #expect(result.isValid == true)
        }
    }

    @Test("Tr with invalid mode fails")
    func trWithInvalidMode() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()

        let resultNegative = validator.validate(.setTextRenderingMode(-1), in: context)
        #expect(resultNegative.isValid == false)

        let resultHigh = validator.validate(.setTextRenderingMode(8), in: context)
        #expect(resultHigh.isValid == false)
    }

    // MARK: - Text Matrix Validation Tests

    @Test("Tm with identity matrix passes")
    func tmWithIdentityMatrix() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setTextMatrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0), in: context)
        #expect(result.isValid == true)
    }

    @Test("Tm with scaled matrix passes")
    func tmWithScaledMatrix() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setTextMatrix(a: 2, b: 0, c: 0, d: 2, e: 100, f: 200), in: context)
        #expect(result.isValid == true)
    }

    @Test("Tm with singular matrix fails")
    func tmWithSingularMatrix() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setTextMatrix(a: 0, b: 0, c: 0, d: 0, e: 0, f: 0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { $0 == .singularTextMatrix })
    }

    // MARK: - Text Showing Operator Tests

    @Test("Tj in text object with font passes")
    func tjInTextObjectWithFont() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        context.textState.fontName = ASAtom("Helvetica")
        context.textState.fontSize = 12
        let result = validator.validate(.showText(Data("Hello".utf8)), in: context)
        #expect(result.isValid == true)
    }

    @Test("Tj outside text object fails")
    func tjOutsideTextObject() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        context.textState.fontName = ASAtom("Helvetica")
        context.textState.fontSize = 12
        let result = validator.validate(.showText(Data("Hello".utf8)), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .textOperatorOutsideTextObject = issue { return true }
            return false
        })
    }

    @Test("Tj without font selected fails")
    func tjWithoutFontSelected() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        let result = validator.validate(.showText(Data("Hello".utf8)), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { $0 == .noFontSelected })
    }

    @Test("Tj with empty text passes by default")
    func tjWithEmptyTextDefault() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        context.textState.fontName = ASAtom("Helvetica")
        context.textState.fontSize = 12
        let result = validator.validate(.showText(Data()), in: context)
        #expect(result.isValid == true)
    }

    @Test("Tj with empty text fails when not allowed")
    func tjWithEmptyTextNotAllowed() {
        let validator = TextOperatorValidator(
            requireFontEmbedding: false,
            requireUnicodeMappings: false,
            allowEmptyText: false
        )
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        context.textState.fontName = ASAtom("Helvetica")
        context.textState.fontSize = 12
        let result = validator.validate(.showText(Data()), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { $0 == .emptyTextString })
    }

    // MARK: - TJ Operator Tests

    @Test("TJ in text object with font passes")
    func tjArrayInTextObjectWithFont() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        context.textState.fontName = ASAtom("Helvetica")
        context.textState.fontSize = 12

        let elements: [ValidatedTextArrayElement] = [
            .text(Data("Hello".utf8)),
            .adjustment(-50),
            .text(Data(" World".utf8))
        ]
        let result = validator.validate(.showTextArray(elements), in: context)
        #expect(result.isValid == true)
    }

    @Test("TJ outside text object fails")
    func tjArrayOutsideTextObject() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        context.textState.fontName = ASAtom("Helvetica")
        context.textState.fontSize = 12

        let elements: [ValidatedTextArrayElement] = [.text(Data("Hello".utf8))]
        let result = validator.validate(.showTextArray(elements), in: context)
        #expect(result.isValid == false)
    }

    @Test("TJ with empty array fails when empty text not allowed")
    func tjArrayEmpty() {
        let validator = TextOperatorValidator(
            requireFontEmbedding: false,
            requireUnicodeMappings: false,
            allowEmptyText: false
        )
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        context.textState.fontName = ASAtom("Helvetica")
        context.textState.fontSize = 12

        let elements: [ValidatedTextArrayElement] = [.adjustment(-50)]  // Only adjustments, no text
        let result = validator.validate(.showTextArray(elements), in: context)
        #expect(result.isValid == false)
    }

    // MARK: - Quote Operator Tests

    @Test("Single quote operator validates like Tj")
    func singleQuoteOperator() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        context.textState.fontName = ASAtom("Helvetica")
        context.textState.fontSize = 12
        let result = validator.validate(.moveAndShowText(Data("Hello".utf8)), in: context)
        #expect(result.isValid == true)
    }

    @Test("Double quote operator validates like Tj")
    func doubleQuoteOperator() {
        let validator = TextOperatorValidator()
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        context.textState.fontName = ASAtom("Helvetica")
        context.textState.fontSize = 12
        let result = validator.validate(
            .moveAndShowTextWithSpacing(wordSpacing: 0, charSpacing: 0, text: Data("Hello".utf8)),
            in: context
        )
        #expect(result.isValid == true)
    }

    // MARK: - Text Positioning Operator Tests

    @Test("Text positioning operators require text object")
    func textPositioningRequiresTextObject() {
        let validator = TextOperatorValidator()
        let context = OperatorValidationContext()

        // These should fail outside text object
        let tdResult = validator.validate(.moveTextPosition(tx: 100, ty: 0), in: context)
        #expect(tdResult.isValid == false)

        let starResult = validator.validate(.moveToNextLine, in: context)
        #expect(starResult.isValid == false)
    }

    // MARK: - TextRenderingMode Tests

    @Test("TextRenderingMode properties")
    func textRenderingModeProperties() {
        #expect(TextRenderingMode.fill.involvesFill == true)
        #expect(TextRenderingMode.fill.involvesStroke == false)
        #expect(TextRenderingMode.fill.involvesClip == false)
        #expect(TextRenderingMode.fill.isVisible == true)

        #expect(TextRenderingMode.stroke.involvesFill == false)
        #expect(TextRenderingMode.stroke.involvesStroke == true)

        #expect(TextRenderingMode.fillStroke.involvesFill == true)
        #expect(TextRenderingMode.fillStroke.involvesStroke == true)

        #expect(TextRenderingMode.invisible.isVisible == false)
        #expect(TextRenderingMode.clip.isVisible == false)

        #expect(TextRenderingMode.fillClip.involvesClip == true)
    }

    // MARK: - TextValidationIssue Tests

    @Test("TextValidationIssue descriptions")
    func textValidationIssueDescriptions() {
        let issue1 = TextValidationIssue.noFontSelected
        #expect(issue1.description.contains("font"))

        let issue2 = TextValidationIssue.invalidFontSize(size: -12)
        #expect(issue2.description.contains("-12"))

        let issue3 = TextValidationIssue.textOperatorOutsideTextObject(operator: "Tj")
        #expect(issue3.description.contains("Tj"))
    }

    @Test("TextValidationIssue severity")
    func textValidationIssueSeverity() {
        #expect(TextValidationIssue.noFontSelected.severity == .error)
        #expect(TextValidationIssue.nestedBeginText.severity == .error)
        #expect(TextValidationIssue.emptyTextString.severity == .warning)
    }

    // MARK: - PDF/A Text Validator Tests

    @Test("PDFATextValidator creation")
    func pdfaTextValidatorCreation() {
        let validator = PDFATextValidator(
            conformanceLevel: .pdfa1a,
            knownFonts: ["Helvetica"],
            embeddedFonts: ["Helvetica"]
        )
        #expect(validator.conformanceLevel == .pdfa1a)
    }

    // MARK: - PDFATextConformance Tests

    @Test("PDFATextConformance requires font embedding")
    func pdfaTextConformanceRequiresEmbedding() {
        for level in PDFATextConformance.allCases {
            #expect(level.requiresFontEmbedding == true)
        }
    }

    @Test("PDFATextConformance Unicode mapping requirements")
    func pdfaTextConformanceUnicodeMapping() {
        #expect(PDFATextConformance.pdfa1a.requiresUnicodeMappings == true)
        #expect(PDFATextConformance.pdfa1b.requiresUnicodeMappings == false)
        #expect(PDFATextConformance.pdfa2a.requiresUnicodeMappings == true)
        #expect(PDFATextConformance.pdfa2b.requiresUnicodeMappings == false)
        #expect(PDFATextConformance.pdfa2u.requiresUnicodeMappings == true)
    }

    @Test("PDFATextConformance accessibility level")
    func pdfaTextConformanceAccessibility() {
        #expect(PDFATextConformance.pdfa1a.isAccessibilityLevel == true)
        #expect(PDFATextConformance.pdfa1b.isAccessibilityLevel == false)
        #expect(PDFATextConformance.pdfa2a.isAccessibilityLevel == true)
        #expect(PDFATextConformance.pdfa2b.isAccessibilityLevel == false)
    }

    // MARK: - FontValidationInfo Tests

    @Test("FontValidationInfo creation")
    func fontValidationInfoCreation() {
        let info = FontValidationInfo(
            name: "Helvetica",
            isEmbedded: true,
            hasToUnicode: true,
            isSymbolic: false,
            fontType: "TrueType",
            encoding: "WinAnsiEncoding"
        )
        #expect(info.name == "Helvetica")
        #expect(info.isEmbedded == true)
        #expect(info.hasToUnicode == true)
    }

    @Test("FontValidationInfo PDF/A compliance check")
    func fontValidationInfoPDFACompliance() {
        let embeddedWithUnicode = FontValidationInfo(
            name: "Helvetica",
            isEmbedded: true,
            hasToUnicode: true
        )
        #expect(embeddedWithUnicode.meetsPDFARequirements(level: .pdfa1a) == true)
        #expect(embeddedWithUnicode.meetsPDFARequirements(level: .pdfa1b) == true)

        let embeddedNoUnicode = FontValidationInfo(
            name: "Helvetica",
            isEmbedded: true,
            hasToUnicode: false
        )
        #expect(embeddedNoUnicode.meetsPDFARequirements(level: .pdfa1a) == false)
        #expect(embeddedNoUnicode.meetsPDFARequirements(level: .pdfa1b) == true)

        let notEmbedded = FontValidationInfo(
            name: "Helvetica",
            isEmbedded: false,
            hasToUnicode: true
        )
        #expect(notEmbedded.meetsPDFARequirements(level: .pdfa1a) == false)
        #expect(notEmbedded.meetsPDFARequirements(level: .pdfa1b) == false)

        // Symbolic fonts don't require ToUnicode
        let symbolicNoUnicode = FontValidationInfo(
            name: "Symbol",
            isEmbedded: true,
            hasToUnicode: false,
            isSymbolic: true
        )
        #expect(symbolicNoUnicode.meetsPDFARequirements(level: .pdfa1a) == true)
    }
}
