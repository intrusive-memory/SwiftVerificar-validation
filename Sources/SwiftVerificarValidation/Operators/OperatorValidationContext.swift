import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Graphics State

/// A snapshot of the graphics state at a point in content stream processing.
///
/// This struct captures the graphics state parameters that are relevant for validation,
/// including color, line attributes, and transformation matrix.
public struct GraphicsStateSnapshot: Sendable, Equatable {

    // MARK: - Color State

    /// The current stroking color space name.
    public var strokeColorSpace: ASAtom?

    /// The current non-stroking (fill) color space name.
    public var fillColorSpace: ASAtom?

    /// The current stroking color components.
    public var strokeColor: [Double]

    /// The current non-stroking (fill) color components.
    public var fillColor: [Double]

    // MARK: - Line State

    /// The current line width.
    public var lineWidth: Double

    /// The current line cap style (0, 1, or 2).
    public var lineCap: Int

    /// The current line join style (0, 1, or 2).
    public var lineJoin: Int

    /// The current miter limit.
    public var miterLimit: Double

    /// The current dash pattern.
    public var dashPattern: [Double]

    /// The current dash phase.
    public var dashPhase: Double

    // MARK: - Transformation Matrix

    /// The current transformation matrix components (a, b, c, d, e, f).
    public var ctm: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    // MARK: - Other State

    /// The current color rendering intent.
    public var renderingIntent: ASAtom?

    /// The current flatness tolerance.
    public var flatness: Double

    /// The current extended graphics state name.
    public var extGState: ASAtom?

    // MARK: - Initialization

    /// Creates a default graphics state (initial state for a page).
    public init() {
        // PDF default values per specification
        self.strokeColorSpace = ASAtom("DeviceGray")
        self.fillColorSpace = ASAtom("DeviceGray")
        self.strokeColor = [0.0]  // Black
        self.fillColor = [0.0]    // Black
        self.lineWidth = 1.0
        self.lineCap = 0          // Butt cap
        self.lineJoin = 0         // Miter join
        self.miterLimit = 10.0
        self.dashPattern = []
        self.dashPhase = 0.0
        self.ctm = (a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0)  // Identity
        self.renderingIntent = nil
        self.flatness = 0.0
        self.extGState = nil
    }

    /// Creates a graphics state with specific values.
    public init(
        strokeColorSpace: ASAtom? = ASAtom("DeviceGray"),
        fillColorSpace: ASAtom? = ASAtom("DeviceGray"),
        strokeColor: [Double] = [0.0],
        fillColor: [Double] = [0.0],
        lineWidth: Double = 1.0,
        lineCap: Int = 0,
        lineJoin: Int = 0,
        miterLimit: Double = 10.0,
        dashPattern: [Double] = [],
        dashPhase: Double = 0.0,
        ctm: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) = (1, 0, 0, 1, 0, 0),
        renderingIntent: ASAtom? = nil,
        flatness: Double = 0.0,
        extGState: ASAtom? = nil
    ) {
        self.strokeColorSpace = strokeColorSpace
        self.fillColorSpace = fillColorSpace
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.lineWidth = lineWidth
        self.lineCap = lineCap
        self.lineJoin = lineJoin
        self.miterLimit = miterLimit
        self.dashPattern = dashPattern
        self.dashPhase = dashPhase
        self.ctm = ctm
        self.renderingIntent = renderingIntent
        self.flatness = flatness
        self.extGState = extGState
    }

    // MARK: - Equatable

    public static func == (lhs: GraphicsStateSnapshot, rhs: GraphicsStateSnapshot) -> Bool {
        lhs.strokeColorSpace == rhs.strokeColorSpace &&
        lhs.fillColorSpace == rhs.fillColorSpace &&
        lhs.strokeColor == rhs.strokeColor &&
        lhs.fillColor == rhs.fillColor &&
        lhs.lineWidth == rhs.lineWidth &&
        lhs.lineCap == rhs.lineCap &&
        lhs.lineJoin == rhs.lineJoin &&
        lhs.miterLimit == rhs.miterLimit &&
        lhs.dashPattern == rhs.dashPattern &&
        lhs.dashPhase == rhs.dashPhase &&
        lhs.ctm.a == rhs.ctm.a &&
        lhs.ctm.b == rhs.ctm.b &&
        lhs.ctm.c == rhs.ctm.c &&
        lhs.ctm.d == rhs.ctm.d &&
        lhs.ctm.e == rhs.ctm.e &&
        lhs.ctm.f == rhs.ctm.f &&
        lhs.renderingIntent == rhs.renderingIntent &&
        lhs.flatness == rhs.flatness &&
        lhs.extGState == rhs.extGState
    }
}

