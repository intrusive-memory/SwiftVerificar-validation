import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - SAStructureElement Tests

@Suite("SAStructureElement")
struct SAStructureElementTests {

    // MARK: - Initialization Tests

    @Test("Default initialization with validated structure element")
    func defaultInit() {
        let validated = ValidatedStructureElement.minimal(typeName: "P")
        let elem = SAStructureElement(validatedElement: validated)

        #expect(elem.validatedElement == validated)
        #expect(elem.children.isEmpty)
        #expect(elem.nodes.isEmpty)
        #expect(elem.resolvedType == .paragraph)
    }

    @Test("Initialization with children")
    func initWithChildren() {
        let child1 = SAStructureElement.minimal(typeName: "Span")
        let child2 = SAStructureElement.minimal(typeName: "Link")
        let parent = SAStructureElement.minimal(typeName: "P", children: [child1, child2])

        #expect(parent.childCount == 2)
        #expect(parent.hasChildren)
    }

    @Test("Initialization with SA nodes")
    func initWithNodes() {
        let node = SANode.minimal(typeName: "P")
        let validated = ValidatedStructureElement.minimal(typeName: "P")
        let elem = SAStructureElement(validatedElement: validated, nodes: [node])

        #expect(elem.nodes.count == 1)
    }

    @Test("Initialization with custom id")
    func initWithCustomId() {
        let customId = UUID()
        let validated = ValidatedStructureElement.minimal(typeName: "P")
        let elem = SAStructureElement(id: customId, validatedElement: validated)

        #expect(elem.id == customId)
    }

    // MARK: - SAObject Conformance Tests

    @Test("saObjectType returns SAStructureElement")
    func saObjectType() {
        let elem = SAStructureElement.minimal(typeName: "P")
        #expect(elem.saObjectType == "SAStructureElement")
    }

    @Test("validationContext has correct location")
    func validationContext() {
        let elem = SAStructureElement.minimal(typeName: "Figure")
        #expect(elem.validationContext.location == "SAStructureElement")
        #expect(elem.validationContext.role == "Figure")
    }

    @Test("accessibilityPropertyNames is not empty")
    func propertyNames() {
        let elem = SAStructureElement.minimal(typeName: "P")
        #expect(!elem.accessibilityPropertyNames.isEmpty)
        #expect(elem.accessibilityPropertyNames.contains("resolvedType"))
        #expect(elem.accessibilityPropertyNames.contains("altText"))
        #expect(elem.accessibilityPropertyNames.contains("isHeading"))
    }

    // MARK: - Property Access Tests

    @Test("accessibilityProperty returns resolved type")
    func propertyResolvedType() {
        let elem = SAStructureElement.minimal(typeName: "P")
        let value = elem.accessibilityProperty(named: "resolvedType")
        #expect(value == .string("P"))
    }

    @Test("accessibilityProperty returns null for unknown type")
    func propertyResolvedTypeNull() {
        let validated = ValidatedStructureElement(originalTypeName: "CustomType")
        let elem = SAStructureElement(validatedElement: validated)
        let value = elem.accessibilityProperty(named: "resolvedType")
        #expect(value == .null)
    }

    @Test("accessibilityProperty returns originalTypeName")
    func propertyOriginalTypeName() {
        let elem = SAStructureElement.minimal(typeName: "H1")
        let value = elem.accessibilityProperty(named: "originalTypeName")
        #expect(value == .string("H1"))
    }

    @Test("accessibilityProperty returns altText when present")
    func propertyAltText() {
        let elem = SAStructureElement.minimal(typeName: "Figure", altText: "A chart")
        let value = elem.accessibilityProperty(named: "altText")
        #expect(value == .string("A chart"))
    }

    @Test("accessibilityProperty returns null altText when absent")
    func propertyAltTextNull() {
        let elem = SAStructureElement.minimal(typeName: "P")
        let value = elem.accessibilityProperty(named: "altText")
        #expect(value == .null)
    }

