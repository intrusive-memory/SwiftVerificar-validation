import Foundation

// MARK: - Dublin Core Schema

/// Dublin Core metadata schema (dc: namespace) for XMP metadata.
///
/// The Dublin Core schema provides core descriptive metadata properties
/// based on the Dublin Core Metadata Element Set.
///
/// ## Namespace
/// - URI: `http://purl.org/dc/elements/1.1/`
/// - Prefix: `dc`
///
/// ## Properties
/// - `contributor` - Contributors to the resource (Bag)
/// - `coverage` - Spatial or temporal coverage
/// - `creator` - Creators of the resource (Seq)
/// - `date` - Date(s) associated with the resource (Seq)
/// - `description` - Description of the resource (Lang Alt)
/// - `format` - File format, physical medium, or dimensions
/// - `identifier` - Unique identifier for the resource
/// - `language` - Languages of the resource (Bag)
/// - `publisher` - Publisher of the resource (Bag)
/// - `relation` - Related resources
/// - `rights` - Rights information (Lang Alt)
/// - `source` - Source from which resource was derived
/// - `subject` - Subject of the resource (Bag)
/// - `title` - Title of the resource (Lang Alt)
/// - `type` - Nature or genre of the resource (Bag)
///
/// ## PDF/A Synchronization
///
/// For PDF/A compliance, the following properties must be synchronized
/// with the Info dictionary:
/// - `dc:title` <-> Info dictionary `/Title`
/// - `dc:creator` <-> Info dictionary `/Author`
/// - `dc:description` <-> Info dictionary `/Subject`
public struct DublinCoreSchema: XMPSchema, Sendable, Equatable {

    // MARK: - Static Properties

    public static let namespaceURI = "http://purl.org/dc/elements/1.1/"
    public static let preferredPrefix = "dc"

    // MARK: - Properties

    /// Contributors to the resource.
    ///
    /// An unordered bag of names of additional contributors.
    public var contributor: [String]?

    /// Spatial or temporal coverage.
    public var coverage: String?

    /// Creators of the resource.
    ///
    /// An ordered sequence of creator names.
    /// Corresponds to Info dictionary `/Author`.
    public var creator: [String]?

    /// Dates associated with the resource.
    ///
    /// An ordered sequence of dates.
    public var date: [Date]?

    /// Description of the resource.
    ///
    /// A language alternative (localized text).
    /// Corresponds to Info dictionary `/Subject`.
    public var descriptionText: [String: String]?

    /// File format, physical medium, or dimensions.
    ///
    /// Typically MIME type for digital resources.
    public var format: String?

    /// Unique identifier for the resource.
    public var identifier: String?

    /// Languages of the resource.
    ///
    /// An unordered bag of language codes (RFC 3066).
    public var language: [String]?

    /// Publisher of the resource.
    ///
    /// An unordered bag of publisher names.
    public var publisher: [String]?

    /// Related resources.
    ///
    /// An unordered bag of related resource identifiers.
    public var relation: [String]?

    /// Rights information.
    ///
    /// A language alternative (localized text).
    public var rights: [String: String]?

    /// Source from which resource was derived.
    public var source: String?

    /// Subject keywords.
    ///
    /// An unordered bag of descriptive phrases or keywords.
    public var subject: [String]?

    /// Title of the resource.
    ///
    /// A language alternative (localized text).
    /// Corresponds to Info dictionary `/Title`.
    public var title: [String: String]?

    /// Nature or genre of the resource.
    ///
    /// An unordered bag of type terms.
    public var type: [String]?

    /// Custom properties not defined in the standard schema.
    private var customProperties: [String: XMPValue] = [:]

    // MARK: - Initialization

    public init(
        contributor: [String]? = nil,
        coverage: String? = nil,
        creator: [String]? = nil,
        date: [Date]? = nil,
        descriptionText: [String: String]? = nil,
        format: String? = nil,
        identifier: String? = nil,
        language: [String]? = nil,
        publisher: [String]? = nil,
        relation: [String]? = nil,
        rights: [String: String]? = nil,
        source: String? = nil,
        subject: [String]? = nil,
        title: [String: String]? = nil,
        type: [String]? = nil
    ) {
        self.contributor = contributor
        self.coverage = coverage
        self.creator = creator
        self.date = date
        self.descriptionText = descriptionText
        self.format = format
        self.identifier = identifier
        self.language = language
        self.publisher = publisher
        self.relation = relation
        self.rights = rights
        self.source = source
        self.subject = subject
        self.title = title
        self.type = type
    }

    // MARK: - Convenience Accessors

    /// Returns the default title (x-default language).
    public var defaultTitle: String? {
        title?["x-default"] ?? title?.values.first
    }

    /// Returns the default description (x-default language).
    public var defaultDescription: String? {
        descriptionText?["x-default"] ?? descriptionText?.values.first
    }

