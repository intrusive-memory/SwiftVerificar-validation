import Foundation
import Testing
@testable import SwiftVerificarValidation

@Suite("ValidatorConfiguration Tests")
struct ValidatorConfigurationTests {

    // MARK: - Default Initialization Tests

    @Test("Create configuration with default values")
    func createWithDefaults() {
        let config = ValidatorConfiguration()

        #expect(config.stopOnFirstError == false)
        #expect(config.maxErrors == nil)
        #expect(config.includeWarnings == true)
        #expect(config.enableFeatureReporting == false)
        #expect(config.enableParallelValidation == true)
        #expect(config.maxConcurrentTasks == 8)
        #expect(config.validationTimeout == nil)
        #expect(config.customMetadata.isEmpty)
        #expect(config.loggingLevel == .warning)
    }

    @Test("Create configuration with custom values")
    func createWithCustomValues() {
        let config = ValidatorConfiguration(
            stopOnFirstError: true,
            maxErrors: 100,
            includeWarnings: false,
            enableFeatureReporting: true,
            enableParallelValidation: false,
            maxConcurrentTasks: 4,
            validationTimeout: 60.0,
            customMetadata: ["key": "value"],
            loggingLevel: .debug
        )

        #expect(config.stopOnFirstError == true)
        #expect(config.maxErrors == 100)
        #expect(config.includeWarnings == false)
        #expect(config.enableFeatureReporting == true)
        #expect(config.enableParallelValidation == false)
        #expect(config.maxConcurrentTasks == 4)
        #expect(config.validationTimeout == 60.0)
        #expect(config.customMetadata["key"] == "value")
        #expect(config.loggingLevel == .debug)
    }

    // MARK: - Preset Configuration Tests

    @Test("Fast preset configuration")
    func fastPreset() {
        let config = ValidatorConfiguration.fast

        #expect(config.stopOnFirstError == true)
        #expect(config.enableFeatureReporting == false)
        #expect(config.enableParallelValidation == true)
        #expect(config.maxConcurrentTasks == 16)
    }

    @Test("Thorough preset configuration")
    func thoroughPreset() {
        let config = ValidatorConfiguration.thorough

        #expect(config.stopOnFirstError == false)
        #expect(config.includeWarnings == true)
        #expect(config.enableFeatureReporting == true)
        #expect(config.enableParallelValidation == true)
        #expect(config.maxConcurrentTasks == 8)
    }

    @Test("Default preset configuration")
    func defaultPreset() {
        let defaultConfig = ValidatorConfiguration.default
        let explicitDefault = ValidatorConfiguration()

        #expect(defaultConfig.stopOnFirstError == explicitDefault.stopOnFirstError)
        #expect(defaultConfig.includeWarnings == explicitDefault.includeWarnings)
        #expect(defaultConfig.enableParallelValidation == explicitDefault.enableParallelValidation)
        #expect(defaultConfig.loggingLevel == explicitDefault.loggingLevel)
    }

    // MARK: - Stop on First Error Tests

    @Test("Stop on first error enabled")
    func stopOnFirstErrorEnabled() {
        let config = ValidatorConfiguration(stopOnFirstError: true)
        #expect(config.stopOnFirstError == true)
    }

    @Test("Stop on first error disabled")
    func stopOnFirstErrorDisabled() {
        let config = ValidatorConfiguration(stopOnFirstError: false)
        #expect(config.stopOnFirstError == false)
    }

    // MARK: - Max Errors Tests

    @Test("Max errors set to specific value")
    func maxErrorsSet() {
        let config = ValidatorConfiguration(maxErrors: 50)
        #expect(config.maxErrors == 50)
    }

    @Test("Max errors nil for unlimited")
    func maxErrorsUnlimited() {
        let config = ValidatorConfiguration(maxErrors: nil)
        #expect(config.maxErrors == nil)
    }

    @Test("Max errors set to zero")
    func maxErrorsZero() {
        let config = ValidatorConfiguration(maxErrors: 0)
        #expect(config.maxErrors == 0)
    }

    // MARK: - Include Warnings Tests

    @Test("Include warnings enabled")
    func includeWarningsEnabled() {
        let config = ValidatorConfiguration(includeWarnings: true)
        #expect(config.includeWarnings == true)
    }

