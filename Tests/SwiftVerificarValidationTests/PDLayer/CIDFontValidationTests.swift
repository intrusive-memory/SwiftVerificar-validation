import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - CIDFontValidation Tests

@Suite("CIDFontValidation")
struct CIDFontValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let font = CIDFontValidation()
            #expect(font.fontSubtype == .cidFontType0)
            #expect(font.baseFontName == nil)
            #expect(font.encodingName == nil)
            #expect(!font.hasToUnicode)
            #expect(!font.isEmbedded)
            #expect(font.cidRegistry == nil)
            #expect(font.cidOrdering == nil)
            #expect(font.cidSupplement == nil)
            #expect(font.defaultWidth == 1000.0)
            #expect(font.widthEntryCount == 0)
            #expect(!font.hasCIDToGIDMap)
            #expect(!font.isCIDToGIDMapIdentity)
        }

        @Test("Full initialization CIDFontType0")
        func fullInitType0() {
            let font = CIDFontValidation(
                fontSubtype: .cidFontType0,
                baseFontName: "KozMinPro-Regular",
                isEmbedded: true,
                hasFontDescriptor: true,
                fontDescriptorFlags: 4,
                glyphCount: 15444,
                cidRegistry: "Adobe",
                cidOrdering: "Japan1",
                cidSupplement: 6,
                defaultWidth: 1000.0,
                widthEntryCount: 500
            )

            #expect(font.fontSubtype == .cidFontType0)
            #expect(font.baseFontName == "KozMinPro-Regular")
            #expect(font.cidRegistry == "Adobe")
            #expect(font.cidOrdering == "Japan1")
            #expect(font.cidSupplement == 6)
            #expect(font.glyphCount == 15444)
            #expect(font.widthEntryCount == 500)
        }

        @Test("Full initialization CIDFontType2")
        func fullInitType2() {
            let font = CIDFontValidation(
                fontSubtype: .cidFontType2,
                baseFontName: "MSMincho",
                isEmbedded: true,
                cidRegistry: "Adobe",
                cidOrdering: "Identity",
                cidSupplement: 0,
                hasCIDToGIDMap: true,
                isCIDToGIDMapIdentity: true
            )

            #expect(font.fontSubtype == .cidFontType2)
            #expect(font.hasCIDToGIDMap)
            #expect(font.isCIDToGIDMapIdentity)
        }

        @Test("Object type is PDCIDFont")
        func objectType() {
            let font = CIDFontValidation()
            #expect(font.objectType == "PDCIDFont")
        }

        @Test("Default context uses font name")
        func defaultContext() {
            let font = CIDFontValidation(baseFontName: "TestCID")
            #expect(font.validationContext.location == "Font")
            #expect(font.validationContext.role == "TestCID")
        }
    }

    // MARK: - CID System Info

    @Suite("CID System Info")
    struct CIDSystemInfoTests {

        @Test("hasCIDSystemInfo when all fields present")
        func allFieldsPresent() {
            let font = CIDFontValidation(
                cidRegistry: "Adobe",
                cidOrdering: "Japan1",
                cidSupplement: 6
            )
            #expect(font.hasCIDSystemInfo)
        }

        @Test("hasCIDSystemInfo false when registry nil")
        func nilRegistry() {
            let font = CIDFontValidation(
                cidOrdering: "Japan1",
                cidSupplement: 6
            )
            #expect(!font.hasCIDSystemInfo)
        }

        @Test("hasCIDSystemInfo false when ordering nil")
        func nilOrdering() {
            let font = CIDFontValidation(
                cidRegistry: "Adobe",
                cidSupplement: 6
            )
            #expect(!font.hasCIDSystemInfo)
        }

        @Test("hasCIDSystemInfo false when supplement nil")
        func nilSupplement() {
            let font = CIDFontValidation(
                cidRegistry: "Adobe",
                cidOrdering: "Japan1"
            )
            #expect(!font.hasCIDSystemInfo)
        }

        @Test("cidSystemInfoString when all fields present")
        func systemInfoString() {
            let font = CIDFontValidation(
                cidRegistry: "Adobe",
                cidOrdering: "Identity",
                cidSupplement: 0
            )
            #expect(font.cidSystemInfoString == "Adobe-Identity-0")
        }

        @Test("cidSystemInfoString nil when fields missing")
        func systemInfoStringNil() {
            let font = CIDFontValidation(cidRegistry: "Adobe")
            #expect(font.cidSystemInfoString == nil)
        }
    }

    // MARK: - CIDFont Type Properties

    @Suite("CIDFont Type")
    struct TypeTests {

        @Test("isCIDFontType0 for CIDFontType0")
        func cidType0() {
            let font = CIDFontValidation(fontSubtype: .cidFontType0)
            #expect(font.isCIDFontType0)
            #expect(!font.isCIDFontType2)
        }

        @Test("isCIDFontType2 for CIDFontType2")
        func cidType2() {
            let font = CIDFontValidation(fontSubtype: .cidFontType2)
            #expect(!font.isCIDFontType0)
            #expect(font.isCIDFontType2)
        }

        @Test("CIDToGIDMap properties")
        func cidToGIDMap() {
            let withMap = CIDFontValidation(hasCIDToGIDMap: true, isCIDToGIDMapIdentity: false)
            #expect(withMap.hasCIDToGIDMap)
            #expect(!withMap.isCIDToGIDMapIdentity)

            let withIdentity = CIDFontValidation(hasCIDToGIDMap: true, isCIDToGIDMapIdentity: true)
            #expect(withIdentity.hasCIDToGIDMap)
            #expect(withIdentity.isCIDToGIDMapIdentity)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names include CID specific properties")
        func propertyNames() {
            let font = CIDFontValidation()
            let names = font.propertyNames
            #expect(names.contains("cidRegistry"))
            #expect(names.contains("cidOrdering"))
            #expect(names.contains("cidSupplement"))
            #expect(names.contains("cidSystemInfoString"))
            #expect(names.contains("hasCIDSystemInfo"))
            #expect(names.contains("defaultWidth"))
            #expect(names.contains("widthEntryCount"))
            #expect(names.contains("hasCIDToGIDMap"))
            #expect(names.contains("isCIDToGIDMapIdentity"))
            #expect(names.contains("isCIDFontType0"))
            #expect(names.contains("isCIDFontType2"))
        }

        @Test("Property access for CID system info")
        func cidSystemInfo() {
            let font = CIDFontValidation(
                cidRegistry: "Adobe",
                cidOrdering: "Japan1",
                cidSupplement: 6
            )
            #expect(font.property(named: "cidRegistry") == .string("Adobe"))
            #expect(font.property(named: "cidOrdering") == .string("Japan1"))
            #expect(font.property(named: "cidSupplement") == .integer(6))
            #expect(font.property(named: "cidSystemInfoString") == .string("Adobe-Japan1-6"))
            #expect(font.property(named: "hasCIDSystemInfo") == .boolean(true))
        }

        @Test("Property access for null CID system info")
        func nullCIDSystemInfo() {
            let font = CIDFontValidation()
            #expect(font.property(named: "cidRegistry") == .null)
            #expect(font.property(named: "cidOrdering") == .null)
            #expect(font.property(named: "cidSupplement") == .null)
            #expect(font.property(named: "cidSystemInfoString") == .null)
            #expect(font.property(named: "hasCIDSystemInfo") == .boolean(false))
        }

        @Test("Property access for width properties")
        func widthProperties() {
            let font = CIDFontValidation(defaultWidth: 500.0, widthEntryCount: 100)
            #expect(font.property(named: "defaultWidth") == .real(500.0))
            #expect(font.property(named: "widthEntryCount") == .integer(100))
        }

        @Test("Property access for CIDToGIDMap")
        func cidToGIDMapProperties() {
            let font = CIDFontValidation(hasCIDToGIDMap: true, isCIDToGIDMapIdentity: true)
            #expect(font.property(named: "hasCIDToGIDMap") == .boolean(true))
            #expect(font.property(named: "isCIDToGIDMapIdentity") == .boolean(true))
        }

        @Test("Property access for type booleans")
        func typeBooleans() {
            let t0 = CIDFontValidation(fontSubtype: .cidFontType0)
            #expect(t0.property(named: "isCIDFontType0") == .boolean(true))
            #expect(t0.property(named: "isCIDFontType2") == .boolean(false))
        }

        @Test("Falls through to font properties")
        func fontFallthrough() {
            let font = CIDFontValidation(baseFontName: "TestCID", isEmbedded: true)
            #expect(font.property(named: "fontSubtype") == .string("CIDFontType0"))
            #expect(font.property(named: "baseFontName") == .string("TestCID"))
            #expect(font.property(named: "isEmbedded") == .boolean(true))
        }

        @Test("Falls through to resource properties")
        func resourceFallthrough() {
            let font = CIDFontValidation(resourceName: ASAtom("F4"))
            #expect(font.property(named: "resourceName") == .name("F4"))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let font = CIDFontValidation()
            #expect(font.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let f1 = CIDFontValidation(id: id, baseFontName: "A")
            let f2 = CIDFontValidation(id: id, baseFontName: "B")
            #expect(f1 == f2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let f1 = CIDFontValidation(baseFontName: "A")
            let f2 = CIDFontValidation(baseFontName: "A")
            #expect(f1 != f2)
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("minimal factory creates basic CIDFont")
        func minimal() {
            let font = CIDFontValidation.minimal(
                name: "MyCIDFont",
                subtype: .cidFontType2,
                registry: "Adobe",
                ordering: "Japan1"
            )
            #expect(font.baseFontName == "MyCIDFont")
            #expect(font.fontSubtype == .cidFontType2)
            #expect(font.cidRegistry == "Adobe")
            #expect(font.cidOrdering == "Japan1")
            #expect(font.cidSupplement == 0)
        }

        @Test("minimal factory with defaults")
        func minimalDefaults() {
            let font = CIDFontValidation.minimal()
            #expect(font.baseFontName == "TestCIDFont")
            #expect(font.fontSubtype == .cidFontType0)
            #expect(font.cidRegistry == "Adobe")
            #expect(font.cidOrdering == "Identity")
        }
    }
}