// MARK: - Text State

/// A snapshot of the text state at a point in content stream processing.
public struct TextStateSnapshot: Sendable, Equatable {

    /// The current font name.
    public var fontName: ASAtom?

    /// The current font size.
    public var fontSize: Double

    /// The character spacing (Tc).
    public var characterSpacing: Double

    /// The word spacing (Tw).
    public var wordSpacing: Double

    /// The horizontal scaling (Tz) as a percentage (100 = normal).
    public var horizontalScaling: Double

    /// The text leading (TL).
    public var leading: Double

    /// The text rendering mode (Tr).
    public var renderingMode: Int

    /// The text rise (Ts).
    public var rise: Double

    /// The text matrix components (a, b, c, d, e, f).
    public var textMatrix: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// The text line matrix (set at beginning of each line).
    public var lineMatrix: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// Creates a default text state.
    public init() {
        self.fontName = nil
        self.fontSize = 0.0
        self.characterSpacing = 0.0
        self.wordSpacing = 0.0
        self.horizontalScaling = 100.0
        self.leading = 0.0
        self.renderingMode = 0  // Fill
        self.rise = 0.0
        self.textMatrix = (a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0)
        self.lineMatrix = (a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0)
    }

    /// Creates a text state with specific values.
    public init(
        fontName: ASAtom? = nil,
        fontSize: Double = 0.0,
        characterSpacing: Double = 0.0,
        wordSpacing: Double = 0.0,
        horizontalScaling: Double = 100.0,
        leading: Double = 0.0,
        renderingMode: Int = 0,
        rise: Double = 0.0,
        textMatrix: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) = (1, 0, 0, 1, 0, 0),
        lineMatrix: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) = (1, 0, 0, 1, 0, 0)
    ) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.characterSpacing = characterSpacing
        self.wordSpacing = wordSpacing
        self.horizontalScaling = horizontalScaling
        self.leading = leading
        self.renderingMode = renderingMode
        self.rise = rise
        self.textMatrix = textMatrix
        self.lineMatrix = lineMatrix
    }

    /// Whether a font has been selected.
    public var hasFontSelected: Bool {
        fontName != nil && fontSize > 0
    }

    // MARK: - Equatable

    public static func == (lhs: TextStateSnapshot, rhs: TextStateSnapshot) -> Bool {
        lhs.fontName == rhs.fontName &&
        lhs.fontSize == rhs.fontSize &&
        lhs.characterSpacing == rhs.characterSpacing &&
        lhs.wordSpacing == rhs.wordSpacing &&
        lhs.horizontalScaling == rhs.horizontalScaling &&
        lhs.leading == rhs.leading &&
        lhs.renderingMode == rhs.renderingMode &&
        lhs.rise == rhs.rise &&
        lhs.textMatrix.a == rhs.textMatrix.a &&
        lhs.textMatrix.b == rhs.textMatrix.b &&
        lhs.textMatrix.c == rhs.textMatrix.c &&
        lhs.textMatrix.d == rhs.textMatrix.d &&
        lhs.textMatrix.e == rhs.textMatrix.e &&
        lhs.textMatrix.f == rhs.textMatrix.f &&
        lhs.lineMatrix.a == rhs.lineMatrix.a &&
        lhs.lineMatrix.b == rhs.lineMatrix.b &&
        lhs.lineMatrix.c == rhs.lineMatrix.c &&
        lhs.lineMatrix.d == rhs.lineMatrix.d &&
        lhs.lineMatrix.e == rhs.lineMatrix.e &&
        lhs.lineMatrix.f == rhs.lineMatrix.f
    }
}

// MARK: - Operator Validation Context

/// Context for validating content stream operators.
///
/// This struct tracks the state during content stream processing, including:
/// - Graphics state stack (for q/Q validation)
/// - Current color space (for color operator validation)
/// - Text state (for BT/ET and text operator validation)
/// - Marked content nesting
///
/// Corresponds to aspects of the Java `StaticContainers` and operator validation
/// context from veraPDF-validation.
public struct OperatorValidationContext: Sendable {

    // MARK: - Graphics State Stack

