import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Appearance Streams

/// Represents the appearance streams for an annotation.
///
/// PDF annotations can have three appearance streams:
/// - **Normal**: The default appearance.
/// - **Rollover**: Displayed when the user hovers over the annotation.
/// - **Down**: Displayed when the annotation is activated (clicked).
///
/// Each appearance may have sub-appearances keyed by appearance state name.
public struct AppearanceStreams: Sendable, Equatable {

    /// Whether a normal appearance stream is present.
    public let hasNormalAppearance: Bool

    /// Whether a rollover appearance stream is present.
    public let hasRolloverAppearance: Bool

    /// Whether a down appearance stream is present.
    public let hasDownAppearance: Bool

    /// The number of normal appearance sub-appearances.
    public let normalAppearanceCount: Int

    /// The number of rollover appearance sub-appearances.
    public let rolloverAppearanceCount: Int

    /// The number of down appearance sub-appearances.
    public let downAppearanceCount: Int

    /// Creates appearance streams information.
    ///
    /// - Parameters:
    ///   - hasNormalAppearance: Whether the normal appearance exists.
    ///   - hasRolloverAppearance: Whether the rollover appearance exists.
    ///   - hasDownAppearance: Whether the down appearance exists.
    ///   - normalAppearanceCount: Number of normal sub-appearances.
    ///   - rolloverAppearanceCount: Number of rollover sub-appearances.
    ///   - downAppearanceCount: Number of down sub-appearances.
    public init(
        hasNormalAppearance: Bool = false,
        hasRolloverAppearance: Bool = false,
        hasDownAppearance: Bool = false,
        normalAppearanceCount: Int = 0,
        rolloverAppearanceCount: Int = 0,
        downAppearanceCount: Int = 0
    ) {
        self.hasNormalAppearance = hasNormalAppearance
        self.hasRolloverAppearance = hasRolloverAppearance
        self.hasDownAppearance = hasDownAppearance
        self.normalAppearanceCount = normalAppearanceCount
        self.rolloverAppearanceCount = rolloverAppearanceCount
        self.downAppearanceCount = downAppearanceCount
    }

    /// Whether any appearance stream is present.
    public var hasAnyAppearance: Bool {
        hasNormalAppearance || hasRolloverAppearance || hasDownAppearance
    }
}

// MARK: - Annotation Flags

/// Bitwise flags for annotation properties.
///
/// Corresponds to the `/F` (Flags) entry in an annotation dictionary.
/// See PDF specification Table 165 -- Annotation flags.
public struct AnnotationFlags: OptionSet, Sendable, Hashable {

    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// The annotation is invisible (not displayed if no AP).
    public static let invisible = AnnotationFlags(rawValue: 1 << 0)

    /// The annotation is hidden (not displayed or printed).
    public static let hidden = AnnotationFlags(rawValue: 1 << 1)

    /// The annotation is printed when the page is printed.
    public static let print = AnnotationFlags(rawValue: 1 << 2)

    /// The annotation is not zoomed with the page.
    public static let noZoom = AnnotationFlags(rawValue: 1 << 3)

    /// The annotation is not rotated with the page.
    public static let noRotate = AnnotationFlags(rawValue: 1 << 4)

    /// The annotation is not displayed interactively.
    public static let noView = AnnotationFlags(rawValue: 1 << 5)

    /// The annotation is read-only (cannot be modified interactively).
    public static let readOnly = AnnotationFlags(rawValue: 1 << 6)

    /// The annotation is locked (cannot be deleted or properties changed).
    public static let locked = AnnotationFlags(rawValue: 1 << 7)

    /// The annotation's appearance should be toggled on mouse hover.
    public static let toggleNoView = AnnotationFlags(rawValue: 1 << 8)

    /// The annotation's content is locked (cannot be changed).
    public static let lockedContents = AnnotationFlags(rawValue: 1 << 9)
}

// MARK: - Validated Annotation

