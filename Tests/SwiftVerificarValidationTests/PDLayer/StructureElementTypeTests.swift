import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - StructureElementType Tests

@Suite("StructureElementType")
struct StructureElementTypeTests {

    // MARK: - Raw Value Initialization

    @Suite("Raw Value Initialization")
    struct RawValueTests {

        @Test("Standard document structure types have correct raw values")
        func documentStructureRawValues() {
            #expect(StructureElementType.document.rawValue == "Document")
            #expect(StructureElementType.documentFragment.rawValue == "DocumentFragment")
            #expect(StructureElementType.part.rawValue == "Part")
            #expect(StructureElementType.sect.rawValue == "Sect")
            #expect(StructureElementType.div.rawValue == "Div")
            #expect(StructureElementType.aside.rawValue == "Aside")
            #expect(StructureElementType.nonStruct.rawValue == "NonStruct")
        }

        @Test("Block-level types have correct raw values")
        func blockLevelRawValues() {
            #expect(StructureElementType.paragraph.rawValue == "P")
            #expect(StructureElementType.heading.rawValue == "H")
            #expect(StructureElementType.h1.rawValue == "H1")
            #expect(StructureElementType.h2.rawValue == "H2")
            #expect(StructureElementType.h3.rawValue == "H3")
            #expect(StructureElementType.h4.rawValue == "H4")
            #expect(StructureElementType.h5.rawValue == "H5")
            #expect(StructureElementType.h6.rawValue == "H6")
            #expect(StructureElementType.blockQuote.rawValue == "BlockQuote")
            #expect(StructureElementType.caption.rawValue == "Caption")
        }

        @Test("List types have correct raw values")
        func listRawValues() {
            #expect(StructureElementType.list.rawValue == "L")
            #expect(StructureElementType.listItem.rawValue == "LI")
            #expect(StructureElementType.label.rawValue == "Lbl")
            #expect(StructureElementType.listBody.rawValue == "LBody")
        }

        @Test("Table types have correct raw values")
        func tableRawValues() {
            #expect(StructureElementType.table.rawValue == "Table")
            #expect(StructureElementType.tableRow.rawValue == "TR")
            #expect(StructureElementType.tableHeader.rawValue == "TH")
            #expect(StructureElementType.tableData.rawValue == "TD")
            #expect(StructureElementType.tableHead.rawValue == "THead")
            #expect(StructureElementType.tableBody.rawValue == "TBody")
            #expect(StructureElementType.tableFoot.rawValue == "TFoot")
        }

        @Test("Inline types have correct raw values")
        func inlineRawValues() {
            #expect(StructureElementType.span.rawValue == "Span")
            #expect(StructureElementType.quote.rawValue == "Quote")
            #expect(StructureElementType.note.rawValue == "Note")
            #expect(StructureElementType.reference.rawValue == "Reference")
            #expect(StructureElementType.bibEntry.rawValue == "BibEntry")
            #expect(StructureElementType.code.rawValue == "Code")
            #expect(StructureElementType.link.rawValue == "Link")
            #expect(StructureElementType.annot.rawValue == "Annot")
        }

        @Test("Illustration types have correct raw values")
        func illustrationRawValues() {
            #expect(StructureElementType.figure.rawValue == "Figure")
            #expect(StructureElementType.formula.rawValue == "Formula")
            #expect(StructureElementType.form.rawValue == "Form")
        }

        @Test("Ruby/Warichu types have correct raw values")
        func rubyWarichuRawValues() {
            #expect(StructureElementType.ruby.rawValue == "Ruby")
            #expect(StructureElementType.rb.rawValue == "RB")
            #expect(StructureElementType.rt.rawValue == "RT")
            #expect(StructureElementType.rp.rawValue == "RP")
            #expect(StructureElementType.warichu.rawValue == "Warichu")
            #expect(StructureElementType.wt.rawValue == "WT")
            #expect(StructureElementType.wp.rawValue == "WP")
        }

