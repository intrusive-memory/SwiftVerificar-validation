import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Shading Type Tests

@Suite("ShadingType Tests")
struct ShadingTypeTests {

    @Test("Raw values match PDF specification")
    func rawValues() {
        #expect(ShadingType.functionBased.rawValue == 1)
        #expect(ShadingType.axial.rawValue == 2)
        #expect(ShadingType.radial.rawValue == 3)
        #expect(ShadingType.freeFormGouraud.rawValue == 4)
        #expect(ShadingType.latticeFormGouraud.rawValue == 5)
        #expect(ShadingType.coonsPatch.rawValue == 6)
        #expect(ShadingType.tensorProduct.rawValue == 7)
        #expect(ShadingType.unknown.rawValue == 0)
    }

    @Test("Creates type from valid value")
    func fromValidValue() {
        #expect(ShadingType(fromValue: 1) == .functionBased)
        #expect(ShadingType(fromValue: 2) == .axial)
        #expect(ShadingType(fromValue: 3) == .radial)
        #expect(ShadingType(fromValue: 4) == .freeFormGouraud)
        #expect(ShadingType(fromValue: 5) == .latticeFormGouraud)
        #expect(ShadingType(fromValue: 6) == .coonsPatch)
        #expect(ShadingType(fromValue: 7) == .tensorProduct)
    }

    @Test("Creates unknown for invalid value")
    func fromInvalidValue() {
        #expect(ShadingType(fromValue: 8) == .unknown)
        #expect(ShadingType(fromValue: nil) == .unknown)
        #expect(ShadingType(fromValue: -1) == .unknown)
    }

    @Test("Mesh classification")
    func meshClassification() {
        #expect(ShadingType.freeFormGouraud.isMesh == true)
        #expect(ShadingType.latticeFormGouraud.isMesh == true)
        #expect(ShadingType.coonsPatch.isMesh == true)
        #expect(ShadingType.tensorProduct.isMesh == true)
        #expect(ShadingType.functionBased.isMesh == false)
        #expect(ShadingType.axial.isMesh == false)
        #expect(ShadingType.radial.isMesh == false)
        #expect(ShadingType.unknown.isMesh == false)
    }

    @Test("Gradient classification")
    func gradientClassification() {
        #expect(ShadingType.axial.isGradient == true)
        #expect(ShadingType.radial.isGradient == true)
        #expect(ShadingType.functionBased.isGradient == false)
        #expect(ShadingType.freeFormGouraud.isGradient == false)
    }

    @Test("CaseIterable conformance")
    func caseIterable() {
        #expect(ShadingType.allCases.count == 8)
    }
}

// MARK: - Validated Shading Tests

@Suite("ValidatedShading Tests")
struct ValidatedShadingTests {

    @Test("Default initialization")
    func defaultInit() {
        let shading = ValidatedShading()
        #expect(shading.shadingType == .axial)
        #expect(shading.colorSpaceName == nil)
        #expect(shading.colorComponentCount == 3)
        #expect(shading.hasBBox == false)
        #expect(shading.hasBackground == false)
        #expect(shading.hasFunction == false)
        #expect(shading.functionCount == 0)
        #expect(shading.antiAlias == false)
        #expect(shading.objectType == "PDShading")
    }

    @Test("Axial shading factory")
    func axialFactory() {
        let shading = ValidatedShading.axial(colorSpaceName: "DeviceRGB")
        #expect(shading.shadingType == .axial)
        #expect(shading.colorSpaceName == "DeviceRGB")
        #expect(shading.colorComponentCount == 3)
        #expect(shading.hasFunction == true)
        #expect(shading.functionCount == 1)
        #expect(shading.hasCoords == true)
        #expect(shading.isGradient == true)
        #expect(shading.isMesh == false)
        #expect(shading.isValid == true)
    }

    @Test("Radial shading factory")
    func radialFactory() {
        let shading = ValidatedShading.radial(colorSpaceName: "DeviceCMYK")
        #expect(shading.shadingType == .radial)
        #expect(shading.colorSpaceName == "DeviceCMYK")
        #expect(shading.isGradient == true)
        #expect(shading.isValid == true)
    }

    @Test("Function-based shading factory")
    func functionBasedFactory() {
        let shading = ValidatedShading.functionBased(colorSpaceName: "DeviceGray")
        #expect(shading.shadingType == .functionBased)
        #expect(shading.colorSpaceName == "DeviceGray")
        #expect(shading.colorComponentCount == 1)
        #expect(shading.hasFunction == true)
        #expect(shading.hasDomain == true)
        #expect(shading.isValid == true)
    }

