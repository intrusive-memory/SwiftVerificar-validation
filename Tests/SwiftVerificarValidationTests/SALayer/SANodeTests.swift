import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - SANode Tests

@Suite("SANode")
struct SANodeTests {

    // MARK: - Initialization Tests

    @Test("Default initialization with validated structure element")
    func defaultInit() {
        let elem = ValidatedStructElem.minimal(typeName: "P")
        let node = SANode(structElem: elem)

        #expect(node.structElem == elem)
        #expect(node.children.isEmpty)
        #expect(node.structureType == .paragraph)
        #expect(node.inheritedLanguage == nil)
    }

    @Test("Full initialization with all parameters")
    func fullInit() {
        let elem = ValidatedStructElem.minimal(
            typeName: "H1",
            altText: nil,
            language: "en-US"
        )
        let child = SANode.minimal(typeName: "Span")

        let node = SANode(
            structElem: elem,
            children: [child],
            structureType: .h1,
            inheritedLanguage: "en"
        )

        #expect(node.children.count == 1)
        #expect(node.structureType == .h1)
        #expect(node.inheritedLanguage == "en")
        #expect(node.language == "en-US")
    }

    @Test("structureType defaults from struct elem when not provided")
    func structureTypeDefault() {
        let elem = ValidatedStructElem.minimal(typeName: "Figure")
        let node = SANode(structElem: elem)
        #expect(node.structureType == .figure)
    }

    @Test("structureType can be overridden")
    func structureTypeOverride() {
        let elem = ValidatedStructElem.minimal(typeName: "CustomType")
        let node = SANode(structElem: elem, structureType: .paragraph)
        #expect(node.structureType == .paragraph)
    }

    // MARK: - SAObject Conformance Tests

    @Test("saObjectType is SANode")
    func saObjectType() {
        let node = SANode.minimal(typeName: "P")
        #expect(node.saObjectType == "SANode")
    }

    @Test("validationContext includes structure type name")
    func validationContextTest() {
        let node = SANode.minimal(typeName: "H1")
        #expect(node.validationContext.location == "SANode")
        #expect(node.validationContext.role == "H1")
    }

    @Test("accessibilityPropertyNames includes all expected names")
    func propertyNamesComplete() {
        let node = SANode.minimal(typeName: "P")
        let names = node.accessibilityPropertyNames
        #expect(names.contains("structureTypeName"))
        #expect(names.contains("structureType"))
        #expect(names.contains("altText"))
        #expect(names.contains("actualText"))
        #expect(names.contains("language"))
        #expect(names.contains("effectiveLanguage"))
        #expect(names.contains("hasAltText"))
        #expect(names.contains("hasActualText"))
        #expect(names.contains("hasLanguage"))
        #expect(names.contains("hasEffectiveLanguage"))
        #expect(names.contains("childCount"))
        #expect(names.contains("hasChildren"))
        #expect(names.contains("pageNumber"))
        #expect(names.contains("requiresAltText"))
        #expect(names.contains("isAccessible"))
        #expect(names.contains("isHeading"))
        #expect(names.contains("headingLevel"))
        #expect(names.contains("isFigure"))
        #expect(names.contains("isTableElement"))
        #expect(names.contains("isListElement"))
        #expect(names.contains("isGrouping"))
        #expect(names.contains("isContent"))
        #expect(names.contains("isArtifact"))
        #expect(names.contains("inheritedLanguage"))
    }

    // MARK: - Accessibility Property Access Tests

    @Test("accessibilityProperty returns structureTypeName")
    func propertyStructureTypeName() {
        let node = SANode.minimal(typeName: "H2")
        #expect(node.accessibilityProperty(named: "structureTypeName") == .string("H2"))
    }

    @Test("accessibilityProperty returns structureType")
    func propertyStructureType() {
        let node = SANode.heading(level: 3)
        #expect(node.accessibilityProperty(named: "structureType") == .string("H3"))

        let unknown = SANode.minimal(typeName: "CustomUnknown")
        #expect(unknown.accessibilityProperty(named: "structureType") == .null)
    }

    @Test("accessibilityProperty returns altText")
    func propertyAltText() {
        let withAlt = SANode.figure(altText: "A photo of a sunset")
        #expect(withAlt.accessibilityProperty(named: "altText") == .string("A photo of a sunset"))
        #expect(withAlt.accessibilityProperty(named: "hasAltText") == .boolean(true))

        let withoutAlt = SANode.figure()
        #expect(withoutAlt.accessibilityProperty(named: "altText") == .null)
        #expect(withoutAlt.accessibilityProperty(named: "hasAltText") == .boolean(false))
    }

