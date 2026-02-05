import Foundation
import SwiftVerificarValidationProfiles

/// Validates individual PDF objects against rules from a validation profile.
///
/// `ObjectValidator` coordinates the validation of a single PDF object,
/// selecting appropriate rules from a profile and executing them via a
/// `RuleExecutor`. It provides:
/// - Rule filtering based on object type
/// - Object-level validation orchestration
/// - Result aggregation
/// - Support for nested object validation
///
/// ## Example
/// ```swift
/// let validator = ObjectValidator(
///     profile: pdfUA2Profile,
///     executor: ruleExecutor
/// )
///
/// let result = await validator.validate(object: pdfDocument)
/// if !result.isCompliant {
///     print("Found \(result.failedRules) validation failures")
/// }
/// ```
public struct ObjectValidator: Sendable {

    /// Configuration for object validation
    public struct Configuration: Sendable {
        /// Whether to validate nested objects recursively
        public let validateNestedObjects: Bool

        /// Maximum depth for nested validation
        public let maxNestingDepth: Int

        /// Whether to stop on first failure
        public let stopOnFirstFailure: Bool

        /// Whether to include passing rules in results
        public let includePassingRules: Bool

        public init(
            validateNestedObjects: Bool = true,
            maxNestingDepth: Int = 10,
            stopOnFirstFailure: Bool = false,
            includePassingRules: Bool = false
        ) {
            self.validateNestedObjects = validateNestedObjects
            self.maxNestingDepth = maxNestingDepth
            self.stopOnFirstFailure = stopOnFirstFailure
            self.includePassingRules = includePassingRules
        }

        /// Default configuration
        public static let `default` = Configuration()

        /// Fast configuration that stops on first failure
        public static let fast = Configuration(
            validateNestedObjects: false,
            stopOnFirstFailure: true,
            includePassingRules: false
        )

        /// Thorough configuration that validates everything
        public static let thorough = Configuration(
            validateNestedObjects: true,
            maxNestingDepth: 20,
            stopOnFirstFailure: false,
            includePassingRules: true
        )
    }

    /// Result of validating an object
    public struct ObjectValidationResult: Sendable {
        /// The object that was validated
        public let objectType: String

        /// Whether the object is compliant
        public let isCompliant: Bool

        /// Total number of rules checked
        public let totalRules: Int

        /// Number of passed rules
        public let passedRules: Int

        /// Number of failed rules
        public let failedRules: Int

        /// Individual rule results
        public let ruleResults: [RuleResult]

        /// Results from nested object validation
        public let nestedResults: [ObjectValidationResult]

        /// Validation duration
        public let duration: TimeInterval

        public init(
            objectType: String,
            isCompliant: Bool,
            totalRules: Int,
            passedRules: Int,
            failedRules: Int,
            ruleResults: [RuleResult],
            nestedResults: [ObjectValidationResult] = [],
            duration: TimeInterval
        ) {
            self.objectType = objectType
            self.isCompliant = isCompliant
            self.totalRules = totalRules
            self.passedRules = passedRules
            self.failedRules = failedRules
            self.ruleResults = ruleResults
            self.nestedResults = nestedResults
            self.duration = duration
        }
    }

    /// The validation profile containing rules
    public let profile: ValidationProfile

    /// The rule executor to use
    public let executor: RuleExecutor

    /// Configuration for this validator
    public let configuration: Configuration

    /// Creates a new object validator
    ///
    /// - Parameters:
    ///   - profile: The validation profile to use
    ///   - executor: The rule executor to use (defaults to new executor)
    ///   - configuration: The validation configuration
    public init(
        profile: ValidationProfile,
        executor: RuleExecutor = RuleExecutor(),
        configuration: Configuration = .default
    ) {
        self.profile = profile
        self.executor = executor
        self.configuration = configuration
    }

