import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarValidationProfiles

@Suite("ValidationEngine Tests")
struct ValidationEngineTests {

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
        clause: String = "8.2.5.26",
        testNumber: Int = 1
    ) -> ValidationRule {
        ValidationRule(
            id: RuleID(
                specification: .iso142892,
                clause: clause,
                testNumber: testNumber
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
        let config = PDFValidationEngine.Configuration.default

        #expect(config.enableParallelValidation == true)
        #expect(config.maxConcurrentTasks == 8)
        #expect(config.validationTimeout == nil)
        #expect(config.enableResultCaching == true)
    }

    @Test("Fast configuration optimizes for speed")
    func testFastConfiguration() {
        let config = PDFValidationEngine.Configuration.fast

        #expect(config.enableParallelValidation == true)
        #expect(config.maxConcurrentTasks == 16)
        #expect(config.enableResultCaching == true)
        #expect(config.executorConfig.includeDetailedErrors == false)
        #expect(config.validatorConfig.validateNestedObjects == false)
    }

    @Test("Thorough configuration validates comprehensively")
    func testThoroughConfiguration() {
        let config = PDFValidationEngine.Configuration.thorough

        #expect(config.enableParallelValidation == true)
        #expect(config.maxConcurrentTasks == 8)
        #expect(config.validationTimeout == 300.0)
        #expect(config.enableResultCaching == false)
        #expect(config.executorConfig.includeDetailedErrors == true)
        #expect(config.validatorConfig.validateNestedObjects == true)
    }

    @Test("Custom configuration can be created")
    func testCustomConfiguration() {
        let config = PDFValidationEngine.Configuration(
            enableParallelValidation: false,
            maxConcurrentTasks: 4,
            validationTimeout: 60.0,
            enableResultCaching: false,
            customMetadata: ["env": "test"]
        )

        #expect(config.enableParallelValidation == false)
        #expect(config.maxConcurrentTasks == 4)
        #expect(config.validationTimeout == 60.0)
        #expect(config.enableResultCaching == false)
        #expect(config.customMetadata["env"] == "test")
    }

    // MARK: - Statistics Tests

    @Test("Statistics stores validation metrics")
    func testStatisticsStorage() {
        let stats = PDFValidationEngine.Statistics(
            totalValidations: 10,
            totalRulesExecuted: 100,
            totalValidationTime: 5.0,
            cacheHits: 3
        )

        #expect(stats.totalValidations == 10)
        #expect(stats.totalRulesExecuted == 100)
        #expect(stats.totalValidationTime == 5.0)
        #expect(stats.cacheHits == 3)
    }

    @Test("Statistics calculates average validation time")
    func testStatisticsAverageTime() {
        let stats = PDFValidationEngine.Statistics(
            totalValidations: 10,
            totalRulesExecuted: 100,
            totalValidationTime: 10.0
        )

        #expect(stats.averageValidationTime == 1.0)
    }

    @Test("Statistics handles zero validations")
    func testStatisticsZeroValidations() {
        let stats = PDFValidationEngine.Statistics()

        #expect(stats.totalValidations == 0)
        #expect(stats.averageValidationTime == 0)
        #expect(stats.cacheHitRate == 0)
    }

    @Test("Statistics calculates cache hit rate")
    func testStatisticsCacheHitRate() {
        let stats = PDFValidationEngine.Statistics(
            totalValidations: 100,
            totalRulesExecuted: 1000,
            totalValidationTime: 50.0,
            cacheHits: 25
        )

        #expect(stats.cacheHitRate == 25.0)
    }

    // MARK: - Engine Initialization Tests

    @Test("ValidationEngine can be created with default configuration")
    func testEngineInitialization() async {
        let engine = PDFValidationEngine()

        let stats = await engine.getStatistics()
        #expect(stats.totalValidations == 0)
    }

    @Test("ValidationEngine can be created with custom configuration")
    func testEngineWithCustomConfiguration() async {
        let config = PDFValidationEngine.Configuration.fast
        let engine = PDFValidationEngine(configuration: config)

        let stats = await engine.getStatistics()
        #expect(stats.totalValidations == 0)
    }

    // MARK: - Document Validation Tests

    @Test("Validate document with no rules")
    func testValidateDocumentWithNoRules() async throws {
        let engine = PDFValidationEngine()
        let profile = makeTestProfile(rules: [])
        let document = makeTestObject()

        let result = try await engine.validate(document: document, profile: profile)

        #expect(result.isCompliant == true)
        #expect(result.totalRules == 0)
        #expect(result.passedRules == 0)
        #expect(result.failedRules == 0)
    }

    @Test("Validate document with passing rules")
    func testValidateDocumentWithPassingRules() async throws {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "prop1"),
            makeTestRule(objectType: "PDDocument", test: "prop2")
        ]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()
        let document = makeTestObject(
            type: "PDDocument",
            properties: ["prop1": "yes", "prop2": "yes"]
        )

        let result = try await engine.validate(document: document, profile: profile)

        #expect(result.isCompliant == true)
        #expect(result.totalRules == 2)
        #expect(result.passedRules == 2)
        #expect(result.failedRules == 0)
        #expect(result.profileName == "Test Profile")
    }

    @Test("Validate document with failing rules")
    func testValidateDocumentWithFailingRules() async throws {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "exists"),
            makeTestRule(objectType: "PDDocument", test: "missing")
        ]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()
        let document = makeTestObject(
            type: "PDDocument",
            properties: ["exists": "yes"]
        )

        let result = try await engine.validate(document: document, profile: profile)

        #expect(result.isCompliant == false)
        #expect(result.totalRules == 2)
        #expect(result.passedRules == 1)
        #expect(result.failedRules == 1)
    }

    @Test("Validate document with mixed rule results")
    func testValidateDocumentWithMixedResults() async throws {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "prop1", testNumber: 1),
            makeTestRule(objectType: "PDDocument", test: "prop2", testNumber: 2),
            makeTestRule(objectType: "PDDocument", test: "prop3", testNumber: 3),
            makeTestRule(objectType: "PDDocument", test: "prop4", testNumber: 4)
        ]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()
        let document = makeTestObject(
            type: "PDDocument",
            properties: ["prop1": "yes", "prop3": "yes"]
        )

        let result = try await engine.validate(document: document, profile: profile)

        #expect(result.totalRules == 4)
        #expect(result.passedRules == 2)
        #expect(result.failedRules == 2)
        #expect(result.isCompliant == false)
    }

    @Test("Validate document records duration")
    func testValidateDocumentRecordsDuration() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()
        let document = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])

        let result = try await engine.validate(document: document, profile: profile)

        #expect(result.duration > 0)
    }

    @Test("Validate document calculates compliance percentage")
    func testValidateDocumentCompliancePercentage() async throws {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "prop1", testNumber: 1),
            makeTestRule(objectType: "PDDocument", test: "prop2", testNumber: 2)
        ]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()
        let document = makeTestObject(
            type: "PDDocument",
            properties: ["prop1": "yes"]
        )

        let result = try await engine.validate(document: document, profile: profile)

        #expect(result.compliancePercentage == 50.0)
    }

    // MARK: - Statistics Tracking Tests

    @Test("Engine tracks validation statistics")
    func testEngineTracksStatistics() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()
        let document = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])

        _ = try await engine.validate(document: document, profile: profile)

        let stats = await engine.getStatistics()
        #expect(stats.totalValidations == 1)
        #expect(stats.totalRulesExecuted == 1)
        #expect(stats.totalValidationTime > 0)
    }

    @Test("Engine accumulates statistics over multiple validations")
    func testEngineAccumulatesStatistics() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()
        let document = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])

        _ = try await engine.validate(document: document, profile: profile)
        _ = try await engine.validate(document: document, profile: profile)
        _ = try await engine.validate(document: document, profile: profile)

        let stats = await engine.getStatistics()
        #expect(stats.totalValidations == 3)
        #expect(stats.totalRulesExecuted == 3)
    }

    @Test("Engine can reset statistics")
    func testEngineResetStatistics() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()
        let document = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])

        _ = try await engine.validate(document: document, profile: profile)

        await engine.resetStatistics()

        let stats = await engine.getStatistics()
        #expect(stats.totalValidations == 0)
        #expect(stats.totalRulesExecuted == 0)
    }

    // MARK: - Caching Tests

    @Test("Engine caches validation results when enabled")
    func testEngineCachesResults() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let config = PDFValidationEngine.Configuration(enableResultCaching: true)
        let engine = PDFValidationEngine(configuration: config)
        let document = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])

        let result1 = try await engine.validate(document: document, profile: profile)
        let result2 = try await engine.validate(document: document, profile: profile)

        let stats = await engine.getStatistics()
        #expect(stats.totalValidations == 2)
        #expect(stats.cacheHits == 1)
        #expect(result1.isCompliant == result2.isCompliant)
    }

    @Test("Engine does not cache when disabled")
    func testEngineDoesNotCacheWhenDisabled() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let config = PDFValidationEngine.Configuration(enableResultCaching: false)
        let engine = PDFValidationEngine(configuration: config)
        let document = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])

        _ = try await engine.validate(document: document, profile: profile)
        _ = try await engine.validate(document: document, profile: profile)

        let stats = await engine.getStatistics()
        #expect(stats.totalValidations == 2)
        #expect(stats.cacheHits == 0)
    }

    @Test("Engine can clear cache")
    func testEngineClearCache() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let config = PDFValidationEngine.Configuration(enableResultCaching: true)
        let engine = PDFValidationEngine(configuration: config)
        let document = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])

        _ = try await engine.validate(document: document, profile: profile)
        await engine.clearCache()
        _ = try await engine.validate(document: document, profile: profile)

        let stats = await engine.getStatistics()
        #expect(stats.cacheHits == 0)
    }

    // MARK: - Parallel Validation Tests

    @Test("ValidateAll processes multiple documents")
    func testValidateAllProcessesMultipleDocuments() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()

        let documents = [
            makeTestObject(type: "PDDocument", properties: ["prop": "yes"]),
            makeTestObject(type: "PDDocument", properties: ["prop": "yes"]),
            makeTestObject(type: "PDDocument", properties: [:])
        ]

        let results = try await engine.validateAll(documents: documents, profile: profile)

        #expect(results.count == 3)
        #expect(results[0].isCompliant == true)
        #expect(results[1].isCompliant == true)
        #expect(results[2].isCompliant == false)
    }

    @Test("ValidateAll maintains document order")
    func testValidateAllMaintainsOrder() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "id")]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()

        let documents = [
            makeTestObject(type: "PDDocument", properties: ["id": "first"]),
            makeTestObject(type: "PDDocument", properties: ["id": "second"]),
            makeTestObject(type: "PDDocument", properties: ["id": "third"])
        ]

        let results = try await engine.validateAll(documents: documents, profile: profile)

        #expect(results.count == 3)
        #expect(results[0].isCompliant == true)
        #expect(results[1].isCompliant == true)
        #expect(results[2].isCompliant == true)
    }

    @Test("ValidateAll handles empty document list")
    func testValidateAllHandlesEmptyList() async throws {
        let profile = makeTestProfile()
        let engine = PDFValidationEngine()

        let results = try await engine.validateAll(documents: [], profile: profile)

        #expect(results.isEmpty)
    }

    @Test("ValidateAll with parallel validation disabled")
    func testValidateAllSequential() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let config = PDFValidationEngine.Configuration(enableParallelValidation: false)
        let engine = PDFValidationEngine(configuration: config)

        let documents = [
            makeTestObject(type: "PDDocument", properties: ["prop": "yes"]),
            makeTestObject(type: "PDDocument", properties: ["prop": "yes"])
        ]

        let results = try await engine.validateAll(documents: documents, profile: profile)

        #expect(results.count == 2)
        #expect(results[0].isCompliant == true)
        #expect(results[1].isCompliant == true)
    }

    // MARK: - Integration Tests

    @Test("Complete validation flow with complex profile")
    func testCompleteValidationFlow() async throws {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "hasStructTree", testNumber: 1),
            makeTestRule(objectType: "PDDocument", test: "hasMetadata", testNumber: 2),
            makeTestRule(objectType: "PDDocument", test: "hasTitle", testNumber: 3),
            makeTestRule(objectType: "PDDocument", test: "hasLang", testNumber: 4)
        ]
        let profile = makeTestProfile(name: "PDF/UA-2 Full", rules: rules)
        let engine = PDFValidationEngine(configuration: .thorough)

        let document = makeTestObject(
            type: "PDDocument",
            properties: [
                "hasStructTree": "true",
                "hasMetadata": "true",
                "hasTitle": "true"
            ]
        )

        let result = try await engine.validate(document: document, profile: profile)

        #expect(result.profileName == "PDF/UA-2 Full")
        #expect(result.totalRules == 4)
        #expect(result.passedRules == 3)
        #expect(result.failedRules == 1)
        #expect(result.isCompliant == false)
        #expect(result.compliancePercentage == 75.0)
        #expect(result.duration > 0)
    }

    @Test("Validation with custom metadata")
    func testValidationWithCustomMetadata() async throws {
        let rules = [makeTestRule(objectType: "PDDocument", test: "prop")]
        let profile = makeTestProfile(rules: rules)
        let config = PDFValidationEngine.Configuration(
            customMetadata: ["environment": "test", "version": "1.0"]
        )
        let engine = PDFValidationEngine(configuration: config)
        let document = makeTestObject(type: "PDDocument", properties: ["prop": "yes"])

        let result = try await engine.validate(document: document, profile: profile)

        #expect(result.isCompliant == true)
    }

    @Test("Performance of batch validation")
    func testBatchValidationPerformance() async throws {
        let rules = [
            makeTestRule(objectType: "PDDocument", test: "prop1"),
            makeTestRule(objectType: "PDDocument", test: "prop2")
        ]
        let profile = makeTestProfile(rules: rules)
        let engine = PDFValidationEngine()

        let documents = (0..<20).map { _ in
            makeTestObject(type: "PDDocument", properties: ["prop1": "yes", "prop2": "yes"])
        }

        let startTime = Date()
        let results = try await engine.validateAll(documents: documents, profile: profile)
        let duration = Date().timeIntervalSince(startTime)

        #expect(results.count == 20)
        #expect(results.allSatisfy { $0.isCompliant })
        #expect(duration < 10.0) // Should complete reasonably fast
    }
}
