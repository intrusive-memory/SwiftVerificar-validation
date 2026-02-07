import Testing
import Foundation
@testable import SwiftVerificarValidation

/// Tests for GraphicsStateValidator.
@Suite("GraphicsStateValidator Tests")
struct GraphicsStateValidatorTests {

    // MARK: - Initialization Tests

    @Test("Default validator configuration")
    func defaultValidatorConfiguration() {
        let validator = GraphicsStateValidator()
        #expect(validator.maxStackDepth == 28)
        #expect(validator.allowTransparency == true)
    }

    @Test("Custom validator configuration")
    func customValidatorConfiguration() {
        let validator = GraphicsStateValidator(
            maxStackDepth: 50,
            allowTransparency: false,
            knownExtGStates: ["GS1", "GS2"],
            transparentExtGStates: ["GS2"]
        )
        #expect(validator.maxStackDepth == 50)
        #expect(validator.allowTransparency == false)
        #expect(validator.knownExtGStates.count == 2)
    }

    // MARK: - q/Q Validation Tests

    @Test("q operator passes in normal state")
    func qOperatorPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.saveGraphicsState, in: context)
        #expect(result.isValid == true)
    }

    @Test("Q operator passes after q")
    func qOperatorAfterQ() {
        let validator = GraphicsStateValidator()
        var context = OperatorValidationContext()
        context.pushGraphicsState()
        let result = validator.validate(.restoreGraphicsState, in: context)
        #expect(result.isValid == true)
    }

    @Test("Q operator fails on stack underflow")
    func qOperatorStackUnderflow() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.restoreGraphicsState, in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { $0 == .graphicsStateStackUnderflow })
    }

    @Test("q operator fails on stack overflow")
    func qOperatorStackOverflow() {
        let validator = GraphicsStateValidator(maxStackDepth: 3)
        var context = OperatorValidationContext()
        context.pushGraphicsState()
        context.pushGraphicsState()
        // Stack depth is now 3, which equals maxStackDepth
        let result = validator.validate(.saveGraphicsState, in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .graphicsStateStackOverflow = issue { return true }
            return false
        })
    }

    // MARK: - Matrix Validation Tests

    @Test("Identity matrix passes")
    func identityMatrixPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.concatMatrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0), in: context)
        #expect(result.isValid == true)
    }

    @Test("Scaled matrix passes")
    func scaledMatrixPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.concatMatrix(a: 2, b: 0, c: 0, d: 2, e: 100, f: 100), in: context)
        #expect(result.isValid == true)
    }

    @Test("Rotated matrix passes")
    func rotatedMatrixPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        // 45-degree rotation
        let cos45 = 0.7071067811865476
        let sin45 = 0.7071067811865476
        let result = validator.validate(.concatMatrix(a: cos45, b: sin45, c: -sin45, d: cos45, e: 0, f: 0), in: context)
        #expect(result.isValid == true)
    }

    @Test("Singular matrix fails")
    func singularMatrixFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.concatMatrix(a: 0, b: 0, c: 0, d: 0, e: 0, f: 0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { $0 == .singularMatrix })
    }

    @Test("Matrix with NaN fails")
    func matrixWithNaNFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.concatMatrix(a: Double.nan, b: 0, c: 0, d: 1, e: 0, f: 0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { $0 == .invalidMatrixComponents })
    }

    @Test("Matrix with Infinity fails")
    func matrixWithInfinityFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.concatMatrix(a: Double.infinity, b: 0, c: 0, d: 1, e: 0, f: 0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { $0 == .invalidMatrixComponents })
    }

    // MARK: - Line Width Validation Tests

    @Test("Positive line width passes")
    func positiveLineWidthPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setLineWidth(1.5), in: context)
        #expect(result.isValid == true)
    }

    @Test("Zero line width passes")
    func zeroLineWidthPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setLineWidth(0), in: context)
        #expect(result.isValid == true)  // 0 means thinnest possible
    }

    @Test("Negative line width fails")
    func negativeLineWidthFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setLineWidth(-1), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .invalidLineWidth = issue { return true }
            return false
        })
    }

    // MARK: - Line Cap Validation Tests

    @Test("Valid line cap values pass")
    func validLineCapPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        for cap in 0...2 {
            let result = validator.validate(.setLineCap(cap), in: context)
            #expect(result.isValid == true)
        }
    }

    @Test("Invalid line cap value fails")
    func invalidLineCapFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()

        let resultNegative = validator.validate(.setLineCap(-1), in: context)
        #expect(resultNegative.isValid == false)

        let resultHigh = validator.validate(.setLineCap(3), in: context)
        #expect(resultHigh.isValid == false)
    }

    // MARK: - Line Join Validation Tests

    @Test("Valid line join values pass")
    func validLineJoinPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        for join in 0...2 {
            let result = validator.validate(.setLineJoin(join), in: context)
            #expect(result.isValid == true)
        }
    }

    @Test("Invalid line join value fails")
    func invalidLineJoinFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()

        let resultNegative = validator.validate(.setLineJoin(-1), in: context)
        #expect(resultNegative.isValid == false)

        let resultHigh = validator.validate(.setLineJoin(3), in: context)
        #expect(resultHigh.isValid == false)
    }

    // MARK: - Miter Limit Validation Tests

    @Test("Valid miter limit passes")
    func validMiterLimitPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setMiterLimit(10), in: context)
        #expect(result.isValid == true)
    }

    @Test("Miter limit of 1 passes")
    func miterLimitOnePasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setMiterLimit(1), in: context)
        #expect(result.isValid == true)
    }

    @Test("Miter limit less than 1 fails")
    func miterLimitLessThanOneFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setMiterLimit(0.5), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .invalidMiterLimit = issue { return true }
            return false
        })
    }

    // MARK: - Dash Pattern Validation Tests

    @Test("Valid dash pattern passes")
    func validDashPatternPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setDashPattern(pattern: [3, 2], phase: 0), in: context)
        #expect(result.isValid == true)
    }

    @Test("Empty dash pattern passes")
    func emptyDashPatternPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setDashPattern(pattern: [], phase: 0), in: context)
        #expect(result.isValid == true)  // Solid line
    }

    @Test("Dash pattern with negative value fails")
    func dashPatternNegativeValueFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setDashPattern(pattern: [3, -2], phase: 0), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .invalidDashPattern = issue { return true }
            return false
        })
    }

    @Test("Dash pattern with all zeros fails")
    func dashPatternAllZerosFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setDashPattern(pattern: [0, 0], phase: 0), in: context)
        #expect(result.isValid == false)
    }

    @Test("Dash pattern with negative phase fails")
    func dashPatternNegativePhaseFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setDashPattern(pattern: [3, 2], phase: -1), in: context)
        #expect(result.isValid == false)
    }

    // MARK: - Rendering Intent Validation Tests

    @Test("Valid rendering intents pass")
    func validRenderingIntentsPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()

        let intents = ["AbsoluteColorimetric", "RelativeColorimetric", "Saturation", "Perceptual"]
        for intent in intents {
            let result = validator.validate(.setRenderingIntent(ASAtom(intent)), in: context)
            #expect(result.isValid == true)
        }
    }

    @Test("Invalid rendering intent fails")
    func invalidRenderingIntentFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setRenderingIntent(ASAtom("InvalidIntent")), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .invalidRenderingIntent = issue { return true }
            return false
        })
    }

    // MARK: - Flatness Validation Tests

    @Test("Valid flatness passes")
    func validFlatnessPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()

        let result0 = validator.validate(.setFlatness(0), in: context)
        #expect(result0.isValid == true)

        let result50 = validator.validate(.setFlatness(50), in: context)
        #expect(result50.isValid == true)

        let result100 = validator.validate(.setFlatness(100), in: context)
        #expect(result100.isValid == true)
    }

    @Test("Flatness out of range fails")
    func flatnessOutOfRangeFails() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()

        let resultNegative = validator.validate(.setFlatness(-1), in: context)
        #expect(resultNegative.isValid == false)

        let resultHigh = validator.validate(.setFlatness(101), in: context)
        #expect(resultHigh.isValid == false)
    }

    // MARK: - ExtGState Validation Tests

    @Test("Known ExtGState passes")
    func knownExtGStatePasses() {
        let validator = GraphicsStateValidator(
            knownExtGStates: ["GS1", "GS2"]
        )
        let context = OperatorValidationContext()
        let result = validator.validate(.setExtGState(ASAtom("GS1")), in: context)
        #expect(result.isValid == true)
    }

    @Test("Unknown ExtGState fails when tracking")
    func unknownExtGStateFails() {
        let validator = GraphicsStateValidator(
            knownExtGStates: ["GS1", "GS2"]
        )
        let context = OperatorValidationContext()
        let result = validator.validate(.setExtGState(ASAtom("GS3")), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .undefinedExtGState = issue { return true }
            return false
        })
    }

    @Test("Transparent ExtGState fails when not allowed")
    func transparentExtGStateNotAllowed() {
        let validator = GraphicsStateValidator(
            allowTransparency: false,
            knownExtGStates: ["GS1", "GS2"],
            transparentExtGStates: ["GS2"]
        )
        let context = OperatorValidationContext()
        let result = validator.validate(.setExtGState(ASAtom("GS2")), in: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .transparencyNotAllowed = issue { return true }
            return false
        })
    }

    @Test("ExtGState passes when not tracking")
    func extGStatePassesWhenNotTracking() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validate(.setExtGState(ASAtom("AnyGS")), in: context)
        #expect(result.isValid == true)
    }

    // MARK: - End of Stream Validation Tests

    @Test("Clean end of stream passes")
    func cleanEndOfStreamPasses() {
        let validator = GraphicsStateValidator()
        let context = OperatorValidationContext()
        let result = validator.validateEndOfStream(context: context)
        #expect(result.isValid == true)
    }

    @Test("Unmatched q detected at end of stream")
    func unmatchedQAtEndOfStream() {
        let validator = GraphicsStateValidator()
        var context = OperatorValidationContext()
        context.pushGraphicsState()
        context.pushGraphicsState()
        let result = validator.validateEndOfStream(context: context)
        #expect(result.isValid == false)
        #expect(result.issues.contains { issue in
            if case .unmatchedSaveState(let count) = issue {
                return count == 2
            }
            return false
        })
    }

    // MARK: - Utility Methods Tests

    @Test("Is identity matrix")
    func isIdentityMatrix() {
        let validator = GraphicsStateValidator()
        #expect(validator.isIdentityMatrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0) == true)
        #expect(validator.isIdentityMatrix(a: 2, b: 0, c: 0, d: 1, e: 0, f: 0) == false)
        #expect(validator.isIdentityMatrix(a: 1, b: 0, c: 0, d: 1, e: 100, f: 0) == false)
    }

    @Test("Matrix determinant calculation")
    func matrixDeterminant() {
        let validator = GraphicsStateValidator()
        #expect(validator.matrixDeterminant(a: 1, b: 0, c: 0, d: 1) == 1)
        #expect(validator.matrixDeterminant(a: 2, b: 0, c: 0, d: 2) == 4)
        #expect(validator.matrixDeterminant(a: 1, b: 2, c: 3, d: 4) == -2)
        #expect(validator.matrixDeterminant(a: 0, b: 0, c: 0, d: 0) == 0)
    }

    // MARK: - Line Style Enum Tests

    @Test("LineCapStyle values")
    func lineCapStyleValues() {
        #expect(LineCapStyle.butt.rawValue == 0)
        #expect(LineCapStyle.round.rawValue == 1)
        #expect(LineCapStyle.projectingSquare.rawValue == 2)
        #expect(LineCapStyle.allCases.count == 3)
    }

    @Test("LineJoinStyle values")
    func lineJoinStyleValues() {
        #expect(LineJoinStyle.miter.rawValue == 0)
        #expect(LineJoinStyle.round.rawValue == 1)
        #expect(LineJoinStyle.bevel.rawValue == 2)
        #expect(LineJoinStyle.allCases.count == 3)
    }

    // MARK: - RenderingIntent Tests

    @Test("RenderingIntent from ASAtom")
    func renderingIntentFromAtom() {
        #expect(RenderingIntent(from: ASAtom("AbsoluteColorimetric")) == .absoluteColorimetric)
        #expect(RenderingIntent(from: ASAtom("RelativeColorimetric")) == .relativeColorimetric)
        #expect(RenderingIntent(from: ASAtom("Saturation")) == .saturation)
        #expect(RenderingIntent(from: ASAtom("Perceptual")) == .perceptual)
        #expect(RenderingIntent(from: ASAtom("Invalid")) == nil)
    }

    // MARK: - GraphicsStateValidationIssue Tests

    @Test("Issue descriptions are meaningful")
    func issueDescriptions() {
        #expect(GraphicsStateValidationIssue.graphicsStateStackUnderflow.description.contains("underflow"))
        #expect(GraphicsStateValidationIssue.singularMatrix.description.contains("Singular"))
        #expect(GraphicsStateValidationIssue.invalidLineWidth(width: -1).description.contains("-1"))
    }

    @Test("Issue severity")
    func issueSeverity() {
        #expect(GraphicsStateValidationIssue.graphicsStateStackUnderflow.severity == .error)
        #expect(GraphicsStateValidationIssue.singularMatrix.severity == .error)
        #expect(GraphicsStateValidationIssue.invalidLineWidth(width: -1).severity == .warning)
    }

    // MARK: - PDF/A Graphics State Validator Tests

    @Test("PDFAGraphicsStateValidator for PDF/A-1")
    func pdfaGraphicsStateValidatorPDFA1() {
        let validator = PDFAGraphicsStateValidator(
            conformanceLevel: .pdfa1a,
            transparentExtGStates: ["GS1"]
        )
        var context = OperatorValidationContext()
        context.pushGraphicsState()  // Need to have something on stack

        let result = validator.validate(.setExtGState(ASAtom("GS1")), in: context)
        #expect(result.isValid == false)  // Transparency not allowed in PDF/A-1
    }

    @Test("PDFAGraphicsStateValidator for PDF/A-2")
    func pdfaGraphicsStateValidatorPDFA2() {
        let validator = PDFAGraphicsStateValidator(conformanceLevel: .pdfa2a)
        let context = OperatorValidationContext()
        let result = validator.validate(.saveGraphicsState, in: context)
        #expect(result.isValid == true)
    }

    // MARK: - PDFAGraphicsStateConformance Tests

    @Test("PDFAGraphicsStateConformance transparency rules")
    func pdfaGraphicsStateConformanceTransparency() {
        #expect(PDFAGraphicsStateConformance.pdfa1a.allowsTransparency == false)
        #expect(PDFAGraphicsStateConformance.pdfa1b.allowsTransparency == false)
        #expect(PDFAGraphicsStateConformance.pdfa2a.allowsTransparency == true)
        #expect(PDFAGraphicsStateConformance.pdfa2b.allowsTransparency == true)
        #expect(PDFAGraphicsStateConformance.pdfa4.allowsTransparency == true)
    }

    @Test("PDFAGraphicsStateConformance max stack depth")
    func pdfaGraphicsStateConformanceStackDepth() {
        for level in PDFAGraphicsStateConformance.allCases {
            #expect(level.maxStackDepth == 28)
        }
    }

    // MARK: - ExtGStateParameter Tests

    @Test("ExtGStateParameter transparency classification")
    func extGStateParameterTransparency() {
        #expect(ExtGStateParameter.strokeAlpha.isTransparencyParameter == true)
        #expect(ExtGStateParameter.fillAlpha.isTransparencyParameter == true)
        #expect(ExtGStateParameter.blendMode.isTransparencyParameter == true)
        #expect(ExtGStateParameter.softMask.isTransparencyParameter == true)
        #expect(ExtGStateParameter.lineWidth.isTransparencyParameter == false)
        #expect(ExtGStateParameter.lineCap.isTransparencyParameter == false)
    }

    @Test("ExtGStateParameter all cases")
    func extGStateParameterAllCases() {
        #expect(ExtGStateParameter.allCases.count >= 20)
    }
}
