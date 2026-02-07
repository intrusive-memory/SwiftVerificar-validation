import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - Type0FontValidation Tests

@Suite("Type0FontValidation")
struct Type0FontValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let font = Type0FontValidation()
            #expect(font.fontSubtype == .type0)
            #expect(font.baseFontName == nil)
            #expect(font.encodingName == nil)
            #expect(!font.hasToUnicode)
            #expect(!font.isEmbedded)
            #expect(!font.hasFontDescriptor)
            #expect(font.fontDescriptorFlags == nil)
            #expect(font.italicAngle == nil)
            #expect(font.fontBBox == nil)
            #expect(font.hasConsistentWidths)
            #expect(font.fontProgram == nil)
            #expect(font.glyphCount == 0)
            #expect(font.hasCompleteUnicodeMappings)
            #expect(font.descendantFont == nil)
            #expect(font.cmap == nil)
            #expect(font.resourceType == .font)
        }

        @Test("Full initialization")
        func fullInit() {
            let cidFont = CIDFontValidation.minimal()
            let cmap = CMapValidation.minimal()
            let program = FontProgramValidation.cffProgram()

            let font = Type0FontValidation(
                baseFontName: "KozMinPro-Regular",
                encodingName: "Identity-H",
                hasToUnicode: true,
                isEmbedded: true,
                hasFontDescriptor: true,
                fontDescriptorFlags: 4,
                italicAngle: 0.0,
                fontBBox: [-100.0, -200.0, 1000.0, 900.0],
                glyphCount: 15000,
                descendantFont: cidFont,
                cmap: cmap
            )

            #expect(font.fontSubtype == .type0)
            #expect(font.baseFontName == "KozMinPro-Regular")
            #expect(font.encodingName == "Identity-H")
            #expect(font.hasToUnicode)
            #expect(font.isEmbedded)
            #expect(font.hasFontDescriptor)
            #expect(font.fontDescriptorFlags == 4)
            #expect(font.italicAngle == 0.0)
            #expect(font.fontBBox?.count == 4)
            #expect(font.glyphCount == 15000)
            #expect(font.hasDescendantFont)
            #expect(font.cmap != nil)
        }

        @Test("Object type is PDType0Font")
        func objectType() {
            let font = Type0FontValidation()
            #expect(font.objectType == "PDType0Font")
        }

        @Test("Default context uses font name")
        func defaultContext() {
            let font = Type0FontValidation(baseFontName: "TestFont")
            #expect(font.validationContext.location == "Font")
            #expect(font.validationContext.role == "TestFont")
        }

        @Test("Custom context is preserved")
        func customContext() {
            let ctx = ObjectContext(pageNumber: 2, location: "Custom")
            let font = Type0FontValidation(context: ctx)
            #expect(font.validationContext.pageNumber == 2)
        }
    }

    // MARK: - Type 0 Specific Properties

    @Suite("Type 0 Specific Properties")
    struct Type0SpecificTests {

        @Test("isPredefinedCMap when no embedded CMap")
        func predefinedCMap() {
            let font = Type0FontValidation(encodingName: "Identity-H")
            #expect(font.isPredefinedCMap)
        }

        @Test("isPredefinedCMap false when embedded CMap present")
        func embeddedCMapPresent() {
            let cmap = CMapValidation.minimal()
            let font = Type0FontValidation(encodingName: "CustomCMap", cmap: cmap)
            #expect(!font.isPredefinedCMap)
        }

        @Test("isPredefinedCMap false when no encoding")
        func noCMap() {
            let font = Type0FontValidation()
            #expect(!font.isPredefinedCMap)
        }

        @Test("isIdentityCMap for Identity-H")
        func identityH() {
            let font = Type0FontValidation(encodingName: "Identity-H")
            #expect(font.isIdentityCMap)
        }

        @Test("isIdentityCMap for Identity-V")
        func identityV() {
            let font = Type0FontValidation(encodingName: "Identity-V")
            #expect(font.isIdentityCMap)
        }

        @Test("isIdentityCMap false for non-identity")
        func nonIdentity() {
            let font = Type0FontValidation(encodingName: "UniJIS-UCS2-H")
            #expect(!font.isIdentityCMap)
        }

        @Test("isIdentityCMap false when nil encoding")
        func nilEncoding() {
            let font = Type0FontValidation()
            #expect(!font.isIdentityCMap)
        }

        @Test("hasDescendantFont when descendant is set")
        func hasDescendant() {
            let cidFont = CIDFontValidation.minimal()
            let font = Type0FontValidation(descendantFont: cidFont)
            #expect(font.hasDescendantFont)
        }

        @Test("hasDescendantFont false when nil")
        func noDescendant() {
            let font = Type0FontValidation()
            #expect(!font.hasDescendantFont)
        }

        @Test("isVerticalWriting for -V suffix")
        func verticalWriting() {
            let font = Type0FontValidation(encodingName: "Identity-V")
            #expect(font.isVerticalWriting)
        }

        @Test("isVerticalWriting false for -H suffix")
        func horizontalWriting() {
            let font = Type0FontValidation(encodingName: "Identity-H")
            #expect(!font.isVerticalWriting)
        }

        @Test("isVerticalWriting false for nil encoding")
        func noEncodingWriting() {
            let font = Type0FontValidation()
            #expect(!font.isVerticalWriting)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include Type 0 specific properties")
        func propertyNames() {
            let font = Type0FontValidation()
            let names = font.propertyNames
            #expect(names.contains("hasDescendantFont"))
            #expect(names.contains("isPredefinedCMap"))
            #expect(names.contains("isIdentityCMap"))
            #expect(names.contains("isVerticalWriting"))
            #expect(names.contains("fontSubtype"))
            #expect(names.contains("baseFontName"))
        }

        @Test("Property access for Type 0 specific properties")
        func type0Properties() {
            let cidFont = CIDFontValidation.minimal()
            let font = Type0FontValidation(
                encodingName: "Identity-H",
                descendantFont: cidFont
            )
            #expect(font.property(named: "hasDescendantFont") == .boolean(true))
            #expect(font.property(named: "isPredefinedCMap") == .boolean(true))
            #expect(font.property(named: "isIdentityCMap") == .boolean(true))
            #expect(font.property(named: "isVerticalWriting") == .boolean(false))
        }

        @Test("Property access falls through to font properties")
        func fontPropertyFallthrough() {
            let font = Type0FontValidation(baseFontName: "TestFont", hasToUnicode: true)
            #expect(font.property(named: "fontSubtype") == .string("Type0"))
            #expect(font.property(named: "baseFontName") == .string("TestFont"))
            #expect(font.property(named: "hasToUnicode") == .boolean(true))
        }

        @Test("Property access falls through to resource properties")
        func resourcePropertyFallthrough() {
            let font = Type0FontValidation(resourceName: ASAtom("F1"))
            #expect(font.property(named: "resourceName") == .name("F1"))
            #expect(font.property(named: "resourceType") == .string("Font"))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let font = Type0FontValidation()
            #expect(font.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let f1 = Type0FontValidation(id: id, baseFontName: "Font1")
            let f2 = Type0FontValidation(id: id, baseFontName: "Font2")
            #expect(f1 == f2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let f1 = Type0FontValidation(baseFontName: "Font1")
            let f2 = Type0FontValidation(baseFontName: "Font1")
            #expect(f1 != f2)
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("minimal factory creates basic Type 0 font")
        func minimalFactory() {
            let font = Type0FontValidation.minimal(name: "TestComposite", encoding: "Identity-H")
            #expect(font.baseFontName == "TestComposite")
            #expect(font.encodingName == "Identity-H")
            #expect(font.fontSubtype == .type0)
        }

        @Test("minimal factory with defaults")
        func minimalDefaults() {
            let font = Type0FontValidation.minimal()
            #expect(font.baseFontName == "TestFont")
            #expect(font.encodingName == "Identity-H")
            #expect(!font.isEmbedded)
        }
    }
}
