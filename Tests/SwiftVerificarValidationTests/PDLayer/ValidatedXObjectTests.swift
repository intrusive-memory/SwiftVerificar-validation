import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - XObject Subtype Tests

@Suite("XObjectSubtype Tests")
struct XObjectSubtypeTests {

    @Test("Raw values match PDF specification")
    func rawValues() {
        #expect(XObjectSubtype.image.rawValue == "Image")
        #expect(XObjectSubtype.form.rawValue == "Form")
        #expect(XObjectSubtype.postScript.rawValue == "PS")
        #expect(XObjectSubtype.unknown.rawValue == "Unknown")
    }

    @Test("Creates subtype from valid string")
    func fromValidString() {
        #expect(XObjectSubtype(fromString: "Image") == .image)
        #expect(XObjectSubtype(fromString: "Form") == .form)
        #expect(XObjectSubtype(fromString: "PS") == .postScript)
    }

    @Test("Creates unknown for invalid string")
    func fromInvalidString() {
        #expect(XObjectSubtype(fromString: "Invalid") == .unknown)
        #expect(XObjectSubtype(fromString: nil) == .unknown)
    }

    @Test("CaseIterable conformance")
    func caseIterable() {
        #expect(XObjectSubtype.allCases.count == 4)
    }
}

// MARK: - Validated XObject Tests

@Suite("ValidatedXObject Tests")
struct ValidatedXObjectTests {

    @Test("Default initialization")
    func defaultInit() {
        let xobj = ValidatedXObject()
        #expect(xobj.subtype == .image)
        #expect(xobj.subtypeName == "Image")
        #expect(xobj.structParent == nil)
        #expect(xobj.hasOPI == false)
        #expect(xobj.width == nil)
        #expect(xobj.height == nil)
        #expect(xobj.isImageMask == false)
        #expect(xobj.hasSoftMask == false)
        #expect(xobj.filters.isEmpty)
        #expect(xobj.isImage == true)
        #expect(xobj.isForm == false)
        #expect(xobj.objectType == "PDXImage")
    }

    @Test("Image XObject factory")
    func imageFactory() {
        let img = ValidatedXObject.image(width: 800, height: 600, colorSpaceName: "DeviceRGB")
        #expect(img.isImage == true)
        #expect(img.width == 800)
        #expect(img.height == 600)
        #expect(img.colorSpaceName == "DeviceRGB")
        #expect(img.colorComponentCount == 3)
        #expect(img.bitsPerComponent == 8)
        #expect(img.pixelCount == 480000)
        #expect(img.objectType == "PDXImage")
    }

    @Test("Image XObject with grayscale")
    func imageGrayscale() {
        let img = ValidatedXObject.image(colorSpaceName: "DeviceGray")
        #expect(img.colorComponentCount == 1)
    }

    @Test("Image XObject with CMYK")
    func imageCMYK() {
        let img = ValidatedXObject.image(colorSpaceName: "DeviceCMYK")
        #expect(img.colorComponentCount == 4)
    }

    @Test("Form XObject factory")
    func formFactory() {
        let form = ValidatedXObject.form()
        #expect(form.isForm == true)
        #expect(form.isImage == false)
        #expect(form.formBBox != nil)
        #expect(form.hasResources == true)
        #expect(form.hasContentStream == true)
        #expect(form.isTransparencyGroup == false)
        #expect(form.objectType == "PDXForm")
    }

    @Test("Form XObject with transparency group")
    func formTransparencyGroup() {
        let form = ValidatedXObject.form(isTransparencyGroup: true)
        #expect(form.isTransparencyGroup == true)
        #expect(form.involvesTransparency == true)
    }

    @Test("Image mask factory")
    func imageMaskFactory() {
        let mask = ValidatedXObject.imageMask()
        #expect(mask.isImageMask == true)
        #expect(mask.bitsPerComponent == 1)
        #expect(mask.width == 100)
        #expect(mask.height == 100)
    }

