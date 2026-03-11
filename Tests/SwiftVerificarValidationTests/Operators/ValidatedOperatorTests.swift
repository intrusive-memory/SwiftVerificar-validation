import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarParser

/// Tests for ValidatedOperator enum.
@Suite("ValidatedOperator Tests")
struct ValidatedOperatorTests {

    // MARK: - Operator Name Tests

    @Test("Color operator names are correct")
    func colorOperatorNames() {
        #expect(ValidatedOperator.setGrayStroke(0.5).operatorName == "G")
        #expect(ValidatedOperator.setGrayFill(0.5).operatorName == "g")
        #expect(ValidatedOperator.setRGBStroke(r: 1, g: 0, b: 0).operatorName == "RG")
        #expect(ValidatedOperator.setRGBFill(r: 1, g: 0, b: 0).operatorName == "rg")
        #expect(ValidatedOperator.setCMYKStroke(c: 0, m: 1, y: 1, k: 0).operatorName == "K")
        #expect(ValidatedOperator.setCMYKFill(c: 0, m: 1, y: 1, k: 0).operatorName == "k")
        #expect(ValidatedOperator.setColorSpaceStroke(ASAtom("DeviceRGB")).operatorName == "CS")
        #expect(ValidatedOperator.setColorSpaceFill(ASAtom("DeviceRGB")).operatorName == "cs")
        #expect(ValidatedOperator.setColorStroke([1, 0, 0]).operatorName == "SC")
        #expect(ValidatedOperator.setColorFill([1, 0, 0]).operatorName == "sc")
        #expect(ValidatedOperator.setColorStrokeN(components: [1], pattern: nil).operatorName == "SCN")
        #expect(ValidatedOperator.setColorFillN(components: [1], pattern: nil).operatorName == "scn")
    }

    @Test("Text operator names are correct")
    func textOperatorNames() {
        #expect(ValidatedOperator.beginText.operatorName == "BT")
        #expect(ValidatedOperator.endText.operatorName == "ET")
        #expect(ValidatedOperator.setFont(name: ASAtom("F1"), size: 12).operatorName == "Tf")
        #expect(ValidatedOperator.setCharacterSpacing(0.5).operatorName == "Tc")
        #expect(ValidatedOperator.setWordSpacing(0.5).operatorName == "Tw")
        #expect(ValidatedOperator.setHorizontalScaling(100).operatorName == "Tz")
        #expect(ValidatedOperator.setTextLeading(12).operatorName == "TL")
        #expect(ValidatedOperator.setTextRenderingMode(0).operatorName == "Tr")
        #expect(ValidatedOperator.setTextRise(0).operatorName == "Ts")
        #expect(ValidatedOperator.setTextMatrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0).operatorName == "Tm")
        #expect(ValidatedOperator.moveTextPosition(tx: 100, ty: 0).operatorName == "Td")
        #expect(ValidatedOperator.moveTextPositionLeading(tx: 0, ty: -12).operatorName == "TD")
        #expect(ValidatedOperator.moveToNextLine.operatorName == "T*")
        #expect(ValidatedOperator.showText(Data("Hello".utf8)).operatorName == "Tj")
        #expect(ValidatedOperator.showTextArray([.text(Data("Hi".utf8))]).operatorName == "TJ")
        #expect(ValidatedOperator.moveAndShowText(Data("Hello".utf8)).operatorName == "'")
        #expect(ValidatedOperator.moveAndShowTextWithSpacing(wordSpacing: 0, charSpacing: 0, text: Data()).operatorName == "\"")
    }

    @Test("Path operator names are correct")
    func pathOperatorNames() {
        #expect(ValidatedOperator.moveTo(x: 0, y: 0).operatorName == "m")
        #expect(ValidatedOperator.lineTo(x: 100, y: 100).operatorName == "l")
        #expect(ValidatedOperator.curveTo(x1: 0, y1: 0, x2: 50, y2: 50, x3: 100, y3: 100).operatorName == "c")
        #expect(ValidatedOperator.curveToInitialReplicated(x2: 50, y2: 50, x3: 100, y3: 100).operatorName == "v")
        #expect(ValidatedOperator.curveToFinalReplicated(x1: 0, y1: 0, x3: 100, y3: 100).operatorName == "y")
        #expect(ValidatedOperator.closePath.operatorName == "h")
        #expect(ValidatedOperator.appendRectangle(x: 0, y: 0, width: 100, height: 100).operatorName == "re")
    }