    /// Returns the first creator.
    public var primaryCreator: String? {
        creator?.first
    }

    /// Returns all creators as a single comma-separated string.
    public var creatorsString: String? {
        guard let creators = creator, !creators.isEmpty else { return nil }
        return creators.joined(separator: ", ")
    }

    // MARK: - XMPSchema Protocol

    public var propertyNames: [String] {
        var names = [
            "contributor", "coverage", "creator", "date", "description",
            "format", "identifier", "language", "publisher", "relation",
            "rights", "source", "subject", "title", "type"
        ]
        names.append(contentsOf: customProperties.keys)
        return names
    }

    public func property(named name: String) -> XMPValue? {
        switch name {
        case "contributor":
            return contributor.map { .bag($0.map { .text($0) }) }
        case "coverage":
            return coverage.map { .text($0) }
        case "creator":
            return creator.map { .seq($0.map { .text($0) }) }
        case "date":
            return date.map { .seq($0.map { .date($0) }) }
        case "description":
            return descriptionText.map { .langAlt($0) }
        case "format":
            return format.map { .text($0) }
        case "identifier":
            return identifier.map { .text($0) }
        case "language":
            return language.map { .bag($0.map { .text($0) }) }
        case "publisher":
            return publisher.map { .bag($0.map { .text($0) }) }
        case "relation":
            return relation.map { .bag($0.map { .text($0) }) }
        case "rights":
            return rights.map { .langAlt($0) }
        case "source":
            return source.map { .text($0) }
        case "subject":
            return subject.map { .bag($0.map { .text($0) }) }
        case "title":
            return title.map { .langAlt($0) }
        case "type":
            return type.map { .bag($0.map { .text($0) }) }
        default:
            return customProperties[name]
        }
    }

    public mutating func setProperty(named name: String, to value: XMPValue?) {
        switch name {
        case "contributor":
            contributor = extractStringArray(from: value)
        case "coverage":
            coverage = value?.textValue
        case "creator":
            creator = extractStringArray(from: value)
        case "date":
            date = extractDateArray(from: value)
        case "description":
            descriptionText = value?.langAltValue
        case "format":
            format = value?.textValue
        case "identifier":
            identifier = value?.textValue
        case "language":
            language = extractStringArray(from: value)
        case "publisher":
            publisher = extractStringArray(from: value)
        case "relation":
            relation = extractStringArray(from: value)
        case "rights":
            rights = value?.langAltValue
        case "source":
            source = value?.textValue
        case "subject":
            subject = extractStringArray(from: value)
        case "title":
            title = value?.langAltValue
        case "type":
            type = extractStringArray(from: value)
        default:
            customProperties[name] = value
        }
    }

    public func validate() -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Check for common issues

        // Empty title
        if let titleDict = title, titleDict.isEmpty {
            issues.append(XMPValidationIssue(
                severity: .warning,
                namespace: Self.namespaceURI,
                propertyName: "title",
                message: "dc:title is present but empty"
            ))
        }

        // Empty creator list
        if let creators = creator, creators.isEmpty {
            issues.append(XMPValidationIssue(
                severity: .warning,
                namespace: Self.namespaceURI,
                propertyName: "creator",
                message: "dc:creator is present but empty"
            ))
        }

        // Validate language codes if present
        if let languages = language {
            for lang in languages {
                if !isValidLanguageCode(lang) {
                    issues.append(XMPValidationIssue(
                        severity: .warning,
                        namespace: Self.namespaceURI,
                        propertyName: "language",
                        message: "Invalid language code: '\(lang)'. Expected RFC 3066 format."
                    ))
                }
            }
        }

        // Validate format as MIME type if present
        if let fmt = format {
            if !isValidMIMEType(fmt) {
                issues.append(XMPValidationIssue(
                    severity: .info,
                    namespace: Self.namespaceURI,
                    propertyName: "format",
                    message: "dc:format '\(fmt)' may not be a valid MIME type"
                ))
            }
        }

