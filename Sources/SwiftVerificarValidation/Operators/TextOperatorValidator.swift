import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Text Rendering Mode

/// Text rendering modes as defined in PDF specification.
public enum TextRenderingMode: Int, Sendable, CaseIterable {
    /// Fill text.
    case fill = 0

    /// Stroke text.
    case stroke = 1

    /// Fill then stroke text.
    case fillStroke = 2

    /// Invisible text.
    case invisible = 3

    /// Fill text and add to clipping path.
    case fillClip = 4

    /// Stroke text and add to clipping path.
    case strokeClip = 5

    /// Fill, stroke, and add to clipping path.
    case fillStrokeClip = 6

    /// Add text to clipping path only.
    case clip = 7

    /// Whether this mode involves filling.
    public var involvesFill: Bool {
        switch self {
        case .fill, .fillStroke, .fillClip, .fillStrokeClip:
            return true
        default:
            return false
        }
    }

    /// Whether this mode involves stroking.
    public var involvesStroke: Bool {
        switch self {
        case .stroke, .fillStroke, .strokeClip, .fillStrokeClip:
            return true
        default:
            return false
        }
    }

    /// Whether this mode involves clipping.
    public var involvesClip: Bool {
        switch self {
        case .fillClip, .strokeClip, .fillStrokeClip, .clip:
            return true
        default:
            return false
        }
    }

    /// Whether text is visible in this mode.
    public var isVisible: Bool {
        self != .invisible && self != .clip
    }
}

// MARK: - Text Validation Result

/// Result of validating a text operator.
public struct TextValidationResult: Sendable, Equatable {

    /// Whether the validation passed.
    public let isValid: Bool

    /// Any issues found during validation.
    public let issues: [TextValidationIssue]

    /// Creates a successful validation result.
    public static func success() -> TextValidationResult {
        TextValidationResult(isValid: true, issues: [])
    }

    /// Creates a failed validation result.
    public static func failure(issues: [TextValidationIssue]) -> TextValidationResult {
        TextValidationResult(isValid: false, issues: issues)
    }
}

// MARK: - Text Validation Issue

/// An issue found during text operator validation.
public enum TextValidationIssue: Sendable, Equatable, CustomStringConvertible {

    /// Text operator used outside a text object (BT/ET).
    case textOperatorOutsideTextObject(operator: String)

    /// No font selected before text showing operator.
    case noFontSelected

    /// Invalid font size (zero or negative).
    case invalidFontSize(size: Double)

    /// Invalid text rendering mode.
    case invalidTextRenderingMode(mode: Int)

    /// Invalid horizontal scaling (zero).
    case invalidHorizontalScaling(scale: Double)

    /// Nested BT operator.
    case nestedBeginText

    /// ET without matching BT.
    case unmatchedEndText

    /// Text matrix is singular (non-invertible).
    case singularTextMatrix

    /// Invalid character spacing.
    case invalidCharacterSpacing(value: Double)

    /// Invalid word spacing.
    case invalidWordSpacing(value: Double)

    /// Empty text string.
    case emptyTextString

    /// Text uses undefined font.
    case undefinedFont(name: String)

    /// Font embedding required but not embedded.
    case fontNotEmbedded(name: String)

    /// Text uses glyph not in font.
    case glyphNotInFont(glyph: UInt16, font: String)

    /// Unicode mapping missing (PDF/A requirement).
    case missingUnicodeMapping(font: String)

    public var description: String {
        switch self {
        case .textOperatorOutsideTextObject(let op):
            return "Text operator '\(op)' used outside text object (BT/ET)"
        case .noFontSelected:
            return "No font selected before text showing operator"
        case .invalidFontSize(let size):
            return "Invalid font size: \(size)"
        case .invalidTextRenderingMode(let mode):
            return "Invalid text rendering mode: \(mode)"
        case .invalidHorizontalScaling(let scale):
            return "Invalid horizontal scaling: \(scale)"
        case .nestedBeginText:
            return "Nested BT operator (BT inside existing text object)"
        case .unmatchedEndText:
            return "Unmatched ET operator (ET without preceding BT)"
        case .singularTextMatrix:
            return "Text matrix is singular (non-invertible)"
        case .invalidCharacterSpacing(let value):
            return "Invalid character spacing: \(value)"
        case .invalidWordSpacing(let value):
            return "Invalid word spacing: \(value)"
        case .emptyTextString:
            return "Empty text string"
        case .undefinedFont(let name):
            return "Undefined font: \(name)"
        case .fontNotEmbedded(let name):
            return "Font not embedded: \(name)"
        case .glyphNotInFont(let glyph, let font):
            return "Glyph \(glyph) not found in font \(font)"
        case .missingUnicodeMapping(let font):
            return "Missing Unicode mapping for font: \(font)"
        }
    }

