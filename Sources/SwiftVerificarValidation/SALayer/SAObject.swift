import Foundation

// MARK: - SA Object Protocol

/// Base protocol for all SA (Structured Accessibility) layer types.
///
/// The SA layer wraps PD-layer validated types and adds accessibility-specific
/// semantics for WCAG validation. All SA types conform to this protocol, which
/// provides a uniform interface for accessibility analysis and traversal.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFSAObject` from veraPDF-validation's wcag-validation module.
/// In the Java codebase, this is the base interface for all SA model objects that
/// participate in accessibility validation.
///
/// ## SA Layer Architecture
///
/// The SA layer sits above the PD (Page Description) layer:
/// ```
/// SA Layer (accessibility semantics)
///   |
/// PD Layer (validated PDF structures)
///   |
/// COS Layer (low-level PDF objects)
/// ```
///
/// ## Swift Adaptations
///
/// - Protocol instead of abstract class
/// - All conforming types are value types (structs) for thread safety
/// - `Sendable` conformance for concurrent WCAG validation
/// - Property-based access for accessibility properties
public protocol SAObject: Sendable, Equatable, Identifiable {

    /// A unique identifier for this SA object.
    var id: UUID { get }

    /// The SA object type name for accessibility profiling.
    ///
    /// This corresponds to the type names used in WCAG validation rules,
    /// such as "SADocument", "SAPage", "SAStructureRoot", "SANode".
    var saObjectType: String { get }

    /// The validation context providing location information.
    ///
    /// Used for generating meaningful accessibility validation messages
    /// that reference the specific location in the document.
    var validationContext: ObjectContext { get }

    /// Returns the value of an accessibility property by name.
    ///
    /// This is used by WCAG validation rules to access SA object properties.
    /// Property names correspond to accessibility-relevant getters defined
    /// in the Java veraPDF SA model classes.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if the property does not exist.
    func accessibilityProperty(named name: String) -> PropertyValue?

    /// Returns all accessibility property names supported by this object.
    ///
    /// Used for introspection and debugging of SA objects.
    var accessibilityPropertyNames: [String] { get }
}

// MARK: - Default Implementations

extension SAObject {

    /// Default: returns an empty array of property names.
    public var accessibilityPropertyNames: [String] {
        []
    }

    /// Default: returns `nil` for all property lookups.
    public func accessibilityProperty(named name: String) -> PropertyValue? {
        nil
    }
}

// MARK: - SA Object Type

/// Enumeration of SA layer object types.
///
/// Provides type-safe identification of SA layer objects, enabling
/// pattern matching and dispatching in WCAG validation rules.
public enum SAObjectType: String, Sendable, Hashable, CaseIterable, Codable {

    /// An SA document wrapping a validated PDF document.
    case document = "SADocument"

    /// An SA page wrapping a validated PDF page.
    case page = "SAPage"

    /// An SA structure tree root wrapping a validated structure tree root.
    case structureRoot = "SAStructureRoot"

    /// An SA node representing a node in the accessibility tree.
    case node = "SANode"

    /// An SA structure element (to be defined in Sprint 15).
    case structureElement = "SAStructureElement"
}

// MARK: - ObjectContext SA Extensions

extension ObjectContext {

    /// Context for SA document-level objects.
    public static let saDocument = ObjectContext(location: "SADocument")

    /// Context for an SA page.
    ///
    /// - Parameter pageNumber: The page number (1-based).
    /// - Returns: An SA page context.
    public static func saPage(_ pageNumber: Int) -> ObjectContext {
        ObjectContext(pageNumber: pageNumber, location: "SAPage")
    }

    /// Context for the SA structure tree root.
    public static let saStructureRoot = ObjectContext(location: "SAStructureRoot")

    /// Context for an SA node.
    ///
    /// - Parameter role: The node's role or structure type name.
    /// - Returns: An SA node context.
    public static func saNode(_ role: String) -> ObjectContext {
        ObjectContext(location: "SANode", role: role)
    }
}