        @Test("PDF 2.0 types have correct raw values")
        func pdf2RawValues() {
            #expect(StructureElementType.feNote.rawValue == "FENote")
            #expect(StructureElementType.em.rawValue == "Em")
            #expect(StructureElementType.strong.rawValue == "Strong")
            #expect(StructureElementType.sub.rawValue == "Sub")
            #expect(StructureElementType.title.rawValue == "Title")
            #expect(StructureElementType.artifact.rawValue == "Artifact")
        }

        @Test("Other types have correct raw values")
        func otherRawValues() {
            #expect(StructureElementType.toc.rawValue == "TOC")
            #expect(StructureElementType.toci.rawValue == "TOCI")
            #expect(StructureElementType.index.rawValue == "Index")
            #expect(StructureElementType.private.rawValue == "Private")
        }

        @Test("Round-trip from raw value succeeds for all cases")
        func roundTripAll() {
            for type in StructureElementType.allCases {
                let rebuilt = StructureElementType(rawValue: type.rawValue)
                #expect(rebuilt == type, "Round-trip failed for \(type)")
            }
        }

        @Test("Unknown raw value returns nil")
        func unknownRawValue() {
            #expect(StructureElementType(rawValue: "UnknownType") == nil)
            #expect(StructureElementType(rawValue: "") == nil)
            #expect(StructureElementType(rawValue: "paragraph") == nil) // case-sensitive
        }
    }

    // MARK: - Category Classification

    @Suite("Category Classification")
    struct CategoryTests {

        @Test("Document structure elements have correct category")
        func documentStructureCategory() {
            #expect(StructureElementType.document.category == .documentStructure)
            #expect(StructureElementType.part.category == .documentStructure)
            #expect(StructureElementType.sect.category == .documentStructure)
            #expect(StructureElementType.div.category == .documentStructure)
            #expect(StructureElementType.aside.category == .documentStructure)
            #expect(StructureElementType.nonStruct.category == .documentStructure)
        }

        @Test("Block-level elements have correct category")
        func blockLevelCategory() {
            #expect(StructureElementType.paragraph.category == .blockLevel)
            #expect(StructureElementType.heading.category == .blockLevel)
            #expect(StructureElementType.h1.category == .blockLevel)
            #expect(StructureElementType.h6.category == .blockLevel)
            #expect(StructureElementType.blockQuote.category == .blockLevel)
            #expect(StructureElementType.caption.category == .blockLevel)
        }

        @Test("List elements have correct category")
        func listCategory() {
            #expect(StructureElementType.list.category == .list)
            #expect(StructureElementType.listItem.category == .list)
            #expect(StructureElementType.label.category == .list)
            #expect(StructureElementType.listBody.category == .list)
        }

        @Test("Table elements have correct category")
        func tableCategory() {
            #expect(StructureElementType.table.category == .table)
            #expect(StructureElementType.tableRow.category == .table)
            #expect(StructureElementType.tableHeader.category == .table)
            #expect(StructureElementType.tableData.category == .table)
            #expect(StructureElementType.tableHead.category == .table)
            #expect(StructureElementType.tableBody.category == .table)
            #expect(StructureElementType.tableFoot.category == .table)
        }

        @Test("Inline elements have correct category")
        func inlineCategory() {
            #expect(StructureElementType.span.category == .inline)
            #expect(StructureElementType.quote.category == .inline)
            #expect(StructureElementType.link.category == .inline)
            #expect(StructureElementType.code.category == .inline)
        }

        @Test("Illustration elements have correct category")
        func illustrationCategory() {
            #expect(StructureElementType.figure.category == .illustration)
            #expect(StructureElementType.formula.category == .illustration)
            #expect(StructureElementType.form.category == .illustration)
        }

        @Test("Ruby/Warichu elements have correct category")
        func rubyWarichuCategory() {
            #expect(StructureElementType.ruby.category == .rubyWarichu)
            #expect(StructureElementType.rb.category == .rubyWarichu)
            #expect(StructureElementType.warichu.category == .rubyWarichu)
        }

        @Test("All Category cases exist")
        func allCategories() {
            #expect(StructureElementType.Category.allCases.count == 8)
        }
    }

