import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - CMapValidation Tests

@Suite("CMapValidation")
struct CMapValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let cmap = CMapValidation()
            #expect(cmap.cmapName == nil)
            #expect(cmap.cmapType == 0)
            #expect(cmap.cidRegistry == nil)
            #expect(cmap.cidOrdering == nil)
            #expect(cmap.cidSupplement == nil)
            #expect(cmap.writingMode == 0)
            #expect(cmap.codeSpaceRangeCount == 0)
            #expect(cmap.cidMappingCount == 0)
            #expect(cmap.notdefMappingCount == 0)
            #expect(cmap.isValid)
            #expect(cmap.dataSize == 0)
            #expect(!cmap.usesBaseCMap)
            #expect(cmap.baseCMapName == nil)
        }

        @Test("Full initialization")
        func fullInit() {
            let cmap = CMapValidation(
                cmapName: "UniJIS-UCS2-H",
                cmapType: 1,
                cidRegistry: "Adobe",
                cidOrdering: "Japan1",
                cidSupplement: 6,
                writingMode: 0,
                codeSpaceRangeCount: 2,
                cidMappingCount: 14099,
                notdefMappingCount: 1,
                isValid: true,
                dataSize: 262144,
                usesBaseCMap: true,
                baseCMapName: "UniJIS-UCS2-H-Base"
            )

            #expect(cmap.cmapName == "UniJIS-UCS2-H")
            #expect(cmap.cmapType == 1)
            #expect(cmap.cidRegistry == "Adobe")
            #expect(cmap.cidOrdering == "Japan1")
            #expect(cmap.cidSupplement == 6)
            #expect(cmap.writingMode == 0)
            #expect(cmap.codeSpaceRangeCount == 2)
            #expect(cmap.cidMappingCount == 14099)
            #expect(cmap.notdefMappingCount == 1)
            #expect(cmap.isValid)
            #expect(cmap.dataSize == 262144)
            #expect(cmap.usesBaseCMap)
            #expect(cmap.baseCMapName == "UniJIS-UCS2-H-Base")
        }

        @Test("Object type is CMap")
        func objectType() {
            let cmap = CMapValidation()
            #expect(cmap.objectType == "CMap")
        }

        @Test("Default context uses CMap name")
        func defaultContext() {
            let cmap = CMapValidation(cmapName: "Identity-H")
            #expect(cmap.validationContext.location == "CMap")
            #expect(cmap.validationContext.role == "Identity-H")
        }

        @Test("Custom context is preserved")
        func customContext() {
            let ctx = ObjectContext(pageNumber: 1, location: "Custom")
            let cmap = CMapValidation(context: ctx, cmapName: "Test")
            #expect(cmap.validationContext.pageNumber == 1)
        }
    }

    // MARK: - CID System Info

    @Suite("CID System Info")
    struct CIDSystemInfoTests {

        @Test("hasCIDSystemInfo when all fields present")
        func allPresent() {
            let cmap = CMapValidation(
                cidRegistry: "Adobe",
                cidOrdering: "Identity",
                cidSupplement: 0
            )
            #expect(cmap.hasCIDSystemInfo)
        }

        @Test("hasCIDSystemInfo false when fields missing")
        func fieldsMissing() {
            let cmap1 = CMapValidation(cidRegistry: "Adobe")
            #expect(!cmap1.hasCIDSystemInfo)

            let cmap2 = CMapValidation(cidOrdering: "Identity")
            #expect(!cmap2.hasCIDSystemInfo)

            let cmap3 = CMapValidation(cidSupplement: 0)
            #expect(!cmap3.hasCIDSystemInfo)
        }

        @Test("cidSystemInfoString format")
        func systemInfoString() {
            let cmap = CMapValidation(
                cidRegistry: "Adobe",
                cidOrdering: "GB1",
                cidSupplement: 5
            )
            #expect(cmap.cidSystemInfoString == "Adobe-GB1-5")
        }

        @Test("cidSystemInfoString nil when fields missing")
        func systemInfoStringNil() {
            let cmap = CMapValidation()
            #expect(cmap.cidSystemInfoString == nil)
        }
    }

    // MARK: - Writing Mode

    @Suite("Writing Mode")
    struct WritingModeTests {

        @Test("isHorizontal for mode 0")
        func horizontal() {
            let cmap = CMapValidation(writingMode: 0)
            #expect(cmap.isHorizontal)
            #expect(!cmap.isVertical)
        }

        @Test("isVertical for mode 1")
        func vertical() {
            let cmap = CMapValidation(writingMode: 1)
            #expect(!cmap.isHorizontal)
            #expect(cmap.isVertical)
        }

        @Test("Neither horizontal nor vertical for other modes")
        func otherMode() {
            let cmap = CMapValidation(writingMode: 2)
            #expect(!cmap.isHorizontal)
            #expect(!cmap.isVertical)
        }
    }

    // MARK: - Computed Properties

    @Suite("Computed Properties")
    struct ComputedPropertyTests {

        @Test("hasMappings when mappings present")
        func hasMappings() {
            let cmap = CMapValidation(cidMappingCount: 100)
            #expect(cmap.hasMappings)
        }

        @Test("hasMappings false when no mappings")
        func noMappings() {
            let cmap = CMapValidation(cidMappingCount: 0)
            #expect(!cmap.hasMappings)
        }

        @Test("hasCodeSpaceRanges when ranges present")
        func hasCodeSpaceRanges() {
            let cmap = CMapValidation(codeSpaceRangeCount: 1)
            #expect(cmap.hasCodeSpaceRanges)
        }

        @Test("hasCodeSpaceRanges false when no ranges")
        func noCodeSpaceRanges() {
            let cmap = CMapValidation(codeSpaceRangeCount: 0)
            #expect(!cmap.hasCodeSpaceRanges)
        }

        @Test("hasData with non-zero size")
        func hasData() {
            let cmap = CMapValidation(dataSize: 2048)
            #expect(cmap.hasData)
        }

        @Test("hasData false with zero size")
        func noData() {
            let cmap = CMapValidation(dataSize: 0)
            #expect(!cmap.hasData)
        }

        @Test("hasBaseCMap when base is set")
        func hasBaseCMap() {
            let cmap = CMapValidation(usesBaseCMap: true, baseCMapName: "BaseCMap")
            #expect(cmap.hasBaseCMap)
        }

        @Test("hasBaseCMap false when no base name")
        func noBaseCMapName() {
            let cmap = CMapValidation(usesBaseCMap: true, baseCMapName: nil)
            #expect(!cmap.hasBaseCMap)
        }

        @Test("hasBaseCMap false when not using base")
        func notUsingBase() {
            let cmap = CMapValidation(usesBaseCMap: false, baseCMapName: "BaseCMap")
            #expect(!cmap.hasBaseCMap)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names are complete")
        func propertyNames() {
            let cmap = CMapValidation()
            let names = cmap.propertyNames
            #expect(names.contains("cmapName"))
            #expect(names.contains("cmapType"))
            #expect(names.contains("cidRegistry"))
            #expect(names.contains("cidOrdering"))
            #expect(names.contains("cidSupplement"))
            #expect(names.contains("cidSystemInfoString"))
            #expect(names.contains("hasCIDSystemInfo"))
            #expect(names.contains("writingMode"))
            #expect(names.contains("isHorizontal"))
            #expect(names.contains("isVertical"))
            #expect(names.contains("codeSpaceRangeCount"))
            #expect(names.contains("cidMappingCount"))
            #expect(names.contains("notdefMappingCount"))
            #expect(names.contains("isValid"))
            #expect(names.contains("dataSize"))
            #expect(names.contains("hasData"))
            #expect(names.contains("hasMappings"))
            #expect(names.contains("hasCodeSpaceRanges"))
            #expect(names.contains("usesBaseCMap"))
            #expect(names.contains("baseCMapName"))
            #expect(names.contains("hasBaseCMap"))
        }

        @Test("Property access for string values")
        func stringProperties() {
            let cmap = CMapValidation(
                cmapName: "Identity-H",
                cidRegistry: "Adobe",
                cidOrdering: "Identity",
                cidSupplement: 0,
                usesBaseCMap: true,
                baseCMapName: "Base"
            )
            #expect(cmap.property(named: "cmapName") == .string("Identity-H"))
            #expect(cmap.property(named: "cidRegistry") == .string("Adobe"))
            #expect(cmap.property(named: "cidOrdering") == .string("Identity"))
            #expect(cmap.property(named: "cidSystemInfoString") == .string("Adobe-Identity-0"))
            #expect(cmap.property(named: "baseCMapName") == .string("Base"))
        }

        @Test("Property access for null string values")
        func nullStringProperties() {
            let cmap = CMapValidation()
            #expect(cmap.property(named: "cmapName") == .null)
            #expect(cmap.property(named: "cidRegistry") == .null)
            #expect(cmap.property(named: "cidOrdering") == .null)
            #expect(cmap.property(named: "cidSupplement") == .null)
            #expect(cmap.property(named: "cidSystemInfoString") == .null)
            #expect(cmap.property(named: "baseCMapName") == .null)
        }

        @Test("Property access for integer values")
        func integerProperties() {
            let cmap = CMapValidation(
                cmapType: 1,
                cidSupplement: 6,
                writingMode: 1,
                codeSpaceRangeCount: 3,
                cidMappingCount: 5000,
                notdefMappingCount: 2,
                dataSize: 8192
            )
            #expect(cmap.property(named: "cmapType") == .integer(1))
            #expect(cmap.property(named: "cidSupplement") == .integer(6))
            #expect(cmap.property(named: "writingMode") == .integer(1))
            #expect(cmap.property(named: "codeSpaceRangeCount") == .integer(3))
            #expect(cmap.property(named: "cidMappingCount") == .integer(5000))
            #expect(cmap.property(named: "notdefMappingCount") == .integer(2))
            #expect(cmap.property(named: "dataSize") == .integer(8192))
        }

        @Test("Property access for boolean values")
        func booleanProperties() {
            let cmap = CMapValidation(
                cidRegistry: "Adobe",
                cidOrdering: "Identity",
                cidSupplement: 0,
                writingMode: 0,
                codeSpaceRangeCount: 1,
                cidMappingCount: 100,
                isValid: true,
                dataSize: 1024,
                usesBaseCMap: true,
                baseCMapName: "Base"
            )
            #expect(cmap.property(named: "hasCIDSystemInfo") == .boolean(true))
            #expect(cmap.property(named: "isHorizontal") == .boolean(true))
            #expect(cmap.property(named: "isVertical") == .boolean(false))
            #expect(cmap.property(named: "isValid") == .boolean(true))
            #expect(cmap.property(named: "hasData") == .boolean(true))
            #expect(cmap.property(named: "hasMappings") == .boolean(true))
            #expect(cmap.property(named: "hasCodeSpaceRanges") == .boolean(true))
            #expect(cmap.property(named: "usesBaseCMap") == .boolean(true))
            #expect(cmap.property(named: "hasBaseCMap") == .boolean(true))
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let cmap = CMapValidation()
            #expect(cmap.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let c1 = CMapValidation(id: id, cmapName: "A")
            let c2 = CMapValidation(id: id, cmapName: "B")
            #expect(c1 == c2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let c1 = CMapValidation(cmapName: "A")
            let c2 = CMapValidation(cmapName: "A")
            #expect(c1 != c2)
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("minimal factory")
        func minimal() {
            let cmap = CMapValidation.minimal(name: "Identity-V", writingMode: 1)
            #expect(cmap.cmapName == "Identity-V")
            #expect(cmap.writingMode == 1)
            #expect(cmap.isValid)
        }

        @Test("minimal factory with defaults")
        func minimalDefaults() {
            let cmap = CMapValidation.minimal()
            #expect(cmap.cmapName == "Identity-H")
            #expect(cmap.writingMode == 0)
        }

        @Test("embedded factory")
        func embedded() {
            let cmap = CMapValidation.embedded(
                name: "CustomCMap",
                registry: "Adobe",
                ordering: "Japan1",
                supplement: 6,
                mappingCount: 14000
            )
            #expect(cmap.cmapName == "CustomCMap")
            #expect(cmap.cidRegistry == "Adobe")
            #expect(cmap.cidOrdering == "Japan1")
            #expect(cmap.cidSupplement == 6)
            #expect(cmap.cidMappingCount == 14000)
            #expect(cmap.codeSpaceRangeCount == 1)
            #expect(cmap.dataSize == 2048)
            #expect(cmap.isValid)
        }

        @Test("embedded factory with defaults")
        func embeddedDefaults() {
            let cmap = CMapValidation.embedded()
            #expect(cmap.cmapName == "CustomCMap")
            #expect(cmap.cidRegistry == "Adobe")
            #expect(cmap.cidOrdering == "Identity")
            #expect(cmap.cidSupplement == 0)
            #expect(cmap.cidMappingCount == 100)
        }
    }
}
