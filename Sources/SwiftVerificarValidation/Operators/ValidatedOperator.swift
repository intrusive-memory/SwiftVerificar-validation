import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Operator Category

/// Categories of PDF content stream operators for validation purposes.
public enum OperatorCategory: String, Sendable, CaseIterable {
    /// Color operators: g, G, rg, RG, k, K, cs, CS, sc, SC, scn, SCN
    case color = "Color"

    /// Text object operators: BT, ET
    case textObject = "TextObject"

    /// Text state operators: Tf, Tc, Tw, Tz, TL, Tr, Ts
    case textState = "TextState"

    /// Text positioning operators: Tm, Td, TD, T*
    case textPositioning = "TextPositioning"

    /// Text showing operators: Tj, TJ, ', "
    case textShowing = "TextShowing"

    /// Path construction operators: m, l, c, v, y, h, re
    case pathConstruction = "PathConstruction"

    /// Path painting operators: S, s, f, F, f*, B, B*, b, b*, n
    case pathPainting = "PathPainting"

    /// Clipping operators: W, W*
    case clipping = "Clipping"

    /// Graphics state operators: q, Q, cm, w, J, j, M, d, ri, i, gs
    case graphicsState = "GraphicsState"

    /// XObject operators: Do
    case xObject = "XObject"

    /// Inline image operators: BI, ID, EI
    case inlineImage = "InlineImage"

    /// Marked content operators: BMC, BDC, EMC, MP, DP
    case markedContent = "MarkedContent"

    /// Shading operators: sh
    case shading = "Shading"

    /// Compatibility operators: BX, EX
    case compatibility = "Compatibility"

    /// Unknown or custom operators
    case unknown = "Unknown"
}

// MARK: - Inline Image Data

/// Data associated with an inline image operator.
public struct InlineImageData: Sendable, Hashable {
    /// The inline image dictionary entries.
    public let dictionary: [ASAtom: COSValue]

    /// The raw image data.
    public let data: Data

    /// Creates inline image data.
    public init(dictionary: [ASAtom: COSValue], data: Data) {
        self.dictionary = dictionary
        self.data = data
    }

    /// The width of the image, if specified.
    public var width: Int? {
        if let value = dictionary[ASAtom("W")] ?? dictionary[ASAtom("Width")] {
            return value.integerValue.map { Int($0) }
        }
        return nil
    }

    /// The height of the image, if specified.
    public var height: Int? {
        if let value = dictionary[ASAtom("H")] ?? dictionary[ASAtom("Height")] {
            return value.integerValue.map { Int($0) }
        }
        return nil
    }

    /// The bits per component, if specified.
    public var bitsPerComponent: Int? {
        if let value = dictionary[ASAtom("BPC")] ?? dictionary[ASAtom("BitsPerComponent")] {
            return value.integerValue.map { Int($0) }
        }
        return nil
    }

    /// The color space, if specified.
    public var colorSpace: ASAtom? {
        if let value = dictionary[ASAtom("CS")] ?? dictionary[ASAtom("ColorSpace")] {
            return value.nameValue
        }
        return nil
    }

    /// The filter, if specified.
    public var filter: ASAtom? {
        if let value = dictionary[ASAtom("F")] ?? dictionary[ASAtom("Filter")] {
            return value.nameValue
        }
        return nil
    }
}

// MARK: - Text Array Element (Validation)

/// An element in a text array for the TJ operator.
///
/// Mirrors TextArrayElement from the parser but for validation purposes.
public enum ValidatedTextArrayElement: Sendable, Hashable {
    /// A text string to show.
    case text(Data)

    /// A position adjustment in thousandths of a unit of text space.
    case adjustment(Double)

    /// Whether this is a text element.
    public var isText: Bool {
        if case .text = self { return true }
        return false
    }

    /// Whether this is an adjustment element.
    public var isAdjustment: Bool {
        if case .adjustment = self { return true }
        return false
    }

    /// The text data, if this is a text element.
    public var textData: Data? {
        if case .text(let data) = self { return data }
        return nil
    }

    /// The adjustment value, if this is an adjustment element.
    public var adjustmentValue: Double? {
        if case .adjustment(let value) = self { return value }
        return nil
    }
}

// MARK: - Validated Operator

