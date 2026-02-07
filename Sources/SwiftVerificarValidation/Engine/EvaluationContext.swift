import Foundation
import SwiftVerificarValidationProfiles

/// Context for rule evaluation containing document state and environment.
///
/// `EvaluationContext` provides contextual information needed during rule evaluation,
/// including the document location, additional properties, and metadata. This allows
/// rules to access information beyond what's available in the immediate object being
/// validated.
///
/// ## Example
/// ```swift
/// let context = EvaluationContext(
///     documentLocation: "Page 5",
///     additionalProperties: [
///         "pageNumber": .int(5),
///         "totalPages": .int(10)
///     ],
///     metadata: [
///         "fileName": "document.pdf",
///         "profileName": "PDF/A-1b"
///     ]
/// )
///
/// let result = await evaluator.evaluate(
///     rule: rule,
///     object: object,
///     context: context
/// )
/// ```
///
/// ## Use Cases
/// - Providing page numbers and document structure context
/// - Passing global document properties to rules
/// - Tracking validation progress and location
/// - Providing profile-specific variables
public struct EvaluationContext: Sendable {

    // MARK: - Properties

    /// The location in the document being validated (e.g., "Page 5", "Font /F1").
    public let documentLocation: String?

    /// Additional properties available to rule expressions.
    ///
    /// These properties are merged with the object's own properties during evaluation.
    /// This allows rules to access document-level or context-specific values.
    public let additionalProperties: [String: ExpressionPropertyValue]

    /// Metadata about the validation context.
    ///
    /// This can include information like the file name, profile name, or any
    /// other contextual information needed for debugging or reporting.
    public let metadata: [String: String]

    /// The parent object in the document hierarchy, if applicable.
    public let parentObject: (any PDFObject)?

    /// The validation profile variables.
    ///
    /// Profile variables provide named values that can be referenced in rule expressions.
    public let profileVariables: [String: ExpressionPropertyValue]

    // MARK: - Initialization

    /// Creates a new evaluation context.
    ///
    /// - Parameters:
    ///   - documentLocation: The location in the document.
    ///   - additionalProperties: Additional properties for rule expressions.
    ///   - metadata: Metadata about the context.
    ///   - parentObject: The parent object in the hierarchy.
    ///   - profileVariables: Profile-defined variables.
    public init(
        documentLocation: String? = nil,
        additionalProperties: [String: ExpressionPropertyValue] = [:],
        metadata: [String: String] = [:],
        parentObject: (any PDFObject)? = nil,
        profileVariables: [String: ExpressionPropertyValue] = [:]
    ) {
        self.documentLocation = documentLocation
        self.additionalProperties = additionalProperties
        self.metadata = metadata
        self.parentObject = parentObject
        self.profileVariables = profileVariables
    }

    /// Creates an empty evaluation context.
    public static let empty = EvaluationContext()

    // MARK: - Context Building

    /// Creates a new context with updated location.
    ///
    /// - Parameter location: The new document location.
    /// - Returns: A new context with the updated location.
    public func with(location: String) -> EvaluationContext {
        EvaluationContext(
            documentLocation: location,
            additionalProperties: additionalProperties,
            metadata: metadata,
            parentObject: parentObject,
            profileVariables: profileVariables
        )
    }

    /// Creates a new context with additional properties.
    ///
    /// - Parameter properties: Additional properties to add.
    /// - Returns: A new context with the merged properties.
    public func with(properties: [String: ExpressionPropertyValue]) -> EvaluationContext {
        var merged = additionalProperties
        for (key, value) in properties {
            merged[key] = value
        }

        return EvaluationContext(
            documentLocation: documentLocation,
            additionalProperties: merged,
            metadata: metadata,
            parentObject: parentObject,
            profileVariables: profileVariables
        )
    }

    /// Creates a new context with additional metadata.
    ///
    /// - Parameter metadata: Additional metadata to add.
    /// - Returns: A new context with the merged metadata.
    public func with(metadata: [String: String]) -> EvaluationContext {
        var merged = self.metadata
        for (key, value) in metadata {
            merged[key] = value
        }

        return EvaluationContext(
            documentLocation: documentLocation,
            additionalProperties: additionalProperties,
            metadata: merged,
            parentObject: parentObject,
            profileVariables: profileVariables
        )
    }

