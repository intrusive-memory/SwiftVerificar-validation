import Foundation

// MARK: - PDF Date Extension

/// Extension for parsing and formatting PDF date strings.
///
/// PDF dates follow the format defined in PDF 1.7 specification (section 7.9.4):
/// `D:YYYYMMDDHHmmSSOHH'mm'`
///
/// Where:
/// - YYYY: Year
/// - MM: Month (01-12)
/// - DD: Day (01-31)
/// - HH: Hour (00-23)
/// - mm: Minute (00-59)
/// - SS: Second (00-59)
/// - O: Offset indicator (+, -, or Z)
/// - HH'mm': Timezone offset
///
/// XMP dates follow ISO 8601 format:
/// `YYYY-MM-DDTHH:mm:ss+HH:mm` or `YYYY-MM-DDTHH:mm:ssZ`
extension Date {

    // MARK: - PDF Date Parsing

    /// Creates a Date from a PDF date string.
    ///
    /// - Parameter pdfDateString: A PDF-format date string (e.g., "D:20230615120000+02'00'")
    /// - Returns: The parsed Date, or nil if parsing fails
    public static func fromPDFDate(_ pdfDateString: String) -> Date? {
        let parser = PDFDateParser()
        return parser.parse(pdfDateString)
    }

    /// Returns the date formatted as a PDF date string.
    ///
    /// - Parameter timeZone: The timezone to use for formatting. Defaults to current.
    /// - Returns: A PDF-format date string (e.g., "D:20230615120000+02'00'")
    public func toPDFDateString(timeZone: TimeZone = .current) -> String {
        let formatter = PDFDateFormatter(timeZone: timeZone)
        return formatter.format(self)
    }

    // MARK: - XMP Date Parsing

    /// Creates a Date from an XMP (ISO 8601) date string.
    ///
    /// - Parameter xmpDateString: An XMP-format date string (e.g., "2023-06-15T12:00:00+02:00")
    /// - Returns: The parsed Date, or nil if parsing fails
    public static func fromXMPDate(_ xmpDateString: String) -> Date? {
        let parser = XMPDateParser()
        return parser.parse(xmpDateString)
    }

    /// Returns the date formatted as an XMP (ISO 8601) date string.
    ///
    /// - Parameter timeZone: The timezone to use for formatting. Defaults to current.
    /// - Returns: An XMP-format date string (e.g., "2023-06-15T12:00:00+02:00")
    public func toXMPDateString(timeZone: TimeZone = .current) -> String {
        let formatter = XMPDateFormatter(timeZone: timeZone)
        return formatter.format(self)
    }
}

// MARK: - PDF Date Parser

/// Parser for PDF date strings.
///
/// PDF date format: `D:YYYYMMDDHHmmSSOHH'mm'`
public struct PDFDateParser: Sendable {

    public init() {}

    /// Parses a PDF date string into a Date.
    ///
    /// - Parameter string: The PDF date string to parse
    /// - Returns: The parsed Date, or nil if parsing fails
    public func parse(_ string: String) -> Date? {
        var dateString = string.trimmingCharacters(in: .whitespaces)

        // Remove the "D:" prefix if present
        if dateString.hasPrefix("D:") {
            dateString = String(dateString.dropFirst(2))
        }

        // Minimum: YYYY
        guard dateString.count >= 4 else { return nil }

        // Parse components
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)

        // Year (required)
        guard let year = Int(dateString.prefix(4)) else { return nil }
        components.year = year
        dateString = String(dateString.dropFirst(4))

        // Month (optional, defaults to 01)
        if dateString.count >= 2, let month = Int(dateString.prefix(2)), month >= 1, month <= 12 {
            components.month = month
            dateString = String(dateString.dropFirst(2))
        } else {
            components.month = 1
        }

        // Day (optional, defaults to 01)
        if dateString.count >= 2, let day = Int(dateString.prefix(2)), day >= 1, day <= 31 {
            components.day = day
            dateString = String(dateString.dropFirst(2))
        } else {
            components.day = 1
        }

        // Hour (optional, defaults to 00)
        if dateString.count >= 2, let hour = Int(dateString.prefix(2)), hour >= 0, hour <= 23 {
            components.hour = hour
            dateString = String(dateString.dropFirst(2))
        } else {
            components.hour = 0
        }

        // Minute (optional, defaults to 00)
        if dateString.count >= 2, let minute = Int(dateString.prefix(2)), minute >= 0, minute <= 59 {
            components.minute = minute
            dateString = String(dateString.dropFirst(2))
        } else {
            components.minute = 0
        }

