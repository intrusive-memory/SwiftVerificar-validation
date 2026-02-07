import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - ValidatedPage Tests

@Suite("ValidatedPage")
struct ValidatedPageTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let page = ValidatedPage()
        #expect(page.pageNumber == 1)
        #expect(page.pageLabel == nil)
        #expect(page.mediaBox == .letter)
        #expect(page.cropBox == nil)
        #expect(page.bleedBox == nil)
        #expect(page.trimBox == nil)
        #expect(page.artBox == nil)
        #expect(page.rotation == 0)
        #expect(page.userUnit == 1.0)
        #expect(page.hasResources == true)
        #expect(page.hasContentStreams == false)
        #expect(page.hasAnnotations == false)
        #expect(page.fontCount == 0)
        #expect(page.xObjectCount == 0)
        #expect(page.colorSpaceCount == 0)
        #expect(page.extGStateCount == 0)
        #expect(page.patternCount == 0)
        #expect(page.shadingCount == 0)
        #expect(page.annotationCount == 0)
        #expect(page.contentStreams.isEmpty)
        #expect(page.hasTransparencyGroup == false)
        #expect(page.transparencyGroupColorSpace == nil)
    }

    @Test("Full initialization")
    func fullInit() {
        let pageDict: COSValue = .dictionary([.type: .name(ASAtom("Page"))])
        let objectKey = COSObjectKey(objectNumber: 5, generation: 0)
        let fontDict: COSValue = .dictionary([.type: .name(.font)])
        let cs = ValidatedContentStream.minimal(pageNumber: 3)

        let page = ValidatedPage(
            cosDictionary: pageDict,
            objectKey: objectKey,
            pageNumber: 3,
            pageLabel: "iii",
            mediaBox: PDFRect(width: 842, height: 1191),
            cropBox: PDFRect(x: 10, y: 10, width: 822, height: 1171),
            bleedBox: PDFRect(x: 5, y: 5, width: 832, height: 1181),
            trimBox: PDFRect(x: 15, y: 15, width: 812, height: 1161),
            artBox: PDFRect(x: 20, y: 20, width: 802, height: 1151),
            rotation: 90,
            userUnit: 2.0,
            hasResources: true,
            hasContentStreams: true,
            hasAnnotations: true,
            fontCount: 3,
            xObjectCount: 2,
            colorSpaceCount: 1,
            extGStateCount: 1,
            patternCount: 1,
            shadingCount: 0,
            annotationCount: 4,
            fontResources: [ASAtom("F1"): fontDict],
            contentStreams: [cs],
            hasTransparencyGroup: true,
            transparencyGroupColorSpace: ASAtom("DeviceRGB")
        )

        #expect(page.cosDictionary != nil)
        #expect(page.objectKey == objectKey)
        #expect(page.pageNumber == 3)
        #expect(page.pageLabel == "iii")
        #expect(page.mediaBox.width == 842)
        #expect(page.cropBox != nil)
        #expect(page.bleedBox != nil)
        #expect(page.trimBox != nil)
        #expect(page.artBox != nil)
        #expect(page.rotation == 90)
        #expect(page.userUnit == 2.0)
        #expect(page.hasContentStreams == true)
        #expect(page.hasAnnotations == true)
        #expect(page.fontCount == 3)
        #expect(page.xObjectCount == 2)
        #expect(page.annotationCount == 4)
        #expect(page.contentStreams.count == 1)
        #expect(page.hasTransparencyGroup == true)
        #expect(page.transparencyGroupColorSpace == ASAtom("DeviceRGB"))
    }

    // MARK: - PDFObject Conformance Tests

    @Test("Object type is PDPage")
    func objectType() {
        let page = ValidatedPage()
        #expect(page.objectType == "PDPage")
    }

    @Test("Property names list is complete")
    func propertyNamesList() {
        let page = ValidatedPage()
        let names = page.propertyNames
        #expect(names.contains("pageNumber"))
        #expect(names.contains("mediaBox"))
        #expect(names.contains("rotation"))
        #expect(names.contains("hasResources"))
        #expect(names.contains("fontCount"))
        #expect(names.contains("annotationCount"))
        #expect(names.contains("hasTransparencyGroup"))
    }

    // MARK: - Property Access Tests

    @Test("Property access - pageNumber")
    func propertyPageNumber() {
        let page = ValidatedPage(pageNumber: 7)
        #expect(page.property(named: "pageNumber")?.integerValue == 7)
    }

    @Test("Property access - pageLabel present")
    func propertyPageLabelPresent() {
        let page = ValidatedPage(pageLabel: "iv")
        #expect(page.property(named: "pageLabel")?.stringValue == "iv")
    }

    @Test("Property access - pageLabel absent")
    func propertyPageLabelAbsent() {
        let page = ValidatedPage()
        #expect(page.property(named: "pageLabel")?.isNull == true)
    }

    @Test("Property access - rotation")
    func propertyRotation() {
        let page = ValidatedPage(rotation: 270)
        #expect(page.property(named: "rotation")?.integerValue == 270)
    }

    @Test("Property access - userUnit")
    func propertyUserUnit() {
        let page = ValidatedPage(userUnit: 3.0)
        #expect(page.property(named: "userUnit")?.realValue == 3.0)
    }

    @Test("Property access - boolean properties")
    func propertyBooleans() {
        let page = ValidatedPage(
            hasResources: true,
            hasContentStreams: true,
            hasAnnotations: true,
            hasTransparencyGroup: true
        )
        #expect(page.property(named: "hasResources")?.boolValue == true)
        #expect(page.property(named: "hasContentStreams")?.boolValue == true)
        #expect(page.property(named: "hasAnnotations")?.boolValue == true)
        #expect(page.property(named: "hasTransparencyGroup")?.boolValue == true)
    }

    @Test("Property access - count properties")
    func propertyCounts() {
        let page = ValidatedPage(
            fontCount: 5,
            xObjectCount: 3,
            colorSpaceCount: 2,
            extGStateCount: 1,
            patternCount: 4,
            shadingCount: 0,
            annotationCount: 7
        )
        #expect(page.property(named: "fontCount")?.integerValue == 5)
        #expect(page.property(named: "xObjectCount")?.integerValue == 3)
        #expect(page.property(named: "colorSpaceCount")?.integerValue == 2)
        #expect(page.property(named: "extGStateCount")?.integerValue == 1)
        #expect(page.property(named: "patternCount")?.integerValue == 4)
        #expect(page.property(named: "shadingCount")?.integerValue == 0)
        #expect(page.property(named: "annotationCount")?.integerValue == 7)
    }

    @Test("Property access - mediaBox as string")
    func propertyMediaBox() {
        let page = ValidatedPage(mediaBox: PDFRect(width: 612, height: 792))
        let value = page.property(named: "mediaBox")
        #expect(value?.stringValue != nil)
    }

    @Test("Property access - cropBox null when absent")
    func propertyCropBoxNull() {
        let page = ValidatedPage()
        #expect(page.property(named: "cropBox")?.isNull == true)
    }

    @Test("Property access - cropBox present")
    func propertyCropBoxPresent() {
        let page = ValidatedPage(cropBox: PDFRect(width: 600, height: 780))
        let value = page.property(named: "cropBox")
        #expect(value?.isNull != true)
    }

    @Test("Property access - transparencyGroupColorSpace")
    func propertyTransparencyGroupCS() {
        let page = ValidatedPage(transparencyGroupColorSpace: ASAtom("DeviceCMYK"))
        let value = page.property(named: "transparencyGroupColorSpace")
        #expect(value?.stringValue == "DeviceCMYK")
    }

    @Test("Property access - transparencyGroupColorSpace null")
    func propertyTransparencyGroupCSNull() {
        let page = ValidatedPage()
        #expect(page.property(named: "transparencyGroupColorSpace")?.isNull == true)
    }

    @Test("Property access - unknown property returns nil")
    func propertyUnknown() {
        let page = ValidatedPage()
        #expect(page.property(named: "nonExistent") == nil)
    }

    // MARK: - ResourceResolver Tests

    @Test("Resolve font resource")
    func resolveFontResource() {
        let fontDict: COSValue = .dictionary([.type: .name(.font)])
        let page = ValidatedPage(fontResources: [ASAtom("F1"): fontDict])
        #expect(page.resolveFont(named: ASAtom("F1")) != nil)
        #expect(page.resolveFont(named: ASAtom("F2")) == nil)
    }

    @Test("Resolve XObject resource")
    func resolveXObjectResource() {
        let xObj: COSValue = .dictionary([.subtype: .name(ASAtom("Image"))])
        let page = ValidatedPage(xObjectResources: [ASAtom("Im1"): xObj])
        #expect(page.resolveXObject(named: ASAtom("Im1")) != nil)
        #expect(page.resolveXObject(named: ASAtom("Im2")) == nil)
    }

    @Test("Resolve color space resource")
    func resolveColorSpaceResource() {
        let cs: COSValue = .name(ASAtom("DeviceRGB"))
        let page = ValidatedPage(colorSpaceResources: [ASAtom("CS0"): cs])
        #expect(page.resolveColorSpace(named: ASAtom("CS0")) != nil)
    }

    @Test("Resolve ExtGState resource")
    func resolveExtGStateResource() {
        let gs: COSValue = .dictionary([:])
        let page = ValidatedPage(extGStateResources: [ASAtom("GS0"): gs])
        #expect(page.resolveExtGState(named: ASAtom("GS0")) != nil)
    }

    @Test("Resolve pattern resource")
    func resolvePatternResource() {
        let pat: COSValue = .dictionary([:])
        let page = ValidatedPage(patternResources: [ASAtom("P0"): pat])
        #expect(page.resolvePattern(named: ASAtom("P0")) != nil)
    }

    @Test("Resolve shading resource")
    func resolveShadingResource() {
        let sh: COSValue = .dictionary([:])
        let page = ValidatedPage(shadingResources: [ASAtom("Sh0"): sh])
        #expect(page.resolveShading(named: ASAtom("Sh0")) != nil)
    }

    @Test("Resolve properties resource")
    func resolvePropertiesResource() {
        let props: COSValue = .dictionary([:])
        let page = ValidatedPage(propertiesResources: [ASAtom("MC0"): props])
        #expect(page.resolveProperties(named: ASAtom("MC0")) != nil)
    }

    // MARK: - Computed Property Tests

    @Test("effectiveCropBox defaults to mediaBox")
    func effectiveCropBoxDefault() {
        let page = ValidatedPage(mediaBox: PDFRect(width: 612, height: 792))
        #expect(page.effectiveCropBox == page.mediaBox)
    }

    @Test("effectiveCropBox uses cropBox when present")
    func effectiveCropBoxPresent() {
        let crop = PDFRect(x: 10, y: 10, width: 592, height: 772)
        let page = ValidatedPage(mediaBox: .letter, cropBox: crop)
        #expect(page.effectiveCropBox == crop)
    }

    @Test("totalResourceCount sums all resource types")
    func totalResourceCount() {
        let page = ValidatedPage(
            fontCount: 3,
            xObjectCount: 2,
            colorSpaceCount: 1,
            extGStateCount: 1,
            patternCount: 1,
            shadingCount: 1
        )
        #expect(page.totalResourceCount == 9)
    }

    @Test("hasAnyResources when resources exist")
    func hasAnyResourcesTrue() {
        let page = ValidatedPage(fontCount: 1)
        #expect(page.hasAnyResources == true)
    }

    @Test("hasAnyResources when no resources")
    func hasAnyResourcesFalse() {
        let page = ValidatedPage()
        #expect(page.hasAnyResources == false)
    }

    @Test("isValidRotation for valid values")
    func isValidRotation() {
        #expect(ValidatedPage(rotation: 0).isValidRotation == true)
        #expect(ValidatedPage(rotation: 90).isValidRotation == true)
        #expect(ValidatedPage(rotation: 180).isValidRotation == true)
        #expect(ValidatedPage(rotation: 270).isValidRotation == true)
    }

    @Test("isValidRotation for invalid values")
    func isInvalidRotation() {
        #expect(ValidatedPage(rotation: 45).isValidRotation == false)
        #expect(ValidatedPage(rotation: -90).isValidRotation == false)
        #expect(ValidatedPage(rotation: 360).isValidRotation == false)
    }

    @Test("effectiveWidth and height without rotation")
    func effectiveDimensionsNoRotation() {
        let page = ValidatedPage(mediaBox: PDFRect(width: 612, height: 792))
        #expect(page.effectiveWidth == 612)
        #expect(page.effectiveHeight == 792)
    }

    @Test("effectiveWidth and height with 90 degree rotation")
    func effectiveDimensions90() {
        let page = ValidatedPage(mediaBox: PDFRect(width: 612, height: 792), rotation: 90)
        #expect(page.effectiveWidth == 792)
        #expect(page.effectiveHeight == 612)
    }

    @Test("effectiveWidth and height with 270 degree rotation")
    func effectiveDimensions270() {
        let page = ValidatedPage(mediaBox: PDFRect(width: 612, height: 792), rotation: 270)
        #expect(page.effectiveWidth == 792)
        #expect(page.effectiveHeight == 612)
    }

    @Test("effectiveWidth accounts for userUnit")
    func effectiveWidthWithUserUnit() {
        let page = ValidatedPage(
            mediaBox: PDFRect(width: 612, height: 792),
            userUnit: 2.0
        )
        #expect(page.effectiveWidth == 1224)
        #expect(page.effectiveHeight == 1584)
    }

    @Test("Summary string includes key info")
    func summaryString() {
        let page = ValidatedPage(
            pageNumber: 5,
            pageLabel: "v",
            mediaBox: PDFRect(width: 595, height: 842),
            rotation: 90,
            hasAnnotations: true,
            annotationCount: 3
        )
        let summary = page.summary
        #expect(summary.contains("Page 5"))
        #expect(summary.contains("595x842"))
        #expect(summary.contains("rotated 90deg"))
        #expect(summary.contains("3 annots"))
        #expect(summary.contains("label=v"))
    }

    // MARK: - Equatable Tests

    @Test("Pages with same ID are equal")
    func equalityById() {
        let id = UUID()
        let page1 = ValidatedPage(id: id, pageNumber: 1)
        let page2 = ValidatedPage(id: id, pageNumber: 2)
        #expect(page1 == page2)
    }

    @Test("Pages with different IDs are not equal")
    func inequalityById() {
        let page1 = ValidatedPage(pageNumber: 1)
        let page2 = ValidatedPage(pageNumber: 1)
        #expect(page1 != page2)
    }

    // MARK: - Factory Tests

    @Test("Minimal factory creates a basic page")
    func minimalFactory() {
        let page = ValidatedPage.minimal(pageNumber: 3, mediaBox: .a4)
        #expect(page.pageNumber == 3)
        #expect(page.mediaBox == .a4)
    }

    @Test("Minimal factory defaults")
    func minimalFactoryDefaults() {
        let page = ValidatedPage.minimal()
        #expect(page.pageNumber == 1)
        #expect(page.mediaBox == .letter)
    }

    // MARK: - Context Tests

    @Test("Default context uses page number")
    func defaultContextUsesPageNumber() {
        let page = ValidatedPage(pageNumber: 5)
        #expect(page.validationContext.pageNumber == 5)
        #expect(page.validationContext.location == "Page")
    }

    @Test("Custom context overrides default")
    func customContextOverridesDefault() {
        let ctx = ObjectContext(pageNumber: 10, location: "CustomPage")
        let page = ValidatedPage(context: ctx, pageNumber: 5)
        #expect(page.validationContext.pageNumber == 10)
        #expect(page.validationContext.location == "CustomPage")
    }

    // MARK: - Sendable Tests

    @Test("ValidatedPage is Sendable")
    func isSendable() {
        let page = ValidatedPage.minimal()
        let sendableRef: any Sendable = page
        #expect(sendableRef is ValidatedPage)
    }
}
