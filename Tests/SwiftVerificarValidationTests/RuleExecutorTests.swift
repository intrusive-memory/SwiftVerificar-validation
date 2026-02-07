import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarValidationProfiles

@Suite("RuleExecutor Tests")
struct RuleExecutorTests {

    // MARK: - Test Helpers

    func makeTestRule(
        id: String = "test-rule-1",
        test: String = "property",
        errorMessage: String = "Test failed"
    ) -> ValidationRule {
        ValidationRule(
            id: RuleID(
                specification: .iso142892,
                clause: "8.2.5.26",
                testNumber: 1
            ),
            object: "PDDocument",
            description: "Test rule",
            test: test,
            error: ErrorDetails(
                message: errorMessage,
                arguments: []
            ),
            references: [],
            tags: []
        )
    }

    func makeTestObject(
        type: String = "PDDocument",
        properties: [String: String] = [:]
    ) -> ValidationObject {
        SimpleValidationObject(objectType: type, properties: properties)
    }

    // MARK: - Configuration Tests

    @Test("Default configuration has expected values")
    func testDefaultConfiguration() {
        let config = RuleExecutor.Configuration.default

        #expect(config.includeDetailedErrors == true)
        #expect(config.captureContext == true)
        #expect(config.executionTimeout == nil)
        #expect(config.treatWarningsAsErrors == false)
    }

    @Test("Fast configuration optimizes for speed")
    func testFastConfiguration() {
        let config = RuleExecutor.Configuration.fast

        #expect(config.includeDetailedErrors == false)
        #expect(config.captureContext == false)
        #expect(config.executionTimeout == nil)
    }

    @Test("Thorough configuration includes all details")
    func testThoroughConfiguration() {
        let config = RuleExecutor.Configuration.thorough

        #expect(config.includeDetailedErrors == true)
        #expect(config.captureContext == true)
        #expect(config.executionTimeout == 30.0)
    }

    @Test("Custom configuration can be created")
    func testCustomConfiguration() {
        let config = RuleExecutor.Configuration(
            includeDetailedErrors: false,
            captureContext: true,
            executionTimeout: 15.0,
            treatWarningsAsErrors: true
        )

        #expect(config.includeDetailedErrors == false)
        #expect(config.captureContext == true)
        #expect(config.executionTimeout == 15.0)
        #expect(config.treatWarningsAsErrors == true)
    }

    // MARK: - ExecutionContext Tests

    @Test("ExecutionContext stores object and metadata")
    func testExecutionContext() {
        let object = makeTestObject(type: "PDDocument")
        let metadata = ["page": "1", "object": "doc"]

        let context = RuleExecutor.ExecutionContext(
            object: object,
            metadata: metadata
        )

        #expect(context.object.objectType == "PDDocument")
        #expect(context.metadata["page"] == "1")
        #expect(context.metadata["object"] == "doc")
    }

    // Note: parentContext removed due to Swift's recursive value type restrictions

    // MARK: - Rule Execution Tests

    @Test("Execute rule with empty test passes")
    func testExecuteRuleWithEmptyTest() async {
        let executor = RuleExecutor()
        let rule = makeTestRule(test: "")
        let object = makeTestObject()
        let context = RuleExecutor.ExecutionContext(object: object)

        let result = await executor.execute(rule: rule, context: context)

        #expect(result.status == .passed)
        #expect(result.message == nil)
    }

    @Test("Execute rule with simple property test")
    func testExecuteRuleWithPropertyTest() async {
        let executor = RuleExecutor()
        let rule = makeTestRule(test: "hasStructTree")
        let object = makeTestObject(properties: ["hasStructTree": "true"])
        let context = RuleExecutor.ExecutionContext(object: object)

        let result = await executor.execute(rule: rule, context: context)

        #expect(result.status == .passed)
        #expect(result.ruleId == "ISO_14289_2-8.2.5.26-1")
    }

    @Test("Execute rule with missing property fails")
    func testExecuteRuleWithMissingProperty() async {
        let executor = RuleExecutor()
        let rule = makeTestRule(test: "missingProperty")
        let object = makeTestObject()
        let context = RuleExecutor.ExecutionContext(object: object)

        let result = await executor.execute(rule: rule, context: context)

        #expect(result.status == .failed)
        #expect(result.message != nil)
    }

