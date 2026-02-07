import Foundation
import SwiftVerificarValidationProfiles

/// Evaluates validation rules from profiles against PDF objects.
///
/// `ProfileRuleEvaluator` bridges the gap between validation profiles and PDF objects,
/// using the `RuleExpressionEvaluator` from the profiles package to evaluate rule
/// test expressions. It extracts properties from PDF objects and converts them
/// to the format expected by the expression evaluator.
///
/// ## Example
/// ```swift
/// let evaluator = ProfileRuleEvaluator()
/// let result = await evaluator.evaluate(
///     rule: validationRule,
///     object: pdfObject,
///     context: evaluationContext
/// )
/// if case .failed = result.status {
///     print("Rule \(rule.id) failed: \(result.message ?? "")")
/// }
/// ```
///
/// ## Integration with RuleExpressionEvaluator
/// This evaluator:
/// 1. Extracts properties from PDF objects using PropertyAccessor
/// 2. Converts validation PropertyValue to profiles PropertyValue
/// 3. Evaluates the rule test expression using RuleExpressionEvaluator
/// 4. Produces enhanced RuleResult with detailed information
public struct ProfileRuleEvaluator: Sendable {

    // MARK: - Configuration

    /// Configuration options for profile rule evaluation.
    public struct Configuration: Sendable {
        /// Whether to include detailed error messages.
        public let includeDetailedErrors: Bool

        /// Whether to capture execution context.
        public let captureContext: Bool

        /// Whether to include property values in context.
        public let includePropertyValues: Bool

        /// Timeout for individual rule execution in seconds.
        public let executionTimeout: TimeInterval?

        /// Whether to treat evaluation errors as rule failures.
        public let treatEvaluationErrorsAsFailures: Bool

        public init(
            includeDetailedErrors: Bool = true,
            captureContext: Bool = true,
            includePropertyValues: Bool = false,
            executionTimeout: TimeInterval? = nil,
            treatEvaluationErrorsAsFailures: Bool = false
        ) {
            self.includeDetailedErrors = includeDetailedErrors
            self.captureContext = captureContext
            self.includePropertyValues = includePropertyValues
            self.executionTimeout = executionTimeout
            self.treatEvaluationErrorsAsFailures = treatEvaluationErrorsAsFailures
        }

        /// Default configuration.
        public static let `default` = Configuration()

        /// Fast configuration with minimal context.
        public static let fast = Configuration(
            includeDetailedErrors: false,
            captureContext: false,
            includePropertyValues: false
        )

        /// Thorough configuration with maximum detail.
        public static let thorough = Configuration(
            includeDetailedErrors: true,
            captureContext: true,
            includePropertyValues: true,
            executionTimeout: 30.0
        )
    }

    // MARK: - Properties

    /// The configuration for this evaluator.
    public let configuration: Configuration

    /// The rule expression evaluator from the profiles package.
    private let expressionEvaluator: RuleExpressionEvaluator

    // MARK: - Initialization