    @Test("accessibilityProperty returns hasAltText boolean")
    func propertyHasAltText() {
        let withAlt = SAStructureElement.minimal(typeName: "Figure", altText: "desc")
        let withoutAlt = SAStructureElement.minimal(typeName: "Figure")

        #expect(withAlt.accessibilityProperty(named: "hasAltText") == .boolean(true))
        #expect(withoutAlt.accessibilityProperty(named: "hasAltText") == .boolean(false))
    }

    @Test("accessibilityProperty returns effectiveLanguage")
    func propertyEffectiveLanguage() {
        let elem = SAStructureElement.minimal(typeName: "P", language: "en-US")
        let value = elem.accessibilityProperty(named: "effectiveLanguage")
        #expect(value == .string("en-US"))
    }

    @Test("accessibilityProperty returns childCount")
    func propertyChildCount() {
        let child = SAStructureElement.minimal(typeName: "Span")
        let parent = SAStructureElement.minimal(typeName: "P", children: [child])
        let value = parent.accessibilityProperty(named: "childCount")
        #expect(value == .integer(1))
    }

    @Test("accessibilityProperty returns depth")
    func propertyDepth() {
        let validated = ValidatedStructureElement(
            originalTypeName: "P",
            depth: 3
        )
        let elem = SAStructureElement(validatedElement: validated)
        let value = elem.accessibilityProperty(named: "depth")
        #expect(value == .integer(3))
    }

    @Test("accessibilityProperty returns pageNumber when set")
    func propertyPageNumber() {
        let elem = SAStructureElement.figure(pageNumber: 5)
        let value = elem.accessibilityProperty(named: "pageNumber")
        #expect(value == .integer(5))
    }

    @Test("accessibilityProperty returns null pageNumber when absent")
    func propertyPageNumberNull() {
        let elem = SAStructureElement.minimal(typeName: "P")
        let value = elem.accessibilityProperty(named: "pageNumber")
        #expect(value == .null)
    }

    @Test("accessibilityProperty returns isHeading for heading elements")
    func propertyIsHeading() {
        let heading = SAStructureElement.heading(level: 2)
        let para = SAStructureElement.minimal(typeName: "P")

        #expect(heading.accessibilityProperty(named: "isHeading") == .boolean(true))
        #expect(para.accessibilityProperty(named: "isHeading") == .boolean(false))
    }

    @Test("accessibilityProperty returns headingLevel for numbered headings")
    func propertyHeadingLevel() {
        let heading = SAStructureElement.heading(level: 3)
        let value = heading.accessibilityProperty(named: "headingLevel")
        #expect(value == .integer(3))
    }

    @Test("accessibilityProperty returns null headingLevel for non-headings")
    func propertyHeadingLevelNull() {
        let para = SAStructureElement.minimal(typeName: "P")
        let value = para.accessibilityProperty(named: "headingLevel")
        #expect(value == .null)
    }

    @Test("accessibilityProperty returns isFigure")
    func propertyIsFigure() {
        let figure = SAStructureElement.figure()
        let para = SAStructureElement.minimal(typeName: "P")

        #expect(figure.accessibilityProperty(named: "isFigure") == .boolean(true))
        #expect(para.accessibilityProperty(named: "isFigure") == .boolean(false))
    }

    @Test("accessibilityProperty returns nodeCount")
    func propertyNodeCount() {
        let node = SANode.minimal(typeName: "P")
        let validated = ValidatedStructureElement.minimal(typeName: "P")
        let elem = SAStructureElement(validatedElement: validated, nodes: [node])
        let value = elem.accessibilityProperty(named: "nodeCount")
        #expect(value == .integer(1))
    }

    @Test("accessibilityProperty returns nil for unknown property")
    func propertyUnknown() {
        let elem = SAStructureElement.minimal(typeName: "P")
        #expect(elem.accessibilityProperty(named: "nonexistent") == nil)
    }

