import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarParser

/// Tests for OperatorValidationContext.
@Suite("OperatorValidationContext Tests")
struct OperatorValidationContextTests {

    // MARK: - Initialization Tests

    @Test("Default context has initial state")
    func defaultContextState() {
        let context = OperatorValidationContext()
        #expect(context.graphicsStateDepth == 1)  // Initial state
        #expect(context.inTextObject == false)
        #expect(context.textObjectDepth == 0)
        #expect(context.markedContentDepth == 0)
        #expect(context.inInlineImage == false)
        #expect(context.inCompatibilitySection == false)
        #expect(context.hasCurrentPath == false)
        #expect(context.operatorCount == 0)
        #expect(context.hasIssues == false)
    }

    // MARK: - Graphics State Stack Tests

    @Test("Push graphics state increases depth")
    func pushGraphicsState() {
        var context = OperatorValidationContext()
        context.pushGraphicsState()
        #expect(context.graphicsStateDepth == 2)
        context.pushGraphicsState()
        #expect(context.graphicsStateDepth == 3)
    }

    @Test("Pop graphics state decreases depth")
    func popGraphicsState() {
        var context = OperatorValidationContext()
        context.pushGraphicsState()
        context.pushGraphicsState()
        #expect(context.graphicsStateDepth == 3)

        let success = context.popGraphicsState()
        #expect(success == true)
        #expect(context.graphicsStateDepth == 2)
    }

    @Test("Pop graphics state prevents underflow")
    func popGraphicsStateUnderflow() {
        var context = OperatorValidationContext()
        let success = context.popGraphicsState()
        #expect(success == false)
        #expect(context.graphicsStateDepth == 1)  // Still has initial state
        #expect(context.hasIssues == true)
    }

    @Test("Reset graphics state stack")
    func resetGraphicsStateStack() {
        var context = OperatorValidationContext()
        context.pushGraphicsState()
        context.pushGraphicsState()
        context.resetGraphicsStateStack()
        #expect(context.graphicsStateDepth == 1)
    }

    @Test("Current graphics state tracks color")
    func graphicsStateTracksColor() {
        var context = OperatorValidationContext()
        context.currentGraphicsState.strokeColorSpace = ASAtom("DeviceRGB")
        context.currentGraphicsState.strokeColor = [1, 0, 0]

        #expect(context.currentGraphicsState.strokeColorSpace == ASAtom("DeviceRGB"))
        #expect(context.currentGraphicsState.strokeColor == [1, 0, 0])
    }

    @Test("Pushed state preserves values")
    func pushedStatePreservesValues() {
        var context = OperatorValidationContext()
        context.currentGraphicsState.lineWidth = 2.5
        context.pushGraphicsState()
        context.currentGraphicsState.lineWidth = 5.0

        _ = context.popGraphicsState()
        #expect(context.currentGraphicsState.lineWidth == 2.5)
    }

    // MARK: - Text Object Tests

    @Test("Begin text object sets state")
    func beginTextObject() {
        var context = OperatorValidationContext()
        let success = context.beginTextObject()
        #expect(success == true)
        #expect(context.inTextObject == true)
        #expect(context.textObjectDepth == 1)
    }

    @Test("End text object clears state")
    func endTextObject() {
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        let success = context.endTextObject()
        #expect(success == true)
        #expect(context.inTextObject == false)
    }

    @Test("Nested text object fails")
    func nestedTextObject() {
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        let success = context.beginTextObject()
        #expect(success == false)
        #expect(context.hasIssues == true)
    }

    @Test("End text without begin fails")
    func endTextWithoutBegin() {
        var context = OperatorValidationContext()
        let success = context.endTextObject()
        #expect(success == false)
        #expect(context.hasIssues == true)
    }

    // MARK: - Marked Content Tests

    @Test("Begin marked content pushes tag")
    func beginMarkedContent() {
        var context = OperatorValidationContext()
        context.beginMarkedContent(tag: ASAtom("Span"))
        #expect(context.markedContentDepth == 1)
    }

    @Test("End marked content pops tag")
    func endMarkedContent() {
        var context = OperatorValidationContext()
        context.beginMarkedContent(tag: ASAtom("Span"))
        let tag = context.endMarkedContent()
        #expect(tag == ASAtom("Span"))
        #expect(context.markedContentDepth == 0)
    }

    @Test("Nested marked content tracks depth")
    func nestedMarkedContent() {
        var context = OperatorValidationContext()
        context.beginMarkedContent(tag: ASAtom("P"))
        context.beginMarkedContent(tag: ASAtom("Span"))
        #expect(context.markedContentDepth == 2)

        _ = context.endMarkedContent()
        #expect(context.markedContentDepth == 1)
    }

