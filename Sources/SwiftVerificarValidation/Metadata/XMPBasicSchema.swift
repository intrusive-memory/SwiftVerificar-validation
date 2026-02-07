import Foundation

// MARK: - XMP Basic Schema

/// XMP Basic schema (xmp: namespace) for XMP metadata.
///
/// The XMP Basic schema defines core XMP properties that apply to all resources.
///
/// ## Namespace
/// - URI: `http://ns.adobe.com/xap/1.0/`
/// - Prefix: `xmp`
///
/// ## Properties
/// - `CreateDate` - Date the resource was originally created
/// - `CreatorTool` - Name of the application that created the resource
/// - `Identifier` - Unordered array of text strings identifying the resource
/// - `Label` - User-defined word or phrase for sorting
/// - `MetadataDate` - Date and time the metadata was last modified
/// - `ModifyDate` - Date the resource was last modified
/// - `Nickname` - Short informal name for the resource
/// - `Rating` - User-assigned rating (-1 to 5)
/// - `Thumbnails` - Array of alternate image thumbnails
///
/// ## PDF/A Synchronization
///
/// For PDF/A compliance, the following properties must be synchronized
/// with the Info dictionary:
/// - `xmp:CreateDate` <-> Info dictionary `/CreationDate`
/// - `xmp:ModifyDate` <-> Info dictionary `/ModDate`
/// - `xmp:CreatorTool` <-> Info dictionary `/Creator`
public struct XMPBasicSchema: XMPSchema, Sendable, Equatable {

    // MARK: - Static Properties

    public static let namespaceURI = "http://ns.adobe.com/xap/1.0/"
    public static let preferredPrefix = "xmp"

    // MARK: - Properties

    /// Date the resource was originally created.
    ///
    /// Corresponds to Info dictionary `/CreationDate`.
    public var createDate: Date?

    /// Name of the application that created the resource.
    ///
    /// Corresponds to Info dictionary `/Creator`.
    public var creatorTool: String?

    /// Unordered array of text strings identifying the resource.
    public var identifier: [String]?

    /// User-defined word or phrase for sorting.
    public var label: String?

    /// Date and time the metadata was last modified.
    ///
    /// This should reflect when the XMP metadata packet was last changed.
    public var metadataDate: Date?

    /// Date the resource was last modified.
    ///
    /// Corresponds to Info dictionary `/ModDate`.
    public var modifyDate: Date?

    /// Short informal name for the resource.
    public var nickname: String?

    /// User-assigned rating for the resource.
    ///
    /// Valid values are -1 (rejected), 0 (unrated), 1-5 (rating).
    public var rating: Int?

    /// Custom properties not defined in the standard schema.
    private var customProperties: [String: XMPValue] = [:]

    // MARK: - Initialization

    public init(
        createDate: Date? = nil,
        creatorTool: String? = nil,
        identifier: [String]? = nil,
        label: String? = nil,
        metadataDate: Date? = nil,
        modifyDate: Date? = nil,
        nickname: String? = nil,
        rating: Int? = nil
    ) {
        self.createDate = createDate
        self.creatorTool = creatorTool
        self.identifier = identifier
        self.label = label
        self.metadataDate = metadataDate
        self.modifyDate = modifyDate
        self.nickname = nickname
        self.rating = rating
    }

    // MARK: - XMPSchema Protocol

    public var propertyNames: [String] {
        var names = [
            "CreateDate", "CreatorTool", "Identifier", "Label",
            "MetadataDate", "ModifyDate", "Nickname", "Rating"
        ]
        names.append(contentsOf: customProperties.keys)
        return names
    }

    public func property(named name: String) -> XMPValue? {
        switch name {
        case "CreateDate":
            return createDate.map { .date($0) }
        case "CreatorTool":
            return creatorTool.map { .text($0) }
        case "Identifier":
            return identifier.map { .bag($0.map { .text($0) }) }
        case "Label":
            return label.map { .text($0) }
        case "MetadataDate":
            return metadataDate.map { .date($0) }
        case "ModifyDate":
            return modifyDate.map { .date($0) }
        case "Nickname":
            return nickname.map { .text($0) }
        case "Rating":
            return rating.map { .integer($0) }
        default:
            return customProperties[name]
        }
    }

    public mutating func setProperty(named name: String, to value: XMPValue?) {
        switch name {
        case "CreateDate":
            createDate = value?.dateValue
        case "CreatorTool":
            creatorTool = value?.textValue
        case "Identifier":
            identifier = extractStringArray(from: value)
        case "Label":
            label = value?.textValue
        case "MetadataDate":
            metadataDate = value?.dateValue
        case "ModifyDate":
            modifyDate = value?.dateValue
        case "Nickname":
            nickname = value?.textValue
        case "Rating":
            rating = value?.integerValue
        default:
            customProperties[name] = value
        }
    }