    @Test("accessibilityProperty returns actualText")
    func propertyActualText() {
        let elem = ValidatedStructElem(
            structureTypeName: "Span",
            actualText: "ff ligature"
        )
        let node = SANode(structElem: elem)
        #expect(node.accessibilityProperty(named: "actualText") == .string("ff ligature"))
        #expect(node.accessibilityProperty(named: "hasActualText") == .boolean(true))

        let withoutActual = SANode.minimal(typeName: "Span")
        #expect(withoutActual.accessibilityProperty(named: "actualText") == .null)
        #expect(withoutActual.accessibilityProperty(named: "hasActualText") == .boolean(false))
    }

    @Test("accessibilityProperty returns language")
    func propertyLanguage() {
        let node = SANode.minimal(typeName: "P", language: "fr")
        #expect(node.accessibilityProperty(named: "language") == .string("fr"))
        #expect(node.accessibilityProperty(named: "hasLanguage") == .boolean(true))

        let noLang = SANode.minimal(typeName: "P")
        #expect(noLang.accessibilityProperty(named: "language") == .null)
        #expect(noLang.accessibilityProperty(named: "hasLanguage") == .boolean(false))
    }

    @Test("accessibilityProperty returns effectiveLanguage")
    func propertyEffectiveLanguage() {
        // Direct language takes precedence
        let direct = SANode.minimal(typeName: "P", language: "de", inheritedLanguage: "en")
        #expect(direct.accessibilityProperty(named: "effectiveLanguage") == .string("de"))

        // Falls back to inherited
        let inherited = SANode.minimal(typeName: "P", inheritedLanguage: "en")
        #expect(inherited.accessibilityProperty(named: "effectiveLanguage") == .string("en"))
        #expect(inherited.accessibilityProperty(named: "hasEffectiveLanguage") == .boolean(true))

        // No language at all
        let noLang = SANode.minimal(typeName: "P")
        #expect(noLang.accessibilityProperty(named: "effectiveLanguage") == .null)
        #expect(noLang.accessibilityProperty(named: "hasEffectiveLanguage") == .boolean(false))
    }

    @Test("accessibilityProperty returns childCount and hasChildren")
    func propertyChildCount() {
        let withChildren = SANode.minimal(
            typeName: "Div",
            children: [SANode.minimal(typeName: "P")]
        )
        #expect(withChildren.accessibilityProperty(named: "childCount") == .integer(1))
        #expect(withChildren.accessibilityProperty(named: "hasChildren") == .boolean(true))

        let leaf = SANode.minimal(typeName: "P")
        #expect(leaf.accessibilityProperty(named: "childCount") == .integer(0))
        #expect(leaf.accessibilityProperty(named: "hasChildren") == .boolean(false))
    }

    @Test("accessibilityProperty returns pageNumber")
    func propertyPageNumber() {
        let elem = ValidatedStructElem(
            structureTypeName: "P",
            pageNumber: 5
        )
        let node = SANode(structElem: elem)
        #expect(node.accessibilityProperty(named: "pageNumber") == .integer(5))

        let noPage = SANode.minimal(typeName: "P")
        #expect(noPage.accessibilityProperty(named: "pageNumber") == .null)
    }

    @Test("accessibilityProperty returns requiresAltText")
    func propertyRequiresAltText() {
        let figure = SANode.figure()
        #expect(figure.accessibilityProperty(named: "requiresAltText") == .boolean(true))

        let paragraph = SANode.paragraph()
        #expect(paragraph.accessibilityProperty(named: "requiresAltText") == .boolean(false))
    }

    @Test("accessibilityProperty returns isAccessible")
    func propertyIsAccessible() {
        let figureWithAlt = SANode.figure(altText: "description")
        #expect(figureWithAlt.accessibilityProperty(named: "isAccessible") == .boolean(true))

        let figureWithoutAlt = SANode.figure()
        #expect(figureWithoutAlt.accessibilityProperty(named: "isAccessible") == .boolean(false))

        let paragraph = SANode.paragraph()
        #expect(paragraph.accessibilityProperty(named: "isAccessible") == .boolean(true))
    }

    @Test("accessibilityProperty returns isHeading and headingLevel")
    func propertyHeading() {
        let heading = SANode.heading(level: 2)
        #expect(heading.accessibilityProperty(named: "isHeading") == .boolean(true))
        #expect(heading.accessibilityProperty(named: "headingLevel") == .integer(2))

        let notHeading = SANode.paragraph()
        #expect(notHeading.accessibilityProperty(named: "isHeading") == .boolean(false))
        #expect(notHeading.accessibilityProperty(named: "headingLevel") == .null)
    }

