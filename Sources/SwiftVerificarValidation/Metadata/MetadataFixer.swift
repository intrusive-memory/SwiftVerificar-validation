import Foundation

// MARK: - Metadata Fixer

/// Main entry point for fixing PDF metadata for PDF/A compliance.
///
/// The MetadataFixer provides functionality to:
/// - Synchronize Info dictionary with XMP metadata
/// - Fix missing required XMP fields
/// - Convert between PDF and XMP date formats
/// - Validate metadata consistency
/// - Generate compliant XMP packets
///
/// ## PDF/A Metadata Requirements
///
/// PDF/A requires:
/// 1. XMP metadata must be present in a metadata stream
/// 2. The PDF/A identification schema must declare conformance
/// 3. Info dictionary entries must be synchronized with XMP
/// 4. Custom properties require extension schema declarations
///
/// ## Usage
///
/// ```swift
/// let fixer = MetadataFixer()
///
/// // Analyze current metadata
/// let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)
///
/// // Fix metadata issues
/// let (fixedInfo, fixedXMP) = fixer.fix(
///     infoDictionary: info,
///     xmpMetadata: xmp,
///     options: .synchronizeToXMP
/// )
/// ```
public struct MetadataFixer: Sendable {

    // MARK: - Configuration

    /// Configuration options for metadata fixing.
    public let configuration: MetadataFixerConfiguration

    // MARK: - Initialization

