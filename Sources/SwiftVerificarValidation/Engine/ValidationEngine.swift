import Foundation
import SwiftVerificarValidationProfiles

/// Main validation engine orchestrating PDF document validation.
///
/// `PDFValidationEngine` is the primary actor responsible for coordinating
/// the entire PDF validation process. It manages:
/// - Document-level validation orchestration
/// - Profile loading and management
/// - Parallel validation of document components
/// - Result aggregation and reporting
/// - Resource management and caching
///
/// ## Example
/// ```swift
/// let engine = PDFValidationEngine(configuration: .thorough)
///
/// // Load a validation profile
/// let profile = try await ProfileLoader.shared.loadProfile(for: .pdfUA2)
///
/// // Validate a document
/// let result = await engine.validate(
///     document: pdfDocument,
///     profile: profile
/// )
///
/// print("Compliant: \(result.isCompliant)")
/// print("Passed: \(result.passedRules)/\(result.totalRules)")
/// ```
public actor PDFValidationEngine {

    /// Configuration for the validation engine
    public struct Configuration: Sendable {
        /// Configuration for the rule executor
        public let executorConfig: RuleExecutor.Configuration

        /// Configuration for object validators
        public let validatorConfig: ObjectValidator.Configuration

        /// Whether to enable parallel validation of objects
        public let enableParallelValidation: Bool

        /// Maximum number of concurrent validation tasks
        public let maxConcurrentTasks: Int

        /// Validation timeout in seconds
        public let validationTimeout: TimeInterval?

        /// Whether to cache validation results
        public let enableResultCaching: Bool

        /// Custom metadata to include in results
        public let customMetadata: [String: String]

        public init(
            executorConfig: RuleExecutor.Configuration = .default,
            validatorConfig: ObjectValidator.Configuration = .default,
            enableParallelValidation: Bool = true,
            maxConcurrentTasks: Int = 8,
            validationTimeout: TimeInterval? = nil,
            enableResultCaching: Bool = true,
            customMetadata: [String: String] = [:]
        ) {
            self.executorConfig = executorConfig
            self.validatorConfig = validatorConfig
            self.enableParallelValidation = enableParallelValidation
            self.maxConcurrentTasks = maxConcurrentTasks
            self.validationTimeout = validationTimeout
            self.enableResultCaching = enableResultCaching
            self.customMetadata = customMetadata
        }

        /// Default configuration
        public static let `default` = Configuration()

        /// Fast configuration optimized for speed
        public static let fast = Configuration(
            executorConfig: .fast,
            validatorConfig: .fast,
            enableParallelValidation: true,
            maxConcurrentTasks: 16,
            enableResultCaching: true
        )

        /// Thorough configuration for comprehensive validation
        public static let thorough = Configuration(
            executorConfig: .thorough,
            validatorConfig: .thorough,
            enableParallelValidation: true,
            maxConcurrentTasks: 8,
            validationTimeout: 300.0,
            enableResultCaching: false
        )
    }

    /// Statistics about validation engine operations
    public struct Statistics: Sendable {
        /// Total number of validations performed
        public let totalValidations: Int

        /// Total number of rules executed
        public let totalRulesExecuted: Int

        /// Total validation time in seconds
        public let totalValidationTime: TimeInterval

        /// Average validation time in seconds
        public var averageValidationTime: TimeInterval {
            guard totalValidations > 0 else { return 0 }
            return totalValidationTime / Double(totalValidations)
        }

        /// Number of cached results used
        public let cacheHits: Int

        /// Cache hit rate as percentage
        public var cacheHitRate: Double {
            guard totalValidations > 0 else { return 0 }
            return (Double(cacheHits) / Double(totalValidations)) * 100.0
        }

        public init(
            totalValidations: Int = 0,
            totalRulesExecuted: Int = 0,
            totalValidationTime: TimeInterval = 0,
            cacheHits: Int = 0
        ) {
            self.totalValidations = totalValidations
            self.totalRulesExecuted = totalRulesExecuted
            self.totalValidationTime = totalValidationTime
            self.cacheHits = cacheHits
        }
    }

    /// The engine configuration
    public let configuration: Configuration

    /// Rule executor instance
    private let executor: RuleExecutor

    /// Result cache (when caching is enabled)
    private var resultCache: [String: ValidationResult] = [:]

    /// Validation statistics
    private var statistics: Statistics = Statistics()

    /// Creates a new validation engine with the specified configuration
    ///
    /// - Parameter configuration: The engine configuration
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.executor = RuleExecutor(configuration: configuration.executorConfig)
    }

    /// Validates a document against a validation profile
    ///
    /// This is the main entry point for document validation. It orchestrates
    /// the entire validation process including object validation, rule execution,
    /// and result aggregation.
    ///
    /// - Parameters:
    ///   - document: The document to validate (as a ValidationObject)
    ///   - profile: The validation profile to use
    /// - Returns: Complete validation result
    /// - Throws: ValidationError if validation fails
    public func validate(
        document: ValidationObject,
        profile: ValidationProfile
    ) async throws -> ValidationResult {
        let startTime = Date()

        // Check cache if enabled
        if configuration.enableResultCaching {
            let cacheKey = makeCacheKey(document: document, profile: profile)
            if let cachedResult = resultCache[cacheKey] {
                statistics = Statistics(
                    totalValidations: statistics.totalValidations + 1,
                    totalRulesExecuted: statistics.totalRulesExecuted,
                    totalValidationTime: statistics.totalValidationTime,
                    cacheHits: statistics.cacheHits + 1
                )
                return cachedResult
            }
        }

        // Apply timeout if configured
        let result: ValidationResult
        if let timeout = configuration.validationTimeout {
            result = try await withThrowingTimeout(timeout) {
                try await self.performValidation(
                    document: document,
                    profile: profile,
                    startTime: startTime
                )
            }
        } else {
            result = try await performValidation(
                document: document,
                profile: profile,
                startTime: startTime
            )
        }

        // Update statistics
        let duration = Date().timeIntervalSince(startTime)
        statistics = Statistics(
            totalValidations: statistics.totalValidations + 1,
            totalRulesExecuted: statistics.totalRulesExecuted + result.totalRules,
            totalValidationTime: statistics.totalValidationTime + duration,
            cacheHits: statistics.cacheHits
        )

        // Cache result if enabled
        if configuration.enableResultCaching {
            let cacheKey = makeCacheKey(document: document, profile: profile)
            resultCache[cacheKey] = result
        }

        return result
    }

    /// Validates multiple documents in parallel
    ///
    /// - Parameters:
    ///   - documents: The documents to validate
    ///   - profile: The validation profile to use
    /// - Returns: Array of validation results in the same order as input
    public func validateAll(
        documents: [ValidationObject],
        profile: ValidationProfile
    ) async throws -> [ValidationResult] {
        if configuration.enableParallelValidation {
            return try await withThrowingTaskGroup(of: (Int, ValidationResult).self) { group in
                for (index, document) in documents.enumerated() {
                    group.addTask {
                        let result = try await self.validate(document: document, profile: profile)
                        return (index, result)
                    }
                }

                var results: [(Int, ValidationResult)] = []
                for try await result in group {
                    results.append(result)
                }

                return results.sorted { $0.0 < $1.0 }.map { $0.1 }
            }
        } else {
            // Sequential validation
            var results: [ValidationResult] = []
            for document in documents {
                let result = try await validate(document: document, profile: profile)
                results.append(result)
            }
            return results
        }
    }

    /// Gets current validation statistics
    ///
    /// - Returns: Current engine statistics
    public func getStatistics() -> Statistics {
        statistics
    }

    /// Clears the result cache
    public func clearCache() {
        resultCache.removeAll()
    }

    /// Resets all statistics
    public func resetStatistics() {
        statistics = Statistics()
    }

    // MARK: - Private Methods

    private func performValidation(
        document: ValidationObject,
        profile: ValidationProfile,
        startTime: Date
    ) async throws -> ValidationResult {
        // Create object validator
        let validator = ObjectValidator(
            profile: profile,
            executor: executor,
            configuration: configuration.validatorConfig
        )

        // Validate the document object
        let objectResult = await validator.validate(
            object: document,
            metadata: configuration.customMetadata
        )

        // Aggregate results
        let allRuleResults = collectAllRuleResults(from: objectResult)
        let passedCount = allRuleResults.filter { $0.status == .passed }.count
        let failedCount = allRuleResults.filter { $0.status == .failed }.count
        let isCompliant = failedCount == 0 &&
            allRuleResults.filter { $0.status == .error }.isEmpty

        let duration = Date().timeIntervalSince(startTime)

        return ValidationResult(
            isCompliant: isCompliant,
            profileName: profile.details.name,
            totalRules: allRuleResults.count,
            passedRules: passedCount,
            failedRules: failedCount,
            ruleResults: allRuleResults,
            duration: duration
        )
    }

    private func collectAllRuleResults(
        from objectResult: ObjectValidator.ObjectValidationResult
    ) -> [RuleResult] {
        var results = objectResult.ruleResults

        // Recursively collect results from nested validations
        for nested in objectResult.nestedResults {
            results.append(contentsOf: collectAllRuleResults(from: nested))
        }

        return results
    }

    private func makeCacheKey(
        document: ValidationObject,
        profile: ValidationProfile
    ) -> String {
        // Simple cache key based on document type and profile ID
        "\(document.objectType)-\(profile.details.name)-\(profile.flavour.rawValue)"
    }

    private func withThrowingTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T where T: Sendable {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw ValidationError(
                    code: .internalError,
                    message: "Validation timed out after \(timeout) seconds"
                )
            }

            // Return first result and cancel the other
            guard let result = try await group.next() else {
                throw ValidationError(
                    code: .internalError,
                    message: "Validation task group failed unexpectedly"
                )
            }
            group.cancelAll()
            return result
        }
    }
}