    @Test("Path painting operator names are correct")
    func pathPaintingOperatorNames() {
        #expect(ValidatedOperator.stroke.operatorName == "S")
        #expect(ValidatedOperator.closeAndStroke.operatorName == "s")
        #expect(ValidatedOperator.fill.operatorName == "f")
        #expect(ValidatedOperator.fillEvenOdd.operatorName == "f*")
        #expect(ValidatedOperator.fillAndStroke.operatorName == "B")
        #expect(ValidatedOperator.fillAndStrokeEvenOdd.operatorName == "B*")
        #expect(ValidatedOperator.closeFillAndStroke.operatorName == "b")
        #expect(ValidatedOperator.closeFillAndStrokeEvenOdd.operatorName == "b*")
        #expect(ValidatedOperator.endPath.operatorName == "n")
    }

    @Test("Clipping operator names are correct")
    func clippingOperatorNames() {
        #expect(ValidatedOperator.clip.operatorName == "W")
        #expect(ValidatedOperator.clipEvenOdd.operatorName == "W*")
    }

    @Test("Graphics state operator names are correct")
    func graphicsStateOperatorNames() {
        #expect(ValidatedOperator.saveGraphicsState.operatorName == "q")
        #expect(ValidatedOperator.restoreGraphicsState.operatorName == "Q")
        #expect(ValidatedOperator.concatMatrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0).operatorName == "cm")
        #expect(ValidatedOperator.setLineWidth(1).operatorName == "w")
        #expect(ValidatedOperator.setLineCap(0).operatorName == "J")
        #expect(ValidatedOperator.setLineJoin(0).operatorName == "j")
        #expect(ValidatedOperator.setMiterLimit(10).operatorName == "M")
        #expect(ValidatedOperator.setDashPattern(pattern: [], phase: 0).operatorName == "d")
        #expect(ValidatedOperator.setRenderingIntent(ASAtom("Perceptual")).operatorName == "ri")
        #expect(ValidatedOperator.setFlatness(0).operatorName == "i")
        #expect(ValidatedOperator.setExtGState(ASAtom("GS1")).operatorName == "gs")
    }

    @Test("XObject operator name is correct")
    func xObjectOperatorName() {
        #expect(ValidatedOperator.invokeXObject(ASAtom("Im1")).operatorName == "Do")
    }

    @Test("Inline image operator names are correct")
    func inlineImageOperatorNames() {
        #expect(ValidatedOperator.beginInlineImage.operatorName == "BI")
        let imageData = InlineImageData(dictionary: [:], data: Data())
        #expect(ValidatedOperator.inlineImageData(imageData).operatorName == "ID")
        #expect(ValidatedOperator.endInlineImage.operatorName == "EI")
    }

    @Test("Marked content operator names are correct")
    func markedContentOperatorNames() {
        #expect(ValidatedOperator.beginMarkedContent(ASAtom("Span")).operatorName == "BMC")
        #expect(ValidatedOperator.beginMarkedContentWithProperties(tag: ASAtom("P"), properties: .null).operatorName == "BDC")
        #expect(ValidatedOperator.endMarkedContent.operatorName == "EMC")
        #expect(ValidatedOperator.markedContentPoint(ASAtom("Artifact")).operatorName == "MP")
        #expect(ValidatedOperator.markedContentPointWithProperties(tag: ASAtom("Artifact"), properties: .null).operatorName == "DP")
    }

    @Test("Shading operator name is correct")
    func shadingOperatorName() {
        #expect(ValidatedOperator.paintShading(ASAtom("Sh1")).operatorName == "sh")
    }

    @Test("Compatibility operator names are correct")
    func compatibilityOperatorNames() {
        #expect(ValidatedOperator.beginCompatibility.operatorName == "BX")
        #expect(ValidatedOperator.endCompatibility.operatorName == "EX")
    }

    @Test("Unknown operator preserves name")
    func unknownOperatorName() {
        let op = ValidatedOperator.unknown(name: "xx", operands: [])
        #expect(op.operatorName == "xx")
    }

    // MARK: - Category Tests

    @Test("Color operators have color category")
    func colorOperatorCategory() {
        #expect(ValidatedOperator.setGrayStroke(0.5).category == .color)
        #expect(ValidatedOperator.setGrayFill(0.5).category == .color)
        #expect(ValidatedOperator.setRGBStroke(r: 1, g: 0, b: 0).category == .color)
        #expect(ValidatedOperator.setRGBFill(r: 1, g: 0, b: 0).category == .color)
        #expect(ValidatedOperator.setCMYKStroke(c: 0, m: 1, y: 1, k: 0).category == .color)
        #expect(ValidatedOperator.setCMYKFill(c: 0, m: 1, y: 1, k: 0).category == .color)
    }