    @Test("Validity for different shading types")
    func validity() {
        // Function-based: needs function
        let funcValid = ValidatedShading(shadingType: .functionBased, hasFunction: true)
        #expect(funcValid.isValid == true)
        let funcInvalid = ValidatedShading(shadingType: .functionBased, hasFunction: false)
        #expect(funcInvalid.isValid == false)

        // Axial: needs coords and function
        let axialValid = ValidatedShading(shadingType: .axial, hasFunction: true, hasCoords: true)
        #expect(axialValid.isValid == true)
        let axialNoCoords = ValidatedShading(shadingType: .axial, hasFunction: true, hasCoords: false)
        #expect(axialNoCoords.isValid == false)
        let axialNoFunc = ValidatedShading(shadingType: .axial, hasFunction: false, hasCoords: true)
        #expect(axialNoFunc.isValid == false)

        // Radial: needs coords and function
        let radialValid = ValidatedShading(shadingType: .radial, hasFunction: true, hasCoords: true)
        #expect(radialValid.isValid == true)

        // Free-form Gouraud: needs bitsPerCoordinate, bitsPerComponent, bitsPerFlag
        let gouraudValid = ValidatedShading(
            shadingType: .freeFormGouraud,
            bitsPerCoordinate: 32, bitsPerComponent: 8, bitsPerFlag: 8
        )
        #expect(gouraudValid.isValid == true)
        let gouraudInvalid = ValidatedShading(shadingType: .freeFormGouraud, bitsPerCoordinate: 32)
        #expect(gouraudInvalid.isValid == false)

        // Lattice-form: needs bitsPerCoordinate, bitsPerComponent, verticesPerRow
        let latticeValid = ValidatedShading(
            shadingType: .latticeFormGouraud,
            bitsPerCoordinate: 32, bitsPerComponent: 8, verticesPerRow: 4
        )
        #expect(latticeValid.isValid == true)
        let latticeInvalid = ValidatedShading(shadingType: .latticeFormGouraud, bitsPerCoordinate: 32)
        #expect(latticeInvalid.isValid == false)

        // Unknown: always invalid
        let unknown = ValidatedShading(shadingType: .unknown)
        #expect(unknown.isValid == false)
    }

    @Test("Device-dependent color space detection")
    func deviceDependentColorSpace() {
        let gray = ValidatedShading(colorSpaceName: "DeviceGray")
        #expect(gray.usesDeviceDependentColorSpace == true)

        let rgb = ValidatedShading(colorSpaceName: "DeviceRGB")
        #expect(rgb.usesDeviceDependentColorSpace == true)

        let cmyk = ValidatedShading(colorSpaceName: "DeviceCMYK")
        #expect(cmyk.usesDeviceDependentColorSpace == true)

        let icc = ValidatedShading(colorSpaceName: "ICCBased")
        #expect(icc.usesDeviceDependentColorSpace == false)

        let none = ValidatedShading(colorSpaceName: nil)
        #expect(none.usesDeviceDependentColorSpace == false)
    }

    @Test("Full mesh shading initialization")
    func fullMeshInit() {
        let shading = ValidatedShading(
            shadingType: .coonsPatch,
            colorSpaceName: "DeviceRGB",
            colorComponentCount: 3,
            hasBBox: true,
            bBox: PDFRect(x: 0, y: 0, width: 100, height: 100),
            hasBackground: true,
            antiAlias: true,
            bitsPerCoordinate: 32,
            bitsPerComponent: 8,
            bitsPerFlag: 8
        )
        #expect(shading.shadingType == .coonsPatch)
        #expect(shading.isMesh == true)
        #expect(shading.hasBBox == true)
        #expect(shading.hasBackground == true)
        #expect(shading.antiAlias == true)
        #expect(shading.bitsPerCoordinate == 32)
        #expect(shading.bitsPerComponent == 8)
        #expect(shading.bitsPerFlag == 8)
        #expect(shading.isValid == true)
    }

    @Test("Gradient extend properties")
    func extendProperties() {
        let shading = ValidatedShading(
            shadingType: .axial,
            hasFunction: true,
            hasCoords: true,
            extendStart: true,
            extendEnd: false
        )
        #expect(shading.extendStart == true)
        #expect(shading.extendEnd == false)
    }

    @Test("Property access")
    func propertyAccess() {
        let shading = ValidatedShading.axial(colorSpaceName: "DeviceRGB")
        #expect(shading.property(named: "shadingType")?.integerValue == 2)
        #expect(shading.property(named: "colorSpaceName")?.stringValue == "DeviceRGB")
        #expect(shading.property(named: "colorComponentCount")?.integerValue == 3)
        #expect(shading.property(named: "hasFunction")?.boolValue == true)
        #expect(shading.property(named: "functionCount")?.integerValue == 1)
        #expect(shading.property(named: "hasCoords")?.boolValue == true)
        #expect(shading.property(named: "isMesh")?.boolValue == false)
        #expect(shading.property(named: "isGradient")?.boolValue == true)
        #expect(shading.property(named: "isValid")?.boolValue == true)
        #expect(shading.property(named: "nonexistent") == nil)
    }

    @Test("Null property values for absent optional fields")
    func nullProperties() {
        let shading = ValidatedShading()
        #expect(shading.property(named: "colorSpaceName")?.isNull == true)
        #expect(shading.property(named: "bBox")?.isNull == true)
        #expect(shading.property(named: "bitsPerCoordinate")?.isNull == true)
        #expect(shading.property(named: "bitsPerComponent")?.isNull == true)
        #expect(shading.property(named: "bitsPerFlag")?.isNull == true)
        #expect(shading.property(named: "verticesPerRow")?.isNull == true)
    }

    @Test("Summary description")
    func summary() {
        let axial = ValidatedShading.axial()
        let s = axial.summary
        #expect(s.contains("Type 2"))
        #expect(s.contains("DeviceRGB"))
        #expect(s.contains("fn(1)"))
    }

    @Test("Equatable by ID")
    func equatable() {
        let id = UUID()
        let a = ValidatedShading(id: id, shadingType: .axial)
        let b = ValidatedShading(id: id, shadingType: .radial)
        let c = ValidatedShading(shadingType: .axial)
        #expect(a == b)
        #expect(a != c)
    }

    @Test("PropertyNames coverage")
    func propertyNames() {
        let shading = ValidatedShading.axial()
        let names = shading.propertyNames
        #expect(names.contains("shadingType"))
        #expect(names.contains("isMesh"))
        #expect(names.contains("isGradient"))
        for propName in names {
            let value = shading.property(named: propName)
            #expect(value != nil)
        }
    }
}
