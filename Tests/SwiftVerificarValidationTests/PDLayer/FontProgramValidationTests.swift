import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - FontProgramValidation Tests

@Suite("FontProgramValidation")
struct FontProgramValidationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization")
        func defaultInit() {
            let program = FontProgramValidation()
            #expect(program.programType == .type1)
            #expect(program.dataSize == 0)
            #expect(program.glyphCount == 0)
            #expect(program.isValid)
            #expect(program.hasWidthInfo)
            #expect(program.widthMismatchCount == 0)
            #expect(program.hasRequiredTables)
            #expect(program.missingTables.isEmpty)
            #expect(program.hasValidCFFStructure)
            #expect(!program.hasCIDMappings)
            #expect(program.cidMappingCount == 0)
            #expect(!program.isSubset)
            #expect(program.subsetPrefix == nil)
        }

        @Test("Full initialization")
        func fullInit() {
            let program = FontProgramValidation(
                programType: .trueType,
                dataSize: 65536,
                glyphCount: 4514,
                isValid: true,
                hasWidthInfo: true,
                widthMismatchCount: 2,
                hasRequiredTables: false,
                missingTables: ["post"],
                hasValidCFFStructure: true,
                hasCIDMappings: false,
                cidMappingCount: 0,
                isSubset: true,
                subsetPrefix: "ABCDEF+"
            )

            #expect(program.programType == .trueType)
            #expect(program.dataSize == 65536)
            #expect(program.glyphCount == 4514)
            #expect(program.isValid)
            #expect(program.widthMismatchCount == 2)
            #expect(!program.hasRequiredTables)
            #expect(program.missingTables == ["post"])
            #expect(program.isSubset)
            #expect(program.subsetPrefix == "ABCDEF+")
        }

        @Test("Object type is FontProgram")
        func objectType() {
            let program = FontProgramValidation()
            #expect(program.objectType == "FontProgram")
        }

        @Test("Default context uses program type")
        func defaultContext() {
            let program = FontProgramValidation(programType: .trueType)
            #expect(program.validationContext.location == "FontProgram")
            #expect(program.validationContext.role == "TrueType")
        }

        @Test("Custom context is preserved")
        func customContext() {
            let ctx = ObjectContext(pageNumber: 3, location: "Custom")
            let program = FontProgramValidation(context: ctx)
            #expect(program.validationContext.pageNumber == 3)
        }
    }

    // MARK: - Computed Properties

    @Suite("Computed Properties")
    struct ComputedPropertyTests {

        @Test("hasConsistentWidths with zero mismatches")
        func consistentWidths() {
            let program = FontProgramValidation(widthMismatchCount: 0)
            #expect(program.hasConsistentWidths)
        }

        @Test("hasConsistentWidths false with mismatches")
        func inconsistentWidths() {
            let program = FontProgramValidation(widthMismatchCount: 5)
            #expect(!program.hasConsistentWidths)
        }

        @Test("hasData with non-zero size")
        func hasData() {
            let program = FontProgramValidation(dataSize: 1024)
            #expect(program.hasData)
        }

        @Test("hasData false with zero size")
        func noData() {
            let program = FontProgramValidation(dataSize: 0)
            #expect(!program.hasData)
        }

        @Test("hasMissingTables when tables are missing")
        func hasMissingTables() {
            let program = FontProgramValidation(missingTables: ["cmap", "post"])
            #expect(program.hasMissingTables)
        }

        @Test("hasMissingTables false when no missing tables")
        func noMissingTables() {
            let program = FontProgramValidation(missingTables: [])
            #expect(!program.hasMissingTables)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccessTests {

        @Test("Property names are complete")
        func propertyNames() {
            let program = FontProgramValidation()
            let names = program.propertyNames
            #expect(names.contains("programType"))
            #expect(names.contains("dataSize"))
            #expect(names.contains("glyphCount"))
            #expect(names.contains("isValid"))
            #expect(names.contains("hasWidthInfo"))
            #expect(names.contains("widthMismatchCount"))
            #expect(names.contains("hasConsistentWidths"))
            #expect(names.contains("hasRequiredTables"))
            #expect(names.contains("missingTableCount"))
            #expect(names.contains("hasValidCFFStructure"))
            #expect(names.contains("hasCIDMappings"))
            #expect(names.contains("cidMappingCount"))
            #expect(names.contains("isSubset"))
            #expect(names.contains("subsetPrefix"))
            #expect(names.contains("hasData"))
            #expect(names.contains("hasMissingTables"))
        }

        @Test("Property access for string values")
        func stringProperties() {
            let program = FontProgramValidation(programType: .type1C, isSubset: true, subsetPrefix: "XYZABC+")
            #expect(program.property(named: "programType") == .string("Type1C"))
            #expect(program.property(named: "subsetPrefix") == .string("XYZABC+"))
        }

        @Test("Property access for integer values")
        func integerProperties() {
            let program = FontProgramValidation(
                dataSize: 4096,
                glyphCount: 256,
                widthMismatchCount: 3,
                missingTables: ["cmap"],
                cidMappingCount: 50
            )
            #expect(program.property(named: "dataSize") == .integer(4096))
            #expect(program.property(named: "glyphCount") == .integer(256))
            #expect(program.property(named: "widthMismatchCount") == .integer(3))
            #expect(program.property(named: "missingTableCount") == .integer(1))
            #expect(program.property(named: "cidMappingCount") == .integer(50))
        }

        @Test("Property access for boolean values")
        func booleanProperties() {
            let program = FontProgramValidation(
                dataSize: 1024,
                isValid: true,
                hasWidthInfo: true,
                widthMismatchCount: 0,
                hasRequiredTables: true,
                hasValidCFFStructure: true,
                hasCIDMappings: true,
                isSubset: false
            )
            #expect(program.property(named: "isValid") == .boolean(true))
            #expect(program.property(named: "hasWidthInfo") == .boolean(true))
            #expect(program.property(named: "hasConsistentWidths") == .boolean(true))
            #expect(program.property(named: "hasRequiredTables") == .boolean(true))
            #expect(program.property(named: "hasValidCFFStructure") == .boolean(true))
            #expect(program.property(named: "hasCIDMappings") == .boolean(true))
            #expect(program.property(named: "isSubset") == .boolean(false))
            #expect(program.property(named: "hasData") == .boolean(true))
            #expect(program.property(named: "hasMissingTables") == .boolean(false))
        }

        @Test("Property access for null subset prefix")
        func nullSubsetPrefix() {
            let program = FontProgramValidation()
            #expect(program.property(named: "subsetPrefix") == .null)
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let program = FontProgramValidation()
            #expect(program.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let p1 = FontProgramValidation(id: id, programType: .type1)
            let p2 = FontProgramValidation(id: id, programType: .trueType)
            #expect(p1 == p2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let p1 = FontProgramValidation(programType: .type1)
            let p2 = FontProgramValidation(programType: .type1)
            #expect(p1 != p2)
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("type1Program factory")
        func type1Program() {
            let program = FontProgramValidation.type1Program(dataSize: 2048, glyphCount: 315)
            #expect(program.programType == .type1)
            #expect(program.dataSize == 2048)
            #expect(program.glyphCount == 315)
        }

        @Test("type1Program default values")
        func type1ProgramDefaults() {
            let program = FontProgramValidation.type1Program()
            #expect(program.programType == .type1)
            #expect(program.dataSize == 1024)
            #expect(program.glyphCount == 228)
        }

        @Test("trueTypeProgram factory")
        func trueTypeProgram() {
            let program = FontProgramValidation.trueTypeProgram(
                dataSize: 65536,
                glyphCount: 4514,
                hasRequiredTables: false
            )
            #expect(program.programType == .trueType)
            #expect(program.dataSize == 65536)
            #expect(program.glyphCount == 4514)
            #expect(!program.hasRequiredTables)
        }

        @Test("trueTypeProgram default values")
        func trueTypeProgramDefaults() {
            let program = FontProgramValidation.trueTypeProgram()
            #expect(program.programType == .trueType)
            #expect(program.dataSize == 4096)
            #expect(program.glyphCount == 256)
            #expect(program.hasRequiredTables)
        }

        @Test("cffProgram factory non-CID")
        func cffProgramNonCID() {
            let program = FontProgramValidation.cffProgram(dataSize: 3072, glyphCount: 200)
            #expect(program.programType == .type1C)
            #expect(program.dataSize == 3072)
            #expect(program.glyphCount == 200)
            #expect(program.hasValidCFFStructure)
            #expect(!program.hasCIDMappings)
            #expect(program.cidMappingCount == 0)
        }

        @Test("cffProgram factory CID")
        func cffProgramCID() {
            let program = FontProgramValidation.cffProgram(dataSize: 8192, glyphCount: 15000, isCID: true)
            #expect(program.programType == .cidFontType0C)
            #expect(program.glyphCount == 15000)
            #expect(program.hasCIDMappings)
            #expect(program.cidMappingCount == 15000)
        }

        @Test("cffProgram default values")
        func cffProgramDefaults() {
            let program = FontProgramValidation.cffProgram()
            #expect(program.programType == .type1C)
            #expect(program.dataSize == 2048)
            #expect(program.glyphCount == 228)
        }
    }
}

// MARK: - FontProgramType Tests

@Suite("FontProgramType")
struct FontProgramTypeTests {

    @Test("All types have correct raw values")
    func rawValues() {
        #expect(FontProgramType.type1.rawValue == "Type1")
        #expect(FontProgramType.trueType.rawValue == "TrueType")
        #expect(FontProgramType.type1C.rawValue == "Type1C")
        #expect(FontProgramType.cidFontType0C.rawValue == "CIDFontType0C")
        #expect(FontProgramType.openType.rawValue == "OpenType")
        #expect(FontProgramType.unknown.rawValue == "Unknown")
    }

    @Test("CaseIterable includes all types")
    func caseIterable() {
        #expect(FontProgramType.allCases.count == 6)
    }

    @Test("fromSubtype creates correct type")
    func fromSubtype() {
        #expect(FontProgramType(fromSubtype: "Type1C") == .type1C)
        #expect(FontProgramType(fromSubtype: "CIDFontType0C") == .cidFontType0C)
        #expect(FontProgramType(fromSubtype: "OpenType") == .openType)
        #expect(FontProgramType(fromSubtype: nil) == .unknown)
        #expect(FontProgramType(fromSubtype: "Invalid") == .unknown)
    }

    @Test("isCFF for CFF types")
    func isCFF() {
        #expect(FontProgramType.type1C.isCFF)
        #expect(FontProgramType.cidFontType0C.isCFF)
        #expect(!FontProgramType.type1.isCFF)
        #expect(!FontProgramType.trueType.isCFF)
        #expect(!FontProgramType.openType.isCFF)
    }

    @Test("isTrueTypeOutlines for TrueType")
    func isTrueTypeOutlines() {
        #expect(FontProgramType.trueType.isTrueTypeOutlines)
        #expect(!FontProgramType.type1.isTrueTypeOutlines)
        #expect(!FontProgramType.type1C.isTrueTypeOutlines)
        #expect(!FontProgramType.openType.isTrueTypeOutlines)
    }

    @Test("isOpenType for OpenType")
    func isOpenType() {
        #expect(FontProgramType.openType.isOpenType)
        #expect(!FontProgramType.trueType.isOpenType)
        #expect(!FontProgramType.type1.isOpenType)
    }
}
