import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - FontSubtype Tests

@Suite("FontSubtype")
struct FontSubtypeTests {

    @Test("All subtypes have correct raw values")
    func rawValues() {
        #expect(FontSubtype.type0.rawValue == "Type0")
        #expect(FontSubtype.type1.rawValue == "Type1")
        #expect(FontSubtype.mmType1.rawValue == "MMType1")
        #expect(FontSubtype.type3.rawValue == "Type3")
        #expect(FontSubtype.trueType.rawValue == "TrueType")
        #expect(FontSubtype.cidFontType0.rawValue == "CIDFontType0")
        #expect(FontSubtype.cidFontType2.rawValue == "CIDFontType2")
        #expect(FontSubtype.unknown.rawValue == "Unknown")
    }

    @Test("CaseIterable includes all subtypes")
    func caseIterable() {
        #expect(FontSubtype.allCases.count == 8)
    }

    @Test("fromName creates correct subtype")
    func fromName() {
        #expect(FontSubtype(fromName: "Type0") == .type0)
        #expect(FontSubtype(fromName: "Type1") == .type1)
        #expect(FontSubtype(fromName: "TrueType") == .trueType)
        #expect(FontSubtype(fromName: "CIDFontType0") == .cidFontType0)
        #expect(FontSubtype(fromName: "CIDFontType2") == .cidFontType2)
        #expect(FontSubtype(fromName: nil) == .unknown)
        #expect(FontSubtype(fromName: "InvalidType") == .unknown)
    }

    @Test("fromAtom creates correct subtype")
    func fromAtom() {
        #expect(FontSubtype(fromAtom: ASAtom("Type1")) == .type1)
        #expect(FontSubtype(fromAtom: ASAtom("TrueType")) == .trueType)
        #expect(FontSubtype(fromAtom: nil) == .unknown)
    }

    @Test("isSimpleFont returns true for simple fonts")
    func isSimpleFont() {
        #expect(FontSubtype.type1.isSimpleFont)
        #expect(FontSubtype.mmType1.isSimpleFont)
        #expect(FontSubtype.type3.isSimpleFont)
        #expect(FontSubtype.trueType.isSimpleFont)
        #expect(!FontSubtype.type0.isSimpleFont)
        #expect(!FontSubtype.cidFontType0.isSimpleFont)
        #expect(!FontSubtype.cidFontType2.isSimpleFont)
        #expect(!FontSubtype.unknown.isSimpleFont)
    }

    @Test("isCompositeFont returns true only for Type0")
    func isCompositeFont() {
        #expect(FontSubtype.type0.isCompositeFont)
        #expect(!FontSubtype.type1.isCompositeFont)
        #expect(!FontSubtype.trueType.isCompositeFont)
        #expect(!FontSubtype.cidFontType0.isCompositeFont)
    }

    @Test("isCIDFont returns true for CIDFont types")
    func isCIDFont() {
        #expect(FontSubtype.cidFontType0.isCIDFont)
        #expect(FontSubtype.cidFontType2.isCIDFont)
        #expect(!FontSubtype.type0.isCIDFont)
        #expect(!FontSubtype.type1.isCIDFont)
        #expect(!FontSubtype.trueType.isCIDFont)
    }
}

// MARK: - FontDescriptorFlags Tests

@Suite("FontDescriptorFlags")
struct FontDescriptorFlagsTests {

    @Test("Individual flags have correct raw values")
    func flagValues() {
        #expect(FontDescriptorFlags.fixedPitch.rawValue == 1)
        #expect(FontDescriptorFlags.serif.rawValue == 2)
        #expect(FontDescriptorFlags.symbolic.rawValue == 4)
        #expect(FontDescriptorFlags.script.rawValue == 8)
        #expect(FontDescriptorFlags.nonsymbolic.rawValue == 32)
        #expect(FontDescriptorFlags.italic.rawValue == 64)
        #expect(FontDescriptorFlags.allCap.rawValue == 65536)
        #expect(FontDescriptorFlags.smallCap.rawValue == 131072)
        #expect(FontDescriptorFlags.forceBold.rawValue == 262144)
    }

    @Test("OptionSet combination works correctly")
    func combination() {
        let flags: FontDescriptorFlags = [.fixedPitch, .symbolic, .italic]
        #expect(flags.contains(.fixedPitch))
        #expect(flags.contains(.symbolic))
        #expect(flags.contains(.italic))
        #expect(!flags.contains(.serif))
        #expect(!flags.contains(.nonsymbolic))
    }

    @Test("Flags created from raw value")
    func fromRawValue() {
        let flags = FontDescriptorFlags(rawValue: 0b1000100)  // symbolic + italic
        #expect(flags.contains(.symbolic))
        #expect(flags.contains(.italic))
        #expect(!flags.contains(.fixedPitch))
    }

