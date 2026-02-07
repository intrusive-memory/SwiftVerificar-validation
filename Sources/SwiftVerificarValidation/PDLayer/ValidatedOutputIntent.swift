import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Output Intent Subtype

/// The subtype of an output intent dictionary.
///
/// PDF output intents specify the intended output device or condition
/// for the document. Different subtypes are used for different standards.
///
/// See PDF specification Table 366 -- Entries in an output intent dictionary.
public enum OutputIntentSubtype: String, Sendable, Hashable, CaseIterable {
    /// PDF/X output intent (ISO 15930).
    case gtspdFX = "GTS_PDFX"

    /// PDF/A output intent (ISO 19005).
    case gtsPDFA = "GTS_PDFA1"

    /// ISO-standardized output intent.
    case iso = "ISO_PDFE1"

    /// Unknown subtype.
    case unknown = "Unknown"

    /// Creates an output intent subtype from a string.
    ///
    /// - Parameter value: The subtype string from the PDF dictionary.
    public init(fromString value: String?) {
        guard let value = value else {
            self = .unknown
            return
        }
        self = OutputIntentSubtype(rawValue: value) ?? .unknown
    }

    /// Whether this subtype is relevant for PDF/A validation.
    public var isPDFARelevant: Bool {
        self == .gtsPDFA
    }

    /// Whether this subtype is relevant for PDF/X validation.
    public var isPDFXRelevant: Bool {
        self == .gtspdFX
    }
}

// MARK: - Validated Output Intent

