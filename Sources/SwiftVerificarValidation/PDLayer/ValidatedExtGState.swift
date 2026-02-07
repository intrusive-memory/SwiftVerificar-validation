import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Blend Mode

/// PDF blend modes for compositing operations.
///
/// Corresponds to the `/BM` entry in an ExtGState dictionary.
/// See PDF specification Table 136 -- Standard separable blend modes and
/// Table 137 -- Standard non-separable blend modes.
public enum BlendMode: String, Sendable, Hashable, CaseIterable, Codable {
    /// Normal blend mode (default).
    case normal = "Normal"

    /// Compatible alias for Normal.
    case compatible = "Compatible"

    /// Multiply blend mode.
    case multiply = "Multiply"

    /// Screen blend mode.
    case screen = "Screen"

    /// Overlay blend mode.
    case overlay = "Overlay"

    /// Darken blend mode.
    case darken = "Darken"

    /// Lighten blend mode.
    case lighten = "Lighten"

    /// Color dodge blend mode.
    case colorDodge = "ColorDodge"

    /// Color burn blend mode.
    case colorBurn = "ColorBurn"

    /// Hard light blend mode.
    case hardLight = "HardLight"

    /// Soft light blend mode.
    case softLight = "SoftLight"

    /// Difference blend mode.
    case difference = "Difference"

    /// Exclusion blend mode.
    case exclusion = "Exclusion"

    /// Hue blend mode (non-separable).
    case hue = "Hue"

    /// Saturation blend mode (non-separable).
    case saturation = "Saturation"

    /// Color blend mode (non-separable).
    case color = "Color"

    /// Luminosity blend mode (non-separable).
    case luminosity = "Luminosity"

    /// Whether this is the default (normal) blend mode.
    public var isNormal: Bool {
        self == .normal || self == .compatible
    }

    /// Whether this blend mode involves transparency effects.
    ///
    /// All blend modes except Normal/Compatible involve transparency.
    public var involvesTransparency: Bool {
        !isNormal
    }

    /// Creates a blend mode from a string.
    ///
    /// - Parameter value: The blend mode name.
    /// - Returns: The matching blend mode, or `nil` if unrecognized.
    public static func from(_ value: String) -> BlendMode? {
        BlendMode(rawValue: value)
    }
}

// MARK: - Validated ExtGState
//
// Note: RenderingIntent enum is defined in Operators/GraphicsStateValidator.swift
// and reused here to avoid duplication.

