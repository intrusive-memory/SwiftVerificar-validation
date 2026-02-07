import Foundation

/// Page-level features extracted from a PDF page.
///
/// This struct contains information about a single page in a PDF document,
/// including dimensions, resources, content, and annotations.
///
/// Corresponds to page-level feature extraction in veraPDF.
public struct PageFeatures: Sendable, Equatable, Identifiable {

    // MARK: - Properties

    /// Unique identifier for this page features instance.
    public let id: UUID

    /// The page number (1-based).
    public let pageNumber: Int

    /// Page label, if any.
    public let pageLabel: String?

    // MARK: - Dimensions

    /// Media box dimensions (in points).
    public let mediaBox: PDFRect

    /// Crop box dimensions (in points), if different from media box.
    public let cropBox: PDFRect?

    /// Bleed box dimensions (in points), if present.
    public let bleedBox: PDFRect?

    /// Trim box dimensions (in points), if present.
    public let trimBox: PDFRect?

    /// Art box dimensions (in points), if present.
    public let artBox: PDFRect?

    /// Page rotation in degrees (0, 90, 180, or 270).
    public let rotation: Int

    /// User unit scaling factor (PDF 1.6+).
    public let userUnit: Double

    // MARK: - Resources

    /// Font resources used on this page.
    public let fonts: [FontInfo]

    /// XObject resources (images, forms) used on this page.
    public let xObjects: [XObjectInfo]

    /// Color space resources used on this page.
    public let colorSpaces: [ColorSpaceInfo]

    /// Extended graphics state resources.
    public let extGStates: [ExtGStateInfo]

    /// Pattern resources.
    public let patterns: [PatternInfo]

    /// Shading resources.
    public let shadings: [ShadingInfo]

    // MARK: - Content

    /// Number of content streams on this page.
    public let contentStreamCount: Int

    /// Whether the page has transparency.
    public let hasTransparency: Bool

    /// Whether the page uses spot colors.
    public let usesSpotColors: Bool

    // MARK: - Annotations

    /// Annotations on this page.
    public let annotations: [AnnotationInfo]

    /// Whether the page has form fields.
    public let hasFormFields: Bool

    /// Whether the page has links.
    public let hasLinks: Bool

    // MARK: - Structure

    /// Whether the page content is tagged.
    public let isTagged: Bool

    /// Structure element count for this page.
    public let structureElementCount: Int

    // MARK: - Initialization

    /// Creates new page features.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - pageNumber: Page number (1-based).
    ///   - pageLabel: Page label.
    ///   - mediaBox: Media box dimensions.
    ///   - cropBox: Crop box dimensions.
    ///   - bleedBox: Bleed box dimensions.
    ///   - trimBox: Trim box dimensions.
    ///   - artBox: Art box dimensions.
    ///   - rotation: Page rotation in degrees.
    ///   - userUnit: User unit scaling factor.
    ///   - fonts: Font resources.
    ///   - xObjects: XObject resources.
    ///   - colorSpaces: Color space resources.
    ///   - extGStates: Extended graphics states.
    ///   - patterns: Pattern resources.
    ///   - shadings: Shading resources.
    ///   - contentStreamCount: Number of content streams.
    ///   - hasTransparency: Whether page has transparency.
    ///   - usesSpotColors: Whether page uses spot colors.
    ///   - annotations: Annotation information.
    ///   - hasFormFields: Whether page has form fields.
    ///   - hasLinks: Whether page has links.
    ///   - isTagged: Whether page is tagged.
    ///   - structureElementCount: Structure element count.
    public init(
        id: UUID = UUID(),
        pageNumber: Int,
        pageLabel: String? = nil,
        mediaBox: PDFRect,
        cropBox: PDFRect? = nil,
        bleedBox: PDFRect? = nil,
        trimBox: PDFRect? = nil,
        artBox: PDFRect? = nil,
        rotation: Int = 0,
        userUnit: Double = 1.0,
        fonts: [FontInfo] = [],
        xObjects: [XObjectInfo] = [],
        colorSpaces: [ColorSpaceInfo] = [],
        extGStates: [ExtGStateInfo] = [],
        patterns: [PatternInfo] = [],
        shadings: [ShadingInfo] = [],
        contentStreamCount: Int = 1,
        hasTransparency: Bool = false,
        usesSpotColors: Bool = false,
        annotations: [AnnotationInfo] = [],
        hasFormFields: Bool = false,
        hasLinks: Bool = false,
        isTagged: Bool = false,
        structureElementCount: Int = 0
    ) {
        self.id = id
        self.pageNumber = pageNumber
        self.pageLabel = pageLabel
        self.mediaBox = mediaBox
        self.cropBox = cropBox
        self.bleedBox = bleedBox
        self.trimBox = trimBox
        self.artBox = artBox
        self.rotation = rotation
        self.userUnit = userUnit
        self.fonts = fonts
        self.xObjects = xObjects
        self.colorSpaces = colorSpaces
        self.extGStates = extGStates
        self.patterns = patterns
        self.shadings = shadings
        self.contentStreamCount = contentStreamCount
        self.hasTransparency = hasTransparency
        self.usesSpotColors = usesSpotColors
        self.annotations = annotations
        self.hasFormFields = hasFormFields
        self.hasLinks = hasLinks
        self.isTagged = isTagged
        self.structureElementCount = structureElementCount
    }

