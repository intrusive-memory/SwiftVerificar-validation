import Foundation

/// Provides type-safe access to object properties for validation rules.
///
/// This type implements the property access mechanisms used in veraPDF
/// validation rules. Rules can access object properties using dot notation
/// (e.g., "font.subtype", "colorSpace.nComponents") and this accessor
/// handles the resolution and type conversion.
///
/// Corresponds to the property access system in the Java veraPDF-validation
/// model, which uses reflection and method calls.
public struct PropertyAccessor: Sendable {

    // MARK: - Properties

    /// The object being accessed.
    private let object: AnyPDFObject

    // MARK: - Initialization

    /// Creates a property accessor for an object.
    ///
    /// - Parameter object: The object to access properties on.
    public init(object: AnyPDFObject) {
        self.object = object
    }

    /// Creates a property accessor for an object conforming to PDFObject.
    ///
    /// - Parameter object: The object to access properties on.
    public init<T: PDFObject>(object: T) where T: Equatable {
        self.object = AnyPDFObject(object)
    }

    // MARK: - Property Access

    /// Accesses a property by name.
    ///
    /// - Parameter path: The property path (e.g., "type" or "font.subtype").
    /// - Returns: The property value, or `nil` if not found.
    public func value(forPath path: String) -> PropertyValue? {
        let components = path.split(separator: ".").map(String.init)
        return value(forComponents: components, startingAt: object)
    }

    /// Recursively resolves a property path.
    ///
    /// - Parameters:
    ///   - components: The remaining path components.
    ///   - object: The current object.
    /// - Returns: The property value, or `nil` if not found.
    private func value(forComponents components: [String], startingAt object: AnyPDFObject) -> PropertyValue? {
        guard let firstComponent = components.first else {
            return nil
        }

        // Get the property value from the current object
        guard let propertyValue = object.property(named: firstComponent) else {
            return nil
        }

        // If this is the last component, return the value
        if components.count == 1 {
            return propertyValue
        }

        // Otherwise, continue navigating
        let remainingComponents = Array(components.dropFirst())

        switch propertyValue {
        case .object(let nestedObject):
            return value(forComponents: remainingComponents, startingAt: nestedObject)

        case .objectArray(let objects):
            // For arrays, we need special handling
            // If the next component is an index, access that element
            if let index = Int(remainingComponents[0]),
               objects.indices.contains(index) {
                let nextComponents = Array(remainingComponents.dropFirst())
                if nextComponents.isEmpty {
                    return .object(objects[index])
                }
                return value(forComponents: nextComponents, startingAt: objects[index])
            }

            // Otherwise, this is an error (can't navigate into an array without an index)
            return nil

        default:
            // Can't navigate into primitive values
            return nil
        }
    }

    // MARK: - Type Conversion

    /// Accesses a property and converts it to a boolean.
    ///
    /// - Parameter path: The property path.
    /// - Returns: The boolean value, or `nil` if not found or not convertible.
    public func boolValue(forPath path: String) -> Bool? {
        value(forPath: path)?.boolValue
    }

    /// Accesses a property and converts it to an integer.
    ///
    /// - Parameter path: The property path.
    /// - Returns: The integer value, or `nil` if not found or not convertible.
    public func integerValue(forPath path: String) -> Int64? {
        value(forPath: path)?.integerValue
    }

    /// Accesses a property and converts it to a real number.
    ///
    /// - Parameter path: The property path.
    /// - Returns: The real value, or `nil` if not found or not convertible.
    public func realValue(forPath path: String) -> Double? {
        value(forPath: path)?.realValue
    }

    /// Accesses a property and converts it to a numeric value (int or real).
    ///
    /// - Parameter path: The property path.
    /// - Returns: The numeric value as a double, or `nil` if not found or not convertible.
    public func numericValue(forPath path: String) -> Double? {
        value(forPath: path)?.numericValue
    }

    /// Accesses a property and converts it to a string.
    ///
    /// - Parameter path: The property path.
    /// - Returns: The string value, or `nil` if not found or not convertible.
    public func stringValue(forPath path: String) -> String? {
        value(forPath: path)?.stringValue
    }

    /// Accesses a property and returns it as an object.
    ///
    /// - Parameter path: The property path.
    /// - Returns: The object, or `nil` if not found or not an object.
    public func objectValue(forPath path: String) -> AnyPDFObject? {
        value(forPath: path)?.objectValue
    }

    /// Accesses a property and returns it as an object array.
    ///
    /// - Parameter path: The property path.
    /// - Returns: The object array, or `nil` if not found or not an array.
    public func objectArrayValue(forPath path: String) -> [AnyPDFObject]? {
        value(forPath: path)?.objectArrayValue
    }

    // MARK: - Existence Checking

    /// Checks if a property exists.
    ///
    /// - Parameter path: The property path.
    /// - Returns: `true` if the property exists, `false` otherwise.
    public func hasProperty(_ path: String) -> Bool {
        value(forPath: path) != nil
    }

