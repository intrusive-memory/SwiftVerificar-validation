import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - BlendMode Tests

@Suite("BlendMode")
struct BlendModeTests {

    @Test("All blend modes have correct raw values")
    func rawValues() {
        #expect(BlendMode.normal.rawValue == "Normal")
        #expect(BlendMode.compatible.rawValue == "Compatible")
        #expect(BlendMode.multiply.rawValue == "Multiply")
        #expect(BlendMode.screen.rawValue == "Screen")
        #expect(BlendMode.overlay.rawValue == "Overlay")
        #expect(BlendMode.darken.rawValue == "Darken")
        #expect(BlendMode.lighten.rawValue == "Lighten")
        #expect(BlendMode.colorDodge.rawValue == "ColorDodge")
        #expect(BlendMode.colorBurn.rawValue == "ColorBurn")
        #expect(BlendMode.hardLight.rawValue == "HardLight")
        #expect(BlendMode.softLight.rawValue == "SoftLight")
        #expect(BlendMode.difference.rawValue == "Difference")
        #expect(BlendMode.exclusion.rawValue == "Exclusion")
        #expect(BlendMode.hue.rawValue == "Hue")
        #expect(BlendMode.saturation.rawValue == "Saturation")
        #expect(BlendMode.color.rawValue == "Color")
        #expect(BlendMode.luminosity.rawValue == "Luminosity")
    }

    @Test("Total case count is 17")
    func caseCount() {
        #expect(BlendMode.allCases.count == 17)
    }

    @Test("isNormal for Normal and Compatible")
    func isNormal() {
        #expect(BlendMode.normal.isNormal)
        #expect(BlendMode.compatible.isNormal)
        #expect(!BlendMode.multiply.isNormal)
        #expect(!BlendMode.screen.isNormal)
    }

    @Test("involvesTransparency for non-normal blend modes")
    func involvesTransparency() {
        #expect(!BlendMode.normal.involvesTransparency)
        #expect(!BlendMode.compatible.involvesTransparency)
        #expect(BlendMode.multiply.involvesTransparency)
        #expect(BlendMode.screen.involvesTransparency)
        #expect(BlendMode.overlay.involvesTransparency)
        #expect(BlendMode.luminosity.involvesTransparency)
    }

    @Test("from() creates blend mode from string")
    func fromString() {
        #expect(BlendMode.from("Normal") == .normal)
        #expect(BlendMode.from("Multiply") == .multiply)
        #expect(BlendMode.from("Invalid") == nil)
    }
}

// MARK: - ValidatedExtGState Tests