    /// The graphics state stack. Pushing saves the current state; popping restores.
    public private(set) var graphicsStateStack: [GraphicsStateSnapshot]

    /// The current graphics state (top of stack or default if stack is empty).
    public var currentGraphicsState: GraphicsStateSnapshot {
        get { graphicsStateStack.last ?? GraphicsStateSnapshot() }
        set {
            if graphicsStateStack.isEmpty {
                graphicsStateStack.append(newValue)
            } else {
                graphicsStateStack[graphicsStateStack.count - 1] = newValue
            }
        }
    }

    /// The depth of the graphics state stack.
    public var graphicsStateDepth: Int {
        graphicsStateStack.count
    }

    // MARK: - Text State

    /// Whether we are inside a text object (between BT and ET).
    public private(set) var inTextObject: Bool

    /// The current text state.
    public var textState: TextStateSnapshot

    /// The nesting depth of text objects (should be 0 or 1; >1 is an error).
    public private(set) var textObjectDepth: Int

    // MARK: - Marked Content

    /// Stack of marked content tags for nesting validation.
    public private(set) var markedContentStack: [ASAtom]

    /// The current marked content nesting depth.
    public var markedContentDepth: Int {
        markedContentStack.count
    }

    // MARK: - Inline Image State

    /// Whether we are inside an inline image (between BI and EI).
    public private(set) var inInlineImage: Bool

    // MARK: - Compatibility Section

    /// Whether we are inside a compatibility section (between BX and EX).
    public private(set) var inCompatibilitySection: Bool

    /// The nesting depth of compatibility sections.
    public private(set) var compatibilityDepth: Int

    // MARK: - Path State

    /// Whether there is a current path (started with m, l, etc., ended with painting/n).
    public private(set) var hasCurrentPath: Bool

    /// Whether the current path has been clipped.
    public private(set) var pathClipped: Bool

    // MARK: - Validation Tracking

    /// Count of operators processed.
    public private(set) var operatorCount: Int

    /// Issues encountered during validation.
    public private(set) var validationIssues: [OperatorValidationIssue]

    // MARK: - Initialization

    /// Creates a new validation context with default state.
    public init() {
        self.graphicsStateStack = [GraphicsStateSnapshot()]
        self.inTextObject = false
        self.textState = TextStateSnapshot()
        self.textObjectDepth = 0
        self.markedContentStack = []
        self.inInlineImage = false
        self.inCompatibilitySection = false
        self.compatibilityDepth = 0
        self.hasCurrentPath = false
        self.pathClipped = false
        self.operatorCount = 0
        self.validationIssues = []
    }

    // MARK: - Graphics State Operations

    /// Pushes the current graphics state onto the stack (q operator).
    public mutating func pushGraphicsState() {
        graphicsStateStack.append(currentGraphicsState)
    }

    /// Pops the graphics state from the stack (Q operator).
    /// - Returns: `true` if successful, `false` if stack underflow.
    @discardableResult
    public mutating func popGraphicsState() -> Bool {
        guard graphicsStateStack.count > 1 else {
            addIssue(.graphicsStateStackUnderflow)
            return false
        }
        graphicsStateStack.removeLast()
        return true
    }

    /// Resets the graphics state stack to initial state.
    public mutating func resetGraphicsStateStack() {
        graphicsStateStack = [GraphicsStateSnapshot()]
    }

    // MARK: - Text Object Operations

    /// Begins a text object (BT operator).
    /// - Returns: `true` if successful, `false` if nested text object.
    @discardableResult
    public mutating func beginTextObject() -> Bool {
        if inTextObject {
            addIssue(.nestedTextObject)
            return false
        }
        inTextObject = true
        textObjectDepth += 1
        // Reset text matrix to identity on BT
        textState.textMatrix = (a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0)
        textState.lineMatrix = (a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 0.0, f: 0.0)
        return true
    }

    /// Ends a text object (ET operator).
    /// - Returns: `true` if successful, `false` if not in text object.
    @discardableResult
    public mutating func endTextObject() -> Bool {
        guard inTextObject else {
            addIssue(.unpairedEndText)
            return false
        }
        inTextObject = false
        return true
    }

    // MARK: - Marked Content Operations

    /// Begins a marked content sequence (BMC or BDC operator).
    public mutating func beginMarkedContent(tag: ASAtom) {
        markedContentStack.append(tag)
    }