    public init(configuration: MetadataFixerConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Analysis

    /// Analyzes metadata for PDF/A compliance issues.
    ///
    /// - Parameters:
    ///   - infoDictionary: The PDF Info dictionary
    ///   - xmpMetadata: The XMP metadata model
    ///   - pdfaPart: The target PDF/A part (optional, for conformance checking)
    ///   - pdfaLevel: The target PDF/A conformance level (optional)
    /// - Returns: A report of metadata issues found
    public func analyze(
        infoDictionary: InfoDictionary,
        xmpMetadata: XMPMetadataModel,
        pdfaPart: Int? = nil,
        pdfaLevel: String? = nil
    ) -> MetadataAnalysisReport {
        var issues: [MetadataIssue] = []

        // 1. Validate Info dictionary
        let infoIssues = infoDictionary.validate()
        for issue in infoIssues {
            issues.append(MetadataIssue(
                category: .infoDictionary,
                severity: mapSeverity(issue.severity),
                key: issue.key,
                message: issue.message,
                fixable: issue.severity != .error
            ))
        }

        // 2. Validate XMP metadata
        let xmpIssues = xmpMetadata.validate()
        for issue in xmpIssues {
            issues.append(MetadataIssue(
                category: .xmpMetadata,
                severity: mapSeverity(issue.severity),
                key: issue.propertyName,
                namespace: issue.namespace,
                message: issue.message,
                ruleId: issue.ruleId,
                fixable: issue.severity != .error
            ))
        }

        // 3. Check synchronization
        let syncIssues = infoDictionary.checkSynchronization(with: xmpMetadata)
        for issue in syncIssues {
            issues.append(MetadataIssue(
                category: .synchronization,
                severity: mapSeverity(issue.severity),
                key: issue.infoKey,
                namespace: issue.xmpNamespace,
                message: issue.message,
                fixable: true
            ))
        }

        // 4. Check PDF/A identification
        if pdfaPart != nil || pdfaLevel != nil {
            let pdfaIssues = xmpMetadata.validatePDFAIdentification(
                expectedPart: pdfaPart,
                expectedLevel: pdfaLevel
            )
            for issue in pdfaIssues {
                issues.append(MetadataIssue(
                    category: .pdfaIdentification,
                    severity: mapSeverity(issue.severity),
                    key: issue.propertyName,
                    namespace: issue.namespace,
                    message: issue.message,
                    ruleId: issue.ruleId,
                    fixable: issue.severity != .error
                ))
            }
        }

        // 5. Check for missing recommended metadata
        issues.append(contentsOf: checkRecommendedMetadata(
            infoDictionary: infoDictionary,
            xmpMetadata: xmpMetadata
        ))

        return MetadataAnalysisReport(
            issues: issues,
            infoDictionary: infoDictionary,
            xmpMetadata: xmpMetadata,
            isCompliant: issues.filter { $0.severity == .error }.isEmpty
        )
    }

    /// Checks for missing recommended metadata.
    private func checkRecommendedMetadata(
        infoDictionary: InfoDictionary,
        xmpMetadata: XMPMetadataModel
    ) -> [MetadataIssue] {
        var issues: [MetadataIssue] = []

        // Check for title
        if infoDictionary.title == nil && xmpMetadata.title == nil {
            issues.append(MetadataIssue(
                category: .missing,
                severity: .warning,
                key: "Title",
                message: "Document title is recommended but missing",
                fixable: false
            ))
        }

        // Check for creator/author
        if infoDictionary.author == nil && xmpMetadata.creator == nil {
            issues.append(MetadataIssue(
                category: .missing,
                severity: .warning,
                key: "Author",
                message: "Document author is recommended but missing",
                fixable: false
            ))
        }

        // Check for dates
        if infoDictionary.creationDate == nil && xmpMetadata.createDate == nil {
            issues.append(MetadataIssue(
                category: .missing,
                severity: .info,
                key: "CreationDate",
                message: "Creation date is recommended but missing",
                fixable: true
            ))
        }

        return issues
    }

    private func mapSeverity(_ severity: InfoDictionaryValidationIssue.Severity) -> MetadataIssue.Severity {
        switch severity {
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        }
    }

    private func mapSeverity(_ severity: XMPValidationIssue.Severity) -> MetadataIssue.Severity {
        switch severity {
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        }
    }

    private func mapSeverity(_ severity: MetadataSynchronizationIssue.Severity) -> MetadataIssue.Severity {
        switch severity {
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        }
    }

    // MARK: - Fixing

    /// Fixes metadata issues for PDF/A compliance.
    ///
    /// - Parameters:
    ///   - infoDictionary: The PDF Info dictionary
    ///   - xmpMetadata: The XMP metadata model
    ///   - options: The fixing options (how to resolve conflicts)
    /// - Returns: A tuple of the fixed Info dictionary and XMP metadata
    public func fix(
        infoDictionary: InfoDictionary,
        xmpMetadata: XMPMetadataModel,
        options: MetadataFixOptions = .synchronizeToXMP
    ) -> (InfoDictionary, XMPMetadataModel) {
        var fixedInfo = infoDictionary
        var fixedXMP = xmpMetadata

        switch options {
        case .synchronizeToXMP:
            // Copy Info dictionary values to XMP (XMP takes precedence for new values)
            fixedXMP = synchronizeInfoToXMP(info: fixedInfo, xmp: fixedXMP)

        case .synchronizeToInfo:
            // Copy XMP values to Info dictionary
            fixedInfo = synchronizeXMPToInfo(info: fixedInfo, xmp: fixedXMP)

        case .preferInfo:
            // Use Info dictionary values when both exist
            fixedXMP = synchronizePreferInfo(info: fixedInfo, xmp: fixedXMP)

        case .preferXMP:
            // Use XMP values when both exist
            fixedInfo = synchronizePreferXMP(info: fixedInfo, xmp: fixedXMP)

        case .bidirectional:
            // Synchronize both directions, preferring non-nil values
            (fixedInfo, fixedXMP) = synchronizeBidirectional(info: fixedInfo, xmp: fixedXMP)
        }

        // Fix date formats if needed
        if configuration.normalizedDates {
            fixedInfo = normalizeDates(in: fixedInfo)
        }

        // Add metadata date if needed
        if configuration.updateMetadataDate {
            fixedXMP.xmpBasic.metadataDate = Date()
        }

        return (fixedInfo, fixedXMP)
    }

    /// Synchronizes Info dictionary values to XMP.
    private func synchronizeInfoToXMP(info: InfoDictionary, xmp: XMPMetadataModel) -> XMPMetadataModel {
        var fixedXMP = xmp

        // Title -> dc:title
        if let title = info.title {
            if fixedXMP.dublinCore.title == nil {
                fixedXMP.dublinCore.title = ["x-default": title]
            }
        }

        // Author -> dc:creator
        if let author = info.author {
            if fixedXMP.dublinCore.creator == nil {
                fixedXMP.dublinCore.creator = [author]
            }
        }

        // Subject -> dc:description
        if let subject = info.subject {
            if fixedXMP.dublinCore.descriptionText == nil {
                fixedXMP.dublinCore.descriptionText = ["x-default": subject]
            }
        }

        // Keywords -> pdf:Keywords
        if let keywords = info.keywords {
            if fixedXMP.adobePDF.keywords == nil {
                fixedXMP.adobePDF.keywords = keywords
            }
        }

        // Creator -> xmp:CreatorTool
        if let creator = info.creator {
            if fixedXMP.xmpBasic.creatorTool == nil {
                fixedXMP.xmpBasic.creatorTool = creator
            }
        }

        // Producer -> pdf:Producer
        if let producer = info.producer {
            if fixedXMP.adobePDF.producer == nil {
                fixedXMP.adobePDF.producer = producer
            }
        }

        // CreationDate -> xmp:CreateDate
        if let dateStr = info.creationDate, let date = Date.fromPDFDate(dateStr) {
            if fixedXMP.xmpBasic.createDate == nil {
                fixedXMP.xmpBasic.createDate = date
            }
        }

        // ModDate -> xmp:ModifyDate
        if let dateStr = info.modDate, let date = Date.fromPDFDate(dateStr) {
            if fixedXMP.xmpBasic.modifyDate == nil {
                fixedXMP.xmpBasic.modifyDate = date
            }
        }

        // Trapped -> pdf:Trapped
        if let trapped = info.trapped {
            if fixedXMP.adobePDF.trapped == nil {
                fixedXMP.adobePDF.trapped = trapped.trappedValue
            }
        }

        return fixedXMP
    }

    /// Synchronizes XMP values to Info dictionary.
    private func synchronizeXMPToInfo(info: InfoDictionary, xmp: XMPMetadataModel) -> InfoDictionary {
        var fixedInfo = info

        // dc:title -> Title
        if let title = xmp.dublinCore.defaultTitle {
            if fixedInfo.title == nil {
                fixedInfo.title = title
            }
        }

        // dc:creator -> Author
        if let creator = xmp.dublinCore.creatorsString {
            if fixedInfo.author == nil {
                fixedInfo.author = creator
            }
        }

        // dc:description -> Subject
        if let description = xmp.dublinCore.defaultDescription {
            if fixedInfo.subject == nil {
                fixedInfo.subject = description
            }
        }

        // pdf:Keywords -> Keywords
        if let keywords = xmp.adobePDF.keywords {
            if fixedInfo.keywords == nil {
                fixedInfo.keywords = keywords
            }
        }

        // xmp:CreatorTool -> Creator
        if let creatorTool = xmp.xmpBasic.creatorTool {
            if fixedInfo.creator == nil {
                fixedInfo.creator = creatorTool
            }
        }

        // pdf:Producer -> Producer
        if let producer = xmp.adobePDF.producer {
            if fixedInfo.producer == nil {
                fixedInfo.producer = producer
            }
        }

        // xmp:CreateDate -> CreationDate
        if let createDate = xmp.xmpBasic.createDate {
            if fixedInfo.creationDate == nil {
                fixedInfo.creationDate = createDate.toPDFDateString()
            }
        }

        // xmp:ModifyDate -> ModDate
        if let modifyDate = xmp.xmpBasic.modifyDate {
            if fixedInfo.modDate == nil {
                fixedInfo.modDate = modifyDate.toPDFDateString()
            }
        }

        // pdf:Trapped -> Trapped
        if let trapped = xmp.adobePDF.trapped {
            if fixedInfo.trapped == nil {
                fixedInfo.trapped = TrappedStatus(from: trapped)
            }
        }

        return fixedInfo
    }

    /// Synchronizes preferring Info dictionary values.
    private func synchronizePreferInfo(info: InfoDictionary, xmp: XMPMetadataModel) -> XMPMetadataModel {
        var fixedXMP = xmp

        // Title
        if let title = info.title {
            fixedXMP.dublinCore.title = ["x-default": title]
        }

        // Author
        if let author = info.author {
            fixedXMP.dublinCore.creator = [author]
        }

        // Subject
        if let subject = info.subject {
            fixedXMP.dublinCore.descriptionText = ["x-default": subject]
        }

        // Keywords
        if let keywords = info.keywords {
            fixedXMP.adobePDF.keywords = keywords
        }

        // Creator
        if let creator = info.creator {
            fixedXMP.xmpBasic.creatorTool = creator
        }

        // Producer
        if let producer = info.producer {
            fixedXMP.adobePDF.producer = producer
        }

        // CreationDate
        if let dateStr = info.creationDate, let date = Date.fromPDFDate(dateStr) {
            fixedXMP.xmpBasic.createDate = date
        }

        // ModDate
        if let dateStr = info.modDate, let date = Date.fromPDFDate(dateStr) {
            fixedXMP.xmpBasic.modifyDate = date
        }

        // Trapped
        if let trapped = info.trapped {
            fixedXMP.adobePDF.trapped = trapped.trappedValue
        }

        return fixedXMP
    }

    /// Synchronizes preferring XMP values.
    private func synchronizePreferXMP(info: InfoDictionary, xmp: XMPMetadataModel) -> InfoDictionary {
        var fixedInfo = info

        // Title
        if let title = xmp.dublinCore.defaultTitle {
            fixedInfo.title = title
        }

        // Author
        if let creator = xmp.dublinCore.creatorsString {
            fixedInfo.author = creator
        }

        // Subject
        if let description = xmp.dublinCore.defaultDescription {
            fixedInfo.subject = description
        }

        // Keywords
        if let keywords = xmp.adobePDF.keywords {
            fixedInfo.keywords = keywords
        }

        // Creator
        if let creatorTool = xmp.xmpBasic.creatorTool {
            fixedInfo.creator = creatorTool
        }

        // Producer
        if let producer = xmp.adobePDF.producer {
            fixedInfo.producer = producer
        }

        // CreationDate
        if let createDate = xmp.xmpBasic.createDate {
            fixedInfo.creationDate = createDate.toPDFDateString()
        }

        // ModDate
        if let modifyDate = xmp.xmpBasic.modifyDate {
            fixedInfo.modDate = modifyDate.toPDFDateString()
        }

        // Trapped
        if let trapped = xmp.adobePDF.trapped {
            fixedInfo.trapped = TrappedStatus(from: trapped)
        }

        return fixedInfo
    }

    /// Synchronizes bidirectionally.
    private func synchronizeBidirectional(
        info: InfoDictionary,
        xmp: XMPMetadataModel
    ) -> (InfoDictionary, XMPMetadataModel) {
        var fixedInfo = info
        var fixedXMP = xmp

        // Title
        if let title = info.title {
            fixedXMP.dublinCore.title = ["x-default": title]
        } else if let title = xmp.dublinCore.defaultTitle {
            fixedInfo.title = title
        }

        // Author
        if let author = info.author {
            fixedXMP.dublinCore.creator = [author]
        } else if let creator = xmp.dublinCore.creatorsString {
            fixedInfo.author = creator
        }

        // Subject
        if let subject = info.subject {
            fixedXMP.dublinCore.descriptionText = ["x-default": subject]
        } else if let description = xmp.dublinCore.defaultDescription {
            fixedInfo.subject = description
        }

        // Keywords
        if let keywords = info.keywords {
            fixedXMP.adobePDF.keywords = keywords
        } else if let keywords = xmp.adobePDF.keywords {
            fixedInfo.keywords = keywords
        }

        // Creator
        if let creator = info.creator {
            fixedXMP.xmpBasic.creatorTool = creator
        } else if let creatorTool = xmp.xmpBasic.creatorTool {
            fixedInfo.creator = creatorTool
        }

        // Producer
        if let producer = info.producer {
            fixedXMP.adobePDF.producer = producer
        } else if let producer = xmp.adobePDF.producer {
            fixedInfo.producer = producer
        }

        // CreationDate
        if let dateStr = info.creationDate, let date = Date.fromPDFDate(dateStr) {
            fixedXMP.xmpBasic.createDate = date
        } else if let createDate = xmp.xmpBasic.createDate {
            fixedInfo.creationDate = createDate.toPDFDateString()
        }

        // ModDate
        if let dateStr = info.modDate, let date = Date.fromPDFDate(dateStr) {
            fixedXMP.xmpBasic.modifyDate = date
        } else if let modifyDate = xmp.xmpBasic.modifyDate {
            fixedInfo.modDate = modifyDate.toPDFDateString()
        }

        // Trapped
        if let trapped = info.trapped {
            fixedXMP.adobePDF.trapped = trapped.trappedValue
        } else if let trapped = xmp.adobePDF.trapped {
            fixedInfo.trapped = TrappedStatus(from: trapped)
        }

        return (fixedInfo, fixedXMP)
    }

    /// Normalizes dates in the Info dictionary.
    private func normalizeDates(in info: InfoDictionary) -> InfoDictionary {
        var fixedInfo = info

        // Normalize CreationDate
        if let dateStr = info.creationDate {
            if let date = Date.fromPDFDate(dateStr) {
                fixedInfo.creationDate = date.toPDFDateString(timeZone: TimeZone(secondsFromGMT: 0)!)
            }
        }

        // Normalize ModDate
        if let dateStr = info.modDate {
            if let date = Date.fromPDFDate(dateStr) {
                fixedInfo.modDate = date.toPDFDateString(timeZone: TimeZone(secondsFromGMT: 0)!)
            }
        }

        return fixedInfo
    }

    // MARK: - XMP Packet Generation

    /// Generates a compliant XMP packet.
    ///
    /// - Parameters:
    ///   - metadata: The XMP metadata model
    ///   - includeWrapper: Whether to include the xpacket wrapper
    /// - Returns: The XMP XML string
    public func generateXMPPacket(
        _ metadata: XMPMetadataModel,
        includeWrapper: Bool = true
    ) -> String {
        metadata.toXML(includeWrapper: includeWrapper)
    }

    // MARK: - PDF/A Identification

    /// Sets PDF/A identification in XMP metadata.
    ///
    /// - Parameters:
    ///   - metadata: The XMP metadata model to modify
    ///   - part: The PDF/A part (1, 2, 3, or 4)
    ///   - conformance: The conformance level (A, B, U, E, or F)
    /// - Returns: The modified XMP metadata model
    public func setPDFAIdentification(
        in metadata: XMPMetadataModel,
        part: Int,
        conformance: String
    ) -> XMPMetadataModel {
        var modified = metadata
        modified.pdfaIdentification.part = part
        modified.pdfaIdentification.conformance = conformance
        return modified
    }
}

// MARK: - Configuration

/// Configuration options for the MetadataFixer.
public struct MetadataFixerConfiguration: Sendable {