/// A validation wrapper for a PDF extended graphics state (ExtGState).
///
/// The ExtGState dictionary specifies additional graphics state parameters beyond
/// those set by content stream operators. This struct wraps the ExtGState dictionary
/// for validation purposes.
///
/// ## Key Properties
///
/// - **Transparency**: Blend mode, alpha values, soft mask
/// - **Line Style**: Line width, cap, join, dash, miter limit
/// - **Text State**: Font, font size, rendering mode
/// - **Color**: Rendering intent, overprint settings
/// - **Other**: Halftone, transfer function, black generation, undercolor removal
///
/// ## Validation Rules
///
/// - **PDF/A-1**: Transparency (blend modes other than Normal, alpha values other
///   than 1.0, soft masks) is **prohibited**.
/// - **PDF/A-2+**: Transparency is allowed but must follow specific rules.
/// - **PDF/UA**: ExtGState parameters may affect text rendering and accessibility.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDExtGState` from veraPDF-validation.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent validation
/// - Uses enum types for blend mode and rendering intent
public struct ValidatedExtGState: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the ExtGState.
    public let cosDictionary: COSValue?

    /// The object key for the ExtGState, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Transparency Properties

    /// The blend mode (`/BM` entry).
    public let blendMode: BlendMode?

    /// The stroking alpha constant (`/CA` entry, 0.0 to 1.0).
    ///
    /// A value of `nil` means the default (1.0, fully opaque).
    public let strokingAlpha: Double?

    /// The non-stroking (fill) alpha constant (`/ca` entry, 0.0 to 1.0).
    ///
    /// A value of `nil` means the default (1.0, fully opaque).
    public let nonStrokingAlpha: Double?

    /// Whether a soft mask is present (`/SMask` entry is not `/None`).
    public let hasSoftMask: Bool

    /// The soft mask type, if present (e.g., "Alpha", "Luminosity").
    public let softMaskSubtype: String?

    /// Whether the alpha source flag is set (`/AIS` entry).
    public let alphaIsShape: Bool

    // MARK: - Line Style Properties

    /// The line width (`/LW` entry).
    public let lineWidth: Double?

    /// The line cap style (`/LC` entry).
    public let lineCap: Int?

    /// The line join style (`/LJ` entry).
    public let lineJoin: Int?

    /// The miter limit (`/ML` entry).
    public let miterLimit: Double?

    /// Whether a dash pattern is set (`/D` entry).
    public let hasDashPattern: Bool

    // MARK: - Text State Properties

    /// Whether a font is specified (`/Font` entry).
    public let hasFont: Bool

    /// The font name from the Font entry, if present.
    public let fontName: String?

    /// The font size from the Font entry, if present.
    public let fontSize: Double?

    // MARK: - Color Properties

    /// The rendering intent (`/RI` entry).
    public let renderingIntent: RenderingIntent?

    /// Whether overprint is enabled for stroking (`/OP` entry).
    public let overprintStroking: Bool?

    /// Whether overprint is enabled for non-stroking (`/op` entry).
    public let overprintNonStroking: Bool?

    /// The overprint mode (`/OPM` entry).
    public let overprintMode: Int?

    // MARK: - Other Properties

    /// Whether a halftone dictionary is present (`/HT` entry).
    public let hasHalftone: Bool

    /// The flatness tolerance (`/FL` entry).
    public let flatness: Double?

    /// The smoothness tolerance (`/SM` entry).
    public let smoothness: Double?

    /// Whether stroke adjustment is enabled (`/SA` entry).
    public let strokeAdjustment: Bool?

    /// Whether a transfer function is present (`/TR` or `/TR2` entry).
    public let hasTransferFunction: Bool

    /// Whether the transfer function is the identity function (`/Default`).
    public let isDefaultTransferFunction: Bool

    /// Whether a black generation function is present (`/BG` or `/BG2` entry).
    public let hasBlackGeneration: Bool

    /// Whether a UCR (undercolor removal) function is present (`/UCR` or `/UCR2` entry).
    public let hasUndercolorRemoval: Bool

    // MARK: - Initialization

    /// Creates a validated ExtGState.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the ExtGState.
    ///   - objectKey: The object key.
    ///   - context: Validation context.
    ///   - blendMode: The blend mode.
    ///   - strokingAlpha: The stroking alpha constant.
    ///   - nonStrokingAlpha: The non-stroking alpha constant.
    ///   - hasSoftMask: Whether a soft mask is present.
    ///   - softMaskSubtype: The soft mask subtype.
    ///   - alphaIsShape: Whether alpha is shape.
    ///   - lineWidth: The line width.
    ///   - lineCap: The line cap style.
    ///   - lineJoin: The line join style.
    ///   - miterLimit: The miter limit.
    ///   - hasDashPattern: Whether a dash pattern exists.
    ///   - hasFont: Whether a font is specified.
    ///   - fontName: The font name.
    ///   - fontSize: The font size.
    ///   - renderingIntent: The rendering intent.
    ///   - overprintStroking: Whether stroking overprint is enabled.
    ///   - overprintNonStroking: Whether non-stroking overprint is enabled.
    ///   - overprintMode: The overprint mode.
    ///   - hasHalftone: Whether a halftone exists.
    ///   - flatness: The flatness tolerance.
    ///   - smoothness: The smoothness tolerance.
    ///   - strokeAdjustment: Whether stroke adjustment is enabled.
    ///   - hasTransferFunction: Whether a transfer function exists.
    ///   - isDefaultTransferFunction: Whether the transfer function is identity.
    ///   - hasBlackGeneration: Whether a black generation function exists.
    ///   - hasUndercolorRemoval: Whether a UCR function exists.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(location: "ExtGState"),
        blendMode: BlendMode? = nil,
        strokingAlpha: Double? = nil,
        nonStrokingAlpha: Double? = nil,
        hasSoftMask: Bool = false,
        softMaskSubtype: String? = nil,
        alphaIsShape: Bool = false,
        lineWidth: Double? = nil,
        lineCap: Int? = nil,
        lineJoin: Int? = nil,
        miterLimit: Double? = nil,
        hasDashPattern: Bool = false,
        hasFont: Bool = false,
        fontName: String? = nil,
        fontSize: Double? = nil,
        renderingIntent: RenderingIntent? = nil,
        overprintStroking: Bool? = nil,
        overprintNonStroking: Bool? = nil,
        overprintMode: Int? = nil,
        hasHalftone: Bool = false,
        flatness: Double? = nil,
        smoothness: Double? = nil,
        strokeAdjustment: Bool? = nil,
        hasTransferFunction: Bool = false,
        isDefaultTransferFunction: Bool = true,
        hasBlackGeneration: Bool = false,
        hasUndercolorRemoval: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.blendMode = blendMode
        self.strokingAlpha = strokingAlpha
        self.nonStrokingAlpha = nonStrokingAlpha
        self.hasSoftMask = hasSoftMask
        self.softMaskSubtype = softMaskSubtype
        self.alphaIsShape = alphaIsShape
        self.lineWidth = lineWidth
        self.lineCap = lineCap
        self.lineJoin = lineJoin
        self.miterLimit = miterLimit
        self.hasDashPattern = hasDashPattern
        self.hasFont = hasFont
        self.fontName = fontName
        self.fontSize = fontSize
        self.renderingIntent = renderingIntent
        self.overprintStroking = overprintStroking
        self.overprintNonStroking = overprintNonStroking
        self.overprintMode = overprintMode
        self.hasHalftone = hasHalftone
        self.flatness = flatness
        self.smoothness = smoothness
        self.strokeAdjustment = strokeAdjustment
        self.hasTransferFunction = hasTransferFunction
        self.isDefaultTransferFunction = isDefaultTransferFunction
        self.hasBlackGeneration = hasBlackGeneration
        self.hasUndercolorRemoval = hasUndercolorRemoval
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDExtGState"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "blendMode", "strokingAlpha", "nonStrokingAlpha",
            "hasSoftMask", "softMaskSubtype", "alphaIsShape",
            "lineWidth", "lineCap", "lineJoin", "miterLimit", "hasDashPattern",
            "hasFont", "fontName", "fontSize",
            "renderingIntent",
            "overprintStroking", "overprintNonStroking", "overprintMode",
            "hasHalftone", "flatness", "smoothness", "strokeAdjustment",
            "hasTransferFunction", "isDefaultTransferFunction",
            "hasBlackGeneration", "hasUndercolorRemoval",
            "involvesTransparency", "isTransparent",
            "isPDFA1Compliant", "containsTransparency"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "blendMode":
            if let bm = blendMode {
                return .string(bm.rawValue)
            }
            return .null
        case "strokingAlpha":
            if let sa = strokingAlpha {
                return .real(sa)
            }
            return .null
        case "nonStrokingAlpha":
            if let nsa = nonStrokingAlpha {
                return .real(nsa)
            }
            return .null
        case "hasSoftMask":
            return .boolean(hasSoftMask)
        case "softMaskSubtype":
            if let sms = softMaskSubtype {
                return .string(sms)
            }
            return .null
        case "alphaIsShape":
            return .boolean(alphaIsShape)
        case "lineWidth":
            if let lw = lineWidth {
                return .real(lw)
            }
            return .null
        case "lineCap":
            if let lc = lineCap {
                return .integer(Int64(lc))
            }
            return .null
        case "lineJoin":
            if let lj = lineJoin {
                return .integer(Int64(lj))
            }
            return .null
        case "miterLimit":
            if let ml = miterLimit {
                return .real(ml)
            }
            return .null
        case "hasDashPattern":
            return .boolean(hasDashPattern)
        case "hasFont":
            return .boolean(hasFont)
        case "fontName":
            if let fn = fontName {
                return .string(fn)
            }
            return .null
        case "fontSize":
            if let fs = fontSize {
                return .real(fs)
            }
            return .null
        case "renderingIntent":
            if let ri = renderingIntent {
                return .string(ri.rawValue)
            }
            return .null
        case "overprintStroking":
            if let op = overprintStroking {
                return .boolean(op)
            }
            return .null
        case "overprintNonStroking":
            if let op = overprintNonStroking {
                return .boolean(op)
            }
            return .null
        case "overprintMode":
            if let opm = overprintMode {
                return .integer(Int64(opm))
            }
            return .null
        case "hasHalftone":
            return .boolean(hasHalftone)
        case "flatness":
            if let fl = flatness {
                return .real(fl)
            }
            return .null
        case "smoothness":
            if let sm = smoothness {
                return .real(sm)
            }
            return .null
        case "strokeAdjustment":
            if let sa = strokeAdjustment {
                return .boolean(sa)
            }
            return .null
        case "hasTransferFunction":
            return .boolean(hasTransferFunction)
        case "isDefaultTransferFunction":
            return .boolean(isDefaultTransferFunction)
        case "hasBlackGeneration":
            return .boolean(hasBlackGeneration)
        case "hasUndercolorRemoval":
            return .boolean(hasUndercolorRemoval)
        case "involvesTransparency":
            return .boolean(involvesTransparency)
        case "isTransparent":
            return .boolean(isTransparent)
        case "isPDFA1Compliant":
            return .boolean(isPDFA1Compliant)
        case "containsTransparency":
            return .boolean(containsTransparency)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedExtGState, rhs: ValidatedExtGState) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedExtGState {

    /// Whether this ExtGState involves any transparency features.
    ///
    /// Transparency features include non-normal blend modes, alpha values
    /// other than 1.0, and soft masks.
    public var involvesTransparency: Bool {
        if let bm = blendMode, bm.involvesTransparency {
            return true
        }
        if let sa = strokingAlpha, sa < 1.0 {
            return true
        }
        if let nsa = nonStrokingAlpha, nsa < 1.0 {
            return true
        }
        if hasSoftMask {
            return true
        }
        return false
    }

    /// Whether this ExtGState makes content transparent.
    ///
    /// Content is transparent if any alpha value is less than 1.0
    /// or if a soft mask is applied.
    public var isTransparent: Bool {
        if let sa = strokingAlpha, sa < 1.0 { return true }
        if let nsa = nonStrokingAlpha, nsa < 1.0 { return true }
        if hasSoftMask { return true }
        return false
    }

    /// Whether this ExtGState contains any transparency-related settings.
    ///
    /// This is broader than `involvesTransparency` -- it checks whether
    /// any transparency-related keys are present, even if their values
    /// do not create actual transparency.
    public var containsTransparency: Bool {
        blendMode != nil || strokingAlpha != nil ||
        nonStrokingAlpha != nil || hasSoftMask || alphaIsShape
    }

    /// Whether this ExtGState is compliant with PDF/A-1.
    ///
    /// PDF/A-1 prohibits transparency features. This checks that:
    /// - Blend mode is Normal or absent
    /// - Alpha values are 1.0 or absent
    /// - No soft mask is present
    /// - Transfer functions are default (identity) or absent
    public var isPDFA1Compliant: Bool {
        // Check blend mode
        if let bm = blendMode, bm.involvesTransparency {
            return false
        }
        // Check alpha values
        if let sa = strokingAlpha, sa < 1.0 {
            return false
        }
        if let nsa = nonStrokingAlpha, nsa < 1.0 {
            return false
        }
        // Check soft mask
        if hasSoftMask {
            return false
        }
        // Check transfer function
        if hasTransferFunction && !isDefaultTransferFunction {
            return false
        }
        return true
    }

    /// The effective stroking alpha (defaults to 1.0 if not set).
    public var effectiveStrokingAlpha: Double {
        strokingAlpha ?? 1.0
    }

    /// The effective non-stroking alpha (defaults to 1.0 if not set).
    public var effectiveNonStrokingAlpha: Double {
        nonStrokingAlpha ?? 1.0
    }

    /// The effective blend mode (defaults to Normal if not set).
    public var effectiveBlendMode: BlendMode {
        blendMode ?? .normal
    }

    /// Returns a summary string describing the ExtGState.
    public var summary: String {
        var parts: [String] = []
        if let bm = blendMode { parts.append("BM=\(bm.rawValue)") }
        if let sa = strokingAlpha { parts.append("CA=\(sa)") }
        if let nsa = nonStrokingAlpha { parts.append("ca=\(nsa)") }
        if hasSoftMask { parts.append("SMask") }
        if let lw = lineWidth { parts.append("LW=\(lw)") }
        if hasFont { parts.append("Font") }
        if involvesTransparency { parts.append("[transparency]") }
        return parts.isEmpty ? "ExtGState (default)" : parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedExtGState {

    /// Creates a minimal ExtGState with default (opaque) settings for testing.
    ///
    /// - Returns: A minimal ExtGState with no transparency.
    public static func opaque() -> ValidatedExtGState {
        ValidatedExtGState()
    }

    /// Creates an ExtGState with transparency settings for testing.
    ///
    /// - Parameters:
    ///   - blendMode: The blend mode.
    ///   - strokingAlpha: The stroking alpha.
    ///   - nonStrokingAlpha: The non-stroking alpha.
    /// - Returns: An ExtGState with transparency.
    public static func transparent(
        blendMode: BlendMode = .normal,
        strokingAlpha: Double = 0.5,
        nonStrokingAlpha: Double = 0.5
    ) -> ValidatedExtGState {
        ValidatedExtGState(
            blendMode: blendMode,
            strokingAlpha: strokingAlpha,
            nonStrokingAlpha: nonStrokingAlpha
        )
    }

    /// Creates an ExtGState with a soft mask for testing.
    ///
    /// - Parameter subtype: The soft mask subtype.
    /// - Returns: An ExtGState with a soft mask.
    public static func withSoftMask(
        subtype: String = "Alpha"
    ) -> ValidatedExtGState {
        ValidatedExtGState(
            hasSoftMask: true,
            softMaskSubtype: subtype
        )
    }
}