    // MARK: - Computed Properties

    /// The effective crop box (defaults to media box).
    public var effectiveCropBox: PDFRect {
        cropBox ?? mediaBox
    }

    /// Page width in points (from media box).
    public var width: Double {
        mediaBox.width
    }

    /// Page height in points (from media box).
    public var height: Double {
        mediaBox.height
    }

    /// Page width in inches.
    public var widthInches: Double {
        width / 72.0
    }

    /// Page height in inches.
    public var heightInches: Double {
        height / 72.0
    }

    /// Page width in millimeters.
    public var widthMM: Double {
        width / 72.0 * 25.4
    }

    /// Page height in millimeters.
    public var heightMM: Double {
        height / 72.0 * 25.4
    }

    /// Total number of resources on this page.
    public var resourceCount: Int {
        fonts.count + xObjects.count + colorSpaces.count +
        extGStates.count + patterns.count + shadings.count
    }

    /// Total number of annotations on this page.
    public var annotationCount: Int {
        annotations.count
    }

    /// Whether this page is landscape orientation.
    public var isLandscape: Bool {
        let effectiveRotation = rotation % 360
        if effectiveRotation == 90 || effectiveRotation == 270 {
            return height > width
        }
        return width > height
    }

    /// The number of images on this page.
    public var imageCount: Int {
        xObjects.filter { $0.subtype == "Image" }.count
    }

    /// The number of form XObjects on this page.
    public var formXObjectCount: Int {
        xObjects.filter { $0.subtype == "Form" }.count
    }

    // MARK: - Conversion to FeatureNode

    /// Converts the page features to a FeatureNode.
    ///
    /// - Returns: A feature node representing the page features.
    public func toFeatureNode() -> FeatureNode {
        var values: [String: FeatureValue] = [:]

        values["pageNumber"] = .int(pageNumber)
        if let pageLabel = pageLabel { values["pageLabel"] = .string(pageLabel) }

        values["mediaBoxX"] = .double(mediaBox.x)
        values["mediaBoxY"] = .double(mediaBox.y)
        values["mediaBoxWidth"] = .double(mediaBox.width)
        values["mediaBoxHeight"] = .double(mediaBox.height)

        values["rotation"] = .int(rotation)
        values["userUnit"] = .double(userUnit)

        values["fontCount"] = .int(fonts.count)
        values["xObjectCount"] = .int(xObjects.count)
        values["colorSpaceCount"] = .int(colorSpaces.count)
        values["annotationCount"] = .int(annotations.count)

        values["contentStreamCount"] = .int(contentStreamCount)
        values["hasTransparency"] = .bool(hasTransparency)
        values["usesSpotColors"] = .bool(usesSpotColors)
        values["hasFormFields"] = .bool(hasFormFields)
        values["hasLinks"] = .bool(hasLinks)
        values["isTagged"] = .bool(isTagged)
        values["structureElementCount"] = .int(structureElementCount)

        // Create child nodes for resources
        var children: [FeatureNode] = []

        for font in fonts {
            children.append(font.toFeatureNode())
        }

        for xObject in xObjects {
            children.append(xObject.toFeatureNode())
        }

        for annotation in annotations {
            children.append(annotation.toFeatureNode())
        }

        return FeatureNode(
            featureType: .page,
            name: pageLabel ?? "Page \(pageNumber)",
            values: values,
            children: children,
            context: ObjectContext.page(pageNumber)
        )
    }
}