/// A validated content stream operator - consolidates 97 Java classes into one enum.
///
/// This enum represents all PDF content stream operators for validation purposes.
/// Each case corresponds to one or more operator classes from veraPDF-validation,
/// dramatically reducing code duplication while maintaining full validation capability.
///
/// Conforms to `PDFObject` for integration with the validation rule engine.
///
/// ## Design Rationale
/// The Java veraPDF-validation has 97 separate operator classes (e.g., `GFOp_g_fill`,
/// `GFOp_BT`, `GFOp_Tj`). This Swift enum consolidates all operators into a single type
/// with associated values, eliminating:
/// - 97 separate class files
/// - Complex inheritance hierarchy
/// - Visitor pattern for operator handling
///
/// ## Operator Categories
/// - **Color**: g, G, rg, RG, k, K, cs, CS, sc, SC, scn, SCN
/// - **Text Objects**: BT, ET
/// - **Text State**: Tf, Tc, Tw, Tz, TL, Tr, Ts
/// - **Text Positioning**: Tm, Td, TD, T*
/// - **Text Showing**: Tj, TJ, ', "
/// - **Path Construction**: m, l, c, v, y, h, re
/// - **Path Painting**: S, s, f, F, f*, B, B*, b, b*, n
/// - **Clipping**: W, W*
/// - **Graphics State**: q, Q, cm, w, J, j, M, d, ri, i, gs
/// - **XObject**: Do
/// - **Inline Image**: BI, ID, EI
/// - **Marked Content**: BMC, BDC, EMC, MP, DP
/// - **Shading**: sh
/// - **Compatibility**: BX, EX
public enum ValidatedOperator: PDFObject, Sendable, Hashable {

    // MARK: - Color Operators (Stroking)

    /// Set stroking gray level (G).
    case setGrayStroke(Double)

    /// Set stroking RGB color (RG).
    case setRGBStroke(r: Double, g: Double, b: Double)

    /// Set stroking CMYK color (K).
    case setCMYKStroke(c: Double, m: Double, y: Double, k: Double)

    /// Set stroking color space (CS).
    case setColorSpaceStroke(ASAtom)

    /// Set stroking color (SC).
    case setColorStroke([Double])

    /// Set stroking color with pattern support (SCN).
    case setColorStrokeN(components: [Double], pattern: ASAtom?)

    // MARK: - Color Operators (Non-stroking/Fill)

    /// Set non-stroking gray level (g).
    case setGrayFill(Double)

    /// Set non-stroking RGB color (rg).
    case setRGBFill(r: Double, g: Double, b: Double)

    /// Set non-stroking CMYK color (k).
    case setCMYKFill(c: Double, m: Double, y: Double, k: Double)

    /// Set non-stroking color space (cs).
    case setColorSpaceFill(ASAtom)

    /// Set non-stroking color (sc).
    case setColorFill([Double])

    /// Set non-stroking color with pattern support (scn).
    case setColorFillN(components: [Double], pattern: ASAtom?)

    // MARK: - Text Object Operators

    /// Begin text object (BT).
    case beginText

    /// End text object (ET).
    case endText

    // MARK: - Text State Operators

    /// Set text font and size (Tf).
    case setFont(name: ASAtom, size: Double)

    /// Set character spacing (Tc).
    case setCharacterSpacing(Double)

    /// Set word spacing (Tw).
    case setWordSpacing(Double)

    /// Set horizontal text scaling (Tz).
    case setHorizontalScaling(Double)

    /// Set text leading (TL).
    case setTextLeading(Double)

    /// Set text rendering mode (Tr).
    case setTextRenderingMode(Int)

    /// Set text rise (Ts).
    case setTextRise(Double)

    // MARK: - Text Positioning Operators

