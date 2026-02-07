import Foundation

// MARK: - XMP Schema Protocol

/// Protocol defining the interface for XMP schema types.
///
/// XMP (Extensible Metadata Platform) uses schemas to organize metadata properties
/// into namespaces. Each schema defines a set of properties with specific semantics.
///
/// This protocol provides a common interface for working with XMP schema data,
/// supporting both reading and writing of properties.
///
/// ## PDF/A Compliance
///
/// PDF/A requires XMP metadata to be synchronized with the Info dictionary.
/// The following XMP schemas are commonly used:
/// - Dublin Core (dc:) - title, creator, description, subject
/// - XMP Basic (xmp:) - creator tool, creation date, modification date
/// - Adobe PDF (pdf:) - PDF-specific properties like producer, keywords
///
/// ## XMP Namespaces
///
/// Common XMP namespace URIs:
/// - `http://purl.org/dc/elements/1.1/` - Dublin Core
/// - `http://ns.adobe.com/xap/1.0/` - XMP Basic
/// - `http://ns.adobe.com/pdf/1.3/` - Adobe PDF
/// - `http://ns.adobe.com/pdfx/1.3/` - PDF/X identification
/// - `http://www.aiim.org/pdfa/ns/id/` - PDF/A identification
public protocol XMPSchema: Sendable {

    /// The namespace URI for this schema.
    ///
    /// Example: `http://purl.org/dc/elements/1.1/` for Dublin Core
    static var namespaceURI: String { get }

    /// The preferred namespace prefix for this schema.
    ///
    /// Example: `dc` for Dublin Core
    static var preferredPrefix: String { get }

    /// Returns all property names defined in this schema.
    var propertyNames: [String] { get }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name (without namespace prefix)
    /// - Returns: The property value, or nil if not set
    func property(named name: String) -> XMPValue?

    /// Sets a property value.
    ///
    /// - Parameters:
    ///   - name: The property name (without namespace prefix)
    ///   - value: The value to set, or nil to remove
    mutating func setProperty(named name: String, to value: XMPValue?)

    /// Validates this schema for PDF/A compliance.
    ///
    /// - Returns: Any validation issues found
    func validate() -> [XMPValidationIssue]

    /// Returns this schema serialized as XMP XML fragment.
    ///
    /// - Returns: XML string representing this schema's properties
    func toXML() -> String
}

// MARK: - XMP Value

/// Represents a value in XMP metadata.
///
/// XMP supports various value types including simple values, arrays, and structures.
public enum XMPValue: Sendable, Equatable, CustomStringConvertible {

    /// A simple text value.
    case text(String)

    /// A URI/URL value.
    case uri(String)

    /// A date value.
    case date(Date)

    /// An integer value.
    case integer(Int)

    /// A boolean value.
    case boolean(Bool)

    /// A real/floating-point value.
    case real(Double)

    /// A language alternative (localized text).
    ///
    /// Keys are language codes (e.g., "en", "x-default"), values are the localized strings.
    case langAlt([String: String])

    /// An unordered bag of values (XMP Bag).
    case bag([XMPValue])

    /// An ordered sequence of values (XMP Seq).
    case seq([XMPValue])

    /// An alternative set of values (XMP Alt).
    case alt([XMPValue])

    /// A structure with named properties.
    case structure([String: XMPValue])

    // MARK: - Value Extraction

    /// Returns the text value if this is a text or uri value.
    public var textValue: String? {
        switch self {
        case .text(let s): return s
        case .uri(let s): return s
        default: return nil
        }
    }

    /// Returns the date value if this is a date value.
    public var dateValue: Date? {
        if case .date(let d) = self { return d }
        return nil
    }

    /// Returns the integer value if this is an integer value.
    public var integerValue: Int? {
        if case .integer(let i) = self { return i }
        return nil
    }

    /// Returns the boolean value if this is a boolean value.
    public var booleanValue: Bool? {
        if case .boolean(let b) = self { return b }
        return nil
    }

    /// Returns the real value if this is a real or integer value.
    public var realValue: Double? {
        switch self {
        case .real(let r): return r
        case .integer(let i): return Double(i)
        default: return nil
        }
    }

    /// Returns the language alternative if this is a langAlt value.
    public var langAltValue: [String: String]? {
        if case .langAlt(let alt) = self { return alt }
        return nil
    }

    /// Returns the default text from a language alternative.
    public var defaultLanguageText: String? {
        guard let alt = langAltValue else { return textValue }
        return alt["x-default"] ?? alt.values.first
    }

    /// Returns the bag values if this is a bag.
    public var bagValues: [XMPValue]? {
        if case .bag(let values) = self { return values }
        return nil
    }