    public func validate() -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Validate rating range
        if let r = rating {
            if r < -1 || r > 5 {
                issues.append(XMPValidationIssue(
                    severity: .warning,
                    namespace: Self.namespaceURI,
                    propertyName: "Rating",
                    message: "xmp:Rating value \(r) is outside valid range (-1 to 5)"
                ))
            }
        }

        // Check date consistency
        if let create = createDate, let modify = modifyDate {
            if modify < create {
                issues.append(XMPValidationIssue(
                    severity: .warning,
                    namespace: Self.namespaceURI,
                    propertyName: "ModifyDate",
                    message: "xmp:ModifyDate is earlier than xmp:CreateDate"
                ))
            }
        }

        // Check metadata date
        if let metadata = metadataDate, let modify = modifyDate {
            if metadata < modify {
                issues.append(XMPValidationIssue(
                    severity: .info,
                    namespace: Self.namespaceURI,
                    propertyName: "MetadataDate",
                    message: "xmp:MetadataDate is earlier than xmp:ModifyDate"
                ))
            }
        }

        return issues
    }

    public func toXML() -> String {
        var elements: [String] = []

        if let date = createDate {
            elements.append("<xmp:CreateDate>\(date.toXMPDateString())</xmp:CreateDate>")
        }
        if let tool = creatorTool {
            elements.append("<xmp:CreatorTool>\(escapeXML(tool))</xmp:CreatorTool>")
        }
        if let ids = identifier, !ids.isEmpty {
            elements.append(formatBag("xmp:Identifier", values: ids))
        }
        if let lbl = label {
            elements.append("<xmp:Label>\(escapeXML(lbl))</xmp:Label>")
        }
        if let date = metadataDate {
            elements.append("<xmp:MetadataDate>\(date.toXMPDateString())</xmp:MetadataDate>")
        }
        if let date = modifyDate {
            elements.append("<xmp:ModifyDate>\(date.toXMPDateString())</xmp:ModifyDate>")
        }
        if let nick = nickname {
            elements.append("<xmp:Nickname>\(escapeXML(nick))</xmp:Nickname>")
        }
        if let r = rating {
            elements.append("<xmp:Rating>\(r)</xmp:Rating>")
        }

        for (name, value) in customProperties.sorted(by: { $0.key < $1.key }) {
            elements.append("<xmp:\(name)>\(escapeXML(value.description))</xmp:\(name)>")
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
}

// MARK: - Property Descriptors

extension XMPBasicSchema {

    /// Returns descriptors for all properties in this schema.
    public static var propertyDescriptors: [XMPPropertyDescriptor] {
        [
            XMPPropertyDescriptor(
                name: "CreateDate",
                type: .date,
                description: "The date and time the resource was originally created.",
                isRequired: false,
                infoDictKey: "CreationDate"
            ),
            XMPPropertyDescriptor(
                name: "CreatorTool",
                type: .text,
                description: "The name of the first known tool used to create the resource.",
                isRequired: false,
                infoDictKey: "Creator"
            ),
            XMPPropertyDescriptor(
                name: "Identifier",
                type: .bag,
                description: "An unordered array of text strings that identify the resource.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "Label",
                type: .text,
                description: "A word or short phrase that identifies a resource as a member of a user-defined collection.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "MetadataDate",
                type: .date,
                description: "The date and time that any metadata for this resource was last changed.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "ModifyDate",
                type: .date,
                description: "The date and time the resource was last modified.",
                isRequired: false,
                infoDictKey: "ModDate"
            ),
            XMPPropertyDescriptor(
                name: "Nickname",
                type: .text,
                description: "A short informal name for the resource.",
                isRequired: false
            ),
            XMPPropertyDescriptor(
                name: "Rating",
                type: .integer,
                description: "A user-assigned rating for this file. Value is -1 (rejected) or 0-5.",
                isRequired: false
            )
        ]
    }
}

// MARK: - Synchronization Support

extension XMPBasicSchema {

    /// Properties that should be synchronized with the Info dictionary.
    public static var synchronizedProperties: [(xmpProperty: String, infoDictKey: String)] {
        [
            ("CreateDate", "CreationDate"),
            ("ModifyDate", "ModDate"),
            ("CreatorTool", "Creator")
        ]
    }

    /// Creates an XMPBasicSchema from Info dictionary values.
    ///
    /// - Parameters:
    ///   - creationDate: The CreationDate from Info dictionary (PDF date string)
    ///   - modDate: The ModDate from Info dictionary (PDF date string)
    ///   - creator: The Creator from Info dictionary
    /// - Returns: A new XMPBasicSchema instance
    public static func fromInfoDictionary(
        creationDate: String? = nil,
        modDate: String? = nil,
        creator: String? = nil
    ) -> XMPBasicSchema {
        XMPBasicSchema(
            createDate: creationDate.flatMap { Date.fromPDFDate($0) },
            creatorTool: creator,
            modifyDate: modDate.flatMap { Date.fromPDFDate($0) }
        )
    }

    /// Checks if this schema is synchronized with given Info dictionary values.
    ///
    /// - Parameters:
    ///   - infoCreationDate: CreationDate from Info dictionary (PDF date string)
    ///   - infoModDate: ModDate from Info dictionary (PDF date string)
    ///   - infoCreator: Creator from Info dictionary
    ///   - toleranceSeconds: Tolerance for date comparison (default: 1 second)
    /// - Returns: List of synchronization issues
    public func checkSynchronization(
        infoCreationDate: String?,
        infoModDate: String?,
        infoCreator: String?,
        toleranceSeconds: TimeInterval = 1.0
    ) -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Check CreateDate synchronization
        if let xmpDate = createDate {
            if let infoDateStr = infoCreationDate {
                if let infoDate = Date.fromPDFDate(infoDateStr) {
                    if abs(xmpDate.timeIntervalSince(infoDate)) > toleranceSeconds {
                        issues.append(XMPValidationIssue(
                            severity: .error,
                            namespace: Self.namespaceURI,
                            propertyName: "CreateDate",
                            message: "xmp:CreateDate '\(xmpDate.toXMPDateString())' does not match Info dictionary CreationDate '\(infoDateStr)'",
                            ruleId: "6.7.3-1"
                        ))
                    }
                } else {
                    issues.append(XMPValidationIssue(
                        severity: .error,
                        namespace: Self.namespaceURI,
                        propertyName: "CreateDate",
                        message: "Info dictionary CreationDate '\(infoDateStr)' has invalid format",
                        ruleId: "6.7.3-1"
                    ))
                }
            } else {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "CreateDate",
                    message: "xmp:CreateDate exists but Info dictionary CreationDate is missing",
                    ruleId: "6.7.3-1"
                ))
            }
        } else if infoCreationDate != nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "CreateDate",
                message: "Info dictionary CreationDate exists but xmp:CreateDate is missing",
                ruleId: "6.7.3-1"
            ))
        }

        // Check ModifyDate synchronization
        if let xmpDate = modifyDate {
            if let infoDateStr = infoModDate {
                if let infoDate = Date.fromPDFDate(infoDateStr) {
                    if abs(xmpDate.timeIntervalSince(infoDate)) > toleranceSeconds {
                        issues.append(XMPValidationIssue(
                            severity: .error,
                            namespace: Self.namespaceURI,
                            propertyName: "ModifyDate",
                            message: "xmp:ModifyDate '\(xmpDate.toXMPDateString())' does not match Info dictionary ModDate '\(infoDateStr)'",
                            ruleId: "6.7.3-1"
                        ))
                    }
                } else {
                    issues.append(XMPValidationIssue(
                        severity: .error,
                        namespace: Self.namespaceURI,
                        propertyName: "ModifyDate",
                        message: "Info dictionary ModDate '\(infoDateStr)' has invalid format",
                        ruleId: "6.7.3-1"
                    ))
                }
            } else {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "ModifyDate",
                    message: "xmp:ModifyDate exists but Info dictionary ModDate is missing",
                    ruleId: "6.7.3-1"
                ))
            }
        } else if infoModDate != nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "ModifyDate",
                message: "Info dictionary ModDate exists but xmp:ModifyDate is missing",
                ruleId: "6.7.3-1"
            ))
        }

        // Check CreatorTool synchronization
        if let xmpTool = creatorTool, let infoC = infoCreator {
            if xmpTool != infoC {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "CreatorTool",
                    message: "xmp:CreatorTool '\(xmpTool)' does not match Info dictionary Creator '\(infoC)'",
                    ruleId: "6.7.3-1"
                ))
            }
        } else if creatorTool != nil && infoCreator == nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "CreatorTool",
                message: "xmp:CreatorTool exists but Info dictionary Creator is missing",
                ruleId: "6.7.3-1"
            ))
        } else if creatorTool == nil && infoCreator != nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "CreatorTool",
                message: "Info dictionary Creator exists but xmp:CreatorTool is missing",
                ruleId: "6.7.3-1"
            ))
        }

        return issues
    }
}

// MARK: - Rating Helpers

extension XMPBasicSchema {

    /// Rating interpretations
    public enum RatingInterpretation: Sendable {
        case rejected
        case unrated
        case rated(Int)

        public init(_ value: Int) {
            switch value {
            case -1: self = .rejected
            case 0: self = .unrated
            case 1...5: self = .rated(value)
            default: self = .unrated
            }
        }

        public var numericValue: Int {
            switch self {
            case .rejected: return -1
            case .unrated: return 0
            case .rated(let v): return v
            }
        }
    }

    /// Returns the rating interpretation.
    public var ratingInterpretation: RatingInterpretation? {
        guard let r = rating else { return nil }
        return RatingInterpretation(r)
    }

    /// Sets the rating from an interpretation.
    public mutating func setRating(_ interpretation: RatingInterpretation) {
        rating = interpretation.numericValue
    }
}
