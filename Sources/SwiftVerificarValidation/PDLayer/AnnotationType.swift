import Foundation

// MARK: - Annotation Type

/// Enumeration of PDF annotation types for validation purposes.
///
/// This enum categorizes the standard annotation types defined in the PDF specification
/// (ISO 32000-1, ISO 32000-2). It provides a type-safe way to identify annotation
/// subtypes during validation, particularly for PDF/A and PDF/UA conformance checking.
///
/// ## Categories
///
/// Annotation types are organized into several categories:
/// - **Markup**: Text, FreeText, Line, Square, Circle, Polygon, PolyLine, Highlight,
///   Underline, Squiggly, StrikeOut, Stamp, Caret, Ink
/// - **Interactive**: Link, Widget, Screen
/// - **Document**: FileAttachment, Sound, Movie, RichMedia, Popup
/// - **Print**: PrinterMark, TrapNet, Watermark
/// - **3D**: ThreeD
///
/// ## Relationship to veraPDF
///
/// Corresponds to the 15+ annotation subtype classes in veraPDF-validation
/// (`GFPDAnnot`, `GFPDLinkAnnot`, `GFPDWidgetAnnot`, etc.), consolidated
/// into a single enum. The raw value matches the annotation subtype name as it appears
/// in the PDF `/Subtype` entry.
///
/// ## Usage
///
/// ```swift
/// let type = AnnotationType(rawValue: "Link") // .link
/// let isMarkup = AnnotationType.highlight.isMarkup
/// ```
public enum AnnotationType: String, Sendable, Hashable, CaseIterable, Codable {

    // MARK: - Markup Annotations

    /// A text annotation (sticky note).
    case text = "Text"

    /// A free text annotation (text directly on the page).
    case freeText = "FreeText"

    /// A line annotation.
    case line = "Line"

    /// A square annotation (rectangle).
    case square = "Square"

    /// A circle annotation (ellipse).
    case circle = "Circle"

    /// A polygon annotation.
    case polygon = "Polygon"

    /// A polyline annotation.
    case polyLine = "PolyLine"

    /// A highlight markup annotation.
    case highlight = "Highlight"

    /// An underline markup annotation.
    case underline = "Underline"

    /// A squiggly underline markup annotation.
    case squiggly = "Squiggly"

    /// A strikeout markup annotation.
    case strikeOut = "StrikeOut"

    /// A rubber stamp annotation.
    case stamp = "Stamp"

    /// A caret annotation (insertion point indicator).
    case caret = "Caret"

    /// An ink (freehand) annotation.
    case ink = "Ink"

    // MARK: - Interactive Annotations

    /// A link annotation (hyperlink or destination).
    case link = "Link"

    /// A widget annotation (interactive form field).
    case widget = "Widget"

    /// A screen annotation (multimedia content).
    case screen = "Screen"

    // MARK: - Document Annotations

    /// A popup annotation (associated with markup annotations).
    case popup = "Popup"

    /// A file attachment annotation.
    case fileAttachment = "FileAttachment"

    /// A sound annotation.
    case sound = "Sound"

    /// A movie annotation.
    case movie = "Movie"

    /// A rich media annotation (PDF 2.0).
    case richMedia = "RichMedia"

    // MARK: - Print Annotations

    /// A printer's mark annotation (registration targets, color bars, etc.).
    case printerMark = "PrinterMark"

    /// A trap network annotation.
    case trapNet = "TrapNet"

    /// A watermark annotation (PDF 1.6+).
    case watermark = "Watermark"

    // MARK: - 3D Annotations

    /// A 3D annotation (3D artwork).
    case threeD = "3D"

    // MARK: - Redaction

    /// A redaction annotation (PDF 2.0).
    case redact = "Redact"

    // MARK: - Projection

    /// A projection annotation (PDF 2.0).
    case projection = "Projection"
}

// MARK: - Category Classification

extension AnnotationType {

    /// The category this annotation type belongs to.
    public var category: Category {
        switch self {
        case .text, .freeText, .line, .square, .circle, .polygon, .polyLine,
             .highlight, .underline, .squiggly, .strikeOut, .stamp, .caret, .ink:
            return .markup
        case .link, .widget, .screen:
            return .interactive
        case .popup, .fileAttachment, .sound, .movie, .richMedia:
            return .document
        case .printerMark, .trapNet, .watermark:
            return .print
        case .threeD:
            return .threeD
        case .redact:
            return .markup
        case .projection:
            return .document
        }
    }