/// A validation wrapper for a PDF output intent dictionary.
///
/// Output intents define the intended output device or viewing conditions
/// for a PDF document. They are critical for PDF/A compliance, where at
/// least one output intent must be present for certain conformance levels.
///
/// ## Key Properties
///
/// - **Subtype**: The type of output intent (PDF/X, PDF/A, etc.)
/// - **OutputCondition**: A human-readable description of the intended output
/// - **OutputConditionIdentifier**: A registered identifier (e.g., "sRGB IEC61966-2.1")
/// - **DestOutputProfile**: An ICC profile describing the output device
///
/// ## Validation Rules
///
/// - **PDF/A-1**: Exactly one output intent with subtype GTS_PDFA1 should exist,
///   and it must include a DestOutputProfile (ICC profile).
/// - **PDF/A-2+**: Relaxed rules; multiple output intents allowed, ICC profile
///   version restrictions apply.
/// - **PDF/X**: Output intents required with specific conditions.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDOutputIntent` from veraPDF-validation, which validates
/// output intent dictionaries against PDF/A and PDF/X requirements.
public struct ValidatedOutputIntent: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the output intent.
    public let cosDictionary: COSValue?

    /// The object key for the output intent, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Output Intent Properties

    /// The output intent subtype (`/S` entry).
    ///
    /// This identifies the type of output intent (e.g., GTS_PDFX, GTS_PDFA1).
    public let subtype: OutputIntentSubtype

    /// The raw subtype string from the dictionary.
    public let subtypeName: String

    /// The human-readable output condition description (`/OutputCondition` entry).
    ///
    /// This is an optional text description of the intended output conditions.
    public let outputCondition: String?

    /// The registered output condition identifier (`/OutputConditionIdentifier` entry).
    ///
    /// This is a standard identifier for the output condition, such as
    /// "sRGB IEC61966-2.1" or "CGATS TR 001".
    public let outputConditionIdentifier: String?

    /// Additional information about the intended output (`/Info` entry).
    public let info: String?

    /// The registry name for the output condition identifier (`/RegistryName` entry).
    ///
    /// The default registry is "http://www.color.org".
    public let registryName: String?

    /// Whether a destination output profile (ICC profile) is present (`/DestOutputProfile` entry).
    public let hasDestOutputProfile: Bool

    /// The number of components in the destination output profile.
    ///
    /// Common values: 1 (gray), 3 (RGB), 4 (CMYK).
    public let destOutputProfileComponents: Int?

    /// The ICC profile color space type of the destination output profile.
    public let destOutputProfileColorSpace: String?

    /// The ICC profile version of the destination output profile.
    public let destOutputProfileVersion: String?

    // MARK: - Initialization

    /// Creates a validated output intent.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the output intent.
    ///   - objectKey: The object key.
    ///   - context: Validation context.
    ///   - subtypeName: The raw subtype string.
    ///   - outputCondition: The human-readable output condition.
    ///   - outputConditionIdentifier: The registered identifier.
    ///   - info: Additional information.
    ///   - registryName: The registry name.
    ///   - hasDestOutputProfile: Whether a destination profile exists.
    ///   - destOutputProfileComponents: Number of profile components.
    ///   - destOutputProfileColorSpace: Profile color space type.
    ///   - destOutputProfileVersion: Profile version string.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(location: "OutputIntent"),
        subtypeName: String = "GTS_PDFA1",
        outputCondition: String? = nil,
        outputConditionIdentifier: String? = nil,
        info: String? = nil,
        registryName: String? = nil,
        hasDestOutputProfile: Bool = false,
        destOutputProfileComponents: Int? = nil,
        destOutputProfileColorSpace: String? = nil,
        destOutputProfileVersion: String? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.subtypeName = subtypeName
        self.subtype = OutputIntentSubtype(fromString: subtypeName)
        self.outputCondition = outputCondition
        self.outputConditionIdentifier = outputConditionIdentifier
        self.info = info
        self.registryName = registryName
        self.hasDestOutputProfile = hasDestOutputProfile
        self.destOutputProfileComponents = destOutputProfileComponents
        self.destOutputProfileColorSpace = destOutputProfileColorSpace
        self.destOutputProfileVersion = destOutputProfileVersion
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDOutputIntent"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "subtype", "subtypeName",
            "outputCondition", "outputConditionIdentifier",
            "info", "registryName",
            "hasDestOutputProfile", "destOutputProfileComponents",
            "destOutputProfileColorSpace", "destOutputProfileVersion",
            "isPDFACompliant", "hasRequiredIdentifier",
            "isColorOrg"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "subtype":
            return .string(subtype.rawValue)
        case "subtypeName":
            return .string(subtypeName)
        case "outputCondition":
            if let oc = outputCondition { return .string(oc) }
            return .null
        case "outputConditionIdentifier":
            if let oci = outputConditionIdentifier { return .string(oci) }
            return .null
        case "info":
            if let i = info { return .string(i) }
            return .null
        case "registryName":
            if let rn = registryName { return .string(rn) }
            return .null
        case "hasDestOutputProfile":
            return .boolean(hasDestOutputProfile)
        case "destOutputProfileComponents":
            if let c = destOutputProfileComponents { return .integer(Int64(c)) }
            return .null
        case "destOutputProfileColorSpace":
            if let cs = destOutputProfileColorSpace { return .string(cs) }
            return .null
        case "destOutputProfileVersion":
            if let v = destOutputProfileVersion { return .string(v) }
            return .null
        case "isPDFACompliant":
            return .boolean(isPDFACompliant)
        case "hasRequiredIdentifier":
            return .boolean(hasRequiredIdentifier)
        case "isColorOrg":
            return .boolean(isColorOrg)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedOutputIntent, rhs: ValidatedOutputIntent) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedOutputIntent {

    /// Whether this output intent has the required identifier.
    ///
    /// PDF/A requires that the OutputConditionIdentifier be present.
    public var hasRequiredIdentifier: Bool {
        if let oci = outputConditionIdentifier {
            return !oci.isEmpty
        }
        return false
    }

    /// Whether the registry name is the ICC color.org registry.
    public var isColorOrg: Bool {
        guard let registry = registryName else { return false }
        return registry.lowercased().contains("color.org")
    }

    /// Whether this output intent meets PDF/A-1 compliance requirements.
    ///
    /// For PDF/A-1, the output intent must:
    /// - Have subtype GTS_PDFA1
    /// - Include an OutputConditionIdentifier
    /// - Include a DestOutputProfile if the identifier is not a registered one
    public var isPDFACompliant: Bool {
        guard subtype == .gtsPDFA else { return false }
        guard hasRequiredIdentifier else { return false }
        // If the identifier is a well-known standard, profile is optional
        if isWellKnownIdentifier { return true }
        // Otherwise, profile must be present
        return hasDestOutputProfile
    }

    /// Whether the output condition identifier is a well-known standard.
    ///
    /// Well-known identifiers (like "sRGB IEC61966-2.1") do not require
    /// an embedded ICC profile.
    public var isWellKnownIdentifier: Bool {
        guard let oci = outputConditionIdentifier else { return false }
        let known = [
            "sRGB IEC61966-2.1",
            "sRGB",
            "Adobe RGB (1998)",
            "CGATS TR 001",
            "CGATS TR 006",
            "FOGRA39",
            "FOGRA43",
            "FOGRA47",
            "FOGRA51",
            "FOGRA52",
            "GRACoL2006_Coated1v2",
            "SWOP2006_Coated3v2",
            "SWOP2006_Coated5v2"
        ]
        return known.contains(oci)
    }

    /// Returns a summary string describing the output intent.
    public var summary: String {
        var parts: [String] = [subtypeName]
        if let oci = outputConditionIdentifier { parts.append(oci) }
        if hasDestOutputProfile { parts.append("has profile") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedOutputIntent {

    /// Creates a minimal PDF/A output intent for testing.
    ///
    /// - Parameters:
    ///   - identifier: The output condition identifier.
    ///   - hasProfile: Whether a destination profile is included.
    /// - Returns: A PDF/A-compliant output intent.
    public static func pdfA(
        identifier: String = "sRGB IEC61966-2.1",
        hasProfile: Bool = true
    ) -> ValidatedOutputIntent {
        ValidatedOutputIntent(
            subtypeName: "GTS_PDFA1",
            outputConditionIdentifier: identifier,
            registryName: "http://www.color.org",
            hasDestOutputProfile: hasProfile,
            destOutputProfileComponents: 3,
            destOutputProfileColorSpace: "RGB"
        )
    }

    /// Creates a minimal PDF/X output intent for testing.
    ///
    /// - Parameters:
    ///   - identifier: The output condition identifier.
    ///   - hasProfile: Whether a destination profile is included.
    /// - Returns: A PDF/X output intent.
    public static func pdfX(
        identifier: String = "CGATS TR 001",
        hasProfile: Bool = true
    ) -> ValidatedOutputIntent {
        ValidatedOutputIntent(
            subtypeName: "GTS_PDFX",
            outputConditionIdentifier: identifier,
            hasDestOutputProfile: hasProfile,
            destOutputProfileComponents: 4,
            destOutputProfileColorSpace: "CMYK"
        )
    }
}
