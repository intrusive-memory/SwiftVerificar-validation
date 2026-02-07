import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Date+PDF Tests

@Suite("Date+PDF Extension Tests")
struct DatePDFTests {

    // MARK: - PDF Date Parsing Tests

    @Suite("PDF Date Parsing")
    struct PDFDateParsing {

        @Test("Parse full PDF date with timezone")
        func parseFullPDFDate() throws {
            let dateStr = "D:20230615120000+02'00'"
            let date = Date.fromPDFDate(dateStr)

            #expect(date != nil)

            let calendar = Calendar(identifier: .gregorian)
            var tz = TimeZone(secondsFromGMT: 7200)! // +02:00
            let components = calendar.dateComponents(in: tz, from: date!)

            #expect(components.year == 2023)
            #expect(components.month == 6)
            #expect(components.day == 15)
            #expect(components.hour == 12)
            #expect(components.minute == 0)
            #expect(components.second == 0)
        }

        @Test("Parse PDF date with negative timezone")
        func parsePDFDateNegativeTimezone() throws {
            let dateStr = "D:20230101080000-05'00'"
            let date = Date.fromPDFDate(dateStr)

            #expect(date != nil)
        }

        @Test("Parse PDF date with Z timezone")
        func parsePDFDateUTC() throws {
            let dateStr = "D:20230615120000Z"
            let date = Date.fromPDFDate(dateStr)

            #expect(date != nil)
        }

        @Test("Parse PDF date without timezone")
        func parsePDFDateNoTimezone() throws {
            let dateStr = "D:20230615120000"
            let date = Date.fromPDFDate(dateStr)

            #expect(date != nil)
        }

        @Test("Parse PDF date without D: prefix")
        func parsePDFDateNoPrefix() throws {
            let dateStr = "20230615120000"
            let date = Date.fromPDFDate(dateStr)

            #expect(date != nil)
        }

        @Test("Parse year-only PDF date")
        func parseYearOnlyPDFDate() throws {
            let dateStr = "D:2023"
            let date = Date.fromPDFDate(dateStr)

            #expect(date != nil)

            let calendar = Calendar(identifier: .gregorian)
            let components = calendar.dateComponents([.year], from: date!)
            #expect(components.year == 2023)
        }

        @Test("Parse year-month PDF date")
        func parseYearMonthPDFDate() throws {
            let dateStr = "D:202306"
            let date = Date.fromPDFDate(dateStr)

            #expect(date != nil)

            let calendar = Calendar(identifier: .gregorian)
            let components = calendar.dateComponents([.year, .month], from: date!)
            #expect(components.year == 2023)
            #expect(components.month == 6)
        }

        @Test("Parse date with whitespace")
        func parsePDFDateWithWhitespace() throws {
            let dateStr = "  D:20230615120000+02'00'  "
            let date = Date.fromPDFDate(dateStr)

            #expect(date != nil)
        }

        @Test("Invalid date returns nil")
        func invalidDateReturnsNil() throws {
            let dateStr = "invalid"
            let date = Date.fromPDFDate(dateStr)

            #expect(date == nil)
        }

        @Test("Empty string returns nil")
        func emptyStringReturnsNil() throws {
            let dateStr = ""
            let date = Date.fromPDFDate(dateStr)

            #expect(date == nil)
        }

        @Test("Short string returns nil")
        func shortStringReturnsNil() throws {
            let dateStr = "D:12"
            let date = Date.fromPDFDate(dateStr)

            #expect(date == nil)
        }
    }

    // MARK: - PDF Date Formatting Tests

    @Suite("PDF Date Formatting")
    struct PDFDateFormatting {

        @Test("Format date to PDF string")
        func formatDateToPDFString() throws {
            let components = DateComponents(
                calendar: Calendar(identifier: .gregorian),
                timeZone: TimeZone(secondsFromGMT: 0),
                year: 2023, month: 6, day: 15,
                hour: 12, minute: 30, second: 45
            )
            let date = components.date!

            let pdfStr = date.toPDFDateString(timeZone: TimeZone(secondsFromGMT: 0)!)

            #expect(pdfStr.hasPrefix("D:"))
            #expect(pdfStr.contains("20230615"))
            #expect(pdfStr.contains("123045"))
        }