    /// Set text matrix (Tm).
    case setTextMatrix(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// Move text position (Td).
    case moveTextPosition(tx: Double, ty: Double)

    /// Move text position and set leading (TD).
    case moveTextPositionLeading(tx: Double, ty: Double)

    /// Move to start of next text line (T*).
    case moveToNextLine

    // MARK: - Text Showing Operators

    /// Show text string (Tj).
    case showText(Data)

    /// Show text with individual glyph positioning (TJ).
    case showTextArray([ValidatedTextArrayElement])

    /// Move to next line and show text (').
    case moveAndShowText(Data)

    /// Set spacing, move to next line, and show text (").
    case moveAndShowTextWithSpacing(wordSpacing: Double, charSpacing: Double, text: Data)

    // MARK: - Path Construction Operators

    /// Begin new subpath - move to (m).
    case moveTo(x: Double, y: Double)

    /// Append straight line segment (l).
    case lineTo(x: Double, y: Double)

    /// Append cubic Bezier curve (c).
    case curveTo(x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double)

    /// Append cubic Bezier curve with initial point replicated (v).
    case curveToInitialReplicated(x2: Double, y2: Double, x3: Double, y3: Double)

    /// Append cubic Bezier curve with final point replicated (y).
    case curveToFinalReplicated(x1: Double, y1: Double, x3: Double, y3: Double)

    /// Close current subpath (h).
    case closePath

    /// Append rectangle (re).
    case appendRectangle(x: Double, y: Double, width: Double, height: Double)

    // MARK: - Path Painting Operators

    /// Stroke path (S).
    case stroke

    /// Close and stroke path (s).
    case closeAndStroke

    /// Fill path using nonzero winding rule (f or F).
    case fill

    /// Fill path using even-odd rule (f*).
    case fillEvenOdd

    /// Fill and stroke path using nonzero winding rule (B).
    case fillAndStroke

    /// Fill and stroke path using even-odd rule (B*).
    case fillAndStrokeEvenOdd

    /// Close, fill, and stroke path using nonzero winding rule (b).
    case closeFillAndStroke

    /// Close, fill, and stroke path using even-odd rule (b*).
    case closeFillAndStrokeEvenOdd

    /// End path without filling or stroking (n).
    case endPath

    // MARK: - Clipping Operators

    /// Set clipping path using nonzero winding rule (W).
    case clip

    /// Set clipping path using even-odd rule (W*).
    case clipEvenOdd

    // MARK: - Graphics State Operators

    /// Save graphics state (q).
    case saveGraphicsState

    /// Restore graphics state (Q).
    case restoreGraphicsState

    /// Concatenate matrix to CTM (cm).
    case concatMatrix(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// Set line width (w).
    case setLineWidth(Double)

    /// Set line cap style (J).
    case setLineCap(Int)

    /// Set line join style (j).
    case setLineJoin(Int)

    /// Set miter limit (M).
    case setMiterLimit(Double)

    /// Set line dash pattern (d).
    case setDashPattern(pattern: [Double], phase: Double)

    /// Set color rendering intent (ri).
    case setRenderingIntent(ASAtom)

    /// Set flatness tolerance (i).
    case setFlatness(Double)

    /// Set graphics state from ExtGState dictionary (gs).
    case setExtGState(ASAtom)

    // MARK: - XObject Operator

    /// Invoke named XObject (Do).
    case invokeXObject(ASAtom)

    // MARK: - Inline Image Operators

    /// Begin inline image (BI).
    case beginInlineImage

    /// Inline image data (ID with data).
    case inlineImageData(InlineImageData)

    /// End inline image (EI).
    case endInlineImage

    // MARK: - Marked Content Operators

    /// Begin marked content sequence (BMC).
    case beginMarkedContent(ASAtom)

    /// Begin marked content sequence with properties (BDC).
    case beginMarkedContentWithProperties(tag: ASAtom, properties: COSValue)

    /// End marked content sequence (EMC).
    case endMarkedContent

    /// Designate marked content point (MP).
    case markedContentPoint(ASAtom)

    /// Designate marked content point with properties (DP).
    case markedContentPointWithProperties(tag: ASAtom, properties: COSValue)

    // MARK: - Shading Operator

    /// Paint shading (sh).
    case paintShading(ASAtom)

    // MARK: - Compatibility Operators

    /// Begin compatibility section (BX).
    case beginCompatibility

    /// End compatibility section (EX).
    case endCompatibility

    // MARK: - Unknown Operator

    /// An unknown or custom operator.
    case unknown(name: String, operands: [COSValue])

    // MARK: - PDFObject Conformance

    /// Unique identifier for this operator instance.
    /// Since enums cannot have stored properties, we generate a stable ID
    /// based on the operator's hash value.
    public var id: UUID {
        // Create a deterministic UUID based on the operator's content
        // This ensures the same operator value gets the same ID
        var hasher = Hasher()
        hash(into: &hasher)
        let hashValue = hasher.finalize()
        // Create a UUID from the hash value
        let bytes = withUnsafeBytes(of: hashValue) { Array($0) }
        var uuidBytes: [UInt8] = Array(repeating: 0, count: 16)
        for i in 0..<min(bytes.count, 16) {
            uuidBytes[i] = bytes[i]
        }
        // Fill remaining bytes with operator name hash
        var nameHasher = Hasher()
        nameHasher.combine(operatorName)
        let nameHash = nameHasher.finalize()
        let nameBytes = withUnsafeBytes(of: nameHash) { Array($0) }
        for i in min(bytes.count, 16)..<16 {
            uuidBytes[i] = nameBytes[i % nameBytes.count]
        }
        return UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
    }

    /// The object type name for validation profiles.
    public var objectType: String {
        "Op\(operatorName)"
    }

    /// Operators don't have an underlying COS object directly.
    public var cosObject: COSValue? {
        nil
    }

    /// Operators don't have object keys.
    public var objectKey: COSObjectKey? {
        nil
    }

    /// The PDF operator name (e.g., "G", "g", "BT", "ET").
    public var operatorName: String {
        switch self {
        // Color operators (stroking)
        case .setGrayStroke: return "G"
        case .setRGBStroke: return "RG"
        case .setCMYKStroke: return "K"
        case .setColorSpaceStroke: return "CS"
        case .setColorStroke: return "SC"
        case .setColorStrokeN: return "SCN"

        // Color operators (fill)
        case .setGrayFill: return "g"
        case .setRGBFill: return "rg"
        case .setCMYKFill: return "k"
        case .setColorSpaceFill: return "cs"
        case .setColorFill: return "sc"
        case .setColorFillN: return "scn"

        // Text object
        case .beginText: return "BT"
        case .endText: return "ET"

        // Text state
        case .setFont: return "Tf"
        case .setCharacterSpacing: return "Tc"
        case .setWordSpacing: return "Tw"
        case .setHorizontalScaling: return "Tz"
        case .setTextLeading: return "TL"
        case .setTextRenderingMode: return "Tr"
        case .setTextRise: return "Ts"

        // Text positioning
        case .setTextMatrix: return "Tm"
        case .moveTextPosition: return "Td"
        case .moveTextPositionLeading: return "TD"
        case .moveToNextLine: return "T*"

        // Text showing
        case .showText: return "Tj"
        case .showTextArray: return "TJ"
        case .moveAndShowText: return "'"
        case .moveAndShowTextWithSpacing: return "\""

        // Path construction
        case .moveTo: return "m"
        case .lineTo: return "l"
        case .curveTo: return "c"
        case .curveToInitialReplicated: return "v"
        case .curveToFinalReplicated: return "y"
        case .closePath: return "h"
        case .appendRectangle: return "re"

        // Path painting
        case .stroke: return "S"
        case .closeAndStroke: return "s"
        case .fill: return "f"
        case .fillEvenOdd: return "f*"
        case .fillAndStroke: return "B"
        case .fillAndStrokeEvenOdd: return "B*"
        case .closeFillAndStroke: return "b"
        case .closeFillAndStrokeEvenOdd: return "b*"
        case .endPath: return "n"

        // Clipping
        case .clip: return "W"
        case .clipEvenOdd: return "W*"

        // Graphics state
        case .saveGraphicsState: return "q"
        case .restoreGraphicsState: return "Q"
        case .concatMatrix: return "cm"
        case .setLineWidth: return "w"
        case .setLineCap: return "J"
        case .setLineJoin: return "j"
        case .setMiterLimit: return "M"
        case .setDashPattern: return "d"
        case .setRenderingIntent: return "ri"
        case .setFlatness: return "i"
        case .setExtGState: return "gs"

        // XObject
        case .invokeXObject: return "Do"

        // Inline image
        case .beginInlineImage: return "BI"
        case .inlineImageData: return "ID"
        case .endInlineImage: return "EI"

        // Marked content
        case .beginMarkedContent: return "BMC"
        case .beginMarkedContentWithProperties: return "BDC"
        case .endMarkedContent: return "EMC"
        case .markedContentPoint: return "MP"
        case .markedContentPointWithProperties: return "DP"

        // Shading
        case .paintShading: return "sh"

        // Compatibility
        case .beginCompatibility: return "BX"
        case .endCompatibility: return "EX"

        // Unknown
        case .unknown(let name, _): return name
        }
    }

    /// The category of this operator.
    public var category: OperatorCategory {
        switch self {
        case .setGrayStroke, .setRGBStroke, .setCMYKStroke, .setColorSpaceStroke,
             .setColorStroke, .setColorStrokeN, .setGrayFill, .setRGBFill,
             .setCMYKFill, .setColorSpaceFill, .setColorFill, .setColorFillN:
            return .color

        case .beginText, .endText:
            return .textObject

        case .setFont, .setCharacterSpacing, .setWordSpacing, .setHorizontalScaling,
             .setTextLeading, .setTextRenderingMode, .setTextRise:
            return .textState

        case .setTextMatrix, .moveTextPosition, .moveTextPositionLeading, .moveToNextLine:
            return .textPositioning

        case .showText, .showTextArray, .moveAndShowText, .moveAndShowTextWithSpacing:
            return .textShowing

        case .moveTo, .lineTo, .curveTo, .curveToInitialReplicated,
             .curveToFinalReplicated, .closePath, .appendRectangle:
            return .pathConstruction

        case .stroke, .closeAndStroke, .fill, .fillEvenOdd, .fillAndStroke,
             .fillAndStrokeEvenOdd, .closeFillAndStroke, .closeFillAndStrokeEvenOdd, .endPath:
            return .pathPainting

        case .clip, .clipEvenOdd:
            return .clipping

        case .saveGraphicsState, .restoreGraphicsState, .concatMatrix, .setLineWidth,
             .setLineCap, .setLineJoin, .setMiterLimit, .setDashPattern,
             .setRenderingIntent, .setFlatness, .setExtGState:
            return .graphicsState

        case .invokeXObject:
            return .xObject

        case .beginInlineImage, .inlineImageData, .endInlineImage:
            return .inlineImage

        case .beginMarkedContent, .beginMarkedContentWithProperties, .endMarkedContent,
             .markedContentPoint, .markedContentPointWithProperties:
            return .markedContent

        case .paintShading:
            return .shading

        case .beginCompatibility, .endCompatibility:
            return .compatibility

        case .unknown:
            return .unknown
        }
    }

    /// Property names supported by this operator.
    public var propertyNames: [String] {
        var names = ["operatorName", "category", "isColorOperator", "isTextOperator",
                     "isPathOperator", "isGraphicsStateOperator"]

        // Add operator-specific property names
        switch self {
        case .setGrayStroke, .setGrayFill:
            names.append("gray")
        case .setRGBStroke, .setRGBFill:
            names.append(contentsOf: ["red", "green", "blue"])
        case .setCMYKStroke, .setCMYKFill:
            names.append(contentsOf: ["cyan", "magenta", "yellow", "black"])
        case .setColorSpaceStroke, .setColorSpaceFill:
            names.append("colorSpace")
        case .setColorStroke, .setColorFill:
            names.append(contentsOf: ["components", "componentCount"])
        case .setColorStrokeN, .setColorFillN:
            names.append(contentsOf: ["components", "componentCount", "pattern"])
        case .setFont:
            names.append(contentsOf: ["fontName", "fontSize"])
        case .setTextMatrix, .concatMatrix:
            names.append(contentsOf: ["a", "b", "c", "d", "e", "f"])
        case .moveTextPosition, .moveTextPositionLeading, .moveTo, .lineTo:
            names.append(contentsOf: ["x", "y", "tx", "ty"])
        case .appendRectangle:
            names.append(contentsOf: ["x", "y", "width", "height"])
        case .showText, .moveAndShowText:
            names.append("textData")
        case .showTextArray:
            names.append(contentsOf: ["elements", "elementCount"])
        case .invokeXObject, .paintShading:
            names.append("name")
        case .beginMarkedContent, .markedContentPoint:
            names.append("tag")
        case .beginMarkedContentWithProperties, .markedContentPointWithProperties:
            names.append(contentsOf: ["tag", "properties"])
        case .inlineImageData:
            names.append(contentsOf: ["width", "height", "bitsPerComponent", "imageColorSpace"])
        default:
            break
        }

        return names
    }

    /// Returns the value of a property by name.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "operatorName":
            return .string(operatorName)
        case "category":
            return .string(category.rawValue)
        case "isColorOperator":
            return .boolean(isColorOperator)
        case "isTextOperator":
            return .boolean(isTextOperator)
        case "isPathOperator":
            return .boolean(isPathOperator)
        case "isGraphicsStateOperator":
            return .boolean(isGraphicsStateOperator)
        default:
            return operatorSpecificProperty(named: name)
        }
    }

