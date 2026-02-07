import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Validated Page

/// A validation wrapper for a PDF page.
///
/// This struct provides access to page-level properties and resources for
/// validation. It wraps a parsed PDF page dictionary and exposes its components
/// in a validation-friendly manner.
///
/// ## Key Properties
///
/// - **Dimensions**: MediaBox, CropBox, BleedBox, TrimBox, ArtBox
/// - **Resources**: Fonts, XObjects, ColorSpaces, ExtGStates, Patterns, Shadings
/// - **Content**: Content streams and operators
/// - **Annotations**: Page annotations
/// - **Structure**: Tagged content markers
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDPage` from veraPDF-validation.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent validation
/// - Implements ResourceResolver for resource lookup
public struct ValidatedPage: PDValidationObject, ResourceResolver, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the page.
    public let cosDictionary: COSValue?

    /// The object key for the page, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Page Identification

    /// The page number (1-based).
    public let pageNumber: Int

    /// The page label, if defined.
    public let pageLabel: String?

    // MARK: - Page Boxes (Dimensions)

    /// The MediaBox (required) -- page boundaries in default user space.
    public let mediaBox: PDFRect

    /// The CropBox (optional) -- visible area after cropping.
    public let cropBox: PDFRect?

    /// The BleedBox (optional) -- clipping boundary for production.
    public let bleedBox: PDFRect?

    /// The TrimBox (optional) -- intended finished page dimensions.
    public let trimBox: PDFRect?

    /// The ArtBox (optional) -- extent of meaningful content.
    public let artBox: PDFRect?

    // MARK: - Page Properties

    /// Page rotation in degrees (0, 90, 180, or 270).
    public let rotation: Int

    /// User unit scaling factor (PDF 1.6+).
    public let userUnit: Double

    /// Whether the page has a Resources dictionary.
    public let hasResources: Bool

    /// Whether the page has content streams.
    public let hasContentStreams: Bool

    /// Whether the page has annotations.
    public let hasAnnotations: Bool

    // MARK: - Resource Counts

    /// Number of font resources on this page.
    public let fontCount: Int

    /// Number of XObject resources on this page.
    public let xObjectCount: Int

    /// Number of color space resources on this page.
    public let colorSpaceCount: Int

    /// Number of extended graphics state resources on this page.
    public let extGStateCount: Int

    /// Number of pattern resources on this page.
    public let patternCount: Int

    /// Number of shading resources on this page.
    public let shadingCount: Int

    /// Number of annotations on this page.
    public let annotationCount: Int

    // MARK: - Resource Dictionaries

    /// The font resource dictionary entries (name -> COS value).
    public let fontResources: [ASAtom: COSValue]

    /// The XObject resource dictionary entries.
    public let xObjectResources: [ASAtom: COSValue]

    /// The color space resource dictionary entries.
    public let colorSpaceResources: [ASAtom: COSValue]

    /// The extended graphics state resource dictionary entries.
    public let extGStateResources: [ASAtom: COSValue]

    /// The pattern resource dictionary entries.
    public let patternResources: [ASAtom: COSValue]

    /// The shading resource dictionary entries.
    public let shadingResources: [ASAtom: COSValue]

    /// The properties resource dictionary entries.
    public let propertiesResources: [ASAtom: COSValue]

    // MARK: - Content Streams

    /// The content streams on this page.
    public let contentStreams: [ValidatedContentStream]

    // MARK: - Transparency

    /// Whether the page uses transparency (Group with /S /Transparency).
    public let hasTransparencyGroup: Bool

    /// The transparency group color space, if any.
    public let transparencyGroupColorSpace: ASAtom?

    // MARK: - Initialization

    /// Creates a validated page.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - cosDictionary: The COS dictionary for the page.
    ///   - objectKey: The object key for the page.
    ///   - context: Validation context.
    ///   - pageNumber: The page number (1-based).
    ///   - pageLabel: The page label, if any.
    ///   - mediaBox: The MediaBox rectangle.
    ///   - cropBox: The CropBox rectangle, if any.
    ///   - bleedBox: The BleedBox rectangle, if any.
    ///   - trimBox: The TrimBox rectangle, if any.
    ///   - artBox: The ArtBox rectangle, if any.
    ///   - rotation: Page rotation in degrees.
    ///   - userUnit: User unit scaling factor.
    ///   - hasResources: Whether the page has a Resources dictionary.
    ///   - hasContentStreams: Whether the page has content streams.
    ///   - hasAnnotations: Whether the page has annotations.
    ///   - fontCount: Number of font resources.
    ///   - xObjectCount: Number of XObject resources.
    ///   - colorSpaceCount: Number of color space resources.
    ///   - extGStateCount: Number of ExtGState resources.
    ///   - patternCount: Number of pattern resources.
    ///   - shadingCount: Number of shading resources.
    ///   - annotationCount: Number of annotations.
    ///   - fontResources: Font resource dictionary.
    ///   - xObjectResources: XObject resource dictionary.
    ///   - colorSpaceResources: Color space resource dictionary.
    ///   - extGStateResources: ExtGState resource dictionary.
    ///   - patternResources: Pattern resource dictionary.
    ///   - shadingResources: Shading resource dictionary.
    ///   - propertiesResources: Properties resource dictionary.
    ///   - contentStreams: Content streams on this page.
    ///   - hasTransparencyGroup: Whether the page has a transparency group.
    ///   - transparencyGroupColorSpace: Transparency group color space.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        pageNumber: Int = 1,
        pageLabel: String? = nil,
        mediaBox: PDFRect = .letter,
        cropBox: PDFRect? = nil,
        bleedBox: PDFRect? = nil,
        trimBox: PDFRect? = nil,
        artBox: PDFRect? = nil,
        rotation: Int = 0,
        userUnit: Double = 1.0,
        hasResources: Bool = true,
        hasContentStreams: Bool = false,
        hasAnnotations: Bool = false,
        fontCount: Int = 0,
        xObjectCount: Int = 0,
        colorSpaceCount: Int = 0,
        extGStateCount: Int = 0,
        patternCount: Int = 0,
        shadingCount: Int = 0,
        annotationCount: Int = 0,
        fontResources: [ASAtom: COSValue] = [:],
        xObjectResources: [ASAtom: COSValue] = [:],
        colorSpaceResources: [ASAtom: COSValue] = [:],
        extGStateResources: [ASAtom: COSValue] = [:],
        patternResources: [ASAtom: COSValue] = [:],
        shadingResources: [ASAtom: COSValue] = [:],
        propertiesResources: [ASAtom: COSValue] = [:],
        contentStreams: [ValidatedContentStream] = [],
        hasTransparencyGroup: Bool = false,
        transparencyGroupColorSpace: ASAtom? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .page(pageNumber)
        self.pageNumber = pageNumber
        self.pageLabel = pageLabel
        self.mediaBox = mediaBox
        self.cropBox = cropBox
        self.bleedBox = bleedBox
        self.trimBox = trimBox
        self.artBox = artBox
        self.rotation = rotation
        self.userUnit = userUnit
        self.hasResources = hasResources
        self.hasContentStreams = hasContentStreams
        self.hasAnnotations = hasAnnotations
        self.fontCount = fontCount
        self.xObjectCount = xObjectCount
        self.colorSpaceCount = colorSpaceCount
        self.extGStateCount = extGStateCount
        self.patternCount = patternCount
        self.shadingCount = shadingCount
        self.annotationCount = annotationCount
        self.fontResources = fontResources
        self.xObjectResources = xObjectResources
        self.colorSpaceResources = colorSpaceResources
        self.extGStateResources = extGStateResources
        self.patternResources = patternResources
        self.shadingResources = shadingResources
        self.propertiesResources = propertiesResources
        self.contentStreams = contentStreams
        self.hasTransparencyGroup = hasTransparencyGroup
        self.transparencyGroupColorSpace = transparencyGroupColorSpace
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDPage"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "pageNumber", "pageLabel",
            "mediaBox", "cropBox", "bleedBox", "trimBox", "artBox",
            "rotation", "userUnit",
            "hasResources", "hasContentStreams", "hasAnnotations",
            "fontCount", "xObjectCount", "colorSpaceCount",
            "extGStateCount", "patternCount", "shadingCount",
            "annotationCount", "hasTransparencyGroup",
            "transparencyGroupColorSpace"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "pageNumber":
            return .integer(Int64(pageNumber))
        case "pageLabel":
            if let label = pageLabel {
                return .string(label)
            }
            return .null
        case "mediaBox":
            return .string(mediaBox.description)
        case "cropBox":
            if let box = cropBox {
                return .string(box.description)
            }
            return .null
        case "bleedBox":
            if let box = bleedBox {
                return .string(box.description)
            }
            return .null
        case "trimBox":
            if let box = trimBox {
                return .string(box.description)
            }
            return .null
        case "artBox":
            if let box = artBox {
                return .string(box.description)
            }
            return .null
        case "rotation":
            return .integer(Int64(rotation))
        case "userUnit":
            return .real(userUnit)
        case "hasResources":
            return .boolean(hasResources)
        case "hasContentStreams":
            return .boolean(hasContentStreams)
        case "hasAnnotations":
            return .boolean(hasAnnotations)
        case "fontCount":
            return .integer(Int64(fontCount))
        case "xObjectCount":
            return .integer(Int64(xObjectCount))
        case "colorSpaceCount":
            return .integer(Int64(colorSpaceCount))
        case "extGStateCount":
            return .integer(Int64(extGStateCount))
        case "patternCount":
            return .integer(Int64(patternCount))
        case "shadingCount":
            return .integer(Int64(shadingCount))
        case "annotationCount":
            return .integer(Int64(annotationCount))
        case "hasTransparencyGroup":
            return .boolean(hasTransparencyGroup)
        case "transparencyGroupColorSpace":
            if let cs = transparencyGroupColorSpace {
                return .name(cs.stringValue)
            }
            return .null
        default:
            return nil
        }
    }

    // MARK: - ResourceResolver Conformance

    /// Resolves a font resource by name.
    public func resolveFont(named name: ASAtom) -> COSValue? {
        fontResources[name]
    }

    /// Resolves an XObject resource by name.
    public func resolveXObject(named name: ASAtom) -> COSValue? {
        xObjectResources[name]
    }

    /// Resolves a color space resource by name.
    public func resolveColorSpace(named name: ASAtom) -> COSValue? {
        colorSpaceResources[name]
    }

    /// Resolves an extended graphics state resource by name.
    public func resolveExtGState(named name: ASAtom) -> COSValue? {
        extGStateResources[name]
    }

    /// Resolves a pattern resource by name.
    public func resolvePattern(named name: ASAtom) -> COSValue? {
        patternResources[name]
    }

    /// Resolves a shading resource by name.
    public func resolveShading(named name: ASAtom) -> COSValue? {
        shadingResources[name]
    }

    /// Resolves a properties resource by name.
    public func resolveProperties(named name: ASAtom) -> COSValue? {
        propertiesResources[name]
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedPage, rhs: ValidatedPage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Convenience Computed Properties

extension ValidatedPage {

    /// The effective crop box (defaults to MediaBox if CropBox is absent).
    public var effectiveCropBox: PDFRect {
        cropBox ?? mediaBox
    }

    /// The total number of resources on this page.
    public var totalResourceCount: Int {
        fontCount + xObjectCount + colorSpaceCount + extGStateCount + patternCount + shadingCount
    }

    /// Whether the page has any resources at all.
    public var hasAnyResources: Bool {
        totalResourceCount > 0
    }

    /// Whether the rotation is a valid PDF rotation value.
    public var isValidRotation: Bool {
        [0, 90, 180, 270].contains(rotation)
    }

    /// The page width in points, accounting for rotation.
    public var effectiveWidth: Double {
        if rotation == 90 || rotation == 270 {
            return mediaBox.height * userUnit
        }
        return mediaBox.width * userUnit
    }

    /// The page height in points, accounting for rotation.
    public var effectiveHeight: Double {
        if rotation == 90 || rotation == 270 {
            return mediaBox.width * userUnit
        }
        return mediaBox.height * userUnit
    }

    /// Returns a summary string describing the page.
    public var summary: String {
        var parts: [String] = ["Page \(pageNumber)"]
        parts.append("\(Int(mediaBox.width))x\(Int(mediaBox.height))")
        if rotation != 0 { parts.append("rotated \(rotation)deg") }
        if hasAnnotations { parts.append("\(annotationCount) annots") }
        if let label = pageLabel { parts.append("label=\(label)") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedPage {

    /// Creates a minimal validated page for testing.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number (1-based).
    ///   - mediaBox: The page dimensions.
    /// - Returns: A minimal validated page.
    public static func minimal(
        pageNumber: Int = 1,
        mediaBox: PDFRect = .letter
    ) -> ValidatedPage {
        ValidatedPage(
            pageNumber: pageNumber,
            mediaBox: mediaBox
        )
    }
}

