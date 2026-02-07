import Foundation

// MARK: - Structure Element Type

/// Enumeration of all PDF structure element types.
///
/// This enum categorizes the standard structure types defined in the PDF specification
/// (ISO 32000-1, ISO 32000-2) and PDF/UA standards. It provides a type-safe way to
/// identify structure element types during validation.
///
/// ## Categories
///
/// Structure elements are organized into several categories:
/// - **Document structure**: Document, Part, Sect, Div, etc.
/// - **Block-level**: Paragraphs, headings, block quotes
/// - **Lists**: L, LI, Lbl, LBody
/// - **Tables**: Table, TR, TH, TD, THead, TBody, TFoot
/// - **Inline**: Span, Quote, Note, Reference, etc.
/// - **Illustration**: Figure, Formula, Form
/// - **Ruby/Warichu**: Ruby, RB, RT, RP, Warichu, WT, WP
/// - **PDF 2.0 additions**: FENote, Em, Strong, Sub, Title, Artifact
///
/// ## Relationship to veraPDF
///
/// Corresponds to the 58 `GFSE*` Java classes in veraPDF-validation, consolidated
/// into a single enum. The raw value matches the structure type name as it appears
/// in the PDF `/S` (structure type) entry.
///
/// ## Usage
///
/// ```swift
/// let elementType = StructureElementType(rawValue: "P") // .paragraph
/// let headingLevel = StructureElementType.h1
/// ```
///
/// ## Important
///
/// This is a **critical shared type** that `SwiftVerificar-biblioteca` (Layer 2)
/// will import and use for structure analysis and accessibility validation.
public enum StructureElementType: String, Sendable, Hashable, CaseIterable, Codable {

    // MARK: - Document Structure

    /// The root document structure element.
    case document = "Document"

    /// A document fragment (PDF 2.0).
    case documentFragment = "DocumentFragment"

    /// A large division of the document, such as a chapter or section.
    case part = "Part"

    /// A section of content, typically with a heading.
    case sect = "Sect"

    /// A generic block-level grouping element.
    case div = "Div"

    /// Content tangential to the main text (PDF 2.0).
    case aside = "Aside"

    /// A non-structural grouping element.
    case nonStruct = "NonStruct"

    // MARK: - Block-Level Elements

    /// A paragraph.
    case paragraph = "P"

    /// A generic heading (unnumbered).
    case heading = "H"

    /// A level-1 heading.
    case h1 = "H1"

    /// A level-2 heading.
    case h2 = "H2"

    /// A level-3 heading.
    case h3 = "H3"

    /// A level-4 heading.
    case h4 = "H4"

    /// A level-5 heading.
    case h5 = "H5"

    /// A level-6 heading.
    case h6 = "H6"

    /// A block-level quotation.
    case blockQuote = "BlockQuote"

    /// A caption for a figure or table (PDF 2.0).
    case caption = "Caption"

    // MARK: - List Elements

    /// A list (ordered or unordered).
    case list = "L"

    /// A list item.
    case listItem = "LI"

    /// A label for a list item (e.g., bullet, number).
    case label = "Lbl"

    /// The body content of a list item.
    case listBody = "LBody"

    // MARK: - Table Elements

    /// A table.
    case table = "Table"

    /// A table row.
    case tableRow = "TR"

    /// A table header cell.
    case tableHeader = "TH"

    /// A table data cell.
    case tableData = "TD"

    /// A table header row group.
    case tableHead = "THead"

    /// A table body row group.
    case tableBody = "TBody"

    /// A table footer row group.
    case tableFoot = "TFoot"

    // MARK: - Inline Elements

    /// A generic inline-level grouping element.
    case span = "Span"

    /// An inline quotation.
    case quote = "Quote"

    /// A note or annotation reference.
    case note = "Note"

    /// A reference to content elsewhere in the document.
    case reference = "Reference"

    /// A bibliographic entry.
    case bibEntry = "BibEntry"

    /// A fragment of computer code.
    case code = "Code"

    /// A hyperlink.
    case link = "Link"

    /// An annotation associated with content.
    case annot = "Annot"

    // MARK: - Illustration Elements

    /// A figure or illustration.
    case figure = "Figure"

    /// A mathematical formula.
    case formula = "Formula"

    /// An interactive form widget.
    case form = "Form"

    // MARK: - Ruby and Warichu Elements

    /// A ruby annotation (used in CJK text).
    case ruby = "Ruby"

    /// Ruby base text.
    case rb = "RB"

    /// Ruby annotation text.
    case rt = "RT"

    /// Ruby punctuation.
    case rp = "RP"

    /// A warichu annotation (used in CJK text).
    case warichu = "Warichu"

    /// Warichu text content.
    case wt = "WT"

    /// Warichu punctuation.
    case wp = "WP"

    // MARK: - PDF 2.0 Additions

    /// A footnote or endnote (PDF 2.0).
    case feNote = "FENote"

    /// Emphasis (PDF 2.0).
    case em = "Em"

    /// Strong importance (PDF 2.0).
    case strong = "Strong"

    /// A subscript element (PDF 2.0).
    case sub = "Sub"

    /// A title element (PDF 2.0).
    case title = "Title"

    /// A non-structural artifact.
    case artifact = "Artifact"

    /// A table of contents (TOC).
    case toc = "TOC"

    /// A table of contents item (TOCI).
    case toci = "TOCI"

    /// An index.
    case index = "Index"

    /// A private element (non-standard).
    case `private` = "Private"
}

// MARK: - Category Classification

extension StructureElementType {