    /// Returns operator-specific properties.
    private func operatorSpecificProperty(named name: String) -> PropertyValue? {
        switch self {
        case .setGrayStroke(let gray), .setGrayFill(let gray):
            if name == "gray" { return .real(gray) }

        case .setRGBStroke(let r, let g, let b), .setRGBFill(let r, let g, let b):
            switch name {
            case "red": return .real(r)
            case "green": return .real(g)
            case "blue": return .real(b)
            default: break
            }

        case .setCMYKStroke(let c, let m, let y, let k),
             .setCMYKFill(let c, let m, let y, let k):
            switch name {
            case "cyan": return .real(c)
            case "magenta": return .real(m)
            case "yellow": return .real(y)
            case "black": return .real(k)
            default: break
            }

        case .setColorSpaceStroke(let cs), .setColorSpaceFill(let cs):
            if name == "colorSpace" { return .name(cs.stringValue) }

        case .setColorStroke(let components), .setColorFill(let components):
            switch name {
            case "componentCount": return .integer(Int64(components.count))
            default: break
            }

        case .setColorStrokeN(let components, let pattern),
             .setColorFillN(let components, let pattern):
            switch name {
            case "componentCount": return .integer(Int64(components.count))
            case "pattern": return pattern.map { .name($0.stringValue) }
            default: break
            }

        case .setFont(let fontName, let size):
            switch name {
            case "fontName": return .name(fontName.stringValue)
            case "fontSize": return .real(size)
            default: break
            }

        case .setTextMatrix(let a, let b, let c, let d, let e, let f),
             .concatMatrix(let a, let b, let c, let d, let e, let f):
            switch name {
            case "a": return .real(a)
            case "b": return .real(b)
            case "c": return .real(c)
            case "d": return .real(d)
            case "e": return .real(e)
            case "f": return .real(f)
            default: break
            }

        case .moveTextPosition(let tx, let ty), .moveTextPositionLeading(let tx, let ty):
            switch name {
            case "tx", "x": return .real(tx)
            case "ty", "y": return .real(ty)
            default: break
            }

        case .moveTo(let x, let y), .lineTo(let x, let y):
            switch name {
            case "x": return .real(x)
            case "y": return .real(y)
            default: break
            }

        case .appendRectangle(let x, let y, let width, let height):
            switch name {
            case "x": return .real(x)
            case "y": return .real(y)
            case "width": return .real(width)
            case "height": return .real(height)
            default: break
            }

        case .showTextArray(let elements):
            if name == "elementCount" { return .integer(Int64(elements.count)) }

        case .invokeXObject(let xName), .paintShading(let xName):
            if name == "name" { return .name(xName.stringValue) }

        case .beginMarkedContent(let tag), .markedContentPoint(let tag):
            if name == "tag" { return .name(tag.stringValue) }

        case .beginMarkedContentWithProperties(let tag, _),
             .markedContentPointWithProperties(let tag, _):
            if name == "tag" { return .name(tag.stringValue) }

        case .inlineImageData(let imageData):
            switch name {
            case "width": return imageData.width.map { .integer(Int64($0)) }
            case "height": return imageData.height.map { .integer(Int64($0)) }
            case "bitsPerComponent": return imageData.bitsPerComponent.map { .integer(Int64($0)) }
            case "imageColorSpace": return imageData.colorSpace.map { .name($0.stringValue) }
            default: break
            }

        default:
            break
        }

        return nil
    }

