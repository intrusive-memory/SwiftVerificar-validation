import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Line Cap Style

/// PDF line cap styles.
public enum LineCapStyle: Int, Sendable, CaseIterable {
    /// Butt cap - the stroke is squared off at the endpoint.
    case butt = 0

    /// Round cap - a semicircular arc with diameter equal to line width.
    case round = 1

    /// Projecting square cap - the stroke extends beyond the endpoint.
    case projectingSquare = 2
}

// MARK: - Line Join Style

/// PDF line join styles.
public enum LineJoinStyle: Int, Sendable, CaseIterable {
    /// Miter join - the outer edges of the strokes are extended until they meet.
    case miter = 0

    /// Round join - an arc of a circle is drawn around the point.
    case round = 1

    /// Bevel join - the two segments are squared off at their endpoints.
    case bevel = 2
}

// MARK: - Rendering Intent

/// PDF color rendering intents.
public enum RenderingIntent: String, Sendable, CaseIterable {
    case absoluteColorimetric = "AbsoluteColorimetric"
    case relativeColorimetric = "RelativeColorimetric"
    case saturation = "Saturation"
    case perceptual = "Perceptual"

    /// Creates from an ASAtom, returning nil for invalid values.
    public init?(from atom: ASAtom) {
        self.init(rawValue: atom.stringValue)
    }
}

// MARK: - Graphics State Validation Result

/// Result of validating a graphics state operator.
public struct GraphicsStateValidationResult: Sendable, Equatable {

    /// Whether the validation passed.
    public let isValid: Bool

    /// Any issues found during validation.
    public let issues: [GraphicsStateValidationIssue]

    /// Creates a successful validation result.
    public static func success() -> GraphicsStateValidationResult {
        GraphicsStateValidationResult(isValid: true, issues: [])
    }

    /// Creates a failed validation result.
    public static func failure(issues: [GraphicsStateValidationIssue]) -> GraphicsStateValidationResult {
        GraphicsStateValidationResult(isValid: false, issues: issues)
    }
}

// MARK: - Graphics State Validation Issue

/// An issue found during graphics state operator validation.
public enum GraphicsStateValidationIssue: Sendable, Equatable, CustomStringConvertible {

    // Stack issues
    case graphicsStateStackUnderflow
    case graphicsStateStackOverflow(depth: Int)
    case unmatchedSaveState(count: Int)
    case unmatchedRestoreState

    // Line state issues
    case invalidLineWidth(width: Double)
    case invalidLineCap(value: Int)
    case invalidLineJoin(value: Int)
    case invalidMiterLimit(limit: Double)
    case invalidDashPattern(reason: String)
    case invalidFlatness(value: Double)

    // Matrix issues
    case singularMatrix
    case invalidMatrixComponents

    // Rendering intent issues
    case invalidRenderingIntent(value: String)

    // ExtGState issues
    case undefinedExtGState(name: String)
    case invalidExtGStateParameter(name: String, parameter: String)

    // Transparency issues
    case transparencyNotAllowed(parameter: String)

    public var description: String {
        switch self {
        case .graphicsStateStackUnderflow:
            return "Graphics state stack underflow: Q without matching q"
        case .graphicsStateStackOverflow(let depth):
            return "Graphics state stack overflow: depth \(depth) exceeds maximum"
        case .unmatchedSaveState(let count):
            return "Unmatched save state: \(count) q operator(s) without matching Q"
        case .unmatchedRestoreState:
            return "Unmatched restore state: Q without matching q"
        case .invalidLineWidth(let width):
            return "Invalid line width: \(width)"
        case .invalidLineCap(let value):
            return "Invalid line cap style: \(value) (must be 0, 1, or 2)"
        case .invalidLineJoin(let value):
            return "Invalid line join style: \(value) (must be 0, 1, or 2)"
        case .invalidMiterLimit(let limit):
            return "Invalid miter limit: \(limit) (must be >= 1)"
        case .invalidDashPattern(let reason):
            return "Invalid dash pattern: \(reason)"
        case .invalidFlatness(let value):
            return "Invalid flatness: \(value) (must be in range 0-100)"
        case .singularMatrix:
            return "Singular matrix: transformation matrix is non-invertible"
        case .invalidMatrixComponents:
            return "Invalid matrix components: contains NaN or Infinity"
        case .invalidRenderingIntent(let value):
            return "Invalid rendering intent: \(value)"
        case .undefinedExtGState(let name):
            return "Undefined extended graphics state: \(name)"
        case .invalidExtGStateParameter(let name, let parameter):
            return "Invalid parameter '\(parameter)' in ExtGState '\(name)'"
        case .transparencyNotAllowed(let parameter):
            return "Transparency not allowed: \(parameter)"
        }
    }