    /// The severity of this issue.
    public var severity: IssueSeverity {
        switch self {
        case .textOperatorOutsideTextObject, .nestedBeginText, .unmatchedEndText:
            return .error
        case .noFontSelected, .undefinedFont, .fontNotEmbedded, .missingUnicodeMapping:
            return .error
        case .invalidFontSize, .invalidTextRenderingMode, .singularTextMatrix:
            return .error
        case .invalidHorizontalScaling, .invalidCharacterSpacing, .invalidWordSpacing:
            return .warning
        case .emptyTextString, .glyphNotInFont:
            return .warning
        }
    }
}

// MARK: - Text Operator Validator

/// Validates text-related operators in PDF content streams.
///
/// This struct provides validation for:
/// - BT/ET pairing and nesting
/// - Font selection before text showing
/// - Text state parameter validity
/// - Text rendering mode validity
///
/// Corresponds to the Java `GFOp_BT`, `GFOp_ET`, `GFOp_Tj`, etc. classes
/// from veraPDF-validation, consolidated into a single validator.
public struct TextOperatorValidator: Sendable {

    // MARK: - Configuration

    /// Whether to require font embedding (for PDF/A).
    public let requireFontEmbedding: Bool

    /// Whether to require Unicode mappings (for PDF/A).
    public let requireUnicodeMappings: Bool

    /// Whether to allow empty text strings.
    public let allowEmptyText: Bool

    /// Known fonts in the document resources.
    public let knownFonts: Set<String>

    /// Embedded fonts in the document.
    public let embeddedFonts: Set<String>

    // MARK: - Initialization

    /// Creates a text operator validator with default settings.
    public init() {
        self.requireFontEmbedding = false
        self.requireUnicodeMappings = false
        self.allowEmptyText = true
        self.knownFonts = []
        self.embeddedFonts = []
    }

    /// Creates a text operator validator with custom settings.
    public init(
        requireFontEmbedding: Bool,
        requireUnicodeMappings: Bool,
        allowEmptyText: Bool = true,
        knownFonts: Set<String> = [],
        embeddedFonts: Set<String> = []
    ) {
        self.requireFontEmbedding = requireFontEmbedding
        self.requireUnicodeMappings = requireUnicodeMappings
        self.allowEmptyText = allowEmptyText
        self.knownFonts = knownFonts
        self.embeddedFonts = embeddedFonts
    }

    // MARK: - Validation

    /// Validates a text operator.
    ///
    /// - Parameters:
    ///   - op: The text operator to validate.
    ///   - context: The current validation context.
    /// - Returns: The validation result.
    public func validate(
        _ op: ValidatedOperator,
        in context: OperatorValidationContext
    ) -> TextValidationResult {
        switch op {
        case .beginText:
            return validateBeginText(context: context)

        case .endText:
            return validateEndText(context: context)

        case .setFont(let name, let size):
            return validateSetFont(name: name, size: size, context: context)

        case .setCharacterSpacing(let spacing):
            return validateCharacterSpacing(spacing)

        case .setWordSpacing(let spacing):
            return validateWordSpacing(spacing)

        case .setHorizontalScaling(let scale):
            return validateHorizontalScaling(scale)

        case .setTextRenderingMode(let mode):
            return validateTextRenderingMode(mode)

        case .setTextMatrix(let a, let b, let c, let d, _, _):
            return validateTextMatrix(a: a, b: b, c: c, d: d)

        case .showText(let data):
            return validateShowText(data: data, context: context)

        case .showTextArray(let elements):
            return validateShowTextArray(elements: elements, context: context)

        case .moveAndShowText(let data):
            return validateShowText(data: data, context: context)

        case .moveAndShowTextWithSpacing(_, _, let data):
            return validateShowText(data: data, context: context)

        case .setTextLeading, .setTextRise, .moveTextPosition,
             .moveTextPositionLeading, .moveToNextLine:
            // These operators require being in a text object
            return validateTextObjectContext(operator: op.operatorName, context: context)

        default:
            // Not a text operator
            return .success()
        }
    }