    @Test("End marked content without begin returns nil")
    func endMarkedContentWithoutBegin() {
        var context = OperatorValidationContext()
        let tag = context.endMarkedContent()
        #expect(tag == nil)
        #expect(context.hasIssues == true)
    }

    // MARK: - Inline Image Tests

    @Test("Begin inline image sets state")
    func beginInlineImage() {
        var context = OperatorValidationContext()
        context.beginInlineImage()
        #expect(context.inInlineImage == true)
    }

    @Test("End inline image clears state")
    func endInlineImage() {
        var context = OperatorValidationContext()
        context.beginInlineImage()
        context.endInlineImage()
        #expect(context.inInlineImage == false)
    }

    @Test("Nested inline image adds issue")
    func nestedInlineImage() {
        var context = OperatorValidationContext()
        context.beginInlineImage()
        context.beginInlineImage()
        #expect(context.hasIssues == true)
    }

    // MARK: - Compatibility Section Tests

    @Test("Begin compatibility section sets state")
    func beginCompatibilitySection() {
        var context = OperatorValidationContext()
        context.beginCompatibilitySection()
        #expect(context.inCompatibilitySection == true)
        #expect(context.compatibilityDepth == 1)
    }

    @Test("End compatibility section clears state")
    func endCompatibilitySection() {
        var context = OperatorValidationContext()
        context.beginCompatibilitySection()
        context.endCompatibilitySection()
        #expect(context.inCompatibilitySection == false)
        #expect(context.compatibilityDepth == 0)
    }

    @Test("Nested compatibility sections track depth")
    func nestedCompatibilitySections() {
        var context = OperatorValidationContext()
        context.beginCompatibilitySection()
        context.beginCompatibilitySection()
        #expect(context.compatibilityDepth == 2)
        #expect(context.inCompatibilitySection == true)
    }

    // MARK: - Path Tests

    @Test("Begin path sets state")
    func beginPath() {
        var context = OperatorValidationContext()
        context.beginPath()
        #expect(context.hasCurrentPath == true)
    }

    @Test("End path clears state")
    func endPath() {
        var context = OperatorValidationContext()
        context.beginPath()
        context.endPath()
        #expect(context.hasCurrentPath == false)
    }

    @Test("Clip path sets clipped flag")
    func clipPath() {
        var context = OperatorValidationContext()
        context.beginPath()
        context.clipPath()
        #expect(context.pathClipped == true)
    }

    // MARK: - Process Operator Tests

    @Test("Process operator updates count")
    func processOperatorUpdatesCount() {
        var context = OperatorValidationContext()
        _ = context.process(.beginText)
        #expect(context.operatorCount == 1)
        _ = context.process(.endText)
        #expect(context.operatorCount == 2)
    }

    @Test("Process q pushes state")
    func processQOperator() {
        var context = OperatorValidationContext()
        _ = context.process(.saveGraphicsState)
        #expect(context.graphicsStateDepth == 2)
    }

    @Test("Process Q pops state")
    func processUpperQOperator() {
        var context = OperatorValidationContext()
        _ = context.process(.saveGraphicsState)
        _ = context.process(.restoreGraphicsState)
        #expect(context.graphicsStateDepth == 1)
    }

    @Test("Process BT begins text object")
    func processBTOperator() {
        var context = OperatorValidationContext()
        _ = context.process(.beginText)
        #expect(context.inTextObject == true)
    }

    @Test("Process color operators updates state")
    func processColorOperators() {
        var context = OperatorValidationContext()
        _ = context.process(.setGrayFill(0.5))
        #expect(context.currentGraphicsState.fillColorSpace == ASAtom("DeviceGray"))
        #expect(context.currentGraphicsState.fillColor == [0.5])

        _ = context.process(.setRGBStroke(r: 1, g: 0, b: 0))
        #expect(context.currentGraphicsState.strokeColorSpace == ASAtom("DeviceRGB"))
        #expect(context.currentGraphicsState.strokeColor == [1, 0, 0])
    }

    @Test("Process Tf sets font")
    func processTfOperator() {
        var context = OperatorValidationContext()
        _ = context.process(.setFont(name: ASAtom("Helvetica"), size: 12))
        #expect(context.textState.fontName == ASAtom("Helvetica"))
        #expect(context.textState.fontSize == 12)
    }

    @Test("Process text showing checks context")
    func processTextShowingOperator() {
        var context = OperatorValidationContext()
        // Without BT and Tf, should add issues
        let issues = context.process(.showText(Data("Hello".utf8)))
        #expect(issues.count >= 2)  // Outside text object and no font
    }

    @Test("Process moveTo starts path")
    func processMoveToOperator() {
        var context = OperatorValidationContext()
        _ = context.process(.moveTo(x: 0, y: 0))
        #expect(context.hasCurrentPath == true)
    }