    @Test("accessibilityProperty returns kidsStandardTypes")
    func propertyKidsStandardTypes() {
        let child1 = SAStructureElement.minimal(typeName: "Span")
        let child2 = SAStructureElement.minimal(typeName: "Link")
        let parent = SAStructureElement.minimal(typeName: "P", children: [child1, child2])
        let value = parent.accessibilityProperty(named: "kidsStandardTypes")
        #expect(value == .string("Span&Link"))
    }

    @Test("accessibilityProperty returns isAccessibilityRelevant")
    func propertyIsAccessibilityRelevant() {
        let para = SAStructureElement.minimal(typeName: "P")
        let value = para.accessibilityProperty(named: "isAccessibilityRelevant")
        #expect(value == .boolean(true))
    }

    @Test("accessibilityProperty returns meetsAccessibilityRequirements")
    func propertyMeetsAccessibility() {
        let figureNoAlt = SAStructureElement.figure()
        let figureWithAlt = SAStructureElement.figure(altText: "Description")

        #expect(figureNoAlt.accessibilityProperty(named: "meetsAccessibilityRequirements") == .boolean(false))
        #expect(figureWithAlt.accessibilityProperty(named: "meetsAccessibilityRequirements") == .boolean(true))
    }

    // MARK: - Delegated Property Tests

    @Test("resolvedType delegates to validatedElement")
    func resolvedType() {
        let elem = SAStructureElement.minimal(typeName: "Table")
        #expect(elem.resolvedType == .table)
    }

    @Test("wasRemapped is false for standard types")
    func wasRemapped() {
        let elem = SAStructureElement.minimal(typeName: "P")
        #expect(!elem.wasRemapped)
    }

    @Test("isStandardType is true for known types")
    func isStandardType() {
        let known = SAStructureElement.minimal(typeName: "P")
        let unknown = SAStructureElement(
            validatedElement: ValidatedStructureElement(originalTypeName: "CustomType")
        )
        #expect(known.isStandardType)
        #expect(!unknown.isStandardType)
    }

    // MARK: - Accessibility Property Tests

    @Test("requiresAltText for figure elements")
    func requiresAltText() {
        let figure = SAStructureElement.figure()
        let para = SAStructureElement.paragraph()
        #expect(figure.requiresAltText)
        #expect(!para.requiresAltText)
    }

    @Test("isAccessible checks alt text requirement")
    func isAccessible() {
        let figureNoAlt = SAStructureElement.figure()
        let figureWithAlt = SAStructureElement.figure(altText: "Chart")
        let para = SAStructureElement.paragraph()

        #expect(!figureNoAlt.isAccessible)
        #expect(figureWithAlt.isAccessible)
        #expect(para.isAccessible)
    }

    @Test("isHeading identifies heading elements")
    func isHeading() {
        let h1 = SAStructureElement.heading(level: 1)
        let h3 = SAStructureElement.heading(level: 3)
        let para = SAStructureElement.paragraph()

        #expect(h1.isHeading)
        #expect(h3.isHeading)
        #expect(!para.isHeading)
    }

    @Test("headingLevel returns correct level")
    func headingLevel() {
        let h2 = SAStructureElement.heading(level: 2)
        #expect(h2.headingLevel == 2)
    }

    @Test("isFigure identifies figure elements")
    func isFigure() {
        let figure = SAStructureElement.figure()
        let para = SAStructureElement.paragraph()
        #expect(figure.isFigure)
        #expect(!para.isFigure)
    }

    @Test("isTableElement identifies table elements")
    func isTableElement() {
        let table = SAStructureElement.minimal(typeName: "Table")
        let para = SAStructureElement.paragraph()
        #expect(table.isTableElement)
        #expect(!para.isTableElement)
    }

    @Test("isListElement identifies list elements")
    func isListElement() {
        let list = SAStructureElement.minimal(typeName: "L")
        let para = SAStructureElement.paragraph()
        #expect(list.isListElement)
        #expect(!para.isListElement)
    }