    @Test("accessibilityProperty returns isFigure")
    func propertyIsFigure() {
        let figure = SANode.figure()
        #expect(figure.accessibilityProperty(named: "isFigure") == .boolean(true))

        let notFigure = SANode.paragraph()
        #expect(notFigure.accessibilityProperty(named: "isFigure") == .boolean(false))
    }

    @Test("accessibilityProperty returns isTableElement")
    func propertyIsTableElement() {
        let table = SANode.minimal(typeName: "Table")
        #expect(table.accessibilityProperty(named: "isTableElement") == .boolean(true))

        let tableRow = SANode.minimal(typeName: "TR")
        #expect(tableRow.accessibilityProperty(named: "isTableElement") == .boolean(true))

        let notTable = SANode.paragraph()
        #expect(notTable.accessibilityProperty(named: "isTableElement") == .boolean(false))
    }

    @Test("accessibilityProperty returns isListElement")
    func propertyIsListElement() {
        let list = SANode.minimal(typeName: "L")
        #expect(list.accessibilityProperty(named: "isListElement") == .boolean(true))

        let notList = SANode.paragraph()
        #expect(notList.accessibilityProperty(named: "isListElement") == .boolean(false))
    }

    @Test("accessibilityProperty returns isGrouping")
    func propertyIsGrouping() {
        let div = SANode.minimal(typeName: "Div")
        #expect(div.accessibilityProperty(named: "isGrouping") == .boolean(true))

        let para = SANode.paragraph()
        #expect(para.accessibilityProperty(named: "isGrouping") == .boolean(false))
    }

    @Test("accessibilityProperty returns isContent")
    func propertyIsContent() {
        let para = SANode.paragraph()
        #expect(para.accessibilityProperty(named: "isContent") == .boolean(true))

        let div = SANode.minimal(typeName: "Div")
        #expect(div.accessibilityProperty(named: "isContent") == .boolean(false))
    }

    @Test("accessibilityProperty returns isArtifact")
    func propertyIsArtifact() {
        let artifact = SANode.minimal(typeName: "Artifact")
        #expect(artifact.accessibilityProperty(named: "isArtifact") == .boolean(true))

        let notArtifact = SANode.paragraph()
        #expect(notArtifact.accessibilityProperty(named: "isArtifact") == .boolean(false))
    }

    @Test("accessibilityProperty returns inheritedLanguage")
    func propertyInheritedLanguage() {
        let withInherited = SANode.minimal(typeName: "P", inheritedLanguage: "ja")
        #expect(withInherited.accessibilityProperty(named: "inheritedLanguage") == .string("ja"))

        let withoutInherited = SANode.minimal(typeName: "P")
        #expect(withoutInherited.accessibilityProperty(named: "inheritedLanguage") == .null)
    }

    @Test("accessibilityProperty returns nil for unknown property")
    func propertyUnknown() {
        let node = SANode.minimal(typeName: "P")
        #expect(node.accessibilityProperty(named: "nonexistent") == nil)
    }

    // MARK: - Computed Accessibility Properties Tests

    @Test("structureTypeName computed property")
    func structureTypeNameComputed() {
        let node = SANode.minimal(typeName: "BlockQuote")
        #expect(node.structureTypeName == "BlockQuote")
    }

    @Test("altText and hasAltText computed properties")
    func altTextComputed() {
        let withAlt = SANode.figure(altText: "description")
        #expect(withAlt.altText == "description")
        #expect(withAlt.hasAltText == true)

        let withoutAlt = SANode.figure()
        #expect(withoutAlt.altText == nil)
        #expect(withoutAlt.hasAltText == false)
    }

    @Test("actualText and hasActualText computed properties")
    func actualTextComputed() {
        let elem = ValidatedStructElem(
            structureTypeName: "Span",
            actualText: "replacement"
        )
        let node = SANode(structElem: elem)
        #expect(node.actualText == "replacement")
        #expect(node.hasActualText == true)

        let noActual = SANode.minimal(typeName: "Span")
        #expect(noActual.actualText == nil)
        #expect(noActual.hasActualText == false)
    }

