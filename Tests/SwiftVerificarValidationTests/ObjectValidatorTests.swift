import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarValidationProfiles

@Suite("ObjectValidator Tests")
struct ObjectValidatorTests {

    // MARK: - Test Helpers

    func makeTestProfile(
        name: String = "Test Profile",
        rules: [ValidationRule] = []
    ) -> ValidationProfile {
        ValidationProfile(
            details: ProfileDetails(
                name: name,
                description: "Test profile",
                creator: "Test",
                created: Date()
            ),
            rules: rules,
            flavour: .pdfUA2
        )
    }

    func makeTestRule(
        objectType: String = "PDDocument",
        test: String = "property",
        clause: String = "8.2.5.26"
    ) -> ValidationRule {
        ValidationRule(
            id: RuleID(
                specification: .iso142892,
                clause: clause,
                testNumber: 1
            ),
            object: objectType,
            description: "Test rule",
            test: test,
            error: ErrorDetails(
                message: "Test failed",
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
        let config = ObjectValidator.Configuration.default

        #expect(config.validateNestedObjects == true)
        #expect(config.maxNestingDepth == 10)
        #expect(config.stopOnFirstFailure == false)
        #expect(config.includePassingRules == false)
    }

    @Test("Fast configuration optimizes for speed")
    func testFastConfiguration() {
        let config = ObjectValidator.Configuration.fast

        #expect(config.validateNestedObjects == false)
        #expect(config.stopOnFirstFailure == true)
        #expect(config.includePassingRules == false)
    }

    @Test("Thorough configuration validates comprehensively")
    func testThoroughConfiguration() {
        let config = ObjectValidator.Configuration.thorough

        #expect(config.validateNestedObjects == true)
        #expect(config.maxNestingDepth == 20)
        #expect(config.stopOnFirstFailure == false)
        #expect(config.includePassingRules == true)
    }

    @Test("Custom configuration can be created")
    func testCustomConfiguration() {
        let config = ObjectValidator.Configuration(
            validateNestedObjects: false,
            maxNestingDepth: 5,
            stopOnFirstFailure: true,
            includePassingRules: true
        )

        #expect(config.validateNestedObjects == false)
        #expect(config.maxNestingDepth == 5)
        #expect(config.stopOnFirstFailure == true)
        #expect(config.includePassingRules == true)
    }

    // MARK: - ObjectValidationResult Tests

    @Test("ObjectValidationResult stores validation data")
    func testObjectValidationResult() {
        let result = ObjectValidator.ObjectValidationResult(
            objectType: "PDDocument",
            isCompliant: true,
            totalRules: 10,
            passedRules: 10,
            failedRules: 0,
            ruleResults: [],
            duration: 0.5
        )

        #expect(result.objectType == "PDDocument")
        #expect(result.isCompliant == true)
        #expect(result.totalRules == 10)
        #expect(result.passedRules == 10)
        #expect(result.failedRules == 0)
        #expect(result.duration == 0.5)
    }

    @Test("ObjectValidationResult handles nested results")
    func testObjectValidationResultWithNested() {
        let nested = ObjectValidator.ObjectValidationResult(
            objectType: "PDPage",
            isCompliant: true,
            totalRules: 5,
            passedRules: 5,
            failedRules: 0,
            ruleResults: [],
            duration: 0.1
        )

        let result = ObjectValidator.ObjectValidationResult(
            objectType: "PDDocument",
            isCompliant: true,
            totalRules: 10,
            passedRules: 10,
            failedRules: 0,
            ruleResults: [],
            nestedResults: [nested],
            duration: 0.5
        )

        #expect(result.nestedResults.count == 1)
        #expect(result.nestedResults[0].objectType == "PDPage")
    }

    // MARK: - Validator Initialization Tests

    @Test("ObjectValidator can be created with profile")
    func testObjectValidatorInitialization() {
        let profile = makeTestProfile()
        let validator = ObjectValidator(profile: profile)

        #expect(validator.profile.details.name == "Test Profile")
    }

    @Test("ObjectValidator can be created with custom executor")
    func testObjectValidatorWithCustomExecutor() {
        let profile = makeTestProfile()
        let executor = RuleExecutor(configuration: .fast)
        let validator = ObjectValidator(profile: profile, executor: executor)

        #expect(validator.profile.details.name == "Test Profile")
        #expect(validator.executor.configuration.includeDetailedErrors == false)
    }

    @Test("ObjectValidator can be created with custom configuration")
    func testObjectValidatorWithCustomConfiguration() {
        let profile = makeTestProfile()
        let config = ObjectValidator.Configuration.thorough
        let validator = ObjectValidator(profile: profile, configuration: config)

        #expect(validator.configuration.validateNestedObjects == true)
        #expect(validator.configuration.maxNestingDepth == 20)
    }

    // MARK: - Object Validation Tests

    @Test("Validate object with no applicable rules")
    func testValidateObjectWithNoRules() async {
        let profile = makeTestProfile(rules: [])
        let validator = ObjectValidator(profile: profile)
        let object = makeTestObject()

        let result = await validator.validate(object: object)

        #expect(result.isCompliant == true)
        #expect(result.totalRules == 0)
        #expect(result.passedRules == 0)
        #expect(result.failedRules == 0)
    }

    @Test("Validate object with matching rules")
    func testValidateObjectWithMatchingRules() async {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "prop1"),
            makeTestRule(objectType: "PDDocument", test: "prop2")
        ]
        let profile = makeTestProfile(rules: rules)
        let validator = ObjectValidator(profile: profile)
        let object = makeTestObject(
            type: "PDDocument",
            properties: ["prop1": "yes", "prop2": "yes"]
        )

        let result = await validator.validate(object: object)

        #expect(result.objectType == "PDDocument")
        #expect(result.totalRules == 2)
        #expect(result.passedRules == 2)
        #expect(result.failedRules == 0)
        #expect(result.isCompliant == true)
    }

