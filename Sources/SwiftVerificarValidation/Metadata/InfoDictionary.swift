import Foundation

// MARK: - PDF Info Dictionary

/// Represents the PDF document information dictionary.
///
/// The Info dictionary contains metadata about the PDF document. It was the
/// original metadata mechanism in PDF and is still used alongside XMP metadata.
///
/// ## Standard Keys
///
/// PDF 1.7 defines these standard keys:
/// - `Title` - The document's title
/// - `Author` - The person who created the document
/// - `Subject` - The subject of the document
/// - `Keywords` - Keywords associated with the document
/// - `Creator` - The application that created the original document
/// - `Producer` - The application that converted the document to PDF
/// - `CreationDate` - The date and time the document was created
/// - `ModDate` - The date and time the document was last modified
/// - `Trapped` - Whether the document has been trapped
///
/// ## PDF/A Requirements
///
/// For PDF/A compliance:
/// - All string values must be properly encoded (UTF-8 or UTF-16)
/// - Dates must use the PDF date format: D:YYYYMMDDHHmmSSOHH'mm'
/// - Values must be synchronized with XMP metadata
/// - Custom keys require XMP extension schema declarations
public struct InfoDictionary: Sendable, Equatable {

    // MARK: - Standard Properties

    /// The document's title.
    ///
    /// Synchronized with `dc:title` in XMP.
    public var title: String?

    /// The person who created the document content.
    ///
    /// Synchronized with `dc:creator` in XMP.
    public var author: String?

    /// The subject of the document.
    ///
    /// Synchronized with `dc:description` in XMP.
    public var subject: String?

    /// Keywords associated with the document.
    ///
    /// Synchronized with `pdf:Keywords` in XMP.
    public var keywords: String?

    /// The application that created the original document.
    ///
    /// If the document was converted from another format, this is the
    /// application that created the original (e.g., "Microsoft Word").
    /// Synchronized with `xmp:CreatorTool` in XMP.
    public var creator: String?

    /// The application that converted the document to PDF.
    ///
    /// This is the PDF producer application.
    /// Synchronized with `pdf:Producer` in XMP.
    public var producer: String?

    /// The date and time the document was created.
    ///
    /// Stored as PDF date string (D:YYYYMMDDHHmmSSOHH'mm').
    /// Synchronized with `xmp:CreateDate` in XMP.
    public var creationDate: String?

    /// The date and time the document was last modified.
    ///
    /// Stored as PDF date string (D:YYYYMMDDHHmmSSOHH'mm').
    /// Synchronized with `xmp:ModifyDate` in XMP.
    public var modDate: String?

    /// Whether the document has been trapped.
    ///
    /// PDF name value: /True, /False, or /Unknown.
    /// Synchronized with `pdf:Trapped` in XMP.
    public var trapped: TrappedStatus?

    /// Custom properties not defined in the standard.
    ///
    /// For PDF/A compliance, custom properties require XMP extension schema.
    public var customProperties: [String: String]

    // MARK: - Initialization

    public init(
        title: String? = nil,
        author: String? = nil,
        subject: String? = nil,
        keywords: String? = nil,
        creator: String? = nil,
        producer: String? = nil,
        creationDate: String? = nil,
        modDate: String? = nil,
        trapped: TrappedStatus? = nil,
        customProperties: [String: String] = [:]
    ) {
        self.title = title
        self.author = author
        self.subject = subject
        self.keywords = keywords
        self.creator = creator
        self.producer = producer
        self.creationDate = creationDate
        self.modDate = modDate
        self.trapped = trapped
        self.customProperties = customProperties
    }

    // MARK: - Date Accessors

    /// Returns the creation date as a Date object.
    public var creationDateValue: Date? {
        guard let str = creationDate else { return nil }
        return Date.fromPDFDate(str)
    }

    /// Returns the modification date as a Date object.
    public var modDateValue: Date? {
        guard let str = modDate else { return nil }
        return Date.fromPDFDate(str)
    }

    /// Sets the creation date from a Date object.
    public mutating func setCreationDate(_ date: Date, timeZone: TimeZone = .current) {
        creationDate = date.toPDFDateString(timeZone: timeZone)
    }

