import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Destination Type

/// The type of a PDF destination.
///
/// Destinations specify a particular view of a page, defining the page,
/// the visible area, and optionally the zoom level.
///
/// See PDF specification Table 151 -- Destination syntax.
public enum DestinationType: String, Sendable, Hashable, CaseIterable {
    /// Display the page with coordinates at the upper-left corner
    /// and the specified zoom.
    case xyz = "XYZ"

    /// Fit the entire page within the window.
    case fit = "Fit"

    /// Fit the page width in the window, with the specified top coordinate.
    case fitH = "FitH"

    /// Fit the page height in the window, with the specified left coordinate.
    case fitV = "FitV"

    /// Fit the specified rectangle in the window.
    case fitR = "FitR"

    /// Fit the bounding box of the page within the window.
    case fitB = "FitB"

    /// Fit the bounding box width, with the specified top coordinate.
    case fitBH = "FitBH"

    /// Fit the bounding box height, with the specified left coordinate.
    case fitBV = "FitBV"

    /// Unknown destination type.
    case unknown = "Unknown"

    /// Creates a destination type from a string.
    ///
    /// - Parameter value: The destination type string.
    public init(fromString value: String?) {
        guard let value = value else {
            self = .unknown
            return
        }
        self = DestinationType(rawValue: value) ?? .unknown
    }

    /// Whether this destination type requires page coordinates.
    public var requiresCoordinates: Bool {
        switch self {
        case .xyz, .fitH, .fitV, .fitR, .fitBH, .fitBV:
            return true
        case .fit, .fitB, .unknown:
            return false
        }
    }

    /// Whether this destination type specifies a zoom level.
    public var specifiesZoom: Bool {
        self == .xyz
    }
}

// MARK: - Validated Destination