    /// Whether to normalize dates to UTC.
    public let normalizedDates: Bool

    /// Whether to update xmp:MetadataDate when fixing.
    public let updateMetadataDate: Bool

    /// Tolerance for date comparison in seconds.
    public let dateTolerance: TimeInterval

    public init(
        normalizedDates: Bool = false,
        updateMetadataDate: Bool = true,
        dateTolerance: TimeInterval = 1.0
    ) {
        self.normalizedDates = normalizedDates
        self.updateMetadataDate = updateMetadataDate
        self.dateTolerance = dateTolerance
    }

    /// Default configuration.
    public static let `default` = MetadataFixerConfiguration()

    /// Strict configuration for maximum PDF/A compliance.
    public static let strict = MetadataFixerConfiguration(
        normalizedDates: true,
        updateMetadataDate: true,
        dateTolerance: 0.0
    )
}

// MARK: - Fix Options

/// Options for how to fix metadata synchronization issues.
public enum MetadataFixOptions: Sendable {
    /// Copy Info dictionary values to XMP (XMP takes precedence for conflicts).
    case synchronizeToXMP

    /// Copy XMP values to Info dictionary.
    case synchronizeToInfo

    /// Use Info dictionary values when both exist.
    case preferInfo

    /// Use XMP values when both exist.
    case preferXMP