    /// Sets the modification date from a Date object.
    public mutating func setModDate(_ date: Date, timeZone: TimeZone = .current) {
        modDate = date.toPDFDateString(timeZone: timeZone)
    }

    // MARK: - Property Access

    /// All standard property keys.
    public static let standardKeys: Set<String> = [
        "Title", "Author", "Subject", "Keywords",
        "Creator", "Producer", "CreationDate", "ModDate", "Trapped"
    ]

    /// Returns the value for a given key.
    ///
    /// - Parameter key: The property key (e.g., "Title", "Author")
    /// - Returns: The string value, or nil if not set
    public func value(forKey key: String) -> String? {
        switch key {
        case "Title": return title
        case "Author": return author
        case "Subject": return subject
        case "Keywords": return keywords
        case "Creator": return creator
        case "Producer": return producer
        case "CreationDate": return creationDate
        case "ModDate": return modDate
        case "Trapped": return trapped?.rawValue
        default: return customProperties[key]
        }
    }

    /// Sets the value for a given key.
    ///
    /// - Parameters:
    ///   - value: The string value to set, or nil to remove
    ///   - key: The property key
    public mutating func setValue(_ value: String?, forKey key: String) {
        switch key {
        case "Title": title = value
        case "Author": author = value
        case "Subject": subject = value
        case "Keywords": keywords = value
        case "Creator": creator = value
        case "Producer": producer = value
        case "CreationDate": creationDate = value
        case "ModDate": modDate = value
        case "Trapped":
            if let v = value {
                trapped = TrappedStatus(rawValue: v)
            } else {
                trapped = nil
            }
        default:
            if let v = value {
                customProperties[key] = v
            } else {
                customProperties.removeValue(forKey: key)
            }
        }
    }

    /// Returns all keys that have values set.
    public var allKeys: [String] {
        var keys: [String] = []
        if title != nil { keys.append("Title") }
        if author != nil { keys.append("Author") }
        if subject != nil { keys.append("Subject") }
        if keywords != nil { keys.append("Keywords") }
        if creator != nil { keys.append("Creator") }
        if producer != nil { keys.append("Producer") }
        if creationDate != nil { keys.append("CreationDate") }
        if modDate != nil { keys.append("ModDate") }
        if trapped != nil { keys.append("Trapped") }
        keys.append(contentsOf: customProperties.keys.sorted())
        return keys
    }

    /// Returns whether this dictionary is empty (no properties set).
    public var isEmpty: Bool {
        title == nil && author == nil && subject == nil &&
        keywords == nil && creator == nil && producer == nil &&
        creationDate == nil && modDate == nil && trapped == nil &&
        customProperties.isEmpty
    }

    // MARK: - Validation

    /// Validates this Info dictionary for PDF/A compliance.
    ///
    /// - Returns: Array of validation issues found
    public func validate() -> [InfoDictionaryValidationIssue] {
        var issues: [InfoDictionaryValidationIssue] = []

        // Validate date formats
        if let dateStr = creationDate {
            if Date.fromPDFDate(dateStr) == nil {
                issues.append(InfoDictionaryValidationIssue(
                    severity: .error,
                    key: "CreationDate",
                    message: "Invalid PDF date format: '\(dateStr)'"
                ))
            }
        }

        if let dateStr = modDate {
            if Date.fromPDFDate(dateStr) == nil {
                issues.append(InfoDictionaryValidationIssue(
                    severity: .error,
                    key: "ModDate",
                    message: "Invalid PDF date format: '\(dateStr)'"
                ))
            }
        }

        // Check date consistency
        if let create = creationDateValue, let mod = modDateValue {
            if mod < create {
                issues.append(InfoDictionaryValidationIssue(
                    severity: .warning,
                    key: "ModDate",
                    message: "ModDate is earlier than CreationDate"
                ))
            }
        }

        // Check for custom properties (may need extension schema for PDF/A)
        if !customProperties.isEmpty {
            issues.append(InfoDictionaryValidationIssue(
                severity: .info,
                key: nil,
                message: "Custom properties found. PDF/A requires XMP extension schema for custom Info dictionary entries."
            ))
        }

        return issues
    }
}