    @Test("PostScript XObject")
    func postScriptXObject() {
        let ps = ValidatedXObject(subtypeName: "PS")
        #expect(ps.isPostScript == true)
        #expect(ps.isImage == false)
        #expect(ps.isForm == false)
        #expect(ps.objectType == "PDXObject")
    }

    @Test("Unknown subtype object type")
    func unknownSubtype() {
        let unknown = ValidatedXObject(subtypeName: "Invalid")
        #expect(unknown.subtype == .unknown)
        #expect(unknown.objectType == "PDXObject")
    }

    @Test("Structure parent")
    func structParent() {
        let withSP = ValidatedXObject(structParent: 5)
        #expect(withSP.hasStructParent == true)
        #expect(withSP.structParent == 5)

        let withoutSP = ValidatedXObject()
        #expect(withoutSP.hasStructParent == false)
    }

    @Test("Filter detection")
    func filterDetection() {
        let jpx = ValidatedXObject(filters: ["JPXDecode"])
        #expect(jpx.usesJPXFilter == true)
        #expect(jpx.usesJBIG2Filter == false)
        #expect(jpx.usesDCTFilter == false)

        let jbig2 = ValidatedXObject(filters: ["JBIG2Decode"])
        #expect(jbig2.usesJBIG2Filter == true)

        let dct = ValidatedXObject(filters: ["DCTDecode"])
        #expect(dct.usesDCTFilter == true)

        let multi = ValidatedXObject(filters: ["FlateDecode", "DCTDecode"])
        #expect(multi.usesDCTFilter == true)
        #expect(multi.usesJPXFilter == false)
    }

    @Test("Transparency involvement")
    func transparencyInvolvement() {
        let noTransp = ValidatedXObject()
        #expect(noTransp.involvesTransparency == false)

        let softMask = ValidatedXObject(hasSoftMask: true)
        #expect(softMask.involvesTransparency == true)

        let transpGroup = ValidatedXObject(subtypeName: "Form", isTransparencyGroup: true)
        #expect(transpGroup.involvesTransparency == true)

        let isolated = ValidatedXObject(subtypeName: "Form", isIsolated: true)
        #expect(isolated.involvesTransparency == true)

        let knockout = ValidatedXObject(subtypeName: "Form", isKnockout: true)
        #expect(knockout.involvesTransparency == true)
    }

    @Test("Full image initialization")
    func fullImageInit() {
        let img = ValidatedXObject(
            subtypeName: "Image",
            structParent: 3,
            width: 1920,
            height: 1080,
            bitsPerComponent: 8,
            colorSpaceName: "ICCBased",
            colorComponentCount: 3,
            hasMask: true,
            hasAlternates: true,
            filters: ["FlateDecode"],
            hasICCProfile: true,
            interpolate: true
        )
        #expect(img.structParent == 3)
        #expect(img.width == 1920)
        #expect(img.height == 1080)
        #expect(img.hasMask == true)
        #expect(img.hasAlternates == true)
        #expect(img.hasICCProfile == true)
        #expect(img.interpolate == true)
        #expect(img.pixelCount == 2073600)
    }

    @Test("Full form initialization")
    func fullFormInit() {
        let form = ValidatedXObject(
            subtypeName: "Form",
            hasOPI: true,
            formBBox: PDFRect(x: 0, y: 0, width: 200, height: 300),
            hasMatrix: true,
            hasResources: true,
            isTransparencyGroup: true,
            groupColorSpace: "DeviceRGB",
            isIsolated: true,
            isKnockout: false,
            hasContentStream: true,
            hasMetadata: true
        )
        #expect(form.hasOPI == true)
        #expect(form.hasMatrix == true)
        #expect(form.isTransparencyGroup == true)
        #expect(form.groupColorSpace == "DeviceRGB")
        #expect(form.isIsolated == true)
        #expect(form.isKnockout == false)
        #expect(form.hasMetadata == true)
    }

    @Test("Pixel count returns nil for forms")
    func pixelCountNil() {
        let form = ValidatedXObject.form()
        #expect(form.pixelCount == nil)
    }