    // MARK: - Private Validation Methods

    /// Validates the BT operator.
    private func validateBeginText(context: OperatorValidationContext) -> TextValidationResult {
        if context.inTextObject {
            return .failure(issues: [.nestedBeginText])
        }
        return .success()
    }

    /// Validates the ET operator.
    private func validateEndText(context: OperatorValidationContext) -> TextValidationResult {
        if !context.inTextObject {
            return .failure(issues: [.unmatchedEndText])
        }
        return .success()
    }

    /// Validates the Tf operator.
    private func validateSetFont(
        name: ASAtom,
        size: Double,
        context: OperatorValidationContext
    ) -> TextValidationResult {
        var issues: [TextValidationIssue] = []

        // Check font size
        if size <= 0 {
            issues.append(.invalidFontSize(size: size))
        }

        // Check if font is known (if we have font information)
        if !knownFonts.isEmpty && !knownFonts.contains(name.stringValue) {
            issues.append(.undefinedFont(name: name.stringValue))
        }

        // Check font embedding for PDF/A
        if requireFontEmbedding && !embeddedFonts.isEmpty {
            if !embeddedFonts.contains(name.stringValue) {
                issues.append(.fontNotEmbedded(name: name.stringValue))
            }
        }

        if issues.isEmpty {
            return .success()
        } else {
            return .failure(issues: issues)
        }
    }

    /// Validates character spacing.
    private func validateCharacterSpacing(_ spacing: Double) -> TextValidationResult {
        // Character spacing can be negative (for condensing)
        // but extremely large values might indicate an error
        if abs(spacing) > 10000 {
            return .failure(issues: [.invalidCharacterSpacing(value: spacing)])
        }
        return .success()
    }

    /// Validates word spacing.
    private func validateWordSpacing(_ spacing: Double) -> TextValidationResult {
        // Word spacing can be negative
        if abs(spacing) > 10000 {
            return .failure(issues: [.invalidWordSpacing(value: spacing)])
        }
        return .success()
    }

    /// Validates horizontal scaling.
    private func validateHorizontalScaling(_ scale: Double) -> TextValidationResult {
        if scale == 0 {
            return .failure(issues: [.invalidHorizontalScaling(scale: scale)])
        }
        return .success()
    }

    /// Validates text rendering mode.
    private func validateTextRenderingMode(_ mode: Int) -> TextValidationResult {
        if mode < 0 || mode > 7 {
            return .failure(issues: [.invalidTextRenderingMode(mode: mode)])
        }
        return .success()
    }

    /// Validates text matrix.
    private func validateTextMatrix(a: Double, b: Double, c: Double, d: Double) -> TextValidationResult {
        // Check if matrix is singular (determinant is zero)
        let determinant = a * d - b * c
        if abs(determinant) < 1e-10 {
            return .failure(issues: [.singularTextMatrix])
        }
        return .success()
    }

    /// Validates a text showing operator.
    private func validateShowText(
        data: Data,
        context: OperatorValidationContext
    ) -> TextValidationResult {
        var issues: [TextValidationIssue] = []

        // Must be in a text object
        if !context.inTextObject {
            issues.append(.textOperatorOutsideTextObject(operator: "Tj"))
        }

        // Must have a font selected
        if !context.textState.hasFontSelected {
            issues.append(.noFontSelected)
        }

        // Check for empty text
        if !allowEmptyText && data.isEmpty {
            issues.append(.emptyTextString)
        }

        if issues.isEmpty {
            return .success()
        } else {
            return .failure(issues: issues)
        }
    }

    /// Validates a TJ text array operator.
    private func validateShowTextArray(
        elements: [ValidatedTextArrayElement],
        context: OperatorValidationContext
    ) -> TextValidationResult {
        var issues: [TextValidationIssue] = []

        // Must be in a text object
        if !context.inTextObject {
            issues.append(.textOperatorOutsideTextObject(operator: "TJ"))
        }

        // Must have a font selected
        if !context.textState.hasFontSelected {
            issues.append(.noFontSelected)
        }

        // Check for any text content
        if !allowEmptyText {
            let hasText = elements.contains { element in
                if case .text(let data) = element {
                    return !data.isEmpty
                }
                return false
            }
            if !hasText {
                issues.append(.emptyTextString)
            }
        }

        if issues.isEmpty {
            return .success()
        } else {
            return .failure(issues: issues)
        }
    }