// MARK: - TrappedStatus Extensions

extension TrappedStatus {
    /// Creates a TrappedStatus from a TrappedValue (from XMP).
    public init(from trappedValue: TrappedValue) {
        switch trappedValue {
        case .true: self = .trapped
        case .false: self = .notTrapped
        case .unknown: self = .unknown
        }
    }

    /// Converts to TrappedValue (for XMP).
    public var trappedValue: TrappedValue {
        switch self {
        case .trapped: return .true
        case .notTrapped: return .false
        case .unknown: return .unknown
        }
    }

    /// The raw string value for PDF Info dictionary.
    public var pdfValue: String {
        rawValue
    }
}

// MARK: - Info Dictionary Validation Issue

/// Represents a validation issue found in the Info dictionary.
public struct InfoDictionaryValidationIssue: Sendable, Equatable, Identifiable {
    public let id: UUID

    /// The severity of the issue.
    public let severity: Severity

    /// The dictionary key where the issue was found, if applicable.
    public let key: String?

    /// A description of the issue.
    public let message: String

    public init(
        id: UUID = UUID(),
        severity: Severity,
        key: String?,
        message: String
    ) {
        self.id = id
        self.severity = severity
        self.key = key
        self.message = message
    }

    /// Severity levels for Info dictionary validation issues.
    public enum Severity: String, Sendable, Codable {
        case error
        case warning
        case info
    }
}

// MARK: - COS Dictionary Conversion

extension InfoDictionary {

    /// Creates an InfoDictionary from a COS dictionary value.
    ///
    /// - Parameter cosDict: The COS dictionary to parse
    /// - Returns: A new InfoDictionary instance
    public static func fromCOSDictionary(_ cosDict: [ASAtom: COSValue]) -> InfoDictionary {
        var info = InfoDictionary()

        for (key, value) in cosDict {
            let keyStr = key.stringValue
            if let text = value.textValue {
                info.setValue(text, forKey: keyStr)
            } else if let name = value.nameValue {
                // Handle Trapped which is a name value
                info.setValue(name.stringValue, forKey: keyStr)
            }
        }

        return info
    }

    /// Converts this InfoDictionary to a COS dictionary value.
    ///
    /// - Returns: A COS dictionary representing this Info dictionary
    public func toCOSDictionary() -> [ASAtom: COSValue] {
        var dict: [ASAtom: COSValue] = [:]

        if let title = title {
            dict[ASAtom("Title")] = .string(COSString(string: title))
        }
        if let author = author {
            dict[ASAtom("Author")] = .string(COSString(string: author))
        }
        if let subject = subject {
            dict[ASAtom("Subject")] = .string(COSString(string: subject))
        }
        if let keywords = keywords {
            dict[ASAtom("Keywords")] = .string(COSString(string: keywords))
        }
        if let creator = creator {
            dict[ASAtom("Creator")] = .string(COSString(string: creator))
        }
        if let producer = producer {
            dict[ASAtom("Producer")] = .string(COSString(string: producer))
        }
        if let creationDate = creationDate {
            dict[ASAtom("CreationDate")] = .string(COSString(string: creationDate))
        }
        if let modDate = modDate {
            dict[ASAtom("ModDate")] = .string(COSString(string: modDate))
        }
        if let trapped = trapped {
            dict[ASAtom("Trapped")] = .name(ASAtom(trapped.rawValue))
        }

        for (key, value) in customProperties {
            dict[ASAtom(key)] = .string(COSString(string: value))
        }

        return dict
    }
}

// MARK: - XMP Synchronization

extension InfoDictionary {