    /// Creates a new profile rule evaluator.
    ///
    /// - Parameter configuration: The configuration to use.
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.expressionEvaluator = RuleExpressionEvaluator()
    }

    // MARK: - Rule Evaluation

    /// Evaluates a validation rule against a PDF object.
    ///
    /// - Parameters:
    ///   - rule: The validation rule to evaluate.
    ///   - object: The PDF object to validate.
    ///   - context: The evaluation context.
    /// - Returns: The result of evaluating the rule.
    public func evaluate(
        rule: ValidationRule,
        object: any PDFObject,
        context: EvaluationContext
    ) async -> RuleResult {
        let startTime = Date()

        // Apply timeout if configured
        if let timeout = configuration.executionTimeout {
            return await withTimeout(timeout) {
                await performEvaluation(rule: rule, object: object, context: context, startTime: startTime)
            }
        } else {
            return await performEvaluation(rule: rule, object: object, context: context, startTime: startTime)
        }
    }

    /// Evaluates multiple rules against an object in parallel.
    ///
    /// - Parameters:
    ///   - rules: The validation rules to evaluate.
    ///   - object: The PDF object to validate.
    ///   - context: The evaluation context.
    /// - Returns: An array of rule results in the same order as input rules.
    public func evaluateAll(
        rules: [ValidationRule],
        object: any PDFObject,
        context: EvaluationContext
    ) async -> [RuleResult] {
        await withTaskGroup(of: (Int, RuleResult).self) { group in
            for (index, rule) in rules.enumerated() {
                group.addTask {
                    let result = await evaluate(rule: rule, object: object, context: context)
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

    private func performEvaluation(
        rule: ValidationRule,
        object: any PDFObject,
        context: EvaluationContext,
        startTime: Date
    ) async -> RuleResult {
        do {
            // Extract properties from the PDF object
            let properties = extractProperties(from: object, context: context)

            // Evaluate the rule test expression
            let passed = try expressionEvaluator.evaluate(
                expression: rule.test,
                properties: properties
            )

            // Build the result
            let status: RuleStatus = passed ? .passed : .failed
            let message = passed ? nil : buildErrorMessage(rule: rule)
            let resultContext = configuration.captureContext ?
                buildContext(rule: rule, object: object, properties: properties, context: context) : nil
            let explanation = configuration.includeDetailedErrors ?
                buildExplanation(rule: rule, passed: passed) : nil

            return RuleResult(
                ruleId: rule.id.uniqueID,
                status: status,
                message: message,
                context: resultContext,
                explanation: explanation
            )

        } catch {
            // Rule evaluation failed with an error
            return handleEvaluationError(
                error: error,
                rule: rule,
                object: object,
                context: context
            )
        }
    }

    private func extractProperties(
        from object: any PDFObject,
        context: EvaluationContext
    ) -> [String: ExpressionPropertyValue] {
        var properties: [String: ExpressionPropertyValue] = [:]

        // Add profile variables first (lowest priority)
        for (name, value) in context.profileVariables {
            properties[name] = value
        }

        // Extract all properties from the object (overrides variables)
        for name in object.propertyNames {
            if let value = object.property(named: name) {
                properties[name] = convertPropertyValue(value)
            }
        }

        // Add context-provided properties (highest priority)
        for (name, value) in context.additionalProperties {
            properties[name] = value
        }

        return properties
    }

    private func convertPropertyValue(_ value: PropertyValue) -> ExpressionPropertyValue {
        switch value {
        case .null:
            return .null
        case .boolean(let b):
            return .bool(b)
        case .integer(let i):
            return .int(i)
        case .real(let r):
            return .double(r)
        case .string(let s):
            return .string(s)
        case .name(let n):
            return .string(n)
        case .object(let obj):
            // For objects, we return null and expect the rule to navigate properties
            // This is consistent with how veraPDF handles object references
            return .null
        case .objectArray(let objects):
            // Convert object arrays to null arrays (placeholder)
            // In a full implementation, we'd recursively extract properties
            return .array(Array(repeating: .null, count: objects.count))
        }
    }

    private func buildErrorMessage(rule: ValidationRule) -> String {
        if configuration.includeDetailedErrors {
            return "\(rule.description): \(rule.error.message)"
        } else {
            return rule.error.message
        }
    }

    private func buildContext(
        rule: ValidationRule,
        object: any PDFObject,
        properties: [String: ExpressionPropertyValue],
        context: EvaluationContext
    ) -> String {
        var parts: [String] = []

        // Object information
        parts.append("Object: \(object.objectType)")

        // Rule information
        parts.append("Rule: \(rule.id.uniqueID)")
        parts.append("Clause: \(rule.id.clause)")

        // Document location
        if let location = context.documentLocation {
            parts.append("Location: \(location)")
        }

        // Property values (if configured)
        if configuration.includePropertyValues && !properties.isEmpty {
            let propStrs = properties.map { "\($0.key)=\($0.value.stringValue)" }
                .sorted()
                .prefix(5) // Limit to first 5 properties
            parts.append("Properties: \(propStrs.joined(separator: ", "))")
        }

        return parts.joined(separator: "; ")
    }

    private func buildExplanation(rule: ValidationRule, passed: Bool) -> String? {
        guard !passed else {
            return nil
        }

        var explanation = "Rule \(rule.id.uniqueID) failed.\n"
        explanation += "Description: \(rule.description)\n"
        explanation += "Test: \(rule.test)\n"

        if !rule.references.isEmpty {
            let refs = rule.references.map { "\($0.specification) \($0.clause)" }.joined(separator: ", ")
            explanation += "References: \(refs)\n"
        }

        return explanation
    }

    private func handleEvaluationError(
        error: Error,
        rule: ValidationRule,
        object: any PDFObject,
        context: EvaluationContext
    ) -> RuleResult {
        let status: RuleStatus

        if configuration.treatEvaluationErrorsAsFailures {
            status = .failed
        } else {
            status = .error
        }

        let errorMessage: String
        if configuration.includeDetailedErrors {
            errorMessage = "Rule evaluation failed: \(error.localizedDescription)"
        } else {
            errorMessage = "Rule evaluation failed"
        }

        let resultContext: String?
        if configuration.captureContext {
            var parts: [String] = []
            parts.append("Object: \(object.objectType)")
            parts.append("Rule: \(rule.id.uniqueID)")
            if let location = context.documentLocation {
                parts.append("Location: \(location)")
            }
            resultContext = parts.joined(separator: "; ")
        } else {
            resultContext = nil
        }

        return RuleResult(
            ruleId: rule.id.uniqueID,
            status: status,
            message: errorMessage,
            context: resultContext,
            explanation: configuration.includeDetailedErrors ? "Error: \(error)" : nil
        )
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