    @Test("Text operators have appropriate text categories")
    func textOperatorCategories() {
        #expect(ValidatedOperator.beginText.category == .textObject)
        #expect(ValidatedOperator.endText.category == .textObject)
        #expect(ValidatedOperator.setFont(name: ASAtom("F1"), size: 12).category == .textState)
        #expect(ValidatedOperator.setTextMatrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0).category == .textPositioning)
        #expect(ValidatedOperator.showText(Data()).category == .textShowing)
    }

    @Test("Path operators have appropriate categories")
    func pathOperatorCategories() {
        #expect(ValidatedOperator.moveTo(x: 0, y: 0).category == .pathConstruction)
        #expect(ValidatedOperator.lineTo(x: 100, y: 100).category == .pathConstruction)
        #expect(ValidatedOperator.stroke.category == .pathPainting)
        #expect(ValidatedOperator.fill.category == .pathPainting)
    }

    @Test("Graphics state operators have graphicsState category")
    func graphicsStateOperatorCategory() {
        #expect(ValidatedOperator.saveGraphicsState.category == .graphicsState)
        #expect(ValidatedOperator.restoreGraphicsState.category == .graphicsState)
        #expect(ValidatedOperator.setLineWidth(1).category == .graphicsState)
    }

    // MARK: - Category Check Tests

    @Test("isColorOperator returns correct value")
    func isColorOperator() {
        #expect(ValidatedOperator.setGrayStroke(0.5).isColorOperator == true)
        #expect(ValidatedOperator.beginText.isColorOperator == false)
        #expect(ValidatedOperator.stroke.isColorOperator == false)
    }

    @Test("isTextOperator returns correct value")
    func isTextOperator() {
        #expect(ValidatedOperator.beginText.isTextOperator == true)
        #expect(ValidatedOperator.setFont(name: ASAtom("F1"), size: 12).isTextOperator == true)
        #expect(ValidatedOperator.showText(Data()).isTextOperator == true)
        #expect(ValidatedOperator.stroke.isTextOperator == false)
        #expect(ValidatedOperator.setGrayFill(0).isTextOperator == false)
    }

    @Test("isPathOperator returns correct value")
    func isPathOperator() {
        #expect(ValidatedOperator.moveTo(x: 0, y: 0).isPathOperator == true)
        #expect(ValidatedOperator.stroke.isPathOperator == true)
        #expect(ValidatedOperator.fill.isPathOperator == true)
        #expect(ValidatedOperator.beginText.isPathOperator == false)
    }

    @Test("isGraphicsStateOperator returns correct value")
    func isGraphicsStateOperator() {
        #expect(ValidatedOperator.saveGraphicsState.isGraphicsStateOperator == true)
        #expect(ValidatedOperator.setLineWidth(1).isGraphicsStateOperator == true)
        #expect(ValidatedOperator.beginText.isGraphicsStateOperator == false)
    }

    @Test("isBeginOperator returns correct value")
    func isBeginOperator() {
        #expect(ValidatedOperator.beginText.isBeginOperator == true)
        #expect(ValidatedOperator.saveGraphicsState.isBeginOperator == true)
        #expect(ValidatedOperator.beginMarkedContent(ASAtom("Span")).isBeginOperator == true)
        #expect(ValidatedOperator.beginInlineImage.isBeginOperator == true)
        #expect(ValidatedOperator.beginCompatibility.isBeginOperator == true)
        #expect(ValidatedOperator.endText.isBeginOperator == false)
    }

    @Test("isEndOperator returns correct value")
    func isEndOperator() {
        #expect(ValidatedOperator.endText.isEndOperator == true)
        #expect(ValidatedOperator.restoreGraphicsState.isEndOperator == true)
        #expect(ValidatedOperator.endMarkedContent.isEndOperator == true)
        #expect(ValidatedOperator.endInlineImage.isEndOperator == true)
        #expect(ValidatedOperator.endCompatibility.isEndOperator == true)
        #expect(ValidatedOperator.beginText.isEndOperator == false)
    }