        return issues
    }

    public func toXML() -> String {
        var elements: [String] = []

        // contributor (Bag)
        if let contributors = contributor, !contributors.isEmpty {
            elements.append(formatBag("dc:contributor", values: contributors))
        }

        // coverage (Text)
        if let coverage = coverage {
            elements.append("<dc:coverage>\(escapeXML(coverage))</dc:coverage>")
        }

        // creator (Seq)
        if let creators = creator, !creators.isEmpty {
            elements.append(formatSeq("dc:creator", values: creators))
        }

        // date (Seq of Date)
        if let dates = date, !dates.isEmpty {
            let dateStrings = dates.map { $0.toXMPDateString() }
            elements.append(formatSeq("dc:date", values: dateStrings))
        }

        // description (Lang Alt)
        if let desc = descriptionText, !desc.isEmpty {
            elements.append(formatLangAlt("dc:description", values: desc))
        }

        // format (Text)
        if let format = format {
            elements.append("<dc:format>\(escapeXML(format))</dc:format>")
        }

        // identifier (Text)
        if let identifier = identifier {
            elements.append("<dc:identifier>\(escapeXML(identifier))</dc:identifier>")
        }

        // language (Bag)
        if let languages = language, !languages.isEmpty {
            elements.append(formatBag("dc:language", values: languages))
        }

        // publisher (Bag)
        if let publishers = publisher, !publishers.isEmpty {
            elements.append(formatBag("dc:publisher", values: publishers))
        }

        // relation (Bag)
        if let relations = relation, !relations.isEmpty {
            elements.append(formatBag("dc:relation", values: relations))
        }

        // rights (Lang Alt)
        if let rights = rights, !rights.isEmpty {
            elements.append(formatLangAlt("dc:rights", values: rights))
        }

        // source (Text)
        if let source = source {
            elements.append("<dc:source>\(escapeXML(source))</dc:source>")
        }

        // subject (Bag)
        if let subjects = subject, !subjects.isEmpty {
            elements.append(formatBag("dc:subject", values: subjects))
        }

        // title (Lang Alt)
        if let title = title, !title.isEmpty {
            elements.append(formatLangAlt("dc:title", values: title))
        }

        // type (Bag)
        if let types = type, !types.isEmpty {
            elements.append(formatBag("dc:type", values: types))
        }

        // Custom properties
        for (name, value) in customProperties.sorted(by: { $0.key < $1.key }) {
            elements.append("<dc:\(name)>\(escapeXML(value.description))</dc:\(name)>")
        }

        return elements.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private func extractStringArray(from value: XMPValue?) -> [String]? {
        guard let value = value else { return nil }
        if let array = value.arrayValues {
            return array.compactMap { $0.textValue }
        }
        if let text = value.textValue {
            return [text]
        }
        return nil
    }

    private func extractDateArray(from value: XMPValue?) -> [Date]? {
        guard let value = value else { return nil }
        if let array = value.arrayValues {
            return array.compactMap { $0.dateValue }
        }
        if let date = value.dateValue {
            return [date]
        }
        return nil
    }

    private func isValidLanguageCode(_ code: String) -> Bool {
        // Simple validation for RFC 3066 language codes
        // Primary subtag: 2-3 letters, optional subtags separated by hyphens
        let pattern = #"^[a-zA-Z]{2,3}(-[a-zA-Z0-9]{2,8})*$"#
        return code.range(of: pattern, options: .regularExpression) != nil
    }

    private func isValidMIMEType(_ type: String) -> Bool {
        // Simple validation for MIME type format: type/subtype
        let pattern = #"^[a-zA-Z0-9][a-zA-Z0-9!#$&\-^_]*\/[a-zA-Z0-9][a-zA-Z0-9!#$&\-^_.+]*$"#
        return type.range(of: pattern, options: .regularExpression) != nil
    }

    private func escapeXML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&apos;")
        return escaped
    }

    private func formatBag(_ name: String, values: [String]) -> String {
        var xml = "<\(name)>\n  <rdf:Bag>\n"
        for value in values {
            xml += "    <rdf:li>\(escapeXML(value))</rdf:li>\n"
        }
        xml += "  </rdf:Bag>\n</\(name)>"
        return xml
    }

    private func formatSeq(_ name: String, values: [String]) -> String {
        var xml = "<\(name)>\n  <rdf:Seq>\n"
        for value in values {
            xml += "    <rdf:li>\(escapeXML(value))</rdf:li>\n"
        }
        xml += "  </rdf:Seq>\n</\(name)>"
        return xml
    }

    private func formatLangAlt(_ name: String, values: [String: String]) -> String {
        var xml = "<\(name)>\n  <rdf:Alt>\n"
        // Ensure x-default comes first if present
        let sortedKeys = values.keys.sorted { key1, key2 in
            if key1 == "x-default" { return true }
            if key2 == "x-default" { return false }
            return key1 < key2
        }
        for key in sortedKeys {
            if let value = values[key] {
                xml += "    <rdf:li xml:lang=\"\(key)\">\(escapeXML(value))</rdf:li>\n"
            }
        }
        xml += "  </rdf:Alt>\n</\(name)>"
        return xml
    }
}

// MARK: - Property Descriptors

extension DublinCoreSchema {

