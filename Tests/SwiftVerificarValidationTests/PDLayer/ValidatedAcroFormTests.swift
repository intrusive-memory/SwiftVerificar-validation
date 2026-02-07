import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - FormFieldType Tests

@Suite("FormFieldType")
struct FormFieldTypeTests {

    @Test("Raw values are correct")
    func rawValues() {
        #expect(FormFieldType.text.rawValue == "Tx")
        #expect(FormFieldType.button.rawValue == "Btn")
        #expect(FormFieldType.choice.rawValue == "Ch")
        #expect(FormFieldType.signature.rawValue == "Sig")
    }

    @Test("Total case count is 4")
    func caseCount() {
        #expect(FormFieldType.allCases.count == 4)
    }

    @Test("from() works correctly")
    func fromString() {
        #expect(FormFieldType.from("Tx") == .text)
        #expect(FormFieldType.from("Btn") == .button)
        #expect(FormFieldType.from("Ch") == .choice)
        #expect(FormFieldType.from("Sig") == .signature)
        #expect(FormFieldType.from("Unknown") == nil)
    }
}

// MARK: - ValidatedAcroForm Tests

@Suite("ValidatedAcroForm")
struct ValidatedAcroFormTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let form = ValidatedAcroForm()
            #expect(form.fieldCount == 0)
            #expect(!form.needAppearances)
            #expect(form.signatureFlags == 0)
            #expect(!form.hasDefaultAppearance)
            #expect(form.defaultAppearance == nil)
            #expect(!form.hasDefaultResources)
            #expect(!form.hasCalculationOrder)
            #expect(form.calculationOrderCount == 0)
            #expect(!form.hasXFA)
            #expect(form.textFieldCount == 0)
            #expect(form.buttonFieldCount == 0)
            #expect(form.choiceFieldCount == 0)
            #expect(form.signatureFieldCount == 0)
        }

        @Test("Object type is PDAcroForm")
        func objectType() {
            let form = ValidatedAcroForm()
            #expect(form.objectType == "PDAcroForm")
        }

        @Test("Default context is AcroForm")
        func defaultContext() {
            let form = ValidatedAcroForm()
            #expect(form.validationContext.location == "AcroForm")
        }

        @Test("Custom context is preserved")
        func customContext() {
            let ctx = ObjectContext(location: "CustomForm")
            let form = ValidatedAcroForm(context: ctx)
            #expect(form.validationContext.location == "CustomForm")
        }
    }

    // MARK: - Form Properties

    @Suite("Form Properties")
    struct FormPropertyTests {

        @Test("NeedAppearances flag")
        func needAppearances() {
            let withNA = ValidatedAcroForm(needAppearances: true)
            #expect(withNA.needAppearances)

            let withoutNA = ValidatedAcroForm(needAppearances: false)
            #expect(!withoutNA.needAppearances)
        }

        @Test("Signature flags")
        func signatureFlags() {
            let withSig = ValidatedAcroForm(signatureFlags: 3)
            #expect(withSig.signatureFlags == 3)
            #expect(withSig.signaturesExist)
            #expect(withSig.isAppendOnly)

            let sigOnly = ValidatedAcroForm(signatureFlags: 1)
            #expect(sigOnly.signaturesExist)
            #expect(!sigOnly.isAppendOnly)

            let appendOnly = ValidatedAcroForm(signatureFlags: 2)
            #expect(!appendOnly.signaturesExist)
            #expect(appendOnly.isAppendOnly)

            let noFlags = ValidatedAcroForm(signatureFlags: 0)
            #expect(!noFlags.signaturesExist)
            #expect(!noFlags.isAppendOnly)
        }

        @Test("Default appearance")
        func defaultAppearance() {
            let withDA = ValidatedAcroForm(
                hasDefaultAppearance: true,
                defaultAppearance: "/Helv 12 Tf 0 0 0 rg"
            )
            #expect(withDA.hasDefaultAppearance)
            #expect(withDA.defaultAppearance == "/Helv 12 Tf 0 0 0 rg")

            let withoutDA = ValidatedAcroForm()
            #expect(!withoutDA.hasDefaultAppearance)
            #expect(withoutDA.defaultAppearance == nil)
        }

        @Test("XFA presence")
        func xfa() {
            let withXFA = ValidatedAcroForm(hasXFA: true)
            #expect(withXFA.hasXFA)

            let withoutXFA = ValidatedAcroForm()
            #expect(!withoutXFA.hasXFA)
        }

        @Test("Calculation order")
        func calculationOrder() {
            let withCO = ValidatedAcroForm(
                hasCalculationOrder: true,
                calculationOrderCount: 3
            )
            #expect(withCO.hasCalculationOrder)
            #expect(withCO.calculationOrderCount == 3)
        }
    }

    // MARK: - Field Counts

    @Suite("Field Counts")
    struct FieldCountTests {

        @Test("Individual field type counts")
        func fieldTypeCounts() {
            let form = ValidatedAcroForm(
                fieldCount: 10,
                textFieldCount: 4,
                buttonFieldCount: 3,
                choiceFieldCount: 2,
                signatureFieldCount: 1
            )
            #expect(form.fieldCount == 10)
            #expect(form.textFieldCount == 4)
            #expect(form.buttonFieldCount == 3)
            #expect(form.choiceFieldCount == 2)
            #expect(form.signatureFieldCount == 1)
        }

        @Test("hasSignatureFields")
        func hasSignatureFields() {
            let withSig = ValidatedAcroForm(signatureFieldCount: 2)
            #expect(withSig.hasSignatureFields)

            let withoutSig = ValidatedAcroForm(signatureFieldCount: 0)
            #expect(!withoutSig.hasSignatureFields)
        }
    }

    // MARK: - Computed Properties

    @Suite("Computed Properties")
    struct ComputedPropertyTests {

        @Test("hasFields")
        func hasFields() {
            let withFields = ValidatedAcroForm(fieldCount: 5)
            #expect(withFields.hasFields)

            let empty = ValidatedAcroForm(fieldCount: 0)
            #expect(!empty.hasFields)
        }

        @Test("isEmpty")
        func isEmpty() {
            let empty = ValidatedAcroForm(fieldCount: 0)
            #expect(empty.isEmpty)

            let notEmpty = ValidatedAcroForm(fieldCount: 1)
            #expect(!notEmpty.isEmpty)
        }

        @Test("isPDFACompliant when clean")
        func pdfaCompliant() {
            let compliant = ValidatedAcroForm(
                needAppearances: false,
                hasXFA: false
            )
            #expect(compliant.isPDFACompliant)
        }

        @Test("isPDFACompliant fails with needAppearances")
        func pdfaNonCompliantNA() {
            let nonCompliant = ValidatedAcroForm(needAppearances: true)
            #expect(!nonCompliant.isPDFACompliant)
        }

        @Test("isPDFACompliant fails with XFA")
        func pdfaNonCompliantXFA() {
            let nonCompliant = ValidatedAcroForm(hasXFA: true)
            #expect(!nonCompliant.isPDFACompliant)
        }

        @Test("isPDFACompliant fails with both")
        func pdfaNonCompliantBoth() {
            let nonCompliant = ValidatedAcroForm(
                needAppearances: true,
                hasXFA: true
            )
            #expect(!nonCompliant.isPDFACompliant)
        }
    }

    // MARK: - PDFObject Property Access

    @Suite("PDFObject Property Access")
    struct PropertyAccessTests {

        @Test("Property names are complete")
        func propertyNames() {
            let form = ValidatedAcroForm()
            let names = form.propertyNames
            #expect(names.contains("fieldCount"))
            #expect(names.contains("needAppearances"))
            #expect(names.contains("signatureFlags"))
            #expect(names.contains("hasDefaultAppearance"))
            #expect(names.contains("defaultAppearance"))
            #expect(names.contains("hasDefaultResources"))
            #expect(names.contains("hasCalculationOrder"))
            #expect(names.contains("calculationOrderCount"))
            #expect(names.contains("hasXFA"))
            #expect(names.contains("textFieldCount"))
            #expect(names.contains("buttonFieldCount"))
            #expect(names.contains("choiceFieldCount"))
            #expect(names.contains("signatureFieldCount"))
            #expect(names.contains("hasSignatureFields"))
            #expect(names.contains("signaturesExist"))
            #expect(names.contains("isAppendOnly"))
            #expect(names.contains("hasFields"))
            #expect(names.contains("isPDFACompliant"))
        }

        @Test("Integer properties")
        func integerProperties() {
            let form = ValidatedAcroForm(
                fieldCount: 10,
                signatureFlags: 3,
                calculationOrderCount: 2,
                textFieldCount: 4,
                buttonFieldCount: 3,
                choiceFieldCount: 2,
                signatureFieldCount: 1
            )
            #expect(form.property(named: "fieldCount") == .integer(10))
            #expect(form.property(named: "signatureFlags") == .integer(3))
            #expect(form.property(named: "calculationOrderCount") == .integer(2))
            #expect(form.property(named: "textFieldCount") == .integer(4))
            #expect(form.property(named: "buttonFieldCount") == .integer(3))
            #expect(form.property(named: "choiceFieldCount") == .integer(2))
            #expect(form.property(named: "signatureFieldCount") == .integer(1))
        }

        @Test("Boolean properties")
        func booleanProperties() {
            let form = ValidatedAcroForm(
                fieldCount: 5,
                needAppearances: true,
                signatureFlags: 1,
                hasDefaultAppearance: true,
                hasDefaultResources: true,
                hasCalculationOrder: true,
                hasXFA: true,
                signatureFieldCount: 1
            )
            #expect(form.property(named: "needAppearances") == .boolean(true))
            #expect(form.property(named: "hasDefaultAppearance") == .boolean(true))
            #expect(form.property(named: "hasDefaultResources") == .boolean(true))
            #expect(form.property(named: "hasCalculationOrder") == .boolean(true))
            #expect(form.property(named: "hasXFA") == .boolean(true))
            #expect(form.property(named: "hasSignatureFields") == .boolean(true))
            #expect(form.property(named: "signaturesExist") == .boolean(true))
            #expect(form.property(named: "isAppendOnly") == .boolean(false))
            #expect(form.property(named: "hasFields") == .boolean(true))
            #expect(form.property(named: "isPDFACompliant") == .boolean(false))
        }

        @Test("String and null properties")
        func stringProperties() {
            let withDA = ValidatedAcroForm(
                hasDefaultAppearance: true,
                defaultAppearance: "/Helv 12 Tf"
            )
            #expect(withDA.property(named: "defaultAppearance") == .string("/Helv 12 Tf"))

            let withoutDA = ValidatedAcroForm()
            #expect(withoutDA.property(named: "defaultAppearance") == .null)
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let form = ValidatedAcroForm()
            #expect(form.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Summary

    @Suite("Summary")
    struct SummaryTests {

        @Test("Summary includes field count")
        func basicSummary() {
            let form = ValidatedAcroForm(fieldCount: 5)
            #expect(form.summary.contains("5 fields"))
        }

        @Test("Summary includes field type details")
        func detailedSummary() {
            let form = ValidatedAcroForm(
                fieldCount: 10,
                textFieldCount: 4,
                buttonFieldCount: 3,
                choiceFieldCount: 2,
                signatureFieldCount: 1
            )
            let summary = form.summary
            #expect(summary.contains("4 text"))
            #expect(summary.contains("3 buttons"))
            #expect(summary.contains("2 choices"))
            #expect(summary.contains("1 signatures"))
        }

        @Test("Summary includes flags")
        func flagsSummary() {
            let form = ValidatedAcroForm(
                fieldCount: 1,
                needAppearances: true,
                hasXFA: true
            )
            let summary = form.summary
            #expect(summary.contains("needAppearances"))
            #expect(summary.contains("XFA"))
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("minimal() creates basic form")
        func minimal() {
            let form = ValidatedAcroForm.minimal(fieldCount: 3, needAppearances: false)
            #expect(form.fieldCount == 3)
            #expect(!form.needAppearances)
        }

        @Test("withSignatures() creates form with signatures")
        func withSignatures() {
            let form = ValidatedAcroForm.withSignatures(
                signatureCount: 2,
                signaturesExist: true
            )
            #expect(form.fieldCount == 2)
            #expect(form.signatureFieldCount == 2)
            #expect(form.signaturesExist)
        }

        @Test("withSignatures() without signaturesExist flag")
        func withSignaturesNoFlag() {
            let form = ValidatedAcroForm.withSignatures(
                signatureCount: 1,
                signaturesExist: false
            )
            #expect(form.signatureFieldCount == 1)
            #expect(!form.signaturesExist)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let form1 = ValidatedAcroForm(id: id, fieldCount: 5)
            let form2 = ValidatedAcroForm(id: id, fieldCount: 10)
            #expect(form1 == form2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let form1 = ValidatedAcroForm(fieldCount: 5)
            let form2 = ValidatedAcroForm(fieldCount: 5)
            #expect(form1 != form2)
        }
    }
}