    /// Ends a marked content sequence (EMC operator).
    /// - Returns: The tag that was ended, or `nil` if stack underflow.
    @discardableResult
    public mutating func endMarkedContent() -> ASAtom? {
        guard !markedContentStack.isEmpty else {
            addIssue(.unpairedEndMarkedContent)
            return nil
        }
        return markedContentStack.removeLast()
    }

    // MARK: - Inline Image Operations

    /// Begins an inline image (BI operator).
    public mutating func beginInlineImage() {
        if inInlineImage {
            addIssue(.nestedInlineImage)
        }
        inInlineImage = true
    }

    /// Ends an inline image (EI operator).
    public mutating func endInlineImage() {
        if !inInlineImage {
            addIssue(.unpairedEndInlineImage)
        }
        inInlineImage = false
    }

    // MARK: - Compatibility Section Operations

    /// Begins a compatibility section (BX operator).
    public mutating func beginCompatibilitySection() {
        inCompatibilitySection = true
        compatibilityDepth += 1
    }

    /// Ends a compatibility section (EX operator).
    public mutating func endCompatibilitySection() {
        if compatibilityDepth > 0 {
            compatibilityDepth -= 1
            inCompatibilitySection = compatibilityDepth > 0
        } else {
            addIssue(.unpairedEndCompatibility)
        }
    }

    // MARK: - Path Operations

    /// Marks that a path has been started.
    public mutating func beginPath() {
        hasCurrentPath = true
        pathClipped = false
    }

    /// Marks that the path has been painted or ended.
    public mutating func endPath() {
        hasCurrentPath = false
        pathClipped = false
    }

    /// Marks that the current path has been clipped.
    public mutating func clipPath() {
        pathClipped = true
    }

    // MARK: - Operator Processing

