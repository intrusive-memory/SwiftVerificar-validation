import Foundation

/// Represents extracted feature data in a tree structure.
///
/// A `FeatureNode` is a single node in the feature extraction tree.
/// It contains feature data values and can have child nodes, forming
/// a hierarchical representation of extracted PDF features.
///
/// Corresponds to feature nodes in veraPDF's feature reporting system.
public struct FeatureNode: Sendable, Identifiable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this feature node.
    public let id: UUID

    /// The type of feature this node represents.
    public let featureType: FeatureType

    /// The name of this feature instance (e.g., font name, color space name).
    public let name: String?

    /// Feature data as key-value pairs.
    public let values: [String: FeatureValue]

    /// Child feature nodes.
    public let children: [FeatureNode]

    /// Optional reference to the source PDF object.
    public let objectKey: COSObjectKey?

    /// Additional context information.
    public let context: ObjectContext?

    // MARK: - Initialization

    /// Creates a new feature node.
    ///
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if not provided).
    ///   - featureType: The type of feature this node represents.
    ///   - name: Optional name for this feature instance.
    ///   - values: Feature data as key-value pairs.
    ///   - children: Child feature nodes.
    ///   - objectKey: Optional reference to source PDF object.
    ///   - context: Optional context information.
    public init(
        id: UUID = UUID(),
        featureType: FeatureType,
        name: String? = nil,
        values: [String: FeatureValue] = [:],
        children: [FeatureNode] = [],
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil
    ) {
        self.id = id
        self.featureType = featureType
        self.name = name
        self.values = values
        self.children = children
        self.objectKey = objectKey
        self.context = context
    }

    // MARK: - Value Access

    /// Returns the value for a specific key.
    ///
    /// - Parameter key: The value key.
    /// - Returns: The feature value if found.
    public func value(for key: String) -> FeatureValue? {
        values[key]
    }

    /// Returns the string value for a specific key.
    ///
    /// - Parameter key: The value key.
    /// - Returns: The string value if found and convertible.
    public func stringValue(for key: String) -> String? {
        values[key]?.stringValue
    }

    /// Returns the integer value for a specific key.
    ///
    /// - Parameter key: The value key.
    /// - Returns: The integer value if found and convertible.
    public func intValue(for key: String) -> Int? {
        values[key]?.intValue
    }

    /// Returns the double value for a specific key.
    ///
    /// - Parameter key: The value key.
    /// - Returns: The double value if found and convertible.
    public func doubleValue(for key: String) -> Double? {
        values[key]?.doubleValue
    }

    /// Returns the boolean value for a specific key.
    ///
    /// - Parameter key: The value key.
    /// - Returns: The boolean value if found and convertible.
    public func boolValue(for key: String) -> Bool? {
        values[key]?.boolValue
    }

    // MARK: - Child Access

    /// Returns all children of a specific feature type.
    ///
    /// - Parameter type: The feature type to filter by.
    /// - Returns: Array of matching child nodes.
    public func children(ofType type: FeatureType) -> [FeatureNode] {
        children.filter { $0.featureType == type }
    }

    /// Returns the first child with the specified name.
    ///
    /// - Parameter name: The name to search for.
    /// - Returns: The first matching child node.
    public func child(named name: String) -> FeatureNode? {
        children.first { $0.name == name }
    }

    /// Returns all child nodes matching a predicate.
    ///
    /// - Parameter predicate: The predicate to filter by.
    /// - Returns: Array of matching child nodes.
    public func children(where predicate: (FeatureNode) -> Bool) -> [FeatureNode] {
        children.filter(predicate)
    }

    /// Returns a flattened array of all descendant nodes.
    public var allDescendants: [FeatureNode] {
        var result: [FeatureNode] = []
        for child in children {
            result.append(child)
            result.append(contentsOf: child.allDescendants)
        }
        return result
    }

    /// Returns all descendant nodes of a specific feature type.
    ///
    /// - Parameter type: The feature type to filter by.
    /// - Returns: Array of matching descendant nodes.
    public func descendants(ofType type: FeatureType) -> [FeatureNode] {
        allDescendants.filter { $0.featureType == type }
    }

    // MARK: - Statistics

    /// The total number of child nodes (direct children only).
    public var childCount: Int {
        children.count
    }

    /// The total number of descendant nodes (all levels).
    public var descendantCount: Int {
        children.reduce(0) { $0 + 1 + $1.descendantCount }
    }

    /// The depth of this node in the tree (root = 0).
    public var depth: Int {
        guard !children.isEmpty else { return 0 }
        return 1 + (children.map(\.depth).max() ?? 0)
    }

    // MARK: - Modification

    /// Returns a new node with an additional value.
    ///
    /// - Parameters:
    ///   - key: The value key.
    ///   - value: The feature value.
    /// - Returns: A new node with the value added.
    public func withValue(_ key: String, _ value: FeatureValue) -> FeatureNode {
        var newValues = values
        newValues[key] = value
        return FeatureNode(
            id: id,
            featureType: featureType,
            name: name,
            values: newValues,
            children: children,
            objectKey: objectKey,
            context: context
        )
    }

    /// Returns a new node with additional values.
    ///
    /// - Parameter additionalValues: The values to add.
    /// - Returns: A new node with the values added.
    public func withValues(_ additionalValues: [String: FeatureValue]) -> FeatureNode {
        var newValues = values
        for (key, value) in additionalValues {
            newValues[key] = value
        }
        return FeatureNode(
            id: id,
            featureType: featureType,
            name: name,
            values: newValues,
            children: children,
            objectKey: objectKey,
            context: context
        )
    }

    /// Returns a new node with an additional child.
    ///
    /// - Parameter child: The child node to add.
    /// - Returns: A new node with the child added.
    public func withChild(_ child: FeatureNode) -> FeatureNode {
        FeatureNode(
            id: id,
            featureType: featureType,
            name: name,
            values: values,
            children: children + [child],
            objectKey: objectKey,
            context: context
        )
    }

    /// Returns a new node with additional children.
    ///
    /// - Parameter newChildren: The children to add.
    /// - Returns: A new node with the children added.
    public func withChildren(_ newChildren: [FeatureNode]) -> FeatureNode {
        FeatureNode(
            id: id,
            featureType: featureType,
            name: name,
            values: values,
            children: children + newChildren,
            objectKey: objectKey,
            context: context
        )
    }

    /// Returns a new node with replaced children.
    ///
    /// - Parameter newChildren: The new children.
    /// - Returns: A new node with replaced children.
    public func replacingChildren(_ newChildren: [FeatureNode]) -> FeatureNode {
        FeatureNode(
            id: id,
            featureType: featureType,
            name: name,
            values: values,
            children: newChildren,
            objectKey: objectKey,
            context: context
        )
    }

    // MARK: - Equatable

    public static func == (lhs: FeatureNode, rhs: FeatureNode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Feature Value

/// A value extracted from a PDF feature.
///
/// Feature values can be of different types depending on the feature
/// being extracted. This enum provides type-safe access to feature data.
public enum FeatureValue: Sendable, Equatable, Hashable {

    /// A null/empty value.
    case null

    /// A boolean value.
    case bool(Bool)

    /// An integer value.
    case int(Int)

    /// A floating-point value.
    case double(Double)

    /// A string value.
    case string(String)

    /// Binary data.
    case data(Data)

    /// An array of values.
    case array([FeatureValue])

    /// A dictionary of values.
    case dictionary([String: FeatureValue])

    /// A date value.
    case date(Date)

    // MARK: - Type Checking

    /// Whether this value is null.
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    /// Whether this value is a boolean.
    public var isBool: Bool {
        if case .bool = self { return true }
        return false
    }

    /// Whether this value is an integer.
    public var isInt: Bool {
        if case .int = self { return true }
        return false
    }

    /// Whether this value is a double.
    public var isDouble: Bool {
        if case .double = self { return true }
        return false
    }

    /// Whether this value is a string.
    public var isString: Bool {
        if case .string = self { return true }
        return false
    }

    /// Whether this value is data.
    public var isData: Bool {
        if case .data = self { return true }
        return false
    }

    /// Whether this value is an array.
    public var isArray: Bool {
        if case .array = self { return true }
        return false
    }

    /// Whether this value is a dictionary.
    public var isDictionary: Bool {
        if case .dictionary = self { return true }
        return false
    }

    /// Whether this value is a date.
    public var isDate: Bool {
        if case .date = self { return true }
        return false
    }

    // MARK: - Value Extraction

    /// The boolean value, if this is a bool.
    public var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }

    /// The integer value, if this is an int.
    public var intValue: Int? {
        if case .int(let v) = self { return v }
        return nil
    }

    /// The double value, if this is a double or int.
    public var doubleValue: Double? {
        switch self {
        case .double(let v): return v
        case .int(let v): return Double(v)
        default: return nil
        }
    }

    /// The string value, if this is a string.
    public var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    /// The data value, if this is data.
    public var dataValue: Data? {
        if case .data(let v) = self { return v }
        return nil
    }

    /// The array value, if this is an array.
    public var arrayValue: [FeatureValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    /// The dictionary value, if this is a dictionary.
    public var dictionaryValue: [String: FeatureValue]? {
        if case .dictionary(let v) = self { return v }
        return nil
    }

    /// The date value, if this is a date.
    public var dateValue: Date? {
        if case .date(let v) = self { return v }
        return nil
    }
}

// MARK: - CustomStringConvertible

extension FeatureNode: CustomStringConvertible {
    public var description: String {
        var result = "\(featureType.displayName)"
        if let name = name {
            result += " '\(name)'"
        }
        if !values.isEmpty {
            result += " [\(values.count) values]"
        }
        if !children.isEmpty {
            result += " (\(children.count) children)"
        }
        return result
    }
}

extension FeatureValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null: return "null"
        case .bool(let v): return v ? "true" : "false"
        case .int(let v): return String(v)
        case .double(let v): return String(v)
        case .string(let v): return "\"\(v)\""
        case .data(let v): return "<\(v.count) bytes>"
        case .array(let v): return "[\(v.count) items]"
        case .dictionary(let v): return "{\(v.count) entries}"
        case .date(let v): return ISO8601DateFormatter().string(from: v)
        }
    }
}

// MARK: - ExpressibleBy Literals

extension FeatureValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension FeatureValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension FeatureValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension FeatureValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension FeatureValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: FeatureValue...) {
        self = .array(elements)
    }
}

extension FeatureValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, FeatureValue)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension FeatureValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}
