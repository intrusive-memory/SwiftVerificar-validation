import Foundation
import Testing
@testable import SwiftVerificarValidation
import SwiftVerificarParser

// MARK: - TrueTypeFontValidation Tests

@Suite("TrueTypeFontValidation")
struct TrueTypeFontValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let font = TrueTypeFontValidation()
            #expect(font.fontSubtype == .trueType)
            #expect(font.baseFontName == nil)
            #expect(font.encodingName == nil)
            #expect(!font.hasToUnicode)
            #expect(!font.isEmbedded)
            #expect(font.firstChar == nil)
            #expect(font.lastChar == nil)
            #expect(font.widths.isEmpty)
            #expect(!font.hasDifferencesEncoding)
            #expect(font.differencesCount == 0)
            #expect(font.hasCmapTable)
            #expect(font.hasPostTable)
            #expect(!font.isWindowsSymbolEncoding)
        }

        @Test("Full initialization")
        func fullInit() {
            let program = FontProgramValidation.trueTypeProgram()
            let font = TrueTypeFontValidation(
                baseFontName: "ArialMT",
                encodingName: "WinAnsiEncoding",
                hasToUnicode: true,
                isEmbedded: true,
                hasFontDescriptor: true,
                fontDescriptorFlags: 32,
                italicAngle: 0.0,
                fontBBox: [-665.0, -325.0, 2000.0, 1006.0],
                fontProgram: program,
                glyphCount: 4514,
                firstChar: 32,
                lastChar: 255,
                widths: Array(repeating: 750.0, count: 224),
                hasCmapTable: true,
                hasPostTable: true
            )

            #expect(font.baseFontName == "ArialMT")
            #expect(font.isEmbedded)
            #expect(font.glyphCount == 4514)
            #expect(font.firstChar == 32)
            #expect(font.lastChar == 255)
            #expect(font.widths.count == 224)
            #expect(font.hasCmapTable)
            #expect(font.hasPostTable)
            #expect(font.fontProgram != nil)
        }

        @Test("Object type is PDTrueTypeFont")
        func objectType() {
            let font = TrueTypeFontValidation()
            #expect(font.objectType == "PDTrueTypeFont")
        }

        @Test("Default context uses font name")
        func defaultContext() {
            let font = TrueTypeFontValidation(baseFontName: "ArialMT")
            #expect(font.validationContext.location == "Font")
            #expect(font.validationContext.role == "ArialMT")
        }
    }

    // MARK: - Character Range Validation

    @Suite("Character Range")
    struct CharRangeTests {

        @Test("hasValidCharRange with valid range")
        func validRange() {
            let font = TrueTypeFontValidation(firstChar: 0, lastChar: 255)
            #expect(font.hasValidCharRange)
        }

        @Test("hasValidCharRange false when firstChar > lastChar")
        func invertedRange() {
            let font = TrueTypeFontValidation(firstChar: 200, lastChar: 50)
            #expect(!font.hasValidCharRange)
        }

        @Test("hasValidCharRange false when nil")
        func nilRange() {
            let font = TrueTypeFontValidation()
            #expect(!font.hasValidCharRange)
        }

        @Test("hasMatchingWidths with correct count")
        func matchingWidths() {
            let font = TrueTypeFontValidation(
                firstChar: 65,
                lastChar: 67,
                widths: [722.0, 667.0, 722.0]
            )
            #expect(font.hasMatchingWidths)
        }

        @Test("hasMatchingWidths false with wrong count")
        func mismatchedWidths() {
            let font = TrueTypeFontValidation(
                firstChar: 65,
                lastChar: 67,
                widths: [722.0, 667.0]
            )
            #expect(!font.hasMatchingWidths)
        }

        @Test("hasMatchingWidths true when no range and no widths")
        func noRangeNoWidths() {
            let font = TrueTypeFontValidation()
            #expect(font.hasMatchingWidths)
        }
    }

    // MARK: - TrueType Specific Properties

    @Suite("TrueType Specific")
    struct TrueTypeSpecificTests {

        @Test("hasCmapTable default is true")
        func defaultCmapTable() {
            let font = TrueTypeFontValidation()
            #expect(font.hasCmapTable)
        }

        @Test("hasCmapTable can be set to false")
        func missingCmapTable() {
            let font = TrueTypeFontValidation(hasCmapTable: false)
            #expect(!font.hasCmapTable)
        }

        @Test("hasPostTable default is true")
        func defaultPostTable() {
            let font = TrueTypeFontValidation()
            #expect(font.hasPostTable)
        }

        @Test("hasPostTable can be set to false")
        func missingPostTable() {
            let font = TrueTypeFontValidation(hasPostTable: false)
            #expect(!font.hasPostTable)
        }

        @Test("isWindowsSymbolEncoding")
        func windowsSymbol() {
            let font = TrueTypeFontValidation(isWindowsSymbolEncoding: true)
            #expect(font.isWindowsSymbolEncoding)
        }

        @Test("hasDifferencesEncoding")
        func differencesEncoding() {
            let font = TrueTypeFontValidation(hasDifferencesEncoding: true, differencesCount: 10)
            #expect(font.hasDifferencesEncoding)
            #expect(font.differencesCount == 10)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include TrueType specific properties")
        func propertyNames() {
            let font = TrueTypeFontValidation()
            let names = font.propertyNames
            #expect(names.contains("firstChar"))
            #expect(names.contains("lastChar"))
            #expect(names.contains("widthsCount"))
            #expect(names.contains("hasDifferencesEncoding"))
            #expect(names.contains("differencesCount"))
            #expect(names.contains("hasCmapTable"))
            #expect(names.contains("hasPostTable"))
            #expect(names.contains("isWindowsSymbolEncoding"))
            #expect(names.contains("hasValidCharRange"))
            #expect(names.contains("hasMatchingWidths"))
        }

        @Test("Property access for firstChar and lastChar")
        func charRange() {
            let font = TrueTypeFontValidation(firstChar: 32, lastChar: 126)
            #expect(font.property(named: "firstChar") == .integer(32))
            #expect(font.property(named: "lastChar") == .integer(126))
        }

        @Test("Property access for null firstChar and lastChar")
        func nullCharRange() {
            let font = TrueTypeFontValidation()
            #expect(font.property(named: "firstChar") == .null)
            #expect(font.property(named: "lastChar") == .null)
        }

        @Test("Property access for widthsCount")
        func widthsCount() {
            let font = TrueTypeFontValidation(widths: [500.0, 600.0])
            #expect(font.property(named: "widthsCount") == .integer(2))
        }

        @Test("Property access for table presence")
        func tablePresence() {
            let font = TrueTypeFontValidation(hasCmapTable: false, hasPostTable: false)
            #expect(font.property(named: "hasCmapTable") == .boolean(false))
            #expect(font.property(named: "hasPostTable") == .boolean(false))
        }

        @Test("Property access for symbol encoding")
        func symbolEncoding() {
            let font = TrueTypeFontValidation(isWindowsSymbolEncoding: true)
            #expect(font.property(named: "isWindowsSymbolEncoding") == .boolean(true))
        }

        @Test("Property access for computed properties")
        func computedProperties() {
            let font = TrueTypeFontValidation(firstChar: 0, lastChar: 2, widths: [500.0, 600.0, 700.0])
            #expect(font.property(named: "hasValidCharRange") == .boolean(true))
            #expect(font.property(named: "hasMatchingWidths") == .boolean(true))
        }

        @Test("Falls through to font properties")
        func fontFallthrough() {
            let font = TrueTypeFontValidation(baseFontName: "ArialMT", isEmbedded: true)
            #expect(font.property(named: "fontSubtype") == .string("TrueType"))
            #expect(font.property(named: "baseFontName") == .string("ArialMT"))
            #expect(font.property(named: "isEmbedded") == .boolean(true))
        }

        @Test("Falls through to resource properties")
        func resourceFallthrough() {
            let font = TrueTypeFontValidation(resourceName: ASAtom("F3"))
            #expect(font.property(named: "resourceName") == .name("F3"))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let font = TrueTypeFontValidation()
            #expect(font.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let f1 = TrueTypeFontValidation(id: id, baseFontName: "A")
            let f2 = TrueTypeFontValidation(id: id, baseFontName: "B")
            #expect(f1 == f2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let f1 = TrueTypeFontValidation(baseFontName: "A")
            let f2 = TrueTypeFontValidation(baseFontName: "A")
            #expect(f1 != f2)
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("minimal factory")
        func minimal() {
            let font = TrueTypeFontValidation.minimal(name: "TimesNewRomanPSMT")
            #expect(font.baseFontName == "TimesNewRomanPSMT")
            #expect(font.fontSubtype == .trueType)
            #expect(font.encodingName == "WinAnsiEncoding")
        }

        @Test("minimal factory with defaults")
        func minimalDefaults() {
            let font = TrueTypeFontValidation.minimal()
            #expect(font.baseFontName == "TestTrueTypeFont")
            #expect(!font.isEmbedded)
        }

        @Test("minimal factory with embedded flag")
        func minimalEmbedded() {
            let font = TrueTypeFontValidation.minimal(embedded: true)
            #expect(font.isEmbedded)
        }
    }
}