    /// Returns descriptors for all properties in this schema.
    public static var propertyDescriptors: [XMPPropertyDescriptor] {
        [
            XMPPropertyDescriptor(
                name: "contributor",
                type: .bag,
                description: "Contributors to the resource other than the creators.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "coverage",
                type: .text,
                description: "Spatial or temporal coverage of the resource.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "creator",
                type: .seq,
                description: "Creators of the resource (authors).",
                isRequired: false,
                infoDictKey: "Author"
            ),
            XMPPropertyDescriptor(
                name: "date",
                type: .seq,
                description: "Dates associated with events in the lifecycle of the resource.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "description",
                type: .langAlt,
                description: "Description of the resource content.",
                isRequired: false,
                infoDictKey: "Subject"
            ),
            XMPPropertyDescriptor(
                name: "format",
                type: .text,
                description: "File format or physical medium. Typically MIME type.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "identifier",
                type: .text,
                description: "Unique identifier for the resource.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "language",
                type: .bag,
                description: "Languages of the intellectual content.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "publisher",
                type: .bag,
                description: "Publisher of the resource.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "relation",
                type: .bag,
                description: "Related resources.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "rights",
                type: .langAlt,
                description: "Rights or copyright information.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "source",
                type: .text,
                description: "Unique identifier for the original resource from which this was derived.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "subject",
                type: .bag,
                description: "Subject keywords or phrases.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "title",
                type: .langAlt,
                description: "Title of the resource.",
                isRequired: false,
                infoDictKey: "Title"
            ),
            XMPPropertyDescriptor(
                name: "type",
                type: .bag,
                description: "Nature or genre of the resource.",
                isRequired: false
            )
        ]
    }
}

// MARK: - Synchronization Support

extension DublinCoreSchema {

    /// Properties that should be synchronized with the Info dictionary.
    public static var synchronizedProperties: [(xmpProperty: String, infoDictKey: String)] {
        [
            ("title", "Title"),
            ("creator", "Author"),
            ("description", "Subject")
        ]
    }

    /// Creates a DublinCoreSchema from Info dictionary values.
    ///
    /// - Parameters:
    ///   - title: The Title from Info dictionary
    ///   - author: The Author from Info dictionary
    ///   - subject: The Subject from Info dictionary
    /// - Returns: A new DublinCoreSchema instance
    public static func fromInfoDictionary(
        title: String? = nil,
        author: String? = nil,
        subject: String? = nil
    ) -> DublinCoreSchema {
        DublinCoreSchema(
            creator: author.map { [$0] },
            descriptionText: subject.map { ["x-default": $0] },
            title: title.map { ["x-default": $0] }
        )
    }

    /// Checks if this schema is synchronized with given Info dictionary values.
    ///
    /// - Parameters:
    ///   - infoTitle: Title from Info dictionary
    ///   - infoAuthor: Author from Info dictionary
    ///   - infoSubject: Subject from Info dictionary
    /// - Returns: List of synchronization issues
    public func checkSynchronization(
        infoTitle: String?,
        infoAuthor: String?,
        infoSubject: String?
    ) -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Check Title synchronization
        let xmpTitle = defaultTitle
        if let xmpT = xmpTitle, let infoT = infoTitle {
            if xmpT != infoT {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "title",
                    message: "dc:title '\(xmpT)' does not match Info dictionary Title '\(infoT)'",
                    ruleId: "6.7.3-1"
                ))
            }
        } else if xmpTitle != nil && infoTitle == nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "title",
                message: "dc:title exists but Info dictionary Title is missing",
                ruleId: "6.7.3-1"
            ))
        } else if xmpTitle == nil && infoTitle != nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "title",
                message: "Info dictionary Title exists but dc:title is missing",
                ruleId: "6.7.3-1"
            ))
        }

        // Check Author/Creator synchronization
        let xmpCreator = creatorsString
        if let xmpC = xmpCreator, let infoA = infoAuthor {
            if xmpC != infoA {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "creator",
                    message: "dc:creator '\(xmpC)' does not match Info dictionary Author '\(infoA)'",
                    ruleId: "6.7.3-1"
                ))
            }
        } else if xmpCreator != nil && infoAuthor == nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "creator",
                message: "dc:creator exists but Info dictionary Author is missing",
                ruleId: "6.7.3-1"
            ))
        } else if xmpCreator == nil && infoAuthor != nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "creator",
                message: "Info dictionary Author exists but dc:creator is missing",
                ruleId: "6.7.3-1"
            ))
        }

        // Check Subject/Description synchronization
        let xmpDesc = defaultDescription
        if let xmpD = xmpDesc, let infoS = infoSubject {
            if xmpD != infoS {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "description",
                    message: "dc:description '\(xmpD)' does not match Info dictionary Subject '\(infoS)'",
                    ruleId: "6.7.3-1"
                ))
            }
        } else if xmpDesc != nil && infoSubject == nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "description",
                message: "dc:description exists but Info dictionary Subject is missing",
                ruleId: "6.7.3-1"
            ))
        } else if xmpDesc == nil && infoSubject != nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "description",
                message: "Info dictionary Subject exists but dc:description is missing",
                ruleId: "6.7.3-1"
            ))
        }

        return issues
    }
}
