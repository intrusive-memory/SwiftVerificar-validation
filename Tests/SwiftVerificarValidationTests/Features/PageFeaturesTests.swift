import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - PageFeatures Tests

@Suite("PageFeatures Tests")
struct PageFeaturesTests {

    // MARK: - Initialization

    @Test("PageFeatures creates with minimal parameters")
    func minimalInit() {
        let features = PageFeatures(pageNumber: 1, mediaBox: .letter)

        #expect(features.pageNumber == 1)
        #expect(features.pageLabel == nil)
        #expect(features.rotation == 0)
        #expect(features.userUnit == 1.0)
        #expect(features.fonts.isEmpty)
        #expect(features.xObjects.isEmpty)
        #expect(features.annotations.isEmpty)
    }

    @Test("PageFeatures creates with all parameters")
    func fullInit() {
        let fonts = [FontInfo(name: "F1", subtype: "Type1")]
        let xObjects = [XObjectInfo(name: "Im1", subtype: "Image")]
        let colorSpaces = [ColorSpaceInfo(name: "CS1", family: "DeviceRGB", numComponents: 3)]
        let annotations = [AnnotationInfo(subtype: "Link")]

        let features = PageFeatures(
            pageNumber: 5,
            pageLabel: "v",
            mediaBox: PDFRect(x: 0, y: 0, width: 612, height: 792),
            cropBox: PDFRect(x: 18, y: 18, width: 576, height: 756),
            bleedBox: PDFRect(x: 9, y: 9, width: 594, height: 774),
            trimBox: PDFRect(x: 18, y: 18, width: 576, height: 756),
            artBox: PDFRect(x: 36, y: 36, width: 540, height: 720),
            rotation: 90,
            userUnit: 2.0,
            fonts: fonts,
            xObjects: xObjects,
            colorSpaces: colorSpaces,
            extGStates: [],
            patterns: [],
            shadings: [],
            contentStreamCount: 2,
            hasTransparency: true,
            usesSpotColors: true,
            annotations: annotations,
            hasFormFields: true,
            hasLinks: true,
            isTagged: true,
            structureElementCount: 10
        )

        #expect(features.pageNumber == 5)
        #expect(features.pageLabel == "v")
        #expect(features.rotation == 90)
        #expect(features.userUnit == 2.0)
        #expect(features.fonts.count == 1)
        #expect(features.xObjects.count == 1)
        #expect(features.colorSpaces.count == 1)
        #expect(features.annotations.count == 1)
        #expect(features.contentStreamCount == 2)
        #expect(features.hasTransparency == true)
        #expect(features.usesSpotColors == true)
        #expect(features.hasFormFields == true)
        #expect(features.hasLinks == true)
        #expect(features.isTagged == true)
        #expect(features.structureElementCount == 10)
    }

    // MARK: - Computed Properties

    @Test("PageFeatures effective crop box")
    func effectiveCropBox() {
        let features1 = PageFeatures(pageNumber: 1, mediaBox: .letter)
        #expect(features1.effectiveCropBox == .letter)

        let cropBox = PDFRect(x: 10, y: 10, width: 500, height: 700)
        let features2 = PageFeatures(pageNumber: 1, mediaBox: .letter, cropBox: cropBox)
        #expect(features2.effectiveCropBox == cropBox)
    }

    @Test("PageFeatures dimensions")
    func dimensions() {
        let features = PageFeatures(pageNumber: 1, mediaBox: .letter)

        #expect(features.width == 612)
        #expect(features.height == 792)
    }

    @Test("PageFeatures dimensions in inches")
    func dimensionsInInches() {
        let features = PageFeatures(pageNumber: 1, mediaBox: .letter)

        #expect(features.widthInches == 8.5)
        #expect(features.heightInches == 11.0)
    }

    @Test("PageFeatures dimensions in millimeters")
    func dimensionsInMM() {
        let features = PageFeatures(pageNumber: 1, mediaBox: .a4)

        // A4 is approximately 210mm x 297mm
        #expect(features.widthMM > 209 && features.widthMM < 211)
        #expect(features.heightMM > 296 && features.heightMM < 298)
    }