    // MARK: - Heading Properties

    @Suite("Heading Properties")
    struct HeadingTests {

        @Test("Heading types are correctly identified")
        func isHeading() {
            #expect(StructureElementType.heading.isHeading)
            #expect(StructureElementType.h1.isHeading)
            #expect(StructureElementType.h2.isHeading)
            #expect(StructureElementType.h3.isHeading)
            #expect(StructureElementType.h4.isHeading)
            #expect(StructureElementType.h5.isHeading)
            #expect(StructureElementType.h6.isHeading)
        }

        @Test("Non-heading types are not identified as headings")
        func notHeading() {
            #expect(!StructureElementType.paragraph.isHeading)
            #expect(!StructureElementType.div.isHeading)
            #expect(!StructureElementType.table.isHeading)
            #expect(!StructureElementType.figure.isHeading)
        }

        @Test("Heading levels are correct")
        func headingLevels() {
            #expect(StructureElementType.h1.headingLevel == 1)
            #expect(StructureElementType.h2.headingLevel == 2)
            #expect(StructureElementType.h3.headingLevel == 3)
            #expect(StructureElementType.h4.headingLevel == 4)
            #expect(StructureElementType.h5.headingLevel == 5)
            #expect(StructureElementType.h6.headingLevel == 6)
        }

        @Test("Generic heading has nil level")
        func genericHeadingLevel() {
            #expect(StructureElementType.heading.headingLevel == nil)
        }

        @Test("Non-heading has nil level")
        func nonHeadingLevel() {
            #expect(StructureElementType.paragraph.headingLevel == nil)
        }

        @Test("allHeadings returns all heading types")
        func allHeadings() {
            let headings = StructureElementType.allHeadings
            #expect(headings.count == 7)
            #expect(headings.contains(.heading))
            #expect(headings.contains(.h1))
            #expect(headings.contains(.h6))
        }
    }

    // MARK: - Element Classification Properties

    @Suite("Element Classification")
    struct ClassificationTests {

        @Test("Table elements are correctly identified")
        func isTableElement() {
            #expect(StructureElementType.table.isTableElement)
            #expect(StructureElementType.tableRow.isTableElement)
            #expect(StructureElementType.tableHeader.isTableElement)
            #expect(!StructureElementType.paragraph.isTableElement)
        }

        @Test("List elements are correctly identified")
        func isListElement() {
            #expect(StructureElementType.list.isListElement)
            #expect(StructureElementType.listItem.isListElement)
            #expect(StructureElementType.label.isListElement)
            #expect(StructureElementType.listBody.isListElement)
            #expect(!StructureElementType.table.isListElement)
        }

        @Test("Inline elements are correctly identified")
        func isInline() {
            #expect(StructureElementType.span.isInline)
            #expect(StructureElementType.link.isInline)
            #expect(!StructureElementType.paragraph.isInline)
        }

        @Test("Block-level elements are correctly identified")
        func isBlockLevel() {
            #expect(StructureElementType.paragraph.isBlockLevel)
            #expect(StructureElementType.document.isBlockLevel)
            #expect(StructureElementType.sect.isBlockLevel)
            #expect(!StructureElementType.span.isBlockLevel)
        }

        @Test("Elements requiring alt text are correctly identified")
        func requiresAltText() {
            #expect(StructureElementType.figure.requiresAltText)
            #expect(StructureElementType.formula.requiresAltText)
            #expect(!StructureElementType.paragraph.requiresAltText)
            #expect(!StructureElementType.table.requiresAltText)
        }

        @Test("Grouping elements are correctly identified")
        func isGrouping() {
            #expect(StructureElementType.document.isGrouping)
            #expect(StructureElementType.part.isGrouping)
            #expect(StructureElementType.list.isGrouping)
            #expect(StructureElementType.table.isGrouping)
            #expect(!StructureElementType.paragraph.isGrouping)
            #expect(!StructureElementType.span.isGrouping)
        }

        @Test("Artifact is correctly identified")
        func isArtifact() {
            #expect(StructureElementType.artifact.isArtifact)
            #expect(!StructureElementType.paragraph.isArtifact)
        }

