import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Metadata Fixer Tests

@Suite("Metadata Fixer Tests")
struct MetadataFixerTests {

    // MARK: - Configuration

    @Suite("Configuration")
    struct ConfigurationTests {

        @Test("Default configuration")
        func defaultConfiguration() throws {
            let config = MetadataFixerConfiguration.default

            #expect(!config.normalizedDates)
            #expect(config.updateMetadataDate)
            #expect(config.dateTolerance == 1.0)
        }

        @Test("Strict configuration")
        func strictConfiguration() throws {
            let config = MetadataFixerConfiguration.strict

            #expect(config.normalizedDates)
            #expect(config.updateMetadataDate)
            #expect(config.dateTolerance == 0.0)
        }

        @Test("Custom configuration")
        func customConfiguration() throws {
            let config = MetadataFixerConfiguration(
                normalizedDates: true,
                updateMetadataDate: false,
                dateTolerance: 5.0
            )

            #expect(config.normalizedDates)
            #expect(!config.updateMetadataDate)
            #expect(config.dateTolerance == 5.0)
        }
    }

    // MARK: - Analysis

    @Suite("Analysis")
    struct AnalysisTests {

        @Test("Analyze synchronized metadata")
        func analyzeSynchronizedMetadata() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(
                title: "Test Title",
                author: "Test Author",
                creationDate: "D:20230615120000Z"
            )

            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(
                    creator: ["Test Author"],
                    title: ["x-default": "Test Title"]
                ),
                xmpBasic: XMPBasicSchema(
                    createDate: Date.fromPDFDate("D:20230615120000Z")
                )
            )