/// A validation wrapper for a PDF destination.
///
/// Destinations define a specific view of a page. They can be explicit
/// (specified as an array) or named (referenced by a name string that
/// is looked up in the document's name dictionary).
///
/// ## Key Properties
///
/// - **Type**: The destination type (XYZ, Fit, FitH, etc.)
/// - **Page**: The target page reference
/// - **Coordinates**: Position and zoom parameters
/// - **Named**: Whether this is a named destination
///
/// ## Validation Rules
///
/// - **PDF/A**: Destinations must reference valid pages.
/// - **PDF/UA**: GoTo actions must have valid destinations for
///   assistive technology navigation.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDDestination` and `GFPDNamedDestination` from
/// veraPDF-validation, consolidated into a single struct.
public struct ValidatedDestination: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary or array for the destination.
    public let cosDictionary: COSValue?

    /// The object key for the destination, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Destination Properties

    /// The destination type.
    public let destinationType: DestinationType

    /// The raw destination type string.
    public let destinationTypeName: String

    /// Whether this is a named destination.
    ///
    /// Named destinations are looked up by name in the document's
    /// name dictionary or Dests catalog entry.
    public let isNamed: Bool

    /// The name of a named destination, if this is a named destination.
    public let name: String?

    /// Whether the destination has a valid page reference.
    public let hasPageReference: Bool

    /// The zero-based page index of the target page, if known.
    public let pageIndex: Int?

    // MARK: - Coordinates

    /// The left coordinate for XYZ, FitV, FitR, and FitBV destinations.
    public let left: Double?

    /// The top coordinate for XYZ, FitH, FitR, and FitBH destinations.
    public let top: Double?

    /// The right coordinate for FitR destinations.
    public let right: Double?

    /// The bottom coordinate for FitR destinations.
    public let bottom: Double?

    /// The zoom factor for XYZ destinations.
    ///
    /// A value of 0 or nil means "inherit the current zoom".
    public let zoom: Double?

    // MARK: - Initialization

    /// Creates a validated destination.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS value for the destination.
    ///   - objectKey: The object key.
    ///   - context: Validation context.
    ///   - destinationTypeName: The raw destination type string.
    ///   - isNamed: Whether this is a named destination.
    ///   - name: The destination name, if named.
    ///   - hasPageReference: Whether a valid page reference exists.
    ///   - pageIndex: The zero-based page index.
    ///   - left: Left coordinate.
    ///   - top: Top coordinate.
    ///   - right: Right coordinate.
    ///   - bottom: Bottom coordinate.
    ///   - zoom: Zoom factor.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(location: "Destination"),
        destinationTypeName: String = "XYZ",
        isNamed: Bool = false,
        name: String? = nil,
        hasPageReference: Bool = true,
        pageIndex: Int? = nil,
        left: Double? = nil,
        top: Double? = nil,
        right: Double? = nil,
        bottom: Double? = nil,
        zoom: Double? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.destinationTypeName = destinationTypeName
        self.destinationType = DestinationType(fromString: destinationTypeName)
        self.isNamed = isNamed
        self.name = name
        self.hasPageReference = hasPageReference
        self.pageIndex = pageIndex
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
        self.zoom = zoom
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDDestination"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "destinationType", "destinationTypeName",
            "isNamed", "name",
            "hasPageReference", "pageIndex",
            "left", "top", "right", "bottom", "zoom",
            "isValid", "isExplicit", "hasCoordinates"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "destinationType":
            return .string(destinationType.rawValue)
        case "destinationTypeName":
            return .string(destinationTypeName)
        case "isNamed":
            return .boolean(isNamed)
        case "name":
            if let n = self.name { return .string(n) }
            return .null
        case "hasPageReference":
            return .boolean(hasPageReference)
        case "pageIndex":
            if let pi = pageIndex { return .integer(Int64(pi)) }
            return .null
        case "left":
            if let l = left { return .real(l) }
            return .null
        case "top":
            if let t = top { return .real(t) }
            return .null
        case "right":
            if let r = right { return .real(r) }
            return .null
        case "bottom":
            if let b = bottom { return .real(b) }
            return .null
        case "zoom":
            if let z = zoom { return .real(z) }
            return .null
        case "isValid":
            return .boolean(isValid)
        case "isExplicit":
            return .boolean(isExplicit)
        case "hasCoordinates":
            return .boolean(hasCoordinates)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedDestination, rhs: ValidatedDestination) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedDestination {

    /// Whether this destination is valid.
    ///
    /// A destination is valid if it either references a page (for explicit
    /// destinations) or has a name (for named destinations).
    public var isValid: Bool {
        if isNamed {
            guard let n = name else { return false }
            return !n.isEmpty
        }
        return hasPageReference
    }

    /// Whether this is an explicit destination (not named).
    public var isExplicit: Bool {
        !isNamed
    }

    /// Whether this destination specifies coordinates.
    public var hasCoordinates: Bool {
        left != nil || top != nil || right != nil || bottom != nil
    }

    /// Whether this destination specifies a zoom level.
    public var hasZoom: Bool {
        guard let z = zoom else { return false }
        return z > 0
    }

    /// The one-based page number, if available.
    public var pageNumber: Int? {
        guard let pi = pageIndex else { return nil }
        return pi + 1
    }

    /// Returns a summary string describing the destination.
    public var summary: String {
        var parts: [String] = []
        if isNamed {
            parts.append("named")
            if let n = name { parts.append("'\(n)'") }
        } else {
            parts.append(destinationTypeName)
            if let pi = pageIndex { parts.append("page \(pi + 1)") }
        }
        if let z = zoom, z > 0 { parts.append("zoom=\(z)") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedDestination {

    /// Creates an explicit XYZ destination for testing.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based page index.
    ///   - left: The left coordinate.
    ///   - top: The top coordinate.
    ///   - zoom: The zoom level.
    /// - Returns: An XYZ destination.
    public static func xyz(
        pageIndex: Int = 0,
        left: Double? = 0,
        top: Double? = 792,
        zoom: Double? = 1.0
    ) -> ValidatedDestination {
        ValidatedDestination(
            destinationTypeName: "XYZ",
            hasPageReference: true,
            pageIndex: pageIndex,
            left: left,
            top: top,
            zoom: zoom
        )
    }

    /// Creates a Fit destination for testing.
    ///
    /// - Parameter pageIndex: The zero-based page index.
    /// - Returns: A Fit destination.
    public static func fit(pageIndex: Int = 0) -> ValidatedDestination {
        ValidatedDestination(
            destinationTypeName: "Fit",
            hasPageReference: true,
            pageIndex: pageIndex
        )
    }

    /// Creates a named destination for testing.
    ///
    /// - Parameter name: The destination name.
    /// - Returns: A named destination.
    public static func named(_ name: String) -> ValidatedDestination {
        ValidatedDestination(
            destinationTypeName: "XYZ",
            isNamed: true,
            name: name
        )
    }
}