    /// Categories of annotation types.
    public enum Category: String, Sendable, Hashable, CaseIterable, Codable {
        /// Markup annotations that add visual content.
        case markup

        /// Interactive annotations for navigation and form interaction.
        case interactive

        /// Document-level annotations (attachments, multimedia, popups).
        case document

        /// Print-related annotations (printer marks, trap networks, watermarks).
        case print

        /// 3D annotations.
        case threeD
    }
}

// MARK: - Semantic Properties

extension AnnotationType {

    /// Whether this annotation type is a text markup annotation.
    ///
    /// Text markup annotations visually mark up text content
    /// (highlight, underline, squiggly, strikeout).
    public var isTextMarkup: Bool {
        switch self {
        case .highlight, .underline, .squiggly, .strikeOut:
            return true
        default:
            return false
        }
    }

    /// Whether this annotation type is a markup annotation.
    ///
    /// Markup annotations are visual annotations that add content
    /// to the page (text notes, shapes, stamps, ink, etc.).
    public var isMarkup: Bool {
        category == .markup
    }

    /// Whether this annotation type is interactive.
    ///
    /// Interactive annotations respond to user input (links, widgets, screens).
    public var isInteractive: Bool {
        category == .interactive
    }

    /// Whether this annotation type is a form widget.
    public var isWidget: Bool {
        self == .widget
    }

    /// Whether this annotation type is a link.
    public var isLink: Bool {
        self == .link
    }

    /// Whether this annotation type is a popup.
    public var isPopup: Bool {
        self == .popup
    }

    /// Whether this annotation type requires an appearance stream for PDF/A conformance.
    ///
    /// PDF/A requires that most annotation types have an appearance stream (`/AP` entry)
    /// to ensure consistent rendering. The exceptions are popup annotations and
    /// printer marks.
    public var requiresAppearanceStream: Bool {
        switch self {
        case .popup, .printerMark:
            return false
        default:
            return true
        }
    }

    /// Whether this annotation type is relevant for accessibility validation.
    ///
    /// Link and widget annotations require accessible alternatives in PDF/UA.
    /// Text annotations should have proper alt text or contents.
    public var isAccessibilityRelevant: Bool {
        switch self {
        case .link, .widget, .screen, .text, .fileAttachment:
            return true
        default:
            return false
        }
    }

    /// Whether this annotation type may contain multimedia content.
    public var isMultimedia: Bool {
        switch self {
        case .sound, .movie, .richMedia, .screen:
            return true
        default:
            return false
        }
    }

    /// Whether this annotation type was introduced in PDF 2.0.
    public var isPDF2Only: Bool {
        switch self {
        case .richMedia, .redact, .projection:
            return true
        default:
            return false
        }
    }

    /// Whether this annotation type is typically visible on screen.
    ///
    /// Most annotations are visible, but some (like popup, printerMark, trapNet)
    /// may not be displayed in all viewing contexts.
    public var isTypicallyVisible: Bool {
        switch self {
        case .popup, .printerMark, .trapNet:
            return false
        default:
            return true
        }
    }
}

// MARK: - Initialization Helpers

extension AnnotationType {

    /// Creates an annotation type from a subtype string, returning `nil` if the string
    /// does not match any known type.
    ///
    /// - Parameter subtype: The annotation subtype name (e.g., "Link", "Widget").
    /// - Returns: The matching annotation type, or `nil`.
    public static func from(subtype: String) -> AnnotationType? {
        AnnotationType(rawValue: subtype)
    }

    /// Returns all markup annotation types.
    public static var allMarkupTypes: [AnnotationType] {
        allCases.filter(\.isMarkup)
    }

    /// Returns all text markup annotation types.
    public static var allTextMarkupTypes: [AnnotationType] {
        [.highlight, .underline, .squiggly, .strikeOut]
    }

    /// Returns all interactive annotation types.
    public static var allInteractiveTypes: [AnnotationType] {
        [.link, .widget, .screen]
    }

    /// Returns all annotation types that require appearance streams for PDF/A.
    public static var typesRequiringAppearanceStream: [AnnotationType] {
        allCases.filter(\.requiresAppearanceStream)
    }
}

// MARK: - CustomStringConvertible

extension AnnotationType: CustomStringConvertible {

    /// A human-readable description of this annotation type.
    public var description: String {
        rawValue
    }
}