    // MARK: - Category Checks

    /// Whether this is a color-related operator.
    public var isColorOperator: Bool {
        category == .color
    }

    /// Whether this is a text-related operator (any text category).
    public var isTextOperator: Bool {
        switch category {
        case .textObject, .textState, .textPositioning, .textShowing:
            return true
        default:
            return false
        }
    }

    /// Whether this is a path-related operator.
    public var isPathOperator: Bool {
        category == .pathConstruction || category == .pathPainting
    }

    /// Whether this is a graphics state operator.
    public var isGraphicsStateOperator: Bool {
        category == .graphicsState
    }

    /// Whether this operator starts a paired sequence (e.g., BT, q, BMC).
    public var isBeginOperator: Bool {
        switch self {
        case .beginText, .saveGraphicsState, .beginMarkedContent,
             .beginMarkedContentWithProperties, .beginInlineImage, .beginCompatibility:
            return true
        default:
            return false
        }
    }

    /// Whether this operator ends a paired sequence (e.g., ET, Q, EMC).
    public var isEndOperator: Bool {
        switch self {
        case .endText, .restoreGraphicsState, .endMarkedContent,
             .endInlineImage, .endCompatibility:
            return true
        default:
            return false
        }
    }

    /// Whether this is a stroking color operator.
    public var isStrokingColorOperator: Bool {
        switch self {
        case .setGrayStroke, .setRGBStroke, .setCMYKStroke,
             .setColorSpaceStroke, .setColorStroke, .setColorStrokeN:
            return true
        default:
            return false
        }
    }