        // Second (optional, defaults to 00)
        if dateString.count >= 2, let second = Int(dateString.prefix(2)), second >= 0, second <= 59 {
            components.second = second
            dateString = String(dateString.dropFirst(2))
        } else {
            components.second = 0
        }

        // Parse timezone offset
        if let timeZone = parseTimeZone(dateString) {
            components.timeZone = timeZone
        } else {
            // No timezone specified — per PDF spec, treat as local time
            components.timeZone = .current
        }

        return components.date
    }

    /// Parses the timezone portion of a PDF date string.
    private func parseTimeZone(_ string: String) -> TimeZone? {
        guard !string.isEmpty else { return nil }

        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Z means UTC
        if trimmed == "Z" {
            return TimeZone(secondsFromGMT: 0)
        }

        // Parse +HH'mm' or -HH'mm' format
        let firstChar = trimmed.first!
        guard firstChar == "+" || firstChar == "-" else { return nil }

        let sign = firstChar == "+" ? 1 : -1
        var remaining = String(trimmed.dropFirst())

        // Remove quotes and apostrophes
        remaining = remaining.replacingOccurrences(of: "'", with: "")

        guard remaining.count >= 2 else { return nil }

        guard let hours = Int(remaining.prefix(2)) else { return nil }
        remaining = String(remaining.dropFirst(2))

        var minutes = 0
        if remaining.count >= 2, let min = Int(remaining.prefix(2)) {
            minutes = min
        }

        let totalSeconds = sign * (hours * 3600 + minutes * 60)
        return TimeZone(secondsFromGMT: totalSeconds)
    }
}

// MARK: - PDF Date Formatter

/// Formatter for creating PDF date strings.
public struct PDFDateFormatter: Sendable {

    /// The timezone to use for formatting.
    public let timeZone: TimeZone

    public init(timeZone: TimeZone = .current) {
        self.timeZone = timeZone
    }

    /// Formats a Date as a PDF date string.
    ///
    /// - Parameter date: The date to format
    /// - Returns: A PDF-format date string
    public func format(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )

        let year = String(format: "%04d", components.year ?? 0)
        let month = String(format: "%02d", components.month ?? 1)
        let day = String(format: "%02d", components.day ?? 1)
        let hour = String(format: "%02d", components.hour ?? 0)
        let minute = String(format: "%02d", components.minute ?? 0)
        let second = String(format: "%02d", components.second ?? 0)

        let tzOffset = formatTimeZoneOffset()

        return "D:\(year)\(month)\(day)\(hour)\(minute)\(second)\(tzOffset)"
    }

    /// Formats the timezone offset for PDF dates.
    private func formatTimeZoneOffset() -> String {
        let seconds = timeZone.secondsFromGMT()

        if seconds == 0 {
            return "Z"
        }

        let sign = seconds >= 0 ? "+" : "-"
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60

        return "\(sign)\(String(format: "%02d", hours))'\(String(format: "%02d", minutes))'"
    }
}

// MARK: - XMP Date Parser

/// Parser for XMP (ISO 8601) date strings.
public struct XMPDateParser: Sendable {

    public init() {}

    /// Parses an XMP date string into a Date.
    ///
    /// Supports various ISO 8601 formats:
    /// - `YYYY`
    /// - `YYYY-MM`
    /// - `YYYY-MM-DD`
    /// - `YYYY-MM-DDTHH:mm`
    /// - `YYYY-MM-DDTHH:mm:ss`
    /// - `YYYY-MM-DDTHH:mm:ssZ`
    /// - `YYYY-MM-DDTHH:mm:ss+HH:mm`
    ///
    /// - Parameter string: The XMP date string to parse
    /// - Returns: The parsed Date, or nil if parsing fails
    public func parse(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Try ISO 8601 formatter first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }

        // Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }

        // Try with just date and time
        isoFormatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }

        // Try custom parsing for partial dates
        return parsePartialDate(trimmed)
    }

    /// Parses partial ISO 8601 dates (year-only, year-month, etc.)
    private func parsePartialDate(_ string: String) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)

        // Try different patterns
        let patterns = [
            ("yyyy-MM-dd'T'HH:mm:ssXXXXX", string),
            ("yyyy-MM-dd'T'HH:mm:ss", string),
            ("yyyy-MM-dd'T'HH:mm", string),
            ("yyyy-MM-dd", string),
            ("yyyy-MM", string),
            ("yyyy", string)
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for (pattern, dateStr) in patterns {
            formatter.dateFormat = pattern
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }

        // Last resort: extract year only
        if string.count >= 4, let year = Int(string.prefix(4)) {
            components.year = year
            components.month = 1
            components.day = 1
            components.hour = 0
            components.minute = 0
            components.second = 0
            return components.date
        }

        return nil
    }
}