    /// The category this structure element type belongs to.
    public var category: Category {
        switch self {
        case .document, .documentFragment, .part, .sect, .div, .aside, .nonStruct:
            return .documentStructure
        case .paragraph, .heading, .h1, .h2, .h3, .h4, .h5, .h6, .blockQuote, .caption:
            return .blockLevel
        case .list, .listItem, .label, .listBody:
            return .list
        case .table, .tableRow, .tableHeader, .tableData, .tableHead, .tableBody, .tableFoot:
            return .table
        case .span, .quote, .note, .reference, .bibEntry, .code, .link, .annot:
            return .inline
        case .figure, .formula, .form:
            return .illustration
        case .ruby, .rb, .rt, .rp, .warichu, .wt, .wp:
            return .rubyWarichu
        case .feNote, .em, .strong, .sub, .title, .artifact, .toc, .toci, .index, .private:
            return .other
        }
    }

    /// Categories of structure element types.
    public enum Category: String, Sendable, Hashable, CaseIterable, Codable {
        /// Document-level grouping elements.
        case documentStructure

        /// Block-level text elements.
        case blockLevel

        /// List elements.
        case list

        /// Table elements.
        case table

        /// Inline text elements.
        case inline

        /// Illustration and figure elements.
        case illustration

        /// Ruby and Warichu annotation elements.
        case rubyWarichu

        /// Other/miscellaneous elements.
        case other
    }
}

// MARK: - Semantic Properties

extension StructureElementType {

    /// Whether this element type is a heading (H, H1-H6).
    public var isHeading: Bool {
        switch self {
        case .heading, .h1, .h2, .h3, .h4, .h5, .h6:
            return true
        default:
            return false
        }
    }

    /// The heading level (1-6), or `nil` if not a numbered heading.
    ///
    /// The generic `.heading` type returns `nil` since it has no specific level.
    public var headingLevel: Int? {
        switch self {
        case .h1: return 1
        case .h2: return 2
        case .h3: return 3
        case .h4: return 4
        case .h5: return 5
        case .h6: return 6
        default: return nil
        }
    }

    /// Whether this element type is a table component (Table, TR, TH, TD, etc.).
    public var isTableElement: Bool {
        category == .table
    }

    /// Whether this element type is a list component (L, LI, Lbl, LBody).
    public var isListElement: Bool {
        category == .list
    }

    /// Whether this element type is an inline element.
    public var isInline: Bool {
        category == .inline
    }

    /// Whether this element type is a block-level element.
    public var isBlockLevel: Bool {
        category == .blockLevel || category == .documentStructure
    }

    /// Whether this element type typically requires alternative text for accessibility.
    ///
    /// Figures require alt text, as do formulas in most accessibility guidelines.
    public var requiresAltText: Bool {
        switch self {
        case .figure, .formula:
            return true
        default:
            return false
        }
    }

    /// Whether this element type is a grouping element.
    ///
    /// Grouping elements define the structure of the document but do not
    /// directly contain text content.
    public var isGrouping: Bool {
        switch self {
        case .document, .documentFragment, .part, .sect, .div, .aside,
             .nonStruct, .list, .listItem, .table, .tableRow,
             .tableHead, .tableBody, .tableFoot, .ruby, .warichu,
             .toc, .toci:
            return true
        default:
            return false
        }
    }

    /// Whether this element type is an artifact (non-structural content).
    public var isArtifact: Bool {
        self == .artifact
    }

    /// Whether this element type was introduced in PDF 2.0.
    public var isPDF2Only: Bool {
        switch self {
        case .documentFragment, .aside, .caption, .feNote, .em, .strong, .sub, .title:
            return true
        default:
            return false
        }
    }

    /// Whether this element type is a content element (carries or contains text/images).
    public var isContent: Bool {
        switch self {
        case .paragraph, .heading, .h1, .h2, .h3, .h4, .h5, .h6,
             .blockQuote, .caption, .span, .quote, .note, .reference,
             .bibEntry, .code, .link, .annot, .figure, .formula, .form,
             .label, .listBody, .tableHeader, .tableData, .rb, .rt,
             .rp, .wt, .wp, .feNote, .em, .strong, .sub, .title:
            return true
        default:
            return false
        }
    }
}

// MARK: - Initialization Helpers

extension StructureElementType {

    /// Creates a structure element type from a string, returning `nil` if the string
    /// does not match any known type.
    ///
    /// This is equivalent to `init(rawValue:)` but provided for clarity.
    ///
    /// - Parameter name: The structure type name (e.g., "P", "H1", "Table").
    /// - Returns: The matching structure element type, or `nil`.
    public static func from(name: String) -> StructureElementType? {
        StructureElementType(rawValue: name)
    }

    /// Returns all heading types (H, H1-H6).
    public static var allHeadings: [StructureElementType] {
        [.heading, .h1, .h2, .h3, .h4, .h5, .h6]
    }

    /// Returns all table-related types.
    public static var allTableTypes: [StructureElementType] {
        [.table, .tableRow, .tableHeader, .tableData, .tableHead, .tableBody, .tableFoot]
    }

    /// Returns all list-related types.
    public static var allListTypes: [StructureElementType] {
        [.list, .listItem, .label, .listBody]
    }

    /// Returns all inline types.
    public static var allInlineTypes: [StructureElementType] {
        [.span, .quote, .note, .reference, .bibEntry, .code, .link, .annot]
    }

    /// Returns all types introduced in PDF 2.0.
    public static var pdf2Types: [StructureElementType] {
        allCases.filter(\.isPDF2Only)
    }
}

// MARK: - CustomStringConvertible

extension StructureElementType: CustomStringConvertible {

    /// A human-readable description of this structure element type.
    public var description: String {
        rawValue
    }
}
