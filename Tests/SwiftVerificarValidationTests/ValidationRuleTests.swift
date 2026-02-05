import Foundation
import Testing
@testable import SwiftVerificarValidation

@Suite("ValidationRule Tests")
struct ValidationRuleTests {

    // MARK: - Initialization Tests

    @Test("Create ValidationRule with all parameters")
    func createWithAllParameters() {
        let rule = ValidationRule(
            id: "6.1.2-1",
            specification: "ISO 19005-1",
            clause: "6.1.2",
            testNumber: 1,
            description: "The file header shall begin at byte zero",
            objectType: "CosDocument",
            test: "header != null && headerOffset == 0",
            errorMessage: "PDF header does not begin at byte zero"
        )

        #expect(rule.id == "6.1.2-1")
        #expect(rule.specification == "ISO 19005-1")
        #expect(rule.clause == "6.1.2")
        #expect(rule.testNumber == 1)
        #expect(rule.description == "The file header shall begin at byte zero")
        #expect(rule.objectType == "CosDocument")
        #expect(rule.test == "header != null && headerOffset == 0")
        #expect(rule.errorMessage == "PDF header does not begin at byte zero")
    }

    @Test("Create ValidationRule with minimal valid parameters")
    func createWithMinimalParameters() {
        let rule = ValidationRule(
            id: "test-1",
            specification: "Test",
            clause: "1",
            testNumber: 1,
            description: "Test",
            objectType: "Object",
            test: "true",
            errorMessage: "Error"
        )

        #expect(rule.id == "test-1")
        #expect(rule.specification == "Test")
        #expect(rule.clause == "1")
        #expect(rule.testNumber == 1)
    }

    // MARK: - Identifiable Conformance

    @Test("ValidationRule conforms to Identifiable")
    func conformsToIdentifiable() {
        let rule = ValidationRule(
            id: "rule-1",
            specification: "Test",
            clause: "1",
            testNumber: 1,
            description: "Test",
            objectType: "Object",
            test: "true",
            errorMessage: "Error"
        )

        let id: String = rule.id
        #expect(id == "rule-1")
    }

    @Test("Multiple rules have unique IDs")
    func uniqueIds() {
        let rules = (1...10).map { i in
            ValidationRule(
                id: "rule-\(i)",
                specification: "Test",
                clause: "1",
                testNumber: i,
                description: "Test",
                objectType: "Object",
                test: "true",
                errorMessage: "Error"
            )
        }

        let ids = rules.map { $0.id }
        let uniqueIds = Set(ids)

        #expect(ids.count == uniqueIds.count)
    }

    // MARK: - Sendable Conformance

    @Test("ValidationRule is Sendable")
    func isSendable() {
        let rule = ValidationRule(
            id: "rule-1",
            specification: "Test",
            clause: "1",
            testNumber: 1,
            description: "Test",
            objectType: "Object",
            test: "true",
            errorMessage: "Error"
        )

        Task {
            let _ = rule
            #expect(true)
        }
    }

    // MARK: - Specification Tests

    @Test("PDF/A-1 specification")
    func pdfa1Specification() {
        let rule = ValidationRule(
            id: "rule-1",
            specification: "ISO 19005-1:2005",
            clause: "6.1.2",
            testNumber: 1,
            description: "Test",
            objectType: "Object",
            test: "true",
            errorMessage: "Error"
        )

        #expect(rule.specification == "ISO 19005-1:2005")
    }

    @Test("PDF/A-2 specification")
    func pdfa2Specification() {
        let rule = ValidationRule(
            id: "rule-1",
            specification: "ISO 19005-2:2011",
            clause: "6.1.2",
            testNumber: 1,
            description: "Test",
            objectType: "Object",
            test: "true",
            errorMessage: "Error"
        )

        #expect(rule.specification == "ISO 19005-2:2011")
    }