            let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)

            #expect(report.errors.isEmpty)
        }

        @Test("Analyze with synchronization issues")
        func analyzeWithSynchronizationIssues() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(
                title: "Info Title",
                author: "Info Author"
            )

            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(
                    creator: ["XMP Author"],
                    title: ["x-default": "XMP Title"]
                )
            )

            let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)

            #expect(!report.issues(in: .synchronization).isEmpty)
        }

        @Test("Analyze with invalid Info dictionary dates")
        func analyzeWithInvalidDates() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(creationDate: "invalid-date")
            let xmp = XMPMetadataModel()

            let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)

            #expect(report.issues(in: .infoDictionary).contains {
                $0.key == "CreationDate" && $0.severity == .error
            })
        }

        @Test("Analyze for PDF/A identification")
        func analyzeForPDFAIdentification() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary()
            let xmp = XMPMetadataModel(
                pdfaIdentification: PDFAIdentificationSchema(part: 2, conformance: "B")
            )

            let report = fixer.analyze(
                infoDictionary: info,
                xmpMetadata: xmp,
                pdfaPart: 3, // Wrong part
                pdfaLevel: "B"
            )

            #expect(report.issues(in: .pdfaIdentification).contains {
                $0.key == "part"
            })
        }

        @Test("Analyze missing recommended metadata")
        func analyzeMissingRecommendedMetadata() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary()
            let xmp = XMPMetadataModel()

            let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)

            #expect(report.issues(in: .missing).count > 0)
        }

        @Test("Report summary")
        func reportSummary() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(title: "Test")
            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test"])
            )

            let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)

            #expect(report.summary.count > 0)
        }

        @Test("Fixable issues")
        func fixableIssues() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(title: "Title")
            let xmp = XMPMetadataModel()

            let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)
            let fixable = report.fixableIssues

            #expect(fixable.allSatisfy { $0.fixable })
        }
    }

    // MARK: - Fixing

    @Suite("Fixing")
    struct FixingTests {

        @Test("Synchronize to XMP")
        func synchronizeToXMP() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(
                title: "Info Title",
                author: "Info Author",
                keywords: "info, keywords"
            )

            let xmp = XMPMetadataModel()

            let (_, fixedXMP) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp,
                options: .synchronizeToXMP
            )

            #expect(fixedXMP.title == "Info Title")
            #expect(fixedXMP.creator == "Info Author")
            #expect(fixedXMP.keywords == "info, keywords")
        }

        @Test("Synchronize to Info")
        func synchronizeToInfo() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary()

            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(
                    creator: ["XMP Author"],
                    title: ["x-default": "XMP Title"]
                ),
                adobePDF: AdobePDFSchema(keywords: "xmp, keywords")
            )

            let (fixedInfo, _) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp,
                options: .synchronizeToInfo
            )

            #expect(fixedInfo.title == "XMP Title")
            #expect(fixedInfo.author == "XMP Author")
            #expect(fixedInfo.keywords == "xmp, keywords")
        }

        @Test("Prefer Info")
        func preferInfo() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(title: "Info Title")

            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(
                    title: ["x-default": "XMP Title"]
                )
            )

            let (_, fixedXMP) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp,
                options: .preferInfo
            )

            #expect(fixedXMP.title == "Info Title")
        }

        @Test("Prefer XMP")
        func preferXMP() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(title: "Info Title")

            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(
                    title: ["x-default": "XMP Title"]
                )
            )

            let (fixedInfo, _) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp,
                options: .preferXMP
            )

            #expect(fixedInfo.title == "XMP Title")
        }

        @Test("Bidirectional synchronization")
        func bidirectionalSynchronization() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(
                title: "Info Title"
                // author not set
            )

            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(
                    creator: ["XMP Author"]
                    // title not set
                )
            )

            let (fixedInfo, fixedXMP) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp,
                options: .bidirectional
            )

            // Info title -> XMP
            #expect(fixedXMP.title == "Info Title")
            // XMP author -> Info
            #expect(fixedInfo.author == "XMP Author")
        }

        @Test("Fix dates synchronization")
        func fixDatesSynchronization() throws {
            let fixer = MetadataFixer()
            let date = Date()

            let info = InfoDictionary(
                creationDate: date.toPDFDateString()
            )

            let xmp = XMPMetadataModel()

            let (_, fixedXMP) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp,
                options: .synchronizeToXMP
            )

            #expect(fixedXMP.createDate != nil)
        }

        @Test("Fix trapped status")
        func fixTrappedStatus() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(trapped: .trapped)
            let xmp = XMPMetadataModel()

            let (_, fixedXMP) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp,
                options: .synchronizeToXMP
            )

            #expect(fixedXMP.adobePDF.trapped == .true)
        }

        @Test("Update metadata date")
        func updateMetadataDate() throws {
            let config = MetadataFixerConfiguration(updateMetadataDate: true)
            let fixer = MetadataFixer(configuration: config)

            let info = InfoDictionary()
            let xmp = XMPMetadataModel()

            let (_, fixedXMP) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp
            )

            #expect(fixedXMP.xmpBasic.metadataDate != nil)
        }

        @Test("Normalize dates")
        func normalizeDates() throws {
            let config = MetadataFixerConfiguration(normalizedDates: true)
            let fixer = MetadataFixer(configuration: config)

            let info = InfoDictionary(
                creationDate: "D:20230615120000+05'00'"
            )
            let xmp = XMPMetadataModel()

            let (fixedInfo, _) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp
            )

            #expect(fixedInfo.creationDate?.contains("Z") == true)
        }
    }

    // MARK: - XMP Generation

    @Suite("XMP Generation")
    struct XMPGenerationTests {

        @Test("Generate XMP packet")
        func generateXMPPacket() throws {
            let fixer = MetadataFixer()
            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test"])
            )

            let packet = fixer.generateXMPPacket(xmp)

            #expect(packet.contains("<?xpacket"))
            #expect(packet.contains("Test"))
        }

        @Test("Generate XMP packet without wrapper")
        func generateXMPPacketWithoutWrapper() throws {
            let fixer = MetadataFixer()
            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test"])
            )

            let packet = fixer.generateXMPPacket(xmp, includeWrapper: false)

            #expect(!packet.contains("<?xpacket"))
        }
    }

    // MARK: - PDF/A Identification

    @Suite("PDF/A Identification")
    struct PDFAIdentificationTests {

        @Test("Set PDF/A identification")
        func setPDFAIdentification() throws {
            let fixer = MetadataFixer()
            let xmp = XMPMetadataModel()

            let modified = fixer.setPDFAIdentification(in: xmp, part: 2, conformance: "B")

            #expect(modified.pdfaPart == 2)
            #expect(modified.pdfaConformance == "B")
        }
    }

    // MARK: - Metadata Issue

    @Suite("Metadata Issue")
    struct MetadataIssueTests {

        @Test("Create metadata issue")
        func createMetadataIssue() throws {
            let issue = MetadataIssue(
                category: .synchronization,
                severity: .error,
                key: "Title",
                namespace: DublinCoreSchema.namespaceURI,
                message: "Title mismatch",
                ruleId: "6.7.3-1",
                fixable: true
            )

            #expect(issue.category == .synchronization)
            #expect(issue.severity == .error)
            #expect(issue.key == "Title")
            #expect(issue.fixable)
        }

        @Test("Issue categories")
        func issueCategories() throws {
            #expect(MetadataIssue.Category.infoDictionary.rawValue == "Info Dictionary")
            #expect(MetadataIssue.Category.xmpMetadata.rawValue == "XMP Metadata")
            #expect(MetadataIssue.Category.synchronization.rawValue == "Synchronization")
        }
    }

    // MARK: - Analysis Report

    @Suite("Analysis Report")
    struct AnalysisReportTests {

        @Test("Filter issues by category")
        func filterIssuesByCategory() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(creationDate: "invalid")
            let xmp = XMPMetadataModel()

            let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)
            let infoIssues = report.issues(in: .infoDictionary)

            #expect(!infoIssues.isEmpty)
        }

        @Test("Filter issues by severity")
        func filterIssuesBySeverity() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary(creationDate: "invalid")
            let xmp = XMPMetadataModel()

            let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)
            let errors = report.issues(with: .error)

            #expect(!errors.isEmpty)
        }

        @Test("Compliance status")
        func complianceStatus() throws {
            let fixer = MetadataFixer()

            // Valid synchronized metadata
            let info = InfoDictionary(title: "Test")
            let xmp = XMPMetadataModel(
                dublinCore: DublinCoreSchema(title: ["x-default": "Test"])
            )

            let report = fixer.analyze(infoDictionary: info, xmpMetadata: xmp)

            // Should be compliant if no errors
            #expect(report.errors.isEmpty == report.isCompliant)
        }
    }

    // MARK: - Fix Options

    @Suite("Fix Options")
    struct FixOptionsTests {

        @Test("All fix options")
        func allFixOptions() throws {
            let options: [MetadataFixOptions] = [
                .synchronizeToXMP,
                .synchronizeToInfo,
                .preferInfo,
                .preferXMP,
                .bidirectional
            ]

            #expect(options.count == 5)
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCaseTests {

        @Test("Empty metadata")
        func emptyMetadata() throws {
            let fixer = MetadataFixer()

            let info = InfoDictionary()
            let xmp = XMPMetadataModel()

            let (fixedInfo, fixedXMP) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp
            )

            // Should not crash
            #expect(fixedInfo.isEmpty)
            #expect(fixedXMP.title == nil)
        }

        @Test("Full metadata synchronization")
        func fullMetadataSynchronization() throws {
            let fixer = MetadataFixer()
            let now = Date()

            let info = InfoDictionary(
                title: "Title",
                author: "Author",
                subject: "Subject",
                keywords: "keywords",
                creator: "Creator",
                producer: "Producer",
                creationDate: now.toPDFDateString(),
                modDate: now.toPDFDateString(),
                trapped: .notTrapped
            )

            let xmp = XMPMetadataModel()

            let (_, fixedXMP) = fixer.fix(
                infoDictionary: info,
                xmpMetadata: xmp,
                options: .synchronizeToXMP
            )

            #expect(fixedXMP.title == "Title")
            #expect(fixedXMP.creator == "Author")
            #expect(fixedXMP.description == "Subject")
            #expect(fixedXMP.keywords == "keywords")
            #expect(fixedXMP.creatorTool == "Creator")
            #expect(fixedXMP.producer == "Producer")
            #expect(fixedXMP.createDate != nil)
            #expect(fixedXMP.modifyDate != nil)
            #expect(fixedXMP.adobePDF.trapped == .false)
        }
    }
}