/// A validation wrapper for a PDF annotation.
///
/// This struct provides access to annotation properties for PDF/A, PDF/UA,
/// and other conformance validation. It wraps the parsed PDF annotation dictionary
/// and exposes its components in a validation-friendly manner.
///
/// ## Key Properties
///
/// - **Type**: The annotation subtype (link, widget, text, popup, etc.)
/// - **Rect**: The annotation rectangle on the page
/// - **Appearance**: Appearance streams for rendering
/// - **Contents**: Text content for the annotation
/// - **Flags**: Annotation behavior flags
///
/// ## Validation Rules
///
/// - **PDF/A**: All annotations (except popup and printer marks) must have
///   appearance streams.
/// - **PDF/UA**: Link and widget annotations must be accessible (tagged,
///   with contents or alt text).
/// - **PDF/A-1**: Certain annotation types (Sound, Movie, 3D) are prohibited.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDAnnot` (and its subclasses `GFPDLinkAnnot`,
/// `GFPDWidgetAnnot`, `GFPDPopupAnnot`, etc.) from veraPDF-validation.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent validation
/// - Uses `AnnotationType` enum instead of class hierarchy
public struct ValidatedAnnotation: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the annotation.
    public let cosDictionary: COSValue?

    /// The object key for the annotation, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Annotation Type

    /// The annotation subtype as a string.
    ///
    /// This is the raw `/Subtype` value from the annotation dictionary.
    public let subtypeName: String

    /// The parsed annotation type, or `nil` if the subtype is non-standard.
    public let annotationType: AnnotationType?

    // MARK: - Annotation Rectangle

    /// The annotation rectangle on the page (in default user space).
    ///
    /// This defines the location and size of the annotation on the page.
    public let rect: PDFRect

    // MARK: - Content Properties

    /// The text content of the annotation (`/Contents` entry).
    ///
    /// For text annotations, this is the note text. For link annotations,
    /// this may provide an accessible description.
    public let contents: String?

    /// The annotation name (`/NM` entry), a unique text identifier.
    public let annotationName: String?

    /// The modification date of the annotation (`/M` entry).
    public let modificationDate: String?

    // MARK: - Appearance

    /// The appearance streams for this annotation.
    public let appearanceStreams: AppearanceStreams

    /// The current appearance state name (`/AS` entry).
    public let appearanceState: String?

    // MARK: - Flags and Behavior

    /// The annotation flags (`/F` entry).
    public let flags: AnnotationFlags

    /// The page number this annotation appears on (1-based).
    public let pageNumber: Int

    // MARK: - Border Properties

    /// Whether the annotation has a border style (`/BS` entry).
    public let hasBorderStyle: Bool

    /// The border width, if a border style is present.
    public let borderWidth: Double?

    // MARK: - Color

    /// Whether the annotation has a color (`/C` entry).
    public let hasColor: Bool

    /// The number of color components in the color array.
    public let colorComponentCount: Int

    // MARK: - Link-Specific Properties

    /// The action associated with a link annotation (`/A` entry).
    public let hasAction: Bool

    /// The destination for a link annotation (`/Dest` entry).
    public let hasDestination: Bool

    /// The action type, if an action is present.
    public let actionType: String?

    // MARK: - Widget-Specific Properties

    /// The field type for widget annotations (`/FT` entry).
    public let fieldType: String?

    /// The field name for widget annotations (`/T` entry).
    public let fieldName: String?

    /// The field value for widget annotations (`/V` entry).
    public let hasFieldValue: Bool

    /// The default value for widget annotations (`/DV` entry).
    public let hasDefaultValue: Bool

    // MARK: - Popup Properties

    /// Whether this annotation has an associated popup (`/Popup` entry).
    public let hasPopup: Bool

    /// Whether this annotation is open (for popup and text annotations).
    public let isOpen: Bool

    // MARK: - Structure

    /// The structure parent key (`/StructParent` entry), for tagged PDF.
    public let structParent: Int?

    /// Whether the annotation is associated with a structure element.
    public var hasStructParent: Bool {
        structParent != nil
    }

    // MARK: - Initialization

    /// Creates a validated annotation.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the annotation.
    ///   - objectKey: The object key for the annotation.
    ///   - context: Validation context.
    ///   - subtypeName: The annotation subtype string.
    ///   - annotationType: The parsed annotation type.
    ///   - rect: The annotation rectangle.
    ///   - contents: The text content.
    ///   - annotationName: The annotation unique name.
    ///   - modificationDate: The modification date string.
    ///   - appearanceStreams: The appearance streams.
    ///   - appearanceState: The current appearance state.
    ///   - flags: The annotation flags.
    ///   - pageNumber: The page number (1-based).
    ///   - hasBorderStyle: Whether a border style exists.
    ///   - borderWidth: The border width.
    ///   - hasColor: Whether a color is set.
    ///   - colorComponentCount: Number of color components.
    ///   - hasAction: Whether an action exists.
    ///   - hasDestination: Whether a destination exists.
    ///   - actionType: The action type string.
    ///   - fieldType: The widget field type.
    ///   - fieldName: The widget field name.
    ///   - hasFieldValue: Whether a field value exists.
    ///   - hasDefaultValue: Whether a default value exists.
    ///   - hasPopup: Whether an associated popup exists.
    ///   - isOpen: Whether the annotation is open.
    ///   - structParent: The structure parent index.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        subtypeName: String,
        annotationType: AnnotationType? = nil,
        rect: PDFRect = PDFRect(x: 0, y: 0, width: 0, height: 0),
        contents: String? = nil,
        annotationName: String? = nil,
        modificationDate: String? = nil,
        appearanceStreams: AppearanceStreams = AppearanceStreams(),
        appearanceState: String? = nil,
        flags: AnnotationFlags = [],
        pageNumber: Int = 1,
        hasBorderStyle: Bool = false,
        borderWidth: Double? = nil,
        hasColor: Bool = false,
        colorComponentCount: Int = 0,
        hasAction: Bool = false,
        hasDestination: Bool = false,
        actionType: String? = nil,
        fieldType: String? = nil,
        fieldName: String? = nil,
        hasFieldValue: Bool = false,
        hasDefaultValue: Bool = false,
        hasPopup: Bool = false,
        isOpen: Bool = false,
        structParent: Int? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .annotation(page: pageNumber, type: subtypeName)
        self.subtypeName = subtypeName
        self.annotationType = annotationType ?? AnnotationType(rawValue: subtypeName)
        self.rect = rect
        self.contents = contents
        self.annotationName = annotationName
        self.modificationDate = modificationDate
        self.appearanceStreams = appearanceStreams
        self.appearanceState = appearanceState
        self.flags = flags
        self.pageNumber = pageNumber
        self.hasBorderStyle = hasBorderStyle
        self.borderWidth = borderWidth
        self.hasColor = hasColor
        self.colorComponentCount = colorComponentCount
        self.hasAction = hasAction
        self.hasDestination = hasDestination
        self.actionType = actionType
        self.fieldType = fieldType
        self.fieldName = fieldName
        self.hasFieldValue = hasFieldValue
        self.hasDefaultValue = hasDefaultValue
        self.hasPopup = hasPopup
        self.isOpen = isOpen
        self.structParent = structParent
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDAnnot"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "subtypeName", "annotationType", "rect",
            "contents", "annotationName", "modificationDate",
            "hasNormalAppearance", "hasRolloverAppearance", "hasDownAppearance",
            "hasAnyAppearance", "appearanceState",
            "flags", "pageNumber",
            "isHidden", "isPrintable", "isReadOnly", "isLocked",
            "isInvisible", "isNoView",
            "hasBorderStyle", "borderWidth",
            "hasColor", "colorComponentCount",
            "hasAction", "hasDestination", "actionType",
            "fieldType", "fieldName", "hasFieldValue", "hasDefaultValue",
            "hasPopup", "isOpen",
            "structParent", "hasStructParent",
            "hasContents", "isVisible",
            "requiresAppearanceStream", "meetsAppearanceRequirement"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "subtypeName":
            return .string(subtypeName)
        case "annotationType":
            if let at = annotationType {
                return .string(at.rawValue)
            }
            return .null
        case "rect":
            return .string(rect.description)
        case "contents":
            if let c = contents {
                return .string(c)
            }
            return .null
        case "annotationName":
            if let n = annotationName {
                return .string(n)
            }
            return .null
        case "modificationDate":
            if let d = modificationDate {
                return .string(d)
            }
            return .null
        case "hasNormalAppearance":
            return .boolean(appearanceStreams.hasNormalAppearance)
        case "hasRolloverAppearance":
            return .boolean(appearanceStreams.hasRolloverAppearance)
        case "hasDownAppearance":
            return .boolean(appearanceStreams.hasDownAppearance)
        case "hasAnyAppearance":
            return .boolean(appearanceStreams.hasAnyAppearance)
        case "appearanceState":
            if let s = appearanceState {
                return .string(s)
            }
            return .null
        case "flags":
            return .integer(Int64(flags.rawValue))
        case "pageNumber":
            return .integer(Int64(pageNumber))
        case "isHidden":
            return .boolean(isHidden)
        case "isPrintable":
            return .boolean(isPrintable)
        case "isReadOnly":
            return .boolean(isReadOnly)
        case "isLocked":
            return .boolean(isLocked)
        case "isInvisible":
            return .boolean(isInvisible)
        case "isNoView":
            return .boolean(isNoView)
        case "hasBorderStyle":
            return .boolean(hasBorderStyle)
        case "borderWidth":
            if let w = borderWidth {
                return .real(w)
            }
            return .null
        case "hasColor":
            return .boolean(hasColor)
        case "colorComponentCount":
            return .integer(Int64(colorComponentCount))
        case "hasAction":
            return .boolean(hasAction)
        case "hasDestination":
            return .boolean(hasDestination)
        case "actionType":
            if let t = actionType {
                return .string(t)
            }
            return .null
        case "fieldType":
            if let ft = fieldType {
                return .string(ft)
            }
            return .null
        case "fieldName":
            if let fn = fieldName {
                return .string(fn)
            }
            return .null
        case "hasFieldValue":
            return .boolean(hasFieldValue)
        case "hasDefaultValue":
            return .boolean(hasDefaultValue)
        case "hasPopup":
            return .boolean(hasPopup)
        case "isOpen":
            return .boolean(isOpen)
        case "structParent":
            if let sp = structParent {
                return .integer(Int64(sp))
            }
            return .null
        case "hasStructParent":
            return .boolean(hasStructParent)
        case "hasContents":
            return .boolean(hasContents)
        case "isVisible":
            return .boolean(isVisible)
        case "requiresAppearanceStream":
            return .boolean(requiresAppearanceStream)
        case "meetsAppearanceRequirement":
            return .boolean(meetsAppearanceRequirement)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedAnnotation, rhs: ValidatedAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedAnnotation {

    /// Whether the annotation has text contents.
    public var hasContents: Bool {
        if let c = contents {
            return !c.isEmpty
        }
        return false
    }

    /// Whether the annotation is hidden (Hidden flag set).
    public var isHidden: Bool {
        flags.contains(.hidden)
    }

    /// Whether the annotation is printable (Print flag set).
    public var isPrintable: Bool {
        flags.contains(.print)
    }

    /// Whether the annotation is read-only (ReadOnly flag set).
    public var isReadOnly: Bool {
        flags.contains(.readOnly)
    }

    /// Whether the annotation is locked (Locked flag set).
    public var isLocked: Bool {
        flags.contains(.locked)
    }

    /// Whether the annotation is invisible (Invisible flag set).
    public var isInvisible: Bool {
        flags.contains(.invisible)
    }

    /// Whether the annotation is NoView (NoView flag set).
    public var isNoView: Bool {
        flags.contains(.noView)
    }

    /// Whether the annotation is visible on screen.
    ///
    /// An annotation is visible if it is not hidden and not NoView.
    public var isVisible: Bool {
        !isHidden && !isNoView
    }

    /// Whether this annotation type requires an appearance stream for PDF/A.
    public var requiresAppearanceStream: Bool {
        annotationType?.requiresAppearanceStream ?? true
    }

    /// Whether the annotation meets the PDF/A appearance requirement.
    ///
    /// Returns `true` if the annotation either does not require an appearance
    /// stream or has a normal appearance stream.
    public var meetsAppearanceRequirement: Bool {
        if !requiresAppearanceStream {
            return true
        }
        return appearanceStreams.hasNormalAppearance
    }

    /// Whether the annotation has a zero-size rectangle.
    ///
    /// Annotations with zero-size rectangles are effectively invisible.
    public var hasZeroSizeRect: Bool {
        rect.width == 0 || rect.height == 0
    }

    /// Whether the annotation is a link annotation.
    public var isLinkAnnotation: Bool {
        annotationType == .link
    }

    /// Whether the annotation is a widget (form field) annotation.
    public var isWidgetAnnotation: Bool {
        annotationType == .widget
    }

    /// Whether the annotation is a popup annotation.
    public var isPopupAnnotation: Bool {
        annotationType == .popup
    }

    /// Whether the annotation is a markup annotation.
    public var isMarkupAnnotation: Bool {
        annotationType?.isMarkup ?? false
    }

    /// Returns a summary string describing the annotation.
    public var summary: String {
        var parts: [String] = [subtypeName]
        parts.append("page \(pageNumber)")
        if hasContents { parts.append("has contents") }
        if appearanceStreams.hasNormalAppearance { parts.append("has AP") }
        if let fn = fieldName { parts.append("field=\(fn)") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedAnnotation {

    /// Creates a minimal link annotation for testing.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number.
    ///   - contents: Optional contents text.
    ///   - hasDestination: Whether a destination is present.
    ///   - structParent: Optional structure parent index.
    /// - Returns: A minimal link annotation.
    public static func link(
        pageNumber: Int = 1,
        contents: String? = nil,
        hasDestination: Bool = true,
        structParent: Int? = nil
    ) -> ValidatedAnnotation {
        ValidatedAnnotation(
            subtypeName: "Link",
            contents: contents,
            appearanceStreams: AppearanceStreams(hasNormalAppearance: true),
            flags: [.print],
            pageNumber: pageNumber,
            hasDestination: hasDestination,
            structParent: structParent
        )
    }

    /// Creates a minimal widget annotation for testing.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number.
    ///   - fieldType: The form field type (e.g., "Tx", "Btn", "Ch").
    ///   - fieldName: The field name.
    /// - Returns: A minimal widget annotation.
    public static func widget(
        pageNumber: Int = 1,
        fieldType: String = "Tx",
        fieldName: String? = nil
    ) -> ValidatedAnnotation {
        ValidatedAnnotation(
            subtypeName: "Widget",
            appearanceStreams: AppearanceStreams(hasNormalAppearance: true),
            flags: [.print],
            pageNumber: pageNumber,
            fieldType: fieldType,
            fieldName: fieldName
        )
    }

    /// Creates a minimal text (sticky note) annotation for testing.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number.
    ///   - contents: The note text.
    /// - Returns: A minimal text annotation.
    public static func textNote(
        pageNumber: Int = 1,
        contents: String = ""
    ) -> ValidatedAnnotation {
        ValidatedAnnotation(
            subtypeName: "Text",
            contents: contents,
            appearanceStreams: AppearanceStreams(hasNormalAppearance: true),
            pageNumber: pageNumber
        )
    }
}