    /// Returns the sequence values if this is a seq.
    public var seqValues: [XMPValue]? {
        if case .seq(let values) = self { return values }
        return nil
    }

    /// Returns the alternative values if this is an alt.
    public var altValues: [XMPValue]? {
        if case .alt(let values) = self { return values }
        return nil
    }

    /// Returns all array values regardless of array type.
    public var arrayValues: [XMPValue]? {
        switch self {
        case .bag(let values), .seq(let values), .alt(let values):
            return values
        default:
            return nil
        }
    }

    /// Returns the structure properties if this is a structure.
    public var structureValue: [String: XMPValue]? {
        if case .structure(let props) = self { return props }
        return nil
    }

    // MARK: - Type Checking

    /// Whether this value is a simple type (text, uri, date, integer, boolean, real).
    public var isSimple: Bool {
        switch self {
        case .text, .uri, .date, .integer, .boolean, .real:
            return true
        default:
            return false
        }
    }

    /// Whether this value is an array type (bag, seq, alt).
    public var isArray: Bool {
        switch self {
        case .bag, .seq, .alt:
            return true
        default:
            return false
        }
    }

    /// Whether this value is a language alternative.
    public var isLangAlt: Bool {
        if case .langAlt = self { return true }
        return false
    }

    /// Whether this value is a structure.
    public var isStructure: Bool {
        if case .structure = self { return true }
        return false
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .text(let s): return s
        case .uri(let s): return s
        case .date(let d): return d.toXMPDateString()
        case .integer(let i): return String(i)
        case .boolean(let b): return b ? "True" : "False"
        case .real(let r): return String(r)
        case .langAlt(let alt):
            let entries = alt.map { "[\($0.key)] \($0.value)" }.joined(separator: ", ")
            return "LangAlt(\(entries))"
        case .bag(let values):
            return "Bag[\(values.map(\.description).joined(separator: ", "))]"
        case .seq(let values):
            return "Seq[\(values.map(\.description).joined(separator: ", "))]"
        case .alt(let values):
            return "Alt[\(values.map(\.description).joined(separator: ", "))]"
        case .structure(let props):
            let entries = props.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            return "Struct{\(entries)}"
        }
    }
}

// MARK: - XMPValue Literal Expressibility

extension XMPValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .text(value)
    }
}

extension XMPValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .integer(value)
    }
}

extension XMPValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .real(value)
    }
}

extension XMPValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

// MARK: - XMP Validation Issue

/// Represents a validation issue found in XMP metadata.
public struct XMPValidationIssue: Sendable, Equatable, Identifiable {
    public let id: UUID

    /// The severity of the issue.
    public let severity: Severity

    /// The schema namespace where the issue was found.
    public let namespace: String

    /// The property name where the issue was found, if applicable.
    public let propertyName: String?

    /// A description of the issue.
    public let message: String

    /// The PDF/A rule ID related to this issue, if applicable.
    public let ruleId: String?

    public init(
        id: UUID = UUID(),
        severity: Severity,
        namespace: String,
        propertyName: String? = nil,
        message: String,
        ruleId: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.namespace = namespace
        self.propertyName = propertyName
        self.message = message
        self.ruleId = ruleId
    }

    /// Severity levels for XMP validation issues.
    public enum Severity: String, Sendable, Codable {
        /// An error that prevents PDF/A compliance.
        case error

        /// A warning that may indicate potential issues.
        case warning

        /// An informational note.
        case info
    }
}

// MARK: - XMP Schema Registry

/// Registry for looking up XMP schema types by namespace URI or prefix.
public struct XMPSchemaRegistry: Sendable {

    /// The shared registry instance.
    public static let shared = XMPSchemaRegistry()

    /// Known namespace URIs mapped to their preferred prefixes.
    private let namespaces: [String: String] = [
        "http://purl.org/dc/elements/1.1/": "dc",
        "http://ns.adobe.com/xap/1.0/": "xmp",
        "http://ns.adobe.com/pdf/1.3/": "pdf",
        "http://ns.adobe.com/xap/1.0/mm/": "xmpMM",
        "http://ns.adobe.com/xap/1.0/rights/": "xmpRights",
        "http://ns.adobe.com/pdfx/1.3/": "pdfx",
        "http://www.aiim.org/pdfa/ns/id/": "pdfaid",
        "http://www.aiim.org/pdfa/ns/extension/": "pdfaExtension",
        "http://www.aiim.org/pdfa/ns/schema#": "pdfaSchema",
        "http://www.aiim.org/pdfa/ns/property#": "pdfaProperty",
        "http://www.aiim.org/pdfa/ns/type#": "pdfaType",
        "http://www.aiim.org/pdfa/ns/field#": "pdfaField",
        "http://www.npes.org/pdfx/ns/id/": "pdfxid",
        "http://ns.adobe.com/photoshop/1.0/": "photoshop",
        "http://ns.adobe.com/tiff/1.0/": "tiff",
        "http://ns.adobe.com/exif/1.0/": "exif"
    ]