// MARK: - Supporting Types

/// A rectangle in PDF coordinates.
public struct PDFRect: Sendable, Equatable, Hashable {

    /// The x coordinate of the lower-left corner.
    public let x: Double

    /// The y coordinate of the lower-left corner.
    public let y: Double

    /// The width of the rectangle.
    public let width: Double

    /// The height of the rectangle.
    public let height: Double

    /// Creates a new PDF rectangle.
    ///
    /// - Parameters:
    ///   - x: X coordinate of lower-left corner.
    ///   - y: Y coordinate of lower-left corner.
    ///   - width: Width of the rectangle.
    ///   - height: Height of the rectangle.
    public init(x: Double = 0, y: Double = 0, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Creates a rectangle from an array of four numbers [llx, lly, urx, ury].
    ///
    /// - Parameter array: Array of four numbers.
    public init?(array: [Double]) {
        guard array.count == 4 else { return nil }
        self.x = array[0]
        self.y = array[1]
        self.width = array[2] - array[0]
        self.height = array[3] - array[1]
    }

    /// Common page sizes.
    public static let letter = PDFRect(width: 612, height: 792)
    public static let legal = PDFRect(width: 612, height: 1008)
    public static let a4 = PDFRect(width: 595, height: 842)
    public static let a3 = PDFRect(width: 842, height: 1191)

    /// The area of the rectangle in square points.
    public var area: Double {
        width * height
    }
}

/// Information about a font resource.
public struct FontInfo: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let subtype: String
    public let baseFont: String?
    public let encoding: String?
    public let isEmbedded: Bool
    public let isSubset: Bool
    public let toUnicode: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        subtype: String,
        baseFont: String? = nil,
        encoding: String? = nil,
        isEmbedded: Bool = false,
        isSubset: Bool = false,
        toUnicode: Bool = false
    ) {
        self.id = id
        self.name = name
        self.subtype = subtype
        self.baseFont = baseFont
        self.encoding = encoding
        self.isEmbedded = isEmbedded
        self.isSubset = isSubset
        self.toUnicode = toUnicode
    }

    /// Converts to a FeatureNode.
    public func toFeatureNode() -> FeatureNode {
        var values: [String: FeatureValue] = [
            "name": .string(name),
            "subtype": .string(subtype),
            "isEmbedded": .bool(isEmbedded),
            "isSubset": .bool(isSubset),
            "toUnicode": .bool(toUnicode)
        ]
        if let baseFont = baseFont { values["baseFont"] = .string(baseFont) }
        if let encoding = encoding { values["encoding"] = .string(encoding) }

        return FeatureNode(featureType: .font, name: name, values: values)
    }
}

/// Information about an XObject resource.
public struct XObjectInfo: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let subtype: String
    public let width: Int?
    public let height: Int?
    public let bitsPerComponent: Int?
    public let colorSpace: String?
    public let filter: String?

    public init(
        id: UUID = UUID(),
        name: String,
        subtype: String,
        width: Int? = nil,
        height: Int? = nil,
        bitsPerComponent: Int? = nil,
        colorSpace: String? = nil,
        filter: String? = nil
    ) {
        self.id = id
        self.name = name
        self.subtype = subtype
        self.width = width
        self.height = height
        self.bitsPerComponent = bitsPerComponent
        self.colorSpace = colorSpace
        self.filter = filter
    }

    /// Converts to a FeatureNode.
    public func toFeatureNode() -> FeatureNode {
        var values: [String: FeatureValue] = [
            "name": .string(name),
            "subtype": .string(subtype)
        ]
        if let width = width { values["width"] = .int(width) }
        if let height = height { values["height"] = .int(height) }
        if let bpc = bitsPerComponent { values["bitsPerComponent"] = .int(bpc) }
        if let cs = colorSpace { values["colorSpace"] = .string(cs) }
        if let filter = filter { values["filter"] = .string(filter) }

        let featureType: FeatureType = subtype == "Image" ? .image : .object
        return FeatureNode(featureType: featureType, name: name, values: values)
    }
}