    /// Mapping between Info dictionary keys and XMP properties.
    public static let xmpMapping: [(infoKey: String, namespace: String, property: String)] = [
        ("Title", DublinCoreSchema.namespaceURI, "title"),
        ("Author", DublinCoreSchema.namespaceURI, "creator"),
        ("Subject", DublinCoreSchema.namespaceURI, "description"),
        ("Keywords", AdobePDFSchema.namespaceURI, "Keywords"),
        ("Creator", XMPBasicSchema.namespaceURI, "CreatorTool"),
        ("Producer", AdobePDFSchema.namespaceURI, "Producer"),
        ("CreationDate", XMPBasicSchema.namespaceURI, "CreateDate"),
        ("ModDate", XMPBasicSchema.namespaceURI, "ModifyDate"),
        ("Trapped", AdobePDFSchema.namespaceURI, "Trapped")
    ]

    /// Checks if this Info dictionary is synchronized with XMP metadata.
    ///
    /// - Parameter xmp: The XMP metadata model to check against
    /// - Returns: Array of synchronization issues
    public func checkSynchronization(with xmp: XMPMetadataModel) -> [MetadataSynchronizationIssue] {
        var issues: [MetadataSynchronizationIssue] = []

        // Dublin Core synchronization
        issues.append(contentsOf: xmp.dublinCore.checkSynchronization(
            infoTitle: title,
            infoAuthor: author,
            infoSubject: subject
        ).map { issue in
            MetadataSynchronizationIssue(
                infoKey: Self.keyForXMPProperty(issue.propertyName ?? ""),
                xmpNamespace: issue.namespace,
                xmpProperty: issue.propertyName ?? "",
                message: issue.message,
                severity: mapSeverity(issue.severity)
            )
        })

        // Adobe PDF schema synchronization
        issues.append(contentsOf: xmp.adobePDF.checkSynchronization(
            infoKeywords: keywords,
            infoProducer: producer
        ).map { issue in
            MetadataSynchronizationIssue(
                infoKey: Self.keyForXMPProperty(issue.propertyName ?? ""),
                xmpNamespace: issue.namespace,
                xmpProperty: issue.propertyName ?? "",
                message: issue.message,
                severity: mapSeverity(issue.severity)
            )
        })

        // XMP Basic schema synchronization
        issues.append(contentsOf: xmp.xmpBasic.checkSynchronization(
            infoCreationDate: creationDate,
            infoModDate: modDate,
            infoCreator: creator
        ).map { issue in
            MetadataSynchronizationIssue(
                infoKey: Self.keyForXMPProperty(issue.propertyName ?? ""),
                xmpNamespace: issue.namespace,
                xmpProperty: issue.propertyName ?? "",
                message: issue.message,
                severity: mapSeverity(issue.severity)
            )
        })

        return issues
    }

    /// Returns the Info dictionary key for an XMP property name.
    private static func keyForXMPProperty(_ property: String) -> String {
        switch property {
        case "title": return "Title"
        case "creator": return "Author"
        case "description": return "Subject"
        case "Keywords": return "Keywords"
        case "CreatorTool": return "Creator"
        case "Producer": return "Producer"
        case "CreateDate": return "CreationDate"
        case "ModifyDate": return "ModDate"
        case "Trapped": return "Trapped"
        default: return property
        }
    }

    private func mapSeverity(_ severity: XMPValidationIssue.Severity) -> MetadataSynchronizationIssue.Severity {
        switch severity {
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        }
    }
}

// MARK: - Metadata Synchronization Issue

/// Represents a synchronization issue between Info dictionary and XMP metadata.
public struct MetadataSynchronizationIssue: Sendable, Equatable, Identifiable {
    public let id: UUID

    /// The Info dictionary key involved.
    public let infoKey: String

    /// The XMP namespace involved.
    public let xmpNamespace: String

    /// The XMP property involved.
    public let xmpProperty: String

    /// A description of the synchronization issue.
    public let message: String

    /// The severity of the issue.
    public let severity: Severity

    public init(
        id: UUID = UUID(),
        infoKey: String,
        xmpNamespace: String,
        xmpProperty: String,
        message: String,
        severity: Severity = .error
    ) {
        self.id = id
        self.infoKey = infoKey
        self.xmpNamespace = xmpNamespace
        self.xmpProperty = xmpProperty
        self.message = message
        self.severity = severity
    }

    public enum Severity: String, Sendable, Codable {
        case error
        case warning
        case info
    }
}