    /// The severity of this issue.
    public var severity: IssueSeverity {
        switch self {
        case .graphicsStateStackUnderflow, .graphicsStateStackOverflow,
             .singularMatrix, .invalidMatrixComponents:
            return .error
        case .unmatchedSaveState, .unmatchedRestoreState:
            return .error
        case .invalidLineCap, .invalidLineJoin, .invalidRenderingIntent:
            return .error
        case .invalidLineWidth, .invalidMiterLimit, .invalidDashPattern, .invalidFlatness:
            return .warning
        case .undefinedExtGState, .invalidExtGStateParameter:
            return .error
        case .transparencyNotAllowed:
            return .error
        }
    }
}

// MARK: - Graphics State Validator

/// Validates graphics state operators in PDF content streams.
///
/// This struct provides validation for:
/// - q/Q pairing and stack depth
/// - Line parameters (width, cap, join, miter limit, dash pattern)
/// - Transformation matrices
/// - Rendering intent
/// - Extended graphics state (gs operator)
///
/// Corresponds to the Java `GFOp_q_gsave`, `GFOp_Q_grestore`, `GFOp_cm`, etc.
/// classes from veraPDF-validation, consolidated into a single validator.
public struct GraphicsStateValidator: Sendable {

    // MARK: - Configuration

    /// Maximum allowed graphics state stack depth.
    public let maxStackDepth: Int

    /// Whether transparency is allowed (false for PDF/A-1).
    public let allowTransparency: Bool

    /// Known extended graphics states in document resources.
    public let knownExtGStates: Set<String>

    /// Extended graphics states with transparency features.
    public let transparentExtGStates: Set<String>

    // MARK: - Initialization

    /// Creates a graphics state validator with default settings.
    public init() {
        self.maxStackDepth = 28  // PDF spec recommendation
        self.allowTransparency = true
        self.knownExtGStates = []
        self.transparentExtGStates = []
    }

    /// Creates a graphics state validator with custom settings.
    public init(
        maxStackDepth: Int = 28,
        allowTransparency: Bool = true,
        knownExtGStates: Set<String> = [],
        transparentExtGStates: Set<String> = []
    ) {
        self.maxStackDepth = maxStackDepth
        self.allowTransparency = allowTransparency
        self.knownExtGStates = knownExtGStates
        self.transparentExtGStates = transparentExtGStates
    }

    // MARK: - Validation

    /// Validates a graphics state operator.
    ///
    /// - Parameters:
    ///   - op: The graphics state operator to validate.
    ///   - context: The current validation context.
    /// - Returns: The validation result.
    public func validate(
        _ op: ValidatedOperator,
        in context: OperatorValidationContext
    ) -> GraphicsStateValidationResult {
        switch op {
        case .saveGraphicsState:
            return validateSaveState(context: context)

        case .restoreGraphicsState:
            return validateRestoreState(context: context)

        case .concatMatrix(let a, let b, let c, let d, let e, let f):
            return validateMatrix(a: a, b: b, c: c, d: d, e: e, f: f)

        case .setLineWidth(let width):
            return validateLineWidth(width)

        case .setLineCap(let cap):
            return validateLineCap(cap)

        case .setLineJoin(let join):
            return validateLineJoin(join)

        case .setMiterLimit(let limit):
            return validateMiterLimit(limit)

        case .setDashPattern(let pattern, let phase):
            return validateDashPattern(pattern: pattern, phase: phase)

        case .setRenderingIntent(let intent):
            return validateRenderingIntent(intent)

        case .setFlatness(let flatness):
            return validateFlatness(flatness)

        case .setExtGState(let name):
            return validateExtGState(name: name)

        default:
            // Not a graphics state operator
            return .success()
        }
    }

    /// Validates the end of a content stream for unmatched states.
    public func validateEndOfStream(
        context: OperatorValidationContext
    ) -> GraphicsStateValidationResult {
        // Check for unmatched save states
        let unmatchedCount = context.graphicsStateDepth - 1  // -1 for initial state
        if unmatchedCount > 0 {
            return .failure(issues: [.unmatchedSaveState(count: unmatchedCount)])
        }
        return .success()
    }

    // MARK: - Private Validation Methods

    /// Validates the q (save state) operator.
    private func validateSaveState(context: OperatorValidationContext) -> GraphicsStateValidationResult {
        // Check stack depth limit
        if context.graphicsStateDepth >= maxStackDepth {
            return .failure(issues: [.graphicsStateStackOverflow(depth: context.graphicsStateDepth)])
        }
        return .success()
    }

    /// Validates the Q (restore state) operator.
    private func validateRestoreState(context: OperatorValidationContext) -> GraphicsStateValidationResult {
        // Check for stack underflow
        if context.graphicsStateDepth <= 1 {
            return .failure(issues: [.graphicsStateStackUnderflow])
        }
        return .success()
    }