    @Test("Include warnings disabled")
    func includeWarningsDisabled() {
        let config = ValidatorConfiguration(includeWarnings: false)
        #expect(config.includeWarnings == false)
    }

    // MARK: - Feature Reporting Tests

    @Test("Feature reporting enabled")
    func featureReportingEnabled() {
        let config = ValidatorConfiguration(enableFeatureReporting: true)
        #expect(config.enableFeatureReporting == true)
    }

    @Test("Feature reporting disabled")
    func featureReportingDisabled() {
        let config = ValidatorConfiguration(enableFeatureReporting: false)
        #expect(config.enableFeatureReporting == false)
    }

    // MARK: - Parallel Validation Tests

    @Test("Parallel validation enabled")
    func parallelValidationEnabled() {
        let config = ValidatorConfiguration(enableParallelValidation: true)
        #expect(config.enableParallelValidation == true)
    }

    @Test("Parallel validation disabled")
    func parallelValidationDisabled() {
        let config = ValidatorConfiguration(enableParallelValidation: false)
        #expect(config.enableParallelValidation == false)
    }

    // MARK: - Max Concurrent Tasks Tests

    @Test("Max concurrent tasks default value")
    func maxConcurrentTasksDefault() {
        let config = ValidatorConfiguration()
        #expect(config.maxConcurrentTasks == 8)
    }

    @Test("Max concurrent tasks custom value")
    func maxConcurrentTasksCustom() {
        let config = ValidatorConfiguration(maxConcurrentTasks: 16)
        #expect(config.maxConcurrentTasks == 16)
    }

    @Test("Max concurrent tasks single thread")
    func maxConcurrentTasksSingleThread() {
        let config = ValidatorConfiguration(maxConcurrentTasks: 1)
        #expect(config.maxConcurrentTasks == 1)
    }

    // MARK: - Validation Timeout Tests

    @Test("Validation timeout set")
    func validationTimeoutSet() {
        let config = ValidatorConfiguration(validationTimeout: 30.0)
        #expect(config.validationTimeout == 30.0)
    }

    @Test("Validation timeout nil for unlimited")
    func validationTimeoutUnlimited() {
        let config = ValidatorConfiguration(validationTimeout: nil)
        #expect(config.validationTimeout == nil)
    }

    @Test("Validation timeout fractional seconds")
    func validationTimeoutFractional() {
        let config = ValidatorConfiguration(validationTimeout: 2.5)
        #expect(config.validationTimeout == 2.5)
    }

    // MARK: - Custom Metadata Tests

    @Test("Custom metadata empty by default")
    func customMetadataEmpty() {
        let config = ValidatorConfiguration()
        #expect(config.customMetadata.isEmpty)
    }

    @Test("Custom metadata with single entry")
    func customMetadataSingle() {
        let config = ValidatorConfiguration(
            customMetadata: ["version": "1.0"]
        )
        #expect(config.customMetadata.count == 1)
        #expect(config.customMetadata["version"] == "1.0")
    }

    @Test("Custom metadata with multiple entries")
    func customMetadataMultiple() {
        let config = ValidatorConfiguration(
            customMetadata: [
                "version": "1.0",
                "author": "Test",
                "context": "CI"
            ]
        )
        #expect(config.customMetadata.count == 3)
        #expect(config.customMetadata["version"] == "1.0")
        #expect(config.customMetadata["author"] == "Test")
        #expect(config.customMetadata["context"] == "CI")
    }

    // MARK: - Logging Level Tests

    @Test("Logging level none")
    func loggingLevelNone() {
        let config = ValidatorConfiguration(loggingLevel: .none)
        #expect(config.loggingLevel == .none)
    }

    @Test("Logging level error")
    func loggingLevelError() {
        let config = ValidatorConfiguration(loggingLevel: .error)
        #expect(config.loggingLevel == .error)
    }

    @Test("Logging level warning")
    func loggingLevelWarning() {
        let config = ValidatorConfiguration(loggingLevel: .warning)
        #expect(config.loggingLevel == .warning)
    }