/// Information about a color space resource.
public struct ColorSpaceInfo: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let family: String
    public let numComponents: Int
    public let iccProfileName: String?

    public init(
        id: UUID = UUID(),
        name: String,
        family: String,
        numComponents: Int,
        iccProfileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.family = family
        self.numComponents = numComponents
        self.iccProfileName = iccProfileName
    }

    /// Converts to a FeatureNode.
    public func toFeatureNode() -> FeatureNode {
        var values: [String: FeatureValue] = [
            "name": .string(name),
            "family": .string(family),
            "numComponents": .int(numComponents)
        ]
        if let icc = iccProfileName { values["iccProfileName"] = .string(icc) }

        return FeatureNode(featureType: .colorSpace, name: name, values: values)
    }
}

/// Information about an extended graphics state.
public struct ExtGStateInfo: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let blendMode: String?
    public let strokeAlpha: Double?
    public let fillAlpha: Double?
    public let softMask: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        blendMode: String? = nil,
        strokeAlpha: Double? = nil,
        fillAlpha: Double? = nil,
        softMask: Bool = false
    ) {
        self.id = id
        self.name = name
        self.blendMode = blendMode
        self.strokeAlpha = strokeAlpha
        self.fillAlpha = fillAlpha
        self.softMask = softMask
    }
}

/// Information about a pattern resource.
public struct PatternInfo: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let patternType: Int
    public let paintType: Int?
    public let tilingType: Int?

    public init(
        id: UUID = UUID(),
        name: String,
        patternType: Int,
        paintType: Int? = nil,
        tilingType: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.patternType = patternType
        self.paintType = paintType
        self.tilingType = tilingType
    }
}

/// Information about a shading resource.
public struct ShadingInfo: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let shadingType: Int
    public let colorSpace: String?

    public init(
        id: UUID = UUID(),
        name: String,
        shadingType: Int,
        colorSpace: String? = nil
    ) {
        self.id = id
        self.name = name
        self.shadingType = shadingType
        self.colorSpace = colorSpace
    }
}

/// Information about an annotation.
public struct AnnotationInfo: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let subtype: String
    public let contents: String?
    public let isVisible: Bool
    public let isPrintable: Bool
    public let hasAppearance: Bool

    public init(
        id: UUID = UUID(),
        subtype: String,
        contents: String? = nil,
        isVisible: Bool = true,
        isPrintable: Bool = true,
        hasAppearance: Bool = true
    ) {
        self.id = id
        self.subtype = subtype
        self.contents = contents
        self.isVisible = isVisible
        self.isPrintable = isPrintable
        self.hasAppearance = hasAppearance
    }

    /// Converts to a FeatureNode.
    public func toFeatureNode() -> FeatureNode {
        var values: [String: FeatureValue] = [
            "subtype": .string(subtype),
            "isVisible": .bool(isVisible),
            "isPrintable": .bool(isPrintable),
            "hasAppearance": .bool(hasAppearance)
        ]
        if let contents = contents { values["contents"] = .string(contents) }

        return FeatureNode(featureType: .annotation, name: subtype, values: values)
    }
}

// MARK: - CustomStringConvertible

extension PageFeatures: CustomStringConvertible {
    public var description: String {
        let label = pageLabel ?? "Page \(pageNumber)"
        let dimensions = String(format: "%.0fx%.0f", width, height)
        var parts = ["\(label)", "\(dimensions)pt"]

        if rotation != 0 { parts.append("rot:\(rotation)") }
        if !fonts.isEmpty { parts.append("\(fonts.count) fonts") }
        if !xObjects.isEmpty { parts.append("\(xObjects.count) XObjects") }
        if !annotations.isEmpty { parts.append("\(annotations.count) annotations") }

        return parts.joined(separator: ", ")
    }
}

extension PDFRect: CustomStringConvertible {
    public var description: String {
        String(format: "[%.1f, %.1f, %.1f, %.1f]", x, y, x + width, y + height)
    }
}
