import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - JPEG 2000 Validation Tests

@Suite("JPEG2000Validation")
struct JPEG2000ValidationTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let jp2 = JPEG2000Validation()
        #expect(jp2.width == 0)
        #expect(jp2.height == 0)
        #expect(jp2.componentCount == 3)
        #expect(jp2.bitsPerComponent == 8)
        #expect(jp2.compressionType == .lossy)
        #expect(jp2.colorSpaceType == .sRGB)
        #expect(jp2.resolutionLevels == 5)
        #expect(jp2.qualityLayers == 1)
        #expect(jp2.tileWidth == 0)
        #expect(jp2.tileHeight == 0)
        #expect(jp2.tileCount == 1)
        #expect(jp2.isValid == true)
        #expect(jp2.hasValidSOCMarker == true)
        #expect(jp2.usesJPXExtensions == false)
        #expect(jp2.hasColorSpecBox == true)
        #expect(jp2.enumeratedColorSpace == nil)
        #expect(jp2.hasEmbeddedICCProfile == false)
    }

    @Test("Custom initialization with all parameters")
    func customInit() {
        let jp2 = JPEG2000Validation(
            width: 1920,
            height: 1080,
            componentCount: 3,
            bitsPerComponent: 12,
            compressionType: .lossless,
            colorSpaceType: .sRGB,
            resolutionLevels: 6,
            qualityLayers: 3,
            tileWidth: 256,
            tileHeight: 256,
            tileCount: 40,
            isValid: true,
            hasValidSOCMarker: true,
            usesJPXExtensions: false,
            hasColorSpecBox: true,
            enumeratedColorSpace: 16,
            hasEmbeddedICCProfile: true
        )
        #expect(jp2.width == 1920)
        #expect(jp2.height == 1080)
        #expect(jp2.componentCount == 3)
        #expect(jp2.bitsPerComponent == 12)
        #expect(jp2.compressionType == .lossless)
        #expect(jp2.resolutionLevels == 6)
        #expect(jp2.qualityLayers == 3)
        #expect(jp2.tileWidth == 256)
        #expect(jp2.tileHeight == 256)
        #expect(jp2.tileCount == 40)
        #expect(jp2.enumeratedColorSpace == 16)
        #expect(jp2.hasEmbeddedICCProfile == true)
    }

    // MARK: - Computed Property Tests

    @Test("Pixel count calculation")
    func pixelCount() {
        let jp2 = JPEG2000Validation(width: 800, height: 600)
        #expect(jp2.pixelCount == 480_000)
    }

    @Test("Single tiled with count 1")
    func singleTiled() {
        let jp2 = JPEG2000Validation(tileCount: 1)
        #expect(jp2.isSingleTiled == true)
    }

    @Test("Single tiled with count 0")
    func singleTiledZero() {
        let jp2 = JPEG2000Validation(tileCount: 0)
        #expect(jp2.isSingleTiled == true)
    }

    @Test("Not single tiled")
    func notSingleTiled() {
        let jp2 = JPEG2000Validation(tileCount: 4)
        #expect(jp2.isSingleTiled == false)
    }

    @Test("Valid dimensions")
    func validDimensions() {
        let jp2 = JPEG2000Validation(width: 800, height: 600)
        #expect(jp2.hasValidDimensions == true)
    }

    @Test("Invalid dimensions with zero width")
    func invalidDimensionsZeroWidth() {
        let jp2 = JPEG2000Validation(width: 0, height: 600)
        #expect(jp2.hasValidDimensions == false)
    }

    @Test("Invalid dimensions with zero height")
    func invalidDimensionsZeroHeight() {
        let jp2 = JPEG2000Validation(width: 800, height: 0)
        #expect(jp2.hasValidDimensions == false)
    }

    @Test("Valid bit depth within range")
    func validBitDepth() {
        #expect(JPEG2000Validation(bitsPerComponent: 1).hasValidBitDepth == true)
        #expect(JPEG2000Validation(bitsPerComponent: 8).hasValidBitDepth == true)
        #expect(JPEG2000Validation(bitsPerComponent: 16).hasValidBitDepth == true)
        #expect(JPEG2000Validation(bitsPerComponent: 38).hasValidBitDepth == true)
    }

    @Test("Invalid bit depth out of range")
    func invalidBitDepth() {
        #expect(JPEG2000Validation(bitsPerComponent: 0).hasValidBitDepth == false)
        #expect(JPEG2000Validation(bitsPerComponent: 39).hasValidBitDepth == false)
    }

    @Test("Consistent bit depth")
    func consistentBitDepth() {
        let jp2 = JPEG2000Validation(componentCount: 3, bitsPerComponent: 8)
        #expect(jp2.hasConsistentBitDepth == true)
    }

    @Test("Inconsistent bit depth with zero components")
    func inconsistentBitDepthZeroComponents() {
        let jp2 = JPEG2000Validation(componentCount: 0, bitsPerComponent: 8)
        #expect(jp2.hasConsistentBitDepth == false)
    }

    // MARK: - PDF/A Compliance Tests

    @Test("PDF/A-1 compliant image")
    func pdfa1Compliant() {
        let jp2 = JPEG2000Validation(
            isValid: true,
            hasValidSOCMarker: true,
            usesJPXExtensions: false
        )
        #expect(jp2.isPDFA1Compliant == true)
    }

    @Test("PDF/A-1 non-compliant with JPX extensions")
    func pdfa1NonCompliantJPX() {
        let jp2 = JPEG2000Validation(
            isValid: true,
            hasValidSOCMarker: true,
            usesJPXExtensions: true
        )
        #expect(jp2.isPDFA1Compliant == false)
    }

    @Test("PDF/A-1 non-compliant with invalid codestream")
    func pdfa1NonCompliantInvalid() {
        let jp2 = JPEG2000Validation(isValid: false, hasValidSOCMarker: true)
        #expect(jp2.isPDFA1Compliant == false)
    }

    @Test("PDF/A-1 non-compliant with invalid SOC marker")
    func pdfa1NonCompliantSOC() {
        let jp2 = JPEG2000Validation(isValid: true, hasValidSOCMarker: false)
        #expect(jp2.isPDFA1Compliant == false)
    }

    @Test("PDF/A-2 compliant image")
    func pdfa2Compliant() {
        let jp2 = JPEG2000Validation(
            isValid: true,
            hasValidSOCMarker: true,
            usesJPXExtensions: true  // PDF/A-2 allows JPX
        )
        #expect(jp2.isPDFA2Compliant == true)
    }

    @Test("PDF/A-2 non-compliant with invalid codestream")
    func pdfa2NonCompliant() {
        let jp2 = JPEG2000Validation(isValid: false, hasValidSOCMarker: true)
        #expect(jp2.isPDFA2Compliant == false)
    }

    // MARK: - PDFObject Conformance Tests

    @Test("Object type is JPEG2000")
    func objectType() {
        let jp2 = JPEG2000Validation()
        #expect(jp2.objectType == "JPEG2000")
    }

    @Test("Property names are populated")
    func propertyNames() {
        let jp2 = JPEG2000Validation()
        #expect(jp2.propertyNames.contains("width"))
        #expect(jp2.propertyNames.contains("height"))
        #expect(jp2.propertyNames.contains("compressionType"))
        #expect(jp2.propertyNames.contains("isPDFA1Compliant"))
        #expect(jp2.propertyNames.contains("pixelCount"))
    }

    @Test("Property access for integer values")
    func propertyAccessIntegers() {
        let jp2 = JPEG2000Validation(
            width: 800, height: 600,
            componentCount: 3, bitsPerComponent: 8,
            resolutionLevels: 5, qualityLayers: 2,
            tileWidth: 128, tileHeight: 128, tileCount: 30
        )
        #expect(jp2.property(named: "width")?.integerValue == 800)
        #expect(jp2.property(named: "height")?.integerValue == 600)
        #expect(jp2.property(named: "componentCount")?.integerValue == 3)
        #expect(jp2.property(named: "bitsPerComponent")?.integerValue == 8)
        #expect(jp2.property(named: "resolutionLevels")?.integerValue == 5)
        #expect(jp2.property(named: "qualityLayers")?.integerValue == 2)
        #expect(jp2.property(named: "tileWidth")?.integerValue == 128)
        #expect(jp2.property(named: "tileHeight")?.integerValue == 128)
        #expect(jp2.property(named: "tileCount")?.integerValue == 30)
        #expect(jp2.property(named: "pixelCount")?.integerValue == 480_000)
    }

    @Test("Property access for string values")
    func propertyAccessStrings() {
        let jp2 = JPEG2000Validation(compressionType: .lossless, colorSpaceType: .greyscale)
        #expect(jp2.property(named: "compressionType")?.stringValue == "Lossless")
        #expect(jp2.property(named: "colorSpaceType")?.stringValue == "Greyscale")
    }

    @Test("Property access for boolean values")
    func propertyAccessBooleans() {
        let jp2 = JPEG2000Validation(
            isValid: true,
            hasValidSOCMarker: true,
            usesJPXExtensions: false,
            hasColorSpecBox: true,
            hasEmbeddedICCProfile: false
        )
        #expect(jp2.property(named: "isValid")?.boolValue == true)
        #expect(jp2.property(named: "hasValidSOCMarker")?.boolValue == true)
        #expect(jp2.property(named: "usesJPXExtensions")?.boolValue == false)
        #expect(jp2.property(named: "hasColorSpecBox")?.boolValue == true)
        #expect(jp2.property(named: "hasEmbeddedICCProfile")?.boolValue == false)
    }

    @Test("Property access for enumerated color space")
    func propertyAccessEnumeratedCS() {
        let jp2WithCS = JPEG2000Validation(enumeratedColorSpace: 16)
        #expect(jp2WithCS.property(named: "enumeratedColorSpace")?.integerValue == 16)

        let jp2WithoutCS = JPEG2000Validation(enumeratedColorSpace: nil)
        #expect(jp2WithoutCS.property(named: "enumeratedColorSpace")?.isNull == true)
    }

    @Test("Property access for unknown property returns nil")
    func propertyAccessUnknown() {
        let jp2 = JPEG2000Validation()
        #expect(jp2.property(named: "unknownProperty") == nil)
    }

    // MARK: - Compression Type Tests

    @Test("Compression type isLossless")
    func compressionTypeLossless() {
        #expect(JPEG2000CompressionType.lossless.isLossless == true)
        #expect(JPEG2000CompressionType.lossy.isLossless == false)
        #expect(JPEG2000CompressionType.unknown.isLossless == false)
    }

    @Test("Compression type CaseIterable")
    func compressionTypeCaseIterable() {
        #expect(JPEG2000CompressionType.allCases.count == 3)
    }

    // MARK: - JPEG 2000 Color Space Tests

    @Test("Color space from enumerated values")
    func colorSpaceFromEnumerated() {
        #expect(JPEG2000ColorSpace(fromEnumerated: 16) == .sRGB)
        #expect(JPEG2000ColorSpace(fromEnumerated: 17) == .greyscale)
        #expect(JPEG2000ColorSpace(fromEnumerated: 18) == .sYCC)
        #expect(JPEG2000ColorSpace(fromEnumerated: 12) == .cmyk)
        #expect(JPEG2000ColorSpace(fromEnumerated: 14) == .cieLab)
        #expect(JPEG2000ColorSpace(fromEnumerated: 99) == .unknown)
        #expect(JPEG2000ColorSpace(fromEnumerated: nil) == .unknown)
    }

    @Test("Color space standard component counts")
    func colorSpaceComponentCounts() {
        #expect(JPEG2000ColorSpace.greyscale.standardComponentCount == 1)
        #expect(JPEG2000ColorSpace.sRGB.standardComponentCount == 3)
        #expect(JPEG2000ColorSpace.sYCC.standardComponentCount == 3)
        #expect(JPEG2000ColorSpace.cieLab.standardComponentCount == 3)
        #expect(JPEG2000ColorSpace.cmyk.standardComponentCount == 4)
        #expect(JPEG2000ColorSpace.iccProfile.standardComponentCount == nil)
        #expect(JPEG2000ColorSpace.unknown.standardComponentCount == nil)
    }

    @Test("Color space CaseIterable")
    func colorSpaceCaseIterable() {
        #expect(JPEG2000ColorSpace.allCases.count == 7)
    }

    // MARK: - Factory Method Tests

    @Test("Valid image factory")
    func validImageFactory() {
        let jp2 = JPEG2000Validation.validImage()
        #expect(jp2.width == 800)
        #expect(jp2.height == 600)
        #expect(jp2.componentCount == 3)
        #expect(jp2.isValid == true)
        #expect(jp2.compressionType == .lossy)
        #expect(jp2.isPDFA1Compliant == true)
    }

    @Test("Valid image factory with custom dimensions")
    func validImageFactoryCustom() {
        let jp2 = JPEG2000Validation.validImage(width: 1920, height: 1080)
        #expect(jp2.width == 1920)
        #expect(jp2.height == 1080)
    }

    @Test("Lossless gray factory")
    func losslessGrayFactory() {
        let jp2 = JPEG2000Validation.losslessGray()
        #expect(jp2.width == 256)
        #expect(jp2.height == 256)
        #expect(jp2.componentCount == 1)
        #expect(jp2.compressionType == .lossless)
        #expect(jp2.colorSpaceType == .greyscale)
    }

    // MARK: - Equatable Tests

    @Test("Equatable by id")
    func equatable() {
        let id = UUID()
        let j1 = JPEG2000Validation(id: id, width: 800, height: 600)
        let j2 = JPEG2000Validation(id: id, width: 1920, height: 1080)
        #expect(j1 == j2)
    }

    @Test("Not equal with different ids")
    func notEqual() {
        let j1 = JPEG2000Validation(width: 800, height: 600)
        let j2 = JPEG2000Validation(width: 800, height: 600)
        #expect(j1 != j2)
    }

    // MARK: - Protocol Conformance Tests

    @Test("Conforms to PDValidationObject")
    func conformsToPDValidationObject() {
        let jp2 = JPEG2000Validation()
        let _: any PDValidationObject = jp2
        #expect(jp2.objectType == "JPEG2000")
    }

    @Test("Validation context defaults")
    func validationContextDefaults() {
        let jp2 = JPEG2000Validation()
        #expect(jp2.validationContext.location == "JPEG2000")
        #expect(jp2.validationContext.role == "Image")
    }
}