// MARK: - XMP Date Formatter

/// Formatter for creating XMP (ISO 8601) date strings.
public struct XMPDateFormatter: Sendable {

    /// The timezone to use for formatting.
    public let timeZone: TimeZone

    /// Whether to include fractional seconds.
    public let includeFractionalSeconds: Bool

    public init(timeZone: TimeZone = .current, includeFractionalSeconds: Bool = false) {
        self.timeZone = timeZone
        self.includeFractionalSeconds = includeFractionalSeconds
    }

    /// Formats a Date as an XMP (ISO 8601) date string.
    ///
    /// - Parameter date: The date to format
    /// - Returns: An XMP-format date string
    public func format(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timeZone

        if includeFractionalSeconds {
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        } else {
            formatter.formatOptions = [.withInternetDateTime]
        }

        return formatter.string(from: date)
    }
}

// MARK: - PDF Date Validation

/// Validates PDF and XMP date strings.
public struct PDFDateValidator: Sendable {

    public init() {}

    /// Validates a PDF date string.
    ///
    /// - Parameter string: The PDF date string to validate
    /// - Returns: A validation result with any issues found
    public func validatePDFDate(_ string: String) -> DateValidationResult {
        var issues: [String] = []

        // Check for D: prefix
        let hasPrefix = string.hasPrefix("D:")
        if !hasPrefix {
            issues.append("Missing 'D:' prefix")
        }

        // Try parsing
        let parser = PDFDateParser()
        if parser.parse(string) == nil {
            issues.append("Unable to parse date string")
        }

        return DateValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }

    /// Validates an XMP date string.
    ///
    /// - Parameter string: The XMP date string to validate
    /// - Returns: A validation result with any issues found
    public func validateXMPDate(_ string: String) -> DateValidationResult {
        var issues: [String] = []

        // Try parsing
        let parser = XMPDateParser()
        if parser.parse(string) == nil {
            issues.append("Unable to parse XMP date string as ISO 8601")
        }

        return DateValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }

    /// Compares a PDF date and XMP date for equivalence.
    ///
    /// - Parameters:
    ///   - pdfDate: The PDF date string
    ///   - xmpDate: The XMP date string
    ///   - toleranceSeconds: Tolerance for comparison in seconds (default: 1)
    /// - Returns: Whether the dates are equivalent within tolerance
    public func datesAreEquivalent(
        pdfDate: String,
        xmpDate: String,
        toleranceSeconds: TimeInterval = 1.0
    ) -> Bool {
        guard let pdf = Date.fromPDFDate(pdfDate),
              let xmp = Date.fromXMPDate(xmpDate) else {
            return false
        }

        return abs(pdf.timeIntervalSince(xmp)) <= toleranceSeconds
    }
}

// MARK: - Date Validation Result

/// Result of validating a date string.
public struct DateValidationResult: Sendable, Equatable {
    /// Whether the date string is valid.
    public let isValid: Bool

    /// Any issues found during validation.
    public let issues: [String]

    public init(isValid: Bool, issues: [String] = []) {
        self.isValid = isValid
        self.issues = issues
    }
}

// MARK: - PDF Date Conversion

/// Utilities for converting between PDF and XMP date formats.
public struct PDFDateConverter: Sendable {

    public init() {}

    /// Converts a PDF date string to XMP format.
    ///
    /// - Parameter pdfDate: The PDF date string
    /// - Returns: The XMP-format date string, or nil if parsing fails
    public func pdfToXMP(_ pdfDate: String) -> String? {
        guard let date = Date.fromPDFDate(pdfDate) else { return nil }
        return date.toXMPDateString()
    }

    /// Converts an XMP date string to PDF format.
    ///
    /// - Parameter xmpDate: The XMP date string
    /// - Returns: The PDF-format date string, or nil if parsing fails
    public func xmpToPDF(_ xmpDate: String) -> String? {
        guard let date = Date.fromXMPDate(xmpDate) else { return nil }
        return date.toPDFDateString()
    }

    /// Normalizes a date string from either format to a canonical form.
    ///
    /// - Parameter dateString: A PDF or XMP date string
    /// - Returns: A normalized XMP (ISO 8601) date string, or nil if parsing fails
    public func normalize(_ dateString: String) -> String? {
        // Try PDF format first
        if let date = Date.fromPDFDate(dateString) {
            return date.toXMPDateString(timeZone: TimeZone(secondsFromGMT: 0)!)
        }

        // Try XMP format
        if let date = Date.fromXMPDate(dateString) {
            return date.toXMPDateString(timeZone: TimeZone(secondsFromGMT: 0)!)
        }

        return nil
    }
}