    @Test("isGrouping identifies grouping elements")
    func isGrouping() {
        let sect = SAStructureElement.minimal(typeName: "Sect")
        let para = SAStructureElement.paragraph()
        #expect(sect.isGrouping)
        #expect(!para.isGrouping)
    }

    @Test("isContent identifies content elements")
    func isContent() {
        let para = SAStructureElement.paragraph()
        let sect = SAStructureElement.minimal(typeName: "Sect")
        #expect(para.isContent)
        #expect(!sect.isContent)
    }

    @Test("isArtifact identifies artifact elements")
    func isArtifact() {
        let artifact = SAStructureElement.minimal(typeName: "Artifact")
        let para = SAStructureElement.paragraph()
        #expect(artifact.isArtifact)
        #expect(!para.isArtifact)
    }

    @Test("isLink identifies link elements")
    func isLink() {
        let link = SAStructureElement.minimal(typeName: "Link")
        let para = SAStructureElement.paragraph()
        #expect(link.isLink)
        #expect(!para.isLink)
    }

    // MARK: - Tree Traversal Tests

    @Test("allDescendants returns all descendants depth-first")
    func allDescendants() {
        let grandchild = SAStructureElement.minimal(typeName: "Span")
        let child1 = SAStructureElement.minimal(typeName: "P", children: [grandchild])
        let child2 = SAStructureElement.minimal(typeName: "H1")
        let root = SAStructureElement.minimal(typeName: "Sect", children: [child1, child2])

        let descendants = root.allDescendants
        #expect(descendants.count == 3)
        #expect(descendants[0].resolvedTypeName == "P")
        #expect(descendants[1].resolvedTypeName == "Span")
        #expect(descendants[2].resolvedTypeName == "H1")
    }

    @Test("descendants(ofType:) filters by type")
    func descendantsOfType() {
        let h1 = SAStructureElement.heading(level: 1)
        let h2 = SAStructureElement.heading(level: 2)
        let para = SAStructureElement.paragraph()
        let root = SAStructureElement.minimal(typeName: "Sect", children: [h1, para, h2])

        let headings = root.descendants(ofType: .h1)
        #expect(headings.count == 1)
    }

    @Test("headingDescendants finds all headings")
    func headingDescendants() {
        let h1 = SAStructureElement.heading(level: 1)
        let h2 = SAStructureElement.heading(level: 2)
        let para = SAStructureElement.paragraph()
        let root = SAStructureElement.minimal(typeName: "Sect", children: [h1, para, h2])

        let headings = root.headingDescendants
        #expect(headings.count == 2)
    }

    @Test("figureDescendants finds all figures")
    func figureDescendants() {
        let fig1 = SAStructureElement.figure(altText: "Chart")
        let fig2 = SAStructureElement.figure()
        let para = SAStructureElement.paragraph()
        let root = SAStructureElement.minimal(typeName: "Sect", children: [fig1, para, fig2])

        let figures = root.figureDescendants
        #expect(figures.count == 2)
    }

    @Test("accessibilityIssues finds elements without required alt text")
    func accessibilityIssues() {
        let goodFigure = SAStructureElement.figure(altText: "Description")
        let badFigure = SAStructureElement.figure()
        let para = SAStructureElement.paragraph()
        let root = SAStructureElement.minimal(typeName: "Sect", children: [goodFigure, badFigure, para])

        let issues = root.accessibilityIssues
        #expect(issues.count == 1)
    }

    @Test("hasAccessibilityIssues detects issues in subtree")
    func hasAccessibilityIssues() {
        let badFigure = SAStructureElement.figure()
        let root = SAStructureElement.minimal(typeName: "Sect", children: [badFigure])
        #expect(root.hasAccessibilityIssues)
    }

    @Test("hasAccessibilityIssues returns false when tree is clean")
    func noAccessibilityIssues() {
        let goodFigure = SAStructureElement.figure(altText: "desc")
        let para = SAStructureElement.paragraph()
        let root = SAStructureElement.minimal(typeName: "Sect", children: [goodFigure, para])
        #expect(!root.hasAccessibilityIssues)
    }