    @Test("effectiveLanguage falls back to inherited")
    func effectiveLanguageComputed() {
        // Direct language
        let direct = SANode.minimal(typeName: "P", language: "de")
        #expect(direct.effectiveLanguage == "de")

        // Inherited language
        let inherited = SANode.minimal(typeName: "P", inheritedLanguage: "en")
        #expect(inherited.effectiveLanguage == "en")
        #expect(inherited.hasEffectiveLanguage == true)

        // Direct takes precedence
        let both = SANode.minimal(typeName: "P", language: "fr", inheritedLanguage: "en")
        #expect(both.effectiveLanguage == "fr")

        // No language
        let none = SANode.minimal(typeName: "P")
        #expect(none.effectiveLanguage == nil)
        #expect(none.hasEffectiveLanguage == false)
    }

    @Test("pageNumber computed property")
    func pageNumberComputed() {
        let elem = ValidatedStructElem(structureTypeName: "P", pageNumber: 3)
        let node = SANode(structElem: elem)
        #expect(node.pageNumber == 3)

        let noPage = SANode.minimal(typeName: "P")
        #expect(noPage.pageNumber == nil)
    }

    @Test("isAccessible computed property")
    func isAccessibleComputed() {
        // Figure with alt text is accessible
        let figureWithAlt = SANode.figure(altText: "description")
        #expect(figureWithAlt.isAccessible == true)

        // Figure without alt or actual text is not accessible
        let figureWithout = SANode.figure()
        #expect(figureWithout.isAccessible == false)

        // Figure with actual text is accessible
        let figureWithActual = SANode(
            structElem: ValidatedStructElem(
                structureTypeName: "Figure",
                actualText: "replacement text"
            )
        )
        #expect(figureWithActual.isAccessible == true)

        // Paragraph is always accessible (no alt text requirement)
        let para = SANode.paragraph()
        #expect(para.isAccessible == true)
    }

    @Test("isHeading and headingLevel computed properties")
    func headingComputed() {
        for level in 1...6 {
            let heading = SANode.heading(level: level)
            #expect(heading.isHeading == true)
            #expect(heading.headingLevel == level)
        }

        let generic = SANode.minimal(typeName: "H")
        #expect(generic.isHeading == true)
        #expect(generic.headingLevel == nil)

        let notHeading = SANode.paragraph()
        #expect(notHeading.isHeading == false)
        #expect(notHeading.headingLevel == nil)
    }

    @Test("Type classification computed properties")
    func typeClassification() {
        let figure = SANode.figure()
        #expect(figure.isFigure == true)
        #expect(figure.isTableElement == false)

        let table = SANode.minimal(typeName: "Table")
        #expect(table.isTableElement == true)
        #expect(table.isFigure == false)

        let list = SANode.minimal(typeName: "L")
        #expect(list.isListElement == true)

        let div = SANode.minimal(typeName: "Div")
        #expect(div.isGrouping == true)
        #expect(div.isContent == false)

        let para = SANode.paragraph()
        #expect(para.isContent == true)
        #expect(para.isGrouping == false)

        let artifact = SANode.minimal(typeName: "Artifact")
        #expect(artifact.isArtifact == true)
    }

    // MARK: - Tree Traversal Tests

    @Test("allDescendants returns all descendants depth-first")
    func allDescendants() {
        let grandchild = SANode.minimal(typeName: "Span")
        let child1 = SANode.minimal(typeName: "P", children: [grandchild])
        let child2 = SANode.heading(level: 1)
        let root = SANode.minimal(typeName: "Div", children: [child1, child2])

        let descendants = root.allDescendants
        #expect(descendants.count == 3)
        #expect(descendants[0].structureTypeName == "P")
        #expect(descendants[1].structureTypeName == "Span")
        #expect(descendants[2].structureTypeName == "H1")
    }

    @Test("allDescendants returns empty for leaf node")
    func allDescendantsLeaf() {
        let leaf = SANode.paragraph()
        #expect(leaf.allDescendants.isEmpty)
    }

    @Test("descendants(ofType:) filters correctly")
    func descendantsOfType() {
        let child1 = SANode.paragraph()
        let child2 = SANode.heading(level: 1)
        let child3 = SANode.paragraph()
        let root = SANode.minimal(typeName: "Div", children: [child1, child2, child3])

        let paragraphs = root.descendants(ofType: .paragraph)
        #expect(paragraphs.count == 2)
    }

    @Test("headingDescendants returns all heading descendants")
    func headingDescendants() {
        let child1 = SANode.heading(level: 1)
        let child2 = SANode.paragraph()
        let child3 = SANode.heading(level: 2)
        let root = SANode.minimal(typeName: "Sect", children: [child1, child2, child3])

        #expect(root.headingDescendants.count == 2)
    }