    private init() {}

    /// Returns the preferred prefix for a namespace URI.
    ///
    /// - Parameter namespaceURI: The namespace URI
    /// - Returns: The preferred prefix, or nil if unknown
    public func prefix(for namespaceURI: String) -> String? {
        namespaces[namespaceURI]
    }

    /// Returns the namespace URI for a prefix.
    ///
    /// - Parameter prefix: The namespace prefix
    /// - Returns: The namespace URI, or nil if unknown
    public func namespaceURI(for prefix: String) -> String? {
        namespaces.first { $0.value == prefix }?.key
    }

    /// Returns all registered namespace URIs.
    public var allNamespaceURIs: [String] {
        Array(namespaces.keys)
    }

    /// Returns all registered prefixes.
    public var allPrefixes: [String] {
        Array(namespaces.values)
    }
}

// MARK: - XMP Property Type

/// Describes the type of an XMP property.
public enum XMPPropertyType: String, Sendable, Codable {
    /// A simple text value.
    case text = "Text"

    /// A URI value.
    case uri = "URI"

    /// A date value.
    case date = "Date"

    /// An integer value.
    case integer = "Integer"

    /// A boolean value.
    case boolean = "Boolean"

    /// A real number value.
    case real = "Real"

    /// A localized text value (language alternative).
    case langAlt = "Lang Alt"

    /// An unordered array of values.
    case bag = "bag"

    /// An ordered array of values.
    case seq = "seq"

    /// An alternative array of values.
    case alt = "alt"

    /// A structure with named fields.
    case structure = "structure"
}

// MARK: - XMP Property Descriptor

/// Describes a property in an XMP schema.
public struct XMPPropertyDescriptor: Sendable {

    /// The property name (without namespace prefix).
    public let name: String

    /// The property type.
    public let type: XMPPropertyType

    /// A description of the property.
    public let description: String

    /// Whether the property is required for PDF/A compliance.
    public let isRequired: Bool

    /// The corresponding Info dictionary key, if any.
    public let infoDictKey: String?

    public init(
        name: String,
        type: XMPPropertyType,
        description: String,
        isRequired: Bool = false,
        infoDictKey: String? = nil
    ) {
        self.name = name
        self.type = type
        self.description = description
        self.isRequired = isRequired
        self.infoDictKey = infoDictKey
    }
}

// MARK: - XMP Extension Schema

/// Represents extension schema metadata required for PDF/A when using custom namespaces.
public struct XMPExtensionSchema: Sendable {

    /// The namespace URI for this extension.
    public let namespaceURI: String

    /// The preferred namespace prefix.
    public let prefix: String

    /// A description of the schema.
    public let schemaDescription: String

    /// The properties defined in this schema.
    public let properties: [XMPPropertyDescriptor]

    public init(
        namespaceURI: String,
        prefix: String,
        schemaDescription: String,
        properties: [XMPPropertyDescriptor]
    ) {
        self.namespaceURI = namespaceURI
        self.prefix = prefix
        self.schemaDescription = schemaDescription
        self.properties = properties
    }

    /// Generates the PDF/A extension schema XML.
    public func toExtensionXML() -> String {
        var xml = """
        <rdf:li rdf:parseType="Resource">
          <pdfaSchema:schema>\(schemaDescription)</pdfaSchema:schema>
          <pdfaSchema:namespaceURI>\(namespaceURI)</pdfaSchema:namespaceURI>
          <pdfaSchema:prefix>\(prefix)</pdfaSchema:prefix>
          <pdfaSchema:property>
            <rdf:Seq>

        """

        for property in properties {
            xml += """
              <rdf:li rdf:parseType="Resource">
                <pdfaProperty:name>\(property.name)</pdfaProperty:name>
                <pdfaProperty:valueType>\(property.type.rawValue)</pdfaProperty:valueType>
                <pdfaProperty:category>external</pdfaProperty:category>
                <pdfaProperty:description>\(property.description)</pdfaProperty:description>
              </rdf:li>

            """
        }

        xml += """
            </rdf:Seq>
          </pdfaSchema:property>
        </rdf:li>
        """

        return xml
    }
}