    @Test("PageFeatures resource count")
    func resourceCount() {
        let features = PageFeatures(
            pageNumber: 1,
            mediaBox: .letter,
            fonts: [FontInfo(name: "F1", subtype: "Type1")],
            xObjects: [XObjectInfo(name: "Im1", subtype: "Image")],
            colorSpaces: [ColorSpaceInfo(name: "CS1", family: "DeviceRGB", numComponents: 3)]
        )

        #expect(features.resourceCount == 3)
    }

    @Test("PageFeatures annotation count")
    func annotationCount() {
        let annotations = [
            AnnotationInfo(subtype: "Link"),
            AnnotationInfo(subtype: "Text"),
            AnnotationInfo(subtype: "Highlight")
        ]
        let features = PageFeatures(pageNumber: 1, mediaBox: .letter, annotations: annotations)

        #expect(features.annotationCount == 3)
    }

    @Test("PageFeatures landscape detection")
    func isLandscape() {
        let portrait = PageFeatures(pageNumber: 1, mediaBox: .letter)
        #expect(portrait.isLandscape == false)

        let landscape = PageFeatures(
            pageNumber: 1,
            mediaBox: PDFRect(width: 792, height: 612)
        )
        #expect(landscape.isLandscape == true)

        let rotated90 = PageFeatures(pageNumber: 1, mediaBox: .letter, rotation: 90)
        #expect(rotated90.isLandscape == true)

        let rotated270 = PageFeatures(pageNumber: 1, mediaBox: .letter, rotation: 270)
        #expect(rotated270.isLandscape == true)
    }

    @Test("PageFeatures image count")
    func imageCount() {
        let xObjects = [
            XObjectInfo(name: "Im1", subtype: "Image"),
            XObjectInfo(name: "Im2", subtype: "Image"),
            XObjectInfo(name: "Fm1", subtype: "Form")
        ]
        let features = PageFeatures(pageNumber: 1, mediaBox: .letter, xObjects: xObjects)

        #expect(features.imageCount == 2)
        #expect(features.formXObjectCount == 1)
    }

    // MARK: - Conversion to FeatureNode

    @Test("PageFeatures converts to FeatureNode")
    func toFeatureNode() {
        let features = PageFeatures(
            pageNumber: 3,
            pageLabel: "iii",
            mediaBox: .letter,
            rotation: 90,
            hasTransparency: true
        )

        let node = features.toFeatureNode()

        #expect(node.featureType == .page)
        #expect(node.name == "iii")
        #expect(node.intValue(for: "pageNumber") == 3)
        #expect(node.intValue(for: "rotation") == 90)
        #expect(node.boolValue(for: "hasTransparency") == true)
        #expect(node.doubleValue(for: "mediaBoxWidth") == 612)
    }

    @Test("PageFeatures FeatureNode includes children")
    func featureNodeIncludesChildren() {
        let features = PageFeatures(
            pageNumber: 1,
            mediaBox: .letter,
            fonts: [FontInfo(name: "F1", subtype: "Type1")],
            xObjects: [XObjectInfo(name: "Im1", subtype: "Image")],
            annotations: [AnnotationInfo(subtype: "Link")]
        )

        let node = features.toFeatureNode()

        #expect(node.children.count == 3)
        #expect(node.children(ofType: .font).count == 1)
        #expect(node.children(ofType: .image).count == 1)
        #expect(node.children(ofType: .annotation).count == 1)
    }

    // MARK: - Equatable

    @Test("PageFeatures is equatable")
    func equatable() {
        let features1 = PageFeatures(id: UUID(), pageNumber: 1, mediaBox: .letter)
        let features2 = features1  // Same instance
        let features3 = PageFeatures(pageNumber: 1, mediaBox: .letter)  // Different ID

        #expect(features1 == features2)
        #expect(features1 != features3)
    }

    // MARK: - CustomStringConvertible

