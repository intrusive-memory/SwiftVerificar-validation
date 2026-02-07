import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - ValidatedStructureElement Tests

@Suite("ValidatedStructureElement")
struct ValidatedStructureElementTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization with type name")
        func defaultInit() {
            let elem = ValidatedStructureElement(originalTypeName: "P")
            #expect(elem.originalTypeName == "P")
            #expect(elem.resolvedTypeName == "P")
            #expect(elem.resolvedType == .paragraph)
            #expect(!elem.wasRemapped)
            #expect(elem.isStandardType)
            #expect(elem.children.isEmpty)
            #expect(elem.childCount == 0)
            #expect(!elem.hasChildren)
            #expect(elem.depth == 0)
            #expect(elem.siblingIndex == 0)
            #expect(elem.altText == nil)
            #expect(elem.actualText == nil)
            #expect(elem.expansionText == nil)
            #expect(elem.effectiveLanguage == nil)
            #expect(!elem.hasOwnLanguage)
        }

        @Test("Remapped type is detected")
        func remappedType() {
            let elem = ValidatedStructureElement(
                resolvedType: .paragraph,
                originalTypeName: "MyParagraph",
                resolvedTypeName: "P"
            )
            #expect(elem.originalTypeName == "MyParagraph")
            #expect(elem.resolvedTypeName == "P")
            #expect(elem.wasRemapped)
            #expect(elem.isStandardType)
        }

        @Test("Non-standard type detection")
        func nonStandardType() {
            let elem = ValidatedStructureElement(
                originalTypeName: "CustomUnknown",
                resolvedTypeName: "CustomUnknown"
            )
            #expect(!elem.isStandardType)
            #expect(elem.resolvedType == nil)
        }

        @Test("Object type is SEGeneral")
        func objectType() {
            let elem = ValidatedStructureElement(originalTypeName: "P")
            #expect(elem.objectType == "SEGeneral")
        }

        @Test("Default context uses structure element factory")
        func defaultContext() {
            let elem = ValidatedStructureElement(originalTypeName: "H1")
            #expect(elem.validationContext.location == "StructureElement")
            #expect(elem.validationContext.role == "H1")
        }

        @Test("Custom context is preserved")
        func customContext() {
            let ctx = ObjectContext(pageNumber: 2, location: "Custom")
            let elem = ValidatedStructureElement(
                context: ctx,
                originalTypeName: "P"
            )
            #expect(elem.validationContext.pageNumber == 2)
        }
    }

    // MARK: - Type Resolution

    @Suite("Type Resolution")
    struct TypeResolutionTests {

        @Test("Standard types resolve correctly")
        func standardTypes() {
            let types: [(String, StructureElementType)] = [
                ("P", .paragraph), ("H1", .h1), ("Table", .table),
                ("Figure", .figure), ("L", .list), ("Link", .link)
            ]
            for (name, expected) in types {
                let elem = ValidatedStructureElement(originalTypeName: name)
                #expect(elem.resolvedType == expected, "Failed for \(name)")
            }
        }

        @Test("resolvedTypeName defaults to originalTypeName")
        func defaultResolvedName() {
            let elem = ValidatedStructureElement(originalTypeName: "P")
            #expect(elem.resolvedTypeName == "P")
        }

        @Test("resolvedTypeName uses explicit value when provided")
        func explicitResolvedName() {
            let elem = ValidatedStructureElement(
                originalTypeName: "MyP",
                resolvedTypeName: "P"
            )
            #expect(elem.resolvedTypeName == "P")
        }
    }

    // MARK: - Hierarchy

    @Suite("Hierarchy")
    struct HierarchyTests {

        @Test("Depth and sibling index are set correctly")
        func depthAndIndex() {
            let elem = ValidatedStructureElement(
                originalTypeName: "P",
                depth: 3,
                siblingIndex: 2
            )
            #expect(elem.depth == 3)
            #expect(elem.siblingIndex == 2)
        }

        @Test("Children are stored correctly")
        func children() {
            let child1 = ValidatedStructureElement(originalTypeName: "P")
            let child2 = ValidatedStructureElement(originalTypeName: "P")
            let parent = ValidatedStructureElement(
                originalTypeName: "Sect",
                children: [child1, child2]
            )
            #expect(parent.childCount == 2)
            #expect(parent.hasChildren)
        }
    }

    // MARK: - Accessibility Properties

    @Suite("Accessibility Properties")
    struct AccessibilityTests {

        @Test("hasAltText returns false for empty string")
        func emptyAltText() {
            let elem = ValidatedStructureElement(originalTypeName: "Figure", altText: "")
            #expect(!elem.hasAltText)
        }

        @Test("hasActualText returns false for nil")
        func nilActualText() {
            let elem = ValidatedStructureElement(originalTypeName: "P")
            #expect(!elem.hasActualText)
        }

        @Test("hasEffectiveLanguage works correctly")
        func effectiveLanguage() {
            let withLang = ValidatedStructureElement(
                originalTypeName: "P",
                effectiveLanguage: "en-US"
            )
            #expect(withLang.hasEffectiveLanguage)

            let withoutLang = ValidatedStructureElement(originalTypeName: "P")
            #expect(!withoutLang.hasEffectiveLanguage)

            let emptyLang = ValidatedStructureElement(
                originalTypeName: "P",
                effectiveLanguage: ""
            )
            #expect(!emptyLang.hasEffectiveLanguage)
        }

        @Test("isAccessibilityRelevant for standard types")
        func isAccessibilityRelevant() {
            let p = ValidatedStructureElement(originalTypeName: "P")
            #expect(p.isAccessibilityRelevant)

            let artifact = ValidatedStructureElement(originalTypeName: "Artifact")
            #expect(!artifact.isAccessibilityRelevant)

            let nonStruct = ValidatedStructureElement(originalTypeName: "NonStruct")
            #expect(!nonStruct.isAccessibilityRelevant)
        }

        @Test("isAccessibilityRelevant returns false for unknown type")
        func unknownTypeNotRelevant() {
            let custom = ValidatedStructureElement(originalTypeName: "CustomUnknown")
            #expect(!custom.isAccessibilityRelevant)
        }

        @Test("meetsAccessibilityRequirements for figures")
        func figureMeetsRequirements() {
            let figNoAlt = ValidatedStructureElement(originalTypeName: "Figure")
            #expect(!figNoAlt.meetsAccessibilityRequirements)

            let figWithAlt = ValidatedStructureElement(
                originalTypeName: "Figure",
                altText: "A chart"
            )
            #expect(figWithAlt.meetsAccessibilityRequirements)

            let figWithActual = ValidatedStructureElement(
                originalTypeName: "Figure",
                actualText: "Chart data"
            )
            #expect(figWithActual.meetsAccessibilityRequirements)
        }

        @Test("meetsAccessibilityRequirements for paragraphs (always true)")
        func paragraphMeetsRequirements() {
            let p = ValidatedStructureElement(originalTypeName: "P")
            #expect(p.meetsAccessibilityRequirements)
        }
    }

    // MARK: - PDFObject Property Access

    @Suite("PDFObject Property Access")
    struct PropertyAccessTests {

        @Test("Property names are complete")
        func propertyNames() {
            let elem = ValidatedStructureElement(originalTypeName: "P")
            let names = elem.propertyNames
            #expect(names.contains("resolvedType"))
            #expect(names.contains("originalTypeName"))
            #expect(names.contains("resolvedTypeName"))
            #expect(names.contains("wasRemapped"))
            #expect(names.contains("isStandardType"))
            #expect(names.contains("childCount"))
            #expect(names.contains("depth"))
            #expect(names.contains("siblingIndex"))
            #expect(names.contains("altText"))
            #expect(names.contains("effectiveLanguage"))
            #expect(names.contains("kidsStandardTypes"))
        }

        @Test("Property access for type information")
        func typeProperties() {
            let elem = ValidatedStructureElement(
                originalTypeName: "MyP",
                resolvedTypeName: "P"
            )
            #expect(elem.property(named: "resolvedType") == .string("P"))
            #expect(elem.property(named: "originalTypeName") == .string("MyP"))
            #expect(elem.property(named: "resolvedTypeName") == .string("P"))
            #expect(elem.property(named: "wasRemapped") == .boolean(true))
            #expect(elem.property(named: "isStandardType") == .boolean(true))
        }

        @Test("Property access for hierarchy")
        func hierarchyProperties() {
            let child = ValidatedStructureElement(originalTypeName: "P")
            let parent = ValidatedStructureElement(
                originalTypeName: "Sect",
                children: [child],
                depth: 1,
                siblingIndex: 3
            )
            #expect(parent.property(named: "childCount") == .integer(1))
            #expect(parent.property(named: "hasChildren") == .boolean(true))
            #expect(parent.property(named: "depth") == .integer(1))
            #expect(parent.property(named: "siblingIndex") == .integer(3))
        }

        @Test("Property access for accessibility")
        func accessibilityProperties() {
            let elem = ValidatedStructureElement(
                originalTypeName: "Figure",
                altText: "Alt",
                actualText: "Actual",
                expansionText: "Exp",
                effectiveLanguage: "en",
                hasOwnLanguage: true
            )
            #expect(elem.property(named: "altText") == .string("Alt"))
            #expect(elem.property(named: "actualText") == .string("Actual"))
            #expect(elem.property(named: "expansionText") == .string("Exp"))
            #expect(elem.property(named: "effectiveLanguage") == .string("en"))
            #expect(elem.property(named: "hasOwnLanguage") == .boolean(true))
            #expect(elem.property(named: "hasAltText") == .boolean(true))
            #expect(elem.property(named: "hasActualText") == .boolean(true))
            #expect(elem.property(named: "hasEffectiveLanguage") == .boolean(true))
        }

        @Test("Property access for null values")
        func nullProperties() {
            let elem = ValidatedStructureElement(originalTypeName: "P")
            #expect(elem.property(named: "altText") == .null)
            #expect(elem.property(named: "actualText") == .null)
            #expect(elem.property(named: "expansionText") == .null)
            #expect(elem.property(named: "effectiveLanguage") == .null)
            #expect(elem.property(named: "pageNumber") == .null)
            #expect(elem.property(named: "elementID") == .null)
            #expect(elem.property(named: "namespaceURI") == .null)
        }

        @Test("resolvedType property returns null for unknown type")
        func resolvedTypeNull() {
            let elem = ValidatedStructureElement(
                originalTypeName: "CustomUnknown",
                resolvedTypeName: "CustomUnknown"
            )
            #expect(elem.property(named: "resolvedType") == .null)
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let elem = ValidatedStructureElement(originalTypeName: "P")
            #expect(elem.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - kidsStandardTypes

    @Suite("kidsStandardTypes")
    struct KidsStandardTypesTests {

        @Test("Empty children produces empty string")
        func emptyChildren() {
            let elem = ValidatedStructureElement(originalTypeName: "Sect")
            #expect(elem.kidsStandardTypes == "")
        }

        @Test("Single child produces single type name")
        func singleChild() {
            let child = ValidatedStructureElement(originalTypeName: "P")
            let elem = ValidatedStructureElement(
                originalTypeName: "Sect",
                children: [child]
            )
            #expect(elem.kidsStandardTypes == "P")
        }

        @Test("Multiple children joined by ampersand")
        func multipleChildren() {
            let p = ValidatedStructureElement(originalTypeName: "P")
            let h1 = ValidatedStructureElement(originalTypeName: "H1")
            let fig = ValidatedStructureElement(originalTypeName: "Figure")
            let elem = ValidatedStructureElement(
                originalTypeName: "Sect",
                children: [p, h1, fig]
            )
            #expect(elem.kidsStandardTypes == "P&H1&Figure")
        }

        @Test("kidsStandardTypes uses resolvedTypeName")
        func usesResolvedTypeName() {
            let child = ValidatedStructureElement(
                originalTypeName: "MyP",
                resolvedTypeName: "P"
            )
            let elem = ValidatedStructureElement(
                originalTypeName: "Sect",
                children: [child]
            )
            #expect(elem.kidsStandardTypes == "P")
        }

        @Test("kidsStandardTypes property access returns string")
        func propertyAccess() {
            let child = ValidatedStructureElement(originalTypeName: "P")
            let elem = ValidatedStructureElement(
                originalTypeName: "Sect",
                children: [child]
            )
            #expect(elem.property(named: "kidsStandardTypes") == .string("P"))
        }
    }

    // MARK: - Convenience Computed Properties

    @Suite("Convenience Properties")
    struct ConvenienceTests {

        @Test("isHeading for heading types")
        func isHeading() {
            #expect(ValidatedStructureElement(originalTypeName: "H1").isHeading)
            #expect(ValidatedStructureElement(originalTypeName: "H").isHeading)
            #expect(!ValidatedStructureElement(originalTypeName: "P").isHeading)
        }

        @Test("headingLevel for numbered headings")
        func headingLevel() {
            #expect(ValidatedStructureElement(originalTypeName: "H1").headingLevel == 1)
            #expect(ValidatedStructureElement(originalTypeName: "H6").headingLevel == 6)
            #expect(ValidatedStructureElement(originalTypeName: "P").headingLevel == nil)
        }

        @Test("isTableElement for table components")
        func isTableElement() {
            #expect(ValidatedStructureElement(originalTypeName: "Table").isTableElement)
            #expect(ValidatedStructureElement(originalTypeName: "TR").isTableElement)
            #expect(!ValidatedStructureElement(originalTypeName: "P").isTableElement)
        }

        @Test("isListElement for list components")
        func isListElement() {
            #expect(ValidatedStructureElement(originalTypeName: "L").isListElement)
            #expect(!ValidatedStructureElement(originalTypeName: "P").isListElement)
        }

        @Test("isFigure for figures")
        func isFigure() {
            #expect(ValidatedStructureElement(originalTypeName: "Figure").isFigure)
            #expect(!ValidatedStructureElement(originalTypeName: "P").isFigure)
        }

        @Test("isLink for links")
        func isLink() {
            #expect(ValidatedStructureElement(originalTypeName: "Link").isLink)
            #expect(!ValidatedStructureElement(originalTypeName: "P").isLink)
        }

        @Test("isArtifact for artifacts")
        func isArtifact() {
            #expect(ValidatedStructureElement(originalTypeName: "Artifact").isArtifact)
            #expect(!ValidatedStructureElement(originalTypeName: "P").isArtifact)
        }

        @Test("isGrouping for grouping elements")
        func isGrouping() {
            #expect(ValidatedStructureElement(originalTypeName: "Document").isGrouping)
            #expect(!ValidatedStructureElement(originalTypeName: "P").isGrouping)
        }

        @Test("isContent for content elements")
        func isContent() {
            #expect(ValidatedStructureElement(originalTypeName: "P").isContent)
            #expect(!ValidatedStructureElement(originalTypeName: "Document").isContent)
        }
    }

    // MARK: - Tree Navigation

    @Suite("Tree Navigation")
    struct NavigationTests {

        @Test("allDescendants returns all nested elements")
        func allDescendants() {
            let grandchild = ValidatedStructureElement(originalTypeName: "P")
            let child = ValidatedStructureElement(
                originalTypeName: "Sect",
                children: [grandchild]
            )
            let root = ValidatedStructureElement(
                originalTypeName: "Document",
                children: [child]
            )
            #expect(root.allDescendants.count == 2)
        }

        @Test("allDescendants is empty for leaf elements")
        func leafDescendants() {
            let elem = ValidatedStructureElement(originalTypeName: "P")
            #expect(elem.allDescendants.isEmpty)
        }

        @Test("descendants(ofType:) filters correctly")
        func descendantsOfType() {
            let p1 = ValidatedStructureElement(originalTypeName: "P")
            let p2 = ValidatedStructureElement(originalTypeName: "P")
            let h1 = ValidatedStructureElement(originalTypeName: "H1")
            let root = ValidatedStructureElement(
                originalTypeName: "Sect",
                children: [p1, h1, p2]
            )
            #expect(root.descendants(ofType: .paragraph).count == 2)
            #expect(root.descendants(ofType: .h1).count == 1)
        }

        @Test("descendantHeadings returns only headings")
        func descendantHeadings() {
            let h1 = ValidatedStructureElement(originalTypeName: "H1")
            let h2 = ValidatedStructureElement(originalTypeName: "H2")
            let p = ValidatedStructureElement(originalTypeName: "P")
            let root = ValidatedStructureElement(
                originalTypeName: "Document",
                children: [h1, p, h2]
            )
            #expect(root.descendantHeadings.count == 2)
        }

        @Test("descendantFigures returns only figures")
        func descendantFigures() {
            let fig = ValidatedStructureElement(originalTypeName: "Figure", altText: "Alt")
            let p = ValidatedStructureElement(originalTypeName: "P")
            let root = ValidatedStructureElement(
                originalTypeName: "Document",
                children: [fig, p]
            )
            #expect(root.descendantFigures.count == 1)
        }

        @Test("accessibilityIssues returns elements failing requirements")
        func accessibilityIssues() {
            let figNoAlt = ValidatedStructureElement(originalTypeName: "Figure")
            let figWithAlt = ValidatedStructureElement(
                originalTypeName: "Figure",
                altText: "Alt"
            )
            let p = ValidatedStructureElement(originalTypeName: "P")
            let root = ValidatedStructureElement(
                originalTypeName: "Document",
                children: [figNoAlt, figWithAlt, p]
            )
            #expect(root.accessibilityIssues.count == 1)
        }
    }

    // MARK: - Creation from ValidatedStructElem

    @Suite("Creation from ValidatedStructElem")
    struct CreationTests {

        @Test("from() resolves type through role map")
        func fromWithRoleMap() {
            let elem = ValidatedStructElem(structureTypeName: "MyP")
            let root = ValidatedStructTreeRoot(roleMap: ["MyP": "P"])

            let resolved = ValidatedStructureElement.from(elem, root: root)
            #expect(resolved.originalTypeName == "MyP")
            #expect(resolved.resolvedTypeName == "P")
            #expect(resolved.resolvedType == .paragraph)
            #expect(resolved.wasRemapped)
        }

        @Test("from() preserves standard type without remapping")
        func fromStandardType() {
            let elem = ValidatedStructElem(structureTypeName: "Table")
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(elem, root: root)
            #expect(resolved.originalTypeName == "Table")
            #expect(resolved.resolvedTypeName == "Table")
            #expect(resolved.resolvedType == .table)
            #expect(!resolved.wasRemapped)
        }

        @Test("from() inherits language from parent")
        func fromInheritsLanguage() {
            let child = ValidatedStructElem(structureTypeName: "P")
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(
                child,
                root: root,
                inheritedLanguage: "en-US"
            )
            #expect(resolved.effectiveLanguage == "en-US")
            #expect(!resolved.hasOwnLanguage)
        }

        @Test("from() uses own language when present")
        func fromOwnLanguage() {
            let child = ValidatedStructElem(structureTypeName: "P", language: "fr")
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(
                child,
                root: root,
                inheritedLanguage: "en-US"
            )
            #expect(resolved.effectiveLanguage == "fr")
            #expect(resolved.hasOwnLanguage)
        }

        @Test("from() sets depth and sibling index")
        func fromDepthAndIndex() {
            let elem = ValidatedStructElem(structureTypeName: "P")
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(
                elem,
                root: root,
                depth: 2,
                siblingIndex: 5
            )
            #expect(resolved.depth == 2)
            #expect(resolved.siblingIndex == 5)
        }

        @Test("from() preserves alt text and actual text")
        func fromPreservesAccessibility() {
            let elem = ValidatedStructElem(
                structureTypeName: "Figure",
                altText: "A picture",
                actualText: "Content"
            )
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(elem, root: root)
            #expect(resolved.altText == "A picture")
            #expect(resolved.actualText == "Content")
        }

        @Test("from() recursively resolves children")
        func fromRecursiveChildren() {
            let grandchild = ValidatedStructElem.paragraph()
            let child = ValidatedStructElem.minimal(
                typeName: "Sect",
                children: [grandchild]
            )
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(
                child,
                root: root,
                depth: 0
            )
            #expect(resolved.children.count == 1)
            #expect(resolved.children[0].depth == 1)
            #expect(resolved.children[0].siblingIndex == 0)
            #expect(resolved.children[0].resolvedType == .paragraph)
        }

        @Test("from() propagates language through hierarchy")
        func fromPropagatesLanguage() {
            let innerChild = ValidatedStructElem(structureTypeName: "Span")
            let child = ValidatedStructElem(
                structureTypeName: "P",
                children: [innerChild],
                language: "de"
            )
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(
                child,
                root: root,
                inheritedLanguage: "en"
            )
            #expect(resolved.effectiveLanguage == "de")
            #expect(resolved.children[0].effectiveLanguage == "de")
        }

        @Test("from() preserves marked content IDs")
        func fromPreservesMCIDs() {
            let elem = ValidatedStructElem(
                structureTypeName: "P",
                markedContentIDs: [10, 11, 12]
            )
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(elem, root: root)
            #expect(resolved.markedContentIDs == [10, 11, 12])
        }

        @Test("from() preserves namespace URI")
        func fromPreservesNamespace() {
            let elem = ValidatedStructElem(
                structureTypeName: "P",
                namespaceURI: "http://example.com/ns"
            )
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(elem, root: root)
            #expect(resolved.namespaceURI == "http://example.com/ns")
        }

        @Test("from() preserves element ID")
        func fromPreservesElementID() {
            let elem = ValidatedStructElem(
                structureTypeName: "P",
                elementID: "elem-42"
            )
            let root = ValidatedStructTreeRoot()

            let resolved = ValidatedStructureElement.from(elem, root: root)
            #expect(resolved.elementID == "elem-42")
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("minimal creates correct element")
        func minimal() {
            let elem = ValidatedStructureElement.minimal(
                typeName: "H2",
                altText: "Heading",
                language: "en"
            )
            #expect(elem.originalTypeName == "H2")
            #expect(elem.resolvedType == .h2)
            #expect(elem.altText == "Heading")
            #expect(elem.effectiveLanguage == "en")
        }

        @Test("minimal with children")
        func minimalWithChildren() {
            let child = ValidatedStructureElement.minimal(typeName: "P")
            let parent = ValidatedStructureElement.minimal(
                typeName: "Sect",
                children: [child]
            )
            #expect(parent.childCount == 1)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let elem1 = ValidatedStructureElement(id: id, originalTypeName: "P")
            let elem2 = ValidatedStructureElement(id: id, originalTypeName: "H1")
            #expect(elem1 == elem2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let elem1 = ValidatedStructureElement(originalTypeName: "P")
            let elem2 = ValidatedStructureElement(originalTypeName: "P")
            #expect(elem1 != elem2)
        }
    }
}
