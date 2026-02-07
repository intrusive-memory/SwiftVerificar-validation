import Foundation
import SwiftVerificarValidationProfiles

/// Executes validation rules from profiles against PDF objects.
///
/// `RuleExecutor` is responsible for evaluating individual validation rules
/// from a profile against PDF objects and producing rule results. It handles:
/// - Rule expression evaluation
/// - Error handling and recovery
/// - Result generation with detailed context
/// - Support for different rule execution modes
///
/// ## Example
/// ```swift
/// let executor = RuleExecutor()
/// let result = await executor.execute(
///     rule: validationRule,
///     object: pdfObject,
///     context: executionContext
/// )
/// if case .failed = result.status {
///     print("Rule \(rule.id) failed: \(result.message ?? "")")
/// }
/// ```
public struct RuleExecutor: Sendable {

    /// Configuration options for rule execution
    public struct Configuration: Sendable {
        /// Whether to include detailed error messages
        public let includeDetailedErrors: Bool

        /// Whether to capture context information
        public let captureContext: Bool

        /// Timeout for individual rule execution in seconds
        public let executionTimeout: TimeInterval?

        /// Whether to treat warnings as errors
        public let treatWarningsAsErrors: Bool

        public init(
            includeDetailedErrors: Bool = true,
            captureContext: Bool = true,
            executionTimeout: TimeInterval? = nil,
            treatWarningsAsErrors: Bool = false
        ) {
            self.includeDetailedErrors = includeDetailedErrors
            self.captureContext = captureContext
            self.executionTimeout = executionTimeout
            self.treatWarningsAsErrors = treatWarningsAsErrors
        }

        /// Default configuration
        public static let `default` = Configuration()

        /// Fast configuration with minimal context
        public static let fast = Configuration(
            includeDetailedErrors: false,
            captureContext: false
        )

        /// Thorough configuration with maximum detail
        public static let thorough = Configuration(
            includeDetailedErrors: true,
            captureContext: true,
            executionTimeout: 30.0
        )
    }

    /// Context for rule execution containing object state and environment
    public struct ExecutionContext: Sendable {
        /// The PDF object being validated
        public let object: ValidationObject

        /// Additional metadata about the object
        public let metadata: [String: String]

        public init(
            object: ValidationObject,
            metadata: [String: String] = [:]
        ) {
            self.object = object
            self.metadata = metadata
        }
    }

    /// The configuration for this executor
    public let configuration: Configuration

    /// Creates a new rule executor with the specified configuration
    ///
    /// - Parameter configuration: The configuration to use
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    /// Executes a validation rule against an object
    ///
    /// - Parameters:
    ///   - rule: The validation rule to execute
    ///   - context: The execution context containing the object to validate
    /// - Returns: The result of executing the rule
    public func execute(
        rule: ValidationRule,
        context: ExecutionContext
    ) async -> RuleResult {
        // Start execution timing
        let startTime = Date()

        // Apply timeout if configured
        if let timeout = configuration.executionTimeout {
            return await withTimeout(timeout) {
                await performExecution(rule: rule, context: context, startTime: startTime)
            }
        } else {
            return await performExecution(rule: rule, context: context, startTime: startTime)
        }
    }

    /// Executes multiple rules in parallel
    ///
    /// - Parameters:
    ///   - rules: The validation rules to execute
    ///   - context: The execution context containing the object to validate
    /// - Returns: An array of rule results in the same order as input rules
    public func executeAll(
        rules: [ValidationRule],
        context: ExecutionContext
    ) async -> [RuleResult] {
        await withTaskGroup(of: (Int, RuleResult).self) { group in
            for (index, rule) in rules.enumerated() {
                group.addTask {
                    let result = await execute(rule: rule, context: context)
                    return (index, result)
                }
            }

            // Collect results and restore original order
            var results: [(Int, RuleResult)] = []
            for await result in group {
                results.append(result)
            }

            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    // MARK: - Private Methods

    private func performExecution(
        rule: ValidationRule,
        context: ExecutionContext,
        startTime: Date
    ) async -> RuleResult {
        do {
            // Evaluate the rule test expression
            let passed = try evaluateTest(rule.test, object: context.object)

            let status: RuleStatus = passed ? .passed : .failed
            let message: String? = passed ? nil : formatErrorMessage(rule: rule)
            let contextInfo: String? = configuration.captureContext ?
                formatContext(rule: rule, context: context) : nil

            return RuleResult(
                ruleId: rule.id.uniqueID,
                status: status,
                message: message,
                context: contextInfo
            )

        } catch {
            // Rule execution failed with an error
            let errorMessage = configuration.includeDetailedErrors ?
                "Rule execution failed: \(error.localizedDescription)" :
                "Rule execution failed"

            let contextInfo: String? = configuration.captureContext ?
                formatContext(rule: rule, context: context) : nil

            return RuleResult(
                ruleId: rule.id.uniqueID,
                status: .error,
                message: errorMessage,
                context: contextInfo
            )
        }
    }

    private func evaluateTest(_ test: String, object: ValidationObject) throws -> Bool {
        // Placeholder implementation
        // In a real implementation, this would parse and evaluate the test expression
        // against the object's properties using the rule expression language

        // For now, we'll implement basic property checking
        // The test string typically contains expressions like "property == value"

        // Strip whitespace
        let trimmedTest = test.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle empty test (always passes)
        guard !trimmedTest.isEmpty else {
            return true
        }

        // Simple property existence check: "propertyName"
        if !trimmedTest.contains("==") && !trimmedTest.contains("!=") {
            return object.hasProperty(trimmedTest)
        }

        // For more complex expressions, default to true for now
        // This will be expanded in future sprints with full expression evaluation
        return true
    }

    private func formatErrorMessage(
        rule: ValidationRule
    ) -> String {
        if configuration.includeDetailedErrors {
            return "\(rule.description): \(rule.error.message)"
        } else {
            return rule.error.message
        }
    }

    private func formatContext(
        rule: ValidationRule,
        context: ExecutionContext
    ) -> String {
        var parts: [String] = []

        parts.append("Object: \(context.object.objectType)")
        parts.append("Rule: \(rule.id.uniqueID)")
        parts.append("Clause: \(rule.id.clause)")

        if !context.metadata.isEmpty {
            let metadataStr = context.metadata.map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
            parts.append("Metadata: \(metadataStr)")
        }

        return parts.joined(separator: "; ")
    }

    private func withTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping @Sendable () async -> T
    ) async -> T where T: Sendable {
        await withTaskGroup(of: T?.self) { group in
            // Add the main operation
            group.addTask {
                await operation()
            }

            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }

            // Return first result (either operation or timeout)
            if let result = await group.next() {
                group.cancelAll()
                if let value = result {
                    return value
                }
            }

            // Timeout occurred - this should not happen with our error handling
            // but we need to return something
            fatalError("Timeout occurred without proper error handling")
        }
    }
}

/// Protocol for objects that can be validated
public protocol ValidationObject: Sendable {
    /// The type of this PDF object
    var objectType: String { get }

    /// Check if the object has a specific property
    func hasProperty(_ name: String) -> Bool

    /// Get a property value as a string
    func getProperty(_ name: String) -> String?
}

/// A simple validation object wrapper for testing
public struct SimpleValidationObject: ValidationObject {
    public let objectType: String
    private let properties: [String: String]

    public init(objectType: String, properties: [String: String] = [:]) {
        self.objectType = objectType
        self.properties = properties
    }

    public func hasProperty(_ name: String) -> Bool {
        properties[name] != nil
    }

    public func getProperty(_ name: String) -> String? {
        properties[name]
    }
}