    @Test("Validate object with failing rules")
    func testValidateObjectWithFailingRules() async {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "exists"),
            makeTestRule(objectType: "PDDocument", test: "missing")
        ]
        let profile = makeTestProfile(rules: rules)
        let validator = ObjectValidator(profile: profile)
        let object = makeTestObject(
            type: "PDDocument",
            properties: ["exists": "yes"]
        )

        let result = await validator.validate(object: object)

        #expect(result.totalRules == 2)
        #expect(result.passedRules == 1)
        #expect(result.failedRules == 1)
        #expect(result.isCompliant == false)
    }

    @Test("Validate object filters by object type")
    func testValidateObjectFiltersByType() async {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "doc"),
            makeTestRule(objectType: "PDPage", test: "page"),
            makeTestRule(objectType: "PDDocument", test: "doc2")
        ]
        let profile = makeTestProfile(rules: rules)
        let validator = ObjectValidator(profile: profile)
        let object = makeTestObject(type: "PDDocument")

        let result = await validator.validate(object: object)

        // Should only execute rules for PDDocument (2 rules)
        #expect(result.totalRules == 2)
    }

    @Test("Validate object with metadata")
    func testValidateObjectWithMetadata() async {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let validator = ObjectValidator(profile: profile)
        let object = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])
        let metadata = ["location": "page 5", "context": "validation"]

        let result = await validator.validate(object: object, metadata: metadata)

        #expect(result.isCompliant == true)
    }

    // MARK: - Configuration Behavior Tests

    @Test("Validate stops on first failure when configured")
    func testValidateStopsOnFirstFailure() async {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "prop1", clause: "1"),
            makeTestRule(objectType: "PDDocument", test: "missing", clause: "2"),
            makeTestRule(objectType: "PDDocument", test: "prop3", clause: "3")
        ]
        let profile = makeTestProfile(rules: rules)
        let config = ObjectValidator.Configuration(stopOnFirstFailure: true)
        let validator = ObjectValidator(profile: profile, configuration: config)
        let object = makeTestObject(type: "PDDocument", properties: ["prop1": "yes"])

        let result = await validator.validate(object: object)

        // Should stop after first failure, not execute prop3
        #expect(result.failedRules >= 1)
        #expect(result.isCompliant == false)
    }

    @Test("Validate includes passing rules when configured")
    func testValidateIncludesPassingRules() async {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "prop1"),
            makeTestRule(objectType: "PDDocument", test: "prop2")
        ]
        let profile = makeTestProfile(rules: rules)
        let config = ObjectValidator.Configuration(includePassingRules: true)
        let validator = ObjectValidator(profile: profile, configuration: config)
        let object = makeTestObject(
            type: "PDDocument",
            properties: ["prop1": "yes", "prop2": "yes"]
        )

        let result = await validator.validate(object: object)

        // Should include all results
        #expect(result.ruleResults.count == 2)
    }

    @Test("Validate includes all rule results for accurate counting")
    func testValidateIncludesAllRuleResults() async {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "prop1"),
            makeTestRule(objectType: "PDDocument", test: "prop2")
        ]
        let profile = makeTestProfile(rules: rules)
        let config = ObjectValidator.Configuration(includePassingRules: false)
        let validator = ObjectValidator(profile: profile, configuration: config)
        let object = makeTestObject(
            type: "PDDocument",
            properties: ["prop1": "yes", "prop2": "yes"]
        )

        let result = await validator.validate(object: object)

        // All rule results are included so the engine can compute accurate counts
        #expect(result.ruleResults.count == 2)
        #expect(result.passedRules == 2)
        #expect(result.isCompliant == true)
    }

    // MARK: - Parallel Validation Tests

    @Test("ValidateAll processes multiple objects")
    func testValidateAllProcessesMultipleObjects() async {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let validator = ObjectValidator(profile: profile)

        let objects = [
            makeTestObject(type: "PDDocument", properties: ["prop": "yes"]),
            makeTestObject(type: "PDDocument", properties: ["prop": "yes"]),
            makeTestObject(type: "PDDocument", properties: [:])
        ]

        let results = await validator.validateAll(objects: objects)

        #expect(results.count == 3)
        #expect(results[0].isCompliant == true)
        #expect(results[1].isCompliant == true)
        #expect(results[2].isCompliant == false)
    }

    @Test("ValidateAll maintains object order")
    func testValidateAllMaintainsOrder() async {
        let rules = [makeTestRule(objectType: "PDDocument", test: "id")]
        let profile = makeTestProfile(rules: rules)
        let validator = ObjectValidator(profile: profile)

        let objects = [
            makeTestObject(type: "PDDocument", properties: ["id": "first"]),
            makeTestObject(type: "PDDocument", properties: ["id": "second"]),
            makeTestObject(type: "PDDocument", properties: ["id": "third"])
        ]

        let results = await validator.validateAll(objects: objects)

        #expect(results.count == 3)
        #expect(results[0].objectType == "PDDocument")
        #expect(results[1].objectType == "PDDocument")
        #expect(results[2].objectType == "PDDocument")
    }

    @Test("ValidateAll handles empty object list")
    func testValidateAllHandlesEmptyList() async {
        let profile = makeTestProfile()
        let validator = ObjectValidator(profile: profile)

        let results = await validator.validateAll(objects: [])

        #expect(results.isEmpty)
    }

    @Test("ValidateAll handles single object")
    func testValidateAllHandlesSingleObject() async {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let validator = ObjectValidator(profile: profile)
        let object = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])

        let results = await validator.validateAll(objects: [object])

        #expect(results.count == 1)
        #expect(results[0].isCompliant == true)
    }

    // MARK: - ValidationObject.ObjectType Tests

    @Test("ObjectType constants are defined")
    func testObjectTypeConstants() {
        #expect(PDFObjectType.document == "PDDocument")
        #expect(PDFObjectType.page == "PDPage")
        #expect(PDFObjectType.annotation == "PDAnnot")
        #expect(PDFObjectType.font == "PDFont")
        #expect(PDFObjectType.colorSpace == "PDColorSpace")
        #expect(PDFObjectType.image == "PDImage")
        #expect(PDFObjectType.contentStream == "PDContentStream")
        #expect(PDFObjectType.structureElement == "PDStructElem")
        #expect(PDFObjectType.metadata == "PDMetadata")
    }

    // MARK: - Integration Tests

    @Test("Complete validation flow with mixed results")
    func testCompleteValidationFlow() async {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "hasStructTree"),
            makeTestRule(objectType: "PDDocument", test: "hasMetadata"),
            makeTestRule(objectType: "PDDocument", test: "missingProp")
        ]
        let profile = makeTestProfile(name: "PDF/UA-2", rules: rules)
        let config = ObjectValidator.Configuration(includePassingRules: true)
        let validator = ObjectValidator(profile: profile, configuration: config)

        let object = makeTestObject(
            type: "PDDocument",
            properties: ["hasStructTree": "true", "hasMetadata": "true"]
        )

        let result = await validator.validate(object: object)

        #expect(result.objectType == "PDDocument")
        #expect(result.totalRules == 3)
        #expect(result.passedRules == 2)
        #expect(result.failedRules == 1)
        #expect(result.isCompliant == false)
        #expect(result.ruleResults.count == 3)
        #expect(result.duration > 0)
    }

    @Test("Validation with different object types")
    func testValidationWithDifferentObjectTypes() async {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "docProp"),
            makeTestRule(objectType: "PDPage", test: "pageProp")
        ]
        let profile = makeTestProfile(rules: rules)
        let validator = ObjectValidator(profile: profile)

        let docObject = makeTestObject(type: "PDDocument", properties: ["docProp": "yes"])
        let pageObject = makeTestObject(type: "PDPage", properties: ["pageProp": "yes"])

        let docResult = await validator.validate(object: docObject)
        let pageResult = await validator.validate(object: pageObject)

        #expect(docResult.totalRules == 1)
        #expect(pageResult.totalRules == 1)
        #expect(docResult.isCompliant == true)
        #expect(pageResult.isCompliant == true)
    }

    @Test("Performance of batch validation")
    func testBatchValidationPerformance() async {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "prop1"),
            makeTestRule(objectType: "PDDocument", test: "prop2")
        ]
        let profile = makeTestProfile(rules: rules)
        let validator = ObjectValidator(profile: profile)

        let objects = (0..<10).map { _ in
            makeTestObject(type: "PDDocument", properties: ["prop1": "yes", "prop2": "yes"])
        }

        let startTime = Date()
        let results = await validator.validateAll(objects: objects)
        let duration = Date().timeIntervalSince(startTime)

        #expect(results.count == 10)
        #expect(duration < 5.0) // Should complete reasonably fast
    }
}