    @Test("PageFeatures description")
    func description() {
        let features = PageFeatures(
            pageNumber: 5,
            pageLabel: "v",
            mediaBox: .letter,
            rotation: 90,
            fonts: [FontInfo(name: "F1", subtype: "Type1")],
            annotations: [AnnotationInfo(subtype: "Link")]
        )

        let desc = features.description
        #expect(desc.contains("v"))
        #expect(desc.contains("612x792"))
        #expect(desc.contains("rot:90"))
        #expect(desc.contains("1 fonts"))
        #expect(desc.contains("1 annotations"))
    }
}

// MARK: - PDFRect Tests

@Suite("PDFRect Tests")
struct PDFRectTests {

    @Test("PDFRect creates with dimensions")
    func initWithDimensions() {
        let rect = PDFRect(x: 10, y: 20, width: 100, height: 200)

        #expect(rect.x == 10)
        #expect(rect.y == 20)
        #expect(rect.width == 100)
        #expect(rect.height == 200)
    }

    @Test("PDFRect creates from array")
    func initFromArray() {
        let rect = PDFRect(array: [0, 0, 612, 792])

        #expect(rect != nil)
        #expect(rect?.x == 0)
        #expect(rect?.y == 0)
        #expect(rect?.width == 612)
        #expect(rect?.height == 792)
    }

    @Test("PDFRect array init fails for invalid array")
    func initFromArrayFailsForInvalid() {
        #expect(PDFRect(array: [0, 0, 612]) == nil)
        #expect(PDFRect(array: []) == nil)
        #expect(PDFRect(array: [0, 0, 612, 792, 100]) == nil)
    }

    @Test("PDFRect common page sizes")
    func commonPageSizes() {
        #expect(PDFRect.letter.width == 612)
        #expect(PDFRect.letter.height == 792)

        #expect(PDFRect.legal.width == 612)
        #expect(PDFRect.legal.height == 1008)

        #expect(PDFRect.a4.width == 595)
        #expect(PDFRect.a4.height == 842)

        #expect(PDFRect.a3.width == 842)
        #expect(PDFRect.a3.height == 1191)
    }

    @Test("PDFRect area calculation")
    func areaCalculation() {
        let rect = PDFRect(width: 100, height: 50)
        #expect(rect.area == 5000)
    }

    @Test("PDFRect is equatable")
    func equatable() {
        let rect1 = PDFRect(x: 0, y: 0, width: 100, height: 200)
        let rect2 = PDFRect(x: 0, y: 0, width: 100, height: 200)
        let rect3 = PDFRect(x: 0, y: 0, width: 100, height: 300)

        #expect(rect1 == rect2)
        #expect(rect1 != rect3)
    }

    @Test("PDFRect is hashable")
    func hashable() {
        let rects: Set<PDFRect> = [.letter, .letter, .a4]
        #expect(rects.count == 2)
    }

    @Test("PDFRect description")
    func description() {
        let rect = PDFRect(x: 10, y: 20, width: 100, height: 200)
        let desc = rect.description

        #expect(desc.contains("10"))
        #expect(desc.contains("20"))
        #expect(desc.contains("110"))  // x + width
        #expect(desc.contains("220"))  // y + height
    }
}

// MARK: - FontInfo Tests

@Suite("FontInfo Tests")
struct FontInfoTests {

    @Test("FontInfo creates with all properties")
    func fullInit() {
        let fontInfo = FontInfo(
            name: "F1",
            subtype: "TrueType",
            baseFont: "Helvetica-Bold",
            encoding: "WinAnsiEncoding",
            isEmbedded: true,
            isSubset: true,
            toUnicode: true
        )

        #expect(fontInfo.name == "F1")
        #expect(fontInfo.subtype == "TrueType")
        #expect(fontInfo.baseFont == "Helvetica-Bold")
        #expect(fontInfo.encoding == "WinAnsiEncoding")
        #expect(fontInfo.isEmbedded == true)
        #expect(fontInfo.isSubset == true)
        #expect(fontInfo.toUnicode == true)
    }