    @Test("isStrokingColorOperator returns correct value")
    func isStrokingColorOperator() {
        #expect(ValidatedOperator.setGrayStroke(0.5).isStrokingColorOperator == true)
        #expect(ValidatedOperator.setRGBStroke(r: 1, g: 0, b: 0).isStrokingColorOperator == true)
        #expect(ValidatedOperator.setGrayFill(0.5).isStrokingColorOperator == false)
    }

    @Test("isFillColorOperator returns correct value")
    func isFillColorOperator() {
        #expect(ValidatedOperator.setGrayFill(0.5).isFillColorOperator == true)
        #expect(ValidatedOperator.setRGBFill(r: 1, g: 0, b: 0).isFillColorOperator == true)
        #expect(ValidatedOperator.setGrayStroke(0.5).isFillColorOperator == false)
    }

    // MARK: - Property Access Tests

    @Test("Gray operator provides gray property")
    func grayOperatorProperties() {
        let op = ValidatedOperator.setGrayFill(0.75)
        #expect(op.property(named: "gray")?.realValue == 0.75)
    }

    @Test("RGB operator provides color properties")
    func rgbOperatorProperties() {
        let op = ValidatedOperator.setRGBFill(r: 0.2, g: 0.4, b: 0.6)
        #expect(op.property(named: "red")?.realValue == 0.2)
        #expect(op.property(named: "green")?.realValue == 0.4)
        #expect(op.property(named: "blue")?.realValue == 0.6)
    }

    @Test("CMYK operator provides color properties")
    func cmykOperatorProperties() {
        let op = ValidatedOperator.setCMYKFill(c: 0.1, m: 0.2, y: 0.3, k: 0.4)
        #expect(op.property(named: "cyan")?.realValue == 0.1)
        #expect(op.property(named: "magenta")?.realValue == 0.2)
        #expect(op.property(named: "yellow")?.realValue == 0.3)
        #expect(op.property(named: "black")?.realValue == 0.4)
    }

    @Test("Font operator provides font properties")
    func fontOperatorProperties() {
        let op = ValidatedOperator.setFont(name: ASAtom("Helvetica"), size: 12.5)
        #expect(op.property(named: "fontName")?.stringValue == "Helvetica")
        #expect(op.property(named: "fontSize")?.realValue == 12.5)
    }

    @Test("Matrix operator provides matrix properties")
    func matrixOperatorProperties() {
        let op = ValidatedOperator.setTextMatrix(a: 1.5, b: 0, c: 0, d: 1.5, e: 100, f: 200)
        #expect(op.property(named: "a")?.realValue == 1.5)
        #expect(op.property(named: "b")?.realValue == 0)
        #expect(op.property(named: "c")?.realValue == 0)
        #expect(op.property(named: "d")?.realValue == 1.5)
        #expect(op.property(named: "e")?.realValue == 100)
        #expect(op.property(named: "f")?.realValue == 200)
    }

    @Test("Rectangle operator provides dimension properties")
    func rectangleOperatorProperties() {
        let op = ValidatedOperator.appendRectangle(x: 10, y: 20, width: 100, height: 50)
        #expect(op.property(named: "x")?.realValue == 10)
        #expect(op.property(named: "y")?.realValue == 20)
        #expect(op.property(named: "width")?.realValue == 100)
        #expect(op.property(named: "height")?.realValue == 50)
    }

    @Test("Common properties are available")
    func commonProperties() {
        let op = ValidatedOperator.beginText
        #expect(op.property(named: "operatorName")?.stringValue == "BT")
        #expect(op.property(named: "category")?.stringValue == "TextObject")
        #expect(op.property(named: "isColorOperator")?.boolValue == false)
        #expect(op.property(named: "isTextOperator")?.boolValue == true)
    }

    // MARK: - Object Type Tests

    @Test("Object type includes operator name")
    func objectType() {
        #expect(ValidatedOperator.beginText.objectType == "OpBT")
        #expect(ValidatedOperator.stroke.objectType == "OpS")
        #expect(ValidatedOperator.setGrayFill(0.5).objectType == "Opg")
    }

    // MARK: - Equatable Tests

    @Test("Operators with same values are equal")
    func operatorEquality() {
        let op1 = ValidatedOperator.setGrayFill(0.5)
        let op2 = ValidatedOperator.setGrayFill(0.5)
        #expect(op1 == op2)
    }

    @Test("Operators with different values are not equal")
    func operatorInequality() {
        let op1 = ValidatedOperator.setGrayFill(0.5)
        let op2 = ValidatedOperator.setGrayFill(0.6)
        #expect(op1 != op2)
    }