    @Test("Property access for image")
    func imagePropertyAccess() {
        let img = ValidatedXObject.image(width: 100, height: 200)
        #expect(img.property(named: "subtype")?.stringValue == "Image")
        #expect(img.property(named: "width")?.integerValue == 100)
        #expect(img.property(named: "height")?.integerValue == 200)
        #expect(img.property(named: "bitsPerComponent")?.integerValue == 8)
        #expect(img.property(named: "colorSpaceName")?.stringValue == "DeviceRGB")
        #expect(img.property(named: "isImage")?.boolValue == true)
        #expect(img.property(named: "isForm")?.boolValue == false)
        #expect(img.property(named: "isPostScript")?.boolValue == false)
        #expect(img.property(named: "usesJPXFilter")?.boolValue == false)
        #expect(img.property(named: "involvesTransparency")?.boolValue == false)
        #expect(img.property(named: "nonexistent") == nil)
    }

    @Test("Property access for form")
    func formPropertyAccess() {
        let form = ValidatedXObject.form(isTransparencyGroup: true)
        #expect(form.property(named: "isForm")?.boolValue == true)
        #expect(form.property(named: "isTransparencyGroup")?.boolValue == true)
        #expect(form.property(named: "hasResources")?.boolValue == true)
        #expect(form.property(named: "hasContentStream")?.boolValue == true)
    }

    @Test("Null property values for absent optional fields")
    func nullProperties() {
        let xobj = ValidatedXObject()
        #expect(xobj.property(named: "structParent")?.isNull == true)
        #expect(xobj.property(named: "width")?.isNull == true)
        #expect(xobj.property(named: "height")?.isNull == true)
        #expect(xobj.property(named: "bitsPerComponent")?.isNull == true)
        #expect(xobj.property(named: "colorSpaceName")?.isNull == true)
        #expect(xobj.property(named: "colorComponentCount")?.isNull == true)
        #expect(xobj.property(named: "formBBox")?.isNull == true)
        #expect(xobj.property(named: "groupColorSpace")?.isNull == true)
    }

    @Test("Filters as comma-separated string")
    func filtersProperty() {
        let multi = ValidatedXObject(filters: ["FlateDecode", "DCTDecode"])
        #expect(multi.property(named: "filters")?.stringValue == "FlateDecode,DCTDecode")

        let empty = ValidatedXObject(filters: [])
        #expect(empty.property(named: "filters")?.stringValue == "")
    }

    @Test("Summary description")
    func summary() {
        let img = ValidatedXObject.image(width: 800, height: 600)
        let s = img.summary
        #expect(s.contains("Image"))
        #expect(s.contains("800x600"))
        #expect(s.contains("DeviceRGB"))

        let form = ValidatedXObject.form(isTransparencyGroup: true)
        let fs = form.summary
        #expect(fs.contains("Form"))
        #expect(fs.contains("transparency group"))

        let ps = ValidatedXObject(subtypeName: "PS")
        let pss = ps.summary
        #expect(pss.contains("PS"))
        #expect(pss.contains("deprecated"))
    }

    @Test("Equatable by ID")
    func equatable() {
        let id = UUID()
        let a = ValidatedXObject(id: id, subtypeName: "Image")
        let b = ValidatedXObject(id: id, subtypeName: "Form")
        let c = ValidatedXObject(subtypeName: "Image")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("PropertyNames coverage")
    func propertyNames() {
        let xobj = ValidatedXObject.image()
        let names = xobj.propertyNames
        #expect(names.contains("subtype"))
        #expect(names.contains("isImage"))
        #expect(names.contains("isForm"))
        #expect(names.contains("involvesTransparency"))
        for propName in names {
            let value = xobj.property(named: propName)
            #expect(value != nil)
        }
    }

    @Test("Inline image flag")
    func inlineImage() {
        let inlineImg = ValidatedXObject(isInline: true)
        #expect(inlineImg.isInline == true)

        let normalImg = ValidatedXObject()
        #expect(normalImg.isInline == false)
    }
}