    /// Processes an operator, updating context state and checking for issues.
    /// - Parameter op: The operator to process.
    /// - Returns: Any validation issues encountered.
    @discardableResult
    public mutating func process(_ op: ValidatedOperator) -> [OperatorValidationIssue] {
        operatorCount += 1
        let issueCountBefore = validationIssues.count

        switch op {
        // Graphics state
        case .saveGraphicsState:
            pushGraphicsState()

        case .restoreGraphicsState:
            popGraphicsState()

        // Color space
        case .setColorSpaceStroke(let cs):
            currentGraphicsState.strokeColorSpace = cs

        case .setColorSpaceFill(let cs):
            currentGraphicsState.fillColorSpace = cs

        case .setGrayStroke(let g):
            currentGraphicsState.strokeColorSpace = ASAtom("DeviceGray")
            currentGraphicsState.strokeColor = [g]

        case .setGrayFill(let g):
            currentGraphicsState.fillColorSpace = ASAtom("DeviceGray")
            currentGraphicsState.fillColor = [g]

        case .setRGBStroke(let r, let g, let b):
            currentGraphicsState.strokeColorSpace = ASAtom("DeviceRGB")
            currentGraphicsState.strokeColor = [r, g, b]

        case .setRGBFill(let r, let g, let b):
            currentGraphicsState.fillColorSpace = ASAtom("DeviceRGB")
            currentGraphicsState.fillColor = [r, g, b]

        case .setCMYKStroke(let c, let m, let y, let k):
            currentGraphicsState.strokeColorSpace = ASAtom("DeviceCMYK")
            currentGraphicsState.strokeColor = [c, m, y, k]

        case .setCMYKFill(let c, let m, let y, let k):
            currentGraphicsState.fillColorSpace = ASAtom("DeviceCMYK")
            currentGraphicsState.fillColor = [c, m, y, k]

        case .setColorStroke(let components), .setColorStrokeN(let components, _):
            currentGraphicsState.strokeColor = components

        case .setColorFill(let components), .setColorFillN(let components, _):
            currentGraphicsState.fillColor = components

        // Line state
        case .setLineWidth(let w):
            currentGraphicsState.lineWidth = w

        case .setLineCap(let cap):
            currentGraphicsState.lineCap = cap

        case .setLineJoin(let join):
            currentGraphicsState.lineJoin = join

        case .setMiterLimit(let limit):
            currentGraphicsState.miterLimit = limit

        case .setDashPattern(let pattern, let phase):
            currentGraphicsState.dashPattern = pattern
            currentGraphicsState.dashPhase = phase

        case .setRenderingIntent(let intent):
            currentGraphicsState.renderingIntent = intent

        case .setFlatness(let f):
            currentGraphicsState.flatness = f

        case .setExtGState(let name):
            currentGraphicsState.extGState = name

        case .concatMatrix(let a, let b, let c, let d, let e, let f):
            // Concatenate matrices (simplified - full implementation would multiply)
            currentGraphicsState.ctm = (a: a, b: b, c: c, d: d, e: e, f: f)

        // Text object
        case .beginText:
            beginTextObject()

        case .endText:
            endTextObject()

        // Text state
        case .setFont(let name, let size):
            textState.fontName = name
            textState.fontSize = size

        case .setCharacterSpacing(let spacing):
            textState.characterSpacing = spacing

        case .setWordSpacing(let spacing):
            textState.wordSpacing = spacing

        case .setHorizontalScaling(let scale):
            textState.horizontalScaling = scale

        case .setTextLeading(let leading):
            textState.leading = leading

        case .setTextRenderingMode(let mode):
            textState.renderingMode = mode

        case .setTextRise(let rise):
            textState.rise = rise

        // Text positioning
        case .setTextMatrix(let a, let b, let c, let d, let e, let f):
            textState.textMatrix = (a: a, b: b, c: c, d: d, e: e, f: f)
            textState.lineMatrix = textState.textMatrix

        case .moveTextPosition(let tx, let ty):
            textState.textMatrix.e += tx
            textState.textMatrix.f += ty
            textState.lineMatrix = textState.textMatrix

        case .moveTextPositionLeading(let tx, let ty):
            textState.leading = -ty
            textState.textMatrix.e += tx
            textState.textMatrix.f += ty
            textState.lineMatrix = textState.textMatrix

        case .moveToNextLine:
            textState.textMatrix.e = textState.lineMatrix.e
            textState.textMatrix.f = textState.lineMatrix.f - textState.leading

        // Text showing - validate font is selected
        case .showText, .showTextArray, .moveAndShowText, .moveAndShowTextWithSpacing:
            if !inTextObject {
                addIssue(.textOperatorOutsideTextObject)
            }
            if !textState.hasFontSelected {
                addIssue(.noFontSelected)
            }

        // Path construction
        case .moveTo, .lineTo, .curveTo, .curveToInitialReplicated,
             .curveToFinalReplicated, .appendRectangle:
            beginPath()

        case .closePath:
            // Path continues after close
            break

        // Path painting
        case .stroke, .closeAndStroke, .fill, .fillEvenOdd,
             .fillAndStroke, .fillAndStrokeEvenOdd,
             .closeFillAndStroke, .closeFillAndStrokeEvenOdd, .endPath:
            endPath()

        // Clipping
        case .clip, .clipEvenOdd:
            clipPath()

        // Marked content
        case .beginMarkedContent(let tag):
            beginMarkedContent(tag: tag)

        case .beginMarkedContentWithProperties(let tag, _):
            beginMarkedContent(tag: tag)

        case .endMarkedContent:
            _ = endMarkedContent()

        // Inline image
        case .beginInlineImage:
            beginInlineImage()

        case .endInlineImage:
            endInlineImage()

        // Compatibility
        case .beginCompatibility:
            beginCompatibilitySection()

        case .endCompatibility:
            endCompatibilitySection()

        // Others don't affect tracked state
        default:
            break
        }

        // Return new issues from this operator
        return Array(validationIssues[issueCountBefore...])
    }

    // MARK: - Validation

    /// Validates the final state after processing all operators.
    /// - Returns: Any end-of-stream validation issues.
    public mutating func validateEndOfStream() -> [OperatorValidationIssue] {
        var issues: [OperatorValidationIssue] = []

        // Check for unclosed graphics state
        if graphicsStateStack.count > 1 {
            issues.append(.unmatchedSaveState(depth: graphicsStateStack.count - 1))
            addIssue(.unmatchedSaveState(depth: graphicsStateStack.count - 1))
        }

        // Check for unclosed text object
        if inTextObject {
            issues.append(.unclosedTextObject)
            addIssue(.unclosedTextObject)
        }

        // Check for unclosed marked content
        if !markedContentStack.isEmpty {
            for tag in markedContentStack {
                issues.append(.unclosedMarkedContent(tag: tag))
                addIssue(.unclosedMarkedContent(tag: tag))
            }
        }

        // Check for unclosed inline image
        if inInlineImage {
            issues.append(.unclosedInlineImage)
            addIssue(.unclosedInlineImage)
        }

        // Check for unclosed compatibility section
        if compatibilityDepth > 0 {
            issues.append(.unclosedCompatibilitySection(depth: compatibilityDepth))
            addIssue(.unclosedCompatibilitySection(depth: compatibilityDepth))
        }

        return issues
    }

