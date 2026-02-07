import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Pattern Type Tests

@Suite("PatternType Tests")
struct PatternTypeTests {

    @Test("Raw values match PDF specification")
    func rawValues() {
        #expect(PatternType.tiling.rawValue == 1)
        #expect(PatternType.shading.rawValue == 2)
        #expect(PatternType.unknown.rawValue == 0)
    }

    @Test("Creates type from valid value")
    func fromValidValue() {
        #expect(PatternType(fromValue: 1) == .tiling)
        #expect(PatternType(fromValue: 2) == .shading)
    }

    @Test("Creates unknown for invalid value")
    func fromInvalidValue() {
        #expect(PatternType(fromValue: 3) == .unknown)
        #expect(PatternType(fromValue: nil) == .unknown)
        #expect(PatternType(fromValue: -1) == .unknown)
    }

    @Test("CaseIterable conformance")
    func caseIterable() {
        #expect(PatternType.allCases.count == 3)
    }
}

// MARK: - Tiling Paint Type Tests

@Suite("TilingPaintType Tests")
struct TilingPaintTypeTests {

    @Test("Raw values")
    func rawValues() {
        #expect(TilingPaintType.colored.rawValue == 1)
        #expect(TilingPaintType.uncolored.rawValue == 2)
        #expect(TilingPaintType.unknown.rawValue == 0)
    }

    @Test("Creates type from valid value")
    func fromValidValue() {
        #expect(TilingPaintType(fromValue: 1) == .colored)
        #expect(TilingPaintType(fromValue: 2) == .uncolored)
    }

    @Test("Creates unknown for invalid value")
    func fromInvalidValue() {
        #expect(TilingPaintType(fromValue: 3) == .unknown)
        #expect(TilingPaintType(fromValue: nil) == .unknown)
    }

    @Test("Is colored check")
    func isColored() {
        #expect(TilingPaintType.colored.isColored == true)
        #expect(TilingPaintType.uncolored.isColored == false)
        #expect(TilingPaintType.unknown.isColored == false)
    }
}

// MARK: - Tiling Type Tests

@Suite("TilingType Tests")
struct TilingTypeTests {

    @Test("Raw values")
    func rawValues() {
        #expect(TilingType.constantSpacing.rawValue == 1)
        #expect(TilingType.noDistortion.rawValue == 2)
        #expect(TilingType.constantSpacingFasterTiling.rawValue == 3)
        #expect(TilingType.unknown.rawValue == 0)
    }

    @Test("Creates type from valid value")
    func fromValidValue() {
        #expect(TilingType(fromValue: 1) == .constantSpacing)
        #expect(TilingType(fromValue: 2) == .noDistortion)
        #expect(TilingType(fromValue: 3) == .constantSpacingFasterTiling)
    }

    @Test("Creates unknown for invalid value")
    func fromInvalidValue() {
        #expect(TilingType(fromValue: 4) == .unknown)
        #expect(TilingType(fromValue: nil) == .unknown)
    }

    @Test("CaseIterable conformance")
    func caseIterable() {
        #expect(TilingType.allCases.count == 4)
    }
}

// MARK: - Validated Pattern Tests

@Suite("ValidatedPattern Tests")
struct ValidatedPatternTests {

    @Test("Default initialization")
    func defaultInit() {
        let pattern = ValidatedPattern()
        #expect(pattern.patternType == .tiling)
        #expect(pattern.hasBBox == false)
        #expect(pattern.bBox == nil)
        #expect(pattern.hasMatrix == false)
        #expect(pattern.paintType == nil)
        #expect(pattern.tilingType == nil)
        #expect(pattern.xStep == nil)
        #expect(pattern.yStep == nil)
        #expect(pattern.hasContentStream == false)
        #expect(pattern.hasShading == false)
        #expect(pattern.objectType == "PDPattern")
    }

    @Test("Colored tiling pattern factory")
    func coloredTilingFactory() {
        let pattern = ValidatedPattern.coloredTiling(xStep: 20, yStep: 30)
        #expect(pattern.isTilingPattern == true)
        #expect(pattern.isShadingPattern == false)
        #expect(pattern.paintType == .colored)
        #expect(pattern.tilingType == .constantSpacing)
        #expect(pattern.xStep == 20)
        #expect(pattern.yStep == 30)
        #expect(pattern.hasBBox == true)
        #expect(pattern.hasContentStream == true)
        #expect(pattern.hasResources == true)
        #expect(pattern.hasValidSteps == true)
        #expect(pattern.isColored == true)
        #expect(pattern.isUncolored == false)
    }

    @Test("Uncolored tiling pattern factory")
    func uncoloredTilingFactory() {
        let pattern = ValidatedPattern.uncoloredTiling(xStep: 15, yStep: 15)
        #expect(pattern.isTilingPattern == true)
        #expect(pattern.paintType == .uncolored)
        #expect(pattern.isColored == false)
        #expect(pattern.isUncolored == true)
        #expect(pattern.hasValidSteps == true)
    }