    @Test("PDF/UA specification")
    func pdfuaSpecification() {
        let rule = ValidationRule(
            id: "rule-1",
            specification: "ISO 14289-1:2014",
            clause: "7.1",
            testNumber: 1,
            description: "Test",
            objectType: "Object",
            test: "true",
            errorMessage: "Error"
        )

        #expect(rule.specification == "ISO 14289-1:2014")
    }

    // MARK: - Test Number Tests

    @Test("Test number variations")
    func testNumbers() {
        for i in 1...100 {
            let rule = ValidationRule(
                id: "rule-\(i)",
                specification: "Test",
                clause: "1",
                testNumber: i,
                description: "Test",
                objectType: "Object",
                test: "true",
                errorMessage: "Error"
            )

            #expect(rule.testNumber == i)
        }
    }

    // MARK: - Object Type Tests

    @Test("Common object types")
    func commonObjectTypes() {
        let objectTypes = [
            "CosDocument",
            "PDDocument",
            "PDPage",
            "PDFont",
            "PDColorSpace",
            "PDAnnot",
            "PDExtGState"
        ]

        for objectType in objectTypes {
            let rule = ValidationRule(
                id: "rule-1",
                specification: "Test",
                clause: "1",
                testNumber: 1,
                description: "Test",
                objectType: objectType,
                test: "true",
                errorMessage: "Error"
            )

            #expect(rule.objectType == objectType)
        }
    }

    // MARK: - Test Expression Tests

    @Test("Simple test expressions")
    func simpleTestExpressions() {
        let expressions = [
            "property == value",
            "property != null",
            "count > 0",
            "flag == true",
            "value >= 1.0"
        ]

        for expression in expressions {
            let rule = ValidationRule(
                id: "rule-1",
                specification: "Test",
                clause: "1",
                testNumber: 1,
                description: "Test",
                objectType: "Object",
                test: expression,
                errorMessage: "Error"
            )

            #expect(rule.test == expression)
        }
    }

    @Test("Complex test expressions")
    func complexTestExpressions() {
        let rule = ValidationRule(
            id: "rule-1",
            specification: "Test",
            clause: "1",
            testNumber: 1,
            description: "Test",
            objectType: "Object",
            test: "(property1 == value1) && (property2 != null || property3 > 0)",
            errorMessage: "Error"
        )

        #expect(rule.test.contains("&&"))
        #expect(rule.test.contains("||"))
    }

    // MARK: - Error Message Tests

    @Test("Error messages are descriptive")
    func descriptiveErrorMessages() {
        let rule = ValidationRule(
            id: "6.2.11.3-1",
            specification: "ISO 19005-1",
            clause: "6.2.11.3",
            testNumber: 1,
            description: "Font embedding requirement",
            objectType: "PDFont",
            test: "isEmbedded == true",
            errorMessage: "All fonts used in a PDF/A-1 document must be embedded in the file"
        )

        #expect(rule.errorMessage.contains("must be embedded"))
    }

    @Test("Error messages contain context")
    func errorMessagesWithContext() {
        let rule = ValidationRule(
            id: "rule-1",
            specification: "Test",
            clause: "1",
            testNumber: 1,
            description: "Test",
            objectType: "Object",
            test: "true",
            errorMessage: "Expected value to be X but found Y in context Z"
        )

        #expect(rule.errorMessage.contains("Expected"))
        #expect(rule.errorMessage.contains("but found"))
    }

    // MARK: - Clause Format Tests

    @Test("Clause format variations")
    func clauseFormats() {
        let clauses = [
            "6.1.2",
            "6.2.11.3",
            "7.1",
            "Annex A",
            "Table 1"
        ]

        for clause in clauses {
            let rule = ValidationRule(
                id: "rule-1",
                specification: "Test",
                clause: clause,
                testNumber: 1,
                description: "Test",
                objectType: "Object",
                test: "true",
                errorMessage: "Error"
            )

            #expect(rule.clause == clause)
        }
    }
}