    /// Adds a validation issue.
    private mutating func addIssue(_ issue: OperatorValidationIssue) {
        validationIssues.append(issue)
    }

    /// Returns all validation issues encountered.
    public var allIssues: [OperatorValidationIssue] {
        validationIssues
    }

    /// Whether any validation issues were encountered.
    public var hasIssues: Bool {
        !validationIssues.isEmpty
    }

    /// Clears all validation issues.
    public mutating func clearIssues() {
        validationIssues.removeAll()
    }
}

// MARK: - Operator Validation Issue

/// An issue encountered during operator validation.
public enum OperatorValidationIssue: Sendable, Equatable, CustomStringConvertible {

    // Graphics state issues
    case graphicsStateStackUnderflow
    case unmatchedSaveState(depth: Int)

    // Text object issues
    case nestedTextObject
    case unpairedEndText
    case unclosedTextObject
    case textOperatorOutsideTextObject
    case noFontSelected

    // Marked content issues
    case unpairedEndMarkedContent
    case unclosedMarkedContent(tag: ASAtom)

    // Inline image issues
    case nestedInlineImage
    case unpairedEndInlineImage
    case unclosedInlineImage

    // Compatibility issues
    case unpairedEndCompatibility
    case unclosedCompatibilitySection(depth: Int)

    // Color issues
    case invalidColorComponentCount(expected: Int, actual: Int)
    case colorOperatorMismatchWithColorSpace

    // Path issues
    case pathOperatorWithNoPath

    public var description: String {
        switch self {
        case .graphicsStateStackUnderflow:
            return "Graphics state stack underflow: Q without matching q"
        case .unmatchedSaveState(let depth):
            return "Unmatched save state: \(depth) q operator(s) without matching Q"
        case .nestedTextObject:
            return "Nested text object: BT inside another BT/ET pair"
        case .unpairedEndText:
            return "Unpaired ET: ET without matching BT"
        case .unclosedTextObject:
            return "Unclosed text object: BT without matching ET"
        case .textOperatorOutsideTextObject:
            return "Text operator outside text object: text operator before BT or after ET"
        case .noFontSelected:
            return "No font selected: text showing operator without prior Tf"
        case .unpairedEndMarkedContent:
            return "Unpaired EMC: EMC without matching BMC/BDC"
        case .unclosedMarkedContent(let tag):
            return "Unclosed marked content: \(tag) BMC/BDC without matching EMC"
        case .nestedInlineImage:
            return "Nested inline image: BI inside another BI/EI pair"
        case .unpairedEndInlineImage:
            return "Unpaired EI: EI without matching BI"
        case .unclosedInlineImage:
            return "Unclosed inline image: BI without matching EI"
        case .unpairedEndCompatibility:
            return "Unpaired EX: EX without matching BX"
        case .unclosedCompatibilitySection(let depth):
            return "Unclosed compatibility section: \(depth) BX operator(s) without matching EX"
        case .invalidColorComponentCount(let expected, let actual):
            return "Invalid color component count: expected \(expected), got \(actual)"
        case .colorOperatorMismatchWithColorSpace:
            return "Color operator does not match current color space"
        case .pathOperatorWithNoPath:
            return "Path painting operator with no current path"
        }
    }

    /// The severity of this issue.
    public var severity: IssueSeverity {
        switch self {
        case .graphicsStateStackUnderflow, .nestedTextObject, .unclosedTextObject,
             .textOperatorOutsideTextObject, .noFontSelected:
            return .error
        case .unpairedEndText, .unmatchedSaveState, .unpairedEndMarkedContent,
             .unclosedMarkedContent, .invalidColorComponentCount:
            return .warning
        case .nestedInlineImage, .unpairedEndInlineImage, .unclosedInlineImage,
             .unpairedEndCompatibility, .unclosedCompatibilitySection,
             .colorOperatorMismatchWithColorSpace, .pathOperatorWithNoPath:
            return .warning
        }
    }
}

// MARK: - Issue Severity

/// The severity of a validation issue.
public enum IssueSeverity: String, Sendable, CaseIterable {
    case error = "error"
    case warning = "warning"
    case info = "info"
}
