import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - XObject Subtype

/// The subtype of a PDF XObject.
///
/// XObjects are self-contained graphical objects that can be referenced
/// multiple times within a document. There are three main subtypes.
///
/// See PDF specification section 8.8 -- External objects.
public enum XObjectSubtype: String, Sendable, Hashable, CaseIterable {
    /// Image XObject: a raster image.
    case image = "Image"

    /// Form XObject: a self-contained stream of graphics operators.
    case form = "Form"

    /// PostScript XObject: a PostScript language fragment (deprecated).
    case postScript = "PS"

    /// Unknown subtype.
    case unknown = "Unknown"

    /// Creates an XObject subtype from a string.
    ///
    /// - Parameter value: The subtype string from the PDF dictionary.
    public init(fromString value: String?) {
        guard let value = value else {
            self = .unknown
            return
        }
        self = XObjectSubtype(rawValue: value) ?? .unknown
    }
}

// MARK: - Validated XObject

/// A validation wrapper for a PDF XObject.
///
/// XObjects are self-contained graphical elements that can be referenced
/// from content streams using the `Do` operator. The three main types are:
/// - **Image XObject**: Raster image data
/// - **Form XObject**: A mini page with its own content stream
/// - **PostScript XObject**: Deprecated PostScript code (prohibited in PDF/A)
///
/// ## Key Properties
///
/// - **Subtype**: Image, Form, or PS
/// - **BBox**: Bounding box (for Form XObjects)
/// - **Width/Height**: Dimensions (for Image XObjects)
/// - **Resources**: Own resource dictionary (for Form XObjects)
///
/// ## Validation Rules
///
/// - **PDF/A**: PostScript XObjects are prohibited.
/// - **PDF/A-1**: Image XObjects must not use JPX (JPEG 2000) compression
///   with certain features.
/// - **PDF/UA**: Images used as content must have alt text via the
///   parent structure element.
/// - **PDF/A**: Transparency group XObjects must comply with color space rules.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDXObject`, `GFPDXImage`, and `GFPDXForm` from
/// veraPDF-validation, consolidated into a single struct with
/// `XObjectSubtype` discriminator.
public struct ValidatedXObject: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the XObject.
    public let cosDictionary: COSValue?

    /// The object key for the XObject, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Common Properties

    /// The XObject subtype.
    public let subtype: XObjectSubtype

    /// The raw subtype string.
    public let subtypeName: String

    /// The structure parent key for tagged PDF (`/StructParent` or `/StructParents` entry).
    public let structParent: Int?

    /// Whether the XObject has an OPI (Open Prepress Interface) entry.
    public let hasOPI: Bool

    // MARK: - Image XObject Properties

    /// The width of the image in pixels (for Image XObjects).
    public let width: Int?

    /// The height of the image in pixels (for Image XObjects).
    public let height: Int?

    /// The bits per component for the image (for Image XObjects).
    public let bitsPerComponent: Int?

    /// The color space name for the image (for Image XObjects).
    public let colorSpaceName: String?

    /// The number of color components for the image (for Image XObjects).
    public let colorComponentCount: Int?

    /// Whether the image uses an image mask (`/ImageMask` entry).
    public let isImageMask: Bool

    /// Whether the image has a mask (`/Mask` entry).
    public let hasMask: Bool

    /// Whether the image has a soft mask (`/SMask` entry).
    public let hasSoftMask: Bool

    /// Whether the image has an alternate representation (`/Alternates` entry).
    public let hasAlternates: Bool

    /// The filter(s) used for image compression.
    public let filters: [String]

    /// Whether the image uses inline data (for inline images only).
    public let isInline: Bool

    /// Whether the image has an ICC profile in its color space.
    public let hasICCProfile: Bool

    /// Whether interpolation is enabled (`/Interpolate` entry).
    public let interpolate: Bool

    // MARK: - Form XObject Properties

    /// The bounding box for form XObjects (`/BBox` entry).
    public let formBBox: PDFRect?

    /// Whether the form has a transformation matrix (`/Matrix` entry).
    public let hasMatrix: Bool

    /// Whether the form has its own resources (`/Resources` entry).
    public let hasResources: Bool

    /// Whether the form is a transparency group (`/Group` entry with `/S /Transparency`).
    public let isTransparencyGroup: Bool

    /// The transparency group color space, if this is a transparency group.
    public let groupColorSpace: String?

    /// Whether the transparency group is isolated.
    public let isIsolated: Bool

    /// Whether the transparency group uses knockout compositing.
    public let isKnockout: Bool

    /// Whether the form has its own content stream.
    public let hasContentStream: Bool

    /// Whether the form has metadata (`/Metadata` entry).
    public let hasMetadata: Bool

    // MARK: - Initialization

    /// Creates a validated XObject.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the XObject.
    ///   - objectKey: The object key.
    ///   - context: Validation context.
    ///   - subtypeName: The raw subtype string.
    ///   - structParent: The structure parent key.
    ///   - hasOPI: Whether an OPI entry exists.
    ///   - width: Image width.
    ///   - height: Image height.
    ///   - bitsPerComponent: Bits per component.
    ///   - colorSpaceName: Color space name.
    ///   - colorComponentCount: Number of color components.
    ///   - isImageMask: Whether this is an image mask.
    ///   - hasMask: Whether a mask exists.
    ///   - hasSoftMask: Whether a soft mask exists.
    ///   - hasAlternates: Whether alternates exist.
    ///   - filters: Compression filters.
    ///   - isInline: Whether this is an inline image.
    ///   - hasICCProfile: Whether an ICC profile exists.
    ///   - interpolate: Whether interpolation is enabled.
    ///   - formBBox: Form bounding box.
    ///   - hasMatrix: Whether a matrix exists.
    ///   - hasResources: Whether resources exist.
    ///   - isTransparencyGroup: Whether this is a transparency group.
    ///   - groupColorSpace: Transparency group color space.
    ///   - isIsolated: Whether the group is isolated.
    ///   - isKnockout: Whether knockout compositing is used.
    ///   - hasContentStream: Whether a content stream exists.
    ///   - hasMetadata: Whether metadata exists.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(location: "XObject"),
        subtypeName: String = "Image",
        structParent: Int? = nil,
        hasOPI: Bool = false,
        width: Int? = nil,
        height: Int? = nil,
        bitsPerComponent: Int? = nil,
        colorSpaceName: String? = nil,
        colorComponentCount: Int? = nil,
        isImageMask: Bool = false,
        hasMask: Bool = false,
        hasSoftMask: Bool = false,
        hasAlternates: Bool = false,
        filters: [String] = [],
        isInline: Bool = false,
        hasICCProfile: Bool = false,
        interpolate: Bool = false,
        formBBox: PDFRect? = nil,
        hasMatrix: Bool = false,
        hasResources: Bool = false,
        isTransparencyGroup: Bool = false,
        groupColorSpace: String? = nil,
        isIsolated: Bool = false,
        isKnockout: Bool = false,
        hasContentStream: Bool = false,
        hasMetadata: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.subtypeName = subtypeName
        self.subtype = XObjectSubtype(fromString: subtypeName)
        self.structParent = structParent
        self.hasOPI = hasOPI
        self.width = width
        self.height = height
        self.bitsPerComponent = bitsPerComponent
        self.colorSpaceName = colorSpaceName
        self.colorComponentCount = colorComponentCount
        self.isImageMask = isImageMask
        self.hasMask = hasMask
        self.hasSoftMask = hasSoftMask
        self.hasAlternates = hasAlternates
        self.filters = filters
        self.isInline = isInline
        self.hasICCProfile = hasICCProfile
        self.interpolate = interpolate
        self.formBBox = formBBox
        self.hasMatrix = hasMatrix
        self.hasResources = hasResources
        self.isTransparencyGroup = isTransparencyGroup
        self.groupColorSpace = groupColorSpace
        self.isIsolated = isIsolated
        self.isKnockout = isKnockout
        self.hasContentStream = hasContentStream
        self.hasMetadata = hasMetadata
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        switch subtype {
        case .image: return "PDXImage"
        case .form: return "PDXForm"
        case .postScript: return "PDXObject"
        case .unknown: return "PDXObject"
        }
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "subtype", "subtypeName", "structParent", "hasOPI",
            "width", "height", "bitsPerComponent",
            "colorSpaceName", "colorComponentCount",
            "isImageMask", "hasMask", "hasSoftMask",
            "hasAlternates", "filters", "isInline",
            "hasICCProfile", "interpolate",
            "formBBox", "hasMatrix", "hasResources",
            "isTransparencyGroup", "groupColorSpace",
            "isIsolated", "isKnockout",
            "hasContentStream", "hasMetadata",
            "isImage", "isForm", "isPostScript",
            "hasStructParent", "usesJPXFilter",
            "involvesTransparency"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "subtype":
            return .string(subtype.rawValue)
        case "subtypeName":
            return .string(subtypeName)
        case "structParent":
            if let sp = structParent { return .integer(Int64(sp)) }
            return .null
        case "hasOPI":
            return .boolean(hasOPI)
        case "width":
            if let w = width { return .integer(Int64(w)) }
            return .null
        case "height":
            if let h = height { return .integer(Int64(h)) }
            return .null
        case "bitsPerComponent":
            if let bpc = bitsPerComponent { return .integer(Int64(bpc)) }
            return .null
        case "colorSpaceName":
            if let csn = colorSpaceName { return .string(csn) }
            return .null
        case "colorComponentCount":
            if let ccc = colorComponentCount { return .integer(Int64(ccc)) }
            return .null
        case "isImageMask":
            return .boolean(isImageMask)
        case "hasMask":
            return .boolean(hasMask)
        case "hasSoftMask":
            return .boolean(hasSoftMask)
        case "hasAlternates":
            return .boolean(hasAlternates)
        case "filters":
            return .string(filters.joined(separator: ","))
        case "isInline":
            return .boolean(isInline)
        case "hasICCProfile":
            return .boolean(hasICCProfile)
        case "interpolate":
            return .boolean(interpolate)
        case "formBBox":
            if let fb = formBBox { return .string(fb.description) }
            return .null
        case "hasMatrix":
            return .boolean(hasMatrix)
        case "hasResources":
            return .boolean(hasResources)
        case "isTransparencyGroup":
            return .boolean(isTransparencyGroup)
        case "groupColorSpace":
            if let gcs = groupColorSpace { return .string(gcs) }
            return .null
        case "isIsolated":
            return .boolean(isIsolated)
        case "isKnockout":
            return .boolean(isKnockout)
        case "hasContentStream":
            return .boolean(hasContentStream)
        case "hasMetadata":
            return .boolean(hasMetadata)
        case "isImage":
            return .boolean(isImage)
        case "isForm":
            return .boolean(isForm)
        case "isPostScript":
            return .boolean(isPostScript)
        case "hasStructParent":
            return .boolean(hasStructParent)
        case "usesJPXFilter":
            return .boolean(usesJPXFilter)
        case "involvesTransparency":
            return .boolean(involvesTransparency)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedXObject, rhs: ValidatedXObject) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedXObject {

    /// Whether this is an image XObject.
    public var isImage: Bool {
        subtype == .image
    }

    /// Whether this is a form XObject.
    public var isForm: Bool {
        subtype == .form
    }

    /// Whether this is a PostScript XObject.
    public var isPostScript: Bool {
        subtype == .postScript
    }

    /// Whether this XObject has a structure parent.
    public var hasStructParent: Bool {
        structParent != nil
    }

    /// Whether the image uses JPX (JPEG 2000) compression.
    public var usesJPXFilter: Bool {
        filters.contains("JPXDecode")
    }

    /// Whether the image uses JBIG2 compression.
    public var usesJBIG2Filter: Bool {
        filters.contains("JBIG2Decode")
    }

    /// Whether the image uses DCT (JPEG) compression.
    public var usesDCTFilter: Bool {
        filters.contains("DCTDecode")
    }

    /// Whether this XObject involves transparency.
    ///
    /// Transparency is involved if the XObject has a soft mask,
    /// is a transparency group, or uses knockout/isolation.
    public var involvesTransparency: Bool {
        hasSoftMask || isTransparencyGroup || isIsolated || isKnockout
    }

    /// The pixel count for image XObjects.
    public var pixelCount: Int? {
        guard let w = width, let h = height else { return nil }
        return w * h
    }

    /// Returns a summary string describing the XObject.
    public var summary: String {
        var parts: [String] = [subtypeName]
        switch subtype {
        case .image:
            if let w = width, let h = height {
                parts.append("\(w)x\(h)")
            }
            if let csn = colorSpaceName { parts.append(csn) }
            if !filters.isEmpty { parts.append(filters.joined(separator: "+")) }
        case .form:
            if isTransparencyGroup { parts.append("transparency group") }
            if hasResources { parts.append("has resources") }
        case .postScript:
            parts.append("(deprecated)")
        case .unknown:
            break
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedXObject {

    /// Creates an image XObject for testing.
    ///
    /// - Parameters:
    ///   - width: Image width in pixels.
    ///   - height: Image height in pixels.
    ///   - colorSpaceName: The color space.
    ///   - bitsPerComponent: Bits per color component.
    /// - Returns: An image XObject.
    public static func image(
        width: Int = 100,
        height: Int = 100,
        colorSpaceName: String = "DeviceRGB",
        bitsPerComponent: Int = 8
    ) -> ValidatedXObject {
        ValidatedXObject(
            subtypeName: "Image",
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            colorSpaceName: colorSpaceName,
            colorComponentCount: colorSpaceName == "DeviceGray" ? 1 :
                                 colorSpaceName == "DeviceCMYK" ? 4 : 3
        )
    }

    /// Creates a form XObject for testing.
    ///
    /// - Parameter isTransparencyGroup: Whether this is a transparency group.
    /// - Returns: A form XObject.
    public static func form(
        isTransparencyGroup: Bool = false
    ) -> ValidatedXObject {
        ValidatedXObject(
            subtypeName: "Form",
            formBBox: PDFRect(x: 0, y: 0, width: 612, height: 792),
            hasResources: true,
            isTransparencyGroup: isTransparencyGroup,
            hasContentStream: true
        )
    }

    /// Creates an image mask XObject for testing.
    ///
    /// - Returns: An image mask XObject.
    public static func imageMask() -> ValidatedXObject {
        ValidatedXObject(
            subtypeName: "Image",
            width: 100,
            height: 100,
            bitsPerComponent: 1,
            isImageMask: true
        )
    }
}
