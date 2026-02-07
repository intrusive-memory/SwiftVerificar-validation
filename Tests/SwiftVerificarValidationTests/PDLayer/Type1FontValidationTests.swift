import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - Type1FontValidation Tests

@Suite("Type1FontValidation")
struct Type1FontValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let font = Type1FontValidation()
            #expect(font.fontSubtype == .type1)
            #expect(font.baseFontName == nil)
            #expect(font.encodingName == nil)
            #expect(!font.hasToUnicode)
            #expect(!font.isEmbedded)
            #expect(font.firstChar == nil)
            #expect(font.lastChar == nil)
            #expect(font.widths.isEmpty)
            #expect(!font.isStandard14)
            #expect(!font.hasDifferencesEncoding)
            #expect(font.differencesCount == 0)
            #expect(!font.isMultipleMaster)
        }

        @Test("Full initialization")
        func fullInit() {
            let font = Type1FontValidation(
                baseFontName: "Helvetica-Bold",
                encodingName: "WinAnsiEncoding",
                hasToUnicode: true,
                isEmbedded: true,
                hasFontDescriptor: true,
                fontDescriptorFlags: 32,
                italicAngle: 0.0,
                fontBBox: [-166.0, -225.0, 1000.0, 931.0],
                glyphCount: 315,
                firstChar: 32,
                lastChar: 255,
                widths: Array(repeating: 500.0, count: 224),
                isStandard14: true,
                hasDifferencesEncoding: false,
                differencesCount: 0
            )

            #expect(font.baseFontName == "Helvetica-Bold")
            #expect(font.encodingName == "WinAnsiEncoding")
            #expect(font.hasToUnicode)
            #expect(font.isEmbedded)
            #expect(font.firstChar == 32)
            #expect(font.lastChar == 255)
            #expect(font.widths.count == 224)
            #expect(font.isStandard14)
            #expect(font.glyphCount == 315)
        }

        @Test("Object type is PDType1Font")
        func objectType() {
            let font = Type1FontValidation()
            #expect(font.objectType == "PDType1Font")
        }

        @Test("MMType1 subtype")
        func mmType1() {
            let font = Type1FontValidation(fontSubtype: .mmType1, baseFontName: "MyMMFont")
            #expect(font.fontSubtype == .mmType1)
            #expect(font.isMultipleMaster)
        }

        @Test("Default context uses font name")
        func defaultContext() {
            let font = Type1FontValidation(baseFontName: "Times-Roman")
            #expect(font.validationContext.location == "Font")
            #expect(font.validationContext.role == "Times-Roman")
        }

        @Test("Context falls back to resource name when no baseFontName")
        func contextFallback() {
            let font = Type1FontValidation(resourceName: ASAtom("F7"))
            #expect(font.validationContext.role == "F7")
        }
    }

    // MARK: - Character Range Validation

    @Suite("Character Range")
    struct CharRangeTests {

        @Test("hasValidCharRange with valid range")
        func validRange() {
            let font = Type1FontValidation(firstChar: 32, lastChar: 255)
            #expect(font.hasValidCharRange)
        }

        @Test("hasValidCharRange with single character")
        func singleChar() {
            let font = Type1FontValidation(firstChar: 65, lastChar: 65)
            #expect(font.hasValidCharRange)
        }

        @Test("hasValidCharRange false when firstChar > lastChar")
        func invertedRange() {
            let font = Type1FontValidation(firstChar: 255, lastChar: 32)
            #expect(!font.hasValidCharRange)
        }

        @Test("hasValidCharRange false when firstChar nil")
        func nilFirstChar() {
            let font = Type1FontValidation(lastChar: 255)
            #expect(!font.hasValidCharRange)
        }

        @Test("hasValidCharRange false when lastChar nil")
        func nilLastChar() {
            let font = Type1FontValidation(firstChar: 32)
            #expect(!font.hasValidCharRange)
        }

        @Test("hasValidCharRange false for negative firstChar")
        func negativeFirstChar() {
            let font = Type1FontValidation(firstChar: -1, lastChar: 255)
            #expect(!font.hasValidCharRange)
        }

        @Test("hasValidCharRange false for lastChar > 255")
        func lastCharTooLarge() {
            let font = Type1FontValidation(firstChar: 0, lastChar: 256)
            #expect(!font.hasValidCharRange)
        }

        @Test("hasMatchingWidths with correct count")
        func matchingWidths() {
            let font = Type1FontValidation(
                firstChar: 32,
                lastChar: 34,
                widths: [278.0, 333.0, 474.0]
            )
            #expect(font.hasMatchingWidths)
        }

        @Test("hasMatchingWidths false with wrong count")
        func mismatchedWidths() {
            let font = Type1FontValidation(
                firstChar: 32,
                lastChar: 34,
                widths: [278.0, 333.0]
            )
            #expect(!font.hasMatchingWidths)
        }

        @Test("hasMatchingWidths true when both nil and widths empty")
        func nilRangeEmptyWidths() {
            let font = Type1FontValidation()
            #expect(font.hasMatchingWidths)
        }

        @Test("hasMatchingWidths false when both nil but widths non-empty")
        func nilRangeWithWidths() {
            let font = Type1FontValidation(widths: [500.0])
            #expect(!font.hasMatchingWidths)
        }
    }

    // MARK: - Standard 14 Fonts

    @Suite("Standard 14 Fonts")
    struct Standard14Tests {

        @Test("isStandard14 static method recognizes all 14 fonts")
        func allStandard14() {
            let names = [
                "Courier", "Courier-Bold", "Courier-BoldOblique", "Courier-Oblique",
                "Helvetica", "Helvetica-Bold", "Helvetica-BoldOblique", "Helvetica-Oblique",
                "Symbol", "Times-Bold", "Times-BoldItalic", "Times-Italic",
                "Times-Roman", "ZapfDingbats"
            ]
            for name in names {
                #expect(Type1FontValidation.isStandard14(name: name), "Expected \(name) to be standard 14")
            }
        }

        @Test("isStandard14 returns false for non-standard fonts")
        func nonStandard() {
            #expect(!Type1FontValidation.isStandard14(name: "Arial"))
            #expect(!Type1FontValidation.isStandard14(name: "CustomFont"))
            #expect(!Type1FontValidation.isStandard14(name: ""))
        }

        @Test("standard14FontNames set has exactly 14 entries")
        func standard14Count() {
            #expect(Type1FontValidation.standard14FontNames.count == 14)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include Type 1 specific properties")
        func propertyNames() {
            let font = Type1FontValidation()
            let names = font.propertyNames
            #expect(names.contains("firstChar"))
            #expect(names.contains("lastChar"))
            #expect(names.contains("widthsCount"))
            #expect(names.contains("isStandard14"))
            #expect(names.contains("hasDifferencesEncoding"))
            #expect(names.contains("differencesCount"))
            #expect(names.contains("hasValidCharRange"))
            #expect(names.contains("hasMatchingWidths"))
            #expect(names.contains("isMultipleMaster"))
        }

        @Test("Property access for firstChar and lastChar")
        func charRangeProperties() {
            let font = Type1FontValidation(firstChar: 32, lastChar: 255)
            #expect(font.property(named: "firstChar") == .integer(32))
            #expect(font.property(named: "lastChar") == .integer(255))
        }

        @Test("Property access for null firstChar and lastChar")
        func nullCharRange() {
            let font = Type1FontValidation()
            #expect(font.property(named: "firstChar") == .null)
            #expect(font.property(named: "lastChar") == .null)
        }

        @Test("Property access for widthsCount")
        func widthsCount() {
            let font = Type1FontValidation(widths: [500.0, 600.0, 700.0])
            #expect(font.property(named: "widthsCount") == .integer(3))
        }

        @Test("Property access for boolean properties")
        func booleanProperties() {
            let font = Type1FontValidation(
                isStandard14: true,
                hasDifferencesEncoding: true,
                differencesCount: 5
            )
            #expect(font.property(named: "isStandard14") == .boolean(true))
            #expect(font.property(named: "hasDifferencesEncoding") == .boolean(true))
            #expect(font.property(named: "differencesCount") == .integer(5))
        }

        @Test("Property access for hasValidCharRange")
        func validCharRange() {
            let font = Type1FontValidation(firstChar: 32, lastChar: 127)
            #expect(font.property(named: "hasValidCharRange") == .boolean(true))
        }

        @Test("Property access for hasMatchingWidths")
        func matchingWidths() {
            let font = Type1FontValidation(firstChar: 0, lastChar: 1, widths: [500.0, 600.0])
            #expect(font.property(named: "hasMatchingWidths") == .boolean(true))
        }

        @Test("Property access for isMultipleMaster")
        func multipleMaster() {
            let mm = Type1FontValidation(fontSubtype: .mmType1)
            #expect(mm.property(named: "isMultipleMaster") == .boolean(true))

            let regular = Type1FontValidation()
            #expect(regular.property(named: "isMultipleMaster") == .boolean(false))
        }

        @Test("Falls through to font properties")
        func fontFallthrough() {
            let font = Type1FontValidation(baseFontName: "Courier", isEmbedded: true)
            #expect(font.property(named: "fontSubtype") == .string("Type1"))
            #expect(font.property(named: "baseFontName") == .string("Courier"))
            #expect(font.property(named: "isEmbedded") == .boolean(true))
        }

        @Test("Falls through to resource properties")
        func resourceFallthrough() {
            let font = Type1FontValidation(resourceName: ASAtom("F2"))
            #expect(font.property(named: "resourceName") == .name("F2"))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let font = Type1FontValidation()
            #expect(font.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let f1 = Type1FontValidation(id: id, baseFontName: "A")
            let f2 = Type1FontValidation(id: id, baseFontName: "B")
            #expect(f1 == f2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let f1 = Type1FontValidation(baseFontName: "A")
            let f2 = Type1FontValidation(baseFontName: "A")
            #expect(f1 != f2)
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("minimal factory")
        func minimal() {
            let font = Type1FontValidation.minimal(name: "TestFont", encoding: "MacRomanEncoding")
            #expect(font.baseFontName == "TestFont")
            #expect(font.encodingName == "MacRomanEncoding")
            #expect(font.fontSubtype == .type1)
        }

        @Test("standard14 factory")
        func standard14() {
            let font = Type1FontValidation.standard14(name: "Times-Roman")
            #expect(font.baseFontName == "Times-Roman")
            #expect(font.isStandard14)
            #expect(font.encodingName == "WinAnsiEncoding")
        }

        @Test("standard14 factory with default name")
        func standard14Default() {
            let font = Type1FontValidation.standard14()
            #expect(font.baseFontName == "Helvetica")
            #expect(font.isStandard14)
        }
    }
}