    /// Validates that we're in a text object context.
    private func validateTextObjectContext(
        operator op: String,
        context: OperatorValidationContext
    ) -> TextValidationResult {
        if !context.inTextObject {
            return .failure(issues: [.textOperatorOutsideTextObject(operator: op)])
        }
        return .success()
    }
}

// MARK: - PDF/A Text Validator

/// Extended text validator for PDF/A compliance.
public struct PDFATextValidator: Sendable {

    /// The base text validator.
    private let baseValidator: TextOperatorValidator

    /// The PDF/A conformance level.
    public let conformanceLevel: PDFATextConformance

    /// Creates a PDF/A text validator.
    public init(
        conformanceLevel: PDFATextConformance,
        knownFonts: Set<String> = [],
        embeddedFonts: Set<String> = []
    ) {
        self.conformanceLevel = conformanceLevel
        self.baseValidator = TextOperatorValidator(
            requireFontEmbedding: conformanceLevel.requiresFontEmbedding,
            requireUnicodeMappings: conformanceLevel.requiresUnicodeMappings,
            allowEmptyText: true,
            knownFonts: knownFonts,
            embeddedFonts: embeddedFonts
        )
    }

    /// Validates a text operator for PDF/A compliance.
    public func validate(
        _ op: ValidatedOperator,
        in context: OperatorValidationContext
    ) -> TextValidationResult {
        baseValidator.validate(op, in: context)
    }
}

// MARK: - PDF/A Text Conformance

/// PDF/A conformance levels for text validation.
public enum PDFATextConformance: String, Sendable, CaseIterable {
    case pdfa1a = "PDF/A-1a"
    case pdfa1b = "PDF/A-1b"
    case pdfa2a = "PDF/A-2a"
    case pdfa2b = "PDF/A-2b"
    case pdfa2u = "PDF/A-2u"
    case pdfa3a = "PDF/A-3a"
    case pdfa3b = "PDF/A-3b"
    case pdfa3u = "PDF/A-3u"
    case pdfa4 = "PDF/A-4"

    /// Whether font embedding is required.
    public var requiresFontEmbedding: Bool {
        true  // All PDF/A levels require embedded fonts
    }

    /// Whether Unicode mappings are required.
    public var requiresUnicodeMappings: Bool {
        switch self {
        case .pdfa1a, .pdfa2a, .pdfa2u, .pdfa3a, .pdfa3u, .pdfa4:
            return true
        case .pdfa1b, .pdfa2b, .pdfa3b:
            return false
        }
    }

    /// Whether this is an "a" level conformance (accessibility).
    public var isAccessibilityLevel: Bool {
        switch self {
        case .pdfa1a, .pdfa2a, .pdfa3a:
            return true
        default:
            return false
        }
    }
}

// MARK: - Font Validation Info

/// Information about a font for validation purposes.
public struct FontValidationInfo: Sendable, Equatable {

    /// The font name.
    public let name: String

    /// Whether the font is embedded.
    public let isEmbedded: Bool

    /// Whether the font has a ToUnicode map.
    public let hasToUnicode: Bool

    /// Whether the font is a symbolic font.
    public let isSymbolic: Bool

    /// The font type (Type1, TrueType, Type0, etc.).
    public let fontType: String

    /// The font encoding, if specified.
    public let encoding: String?

    /// Creates font validation info.
    public init(
        name: String,
        isEmbedded: Bool,
        hasToUnicode: Bool,
        isSymbolic: Bool = false,
        fontType: String = "Type1",
        encoding: String? = nil
    ) {
        self.name = name
        self.isEmbedded = isEmbedded
        self.hasToUnicode = hasToUnicode
        self.isSymbolic = isSymbolic
        self.fontType = fontType
        self.encoding = encoding
    }

    /// Whether this font meets PDF/A requirements.
    public func meetsPDFARequirements(level: PDFATextConformance) -> Bool {
        // All PDF/A levels require embedding
        guard isEmbedded else { return false }

        // "a" and "u" levels require Unicode mapping
        if level.requiresUnicodeMappings && !hasToUnicode && !isSymbolic {
            return false
        }

        return true
    }
}
