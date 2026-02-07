import Foundation
import Testing
import struct SwiftVerificarValidationProfiles.ValidationRule
import struct SwiftVerificarValidationProfiles.RuleID
import struct SwiftVerificarValidationProfiles.ErrorDetails
import struct SwiftVerificarValidationProfiles.Reference
import enum SwiftVerificarValidationProfiles.Specification
@testable import SwiftVerificarValidation

@Suite("ProfileRuleEvaluator Tests")
struct ProfileRuleEvaluatorTests {

    // MARK: - Test Helpers

    struct MockPDFObject: PDFObject, Equatable {
        let id = UUID()
        let objectType: String
        let cosObject: COSValue? = nil
        let properties: [String: PropertyValue]

        var propertyNames: [String] {
            Array(properties.keys).sorted()
        }

        func property(named name: String) -> PropertyValue? {
            properties[name]
        }

        static func == (lhs: MockPDFObject, rhs: MockPDFObject) -> Bool {
            lhs.id == rhs.id
        }
    }

    // MARK: - Initialization Tests

    @Test("Create ProfileRuleEvaluator with default configuration")
    func createWithDefaultConfiguration() {
        let evaluator = ProfileRuleEvaluator()
        #expect(evaluator.configuration.includeDetailedErrors == true)
        #expect(evaluator.configuration.captureContext == true)
        #expect(evaluator.configuration.includePropertyValues == false)
    }

    @Test("Create ProfileRuleEvaluator with custom configuration")
    func createWithCustomConfiguration() {
        let config = ProfileRuleEvaluator.Configuration(
            includeDetailedErrors: false,
            captureContext: false,
            includePropertyValues: true
        )
        let evaluator = ProfileRuleEvaluator(configuration: config)
        #expect(evaluator.configuration.includeDetailedErrors == false)
        #expect(evaluator.configuration.captureContext == false)
        #expect(evaluator.configuration.includePropertyValues == true)
    }

    @Test("ProfileRuleEvaluator fast configuration")
    func fastConfiguration() {
        let config = ProfileRuleEvaluator.Configuration.fast
        #expect(config.includeDetailedErrors == false)
        #expect(config.captureContext == false)
        #expect(config.includePropertyValues == false)
    }

    @Test("ProfileRuleEvaluator thorough configuration")
    func thoroughConfiguration() {
        let config = ProfileRuleEvaluator.Configuration.thorough
        #expect(config.includeDetailedErrors == true)
        #expect(config.captureContext == true)
        #expect(config.includePropertyValues == true)
        #expect(config.executionTimeout == 30.0)
    }

    // MARK: - Simple Rule Evaluation Tests

