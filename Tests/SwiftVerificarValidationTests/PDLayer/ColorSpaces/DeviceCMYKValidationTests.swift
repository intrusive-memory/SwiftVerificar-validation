import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - DeviceCMYKValidation Tests

@Suite("DeviceCMYKValidation")
struct DeviceCMYKValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let cs = DeviceCMYKValidation()
            #expect(cs.colorSpaceFamily == .deviceCMYK)
            #expect(cs.componentCount == 4)
            #expect(!cs.hasDefaultColorSpace)
            #expect(!cs.hasOutputIntentOverride)
            #expect(!cs.isPDFACompliant)
            #expect(cs.isDeviceDependent)
            #expect(!cs.isCIEBased)
            #expect(!cs.isSpecial)
        }

        @Test("Object type is PDDeviceCMYK")
        func objectType() {
            let cs = DeviceCMYKValidation()
            #expect(cs.objectType == "PDDeviceCMYK")
        }

        @Test("Resource type is colorSpace")
        func resourceType() {
            let cs = DeviceCMYKValidation()
            #expect(cs.resourceType == .colorSpace)
        }

        @Test("Default context is ColorSpace DeviceCMYK")
        func defaultContext() {
            let cs = DeviceCMYKValidation()
            #expect(cs.validationContext.location == "ColorSpace")
            #expect(cs.validationContext.role == "DeviceCMYK")
        }
    }

    // MARK: - PDF/A Compliance

    @Suite("PDF/A Compliance")
    struct PDFAComplianceTests {

        @Test("Not compliant when neither default nor output intent")
        func notCompliant() {
            let cs = DeviceCMYKValidation()
            #expect(!cs.isPDFACompliant)
        }

        @Test("Compliant with default color space")
        func compliantWithDefault() {
            let cs = DeviceCMYKValidation(hasDefaultColorSpace: true)
            #expect(cs.isPDFACompliant)
        }

        @Test("Compliant with output intent override")
        func compliantWithOutputIntent() {
            let cs = DeviceCMYKValidation(hasOutputIntentOverride: true)
            #expect(cs.isPDFACompliant)
        }

        @Test("Compliant with both")
        func compliantWithBoth() {
            let cs = DeviceCMYKValidation(hasDefaultColorSpace: true, hasOutputIntentOverride: true)
            #expect(cs.isPDFACompliant)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include device-specific properties")
        func propertyNames() {
            let cs = DeviceCMYKValidation()
            let names = cs.propertyNames
            #expect(names.contains("hasDefaultColorSpace"))
            #expect(names.contains("hasOutputIntentOverride"))
            #expect(names.contains("isPDFACompliant"))
        }

        @Test("Property access for all device CMYK properties")
        func allProperties() {
            let cs = DeviceCMYKValidation(hasDefaultColorSpace: false, hasOutputIntentOverride: true)
            #expect(cs.property(named: "hasDefaultColorSpace") == .boolean(false))
            #expect(cs.property(named: "hasOutputIntentOverride") == .boolean(true))
            #expect(cs.property(named: "isPDFACompliant") == .boolean(true))
            #expect(cs.property(named: "colorSpaceFamily") == .string("DeviceCMYK"))
            #expect(cs.property(named: "componentCount") == .integer(4))
        }

        @Test("Alternate color space is null for device spaces")
        func alternateNull() {
            let cs = DeviceCMYKValidation()
            #expect(cs.property(named: "alternateColorSpaceName") == .null)
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let cs = DeviceCMYKValidation()
            #expect(cs.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let cs1 = DeviceCMYKValidation(id: id)
            let cs2 = DeviceCMYKValidation(id: id)
            #expect(cs1 == cs2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let cs1 = DeviceCMYKValidation()
            let cs2 = DeviceCMYKValidation()
            #expect(cs1 != cs2)
        }
    }
}