    /// Validates a transformation matrix.
    private func validateMatrix(
        a: Double, b: Double, c: Double, d: Double, e: Double, f: Double
    ) -> GraphicsStateValidationResult {
        var issues: [GraphicsStateValidationIssue] = []

        // Check for NaN or Infinity
        let components = [a, b, c, d, e, f]
        for component in components {
            if component.isNaN || component.isInfinite {
                issues.append(.invalidMatrixComponents)
                break
            }
        }

        // Check if matrix is singular (determinant is zero)
        let determinant = a * d - b * c
        if abs(determinant) < 1e-10 && issues.isEmpty {
            issues.append(.singularMatrix)
        }

        if issues.isEmpty {
            return .success()
        } else {
            return .failure(issues: issues)
        }
    }

    /// Validates line width.
    private func validateLineWidth(_ width: Double) -> GraphicsStateValidationResult {
        // Line width must be non-negative
        if width < 0 {
            return .failure(issues: [.invalidLineWidth(width: width)])
        }
        // Line width of 0 means thinnest possible (device-dependent)
        return .success()
    }

    /// Validates line cap style.
    private func validateLineCap(_ cap: Int) -> GraphicsStateValidationResult {
        if cap < 0 || cap > 2 {
            return .failure(issues: [.invalidLineCap(value: cap)])
        }
        return .success()
    }

    /// Validates line join style.
    private func validateLineJoin(_ join: Int) -> GraphicsStateValidationResult {
        if join < 0 || join > 2 {
            return .failure(issues: [.invalidLineJoin(value: join)])
        }
        return .success()
    }

    /// Validates miter limit.
    private func validateMiterLimit(_ limit: Double) -> GraphicsStateValidationResult {
        // Miter limit must be >= 1
        if limit < 1.0 {
            return .failure(issues: [.invalidMiterLimit(limit: limit)])
        }
        return .success()
    }

    /// Validates dash pattern.
    private func validateDashPattern(
        pattern: [Double],
        phase: Double
    ) -> GraphicsStateValidationResult {
        var issues: [GraphicsStateValidationIssue] = []

        // Check for negative values in pattern
        for (index, value) in pattern.enumerated() {
            if value < 0 {
                issues.append(.invalidDashPattern(reason: "negative value at index \(index)"))
                break
            }
        }

        // Check for all-zero pattern (creates invisible line)
        if !pattern.isEmpty && pattern.allSatisfy({ $0 == 0 }) {
            issues.append(.invalidDashPattern(reason: "all values are zero"))
        }

        // Check phase
        if phase < 0 {
            issues.append(.invalidDashPattern(reason: "negative phase"))
        }

        if issues.isEmpty {
            return .success()
        } else {
            return .failure(issues: issues)
        }
    }

    /// Validates rendering intent.
    private func validateRenderingIntent(_ intent: ASAtom) -> GraphicsStateValidationResult {
        if RenderingIntent(from: intent) == nil {
            return .failure(issues: [.invalidRenderingIntent(value: intent.stringValue)])
        }
        return .success()
    }

    /// Validates flatness.
    private func validateFlatness(_ flatness: Double) -> GraphicsStateValidationResult {
        // Flatness must be in range 0-100
        if flatness < 0 || flatness > 100 {
            return .failure(issues: [.invalidFlatness(value: flatness)])
        }
        return .success()
    }

    /// Validates extended graphics state.
    private func validateExtGState(name: ASAtom) -> GraphicsStateValidationResult {
        var issues: [GraphicsStateValidationIssue] = []

        // Check if ExtGState is defined
        if !knownExtGStates.isEmpty && !knownExtGStates.contains(name.stringValue) {
            issues.append(.undefinedExtGState(name: name.stringValue))
        }

        // Check for transparency if not allowed
        if !allowTransparency && transparentExtGStates.contains(name.stringValue) {
            issues.append(.transparencyNotAllowed(parameter: "ExtGState \(name.stringValue)"))
        }

        if issues.isEmpty {
            return .success()
        } else {
            return .failure(issues: issues)
        }
    }

    // MARK: - Utility Methods

    /// Checks if a matrix is identity.
    public func isIdentityMatrix(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) -> Bool {
        let epsilon = 1e-10
        return abs(a - 1) < epsilon &&
               abs(b) < epsilon &&
               abs(c) < epsilon &&
               abs(d - 1) < epsilon &&
               abs(e) < epsilon &&
               abs(f) < epsilon
    }

    /// Calculates the determinant of a transformation matrix.
    public func matrixDeterminant(a: Double, b: Double, c: Double, d: Double) -> Double {
        a * d - b * c
    }
}

// MARK: - PDF/A Graphics State Validator

