import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Action Type

/// The type of a PDF action.
///
/// PDF actions define behaviors that can be triggered by events such as
/// opening a document, clicking a link, or submitting a form.
///
/// See PDF specification Table 198 -- Action types.
public enum ActionType: String, Sendable, Hashable, CaseIterable {
    /// Go to a destination in the current document.
    case goTo = "GoTo"

    /// Go to a destination in a remote document.
    case goToR = "GoToR"

    /// Go to a destination in an embedded file.
    case goToE = "GoToE"

    /// Go to a destination in a 3D annotation.
    case goTo3DView = "GoTo3DView"

    /// Launch an application or open a file.
    case launch = "Launch"

    /// Open a URI (web link).
    case uri = "URI"

    /// Play a sound.
    case sound = "Sound"

    /// Play a movie.
    case movie = "Movie"

    /// Hide or show an annotation.
    case hide = "Hide"

    /// Execute a named action (e.g., NextPage, PrevPage).
    case named = "Named"

    /// Submit form data to a URL.
    case submitForm = "SubmitForm"

    /// Reset form fields to default values.
    case resetForm = "ResetForm"

    /// Import form data from a file.
    case importData = "ImportData"

    /// Execute a JavaScript script.
    case javaScript = "JavaScript"

    /// Set the states of optional content groups.
    case setOCGState = "SetOCGState"

    /// Begin a multimedia rendition.
    case rendition = "Rendition"

    /// Transition to a presentation step.
    case trans = "Trans"

    /// Go to a page in a 3D annotation.
    case goToDp = "GoToDp"

    /// Execute a rich media action.
    case richMediaExecute = "RichMediaExecute"

    /// Unknown action type.
    case unknown = "Unknown"

    /// Creates an action type from a string.
    ///
    /// - Parameter value: The action type string from the PDF dictionary.
    public init(fromString value: String?) {
        guard let value = value else {
            self = .unknown
            return
        }
        self = ActionType(rawValue: value) ?? .unknown
    }

    /// Whether this action type is prohibited in PDF/A-1.
    ///
    /// PDF/A-1 prohibits: Launch, Sound, Movie, JavaScript, and
    /// certain other interactive actions.
    public var isProhibitedInPDFA1: Bool {
        switch self {
        case .launch, .sound, .movie, .javaScript,
             .importData, .resetForm, .submitForm,
             .rendition, .richMediaExecute, .goTo3DView:
            return true
        default:
            return false
        }
    }

    /// Whether this action type is a navigation action.
    public var isNavigation: Bool {
        switch self {
        case .goTo, .goToR, .goToE, .goToDp, .goTo3DView:
            return true
        default:
            return false
        }
    }

    /// Whether this action type is a multimedia action.
    public var isMultimedia: Bool {
        switch self {
        case .sound, .movie, .rendition, .richMediaExecute:
            return true
        default:
            return false
        }
    }

    /// Whether this action type is a form-related action.
    public var isFormAction: Bool {
        switch self {
        case .submitForm, .resetForm, .importData:
            return true
        default:
            return false
        }
    }
}

// MARK: - Validated Action