    @Test("figureDescendants returns all figure descendants")
    func figureDescendants() {
        let child1 = SANode.figure(altText: "img1")
        let child2 = SANode.paragraph()
        let child3 = SANode.figure(altText: "img2")
        let root = SANode.minimal(typeName: "Div", children: [child1, child2, child3])

        #expect(root.figureDescendants.count == 2)
    }

    @Test("hasAccessibilityIssues detects problems")
    func hasAccessibilityIssues() {
        // No issues - figure with alt text
        let goodFigure = SANode.figure(altText: "ok")
        let goodRoot = SANode.minimal(typeName: "Div", children: [goodFigure])
        #expect(goodRoot.hasAccessibilityIssues == false)

        // Issue - figure without alt text
        let badFigure = SANode.figure()
        let badRoot = SANode.minimal(typeName: "Div", children: [badFigure])
        #expect(badRoot.hasAccessibilityIssues == true)

        // Issue in nested descendant
        let nestedBadFigure = SANode.figure()
        let innerDiv = SANode.minimal(typeName: "Div", children: [nestedBadFigure])
        let outerDiv = SANode.minimal(typeName: "Div", children: [innerDiv])
        #expect(outerDiv.hasAccessibilityIssues == true)
    }

    @Test("hasAccessibilityIssues returns false for empty node")
    func noAccessibilityIssuesEmpty() {
        let node = SANode.paragraph()
        #expect(node.hasAccessibilityIssues == false)
    }

    // MARK: - Summary Tests

    @Test("summary contains relevant information")
    func summaryTest() {
        let node = SANode.figure(altText: "photo", pageNumber: 3)
        let summary = node.summary
        #expect(summary.contains("Figure"))
        #expect(summary.contains("alt"))
        #expect(summary.contains("p3"))
    }

    @Test("summary for heading with children")
    func summaryHeading() {
        let children = [SANode.minimal(typeName: "Span")]
        let node = SANode.heading(level: 2, language: "en", children: children)
        let summary = node.summary
        #expect(summary.contains("H2"))
        #expect(summary.contains("1 children"))
    }

    @Test("summary includes effective language")
    func summaryWithLang() {
        let node = SANode.minimal(typeName: "P", inheritedLanguage: "de")
        let summary = node.summary
        #expect(summary.contains("lang=de"))
    }

    // MARK: - Factory Methods Tests

    @Test("minimal factory creates basic node")
    func factoryMinimal() {
        let node = SANode.minimal(typeName: "P")
        #expect(node.structureTypeName == "P")
        #expect(node.structureType == .paragraph)
        #expect(node.children.isEmpty)
    }

    @Test("minimal factory with all parameters")
    func factoryMinimalFull() {
        let children = [SANode.minimal(typeName: "Span")]
        let node = SANode.minimal(
            typeName: "P",
            children: children,
            altText: nil,
            language: "en",
            inheritedLanguage: "de"
        )
        #expect(node.childCount == 1)
        #expect(node.language == "en")
        #expect(node.inheritedLanguage == "de")
    }

    @Test("heading factory creates heading node")
    func factoryHeading() {
        let node = SANode.heading(level: 3, language: "en")
        #expect(node.isHeading == true)
        #expect(node.headingLevel == 3)
        #expect(node.inheritedLanguage == "en")
    }

    @Test("figure factory creates figure node")
    func factoryFigure() {
        let node = SANode.figure(altText: "photo", pageNumber: 2)
        #expect(node.isFigure == true)
        #expect(node.altText == "photo")
        #expect(node.pageNumber == 2)
    }

    @Test("paragraph factory creates paragraph node")
    func factoryParagraph() {
        let node = SANode.paragraph(language: "en")
        #expect(node.structureType == .paragraph)
        #expect(node.inheritedLanguage == "en")
    }

    // MARK: - Equatable Tests

    @Test("Equal SANodes have same id")
    func equatable() {
        let elem = ValidatedStructElem.minimal(typeName: "P")
        let id = UUID()
        let node1 = SANode(id: id, structElem: elem)
        let node2 = SANode(id: id, structElem: elem)
        #expect(node1 == node2)
    }

    @Test("Different SANodes have different ids")
    func notEqual() {
        let elem = ValidatedStructElem.minimal(typeName: "P")
        let node1 = SANode(structElem: elem)
        let node2 = SANode(structElem: elem)
        #expect(node1 != node2)
    }
}