    /// Creates a new context with a parent object.
    ///
    /// - Parameter parent: The parent object.
    /// - Returns: A new context with the parent object set.
    public func with(parent: any PDFObject) -> EvaluationContext {
        EvaluationContext(
            documentLocation: documentLocation,
            additionalProperties: additionalProperties,
            metadata: metadata,
            parentObject: parent,
            profileVariables: profileVariables
        )
    }

    /// Creates a new context with profile variables.
    ///
    /// - Parameter variables: The profile variables to add.
    /// - Returns: A new context with the merged variables.
    public func with(variables: [String: ExpressionPropertyValue]) -> EvaluationContext {
        var merged = profileVariables
        for (key, value) in variables {
            merged[key] = value
        }

        return EvaluationContext(
            documentLocation: documentLocation,
            additionalProperties: additionalProperties,
            metadata: metadata,
            parentObject: parentObject,
            profileVariables: merged
        )
    }

    // MARK: - Convenience Accessors

    /// Gets a property value by name, checking both additional properties and profile variables.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> ExpressionPropertyValue? {
        additionalProperties[name] ?? profileVariables[name]
    }

    /// Checks if a property is defined in the context.
    ///
    /// - Parameter name: The property name.
    /// - Returns: `true` if the property exists, `false` otherwise.
    public func hasProperty(_ name: String) -> Bool {
        additionalProperties[name] != nil || profileVariables[name] != nil
    }

    /// Gets metadata by key.
    ///
    /// - Parameter key: The metadata key.
    /// - Returns: The metadata value, or `nil` if not found.
    public func metadata(for key: String) -> String? {
        metadata[key]
    }

    /// Gets all available properties (both additional and profile variables).
    public var allProperties: [String: ExpressionPropertyValue] {
        var all = profileVariables
        for (key, value) in additionalProperties {
            all[key] = value
        }
        return all
    }
}

// MARK: - Context Builder

/// Builder for constructing evaluation contexts with a fluent API.
///
/// ## Example
/// ```swift
/// let context = EvaluationContext.Builder()
///     .location("Page 5")
///     .property("pageNumber", value: .int(5))
///     .metadata("fileName", value: "document.pdf")
///     .build()
/// ```
public extension EvaluationContext {
    struct Builder {
        private var location: String?
        private var properties: [String: ExpressionPropertyValue] = [:]
        private var metadata: [String: String] = [:]
        private var parent: (any PDFObject)?
        private var variables: [String: ExpressionPropertyValue] = [:]

        /// Creates a new builder.
        public init() {}

        /// Sets the document location.
        public func location(_ location: String) -> Builder {
            var builder = self
            builder.location = location
            return builder
        }

        /// Adds a property.
        public func property(_ name: String, value: ExpressionPropertyValue) -> Builder {
            var builder = self
            builder.properties[name] = value
            return builder
        }

        /// Adds multiple properties.
        public func properties(_ properties: [String: ExpressionPropertyValue]) -> Builder {
            var builder = self
            for (key, value) in properties {
                builder.properties[key] = value
            }
            return builder
        }

        /// Adds metadata.
        public func metadata(_ key: String, value: String) -> Builder {
            var builder = self
            builder.metadata[key] = value
            return builder
        }

        /// Adds multiple metadata entries.
        public func metadata(_ metadata: [String: String]) -> Builder {
            var builder = self
            for (key, value) in metadata {
                builder.metadata[key] = value
            }
            return builder
        }

        /// Sets the parent object.
        public func parent(_ parent: any PDFObject) -> Builder {
            var builder = self
            builder.parent = parent
            return builder
        }

        /// Adds a profile variable.
        public func variable(_ name: String, value: ExpressionPropertyValue) -> Builder {
            var builder = self
            builder.variables[name] = value
            return builder
        }

        /// Adds multiple profile variables.
        public func variables(_ variables: [String: ExpressionPropertyValue]) -> Builder {
            var builder = self
            for (key, value) in variables {
                builder.variables[key] = value
            }
            return builder
        }

        /// Builds the evaluation context.
        public func build() -> EvaluationContext {
            EvaluationContext(
                documentLocation: location,
                additionalProperties: properties,
                metadata: metadata,
                parentObject: parent,
                profileVariables: variables
            )
        }
    }
}
