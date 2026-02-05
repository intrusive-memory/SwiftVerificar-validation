import Foundation

/// Context information for objects during validation.
///
/// This type carries additional metadata about an object's location and
/// role in the document structure, which is useful for generating detailed
/// validation reports and error messages.
///
/// Corresponds to context tracking in the Java veraPDF-validation model.
public struct ObjectContext: Sendable, Equatable {

    // MARK: - Properties

    /// The page number where this object appears, if applicable.
    ///
    /// Page numbers are 1-based. A value of `nil` indicates the object
    /// is not associated with a specific page (e.g., catalog, metadata).
    public let pageNumber: Int?

    /// The location description (e.g., "ContentStream", "Annotation", "Font").
    ///
    /// This provides human-readable context about where the object appears.
    public let location: String?

    /// The object's role or purpose in the document.
    ///
    /// For example: "Title font", "Form field", "Embedded image".
    public let role: String?

    /// Additional metadata as key-value pairs.
    ///
    /// This can store any additional context information needed for
    /// specific validation scenarios.
    public let metadata: [String: String]

    // MARK: - Initialization

    /// Creates an object context.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number (1-based), or `nil` if not page-specific.
    ///   - location: A description of the object's location.
    ///   - role: The object's role or purpose.
    ///   - metadata: Additional metadata.
    public init(
        pageNumber: Int? = nil,
        location: String? = nil,
        role: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.pageNumber = pageNumber
        self.location = location
        self.role = role
        self.metadata = metadata
    }

    // MARK: - Context Building

    /// Returns a new context with the page number set.
    ///
    /// - Parameter pageNumber: The page number (1-based).
    /// - Returns: A new context with the page number.
    public func withPage(_ pageNumber: Int) -> ObjectContext {
        ObjectContext(
            pageNumber: pageNumber,
            location: location,
            role: role,
            metadata: metadata
        )
    }

    /// Returns a new context with the location set.
    ///
    /// - Parameter location: The location description.
    /// - Returns: A new context with the location.
    public func withLocation(_ location: String) -> ObjectContext {
        ObjectContext(
            pageNumber: pageNumber,
            location: location,
            role: role,
            metadata: metadata
        )
    }

    /// Returns a new context with the role set.
    ///
    /// - Parameter role: The role description.
    /// - Returns: A new context with the role.
    public func withRole(_ role: String) -> ObjectContext {
        ObjectContext(
            pageNumber: pageNumber,
            location: location,
            role: role,
            metadata: metadata
        )
    }

    /// Returns a new context with additional metadata.
    ///
    /// - Parameter metadata: Additional metadata to merge.
    /// - Returns: A new context with merged metadata.
    public func withMetadata(_ additionalMetadata: [String: String]) -> ObjectContext {
        var mergedMetadata = metadata
        for (key, value) in additionalMetadata {
            mergedMetadata[key] = value
        }
        return ObjectContext(
            pageNumber: pageNumber,
            location: location,
            role: role,
            metadata: mergedMetadata
        )
    }

    /// Returns a new context with a single metadata entry.
    ///
    /// - Parameters:
    ///   - key: The metadata key.
    ///   - value: The metadata value.
    /// - Returns: A new context with the metadata entry.
    public func withMetadata(key: String, value: String) -> ObjectContext {
        withMetadata([key: value])
    }

    // MARK: - Description

    /// Returns a human-readable description of this context.
    ///
    /// This is useful for error messages and validation reports.
    public var description: String {
        var parts: [String] = []

        if let pageNumber = pageNumber {
            parts.append("Page \(pageNumber)")
        }

        if let location = location {
            parts.append(location)
        }

        if let role = role {
            parts.append("(\(role))")
        }

        if !metadata.isEmpty {
            let metadataStr = metadata
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
            parts.append("[\(metadataStr)]")
        }

        return parts.isEmpty ? "Unknown context" : parts.joined(separator: " ")
    }
}

// MARK: - CustomStringConvertible

extension ObjectContext: CustomStringConvertible {}

// MARK: - Common Context Factories

extension ObjectContext {

    /// Context for document-level objects.
    public static let document = ObjectContext(location: "Document")

    /// Context for catalog-level objects.
    public static let catalog = ObjectContext(location: "Catalog")

    /// Context for metadata objects.
    public static let metadata = ObjectContext(location: "Metadata")

    /// Context for a page.
    ///
    /// - Parameter pageNumber: The page number (1-based).
    /// - Returns: A page context.
    public static func page(_ pageNumber: Int) -> ObjectContext {
        ObjectContext(pageNumber: pageNumber, location: "Page")
    }

    /// Context for a content stream.
    ///
    /// - Parameter pageNumber: The page number (1-based).
    /// - Returns: A content stream context.
    public static func contentStream(page pageNumber: Int) -> ObjectContext {
        ObjectContext(pageNumber: pageNumber, location: "ContentStream")
    }

    /// Context for an annotation.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number (1-based).
    ///   - annotationType: The annotation type.
    /// - Returns: An annotation context.
    public static func annotation(page pageNumber: Int, type annotationType: String) -> ObjectContext {
        ObjectContext(
            pageNumber: pageNumber,
            location: "Annotation",
            role: annotationType
        )
    }

    /// Context for a font.
    ///
    /// - Parameters:
    ///   - fontName: The font name or identifier.
    ///   - pageNumber: The page number (1-based), if applicable.
    /// - Returns: A font context.
    public static func font(_ fontName: String, page pageNumber: Int? = nil) -> ObjectContext {
        ObjectContext(
            pageNumber: pageNumber,
            location: "Font",
            role: fontName
        )
    }

    /// Context for a color space.
    ///
    /// - Parameters:
    ///   - colorSpaceName: The color space name.
    ///   - pageNumber: The page number (1-based), if applicable.
    /// - Returns: A color space context.
    public static func colorSpace(_ colorSpaceName: String, page pageNumber: Int? = nil) -> ObjectContext {
        ObjectContext(
            pageNumber: pageNumber,
            location: "ColorSpace",
            role: colorSpaceName
        )
    }

    /// Context for a structure element.
    ///
    /// - Parameter structureType: The structure element type (e.g., "P", "H1").
    /// - Returns: A structure element context.
    public static func structureElement(_ structureType: String) -> ObjectContext {
        ObjectContext(
            location: "StructureElement",
            role: structureType
        )
    }

    /// Context for a form field.
    ///
    /// - Parameter fieldName: The field name.
    /// - Returns: A form field context.
    public static func formField(_ fieldName: String) -> ObjectContext {
        ObjectContext(
            location: "FormField",
            role: fieldName
        )
    }

    /// Context for an image.
    ///
    /// - Parameter pageNumber: The page number (1-based).
    /// - Returns: An image context.
    public static func image(page pageNumber: Int) -> ObjectContext {
        ObjectContext(
            pageNumber: pageNumber,
            location: "Image"
        )
    }
}
