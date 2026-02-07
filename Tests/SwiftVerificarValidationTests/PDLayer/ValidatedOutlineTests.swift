import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Validated Outline Tests

@Suite("ValidatedOutline Tests")
struct ValidatedOutlineTests {

    @Test("Default initialization")
    func defaultInit() {
        let outline = ValidatedOutline()
        #expect(outline.title == nil)
        #expect(outline.hasDestination == false)
        #expect(outline.destinationName == nil)
        #expect(outline.hasAction == false)
        #expect(outline.actionType == nil)
        #expect(outline.hasChildren == false)
        #expect(outline.childCount == 0)
        #expect(outline.totalCount == nil)
        #expect(outline.isOpen == false)
        #expect(outline.isRoot == false)
        #expect(outline.depth == 0)
        #expect(outline.isBold == false)
        #expect(outline.isItalic == false)
        #expect(outline.hasColor == false)
        #expect(outline.structureElementId == nil)
        #expect(outline.objectType == "PDOutlineItem")
    }

    @Test("Root outline factory")
    func rootFactory() {
        let root = ValidatedOutline.root(childCount: 5)
        #expect(root.isRoot == true)
        #expect(root.hasChildren == true)
        #expect(root.childCount == 5)
        #expect(root.totalCount == 5)
        #expect(root.objectType == "PDOutlines")
    }

    @Test("Root outline with no children")
    func rootNoChildren() {
        let root = ValidatedOutline.root(childCount: 0)
        #expect(root.isRoot == true)
        #expect(root.hasChildren == false)
        #expect(root.childCount == 0)
    }

    @Test("Item factory")
    func itemFactory() {
        let item = ValidatedOutline.item(title: "Chapter 2", depth: 0, hasDestination: true)
        #expect(item.title == "Chapter 2")
        #expect(item.depth == 0)
        #expect(item.hasDestination == true)
        #expect(item.hasTitle == true)
        #expect(item.hasNavigation == true)
        #expect(item.isLeaf == true)
        #expect(item.isAccessible == true)
    }

    @Test("Parent factory")
    func parentFactory() {
        let parent = ValidatedOutline.parent(title: "Part 1", childCount: 4, isOpen: true)
        #expect(parent.title == "Part 1")
        #expect(parent.hasChildren == true)
        #expect(parent.childCount == 4)
        #expect(parent.isOpen == true)
        #expect(parent.totalCount == 4)
        #expect(parent.isLeaf == false)
    }

    @Test("Closed parent has negative total count")
    func closedParent() {
        let parent = ValidatedOutline.parent(title: "Part 2", childCount: 3, isOpen: false)
        #expect(parent.isOpen == false)
        #expect(parent.totalCount == -3)
        #expect(parent.visibleDescendantCount == 3)
    }

    @Test("Title detection")
    func titleDetection() {
        let withTitle = ValidatedOutline(title: "Introduction")
        #expect(withTitle.hasTitle == true)

        let emptyTitle = ValidatedOutline(title: "")
        #expect(emptyTitle.hasTitle == false)

        let noTitle = ValidatedOutline(title: nil)
        #expect(noTitle.hasTitle == false)
    }

    @Test("Navigation detection")
    func navigationDetection() {
        let withDest = ValidatedOutline(hasDestination: true)
        #expect(withDest.hasNavigation == true)

        let withAction = ValidatedOutline(hasAction: true)
        #expect(withAction.hasNavigation == true)

        let both = ValidatedOutline(hasDestination: true, hasAction: true)
        #expect(both.hasNavigation == true)

        let neither = ValidatedOutline()
        #expect(neither.hasNavigation == false)
    }

    @Test("Structure link detection")
    func structureLink() {
        let linked = ValidatedOutline(structureElementId: "se-42")
        #expect(linked.hasStructureLink == true)

        let unlinked = ValidatedOutline()
        #expect(unlinked.hasStructureLink == false)
    }

    @Test("Leaf detection")
    func leafDetection() {
        let leaf = ValidatedOutline(hasChildren: false, childCount: 0)
        #expect(leaf.isLeaf == true)

        let withChildren = ValidatedOutline(hasChildren: true, childCount: 3)
        #expect(withChildren.isLeaf == false)

        let childrenButZeroCount = ValidatedOutline(hasChildren: true, childCount: 0)
        #expect(childrenButZeroCount.isLeaf == true)
    }

    @Test("Accessibility check")
    func accessibility() {
        let accessible = ValidatedOutline(title: "Chapter 1", hasDestination: true)
        #expect(accessible.isAccessible == true)

        let noTitle = ValidatedOutline(hasDestination: true)
        #expect(noTitle.isAccessible == false)

        let noNav = ValidatedOutline(title: "Chapter 1")
        #expect(noNav.isAccessible == false)
    }

    @Test("Visible descendant count")
    func visibleDescendantCount() {
        let open = ValidatedOutline(totalCount: 10)
        #expect(open.visibleDescendantCount == 10)

        let closed = ValidatedOutline(totalCount: -10)
        #expect(closed.visibleDescendantCount == 10)

        let noCount = ValidatedOutline()
        #expect(noCount.visibleDescendantCount == 0)
    }