    @Test("FontInfo converts to FeatureNode")
    func toFeatureNode() {
        let fontInfo = FontInfo(
            name: "F1",
            subtype: "Type1",
            isEmbedded: true
        )

        let node = fontInfo.toFeatureNode()

        #expect(node.featureType == .font)
        #expect(node.name == "F1")
        #expect(node.stringValue(for: "name") == "F1")
        #expect(node.stringValue(for: "subtype") == "Type1")
        #expect(node.boolValue(for: "isEmbedded") == true)
    }
}

// MARK: - XObjectInfo Tests

@Suite("XObjectInfo Tests")
struct XObjectInfoTests {

    @Test("XObjectInfo creates for image")
    func imageInit() {
        let xObject = XObjectInfo(
            name: "Im1",
            subtype: "Image",
            width: 800,
            height: 600,
            bitsPerComponent: 8,
            colorSpace: "DeviceRGB",
            filter: "DCTDecode"
        )

        #expect(xObject.name == "Im1")
        #expect(xObject.subtype == "Image")
        #expect(xObject.width == 800)
        #expect(xObject.height == 600)
        #expect(xObject.bitsPerComponent == 8)
        #expect(xObject.colorSpace == "DeviceRGB")
        #expect(xObject.filter == "DCTDecode")
    }

    @Test("XObjectInfo converts to FeatureNode for image")
    func toFeatureNodeImage() {
        let xObject = XObjectInfo(name: "Im1", subtype: "Image", width: 100, height: 100)
        let node = xObject.toFeatureNode()

        #expect(node.featureType == .image)
        #expect(node.name == "Im1")
    }

    @Test("XObjectInfo converts to FeatureNode for form")
    func toFeatureNodeForm() {
        let xObject = XObjectInfo(name: "Fm1", subtype: "Form")
        let node = xObject.toFeatureNode()

        #expect(node.featureType == .object)
        #expect(node.name == "Fm1")
    }
}

// MARK: - ColorSpaceInfo Tests

@Suite("ColorSpaceInfo Tests")
struct ColorSpaceInfoTests {

    @Test("ColorSpaceInfo creates with all properties")
    func fullInit() {
        let csInfo = ColorSpaceInfo(
            name: "CS1",
            family: "ICCBased",
            numComponents: 4,
            iccProfileName: "U.S. Web Coated (SWOP) v2"
        )

        #expect(csInfo.name == "CS1")
        #expect(csInfo.family == "ICCBased")
        #expect(csInfo.numComponents == 4)
        #expect(csInfo.iccProfileName == "U.S. Web Coated (SWOP) v2")
    }

    @Test("ColorSpaceInfo converts to FeatureNode")
    func toFeatureNode() {
        let csInfo = ColorSpaceInfo(name: "CS1", family: "DeviceRGB", numComponents: 3)
        let node = csInfo.toFeatureNode()

        #expect(node.featureType == .colorSpace)
        #expect(node.name == "CS1")
        #expect(node.stringValue(for: "family") == "DeviceRGB")
        #expect(node.intValue(for: "numComponents") == 3)
    }
}

// MARK: - AnnotationInfo Tests

@Suite("AnnotationInfo Tests")
struct AnnotationInfoTests {

    @Test("AnnotationInfo creates with all properties")
    func fullInit() {
        let annotInfo = AnnotationInfo(
            subtype: "Link",
            contents: "Click here",
            isVisible: true,
            isPrintable: false,
            hasAppearance: true
        )

        #expect(annotInfo.subtype == "Link")
        #expect(annotInfo.contents == "Click here")
        #expect(annotInfo.isVisible == true)
        #expect(annotInfo.isPrintable == false)
        #expect(annotInfo.hasAppearance == true)
    }

    @Test("AnnotationInfo converts to FeatureNode")
    func toFeatureNode() {
        let annotInfo = AnnotationInfo(subtype: "Text", contents: "Note")
        let node = annotInfo.toFeatureNode()

        #expect(node.featureType == .annotation)
        #expect(node.name == "Text")
        #expect(node.stringValue(for: "subtype") == "Text")
        #expect(node.stringValue(for: "contents") == "Note")
    }
}