        @Test("Format date with positive timezone")
        func formatDateWithPositiveTimezone() throws {
            let components = DateComponents(
                calendar: Calendar(identifier: .gregorian),
                timeZone: TimeZone(secondsFromGMT: 7200), // +02:00
                year: 2023, month: 6, day: 15,
                hour: 12, minute: 0, second: 0
            )
            let date = components.date!

            let pdfStr = date.toPDFDateString(timeZone: TimeZone(secondsFromGMT: 7200)!)

            #expect(pdfStr.contains("+02'00'"))
        }

        @Test("Format date with negative timezone")
        func formatDateWithNegativeTimezone() throws {
            let components = DateComponents(
                calendar: Calendar(identifier: .gregorian),
                timeZone: TimeZone(secondsFromGMT: -18000), // -05:00
                year: 2023, month: 1, day: 1,
                hour: 8, minute: 0, second: 0
            )
            let date = components.date!

            let pdfStr = date.toPDFDateString(timeZone: TimeZone(secondsFromGMT: -18000)!)

            #expect(pdfStr.contains("-05'00'"))
        }

        @Test("Format date with UTC timezone")
        func formatDateWithUTCTimezone() throws {
            let date = Date()
            let pdfStr = date.toPDFDateString(timeZone: TimeZone(secondsFromGMT: 0)!)

            #expect(pdfStr.contains("Z"))
        }
    }

    // MARK: - XMP Date Parsing Tests

    @Suite("XMP Date Parsing")
    struct XMPDateParsing {

        @Test("Parse ISO 8601 date with timezone")
        func parseISO8601WithTimezone() throws {
            let dateStr = "2023-06-15T12:00:00+02:00"
            let date = Date.fromXMPDate(dateStr)

            #expect(date != nil)
        }

        @Test("Parse ISO 8601 date with Z")
        func parseISO8601WithZ() throws {
            let dateStr = "2023-06-15T12:00:00Z"
            let date = Date.fromXMPDate(dateStr)

            #expect(date != nil)
        }

        @Test("Parse ISO 8601 date only")
        func parseISO8601DateOnly() throws {
            let dateStr = "2023-06-15"
            let date = Date.fromXMPDate(dateStr)

            #expect(date != nil)
        }

        @Test("Parse year only")
        func parseYearOnly() throws {
            let dateStr = "2023"
            let date = Date.fromXMPDate(dateStr)

            #expect(date != nil)
        }

        @Test("Invalid XMP date returns nil")
        func invalidXMPDateReturnsNil() throws {
            let dateStr = "invalid-date"
            let date = Date.fromXMPDate(dateStr)

            #expect(date == nil)
        }

        @Test("Empty string returns nil")
        func emptyXMPStringReturnsNil() throws {
            let dateStr = ""
            let date = Date.fromXMPDate(dateStr)

            #expect(date == nil)
        }
    }

    // MARK: - XMP Date Formatting Tests

    @Suite("XMP Date Formatting")
    struct XMPDateFormatting {

        @Test("Format date to XMP string")
        func formatDateToXMPString() throws {
            let date = Date()
            let xmpStr = date.toXMPDateString()

            #expect(xmpStr.contains("T"))
            #expect(xmpStr.count > 10)
        }

        @Test("Format date with specific timezone")
        func formatDateWithTimezone() throws {
            let date = Date()
            let xmpStr = date.toXMPDateString(timeZone: TimeZone(secondsFromGMT: 0)!)

            #expect(xmpStr.hasSuffix("Z"))
        }
    }

    // MARK: - Date Conversion Tests

    @Suite("Date Conversion")
    struct DateConversion {

        @Test("Convert PDF to XMP")
        func convertPDFToXMP() throws {
            let converter = PDFDateConverter()
            let pdfDate = "D:20230615120000Z"

            let xmpDate = converter.pdfToXMP(pdfDate)

            #expect(xmpDate != nil)
            #expect(xmpDate!.contains("2023"))
        }