        @Test("Content elements are correctly identified")
        func isContent() {
            #expect(StructureElementType.paragraph.isContent)
            #expect(StructureElementType.h1.isContent)
            #expect(StructureElementType.span.isContent)
            #expect(StructureElementType.figure.isContent)
            #expect(StructureElementType.link.isContent)
            #expect(!StructureElementType.document.isContent)
            #expect(!StructureElementType.table.isContent)
            #expect(!StructureElementType.list.isContent)
        }

        @Test("PDF 2.0 types are correctly identified")
        func isPDF2Only() {
            #expect(StructureElementType.documentFragment.isPDF2Only)
            #expect(StructureElementType.aside.isPDF2Only)
            #expect(StructureElementType.caption.isPDF2Only)
            #expect(StructureElementType.feNote.isPDF2Only)
            #expect(StructureElementType.em.isPDF2Only)
            #expect(StructureElementType.strong.isPDF2Only)
            #expect(StructureElementType.sub.isPDF2Only)
            #expect(StructureElementType.title.isPDF2Only)
            #expect(!StructureElementType.paragraph.isPDF2Only)
            #expect(!StructureElementType.table.isPDF2Only)
        }
    }

    // MARK: - Static Collections

    @Suite("Static Collections")
    struct CollectionTests {

        @Test("allTableTypes returns all table types")
        func allTableTypes() {
            let types = StructureElementType.allTableTypes
            #expect(types.count == 7)
            #expect(types.contains(.table))
            #expect(types.contains(.tableRow))
            #expect(types.contains(.tableHeader))
            #expect(types.contains(.tableData))
            #expect(types.contains(.tableHead))
            #expect(types.contains(.tableBody))
            #expect(types.contains(.tableFoot))
        }

        @Test("allListTypes returns all list types")
        func allListTypes() {
            let types = StructureElementType.allListTypes
            #expect(types.count == 4)
            #expect(types.contains(.list))
            #expect(types.contains(.listItem))
        }

        @Test("allInlineTypes returns all inline types")
        func allInlineTypes() {
            let types = StructureElementType.allInlineTypes
            #expect(types.count == 8)
            #expect(types.contains(.span))
            #expect(types.contains(.link))
        }

        @Test("pdf2Types returns only PDF 2.0 types")
        func pdf2Types() {
            let types = StructureElementType.pdf2Types
            for type in types {
                #expect(type.isPDF2Only, "\(type) should be PDF 2.0 only")
            }
            #expect(types.count >= 8)
        }

        @Test("from(name:) returns correct type")
        func fromName() {
            #expect(StructureElementType.from(name: "P") == .paragraph)
            #expect(StructureElementType.from(name: "H1") == .h1)
            #expect(StructureElementType.from(name: "Table") == .table)
            #expect(StructureElementType.from(name: "Unknown") == nil)
        }
    }

    // MARK: - CaseIterable

    @Suite("CaseIterable")
    struct CaseIterableTests {

        @Test("All cases count is at least 41")
        func caseCount() {
            #expect(StructureElementType.allCases.count >= 41)
        }

        @Test("No duplicate raw values")
        func noDuplicateRawValues() {
            let rawValues = StructureElementType.allCases.map(\.rawValue)
            let uniqueRawValues = Set(rawValues)
            #expect(rawValues.count == uniqueRawValues.count)
        }
    }

    // MARK: - Codable

    @Suite("Codable")
    struct CodableTests {

        @Test("Encoding and decoding round-trips correctly")
        func roundTrip() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            for type in StructureElementType.allCases {
                let data = try encoder.encode(type)
                let decoded = try decoder.decode(StructureElementType.self, from: data)
                #expect(decoded == type, "Codable round-trip failed for \(type)")
            }
        }
    }

    // MARK: - Description

    @Suite("CustomStringConvertible")
    struct DescriptionTests {

        @Test("Description equals raw value")
        func descriptionEqualsRawValue() {
            for type in StructureElementType.allCases {
                #expect(type.description == type.rawValue)
            }
        }
    }
}