    /// Validates a PDF object against the profile rules
    ///
    /// - Parameters:
    ///   - object: The object to validate
    ///   - metadata: Additional metadata about the object
    ///   - depth: Current nesting depth (for internal recursion)
    /// - Returns: The validation result for this object
    public func validate(
        object: ValidationObject,
        metadata: [String: String] = [:],
        depth: Int = 0
    ) async -> ObjectValidationResult {
        let startTime = Date()

        // Get rules applicable to this object type
        let applicableRules = getRulesForObject(object)

        // If no rules apply, return passing result
        guard !applicableRules.isEmpty else {
            return ObjectValidationResult(
                objectType: object.objectType,
                isCompliant: true,
                totalRules: 0,
                passedRules: 0,
                failedRules: 0,
                ruleResults: [],
                nestedResults: [],
                duration: Date().timeIntervalSince(startTime)
            )
        }

        // Create execution context
        let context = RuleExecutor.ExecutionContext(
            object: object,
            metadata: metadata
        )

        // Execute rules
        var ruleResults: [RuleResult] = []
        var shouldStop = false

        for rule in applicableRules {
            guard !shouldStop else { break }

            let result = await executor.execute(rule: rule, context: context)
            ruleResults.append(result)

            if configuration.stopOnFirstFailure && result.status == .failed {
                shouldStop = true
            }
        }

        // Filter results based on configuration
        let finalResults = configuration.includePassingRules ?
            ruleResults :
            ruleResults.filter { $0.status != .passed }

        // Calculate statistics
        let passedCount = ruleResults.filter { $0.status == .passed }.count
        let failedCount = ruleResults.filter { $0.status == .failed }.count
        let isCompliant = failedCount == 0 &&
            ruleResults.filter { $0.status == .error }.isEmpty

        // Validate nested objects if configured
        var nestedResults: [ObjectValidationResult] = []
        if configuration.validateNestedObjects && depth < configuration.maxNestingDepth {
            if let nestedObjects = getNestedObjects(object) {
                for nestedObject in nestedObjects {
                    let nestedResult = await validate(
                        object: nestedObject,
                        metadata: metadata,
                        depth: depth + 1
                    )
                    nestedResults.append(nestedResult)
                }
            }
        }

        let duration = Date().timeIntervalSince(startTime)

        return ObjectValidationResult(
            objectType: object.objectType,
            isCompliant: isCompliant,
            totalRules: applicableRules.count,
            passedRules: passedCount,
            failedRules: failedCount,
            ruleResults: finalResults,
            nestedResults: nestedResults,
            duration: duration
        )
    }

    /// Validates multiple objects in parallel
    ///
    /// - Parameters:
    ///   - objects: The objects to validate
    ///   - metadata: Additional metadata about the objects
    /// - Returns: Array of validation results in the same order as input
    public func validateAll(
        objects: [ValidationObject],
        metadata: [String: String] = [:]
    ) async -> [ObjectValidationResult] {
        await withTaskGroup(of: (Int, ObjectValidationResult).self) { group in
            for (index, object) in objects.enumerated() {
                group.addTask {
                    let result = await validate(object: object, metadata: metadata)
                    return (index, result)
                }
            }

            // Collect and sort results
            var results: [(Int, ObjectValidationResult)] = []
            for await result in group {
                results.append(result)
            }

            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    // MARK: - Private Methods

    private func getRulesForObject(_ object: ValidationObject) -> [ValidationRule] {
        // Filter rules that apply to this object type
        profile.rules.filter { rule in
            rule.object == object.objectType
        }
    }

    private func getNestedObjects(_ object: ValidationObject) -> [ValidationObject]? {
        // This is a placeholder for getting nested objects from a PDF object
        // In a real implementation, this would extract child objects based on
        // the object type (e.g., pages from document, annotations from page)
        nil
    }
}

/// Common PDF object type identifiers
public enum PDFObjectType {
    public static let document = "PDDocument"
    public static let page = "PDPage"
    public static let annotation = "PDAnnot"
    public static let font = "PDFont"
    public static let colorSpace = "PDColorSpace"
    public static let image = "PDImage"
    public static let contentStream = "PDContentStream"
    public static let structureElement = "PDStructElem"
    public static let metadata = "PDMetadata"
}