    /// Whether this is a fill (non-stroking) color operator.
    public var isFillColorOperator: Bool {
        switch self {
        case .setGrayFill, .setRGBFill, .setCMYKFill,
             .setColorSpaceFill, .setColorFill, .setColorFillN:
            return true
        default:
            return false
        }
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(operatorName)

        // Hash associated values for key operators
        switch self {
        case .setGrayStroke(let v), .setGrayFill(let v):
            hasher.combine(v)
        case .setRGBStroke(let r, let g, let b), .setRGBFill(let r, let g, let b):
            hasher.combine(r)
            hasher.combine(g)
            hasher.combine(b)
        case .setCMYKStroke(let c, let m, let y, let k),
             .setCMYKFill(let c, let m, let y, let k):
            hasher.combine(c)
            hasher.combine(m)
            hasher.combine(y)
            hasher.combine(k)
        case .setFont(let name, let size):
            hasher.combine(name)
            hasher.combine(size)
        case .showText(let data), .moveAndShowText(let data):
            hasher.combine(data)
        case .invokeXObject(let name), .paintShading(let name):
            hasher.combine(name)
        case .unknown(let name, _):
            hasher.combine(name)
        default:
            break
        }
    }
}

// MARK: - Operator Count

extension ValidatedOperator {
    /// The total count of defined operator cases (excluding .unknown).
    public static var definedOperatorCount: Int {
        // Color (12) + Text Object (2) + Text State (7) + Text Positioning (4) +
        // Text Showing (4) + Path Construction (7) + Path Painting (9) +
        // Clipping (2) + Graphics State (11) + XObject (1) + Inline Image (3) +
        // Marked Content (5) + Shading (1) + Compatibility (2) = 70
        70
    }