@Suite("ValidatedExtGState")
struct ValidatedExtGStateTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let gs = ValidatedExtGState()
            #expect(gs.blendMode == nil)
            #expect(gs.strokingAlpha == nil)
            #expect(gs.nonStrokingAlpha == nil)
            #expect(!gs.hasSoftMask)
            #expect(gs.softMaskSubtype == nil)
            #expect(!gs.alphaIsShape)
            #expect(gs.lineWidth == nil)
            #expect(gs.lineCap == nil)
            #expect(gs.lineJoin == nil)
            #expect(gs.miterLimit == nil)
            #expect(!gs.hasDashPattern)
            #expect(!gs.hasFont)
            #expect(gs.fontName == nil)
            #expect(gs.fontSize == nil)
            #expect(gs.renderingIntent == nil)
            #expect(gs.overprintStroking == nil)
            #expect(gs.overprintNonStroking == nil)
            #expect(gs.overprintMode == nil)
            #expect(!gs.hasHalftone)
            #expect(gs.flatness == nil)
            #expect(gs.smoothness == nil)
            #expect(gs.strokeAdjustment == nil)
            #expect(!gs.hasTransferFunction)
            #expect(gs.isDefaultTransferFunction)
            #expect(!gs.hasBlackGeneration)
            #expect(!gs.hasUndercolorRemoval)
        }

        @Test("Object type is PDExtGState")
        func objectType() {
            let gs = ValidatedExtGState()
            #expect(gs.objectType == "PDExtGState")
        }

        @Test("Default context is ExtGState")
        func defaultContext() {
            let gs = ValidatedExtGState()
            #expect(gs.validationContext.location == "ExtGState")
        }

        @Test("Custom context is preserved")
        func customContext() {
            let ctx = ObjectContext(pageNumber: 1, location: "Custom")
            let gs = ValidatedExtGState(context: ctx)
            #expect(gs.validationContext.pageNumber == 1)
        }
    }

    // MARK: - Transparency Properties

    @Suite("Transparency Properties")
    struct TransparencyTests {

        @Test("involvesTransparency with non-normal blend mode")
        func blendModeTransparency() {
            let gs = ValidatedExtGState(blendMode: .multiply)
            #expect(gs.involvesTransparency)
        }

        @Test("involvesTransparency with stroking alpha less than 1")
        func strokingAlphaTransparency() {
            let gs = ValidatedExtGState(strokingAlpha: 0.5)
            #expect(gs.involvesTransparency)
        }

        @Test("involvesTransparency with non-stroking alpha less than 1")
        func nonStrokingAlphaTransparency() {
            let gs = ValidatedExtGState(nonStrokingAlpha: 0.8)
            #expect(gs.involvesTransparency)
        }

        @Test("involvesTransparency with soft mask")
        func softMaskTransparency() {
            let gs = ValidatedExtGState(hasSoftMask: true)
            #expect(gs.involvesTransparency)
        }

        @Test("No transparency with normal blend mode and full opacity")
        func noTransparency() {
            let gs = ValidatedExtGState(
                blendMode: .normal,
                strokingAlpha: 1.0,
                nonStrokingAlpha: 1.0
            )
            #expect(!gs.involvesTransparency)
        }

        @Test("No transparency with nil values")
        func nilNoTransparency() {
            let gs = ValidatedExtGState()
            #expect(!gs.involvesTransparency)
        }

        @Test("isTransparent with low alpha")
        func isTransparent() {
            let gs = ValidatedExtGState(strokingAlpha: 0.3)
            #expect(gs.isTransparent)
        }

        @Test("isTransparent with soft mask")
        func isTransparentSoftMask() {
            let gs = ValidatedExtGState(hasSoftMask: true)
            #expect(gs.isTransparent)
        }

        @Test("Not transparent with full alpha")
        func notTransparent() {
            let gs = ValidatedExtGState(
                strokingAlpha: 1.0,
                nonStrokingAlpha: 1.0
            )
            #expect(!gs.isTransparent)
        }

        @Test("containsTransparency detects any transparency key")
        func containsTransparency() {
            let withBM = ValidatedExtGState(blendMode: .normal)
            #expect(withBM.containsTransparency)

            let withAlpha = ValidatedExtGState(strokingAlpha: 1.0)
            #expect(withAlpha.containsTransparency)

            let withAIS = ValidatedExtGState(alphaIsShape: true)
            #expect(withAIS.containsTransparency)

            let empty = ValidatedExtGState()
            #expect(!empty.containsTransparency)
        }
    }

    // MARK: - PDF/A-1 Compliance

    @Suite("PDF/A-1 Compliance")
    struct PDFA1ComplianceTests {

        @Test("Default ExtGState is PDF/A-1 compliant")
        func defaultCompliant() {
            let gs = ValidatedExtGState()
            #expect(gs.isPDFA1Compliant)
        }

        @Test("Normal blend mode is PDF/A-1 compliant")
        func normalBlendCompliant() {
            let gs = ValidatedExtGState(
                blendMode: .normal,
                strokingAlpha: 1.0,
                nonStrokingAlpha: 1.0
            )
            #expect(gs.isPDFA1Compliant)
        }

        @Test("Non-normal blend mode violates PDF/A-1")
        func blendModeViolation() {
            let gs = ValidatedExtGState(blendMode: .multiply)
            #expect(!gs.isPDFA1Compliant)
        }

        @Test("Stroking alpha less than 1 violates PDF/A-1")
        func strokingAlphaViolation() {
            let gs = ValidatedExtGState(strokingAlpha: 0.9)
            #expect(!gs.isPDFA1Compliant)
        }

        @Test("Non-stroking alpha less than 1 violates PDF/A-1")
        func nonStrokingAlphaViolation() {
            let gs = ValidatedExtGState(nonStrokingAlpha: 0.5)
            #expect(!gs.isPDFA1Compliant)
        }

        @Test("Soft mask violates PDF/A-1")
        func softMaskViolation() {
            let gs = ValidatedExtGState(hasSoftMask: true)
            #expect(!gs.isPDFA1Compliant)
        }

        @Test("Non-default transfer function violates PDF/A-1")
        func transferFunctionViolation() {
            let gs = ValidatedExtGState(
                hasTransferFunction: true,
                isDefaultTransferFunction: false
            )
            #expect(!gs.isPDFA1Compliant)
        }

        @Test("Default transfer function is PDF/A-1 compliant")
        func defaultTransferCompliant() {
            let gs = ValidatedExtGState(
                hasTransferFunction: true,
                isDefaultTransferFunction: true
            )
            #expect(gs.isPDFA1Compliant)
        }
    }

    // MARK: - Effective Values

    @Suite("Effective Values")
    struct EffectiveValueTests {

        @Test("effectiveStrokingAlpha defaults to 1.0")
        func effectiveStrokingAlpha() {
            let gs = ValidatedExtGState()
            #expect(gs.effectiveStrokingAlpha == 1.0)

            let withAlpha = ValidatedExtGState(strokingAlpha: 0.7)
            #expect(withAlpha.effectiveStrokingAlpha == 0.7)
        }

        @Test("effectiveNonStrokingAlpha defaults to 1.0")
        func effectiveNonStrokingAlpha() {
            let gs = ValidatedExtGState()
            #expect(gs.effectiveNonStrokingAlpha == 1.0)

            let withAlpha = ValidatedExtGState(nonStrokingAlpha: 0.3)
            #expect(withAlpha.effectiveNonStrokingAlpha == 0.3)
        }

        @Test("effectiveBlendMode defaults to Normal")
        func effectiveBlendMode() {
            let gs = ValidatedExtGState()
            #expect(gs.effectiveBlendMode == .normal)

            let withBM = ValidatedExtGState(blendMode: .screen)
            #expect(withBM.effectiveBlendMode == .screen)
        }
    }

    // MARK: - Line Style Properties

    @Suite("Line Style Properties")
    struct LineStyleTests {

        @Test("Line style properties are stored correctly")
        func lineStyle() {
            let gs = ValidatedExtGState(
                lineWidth: 2.5,
                lineCap: 1,
                lineJoin: 2,
                miterLimit: 10.0,
                hasDashPattern: true
            )
            #expect(gs.lineWidth == 2.5)
            #expect(gs.lineCap == 1)
            #expect(gs.lineJoin == 2)
            #expect(gs.miterLimit == 10.0)
            #expect(gs.hasDashPattern)
        }
    }

    // MARK: - Font Properties

    @Suite("Font Properties")
    struct FontPropertyTests {

        @Test("Font properties are stored correctly")
        func fontProperties() {
            let gs = ValidatedExtGState(
                hasFont: true,
                fontName: "Helvetica",
                fontSize: 12.0
            )
            #expect(gs.hasFont)
            #expect(gs.fontName == "Helvetica")
            #expect(gs.fontSize == 12.0)
        }
    }

    // MARK: - Color Properties

    @Suite("Color Properties")
    struct ColorPropertyTests {

        @Test("Rendering intent is stored correctly")
        func renderingIntent() {
            let gs = ValidatedExtGState(
                renderingIntent: .perceptual
            )
            #expect(gs.renderingIntent == .perceptual)
        }

        @Test("Overprint properties are stored correctly")
        func overprintProperties() {
            let gs = ValidatedExtGState(
                overprintStroking: true,
                overprintNonStroking: false,
                overprintMode: 1
            )
            #expect(gs.overprintStroking == true)
            #expect(gs.overprintNonStroking == false)
            #expect(gs.overprintMode == 1)
        }
    }

    // MARK: - PDFObject Property Access

    @Suite("PDFObject Property Access")
    struct PropertyAccessTests {

        @Test("Property names are complete")
        func propertyNames() {
            let gs = ValidatedExtGState()
            let names = gs.propertyNames
            #expect(names.contains("blendMode"))
            #expect(names.contains("strokingAlpha"))
            #expect(names.contains("nonStrokingAlpha"))
            #expect(names.contains("hasSoftMask"))
            #expect(names.contains("softMaskSubtype"))
            #expect(names.contains("lineWidth"))
            #expect(names.contains("lineCap"))
            #expect(names.contains("hasFont"))
            #expect(names.contains("fontName"))
            #expect(names.contains("renderingIntent"))
            #expect(names.contains("overprintStroking"))
            #expect(names.contains("hasHalftone"))
            #expect(names.contains("hasTransferFunction"))
            #expect(names.contains("involvesTransparency"))
            #expect(names.contains("isTransparent"))
            #expect(names.contains("isPDFA1Compliant"))
            #expect(names.contains("containsTransparency"))
        }

        @Test("Null properties when not set")
        func nullProperties() {
            let gs = ValidatedExtGState()
            #expect(gs.property(named: "blendMode") == .null)
            #expect(gs.property(named: "strokingAlpha") == .null)
            #expect(gs.property(named: "nonStrokingAlpha") == .null)
            #expect(gs.property(named: "softMaskSubtype") == .null)
            #expect(gs.property(named: "lineWidth") == .null)
            #expect(gs.property(named: "lineCap") == .null)
            #expect(gs.property(named: "lineJoin") == .null)
            #expect(gs.property(named: "miterLimit") == .null)
            #expect(gs.property(named: "fontName") == .null)
            #expect(gs.property(named: "fontSize") == .null)
            #expect(gs.property(named: "renderingIntent") == .null)
            #expect(gs.property(named: "overprintStroking") == .null)
            #expect(gs.property(named: "overprintNonStroking") == .null)
            #expect(gs.property(named: "overprintMode") == .null)
            #expect(gs.property(named: "flatness") == .null)
            #expect(gs.property(named: "smoothness") == .null)
            #expect(gs.property(named: "strokeAdjustment") == .null)
        }

        @Test("Populated properties return correct values")
        func populatedProperties() {
            let gs = ValidatedExtGState(
                blendMode: .multiply,
                strokingAlpha: 0.8,
                nonStrokingAlpha: 0.6,
                hasSoftMask: true,
                softMaskSubtype: "Luminosity",
                alphaIsShape: true,
                lineWidth: 3.0,
                lineCap: 1,
                lineJoin: 2,
                miterLimit: 10.0,
                hasDashPattern: true,
                hasFont: true,
                fontName: "Times",
                fontSize: 14.0,
                renderingIntent: .relativeColorimetric,
                overprintStroking: true,
                overprintNonStroking: false,
                overprintMode: 1,
                hasHalftone: true,
                flatness: 0.5,
                smoothness: 0.01,
                strokeAdjustment: true,
                hasTransferFunction: true,
                isDefaultTransferFunction: false,
                hasBlackGeneration: true,
                hasUndercolorRemoval: true
            )

            #expect(gs.property(named: "blendMode") == .string("Multiply"))
            #expect(gs.property(named: "strokingAlpha") == .real(0.8))
            #expect(gs.property(named: "nonStrokingAlpha") == .real(0.6))
            #expect(gs.property(named: "hasSoftMask") == .boolean(true))
            #expect(gs.property(named: "softMaskSubtype") == .string("Luminosity"))
            #expect(gs.property(named: "alphaIsShape") == .boolean(true))
            #expect(gs.property(named: "lineWidth") == .real(3.0))
            #expect(gs.property(named: "lineCap") == .integer(1))
            #expect(gs.property(named: "lineJoin") == .integer(2))
            #expect(gs.property(named: "miterLimit") == .real(10.0))
            #expect(gs.property(named: "hasDashPattern") == .boolean(true))
            #expect(gs.property(named: "hasFont") == .boolean(true))
            #expect(gs.property(named: "fontName") == .string("Times"))
            #expect(gs.property(named: "fontSize") == .real(14.0))
            #expect(gs.property(named: "renderingIntent") == .string("RelativeColorimetric"))
            #expect(gs.property(named: "overprintStroking") == .boolean(true))
            #expect(gs.property(named: "overprintNonStroking") == .boolean(false))
            #expect(gs.property(named: "overprintMode") == .integer(1))
            #expect(gs.property(named: "hasHalftone") == .boolean(true))
            #expect(gs.property(named: "flatness") == .real(0.5))
            #expect(gs.property(named: "smoothness") == .real(0.01))
            #expect(gs.property(named: "strokeAdjustment") == .boolean(true))
            #expect(gs.property(named: "hasTransferFunction") == .boolean(true))
            #expect(gs.property(named: "isDefaultTransferFunction") == .boolean(false))
            #expect(gs.property(named: "hasBlackGeneration") == .boolean(true))
            #expect(gs.property(named: "hasUndercolorRemoval") == .boolean(true))
        }

        @Test("Computed boolean properties through property access")
        func computedBooleanProperties() {
            let transparent = ValidatedExtGState(strokingAlpha: 0.5)
            #expect(transparent.property(named: "involvesTransparency") == .boolean(true))
            #expect(transparent.property(named: "isTransparent") == .boolean(true))
            #expect(transparent.property(named: "isPDFA1Compliant") == .boolean(false))
            #expect(transparent.property(named: "containsTransparency") == .boolean(true))

            let opaque = ValidatedExtGState()
            #expect(opaque.property(named: "involvesTransparency") == .boolean(false))
            #expect(opaque.property(named: "isTransparent") == .boolean(false))
            #expect(opaque.property(named: "isPDFA1Compliant") == .boolean(true))
            #expect(opaque.property(named: "containsTransparency") == .boolean(false))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let gs = ValidatedExtGState()
            #expect(gs.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Summary

    @Suite("Summary")
    struct SummaryTests {

        @Test("Default summary shows default")
        func defaultSummary() {
            let gs = ValidatedExtGState()
            #expect(gs.summary == "ExtGState (default)")
        }

        @Test("Summary includes blend mode")
        func blendModeSummary() {
            let gs = ValidatedExtGState(blendMode: .multiply)
            #expect(gs.summary.contains("BM=Multiply"))
        }

        @Test("Summary includes alpha values")
        func alphaSummary() {
            let gs = ValidatedExtGState(
                strokingAlpha: 0.5,
                nonStrokingAlpha: 0.8
            )
            #expect(gs.summary.contains("CA=0.5"))
            #expect(gs.summary.contains("ca=0.8"))
        }

        @Test("Summary includes soft mask")
        func softMaskSummary() {
            let gs = ValidatedExtGState(hasSoftMask: true)
            #expect(gs.summary.contains("SMask"))
        }

        @Test("Summary includes transparency indicator")
        func transparencySummary() {
            let gs = ValidatedExtGState(strokingAlpha: 0.5)
            #expect(gs.summary.contains("[transparency]"))
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("opaque() creates default state")
        func opaque() {
            let gs = ValidatedExtGState.opaque()
            #expect(!gs.involvesTransparency)
            #expect(!gs.isTransparent)
            #expect(gs.isPDFA1Compliant)
        }

        @Test("transparent() creates transparent state")
        func transparent() {
            let gs = ValidatedExtGState.transparent(
                blendMode: .screen,
                strokingAlpha: 0.4,
                nonStrokingAlpha: 0.6
            )
            #expect(gs.blendMode == .screen)
            #expect(gs.strokingAlpha == 0.4)
            #expect(gs.nonStrokingAlpha == 0.6)
            #expect(gs.involvesTransparency)
            #expect(gs.isTransparent)
            #expect(!gs.isPDFA1Compliant)
        }

        @Test("withSoftMask() creates state with soft mask")
        func withSoftMask() {
            let gs = ValidatedExtGState.withSoftMask(subtype: "Alpha")
            #expect(gs.hasSoftMask)
            #expect(gs.softMaskSubtype == "Alpha")
            #expect(gs.isTransparent)
            #expect(!gs.isPDFA1Compliant)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let gs1 = ValidatedExtGState(id: id, blendMode: .normal)
            let gs2 = ValidatedExtGState(id: id, blendMode: .multiply)
            #expect(gs1 == gs2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let gs1 = ValidatedExtGState()
            let gs2 = ValidatedExtGState()
            #expect(gs1 != gs2)
        }
    }
}