        @Test("Convert XMP to PDF")
        func convertXMPToPDF() throws {
            let converter = PDFDateConverter()
            let xmpDate = "2023-06-15T12:00:00Z"

            let pdfDate = converter.xmpToPDF(xmpDate)

            #expect(pdfDate != nil)
            #expect(pdfDate!.hasPrefix("D:"))
        }

        @Test("Normalize date string")
        func normalizeDateString() throws {
            let converter = PDFDateConverter()
            let pdfDate = "D:20230615120000+02'00'"

            let normalized = converter.normalize(pdfDate)

            #expect(normalized != nil)
            #expect(normalized!.contains("T"))
        }

        @Test("Invalid conversion returns nil")
        func invalidConversionReturnsNil() throws {
            let converter = PDFDateConverter()

            #expect(converter.pdfToXMP("invalid") == nil)
            #expect(converter.xmpToPDF("invalid") == nil)
        }
    }

    // MARK: - Date Validation Tests

    @Suite("Date Validation")
    struct DateValidation {

        @Test("Validate valid PDF date")
        func validateValidPDFDate() throws {
            let validator = PDFDateValidator()
            let result = validator.validatePDFDate("D:20230615120000Z")

            #expect(result.isValid)
            #expect(result.issues.isEmpty)
        }

        @Test("Validate PDF date without prefix")
        func validatePDFDateWithoutPrefix() throws {
            let validator = PDFDateValidator()
            let result = validator.validatePDFDate("20230615120000Z")

            #expect(!result.isValid)
            #expect(result.issues.contains { $0.contains("prefix") })
        }

        @Test("Validate invalid PDF date")
        func validateInvalidPDFDate() throws {
            let validator = PDFDateValidator()
            let result = validator.validatePDFDate("D:invalid")

            #expect(!result.isValid)
        }

        @Test("Validate valid XMP date")
        func validateValidXMPDate() throws {
            let validator = PDFDateValidator()
            let result = validator.validateXMPDate("2023-06-15T12:00:00Z")

            #expect(result.isValid)
            #expect(result.issues.isEmpty)
        }

        @Test("Validate invalid XMP date")
        func validateInvalidXMPDate() throws {
            let validator = PDFDateValidator()
            let result = validator.validateXMPDate("invalid")

            #expect(!result.isValid)
        }

        @Test("Compare equivalent dates")
        func compareEquivalentDates() throws {
            let validator = PDFDateValidator()
            let pdfDate = "D:20230615120000Z"
            let xmpDate = "2023-06-15T12:00:00Z"

            let equivalent = validator.datesAreEquivalent(
                pdfDate: pdfDate,
                xmpDate: xmpDate
            )

            #expect(equivalent)
        }

        @Test("Compare non-equivalent dates")
        func compareNonEquivalentDates() throws {
            let validator = PDFDateValidator()
            let pdfDate = "D:20230615120000Z"
            let xmpDate = "2023-06-15T13:00:00Z" // 1 hour different

            let equivalent = validator.datesAreEquivalent(
                pdfDate: pdfDate,
                xmpDate: xmpDate
            )

            #expect(!equivalent)
        }
    }

    // MARK: - Roundtrip Tests

    @Suite("Roundtrip Tests")
    struct RoundtripTests {

        @Test("PDF date roundtrip")
        func pdfDateRoundtrip() throws {
            let originalDate = Date()
            let pdfStr = originalDate.toPDFDateString(timeZone: TimeZone(secondsFromGMT: 0)!)
            let parsedDate = Date.fromPDFDate(pdfStr)

            #expect(parsedDate != nil)
            #expect(abs(originalDate.timeIntervalSince(parsedDate!)) < 1.0)
        }

        @Test("XMP date roundtrip")
        func xmpDateRoundtrip() throws {
            let originalDate = Date()
            let xmpStr = originalDate.toXMPDateString(timeZone: TimeZone(secondsFromGMT: 0)!)
            let parsedDate = Date.fromXMPDate(xmpStr)

            #expect(parsedDate != nil)
            #expect(abs(originalDate.timeIntervalSince(parsedDate!)) < 1.0)
        }
    }
}