    /// All operator names defined by this enum.
    public static var allOperatorNames: [String] {
        ["G", "RG", "K", "CS", "SC", "SCN",
         "g", "rg", "k", "cs", "sc", "scn",
         "BT", "ET",
         "Tf", "Tc", "Tw", "Tz", "TL", "Tr", "Ts",
         "Tm", "Td", "TD", "T*",
         "Tj", "TJ", "'", "\"",
         "m", "l", "c", "v", "y", "h", "re",
         "S", "s", "f", "f*", "B", "B*", "b", "b*", "n",
         "W", "W*",
         "q", "Q", "cm", "w", "J", "j", "M", "d", "ri", "i", "gs",
         "Do",
         "BI", "ID", "EI",
         "BMC", "BDC", "EMC", "MP", "DP",
         "sh",
         "BX", "EX"]
    }
}

// MARK: - CustomStringConvertible

extension ValidatedOperator: CustomStringConvertible {
    public var description: String {
        switch self {
        case .setGrayStroke(let v):
            return "\(v) G"
        case .setGrayFill(let v):
            return "\(v) g"
        case .setRGBStroke(let r, let g, let b):
            return "\(r) \(g) \(b) RG"
        case .setRGBFill(let r, let g, let b):
            return "\(r) \(g) \(b) rg"
        case .setCMYKStroke(let c, let m, let y, let k):
            return "\(c) \(m) \(y) \(k) K"
        case .setCMYKFill(let c, let m, let y, let k):
            return "\(c) \(m) \(y) \(k) k"
        case .setColorSpaceStroke(let cs):
            return "/\(cs.stringValue) CS"
        case .setColorSpaceFill(let cs):
            return "/\(cs.stringValue) cs"
        case .setFont(let name, let size):
            return "/\(name.stringValue) \(size) Tf"
        case .moveTo(let x, let y):
            return "\(x) \(y) m"
        case .lineTo(let x, let y):
            return "\(x) \(y) l"
        case .appendRectangle(let x, let y, let w, let h):
            return "\(x) \(y) \(w) \(h) re"
        case .invokeXObject(let name):
            return "/\(name.stringValue) Do"
        case .beginMarkedContent(let tag):
            return "/\(tag.stringValue) BMC"
        default:
            return operatorName
        }
    }
}
