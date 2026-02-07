import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - OCG Usage

/// The intended usage of an optional content group.
///
/// Usage categories help applications determine how to present
/// optional content groups to users.
///
/// See PDF specification Table 100 -- Entries in an optional content
/// usage dictionary.
public enum OCGUsageCategory: String, Sendable, Hashable, CaseIterable {
    /// Used for print-specific content.
    case print = "Print"

    /// Used for screen display-specific content.
    case view = "View"

    /// Used for content intended for a specific user.
    case user = "User"

    /// Used for design/layout variations.
    case design = "Design"

    /// Used for language-specific content.
    case language = "Language"

    /// Used for content representing page elements.
    case pageElement = "PageElement"

    /// Used for export-specific content.
    case export = "Export"

    /// Used for zoom-dependent content.
    case zoom = "Zoom"

    /// Unknown usage category.
    case unknown = "Unknown"

    /// Creates a usage category from a string.
    ///
    /// - Parameter value: The usage category string.
    public init(fromString value: String?) {
        guard let value = value else {
            self = .unknown
            return
        }
        self = OCGUsageCategory(rawValue: value) ?? .unknown
    }
}

// MARK: - Validated Optional Content Group

/// A validation wrapper for a PDF optional content group (OCG).
///
/// Optional content groups (also known as layers) allow content to be
/// selectively shown or hidden. They are commonly used for multilingual
/// documents, print vs. screen versions, and design variations.
///
/// ## Key Properties
///
/// - **Name**: The display name of the layer
/// - **Intent**: The intended use (View, Print, Design, etc.)
/// - **DefaultState**: Whether the group is on or off by default
/// - **Usage**: Additional usage information
///
/// ## Validation Rules
///
/// - **PDF/A-1**: Optional content is prohibited entirely.
/// - **PDF/A-2+**: Optional content is allowed but must follow rules:
///   - All OCGs must be listed in the OCProperties catalog entry
///   - Default visibility must be deterministic
///   - AS (auto state) entries must use recognized events
/// - **PDF/UA**: OCGs that hide content relevant to accessibility must
///   not be used to circumvent accessibility requirements.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDOCConfig` and `GFPDOptionalContentGroup` from
/// veraPDF-validation.
public struct ValidatedOptionalContentGroup: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the OCG.
    public let cosDictionary: COSValue?

    /// The object key for the OCG, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - OCG Properties

    /// The name of the optional content group (`/Name` entry).
    ///
    /// This is displayed to the user in layer panels.
    public let name: String?

    /// The intent of the OCG (`/Intent` entry).
    ///
    /// Common values: "View", "Design". An OCG can have multiple intents.
    public let intents: [String]

    /// Whether the OCG is visible by default.
    ///
    /// This is determined by whether the OCG appears in the
    /// OCProperties default configuration's ON or OFF list.
    public let isDefaultOn: Bool

    /// The usage categories associated with this OCG.
    public let usageCategories: [OCGUsageCategory]

    /// Whether the OCG is listed in the document's OCProperties.
    ///
    /// PDF/A-2+ requires all OCGs to be listed in OCProperties.
    public let isListedInOCProperties: Bool

    /// Whether the OCG has a CreatorInfo entry in its usage dictionary.
    public let hasCreatorInfo: Bool

    /// The creator application name, if present.
    public let creatorName: String?

    /// Whether the OCG has a Language entry in its usage dictionary.
    public let hasLanguage: Bool

    /// The language code from the usage dictionary, if present.
    public let languageCode: String?

    /// Whether the language is "preferred" (vs. just "on").
    public let isPreferredLanguage: Bool

    /// Whether the OCG has an Export usage entry.
    public let hasExportUsage: Bool

    /// Whether the OCG has a Print usage entry.
    public let hasPrintUsage: Bool

    /// Whether the OCG has a View usage entry.
    public let hasViewUsage: Bool

    /// Whether the OCG has a Zoom usage entry.
    public let hasZoomUsage: Bool

    // MARK: - Initialization

    /// Creates a validated optional content group.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the OCG.
    ///   - objectKey: The object key.
    ///   - context: Validation context.
    ///   - name: The OCG name.
    ///   - intents: The OCG intents.
    ///   - isDefaultOn: Whether the OCG is visible by default.
    ///   - usageCategories: Usage categories.
    ///   - isListedInOCProperties: Whether listed in OCProperties.
    ///   - hasCreatorInfo: Whether CreatorInfo exists.
    ///   - creatorName: The creator application name.
    ///   - hasLanguage: Whether a Language entry exists.
    ///   - languageCode: The language code.
    ///   - isPreferredLanguage: Whether the language is preferred.
    ///   - hasExportUsage: Whether an Export usage entry exists.
    ///   - hasPrintUsage: Whether a Print usage entry exists.
    ///   - hasViewUsage: Whether a View usage entry exists.
    ///   - hasZoomUsage: Whether a Zoom usage entry exists.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(location: "OptionalContentGroup"),
        name: String? = nil,
        intents: [String] = ["View"],
        isDefaultOn: Bool = true,
        usageCategories: [OCGUsageCategory] = [],
        isListedInOCProperties: Bool = true,
        hasCreatorInfo: Bool = false,
        creatorName: String? = nil,
        hasLanguage: Bool = false,
        languageCode: String? = nil,
        isPreferredLanguage: Bool = false,
        hasExportUsage: Bool = false,
        hasPrintUsage: Bool = false,
        hasViewUsage: Bool = false,
        hasZoomUsage: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.name = name
        self.intents = intents
        self.isDefaultOn = isDefaultOn
        self.usageCategories = usageCategories
        self.isListedInOCProperties = isListedInOCProperties
        self.hasCreatorInfo = hasCreatorInfo
        self.creatorName = creatorName
        self.hasLanguage = hasLanguage
        self.languageCode = languageCode
        self.isPreferredLanguage = isPreferredLanguage
        self.hasExportUsage = hasExportUsage
        self.hasPrintUsage = hasPrintUsage
        self.hasViewUsage = hasViewUsage
        self.hasZoomUsage = hasZoomUsage
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDOptionalContentGroup"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "name", "intents", "isDefaultOn",
            "usageCategories", "isListedInOCProperties",
            "hasCreatorInfo", "creatorName",
            "hasLanguage", "languageCode", "isPreferredLanguage",
            "hasExportUsage", "hasPrintUsage", "hasViewUsage", "hasZoomUsage",
            "hasName", "isPDFA2Compliant", "hasViewIntent",
            "hasDesignIntent", "intentCount"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "name":
            if let n = self.name { return .string(n) }
            return .null
        case "intents":
            return .string(intents.joined(separator: ","))
        case "isDefaultOn":
            return .boolean(isDefaultOn)
        case "usageCategories":
            return .string(usageCategories.map(\.rawValue).joined(separator: ","))
        case "isListedInOCProperties":
            return .boolean(isListedInOCProperties)
        case "hasCreatorInfo":
            return .boolean(hasCreatorInfo)
        case "creatorName":
            if let cn = creatorName { return .string(cn) }
            return .null
        case "hasLanguage":
            return .boolean(hasLanguage)
        case "languageCode":
            if let lc = languageCode { return .string(lc) }
            return .null
        case "isPreferredLanguage":
            return .boolean(isPreferredLanguage)
        case "hasExportUsage":
            return .boolean(hasExportUsage)
        case "hasPrintUsage":
            return .boolean(hasPrintUsage)
        case "hasViewUsage":
            return .boolean(hasViewUsage)
        case "hasZoomUsage":
            return .boolean(hasZoomUsage)
        case "hasName":
            return .boolean(hasName)
        case "isPDFA2Compliant":
            return .boolean(isPDFA2Compliant)
        case "hasViewIntent":
            return .boolean(hasViewIntent)
        case "hasDesignIntent":
            return .boolean(hasDesignIntent)
        case "intentCount":
            return .integer(Int64(intents.count))
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedOptionalContentGroup, rhs: ValidatedOptionalContentGroup) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedOptionalContentGroup {

    /// Whether this OCG has a name.
    public var hasName: Bool {
        guard let n = name else { return false }
        return !n.isEmpty
    }

    /// Whether this OCG has a "View" intent.
    public var hasViewIntent: Bool {
        intents.contains("View")
    }

    /// Whether this OCG has a "Design" intent.
    public var hasDesignIntent: Bool {
        intents.contains("Design")
    }

    /// Whether this OCG meets PDF/A-2+ compliance requirements.
    ///
    /// PDF/A-2+ requires:
    /// - The OCG must be listed in OCProperties
    /// - The OCG must have a name
    public var isPDFA2Compliant: Bool {
        isListedInOCProperties && hasName
    }

    /// Returns a summary string describing the OCG.
    public var summary: String {
        var parts: [String] = []
        if let n = name { parts.append("'\(n)'") }
        parts.append(isDefaultOn ? "ON" : "OFF")
        if !intents.isEmpty { parts.append("intent=\(intents.joined(separator: ","))") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedOptionalContentGroup {

    /// Creates a basic OCG for testing.
    ///
    /// - Parameters:
    ///   - name: The layer name.
    ///   - isDefaultOn: Whether visible by default.
    /// - Returns: A basic OCG.
    public static func layer(
        name: String = "Layer 1",
        isDefaultOn: Bool = true
    ) -> ValidatedOptionalContentGroup {
        ValidatedOptionalContentGroup(
            name: name,
            isDefaultOn: isDefaultOn,
            isListedInOCProperties: true
        )
    }

    /// Creates a language-specific OCG for testing.
    ///
    /// - Parameters:
    ///   - name: The layer name.
    ///   - languageCode: The language code (e.g., "en", "fr").
    ///   - isPreferred: Whether this is the preferred language.
    /// - Returns: A language OCG.
    public static func language(
        name: String = "English",
        languageCode: String = "en",
        isPreferred: Bool = true
    ) -> ValidatedOptionalContentGroup {
        ValidatedOptionalContentGroup(
            name: name,
            isListedInOCProperties: true,
            hasLanguage: true,
            languageCode: languageCode,
            isPreferredLanguage: isPreferred
        )
    }
}