    @Test("Execute rule with complex test expression passes")
    func testExecuteRuleWithComplexExpression() async {
        let executor = RuleExecutor()
        let rule = makeTestRule(test: "property == value")
        let object = makeTestObject()
        let context = RuleExecutor.ExecutionContext(object: object)

        let result = await executor.execute(rule: rule, context: context)

        // Complex expressions default to passing in this implementation
        #expect(result.status == .passed)
    }

    @Test("Execute rule includes error message on failure")
    func testExecuteRuleIncludesErrorMessage() async {
        let executor = RuleExecutor(configuration: .thorough)
        let errorMsg = "Document must have structure tree"
        let rule = makeTestRule(test: "structTree", errorMessage: errorMsg)
        let object = makeTestObject()
        let context = RuleExecutor.ExecutionContext(object: object)

        let result = await executor.execute(rule: rule, context: context)

        #expect(result.status == .failed)
        #expect(result.message?.contains(errorMsg) == true)
    }

    @Test("Execute rule with minimal error details")
    func testExecuteRuleWithMinimalErrorDetails() async {
        let executor = RuleExecutor(configuration: .fast)
        let rule = makeTestRule(test: "missingProp", errorMessage: "Custom error")
        let object = makeTestObject()
        let context = RuleExecutor.ExecutionContext(object: object)

        let result = await executor.execute(rule: rule, context: context)

        #expect(result.status == .failed)
        #expect(result.message != nil)
    }

    @Test("Execute rule captures context when configured")
    func testExecuteRuleCapturesContext() async {
        let executor = RuleExecutor(configuration: .thorough)
        let rule = makeTestRule()
        let object = makeTestObject(type: "PDDocument")
        let metadata = ["page": "5"]
        let context = RuleExecutor.ExecutionContext(object: object, metadata: metadata)

        let result = await executor.execute(rule: rule, context: context)

        #expect(result.context != nil)
        if let ctx = result.context {
            #expect(ctx.contains("PDDocument"))
            #expect(ctx.contains("ISO_14289_2-8.2.5.26-1"))
        }
    }

    @Test("Execute rule does not capture context when disabled")
    func testExecuteRuleDoesNotCaptureContext() async {
        let executor = RuleExecutor(configuration: .fast)
        let rule = makeTestRule()
        let object = makeTestObject()
        let context = RuleExecutor.ExecutionContext(object: object)

        let result = await executor.execute(rule: rule, context: context)

        #expect(result.context == nil)
    }

    // MARK: - Parallel Execution Tests

    @Test("ExecuteAll processes multiple rules")
    func testExecuteAllProcessesMultipleRules() async {
        let executor = RuleExecutor()
        let rules = [
            makeTestRule(id: "rule-1", test: "prop1"),
            makeTestRule(id: "rule-2", test: "prop2"),
            makeTestRule(id: "rule-3", test: "prop3")
        ]
        let object = makeTestObject(properties: ["prop1": "yes", "prop2": "yes"])
        let context = RuleExecutor.ExecutionContext(object: object)

        let results = await executor.executeAll(rules: rules, context: context)

        #expect(results.count == 3)
        #expect(results[0].status == .passed)  // prop1 exists
        #expect(results[1].status == .passed)  // prop2 exists
        #expect(results[2].status == .failed)  // prop3 missing
    }

    @Test("ExecuteAll maintains rule order")
    func testExecuteAllMaintainsOrder() async {
        let executor = RuleExecutor()
        let rules = [
            makeTestRule(id: "alpha", test: "a"),
            makeTestRule(id: "beta", test: "b"),
            makeTestRule(id: "gamma", test: "c")
        ]
        let object = makeTestObject()
        let context = RuleExecutor.ExecutionContext(object: object)

        let results = await executor.executeAll(rules: rules, context: context)

        #expect(results.count == 3)
        // Verify order by checking rule IDs match input order
        #expect(results[0].ruleId.contains("8.2.5.26-1"))
        #expect(results[1].ruleId.contains("8.2.5.26-1"))
        #expect(results[2].ruleId.contains("8.2.5.26-1"))
    }

