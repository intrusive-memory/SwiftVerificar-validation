import Foundation
import Testing
@testable import SwiftVerificarValidation
import SwiftVerificarParser

// MARK: - DeviceRGBValidation Tests

@Suite("DeviceRGBValidation")
struct DeviceRGBValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let cs = DeviceRGBValidation()
            #expect(cs.colorSpaceFamily == .deviceRGB)
            #expect(cs.componentCount == 3)
            #expect(!cs.hasDefaultColorSpace)
            #expect(!cs.hasOutputIntentOverride)
            #expect(!cs.isPDFACompliant)
            #expect(cs.isDeviceDependent)
            #expect(!cs.isCIEBased)
            #expect(!cs.isSpecial)
        }

        @Test("Object type is PDDeviceRGB")
        func objectType() {
            let cs = DeviceRGBValidation()
            #expect(cs.objectType == "PDDeviceRGB")
        }

        @Test("Resource type is colorSpace")
        func resourceType() {
            let cs = DeviceRGBValidation()
            #expect(cs.resourceType == .colorSpace)
        }

        @Test("Default context is ColorSpace DeviceRGB")
        func defaultContext() {
            let cs = DeviceRGBValidation()
            #expect(cs.validationContext.location == "ColorSpace")
            #expect(cs.validationContext.role == "DeviceRGB")
        }

        @Test("Custom resource name")
        func customResourceName() {
            let cs = DeviceRGBValidation(resourceName: ASAtom("CS2"))
            #expect(cs.resourceName == ASAtom("CS2"))
        }
    }

    // MARK: - PDF/A Compliance

    @Suite("PDF/A Compliance")
    struct PDFAComplianceTests {

        @Test("Not compliant when neither default nor output intent")
        func notCompliant() {
            let cs = DeviceRGBValidation()
            #expect(!cs.isPDFACompliant)
        }

        @Test("Compliant with default color space")
        func compliantWithDefault() {
            let cs = DeviceRGBValidation(hasDefaultColorSpace: true)
            #expect(cs.isPDFACompliant)
        }

        @Test("Compliant with output intent override")
        func compliantWithOutputIntent() {
            let cs = DeviceRGBValidation(hasOutputIntentOverride: true)
            #expect(cs.isPDFACompliant)
        }

        @Test("Compliant with both")
        func compliantWithBoth() {
            let cs = DeviceRGBValidation(hasDefaultColorSpace: true, hasOutputIntentOverride: true)
            #expect(cs.isPDFACompliant)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include device-specific properties")
        func propertyNames() {
            let cs = DeviceRGBValidation()
            let names = cs.propertyNames
            #expect(names.contains("hasDefaultColorSpace"))
            #expect(names.contains("hasOutputIntentOverride"))
            #expect(names.contains("isPDFACompliant"))
        }

        @Test("Property access for all device RGB properties")
        func allProperties() {
            let cs = DeviceRGBValidation(hasDefaultColorSpace: true, hasOutputIntentOverride: false)
            #expect(cs.property(named: "hasDefaultColorSpace") == .boolean(true))
            #expect(cs.property(named: "hasOutputIntentOverride") == .boolean(false))
            #expect(cs.property(named: "isPDFACompliant") == .boolean(true))
            #expect(cs.property(named: "colorSpaceFamily") == .string("DeviceRGB"))
            #expect(cs.property(named: "componentCount") == .integer(3))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let cs = DeviceRGBValidation()
            #expect(cs.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let cs1 = DeviceRGBValidation(id: id)
            let cs2 = DeviceRGBValidation(id: id)
            #expect(cs1 == cs2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let cs1 = DeviceRGBValidation()
            let cs2 = DeviceRGBValidation()
            #expect(cs1 != cs2)
        }
    }
}