    @Test("Logging level info")
    func loggingLevelInfo() {
        let config = ValidatorConfiguration(loggingLevel: .info)
        #expect(config.loggingLevel == .info)
    }

    @Test("Logging level debug")
    func loggingLevelDebug() {
        let config = ValidatorConfiguration(loggingLevel: .debug)
        #expect(config.loggingLevel == .debug)
    }

    @Test("All logging levels have unique raw values")
    func loggingLevelsUnique() {
        let levels: [ValidatorConfiguration.LoggingLevel] = [
            .none, .error, .warning, .info, .debug
        ]

        let rawValues = levels.map { $0.rawValue }
        let uniqueValues = Set(rawValues)

        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("Logging levels are Codable")
    func loggingLevelsAreCodable() throws {
        let level = ValidatorConfiguration.LoggingLevel.debug

        let encoder = JSONEncoder()
        let data = try encoder.encode(level)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ValidatorConfiguration.LoggingLevel.self, from: data)

        #expect(decoded == level)
    }

    @Test("Logging level raw values")
    func loggingLevelRawValues() {
        #expect(ValidatorConfiguration.LoggingLevel.none.rawValue == "none")
        #expect(ValidatorConfiguration.LoggingLevel.error.rawValue == "error")
        #expect(ValidatorConfiguration.LoggingLevel.warning.rawValue == "warning")
        #expect(ValidatorConfiguration.LoggingLevel.info.rawValue == "info")
        #expect(ValidatorConfiguration.LoggingLevel.debug.rawValue == "debug")
    }

    // MARK: - Sendable Conformance

    @Test("ValidatorConfiguration is Sendable")
    func isSendable() {
        let config = ValidatorConfiguration()

        Task {
            let _ = config
            #expect(true)
        }
    }

    // MARK: - Preset Comparison Tests

    @Test("Fast preset is different from thorough")
    func fastVsThorough() {
        let fast = ValidatorConfiguration.fast
        let thorough = ValidatorConfiguration.thorough

        #expect(fast.stopOnFirstError != thorough.stopOnFirstError)
        #expect(fast.enableFeatureReporting != thorough.enableFeatureReporting)
    }

    @Test("Fast preset is optimized for speed")
    func fastOptimization() {
        let fast = ValidatorConfiguration.fast

        #expect(fast.stopOnFirstError == true)
        #expect(fast.enableFeatureReporting == false)
        #expect(fast.maxConcurrentTasks >= 16)
    }

    @Test("Thorough preset is optimized for completeness")
    func thoroughOptimization() {
        let thorough = ValidatorConfiguration.thorough

        #expect(thorough.stopOnFirstError == false)
        #expect(thorough.includeWarnings == true)
        #expect(thorough.enableFeatureReporting == true)
    }

    // MARK: - Configuration Scenario Tests

    @Test("Configuration for CI/CD environment")
    func cicdConfiguration() {
        let config = ValidatorConfiguration(
            stopOnFirstError: false,
            includeWarnings: true,
            enableParallelValidation: true,
            validationTimeout: 300.0,
            customMetadata: ["env": "CI"],
            loggingLevel: .info
        )

        #expect(config.stopOnFirstError == false)
        #expect(config.validationTimeout == 300.0)
        #expect(config.customMetadata["env"] == "CI")
    }

    @Test("Configuration for quick validation check")
    func quickCheckConfiguration() {
        let config = ValidatorConfiguration(
            stopOnFirstError: true,
            maxErrors: 1,
            includeWarnings: false,
            enableFeatureReporting: false,
            validationTimeout: 5.0
        )

        #expect(config.stopOnFirstError == true)
        #expect(config.maxErrors == 1)
        #expect(config.validationTimeout == 5.0)
    }

    @Test("Configuration for detailed analysis")
    func detailedAnalysisConfiguration() {
        let config = ValidatorConfiguration(
            stopOnFirstError: false,
            maxErrors: nil,
            includeWarnings: true,
            enableFeatureReporting: true,
            enableParallelValidation: true,
            loggingLevel: .debug
        )

        #expect(config.maxErrors == nil)
        #expect(config.includeWarnings == true)
        #expect(config.enableFeatureReporting == true)
        #expect(config.loggingLevel == .debug)
    }
}
