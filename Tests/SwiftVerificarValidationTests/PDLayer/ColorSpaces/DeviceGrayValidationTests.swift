import Foundation
import Testing
@testable import SwiftVerificarValidation
import SwiftVerificarParser

// MARK: - DeviceGrayValidation Tests

@Suite("DeviceGrayValidation")
struct DeviceGrayValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let cs = DeviceGrayValidation()
            #expect(cs.colorSpaceFamily == .deviceGray)
            #expect(cs.componentCount == 1)
            #expect(!cs.hasDefaultColorSpace)
            #expect(!cs.hasOutputIntentOverride)
            #expect(!cs.isPDFACompliant)
            #expect(cs.isDeviceDependent)
            #expect(!cs.isCIEBased)
            #expect(!cs.isSpecial)
        }

        @Test("Object type is PDDeviceGray")
        func objectType() {
            let cs = DeviceGrayValidation()
            #expect(cs.objectType == "PDDeviceGray")
        }

        @Test("Resource type is colorSpace")
        func resourceType() {
            let cs = DeviceGrayValidation()
            #expect(cs.resourceType == .colorSpace)
        }

        @Test("Default context is ColorSpace DeviceGray")
        func defaultContext() {
            let cs = DeviceGrayValidation()
            #expect(cs.validationContext.location == "ColorSpace")
            #expect(cs.validationContext.role == "DeviceGray")
        }

        @Test("Custom context")
        func customContext() {
            let ctx = ObjectContext(pageNumber: 3, location: "Custom")
            let cs = DeviceGrayValidation(context: ctx)
            #expect(cs.validationContext.pageNumber == 3)
            #expect(cs.validationContext.location == "Custom")
        }

        @Test("Custom resource name")
        func customResourceName() {
            let cs = DeviceGrayValidation(resourceName: ASAtom("CS1"))
            #expect(cs.resourceName == ASAtom("CS1"))
        }
    }

    // MARK: - PDF/A Compliance

    @Suite("PDF/A Compliance")
    struct PDFAComplianceTests {

        @Test("Not compliant when neither default nor output intent")
        func notCompliant() {
            let cs = DeviceGrayValidation()
            #expect(!cs.isPDFACompliant)
        }

        @Test("Compliant with default color space")
        func compliantWithDefault() {
            let cs = DeviceGrayValidation(hasDefaultColorSpace: true)
            #expect(cs.isPDFACompliant)
        }

        @Test("Compliant with output intent override")
        func compliantWithOutputIntent() {
            let cs = DeviceGrayValidation(hasOutputIntentOverride: true)
            #expect(cs.isPDFACompliant)
        }

        @Test("Compliant with both")
        func compliantWithBoth() {
            let cs = DeviceGrayValidation(hasDefaultColorSpace: true, hasOutputIntentOverride: true)
            #expect(cs.isPDFACompliant)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include device-specific properties")
        func propertyNames() {
            let cs = DeviceGrayValidation()
            let names = cs.propertyNames
            #expect(names.contains("hasDefaultColorSpace"))
            #expect(names.contains("hasOutputIntentOverride"))
            #expect(names.contains("isPDFACompliant"))
            #expect(names.contains("colorSpaceFamily"))
            #expect(names.contains("componentCount"))
        }

        @Test("Property access for hasDefaultColorSpace")
        func defaultColorSpaceProperty() {
            let cs = DeviceGrayValidation(hasDefaultColorSpace: true)
            #expect(cs.property(named: "hasDefaultColorSpace") == .boolean(true))
        }

        @Test("Property access for hasOutputIntentOverride")
        func outputIntentProperty() {
            let cs = DeviceGrayValidation(hasOutputIntentOverride: true)
            #expect(cs.property(named: "hasOutputIntentOverride") == .boolean(true))
        }

        @Test("Property access for isPDFACompliant")
        func pdfaCompliantProperty() {
            let compliant = DeviceGrayValidation(hasDefaultColorSpace: true)
            #expect(compliant.property(named: "isPDFACompliant") == .boolean(true))

            let notCompliant = DeviceGrayValidation()
            #expect(notCompliant.property(named: "isPDFACompliant") == .boolean(false))
        }

        @Test("Falls through to color space properties")
        func colorSpaceFallthrough() {
            let cs = DeviceGrayValidation()
            #expect(cs.property(named: "colorSpaceFamily") == .string("DeviceGray"))
            #expect(cs.property(named: "componentCount") == .integer(1))
            #expect(cs.property(named: "isDeviceDependent") == .boolean(true))
        }

        @Test("Falls through to resource properties")
        func resourceFallthrough() {
            let cs = DeviceGrayValidation(resourceName: ASAtom("DG1"))
            #expect(cs.property(named: "resourceName") == .name("DG1"))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let cs = DeviceGrayValidation()
            #expect(cs.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let cs1 = DeviceGrayValidation(id: id, hasDefaultColorSpace: true)
            let cs2 = DeviceGrayValidation(id: id, hasDefaultColorSpace: false)
            #expect(cs1 == cs2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let cs1 = DeviceGrayValidation()
            let cs2 = DeviceGrayValidation()
            #expect(cs1 != cs2)
        }
    }
}