    // MARK: - kidsStandardTypes Tests

    @Test("kidsStandardTypes joins child types with &")
    func kidsStandardTypes() {
        let child1 = SAStructureElement.paragraph()
        let child2 = SAStructureElement.heading(level: 1)
        let root = SAStructureElement.minimal(typeName: "Sect", children: [child1, child2])

        #expect(root.kidsStandardTypes == "P&H1")
    }

    @Test("kidsStandardTypes empty for leaf elements")
    func kidsStandardTypesEmpty() {
        let leaf = SAStructureElement.paragraph()
        #expect(leaf.kidsStandardTypes == "")
    }

    // MARK: - Summary Tests

    @Test("summary includes type name")
    func summaryBasic() {
        let elem = SAStructureElement.minimal(typeName: "P")
        #expect(elem.summary.contains("P"))
    }

    @Test("summary includes alt text indicator")
    func summaryWithAlt() {
        let elem = SAStructureElement.figure(altText: "Chart")
        #expect(elem.summary.contains("alt"))
    }

    @Test("summary includes child count")
    func summaryWithChildren() {
        let child = SAStructureElement.paragraph()
        let parent = SAStructureElement.minimal(typeName: "Sect", children: [child])
        #expect(parent.summary.contains("1 children"))
    }

    // MARK: - Factory Tests

    @Test("from() creates recursive SA structure from ValidatedStructureElement")
    func fromFactory() {
        let grandchild = ValidatedStructureElement.minimal(typeName: "Span")
        let child = ValidatedStructureElement.minimal(typeName: "P", children: [grandchild])
        let root = ValidatedStructureElement.minimal(typeName: "Sect", children: [child])

        let saRoot = SAStructureElement.from(root)

        #expect(saRoot.resolvedTypeName == "Sect")
        #expect(saRoot.childCount == 1)
        #expect(saRoot.children[0].resolvedTypeName == "P")
        #expect(saRoot.children[0].childCount == 1)
        #expect(saRoot.children[0].children[0].resolvedTypeName == "Span")
    }

    @Test("minimal factory creates correctly typed element")
    func minimalFactory() {
        let elem = SAStructureElement.minimal(typeName: "Table")
        #expect(elem.resolvedType == .table)
        #expect(elem.resolvedTypeName == "Table")
    }

    @Test("heading factory creates heading with correct level")
    func headingFactory() {
        let h3 = SAStructureElement.heading(level: 3)
        #expect(h3.isHeading)
        #expect(h3.headingLevel == 3)
        #expect(h3.resolvedTypeName == "H3")
    }

    @Test("figure factory creates figure element")
    func figureFactory() {
        let fig = SAStructureElement.figure(altText: "Test", pageNumber: 2)
        #expect(fig.isFigure)
        #expect(fig.altText == "Test")
        #expect(fig.pageNumber == 2)
    }

    @Test("paragraph factory creates paragraph element")
    func paragraphFactory() {
        let p = SAStructureElement.paragraph(language: "fr")
        #expect(p.resolvedType == .paragraph)
        #expect(p.effectiveLanguage == "fr")
    }

    // MARK: - Equatable Tests

    @Test("Equatable uses id for comparison")
    func equatable() {
        let id = UUID()
        let validated = ValidatedStructureElement.minimal(typeName: "P")
        let elem1 = SAStructureElement(id: id, validatedElement: validated)
        let elem2 = SAStructureElement(id: id, validatedElement: validated)
        let elem3 = SAStructureElement(validatedElement: validated)

        #expect(elem1 == elem2)
        #expect(elem1 != elem3)
    }

    // MARK: - Identifiable Tests

    @Test("Identifiable provides unique id")
    func identifiable() {
        let elem1 = SAStructureElement.minimal(typeName: "P")
        let elem2 = SAStructureElement.minimal(typeName: "P")
        #expect(elem1.id != elem2.id)
    }
}