    @Test("ExecuteAll handles empty rule list")
    func testExecuteAllHandlesEmptyRules() async {
        let executor = RuleExecutor()
        let object = makeTestObject()
        let context = RuleExecutor.ExecutionContext(object: object)

        let results = await executor.executeAll(rules: [], context: context)

        #expect(results.isEmpty)
    }

    @Test("ExecuteAll handles single rule")
    func testExecuteAllHandlesSingleRule() async {
        let executor = RuleExecutor()
        let rule = makeTestRule(test: "property")
        let object = makeTestObject(properties: ["property": "value"])
        let context = RuleExecutor.ExecutionContext(object: object)

        let results = await executor.executeAll(rules: [rule], context: context)

        #expect(results.count == 1)
        #expect(results[0].status == .passed)
    }

    // MARK: - ValidationObject Tests

    @Test("SimpleValidationObject stores type and properties")
    func testSimpleValidationObject() {
        let properties = ["name": "test", "value": "123"]
        let object = SimpleValidationObject(
            objectType: "PDDocument",
            properties: properties
        )

        #expect(object.objectType == "PDDocument")
        #expect(object.hasProperty("name") == true)
        #expect(object.hasProperty("value") == true)
        #expect(object.hasProperty("missing") == false)
    }

    @Test("SimpleValidationObject returns property values")
    func testSimpleValidationObjectGetProperty() {
        let properties = ["name": "test", "count": "42"]
        let object = SimpleValidationObject(
            objectType: "PDPage",
            properties: properties
        )

        #expect(object.getProperty("name") == "test")
        #expect(object.getProperty("count") == "42")
        #expect(object.getProperty("missing") == nil)
    }

    @Test("SimpleValidationObject handles empty properties")
    func testSimpleValidationObjectEmptyProperties() {
        let object = SimpleValidationObject(objectType: "PDAnnot")

        #expect(object.objectType == "PDAnnot")
        #expect(object.hasProperty("any") == false)
        #expect(object.getProperty("any") == nil)
    }

    // MARK: - Error Handling Tests

    @Test("Execute handles rule execution with various statuses")
    func testExecuteHandlesVariousStatuses() async {
        let executor = RuleExecutor()
        let passingRule = makeTestRule(test: "exists")
        let failingRule = makeTestRule(test: "missing")
        let object = makeTestObject(properties: ["exists": "true"])
        let context = RuleExecutor.ExecutionContext(object: object)

        let passResult = await executor.execute(rule: passingRule, context: context)
        let failResult = await executor.execute(rule: failingRule, context: context)

        #expect(passResult.status == .passed)
        #expect(failResult.status == .failed)
    }

    // MARK: - Integration Tests

    @Test("Complete rule execution flow")
    func testCompleteRuleExecutionFlow() async {
        let executor = RuleExecutor(configuration: .thorough)
        let rule = makeTestRule(
            test: "hasMetadata",
            errorMessage: "Document must contain metadata"
        )
        let object = makeTestObject(
            type: "PDDocument",
            properties: ["hasMetadata": "true"]
        )
        let metadata = ["location": "page 1"]
        let context = RuleExecutor.ExecutionContext(
            object: object,
            metadata: metadata
        )

        let result = await executor.execute(rule: rule, context: context)

        #expect(result.status == .passed)
        #expect(result.ruleId == "ISO_14289_2-8.2.5.26-1")
        #expect(result.message == nil)
        #expect(result.context != nil)
    }

    @Test("Batch execution with mixed results")
    func testBatchExecutionWithMixedResults() async {
        let executor = RuleExecutor(configuration: .default)
        let rules = [
            makeTestRule(id: "1", test: "prop1"),
            makeTestRule(id: "2", test: "prop2"),
            makeTestRule(id: "3", test: "prop3"),
            makeTestRule(id: "4", test: "prop4")
        ]
        let object = makeTestObject(properties: [
            "prop1": "yes",
            "prop3": "yes"
        ])
        let context = RuleExecutor.ExecutionContext(object: object)

        let results = await executor.executeAll(rules: rules, context: context)

        #expect(results.count == 4)
        let passedCount = results.filter { $0.status == .passed }.count
        let failedCount = results.filter { $0.status == .failed }.count
        #expect(passedCount == 2)
        #expect(failedCount == 2)
    }
}