    /// Checks if a property has a non-null value.
    ///
    /// - Parameter path: The property path.
    /// - Returns: `true` if the property exists and is not null, `false` otherwise.
    public func hasNonNullValue(_ path: String) -> Bool {
        guard let value = value(forPath: path) else {
            return false
        }
        return !value.isNull
    }
}

// MARK: - Collection Operations

extension PropertyAccessor {

    /// Counts the elements in an array property.
    ///
    /// - Parameter path: The property path.
    /// - Returns: The count, or 0 if not found or not an array.
    public func count(forPath path: String) -> Int {
        guard let array = objectArrayValue(forPath: path) else {
            return 0
        }
        return array.count
    }

    /// Checks if an array property is empty.
    ///
    /// - Parameter path: The property path.
    /// - Returns: `true` if the array is empty or not found, `false` otherwise.
    public func isEmpty(forPath path: String) -> Bool {
        count(forPath: path) == 0
    }

    /// Checks if an array property contains at least one element.
    ///
    /// - Parameter path: The property path.
    /// - Returns: `true` if the array has elements, `false` otherwise.
    public func hasElements(forPath path: String) -> Bool {
        count(forPath: path) > 0
    }
}

// MARK: - Comparison Operations

extension PropertyAccessor {

    /// Compares a numeric property to a value.
    ///
    /// - Parameters:
    ///   - path: The property path.
    ///   - value: The value to compare against.
    /// - Returns: The comparison result, or `nil` if the property is not numeric.
    public func compare(path: String, to value: Double) -> ComparisonResult? {
        guard let propertyValue = numericValue(forPath: path) else {
            return nil
        }

        if propertyValue < value {
            return .orderedAscending
        } else if propertyValue > value {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }

    /// Checks if a numeric property equals a value.
    ///
    /// - Parameters:
    ///   - path: The property path.
    ///   - value: The value to compare against.
    ///   - tolerance: The comparison tolerance for floating-point values.
    /// - Returns: `true` if equal (within tolerance), `false` otherwise.
    public func equals(path: String, value: Double, tolerance: Double = 1e-10) -> Bool {
        guard let propertyValue = numericValue(forPath: path) else {
            return false
        }
        return abs(propertyValue - value) <= tolerance
    }

    /// Checks if a string property equals a value.
    ///
    /// - Parameters:
    ///   - path: The property path.
    ///   - value: The value to compare against.
    ///   - caseSensitive: Whether the comparison is case-sensitive.
    /// - Returns: `true` if equal, `false` otherwise.
    public func equals(path: String, value: String, caseSensitive: Bool = true) -> Bool {
        guard let propertyValue = stringValue(forPath: path) else {
            return false
        }

        if caseSensitive {
            return propertyValue == value
        } else {
            return propertyValue.lowercased() == value.lowercased()
        }
    }

    /// Checks if a boolean property equals a value.
    ///
    /// - Parameters:
    ///   - path: The property path.
    ///   - value: The value to compare against.
    /// - Returns: `true` if equal, `false` otherwise.
    public func equals(path: String, value: Bool) -> Bool {
        guard let propertyValue = boolValue(forPath: path) else {
            return false
        }
        return propertyValue == value
    }
}

// MARK: - String Operations

extension PropertyAccessor {

    /// Checks if a string property contains a substring.
    ///
    /// - Parameters:
    ///   - path: The property path.
    ///   - substring: The substring to search for.
    ///   - caseSensitive: Whether the search is case-sensitive.
    /// - Returns: `true` if the substring is found, `false` otherwise.
    public func contains(path: String, substring: String, caseSensitive: Bool = true) -> Bool {
        guard let propertyValue = stringValue(forPath: path) else {
            return false
        }

        if caseSensitive {
            return propertyValue.contains(substring)
        } else {
            return propertyValue.lowercased().contains(substring.lowercased())
        }
    }

    /// Checks if a string property starts with a prefix.
    ///
    /// - Parameters:
    ///   - path: The property path.
    ///   - prefix: The prefix to check for.
    ///   - caseSensitive: Whether the check is case-sensitive.
    /// - Returns: `true` if the string starts with the prefix, `false` otherwise.
    public func hasPrefix(path: String, prefix: String, caseSensitive: Bool = true) -> Bool {
        guard let propertyValue = stringValue(forPath: path) else {
            return false
        }

        if caseSensitive {
            return propertyValue.hasPrefix(prefix)
        } else {
            return propertyValue.lowercased().hasPrefix(prefix.lowercased())
        }
    }

    /// Checks if a string property ends with a suffix.
    ///
    /// - Parameters:
    ///   - path: The property path.
    ///   - suffix: The suffix to check for.
    ///   - caseSensitive: Whether the check is case-sensitive.
    /// - Returns: `true` if the string ends with the suffix, `false` otherwise.
    public func hasSuffix(path: String, suffix: String, caseSensitive: Bool = true) -> Bool {
        guard let propertyValue = stringValue(forPath: path) else {
            return false
        }

        if caseSensitive {
            return propertyValue.hasSuffix(suffix)
        } else {
            return propertyValue.lowercased().hasSuffix(suffix.lowercased())
        }
    }
}
