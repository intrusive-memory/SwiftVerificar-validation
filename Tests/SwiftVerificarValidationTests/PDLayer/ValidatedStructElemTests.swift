import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - ValidatedStructElem Tests

@Suite("ValidatedStructElem")
struct ValidatedStructElemTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization with type name")
        func defaultInit() {
            let elem = ValidatedStructElem(structureTypeName: "P")
            #expect(elem.structureTypeName == "P")
            #expect(elem.structureType == .paragraph)
            #expect(elem.children.isEmpty)
            #expect(elem.childCount == 0)
            #expect(!elem.hasChildren)
            #expect(elem.altText == nil)
            #expect(elem.actualText == nil)
            #expect(elem.expansionText == nil)
            #expect(elem.language == nil)
            #expect(!elem.hasAltText)
            #expect(!elem.hasActualText)
            #expect(!elem.hasLanguage)
            #expect(elem.markedContentIDs.isEmpty)
            #expect(elem.pageNumber == nil)
            #expect(elem.attributes.isEmpty)
            #expect(!elem.hasAttributes)
            #expect(elem.classNames.isEmpty)
            #expect(!elem.hasClassNames)
            #expect(elem.revision == 0)
            #expect(elem.elementID == nil)
            #expect(!elem.hasElementID)
            #expect(elem.namespaceURI == nil)
            #expect(!elem.hasNamespace)
        }

        @Test("Full initialization sets all properties")
        func fullInit() {
            let elem = ValidatedStructElem(
                structureTypeName: "Figure",
                children: [ValidatedStructElem.paragraph()],
                altText: "A picture",
                actualText: "Image content",
                expansionText: "Fig.",
                language: "en-US",
                markedContentIDs: [1, 2, 3],
                pageNumber: 5,
                attributes: ["Placement": .name(ASAtom("Block"))],
                classNames: ["cls1"],
                revision: 2,
                elementID: "fig-01",
                namespaceURI: "http://example.com/ns"
            )

            #expect(elem.structureTypeName == "Figure")
            #expect(elem.structureType == .figure)
            #expect(elem.childCount == 1)
            #expect(elem.hasChildren)
            #expect(elem.altText == "A picture")
            #expect(elem.actualText == "Image content")
            #expect(elem.expansionText == "Fig.")
            #expect(elem.language == "en-US")
            #expect(elem.hasAltText)
            #expect(elem.hasActualText)
            #expect(elem.hasLanguage)
            #expect(elem.markedContentIDs == [1, 2, 3])
            #expect(elem.pageNumber == 5)
            #expect(elem.hasAttributes)
            #expect(elem.hasClassNames)
            #expect(elem.revision == 2)
            #expect(elem.elementID == "fig-01")
            #expect(elem.hasElementID)
            #expect(elem.namespaceURI == "http://example.com/ns")
            #expect(elem.hasNamespace)
        }

        @Test("Custom type resolves to nil for non-standard name")
        func customTypeResolution() {
            let elem = ValidatedStructElem(structureTypeName: "MyCustomType")
            #expect(elem.structureTypeName == "MyCustomType")
            #expect(elem.structureType == nil)
        }

        @Test("Explicit structureType overrides auto-resolution")
        func explicitType() {
            let elem = ValidatedStructElem(
                structureTypeName: "MyP",
                structureType: .paragraph
            )
            #expect(elem.structureTypeName == "MyP")
            #expect(elem.structureType == .paragraph)
        }

        @Test("Object type is PDStructElem")
        func objectType() {
            let elem = ValidatedStructElem(structureTypeName: "P")
            #expect(elem.objectType == "PDStructElem")
        }

        @Test("Default context uses structure element factory")
        func defaultContext() {
            let elem = ValidatedStructElem(structureTypeName: "H1")
            #expect(elem.validationContext.location == "StructureElement")
            #expect(elem.validationContext.role == "H1")
        }

        @Test("Custom context is preserved")
        func customContext() {
            let ctx = ObjectContext(pageNumber: 3, location: "Custom")
            let elem = ValidatedStructElem(
                context: ctx,
                structureTypeName: "P"
            )
            #expect(elem.validationContext.pageNumber == 3)
            #expect(elem.validationContext.location == "Custom")
        }
    }

    // MARK: - Accessibility Properties

    @Suite("Accessibility Properties")
    struct AccessibilityTests {

        @Test("hasAltText returns false for empty string")
        func emptyAltText() {
            let elem = ValidatedStructElem(structureTypeName: "Figure", altText: "")
            #expect(!elem.hasAltText)
        }

        @Test("hasActualText returns false for empty string")
        func emptyActualText() {
            let elem = ValidatedStructElem(structureTypeName: "P", actualText: "")
            #expect(!elem.hasActualText)
        }

        @Test("hasLanguage returns false for empty string")
        func emptyLanguage() {
            let elem = ValidatedStructElem(structureTypeName: "P", language: "")
            #expect(!elem.hasLanguage)
        }

        @Test("Figure without alt text is not accessible")
        func figureWithoutAlt() {
            let elem = ValidatedStructElem(structureTypeName: "Figure")
            #expect(elem.requiresAltText)
            #expect(!elem.isAccessible)
        }

        @Test("Figure with alt text is accessible")
        func figureWithAlt() {
            let elem = ValidatedStructElem(structureTypeName: "Figure", altText: "Description")
            #expect(elem.isAccessible)
        }

        @Test("Figure with actual text is accessible")
        func figureWithActualText() {
            let elem = ValidatedStructElem(structureTypeName: "Figure", actualText: "Text")
            #expect(elem.isAccessible)
        }

        @Test("Paragraph is always accessible (no alt text required)")
        func paragraphAlwaysAccessible() {
            let elem = ValidatedStructElem(structureTypeName: "P")
            #expect(elem.isAccessible)
        }
    }

    // MARK: - PDFObject Property Access

    @Suite("PDFObject Property Access")
    struct PropertyAccessTests {

        @Test("Property names are complete")
        func propertyNames() {
            let elem = ValidatedStructElem(structureTypeName: "P")
            let names = elem.propertyNames
            #expect(names.contains("structureTypeName"))
            #expect(names.contains("structureType"))
            #expect(names.contains("childCount"))
            #expect(names.contains("altText"))
            #expect(names.contains("actualText"))
            #expect(names.contains("language"))
            #expect(names.contains("hasAltText"))
            #expect(names.contains("revision"))
            #expect(names.contains("elementID"))
        }

        @Test("Property access for string values")
        func stringProperties() {
            let elem = ValidatedStructElem(
                structureTypeName: "P",
                altText: "Alt",
                actualText: "Actual",
                expansionText: "Exp",
                language: "en",
                elementID: "id-1",
                namespaceURI: "http://ns"
            )
            #expect(elem.property(named: "structureTypeName") == .string("P"))
            #expect(elem.property(named: "structureType") == .string("P"))
            #expect(elem.property(named: "altText") == .string("Alt"))
            #expect(elem.property(named: "actualText") == .string("Actual"))
            #expect(elem.property(named: "expansionText") == .string("Exp"))
            #expect(elem.property(named: "language") == .string("en"))
            #expect(elem.property(named: "elementID") == .string("id-1"))
            #expect(elem.property(named: "namespaceURI") == .string("http://ns"))
        }

        @Test("Property access for boolean values")
        func booleanProperties() {
            let elem = ValidatedStructElem(
                structureTypeName: "Figure",
                children: [ValidatedStructElem.paragraph()],
                altText: "Alt",
                language: "en"
            )
            #expect(elem.property(named: "hasChildren") == .boolean(true))
            #expect(elem.property(named: "hasAltText") == .boolean(true))
            #expect(elem.property(named: "hasActualText") == .boolean(false))
            #expect(elem.property(named: "hasLanguage") == .boolean(true))
        }

        @Test("Property access for integer values")
        func integerProperties() {
            let elem = ValidatedStructElem(
                structureTypeName: "P",
                children: [ValidatedStructElem.paragraph(), ValidatedStructElem.paragraph()],
                revision: 3
            )
            #expect(elem.property(named: "childCount") == .integer(2))
            #expect(elem.property(named: "revision") == .integer(3))
        }

        @Test("Property access for null values")
        func nullProperties() {
            let elem = ValidatedStructElem(structureTypeName: "P")
            #expect(elem.property(named: "altText") == .null)
            #expect(elem.property(named: "actualText") == .null)
            #expect(elem.property(named: "expansionText") == .null)
            #expect(elem.property(named: "language") == .null)
            #expect(elem.property(named: "pageNumber") == .null)
            #expect(elem.property(named: "elementID") == .null)
            #expect(elem.property(named: "namespaceURI") == .null)
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let elem = ValidatedStructElem(structureTypeName: "P")
            #expect(elem.property(named: "nonexistent") == nil)
        }

        @Test("markedContentIDs property returns comma-separated string")
        func markedContentIDs() {
            let elem = ValidatedStructElem(
                structureTypeName: "P",
                markedContentIDs: [1, 2, 3]
            )
            #expect(elem.property(named: "markedContentIDs") == .string("1,2,3"))
        }

        @Test("pageNumber property returns integer when set")
        func pageNumberProperty() {
            let elem = ValidatedStructElem(structureTypeName: "P", pageNumber: 5)
            #expect(elem.property(named: "pageNumber") == .integer(5))
        }

        @Test("structureType property returns null for non-standard type")
        func nonStandardTypeProperty() {
            let elem = ValidatedStructElem(structureTypeName: "CustomType")
            #expect(elem.property(named: "structureType") == .null)
        }
    }

    // MARK: - Convenience Computed Properties

    @Suite("Convenience Properties")
    struct ConvenienceTests {

        @Test("isHeading for heading elements")
        func isHeading() {
            #expect(ValidatedStructElem(structureTypeName: "H1").isHeading)
            #expect(ValidatedStructElem(structureTypeName: "H").isHeading)
            #expect(!ValidatedStructElem(structureTypeName: "P").isHeading)
        }

        @Test("headingLevel for numbered headings")
        func headingLevel() {
            #expect(ValidatedStructElem(structureTypeName: "H1").headingLevel == 1)
            #expect(ValidatedStructElem(structureTypeName: "H6").headingLevel == 6)
            #expect(ValidatedStructElem(structureTypeName: "H").headingLevel == nil)
            #expect(ValidatedStructElem(structureTypeName: "P").headingLevel == nil)
        }

        @Test("isTableElement for table components")
        func isTableElement() {
            #expect(ValidatedStructElem(structureTypeName: "Table").isTableElement)
            #expect(ValidatedStructElem(structureTypeName: "TR").isTableElement)
            #expect(!ValidatedStructElem(structureTypeName: "P").isTableElement)
        }

        @Test("isListElement for list components")
        func isListElement() {
            #expect(ValidatedStructElem(structureTypeName: "L").isListElement)
            #expect(ValidatedStructElem(structureTypeName: "LI").isListElement)
            #expect(!ValidatedStructElem(structureTypeName: "P").isListElement)
        }

        @Test("isFigure for figure elements")
        func isFigure() {
            #expect(ValidatedStructElem(structureTypeName: "Figure").isFigure)
            #expect(!ValidatedStructElem(structureTypeName: "P").isFigure)
        }

        @Test("isGrouping for grouping elements")
        func isGrouping() {
            #expect(ValidatedStructElem(structureTypeName: "Document").isGrouping)
            #expect(ValidatedStructElem(structureTypeName: "Sect").isGrouping)
            #expect(!ValidatedStructElem(structureTypeName: "P").isGrouping)
        }

        @Test("isContent for content elements")
        func isContent() {
            #expect(ValidatedStructElem(structureTypeName: "P").isContent)
            #expect(ValidatedStructElem(structureTypeName: "Span").isContent)
            #expect(!ValidatedStructElem(structureTypeName: "Document").isContent)
        }

        @Test("isArtifact for artifacts")
        func isArtifact() {
            #expect(ValidatedStructElem(structureTypeName: "Artifact").isArtifact)
            #expect(!ValidatedStructElem(structureTypeName: "P").isArtifact)
        }

        @Test("Custom type returns false for type-based properties")
        func customTypeProperties() {
            let elem = ValidatedStructElem(structureTypeName: "CustomType")
            #expect(!elem.isHeading)
            #expect(!elem.isTableElement)
            #expect(!elem.isListElement)
            #expect(!elem.isFigure)
            #expect(!elem.isGrouping)
            #expect(!elem.isContent)
            #expect(!elem.isArtifact)
        }
    }

    // MARK: - Descendants

    @Suite("Descendants")
    struct DescendantTests {

        @Test("allDescendants returns all nested elements")
        func allDescendants() {
            let grandchild = ValidatedStructElem.paragraph()
            let child = ValidatedStructElem.minimal(typeName: "Sect", children: [grandchild])
            let root = ValidatedStructElem.minimal(typeName: "Document", children: [child])

            let descendants = root.allDescendants
            #expect(descendants.count == 2)
        }

        @Test("allDescendants is empty for leaf elements")
        func leafDescendants() {
            let elem = ValidatedStructElem.paragraph()
            #expect(elem.allDescendants.isEmpty)
        }

        @Test("descendants(ofType:) filters correctly")
        func descendantsOfType() {
            let p1 = ValidatedStructElem.paragraph()
            let p2 = ValidatedStructElem.paragraph()
            let h1 = ValidatedStructElem.heading(level: 1)
            let root = ValidatedStructElem.minimal(typeName: "Document", children: [p1, h1, p2])

            let paragraphs = root.descendants(ofType: .paragraph)
            #expect(paragraphs.count == 2)
        }
    }

    // MARK: - Summary

    @Suite("Summary")
    struct SummaryTests {

        @Test("Summary includes type name")
        func summaryTypeName() {
            let elem = ValidatedStructElem(structureTypeName: "P")
            #expect(elem.summary.contains("P"))
        }

        @Test("Summary includes alt text indicator")
        func summaryAltText() {
            let elem = ValidatedStructElem(structureTypeName: "Figure", altText: "Alt")
            #expect(elem.summary.contains("alt"))
        }

        @Test("Summary includes language")
        func summaryLanguage() {
            let elem = ValidatedStructElem(structureTypeName: "P", language: "en")
            #expect(elem.summary.contains("lang=en"))
        }

        @Test("Summary includes child count")
        func summaryChildren() {
            let child = ValidatedStructElem.paragraph()
            let elem = ValidatedStructElem.minimal(typeName: "Sect", children: [child])
            #expect(elem.summary.contains("1 children"))
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("minimal factory creates element with type")
        func minimal() {
            let elem = ValidatedStructElem.minimal(typeName: "P")
            #expect(elem.structureTypeName == "P")
            #expect(elem.structureType == .paragraph)
        }

        @Test("heading factory creates correct level")
        func heading() {
            let h3 = ValidatedStructElem.heading(level: 3)
            #expect(h3.structureTypeName == "H3")
            #expect(h3.structureType == .h3)
        }

        @Test("heading factory clamps level to valid range")
        func headingClamp() {
            let h0 = ValidatedStructElem.heading(level: 0)
            #expect(h0.structureTypeName == "H1")

            let h99 = ValidatedStructElem.heading(level: 99)
            #expect(h99.structureTypeName == "H6")
        }

        @Test("paragraph factory creates paragraph")
        func paragraph() {
            let p = ValidatedStructElem.paragraph(altText: "test")
            #expect(p.structureTypeName == "P")
            #expect(p.altText == "test")
        }

        @Test("figure factory creates figure")
        func figure() {
            let fig = ValidatedStructElem.figure(altText: "A chart")
            #expect(fig.structureTypeName == "Figure")
            #expect(fig.altText == "A chart")
        }

        @Test("table factory creates table with rows")
        func table() {
            let row = ValidatedStructElem.minimal(typeName: "TR")
            let table = ValidatedStructElem.table(rows: [row])
            #expect(table.structureTypeName == "Table")
            #expect(table.childCount == 1)
        }

        @Test("list factory creates list with items")
        func list() {
            let item = ValidatedStructElem.minimal(typeName: "LI")
            let list = ValidatedStructElem.list(items: [item])
            #expect(list.structureTypeName == "L")
            #expect(list.childCount == 1)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let elem1 = ValidatedStructElem(id: id, structureTypeName: "P")
            let elem2 = ValidatedStructElem(id: id, structureTypeName: "H1")
            #expect(elem1 == elem2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let elem1 = ValidatedStructElem(structureTypeName: "P")
            let elem2 = ValidatedStructElem(structureTypeName: "P")
            #expect(elem1 != elem2)
        }
    }
}