    @Test("Empty flags has no bits set")
    func emptyFlags() {
        let flags: FontDescriptorFlags = []
        #expect(!flags.contains(.fixedPitch))
        #expect(!flags.contains(.symbolic))
        #expect(flags.rawValue == 0)
    }
}

// MARK: - FontValidation Protocol Default Tests

@Suite("FontValidation Protocol Defaults")
struct FontValidationDefaultTests {

    @Test("Default fontProperty returns correct values for base font name")
    func fontPropertyBaseFontName() {
        let font = Type1FontValidation(baseFontName: "Helvetica")
        #expect(font.fontProperty(named: "baseFontName") == .string("Helvetica"))
    }

    @Test("Default fontProperty returns null for nil base font name")
    func fontPropertyNilBaseFontName() {
        let font = Type1FontValidation()
        #expect(font.fontProperty(named: "baseFontName") == .null)
    }

    @Test("Default fontProperty returns encoding name")
    func fontPropertyEncoding() {
        let font = Type1FontValidation(encodingName: "WinAnsiEncoding")
        #expect(font.fontProperty(named: "encodingName") == .string("WinAnsiEncoding"))
    }

    @Test("Default fontProperty returns null for nil encoding")
    func fontPropertyNilEncoding() {
        let font = Type1FontValidation()
        #expect(font.fontProperty(named: "encodingName") == .null)
    }

    @Test("Default fontProperty returns boolean properties")
    func fontPropertyBooleans() {
        let font = Type1FontValidation(hasToUnicode: true, isEmbedded: true, hasFontDescriptor: true)
        #expect(font.fontProperty(named: "hasToUnicode") == .boolean(true))
        #expect(font.fontProperty(named: "isEmbedded") == .boolean(true))
        #expect(font.fontProperty(named: "hasFontDescriptor") == .boolean(true))
    }

    @Test("Default fontProperty returns descriptor flags")
    func fontPropertyDescriptorFlags() {
        let font = Type1FontValidation(fontDescriptorFlags: 68)
        #expect(font.fontProperty(named: "fontDescriptorFlags") == .integer(68))
    }

    @Test("Default fontProperty returns null for nil descriptor flags")
    func fontPropertyNilDescriptorFlags() {
        let font = Type1FontValidation()
        #expect(font.fontProperty(named: "fontDescriptorFlags") == .null)
    }

    @Test("Default fontProperty returns italic angle")
    func fontPropertyItalicAngle() {
        let font = Type1FontValidation(italicAngle: -12.0)
        #expect(font.fontProperty(named: "italicAngle") == .real(-12.0))
    }

    @Test("Default fontProperty returns null for nil italic angle")
    func fontPropertyNilItalicAngle() {
        let font = Type1FontValidation()
        #expect(font.fontProperty(named: "italicAngle") == .null)
    }

    @Test("Default fontProperty returns glyph count")
    func fontPropertyGlyphCount() {
        let font = Type1FontValidation(glyphCount: 228)
        #expect(font.fontProperty(named: "glyphCount") == .integer(228))
    }

    @Test("Default fontProperty returns nil for unknown property")
    func fontPropertyUnknown() {
        let font = Type1FontValidation()
        #expect(font.fontProperty(named: "nonexistent") == nil)
    }

    @Test("Default isSymbolic reads from descriptor flags")
    func isSymbolicFromFlags() {
        let symbolicFont = Type1FontValidation(fontDescriptorFlags: 4)
        #expect(symbolicFont.isSymbolic)

        let nonSymbolicFont = Type1FontValidation(fontDescriptorFlags: 32)
        #expect(!nonSymbolicFont.isSymbolic)

        let noFlagsFont = Type1FontValidation()
        #expect(!noFlagsFont.isSymbolic)
    }

    @Test("Default resourceType is font")
    func resourceTypeIsFont() {
        let font = Type1FontValidation()
        #expect(font.resourceType == .font)
    }

    @Test("Font property names includes all expected properties")
    func fontPropertyNamesComplete() {
        let font = Type1FontValidation()
        let names = font.fontPropertyNames
        #expect(names.contains("fontSubtype"))
        #expect(names.contains("baseFontName"))
        #expect(names.contains("encodingName"))
        #expect(names.contains("hasToUnicode"))
        #expect(names.contains("isEmbedded"))
        #expect(names.contains("hasFontDescriptor"))
        #expect(names.contains("fontDescriptorFlags"))
        #expect(names.contains("italicAngle"))
        #expect(names.contains("isSymbolic"))
        #expect(names.contains("hasConsistentWidths"))
        #expect(names.contains("glyphCount"))
        #expect(names.contains("hasCompleteUnicodeMappings"))
    }
}