    @Test("Different operator types are not equal")
    func differentOperatorTypes() {
        let op1 = ValidatedOperator.setGrayFill(0.5)
        let op2 = ValidatedOperator.setGrayStroke(0.5)
        #expect(op1 != op2)
    }

    // MARK: - Hashable Tests

    @Test("Equal operators have same hash")
    func operatorHashEquality() {
        let op1 = ValidatedOperator.setRGBFill(r: 1, g: 0, b: 0)
        let op2 = ValidatedOperator.setRGBFill(r: 1, g: 0, b: 0)
        #expect(op1.hashValue == op2.hashValue)
    }

    @Test("Operators can be used in sets")
    func operatorsInSet() {
        var set: Set<ValidatedOperator> = []
        set.insert(.beginText)
        set.insert(.endText)
        set.insert(.beginText)  // Duplicate
        #expect(set.count == 2)
    }

    // MARK: - Static Properties Tests

    @Test("Defined operator count is correct")
    func definedOperatorCount() {
        // Should be 70 defined operators (excluding unknown)
        #expect(ValidatedOperator.definedOperatorCount == 70)
    }

    @Test("All operator names list has correct count")
    func allOperatorNamesCount() {
        #expect(ValidatedOperator.allOperatorNames.count == 70)
    }

    @Test("All operator names are unique")
    func allOperatorNamesUnique() {
        let names = ValidatedOperator.allOperatorNames
        let uniqueNames = Set(names)
        #expect(uniqueNames.count == names.count)
    }

    // MARK: - Description Tests

    @Test("Description includes operator details")
    func operatorDescription() {
        let gray = ValidatedOperator.setGrayFill(0.5)
        #expect(gray.description.contains("0.5"))
        #expect(gray.description.contains("g"))

        let rgb = ValidatedOperator.setRGBFill(r: 1, g: 0, b: 0)
        #expect(rgb.description.contains("rg"))

        let font = ValidatedOperator.setFont(name: ASAtom("F1"), size: 12)
        #expect(font.description.contains("F1"))
        #expect(font.description.contains("Tf"))
    }

    // MARK: - InlineImageData Tests

    @Test("InlineImageData extracts width")
    func inlineImageWidth() {
        let dict: [ASAtom: COSValue] = [ASAtom("W"): .integer(100)]
        let imageData = InlineImageData(dictionary: dict, data: Data())
        #expect(imageData.width == 100)
    }

    @Test("InlineImageData extracts height")
    func inlineImageHeight() {
        let dict: [ASAtom: COSValue] = [ASAtom("H"): .integer(200)]
        let imageData = InlineImageData(dictionary: dict, data: Data())
        #expect(imageData.height == 200)
    }

    @Test("InlineImageData extracts bits per component")
    func inlineImageBitsPerComponent() {
        let dict: [ASAtom: COSValue] = [ASAtom("BPC"): .integer(8)]
        let imageData = InlineImageData(dictionary: dict, data: Data())
        #expect(imageData.bitsPerComponent == 8)
    }

    @Test("InlineImageData extracts color space")
    func inlineImageColorSpace() {
        let dict: [ASAtom: COSValue] = [ASAtom("CS"): .name(ASAtom("DeviceRGB"))]
        let imageData = InlineImageData(dictionary: dict, data: Data())
        #expect(imageData.colorSpace == ASAtom("DeviceRGB"))
    }

    // MARK: - ValidatedTextArrayElement Tests

    @Test("Text array element text extraction")
    func textArrayElementText() {
        let element = ValidatedTextArrayElement.text(Data("Hello".utf8))
        #expect(element.isText == true)
        #expect(element.isAdjustment == false)
        #expect(element.textData == Data("Hello".utf8))
        #expect(element.adjustmentValue == nil)
    }

    @Test("Text array element adjustment extraction")
    func textArrayElementAdjustment() {
        let element = ValidatedTextArrayElement.adjustment(-50)
        #expect(element.isText == false)
        #expect(element.isAdjustment == true)
        #expect(element.textData == nil)
        #expect(element.adjustmentValue == -50)
    }

    // MARK: - OperatorCategory Tests

    @Test("OperatorCategory has all expected cases")
    func operatorCategoryCases() {
        #expect(OperatorCategory.allCases.count == 15)
        #expect(OperatorCategory.color.rawValue == "Color")
        #expect(OperatorCategory.textObject.rawValue == "TextObject")
        #expect(OperatorCategory.graphicsState.rawValue == "GraphicsState")
    }
}