    @Test("Process stroke ends path")
    func processStrokeOperator() {
        var context = OperatorValidationContext()
        _ = context.process(.moveTo(x: 0, y: 0))
        _ = context.process(.stroke)
        #expect(context.hasCurrentPath == false)
    }

    // MARK: - End of Stream Validation Tests

    @Test("Validate end of stream detects unclosed graphics state")
    func validateEndOfStreamGraphicsState() {
        var context = OperatorValidationContext()
        context.pushGraphicsState()
        let issues = context.validateEndOfStream()
        #expect(issues.contains { $0 == .unmatchedSaveState(depth: 1) })
    }

    @Test("Validate end of stream detects unclosed text object")
    func validateEndOfStreamTextObject() {
        var context = OperatorValidationContext()
        _ = context.beginTextObject()
        let issues = context.validateEndOfStream()
        #expect(issues.contains { $0 == .unclosedTextObject })
    }

    @Test("Validate end of stream detects unclosed marked content")
    func validateEndOfStreamMarkedContent() {
        var context = OperatorValidationContext()
        context.beginMarkedContent(tag: ASAtom("Span"))
        let issues = context.validateEndOfStream()
        #expect(issues.contains { issue in
            if case .unclosedMarkedContent(let tag) = issue {
                return tag == ASAtom("Span")
            }
            return false
        })
    }

    @Test("Clean end of stream has no issues")
    func cleanEndOfStream() {
        var context = OperatorValidationContext()
        _ = context.process(.saveGraphicsState)
        _ = context.process(.beginText)
        _ = context.process(.endText)
        _ = context.process(.restoreGraphicsState)
        let issues = context.validateEndOfStream()
        #expect(issues.isEmpty)
    }

    // MARK: - Issue Management Tests

    @Test("Clear issues removes all issues")
    func clearIssues() {
        var context = OperatorValidationContext()
        _ = context.popGraphicsState()  // Creates an issue
        #expect(context.hasIssues == true)
        context.clearIssues()
        #expect(context.hasIssues == false)
    }

    @Test("All issues returns accumulated issues")
    func allIssues() {
        var context = OperatorValidationContext()
        _ = context.popGraphicsState()
        _ = context.endTextObject()
        #expect(context.allIssues.count == 2)
    }

    // MARK: - Graphics State Snapshot Tests

    @Test("Default graphics state snapshot has PDF defaults")
    func defaultGraphicsStateSnapshot() {
        let state = GraphicsStateSnapshot()
        #expect(state.strokeColorSpace == ASAtom("DeviceGray"))
        #expect(state.fillColorSpace == ASAtom("DeviceGray"))
        #expect(state.lineWidth == 1.0)
        #expect(state.lineCap == 0)
        #expect(state.lineJoin == 0)
        #expect(state.miterLimit == 10.0)
        #expect(state.ctm.a == 1.0)
        #expect(state.ctm.d == 1.0)
    }

    @Test("Graphics state snapshot equality")
    func graphicsStateSnapshotEquality() {
        let state1 = GraphicsStateSnapshot()
        let state2 = GraphicsStateSnapshot()
        #expect(state1 == state2)

        var state3 = GraphicsStateSnapshot()
        state3.lineWidth = 2.0
        #expect(state1 != state3)
    }

    // MARK: - Text State Snapshot Tests

    @Test("Default text state snapshot has correct defaults")
    func defaultTextStateSnapshot() {
        let state = TextStateSnapshot()
        #expect(state.fontName == nil)
        #expect(state.fontSize == 0)
        #expect(state.characterSpacing == 0)
        #expect(state.wordSpacing == 0)
        #expect(state.horizontalScaling == 100)
        #expect(state.renderingMode == 0)
        #expect(state.hasFontSelected == false)
    }

    @Test("Text state hasFontSelected checks both name and size")
    func textStateHasFontSelected() {
        var state = TextStateSnapshot()
        state.fontName = ASAtom("Helvetica")
        #expect(state.hasFontSelected == false)  // Size is 0

        state.fontSize = 12
        #expect(state.hasFontSelected == true)
    }

    // MARK: - Operator Validation Issue Tests

    @Test("Issue descriptions are meaningful")
    func issueDescriptions() {
        #expect(OperatorValidationIssue.graphicsStateStackUnderflow.description.contains("underflow"))
        #expect(OperatorValidationIssue.nestedTextObject.description.contains("Nested"))
        #expect(OperatorValidationIssue.noFontSelected.description.contains("font"))
    }

    @Test("Issue severity is appropriate")
    func issueSeverity() {
        #expect(OperatorValidationIssue.graphicsStateStackUnderflow.severity == .error)
        #expect(OperatorValidationIssue.noFontSelected.severity == .error)
        #expect(OperatorValidationIssue.unclosedMarkedContent(tag: ASAtom("P")).severity == .warning)
    }
}