    /// Synchronize both directions, filling in missing values.
    case bidirectional
}

// MARK: - Analysis Report

/// Report of metadata analysis results.
public struct MetadataAnalysisReport: Sendable {

    /// The issues found.
    public let issues: [MetadataIssue]

    /// The analyzed Info dictionary.
    public let infoDictionary: InfoDictionary

    /// The analyzed XMP metadata.
    public let xmpMetadata: XMPMetadataModel

    /// Whether the metadata is PDF/A compliant.
    public let isCompliant: Bool

    /// Issues filtered by category.
    public func issues(in category: MetadataIssue.Category) -> [MetadataIssue] {
        issues.filter { $0.category == category }
    }

    /// Issues filtered by severity.
    public func issues(with severity: MetadataIssue.Severity) -> [MetadataIssue] {
        issues.filter { $0.severity == severity }
    }

    /// Fixable issues.
    public var fixableIssues: [MetadataIssue] {
        issues.filter { $0.fixable }
    }

    /// Error-level issues.
    public var errors: [MetadataIssue] {
        issues.filter { $0.severity == .error }
    }

    /// Warning-level issues.
    public var warnings: [MetadataIssue] {
        issues.filter { $0.severity == .warning }
    }

    /// A summary string of the analysis.
    public var summary: String {
        let errorCount = errors.count
        let warningCount = warnings.count
        let totalCount = issues.count

        if isCompliant {
            if warningCount > 0 {
                return "Metadata is compliant with \(warningCount) warning(s)"
            } else {
                return "Metadata is compliant"
            }
        } else {
            return "Metadata has \(errorCount) error(s) and \(warningCount) warning(s) out of \(totalCount) issue(s)"
        }
    }
}

// MARK: - Metadata Issue

/// Represents an issue found in metadata.
public struct MetadataIssue: Sendable, Identifiable, Equatable {
    public let id: UUID

    /// The category of the issue.
    public let category: Category

    /// The severity of the issue.
    public let severity: Severity

    /// The affected key/property name.
    public let key: String?

    /// The XMP namespace, if applicable.
    public let namespace: String?

    /// A description of the issue.
    public let message: String

    /// The PDF/A rule ID, if applicable.
    public let ruleId: String?

    /// Whether this issue can be automatically fixed.
    public let fixable: Bool

    public init(
        id: UUID = UUID(),
        category: Category,
        severity: Severity,
        key: String? = nil,
        namespace: String? = nil,
        message: String,
        ruleId: String? = nil,
        fixable: Bool = false
    ) {
        self.id = id
        self.category = category
        self.severity = severity
        self.key = key
        self.namespace = namespace
        self.message = message
        self.ruleId = ruleId
        self.fixable = fixable
    }

    /// Categories of metadata issues.
    public enum Category: String, Sendable, Codable {
        case infoDictionary = "Info Dictionary"
        case xmpMetadata = "XMP Metadata"
        case synchronization = "Synchronization"
        case pdfaIdentification = "PDF/A Identification"
        case missing = "Missing Metadata"
    }

    /// Severity levels.
    public enum Severity: String, Sendable, Codable {
        case error
        case warning
        case info
    }
}