/// Extended graphics state validator for PDF/A compliance.
public struct PDFAGraphicsStateValidator: Sendable {

    /// The base validator.
    private let baseValidator: GraphicsStateValidator

    /// The PDF/A conformance level.
    public let conformanceLevel: PDFAGraphicsStateConformance

    /// Creates a PDF/A graphics state validator.
    public init(
        conformanceLevel: PDFAGraphicsStateConformance,
        knownExtGStates: Set<String> = [],
        transparentExtGStates: Set<String> = []
    ) {
        self.conformanceLevel = conformanceLevel
        self.baseValidator = GraphicsStateValidator(
            maxStackDepth: 28,
            allowTransparency: conformanceLevel.allowsTransparency,
            knownExtGStates: knownExtGStates,
            transparentExtGStates: transparentExtGStates
        )
    }

    /// Validates a graphics state operator for PDF/A compliance.
    public func validate(
        _ op: ValidatedOperator,
        in context: OperatorValidationContext
    ) -> GraphicsStateValidationResult {
        baseValidator.validate(op, in: context)
    }

    /// Validates the end of stream for PDF/A compliance.
    public func validateEndOfStream(
        context: OperatorValidationContext
    ) -> GraphicsStateValidationResult {
        baseValidator.validateEndOfStream(context: context)
    }
}

// MARK: - PDF/A Graphics State Conformance

/// PDF/A conformance levels for graphics state validation.
public enum PDFAGraphicsStateConformance: String, Sendable, CaseIterable {
    case pdfa1a = "PDF/A-1a"
    case pdfa1b = "PDF/A-1b"
    case pdfa2a = "PDF/A-2a"
    case pdfa2b = "PDF/A-2b"
    case pdfa2u = "PDF/A-2u"
    case pdfa3a = "PDF/A-3a"
    case pdfa3b = "PDF/A-3b"
    case pdfa3u = "PDF/A-3u"
    case pdfa4 = "PDF/A-4"

    /// Whether transparency is allowed.
    public var allowsTransparency: Bool {
        switch self {
        case .pdfa1a, .pdfa1b:
            return false  // PDF/A-1 does not allow transparency
        case .pdfa2a, .pdfa2b, .pdfa2u, .pdfa3a, .pdfa3b, .pdfa3u, .pdfa4:
            return true   // PDF/A-2 and later allow transparency
        }
    }

    /// Maximum allowed graphics state stack depth.
    public var maxStackDepth: Int {
        28  // Same for all levels
    }
}

// MARK: - ExtGState Parameters

/// Parameters that can appear in an ExtGState dictionary.
public enum ExtGStateParameter: String, Sendable, CaseIterable {
    /// Line width (LW).
    case lineWidth = "LW"

    /// Line cap (LC).
    case lineCap = "LC"

    /// Line join (LJ).
    case lineJoin = "LJ"

    /// Miter limit (ML).
    case miterLimit = "ML"

    /// Dash pattern (D).
    case dashPattern = "D"

    /// Rendering intent (RI).
    case renderingIntent = "RI"

    /// Overprint for stroking (OP).
    case overprintStroke = "OP"

    /// Overprint for non-stroking (op).
    case overprintFill = "op"

    /// Overprint mode (OPM).
    case overprintMode = "OPM"

    /// Font (Font).
    case font = "Font"

    /// Black generation function (BG).
    case blackGeneration = "BG"

    /// Black generation function 2 (BG2).
    case blackGeneration2 = "BG2"

    /// Undercolor removal function (UCR).
    case undercolorRemoval = "UCR"

    /// Undercolor removal function 2 (UCR2).
    case undercolorRemoval2 = "UCR2"

    /// Transfer function (TR).
    case transfer = "TR"

    /// Transfer function 2 (TR2).
    case transfer2 = "TR2"

    /// Halftone dictionary (HT).
    case halftone = "HT"

    /// Flatness (FL).
    case flatness = "FL"

    /// Smoothness (SM).
    case smoothness = "SM"

    /// Stroke alpha (CA) - transparency.
    case strokeAlpha = "CA"

    /// Fill alpha (ca) - transparency.
    case fillAlpha = "ca"

    /// Alpha source flag (AIS) - transparency.
    case alphaSource = "AIS"

    /// Text knockout flag (TK) - transparency.
    case textKnockout = "TK"

    /// Blend mode (BM) - transparency.
    case blendMode = "BM"

    /// Soft mask (SMask) - transparency.
    case softMask = "SMask"

    /// Whether this parameter involves transparency.
    public var isTransparencyParameter: Bool {
        switch self {
        case .strokeAlpha, .fillAlpha, .alphaSource, .textKnockout, .blendMode, .softMask:
            return true
        default:
            return false
        }
    }
}