    @Test("Text formatting")
    func textFormatting() {
        let boldItalic = ValidatedOutline(
            title: "Important",
            isBold: true,
            isItalic: true,
            hasColor: true,
            colorComponentCount: 3
        )
        #expect(boldItalic.isBold == true)
        #expect(boldItalic.isItalic == true)
        #expect(boldItalic.hasColor == true)
        #expect(boldItalic.colorComponentCount == 3)
    }

    @Test("Action type")
    func actionType() {
        let withAction = ValidatedOutline(hasAction: true, actionType: "GoTo")
        #expect(withAction.actionType == "GoTo")

        let noAction = ValidatedOutline()
        #expect(noAction.actionType == nil)
    }

    @Test("Destination name")
    func destinationName() {
        let named = ValidatedOutline(hasDestination: true, destinationName: "page5")
        #expect(named.destinationName == "page5")
    }

    @Test("Object type changes for root vs item")
    func objectType() {
        let root = ValidatedOutline(isRoot: true)
        #expect(root.objectType == "PDOutlines")

        let item = ValidatedOutline(isRoot: false)
        #expect(item.objectType == "PDOutlineItem")
    }

    @Test("Property access")
    func propertyAccess() {
        let item = ValidatedOutline(
            title: "Chapter 3",
            hasDestination: true,
            destinationName: "ch3",
            hasAction: false,
            hasChildren: true,
            childCount: 2,
            totalCount: 5,
            isOpen: true,
            depth: 1,
            isBold: true,
            isItalic: false,
            structureElementId: "se-10"
        )
        #expect(item.property(named: "title")?.stringValue == "Chapter 3")
        #expect(item.property(named: "hasDestination")?.boolValue == true)
        #expect(item.property(named: "destinationName")?.stringValue == "ch3")
        #expect(item.property(named: "hasAction")?.boolValue == false)
        #expect(item.property(named: "hasChildren")?.boolValue == true)
        #expect(item.property(named: "childCount")?.integerValue == 2)
        #expect(item.property(named: "totalCount")?.integerValue == 5)
        #expect(item.property(named: "isOpen")?.boolValue == true)
        #expect(item.property(named: "isRoot")?.boolValue == false)
        #expect(item.property(named: "depth")?.integerValue == 1)
        #expect(item.property(named: "isBold")?.boolValue == true)
        #expect(item.property(named: "isItalic")?.boolValue == false)
        #expect(item.property(named: "structureElementId")?.stringValue == "se-10")
        #expect(item.property(named: "hasTitle")?.boolValue == true)
        #expect(item.property(named: "hasNavigation")?.boolValue == true)
        #expect(item.property(named: "hasStructureLink")?.boolValue == true)
        #expect(item.property(named: "isLeaf")?.boolValue == false)
        #expect(item.property(named: "nonexistent") == nil)
    }

    @Test("Null property values for absent optional fields")
    func nullProperties() {
        let item = ValidatedOutline()
        #expect(item.property(named: "title")?.isNull == true)
        #expect(item.property(named: "destinationName")?.isNull == true)
        #expect(item.property(named: "actionType")?.isNull == true)
        #expect(item.property(named: "totalCount")?.isNull == true)
        #expect(item.property(named: "structureElementId")?.isNull == true)
    }

    @Test("Summary description for root")
    func summaryRoot() {
        let root = ValidatedOutline.root(childCount: 5)
        let s = root.summary
        #expect(s.contains("Outlines root"))
        #expect(s.contains("5 children"))
    }

    @Test("Summary description for item")
    func summaryItem() {
        let item = ValidatedOutline.item(title: "Chapter 1")
        let s = item.summary
        #expect(s.contains("'Chapter 1'"))
        #expect(s.contains("has dest"))
    }

    @Test("Equatable by ID")
    func equatable() {
        let id = UUID()
        let a = ValidatedOutline(id: id, title: "A")
        let b = ValidatedOutline(id: id, title: "B")
        let c = ValidatedOutline(title: "A")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("PropertyNames coverage")
    func propertyNames() {
        let item = ValidatedOutline.item(title: "Test")
        let names = item.propertyNames
        #expect(names.contains("title"))
        #expect(names.contains("hasNavigation"))
        #expect(names.contains("hasStructureLink"))
        #expect(names.contains("isLeaf"))
        for propName in names {
            let value = item.property(named: propName)
            #expect(value != nil)
        }
    }

    @Test("Full initialization with all properties")
    func fullInit() {
        let outline = ValidatedOutline(
            title: "Full Test",
            hasDestination: true,
            destinationName: "full",
            hasAction: true,
            actionType: "GoTo",
            hasChildren: true,
            childCount: 3,
            totalCount: 10,
            isOpen: true,
            isRoot: false,
            depth: 2,
            isBold: true,
            isItalic: true,
            hasColor: true,
            colorComponentCount: 3,
            structureElementId: "se-100"
        )
        #expect(outline.title == "Full Test")
        #expect(outline.hasDestination == true)
        #expect(outline.destinationName == "full")
        #expect(outline.hasAction == true)
        #expect(outline.actionType == "GoTo")
        #expect(outline.hasChildren == true)
        #expect(outline.childCount == 3)
        #expect(outline.totalCount == 10)
        #expect(outline.isOpen == true)
        #expect(outline.isRoot == false)
        #expect(outline.depth == 2)
        #expect(outline.isBold == true)
        #expect(outline.isItalic == true)
        #expect(outline.hasColor == true)
        #expect(outline.colorComponentCount == 3)
        #expect(outline.structureElementId == "se-100")
    }
}
