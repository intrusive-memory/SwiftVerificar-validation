import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - ValidatedContentStream Tests

@Suite("ValidatedContentStream")
struct ValidatedContentStreamTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let cs = ValidatedContentStream()
        #expect(cs.pageNumber == 1)
        #expect(cs.streamIndex == 0)
        #expect(cs.operators.isEmpty)
        #expect(cs.isFormXObject == false)
        #expect(cs.formXObjectName == nil)
        #expect(cs.contentLength == 0)
        #expect(cs.cosDictionary == nil)
        #expect(cs.objectKey == nil)
    }

    @Test("Full initialization")
    func fullInit() {
        let dict: COSValue = .dictionary([ASAtom("Length"): .integer(1024)])
        let key = COSObjectKey(objectNumber: 20)
        let ops: [ValidatedOperator] = [.beginText, .setFont(name: ASAtom("F1"), size: 12), .showText(Data("Hello".utf8)), .endText]

        let cs = ValidatedContentStream(
            cosDictionary: dict,
            objectKey: key,
            pageNumber: 3,
            streamIndex: 1,
            operators: ops,
            isFormXObject: true,
            formXObjectName: ASAtom("Form1"),
            contentLength: 1024
        )

        #expect(cs.cosDictionary != nil)
        #expect(cs.objectKey == key)
        #expect(cs.pageNumber == 3)
        #expect(cs.streamIndex == 1)
        #expect(cs.operators.count == 4)
        #expect(cs.isFormXObject == true)
        #expect(cs.formXObjectName == ASAtom("Form1"))
        #expect(cs.contentLength == 1024)
    }

    // MARK: - PDFObject Conformance Tests

    @Test("Object type is PDContentStream")
    func objectType() {
        let cs = ValidatedContentStream()
        #expect(cs.objectType == "PDContentStream")
    }

    @Test("Property names include all expected properties")
    func propertyNames() {
        let cs = ValidatedContentStream()
        let names = cs.propertyNames
        #expect(names.contains("pageNumber"))
        #expect(names.contains("streamIndex"))
        #expect(names.contains("operatorCount"))
        #expect(names.contains("isFormXObject"))
        #expect(names.contains("contentLength"))
        #expect(names.contains("hasMarkedContent"))
        #expect(names.contains("hasTextContent"))
        #expect(names.contains("isGraphicsStateBalanced"))
        #expect(names.contains("maxGraphicsStateDepth"))
    }

    // MARK: - Property Access Tests

    @Test("Property access - pageNumber")
    func propertyPageNumber() {
        let cs = ValidatedContentStream(pageNumber: 5)
        #expect(cs.property(named: "pageNumber")?.integerValue == 5)
    }

    @Test("Property access - streamIndex")
    func propertyStreamIndex() {
        let cs = ValidatedContentStream(streamIndex: 2)
        #expect(cs.property(named: "streamIndex")?.integerValue == 2)
    }

    @Test("Property access - operatorCount")
    func propertyOperatorCount() {
        let ops: [ValidatedOperator] = [.beginText, .endText]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.property(named: "operatorCount")?.integerValue == 2)
    }

    @Test("Property access - isFormXObject")
    func propertyIsFormXObject() {
        let cs = ValidatedContentStream(isFormXObject: true)
        #expect(cs.property(named: "isFormXObject")?.boolValue == true)
    }

    @Test("Property access - formXObjectName present")
    func propertyFormXObjectNamePresent() {
        let cs = ValidatedContentStream(isFormXObject: true, formXObjectName: ASAtom("XF1"))
        let value = cs.property(named: "formXObjectName")
        #expect(value?.stringValue == "XF1")
    }

    @Test("Property access - formXObjectName absent")
    func propertyFormXObjectNameAbsent() {
        let cs = ValidatedContentStream()
        #expect(cs.property(named: "formXObjectName")?.isNull == true)
    }

    @Test("Property access - contentLength")
    func propertyContentLength() {
        let cs = ValidatedContentStream(contentLength: 2048)
        #expect(cs.property(named: "contentLength")?.integerValue == 2048)
    }

    @Test("Property access - hasMarkedContent")
    func propertyHasMarkedContent() {
        let csWithMC = ValidatedContentStream(operators: [.beginMarkedContent(ASAtom("Span")), .endMarkedContent])
        #expect(csWithMC.property(named: "hasMarkedContent")?.boolValue == true)

        let csWithoutMC = ValidatedContentStream(operators: [.beginText, .endText])
        #expect(csWithoutMC.property(named: "hasMarkedContent")?.boolValue == false)
    }

    @Test("Property access - hasTextContent")
    func propertyHasTextContent() {
        let csWithText = ValidatedContentStream(operators: [.beginText, .showText(Data("Hi".utf8)), .endText])
        #expect(csWithText.property(named: "hasTextContent")?.boolValue == true)

        let csNoText = ValidatedContentStream(operators: [.saveGraphicsState, .restoreGraphicsState])
        #expect(csNoText.property(named: "hasTextContent")?.boolValue == false)
    }

    @Test("Property access - unknown property returns nil")
    func propertyUnknown() {
        let cs = ValidatedContentStream()
        #expect(cs.property(named: "nonExistent") == nil)
    }

    // MARK: - Operator Count Tests

    @Test("operatorCount")
    func operatorCount() {
        let ops: [ValidatedOperator] = [
            .saveGraphicsState, .beginText, .setFont(name: ASAtom("F1"), size: 12),
            .showText(Data("Test".utf8)), .endText, .restoreGraphicsState
        ]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.operatorCount == 6)
    }

    @Test("textOperatorCount")
    func textOperatorCount() {
        let ops: [ValidatedOperator] = [
            .beginText, .setFont(name: ASAtom("F1"), size: 12),
            .setCharacterSpacing(0.5),
            .showText(Data("Hello".utf8)), .endText,
            .saveGraphicsState, .restoreGraphicsState
        ]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.textOperatorCount == 5) // BT, Tf, Tc, Tj, ET
    }

    @Test("graphicsStateOperatorCount")
    func graphicsStateOperatorCount() {
        let ops: [ValidatedOperator] = [
            .saveGraphicsState, .setLineWidth(2.0), .setLineCap(1),
            .restoreGraphicsState
        ]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.graphicsStateOperatorCount == 4)
    }

    @Test("pathOperatorCount")
    func pathOperatorCount() {
        let ops: [ValidatedOperator] = [
            .moveTo(x: 0, y: 0), .lineTo(x: 100, y: 0),
            .lineTo(x: 100, y: 100), .closePath, .stroke
        ]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.pathOperatorCount == 5)
    }

    @Test("colorOperatorCount")
    func colorOperatorCount() {
        let ops: [ValidatedOperator] = [
            .setGrayFill(0.5), .setGrayStroke(0.0),
            .setRGBFill(r: 1, g: 0, b: 0)
        ]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.colorOperatorCount == 3)
    }

    @Test("markedContentOperatorCount")
    func markedContentOperatorCount() {
        let ops: [ValidatedOperator] = [
            .beginMarkedContent(ASAtom("Span")),
            .beginText, .endText,
            .endMarkedContent,
            .markedContentPoint(ASAtom("Artifact"))
        ]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.markedContentOperatorCount == 3)
    }

    // MARK: - Marked Content Analysis Tests

    @Test("hasMarkedContent is true when MC operators present")
    func hasMarkedContentTrue() {
        let cs = ValidatedContentStream(operators: [
            .beginMarkedContent(ASAtom("P")), .endMarkedContent
        ])
        #expect(cs.hasMarkedContent == true)
    }

    @Test("hasMarkedContent is false when no MC operators")
    func hasMarkedContentFalse() {
        let cs = ValidatedContentStream(operators: [.beginText, .endText])
        #expect(cs.hasMarkedContent == false)
    }

    @Test("beginMarkedContentCount with BMC and BDC")
    func beginMarkedContentCount() {
        let props: COSValue = .dictionary([ASAtom("MCID"): .integer(0)])
        let cs = ValidatedContentStream(operators: [
            .beginMarkedContent(ASAtom("Span")),
            .endMarkedContent,
            .beginMarkedContentWithProperties(tag: ASAtom("P"), properties: props),
            .endMarkedContent
        ])
        #expect(cs.beginMarkedContentCount == 2)
    }

    @Test("endMarkedContentCount")
    func endMarkedContentCount() {
        let cs = ValidatedContentStream(operators: [
            .beginMarkedContent(ASAtom("Span")),
            .endMarkedContent,
            .beginMarkedContent(ASAtom("P")),
            .endMarkedContent
        ])
        #expect(cs.endMarkedContentCount == 2)
    }

    @Test("isMarkedContentBalanced when balanced")
    func markedContentBalanced() {
        let cs = ValidatedContentStream(operators: [
            .beginMarkedContent(ASAtom("Span")),
            .beginMarkedContent(ASAtom("P")),
            .endMarkedContent,
            .endMarkedContent
        ])
        #expect(cs.isMarkedContentBalanced == true)
    }

    @Test("isMarkedContentBalanced when unbalanced")
    func markedContentUnbalanced() {
        let cs = ValidatedContentStream(operators: [
            .beginMarkedContent(ASAtom("Span")),
            .beginMarkedContent(ASAtom("P")),
            .endMarkedContent
        ])
        #expect(cs.isMarkedContentBalanced == false)
    }

    // MARK: - Text Analysis Tests

    @Test("hasTextContent true")
    func hasTextContentTrue() {
        let cs = ValidatedContentStream(operators: [
            .beginText, .showText(Data("Hi".utf8)), .endText
        ])
        #expect(cs.hasTextContent == true)
    }

    @Test("hasTextContent false")
    func hasTextContentFalse() {
        let cs = ValidatedContentStream(operators: [
            .moveTo(x: 0, y: 0), .lineTo(x: 100, y: 100), .stroke
        ])
        #expect(cs.hasTextContent == false)
    }

    @Test("isTextObjectBalanced when balanced")
    func textObjectBalanced() {
        let cs = ValidatedContentStream(operators: [
            .beginText, .endText, .beginText, .endText
        ])
        #expect(cs.isTextObjectBalanced == true)
    }

    @Test("isTextObjectBalanced when unbalanced")
    func textObjectUnbalanced() {
        let cs = ValidatedContentStream(operators: [
            .beginText, .beginText, .endText
        ])
        #expect(cs.isTextObjectBalanced == false)
    }

    // MARK: - Graphics State Analysis Tests

    @Test("isGraphicsStateBalanced when balanced")
    func graphicsStateBalanced() {
        let cs = ValidatedContentStream(operators: [
            .saveGraphicsState, .saveGraphicsState,
            .restoreGraphicsState, .restoreGraphicsState
        ])
        #expect(cs.isGraphicsStateBalanced == true)
    }

    @Test("isGraphicsStateBalanced when unbalanced")
    func graphicsStateUnbalanced() {
        let cs = ValidatedContentStream(operators: [
            .saveGraphicsState, .saveGraphicsState, .restoreGraphicsState
        ])
        #expect(cs.isGraphicsStateBalanced == false)
    }

    @Test("maxGraphicsStateDepth")
    func maxGraphicsStateDepth() {
        let cs = ValidatedContentStream(operators: [
            .saveGraphicsState,
            .saveGraphicsState,
            .saveGraphicsState,
            .restoreGraphicsState,
            .restoreGraphicsState,
            .restoreGraphicsState
        ])
        #expect(cs.maxGraphicsStateDepth == 3)
    }

    @Test("maxGraphicsStateDepth with no state operations")
    func maxGraphicsStateDepthZero() {
        let cs = ValidatedContentStream(operators: [.beginText, .endText])
        #expect(cs.maxGraphicsStateDepth == 0)
    }

    @Test("maxGraphicsStateDepth handles unbalanced gracefully")
    func maxGraphicsStateDepthUnbalanced() {
        let cs = ValidatedContentStream(operators: [
            .saveGraphicsState,
            .saveGraphicsState,
            .restoreGraphicsState,
            .restoreGraphicsState,
            .restoreGraphicsState // Extra restore - should not go below 0
        ])
        #expect(cs.maxGraphicsStateDepth == 2)
    }

    // MARK: - Operator Access Tests

    @Test("operators in category")
    func operatorsInCategory() {
        let ops: [ValidatedOperator] = [
            .beginText, .setFont(name: ASAtom("F1"), size: 12),
            .showText(Data("Hello".utf8)), .endText,
            .moveTo(x: 0, y: 0), .stroke
        ]
        let cs = ValidatedContentStream(operators: ops)

        let textOps = cs.operators(inCategory: .textObject)
        #expect(textOps.count == 2) // BT, ET

        let pathOps = cs.operators(inCategory: .pathPainting)
        #expect(pathOps.count == 1) // S

        let colorOps = cs.operators(inCategory: .color)
        #expect(colorOps.isEmpty)
    }

    @Test("operatorAt valid index")
    func operatorAtValidIndex() {
        let ops: [ValidatedOperator] = [.beginText, .endText]
        let cs = ValidatedContentStream(operators: ops)
        let op = cs.operatorAt(0)
        #expect(op != nil)
        if case .beginText = op {
            // expected
        } else {
            Issue.record("Expected beginText operator")
        }
    }

    @Test("operatorAt invalid index returns nil")
    func operatorAtInvalidIndex() {
        let cs = ValidatedContentStream(operators: [.beginText])
        #expect(cs.operatorAt(5) == nil)
        #expect(cs.operatorAt(-1) == nil)
    }

    // MARK: - Summary Tests

    @Test("Summary for page content stream")
    func summaryPageStream() {
        let cs = ValidatedContentStream(
            pageNumber: 3,
            streamIndex: 0,
            operators: [.beginText, .showText(Data("Hi".utf8)), .endText, .beginMarkedContent(ASAtom("P")), .endMarkedContent]
        )
        let summary = cs.summary
        #expect(summary.contains("Page 3"))
        #expect(summary.contains("5 ops"))
        #expect(summary.contains("text"))
        #expect(summary.contains("marked"))
    }

    @Test("Summary for form XObject")
    func summaryFormXObject() {
        let cs = ValidatedContentStream(
            operators: [.moveTo(x: 0, y: 0)],
            isFormXObject: true,
            formXObjectName: ASAtom("XF1")
        )
        let summary = cs.summary
        #expect(summary.contains("Form XObject XF1"))
    }

    @Test("Summary for form XObject without name")
    func summaryFormXObjectNoName() {
        let cs = ValidatedContentStream(
            operators: [],
            isFormXObject: true
        )
        let summary = cs.summary
        #expect(summary.contains("Form XObject"))
    }

    // MARK: - Context Tests

    @Test("Default context uses content stream page")
    func defaultContext() {
        let cs = ValidatedContentStream(pageNumber: 7)
        #expect(cs.validationContext.pageNumber == 7)
        #expect(cs.validationContext.location == "ContentStream")
    }

    @Test("Custom context overrides default")
    func customContext() {
        let ctx = ObjectContext(pageNumber: 10, location: "FormXObject")
        let cs = ValidatedContentStream(context: ctx, pageNumber: 5)
        #expect(cs.validationContext.pageNumber == 10)
        #expect(cs.validationContext.location == "FormXObject")
    }

    // MARK: - Equatable Tests

    @Test("Content streams with same ID are equal")
    func equalById() {
        let id = UUID()
        let cs1 = ValidatedContentStream(id: id, pageNumber: 1)
        let cs2 = ValidatedContentStream(id: id, pageNumber: 2)
        #expect(cs1 == cs2)
    }

    @Test("Content streams with different IDs are not equal")
    func notEqualByDifferentId() {
        let cs1 = ValidatedContentStream(pageNumber: 1)
        let cs2 = ValidatedContentStream(pageNumber: 1)
        #expect(cs1 != cs2)
    }

    // MARK: - Factory Tests

    @Test("Minimal factory")
    func minimalFactory() {
        let cs = ValidatedContentStream.minimal(
            pageNumber: 3,
            operators: [.beginText, .endText]
        )
        #expect(cs.pageNumber == 3)
        #expect(cs.operators.count == 2)
        #expect(cs.isFormXObject == false)
    }

    @Test("Form XObject factory")
    func formXObjectFactory() {
        let cs = ValidatedContentStream.formXObject(
            named: ASAtom("Form1"),
            pageNumber: 2,
            operators: [.moveTo(x: 0, y: 0)]
        )
        #expect(cs.isFormXObject == true)
        #expect(cs.formXObjectName == ASAtom("Form1"))
        #expect(cs.pageNumber == 2)
        #expect(cs.operators.count == 1)
    }

    // MARK: - Sendable Tests

    @Test("ValidatedContentStream is Sendable")
    func isSendable() {
        let cs = ValidatedContentStream.minimal()
        let sendable: any Sendable = cs
        #expect(sendable is ValidatedContentStream)
    }

    // MARK: - Empty Content Stream

    @Test("Empty content stream has zero counts")
    func emptyContentStream() {
        let cs = ValidatedContentStream()
        #expect(cs.operatorCount == 0)
        #expect(cs.textOperatorCount == 0)
        #expect(cs.graphicsStateOperatorCount == 0)
        #expect(cs.pathOperatorCount == 0)
        #expect(cs.colorOperatorCount == 0)
        #expect(cs.markedContentOperatorCount == 0)
        #expect(cs.hasMarkedContent == false)
        #expect(cs.hasTextContent == false)
        #expect(cs.isMarkedContentBalanced == true)
        #expect(cs.isTextObjectBalanced == true)
        #expect(cs.isGraphicsStateBalanced == true)
        #expect(cs.maxGraphicsStateDepth == 0)
    }

    // MARK: - Property Count Tests

    @Test("textOperatorCount property access")
    func textOperatorCountProperty() {
        let ops: [ValidatedOperator] = [.beginText, .showText(Data("Hi".utf8)), .endText]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.property(named: "textOperatorCount")?.integerValue == 3)
    }

    @Test("graphicsStateOperatorCount property access")
    func graphicsStateOperatorCountProperty() {
        let ops: [ValidatedOperator] = [.saveGraphicsState, .restoreGraphicsState]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.property(named: "graphicsStateOperatorCount")?.integerValue == 2)
    }

    @Test("isMarkedContentBalanced property access")
    func isMarkedContentBalancedProperty() {
        let cs = ValidatedContentStream(operators: [
            .beginMarkedContent(ASAtom("P")), .endMarkedContent
        ])
        #expect(cs.property(named: "isMarkedContentBalanced")?.boolValue == true)
    }

    @Test("isTextObjectBalanced property access")
    func isTextObjectBalancedProperty() {
        let cs = ValidatedContentStream(operators: [.beginText, .endText])
        #expect(cs.property(named: "isTextObjectBalanced")?.boolValue == true)
    }

    @Test("maxGraphicsStateDepth property access")
    func maxGraphicsStateDepthProperty() {
        let ops: [ValidatedOperator] = [
            .saveGraphicsState, .saveGraphicsState, .restoreGraphicsState, .restoreGraphicsState
        ]
        let cs = ValidatedContentStream(operators: ops)
        #expect(cs.property(named: "maxGraphicsStateDepth")?.integerValue == 2)
    }
}