    @Test("Shading pattern factory")
    func shadingFactory() {
        let pattern = ValidatedPattern.shading(shadingType: 3)
        #expect(pattern.isShadingPattern == true)
        #expect(pattern.isTilingPattern == false)
        #expect(pattern.hasShading == true)
        #expect(pattern.shadingType == 3)
    }

    @Test("Valid steps check")
    func validSteps() {
        let valid = ValidatedPattern(patternType: .tiling, xStep: 10, yStep: 10)
        #expect(valid.hasValidSteps == true)

        let zeroX = ValidatedPattern(patternType: .tiling, xStep: 0, yStep: 10)
        #expect(zeroX.hasValidSteps == false)

        let zeroY = ValidatedPattern(patternType: .tiling, xStep: 10, yStep: 0)
        #expect(zeroY.hasValidSteps == false)

        let missing = ValidatedPattern(patternType: .tiling, xStep: nil, yStep: nil)
        #expect(missing.hasValidSteps == false)

        // Shading patterns always have valid steps
        let shading = ValidatedPattern(patternType: .shading)
        #expect(shading.hasValidSteps == true)
    }

    @Test("Full tiling pattern initialization")
    func fullTilingInit() {
        let bbox = PDFRect(x: 0, y: 0, width: 50, height: 50)
        let pattern = ValidatedPattern(
            patternType: .tiling,
            hasBBox: true,
            bBox: bbox,
            hasMatrix: true,
            paintType: .colored,
            tilingType: .noDistortion,
            xStep: 50,
            yStep: 50,
            hasContentStream: true,
            hasResources: true
        )
        #expect(pattern.hasBBox == true)
        #expect(pattern.bBox == bbox)
        #expect(pattern.hasMatrix == true)
        #expect(pattern.tilingType == .noDistortion)
        #expect(pattern.hasResources == true)
    }

    @Test("Shading pattern with ExtGState")
    func shadingWithExtGState() {
        let pattern = ValidatedPattern(
            patternType: .shading,
            hasShading: true,
            shadingType: 2,
            hasExtGState: true
        )
        #expect(pattern.isShadingPattern == true)
        #expect(pattern.hasExtGState == true)
        #expect(pattern.shadingType == 2)
    }

    @Test("Property access")
    func propertyAccess() {
        let pattern = ValidatedPattern.coloredTiling(xStep: 10, yStep: 20)
        #expect(pattern.property(named: "patternType")?.integerValue == 1)
        #expect(pattern.property(named: "hasBBox")?.boolValue == true)
        #expect(pattern.property(named: "paintType")?.integerValue == 1)
        #expect(pattern.property(named: "tilingType")?.integerValue == 1)
        #expect(pattern.property(named: "xStep")?.realValue == 10)
        #expect(pattern.property(named: "yStep")?.realValue == 20)
        #expect(pattern.property(named: "hasContentStream")?.boolValue == true)
        #expect(pattern.property(named: "hasResources")?.boolValue == true)
        #expect(pattern.property(named: "isTilingPattern")?.boolValue == true)
        #expect(pattern.property(named: "isShadingPattern")?.boolValue == false)
        #expect(pattern.property(named: "hasValidSteps")?.boolValue == true)
        #expect(pattern.property(named: "isColored")?.boolValue == true)
        #expect(pattern.property(named: "nonexistent") == nil)
    }

    @Test("Null property values for absent optional fields")
    func nullProperties() {
        let pattern = ValidatedPattern()
        #expect(pattern.property(named: "bBox")?.isNull == true)
        #expect(pattern.property(named: "paintType")?.isNull == true)
        #expect(pattern.property(named: "tilingType")?.isNull == true)
        #expect(pattern.property(named: "xStep")?.isNull == true)
        #expect(pattern.property(named: "yStep")?.isNull == true)
        #expect(pattern.property(named: "shadingType")?.isNull == true)
    }

    @Test("Summary description")
    func summary() {
        let tiling = ValidatedPattern.coloredTiling(xStep: 10, yStep: 20)
        let ts = tiling.summary
        #expect(ts.contains("Tiling"))
        #expect(ts.contains("colored"))
        #expect(ts.contains("step"))

        let shading = ValidatedPattern.shading(shadingType: 2)
        let ss = shading.summary
        #expect(ss.contains("Shading"))
        #expect(ss.contains("type=2"))
    }

    @Test("Equatable by ID")
    func equatable() {
        let id = UUID()
        let a = ValidatedPattern(id: id, patternType: .tiling)
        let b = ValidatedPattern(id: id, patternType: .shading)
        let c = ValidatedPattern(patternType: .tiling)
        #expect(a == b)
        #expect(a != c)
    }

    @Test("PropertyNames coverage")
    func propertyNames() {
        let pattern = ValidatedPattern.coloredTiling()
        let names = pattern.propertyNames
        #expect(names.contains("patternType"))
        #expect(names.contains("isTilingPattern"))
        #expect(names.contains("isShadingPattern"))
        for propName in names {
            let value = pattern.property(named: propName)
            #expect(value != nil)
        }
    }
}