    @Test("Evaluate simple passing rule")
    func evaluateSimplePassingRule() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "1.1", testNumber: 1),
            object: "TestObject",
            description: "Test rule",
            test: "hasStructure == true",
            error: ErrorDetails(message: "Missing structure")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "hasStructure": .boolean(true)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
        #expect(result.ruleId == "ISO_14289_2-1.1-1")
        #expect(result.message == nil)
    }

    @Test("Evaluate simple failing rule")
    func evaluateSimpleFailingRule() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "1.1", testNumber: 1),
            object: "TestObject",
            description: "Object must have structure",
            test: "hasStructure == true",
            error: ErrorDetails(message: "Missing structure")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "hasStructure": .boolean(false)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .failed)
        #expect(result.message != nil)
        #expect(result.message?.contains("Missing structure") == true)
    }

    // MARK: - Complex Expression Tests

    @Test("Evaluate rule with numeric comparison")
    func evaluateNumericComparison() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "2.1", testNumber: 1),
            object: "TestObject",
            description: "Page count must be greater than zero",
            test: "pageCount > 0",
            error: ErrorDetails(message: "Invalid page count")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "pageCount": .integer(5)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    @Test("Evaluate rule with string comparison")
    func evaluateStringComparison() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "2.2", testNumber: 1),
            object: "TestObject",
            description: "Type must be Catalog",
            test: "type == \"Catalog\"",
            error: ErrorDetails(message: "Invalid type")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "type": .string("Catalog")
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    @Test("Evaluate rule with logical AND")
    func evaluateLogicalAnd() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "2.3", testNumber: 1),
            object: "TestObject",
            description: "Must have both structure and metadata",
            test: "hasStructure == true && hasMetadata == true",
            error: ErrorDetails(message: "Missing required elements")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "hasStructure": .boolean(true),
                "hasMetadata": .boolean(true)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    @Test("Evaluate rule with logical OR")
    func evaluateLogicalOr() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "2.4", testNumber: 1),
            object: "TestObject",
            description: "Must have title or author",
            test: "hasTitle == true || hasAuthor == true",
            error: ErrorDetails(message: "Missing metadata")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "hasTitle": .boolean(false),
                "hasAuthor": .boolean(true)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    // MARK: - Context Tests

    @Test("Evaluate with document location context")
    func evaluateWithLocationContext() async {
        let config = ProfileRuleEvaluator.Configuration(captureContext: true)
        let evaluator = ProfileRuleEvaluator(configuration: config)

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "3.1", testNumber: 1),
            object: "TestObject",
            description: "Test rule",
            test: "value == 42",
            error: ErrorDetails(message: "Wrong value")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "value": .integer(99)
            ]
        )

        let context = EvaluationContext(documentLocation: "Page 5")

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .failed)
        #expect(result.context?.contains("Page 5") == true)
    }

    @Test("Evaluate with additional properties")
    func evaluateWithAdditionalProperties() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "3.2", testNumber: 1),
            object: "TestObject",
            description: "Page number must be positive",
            test: "pageNumber > 0",
            error: ErrorDetails(message: "Invalid page number")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [:]
        )

        let context = EvaluationContext(
            additionalProperties: [
                "pageNumber": .int(5)
            ]
        )

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    @Test("Evaluate with profile variables")
    func evaluateWithProfileVariables() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "3.3", testNumber: 1),
            object: "TestObject",
            description: "Version must match minimum",
            test: "version >= minVersion",
            error: ErrorDetails(message: "Version too old")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "version": .integer(2)
            ]
        )

        let context = EvaluationContext(
            profileVariables: [
                "minVersion": .int(1)
            ]
        )

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    // MARK: - Configuration Tests

    @Test("Detailed errors include rule description")
    func detailedErrors() async {
        let config = ProfileRuleEvaluator.Configuration(includeDetailedErrors: true)
        let evaluator = ProfileRuleEvaluator(configuration: config)

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "4.1", testNumber: 1),
            object: "TestObject",
            description: "Object must have required field",
            test: "hasField == true",
            error: ErrorDetails(message: "Missing field")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "hasField": .boolean(false)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .failed)
        #expect(result.message?.contains("Object must have required field") == true)
    }

    @Test("Non-detailed errors show only error message")
    func nonDetailedErrors() async {
        let config = ProfileRuleEvaluator.Configuration(includeDetailedErrors: false)
        let evaluator = ProfileRuleEvaluator(configuration: config)

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "4.2", testNumber: 1),
            object: "TestObject",
            description: "Very long description that should not appear",
            test: "hasField == true",
            error: ErrorDetails(message: "Missing field")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "hasField": .boolean(false)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .failed)
        #expect(result.message == "Missing field")
    }

    @Test("Explanation includes rule details")
    func explanationIncludesDetails() async {
        let config = ProfileRuleEvaluator.Configuration(includeDetailedErrors: true)
        let evaluator = ProfileRuleEvaluator(configuration: config)

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "4.3", testNumber: 1),
            object: "TestObject",
            description: "Test description",
            test: "value > 10",
            error: ErrorDetails(message: "Value too small"),
            references: [
                Reference(specification: "ISO 14289-2:2024", clause: "4.3")
            ]
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "value": .integer(5)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .failed)
        #expect(result.explanation != nil)
        #expect(result.explanation?.contains("Test description") == true)
        #expect(result.explanation?.contains("value > 10") == true)
    }

    // MARK: - Multiple Rules Tests

    @Test("Evaluate multiple rules in parallel")
    func evaluateMultipleRules() async {
        let evaluator = ProfileRuleEvaluator()

        let rules = [
            ValidationRule(
                id: RuleID(specification: .iso142892, clause: "5.1", testNumber: 1),
                object: "TestObject",
                description: "Rule 1",
                test: "value1 == true",
                error: ErrorDetails(message: "Rule 1 failed")
            ),
            ValidationRule(
                id: RuleID(specification: .iso142892, clause: "5.2", testNumber: 1),
                object: "TestObject",
                description: "Rule 2",
                test: "value2 == true",
                error: ErrorDetails(message: "Rule 2 failed")
            ),
            ValidationRule(
                id: RuleID(specification: .iso142892, clause: "5.3", testNumber: 1),
                object: "TestObject",
                description: "Rule 3",
                test: "value3 == true",
                error: ErrorDetails(message: "Rule 3 failed")
            )
        ]

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "value1": .boolean(true),
                "value2": .boolean(false),
                "value3": .boolean(true)
            ]
        )

        let context = EvaluationContext.empty

        let results = await evaluator.evaluateAll(rules: rules, object: object, context: context)

        #expect(results.count == 3)
        #expect(results[0].status == .passed)
        #expect(results[1].status == .failed)
        #expect(results[2].status == .passed)
    }

    @Test("Evaluate all rules maintains order")
    func evaluateAllMaintainsOrder() async {
        let evaluator = ProfileRuleEvaluator()

        let rules = (1...10).map { i in
            ValidationRule(
                id: RuleID(specification: .iso142892, clause: "6.\(i)", testNumber: 1),
                object: "TestObject",
                description: "Rule \(i)",
                test: "value == \(i)",
                error: ErrorDetails(message: "Failed")
            )
        }

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "value": .integer(5)
            ]
        )

        let context = EvaluationContext.empty

        let results = await evaluator.evaluateAll(rules: rules, object: object, context: context)

        #expect(results.count == 10)

        // Check that results are in the same order as rules
        for (index, result) in results.enumerated() {
            let expectedRuleId = "ISO_14289_2-6.\(index + 1)-1"
            #expect(result.ruleId == expectedRuleId)
        }
    }

    // MARK: - Error Handling Tests

    @Test("Invalid expression produces error status")
    func invalidExpressionError() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "7.1", testNumber: 1),
            object: "TestObject",
            description: "Invalid test",
            test: "value == (((", // Invalid expression
            error: ErrorDetails(message: "Test failed")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "value": .integer(42)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .error)
        #expect(result.message != nil)
    }

    @Test("Unknown property in expression produces error")
    func unknownPropertyError() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "7.2", testNumber: 1),
            object: "TestObject",
            description: "Test with unknown property",
            test: "unknownProperty == true",
            error: ErrorDetails(message: "Test failed")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "knownProperty": .boolean(true)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .error)
    }

    @Test("Treat evaluation errors as failures")
    func treatErrorsAsFailures() async {
        let config = ProfileRuleEvaluator.Configuration(
            treatEvaluationErrorsAsFailures: true
        )
        let evaluator = ProfileRuleEvaluator(configuration: config)

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "7.3", testNumber: 1),
            object: "TestObject",
            description: "Test",
            test: "unknownProperty == true",
            error: ErrorDetails(message: "Test failed")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [:]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .failed)
    }

    // MARK: - Property Conversion Tests

    @Test("Convert boolean property values")
    func convertBooleanValues() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "8.1", testNumber: 1),
            object: "TestObject",
            description: "Boolean test",
            test: "flag == true",
            error: ErrorDetails(message: "Wrong value")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "flag": .boolean(true)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    @Test("Convert integer property values")
    func convertIntegerValues() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "8.2", testNumber: 1),
            object: "TestObject",
            description: "Integer test",
            test: "count == 42",
            error: ErrorDetails(message: "Wrong count")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "count": .integer(42)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    @Test("Convert real property values")
    func convertRealValues() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "8.3", testNumber: 1),
            object: "TestObject",
            description: "Real test",
            test: "width > 100.0",
            error: ErrorDetails(message: "Too narrow")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "width": .real(150.5)
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    @Test("Convert string property values")
    func convertStringValues() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "8.4", testNumber: 1),
            object: "TestObject",
            description: "String test",
            test: "name == \"Document\"",
            error: ErrorDetails(message: "Wrong name")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "name": .string("Document")
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }

    @Test("Convert name property values as strings")
    func convertNameValues() async {
        let evaluator = ProfileRuleEvaluator()

        let rule = ValidationRule(
            id: RuleID(specification: .iso142892, clause: "8.5", testNumber: 1),
            object: "TestObject",
            description: "Name test",
            test: "type == \"Catalog\"",
            error: ErrorDetails(message: "Wrong type")
        )

        let object = MockPDFObject(
            objectType: "TestObject",
            properties: [
                "type": .name("Catalog")
            ]
        )

        let context = EvaluationContext.empty

        let result = await evaluator.evaluate(rule: rule, object: object, context: context)

        #expect(result.status == .passed)
    }
}