/// A validation wrapper for a PDF action dictionary.
///
/// PDF actions define behaviors triggered by user interaction or events.
/// This struct wraps action dictionaries for validation against PDF/A,
/// PDF/UA, and other conformance requirements.
///
/// ## Key Properties
///
/// - **Type**: The action type (GoTo, URI, JavaScript, etc.)
/// - **Destination**: For GoTo actions, the target destination
/// - **URI**: For URI actions, the target URL
/// - **Next**: Chained actions to execute after this one
///
/// ## Validation Rules
///
/// - **PDF/A-1**: Prohibits Launch, Sound, Movie, JavaScript,
///   ImportData, SubmitForm, ResetForm, and Rendition actions.
/// - **PDF/A-2+**: Same restrictions plus GoToDp.
/// - **PDF/UA**: Actions on links and buttons must be accessible.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDAction` and its subclasses from veraPDF-validation,
/// consolidated into a single struct with `ActionType` discriminator.
public struct ValidatedAction: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the action.
    public let cosDictionary: COSValue?

    /// The object key for the action, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Action Properties

    /// The action type (`/S` entry).
    public let actionType: ActionType

    /// The raw action type string from the dictionary.
    public let actionTypeName: String

    /// The destination for GoTo actions (`/D` entry).
    ///
    /// This can be a named destination string, a page reference,
    /// or an explicit destination array.
    public let hasDestination: Bool

    /// The destination name for GoTo actions, if a named destination.
    public let destinationName: String?

    /// The URI for URI actions (`/URI` entry).
    public let uri: String?

    /// Whether the URI action should be treated as a map (`/IsMap` entry).
    public let isMap: Bool

    /// The file specification for Launch/GoToR/GoToE actions (`/F` entry).
    public let hasFileSpec: Bool

    /// The file specification name, if present.
    public let fileSpecName: String?

    /// The named action name for Named actions (`/N` entry).
    ///
    /// Standard named actions: NextPage, PrevPage, FirstPage, LastPage.
    public let namedActionName: String?

    /// The JavaScript script for JavaScript actions (`/JS` entry).
    public let hasJavaScript: Bool

    /// Whether there is a next action chain (`/Next` entry).
    public let hasNextAction: Bool

    /// The number of chained next actions.
    public let nextActionCount: Int

    // MARK: - Initialization

    /// Creates a validated action.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the action.
    ///   - objectKey: The object key.
    ///   - context: Validation context.
    ///   - actionTypeName: The raw action type string.
    ///   - hasDestination: Whether a destination exists.
    ///   - destinationName: Named destination, if applicable.
    ///   - uri: The URI for URI actions.
    ///   - isMap: Whether the URI is treated as a map.
    ///   - hasFileSpec: Whether a file specification exists.
    ///   - fileSpecName: The file specification name.
    ///   - namedActionName: The named action name.
    ///   - hasJavaScript: Whether JavaScript is present.
    ///   - hasNextAction: Whether a next action chain exists.
    ///   - nextActionCount: Number of chained actions.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(location: "Action"),
        actionTypeName: String = "GoTo",
        hasDestination: Bool = false,
        destinationName: String? = nil,
        uri: String? = nil,
        isMap: Bool = false,
        hasFileSpec: Bool = false,
        fileSpecName: String? = nil,
        namedActionName: String? = nil,
        hasJavaScript: Bool = false,
        hasNextAction: Bool = false,
        nextActionCount: Int = 0
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.actionTypeName = actionTypeName
        self.actionType = ActionType(fromString: actionTypeName)
        self.hasDestination = hasDestination
        self.destinationName = destinationName
        self.uri = uri
        self.isMap = isMap
        self.hasFileSpec = hasFileSpec
        self.fileSpecName = fileSpecName
        self.namedActionName = namedActionName
        self.hasJavaScript = hasJavaScript
        self.hasNextAction = hasNextAction
        self.nextActionCount = nextActionCount
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDAction"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "actionType", "actionTypeName",
            "hasDestination", "destinationName",
            "uri", "isMap",
            "hasFileSpec", "fileSpecName",
            "namedActionName", "hasJavaScript",
            "hasNextAction", "nextActionCount",
            "isProhibitedInPDFA1", "isNavigation",
            "isMultimedia", "isFormAction"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "actionType":
            return .string(actionType.rawValue)
        case "actionTypeName":
            return .string(actionTypeName)
        case "hasDestination":
            return .boolean(hasDestination)
        case "destinationName":
            if let dn = destinationName { return .string(dn) }
            return .null
        case "uri":
            if let u = uri { return .string(u) }
            return .null
        case "isMap":
            return .boolean(isMap)
        case "hasFileSpec":
            return .boolean(hasFileSpec)
        case "fileSpecName":
            if let fsn = fileSpecName { return .string(fsn) }
            return .null
        case "namedActionName":
            if let nan = namedActionName { return .string(nan) }
            return .null
        case "hasJavaScript":
            return .boolean(hasJavaScript)
        case "hasNextAction":
            return .boolean(hasNextAction)
        case "nextActionCount":
            return .integer(Int64(nextActionCount))
        case "isProhibitedInPDFA1":
            return .boolean(isProhibitedInPDFA1)
        case "isNavigation":
            return .boolean(isNavigation)
        case "isMultimedia":
            return .boolean(isMultimedia)
        case "isFormAction":
            return .boolean(isFormAction)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedAction, rhs: ValidatedAction) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedAction {

    /// Whether this action is prohibited in PDF/A-1.
    public var isProhibitedInPDFA1: Bool {
        actionType.isProhibitedInPDFA1
    }

    /// Whether this is a navigation action.
    public var isNavigation: Bool {
        actionType.isNavigation
    }

    /// Whether this is a multimedia action.
    public var isMultimedia: Bool {
        actionType.isMultimedia
    }

    /// Whether this is a form-related action.
    public var isFormAction: Bool {
        actionType.isFormAction
    }

    /// Whether this action has a valid URI for URI actions.
    public var hasValidURI: Bool {
        guard actionType == .uri else { return false }
        guard let u = uri, !u.isEmpty else { return false }
        return true
    }

    /// Whether this action has a valid destination for GoTo actions.
    public var hasValidDestination: Bool {
        guard actionType == .goTo else { return false }
        return hasDestination
    }

    /// Returns a summary string describing the action.
    public var summary: String {
        var parts: [String] = [actionTypeName]
        if let u = uri { parts.append("URI=\(u)") }
        if let dn = destinationName { parts.append("dest=\(dn)") }
        if let nan = namedActionName { parts.append("name=\(nan)") }
        if hasJavaScript { parts.append("JS") }
        if hasNextAction { parts.append("next(\(nextActionCount))") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedAction {

    /// Creates a GoTo action for testing.
    ///
    /// - Parameter destinationName: The named destination.
    /// - Returns: A GoTo action.
    public static func goTo(destinationName: String = "page1") -> ValidatedAction {
        ValidatedAction(
            actionTypeName: "GoTo",
            hasDestination: true,
            destinationName: destinationName
        )
    }

    /// Creates a URI action for testing.
    ///
    /// - Parameter uri: The target URI.
    /// - Returns: A URI action.
    public static func uri(_ uri: String = "https://example.com") -> ValidatedAction {
        ValidatedAction(
            actionTypeName: "URI",
            uri: uri
        )
    }

    /// Creates a JavaScript action for testing.
    ///
    /// - Returns: A JavaScript action.
    public static func javaScript() -> ValidatedAction {
        ValidatedAction(
            actionTypeName: "JavaScript",
            hasJavaScript: true
        )
    }

    /// Creates a Named action for testing.
    ///
    /// - Parameter name: The named action (e.g., "NextPage").
    /// - Returns: A Named action.
    public static func named(_ name: String = "NextPage") -> ValidatedAction {
        ValidatedAction(
            actionTypeName: "Named",
            namedActionName: name
        )
    }
}
