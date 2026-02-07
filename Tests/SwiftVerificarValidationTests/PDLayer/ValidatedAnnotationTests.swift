import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - ValidatedAnnotation Tests

@Suite("ValidatedAnnotation")
struct ValidatedAnnotationTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicPropertyTests {

        @Test("Default initialization with subtype")
        func defaultInit() {
            let annot = ValidatedAnnotation(subtypeName: "Link")
            #expect(annot.subtypeName == "Link")
            #expect(annot.annotationType == .link)
            #expect(annot.pageNumber == 1)
            #expect(annot.contents == nil)
            #expect(annot.annotationName == nil)
            #expect(annot.modificationDate == nil)
            #expect(annot.appearanceState == nil)
            #expect(annot.flags == [])
            #expect(!annot.hasBorderStyle)
            #expect(annot.borderWidth == nil)
            #expect(!annot.hasColor)
            #expect(annot.colorComponentCount == 0)
            #expect(!annot.hasAction)
            #expect(!annot.hasDestination)
            #expect(annot.actionType == nil)
            #expect(annot.fieldType == nil)
            #expect(annot.fieldName == nil)
            #expect(!annot.hasFieldValue)
            #expect(!annot.hasDefaultValue)
            #expect(!annot.hasPopup)
            #expect(!annot.isOpen)
            #expect(annot.structParent == nil)
        }

        @Test("Annotation type is resolved from subtype name")
        func typeResolution() {
            let link = ValidatedAnnotation(subtypeName: "Link")
            #expect(link.annotationType == .link)

            let widget = ValidatedAnnotation(subtypeName: "Widget")
            #expect(widget.annotationType == .widget)

            let unknown = ValidatedAnnotation(subtypeName: "CustomAnnot")
            #expect(unknown.annotationType == nil)
        }

        @Test("Explicit annotation type overrides auto-resolution")
        func explicitType() {
            let annot = ValidatedAnnotation(
                subtypeName: "CustomLink",
                annotationType: .link
            )
            #expect(annot.subtypeName == "CustomLink")
            #expect(annot.annotationType == .link)
        }

        @Test("Object type is PDAnnot")
        func objectType() {
            let annot = ValidatedAnnotation(subtypeName: "Text")
            #expect(annot.objectType == "PDAnnot")
        }

        @Test("Default context uses annotation factory")
        func defaultContext() {
            let annot = ValidatedAnnotation(subtypeName: "Link", pageNumber: 3)
            #expect(annot.validationContext.location == "Annotation")
            #expect(annot.validationContext.role == "Link")
            #expect(annot.validationContext.pageNumber == 3)
        }

        @Test("Custom context is preserved")
        func customContext() {
            let ctx = ObjectContext(pageNumber: 5, location: "Custom")
            let annot = ValidatedAnnotation(context: ctx, subtypeName: "Text")
            #expect(annot.validationContext.pageNumber == 5)
            #expect(annot.validationContext.location == "Custom")
        }
    }

    // MARK: - Appearance Streams

    @Suite("Appearance Streams")
    struct AppearanceTests {

        @Test("No appearance streams by default")
        func noAppearance() {
            let annot = ValidatedAnnotation(subtypeName: "Link")
            #expect(!annot.appearanceStreams.hasNormalAppearance)
            #expect(!annot.appearanceStreams.hasRolloverAppearance)
            #expect(!annot.appearanceStreams.hasDownAppearance)
            #expect(!annot.appearanceStreams.hasAnyAppearance)
        }

        @Test("Normal appearance stream is detected")
        func normalAppearance() {
            let ap = AppearanceStreams(
                hasNormalAppearance: true,
                normalAppearanceCount: 1
            )
            let annot = ValidatedAnnotation(
                subtypeName: "Link",
                appearanceStreams: ap
            )
            #expect(annot.appearanceStreams.hasNormalAppearance)
            #expect(annot.appearanceStreams.hasAnyAppearance)
            #expect(annot.appearanceStreams.normalAppearanceCount == 1)
        }

        @Test("Multiple appearance streams detected")
        func multipleAppearances() {
            let ap = AppearanceStreams(
                hasNormalAppearance: true,
                hasRolloverAppearance: true,
                hasDownAppearance: true,
                normalAppearanceCount: 2,
                rolloverAppearanceCount: 1,
                downAppearanceCount: 1
            )
            #expect(ap.hasAnyAppearance)
            #expect(ap.normalAppearanceCount == 2)
            #expect(ap.rolloverAppearanceCount == 1)
            #expect(ap.downAppearanceCount == 1)
        }
    }

    // MARK: - Annotation Flags

    @Suite("Annotation Flags")
    struct FlagTests {

        @Test("Hidden flag")
        func hidden() {
            let annot = ValidatedAnnotation(
                subtypeName: "Text",
                flags: [.hidden]
            )
            #expect(annot.isHidden)
            #expect(!annot.isVisible)
        }

        @Test("Print flag")
        func printFlag() {
            let annot = ValidatedAnnotation(
                subtypeName: "Link",
                flags: [.print]
            )
            #expect(annot.isPrintable)
        }

        @Test("ReadOnly flag")
        func readOnly() {
            let annot = ValidatedAnnotation(
                subtypeName: "Widget",
                flags: [.readOnly]
            )
            #expect(annot.isReadOnly)
        }

        @Test("Locked flag")
        func locked() {
            let annot = ValidatedAnnotation(
                subtypeName: "Text",
                flags: [.locked]
            )
            #expect(annot.isLocked)
        }

        @Test("Invisible flag")
        func invisible() {
            let annot = ValidatedAnnotation(
                subtypeName: "Link",
                flags: [.invisible]
            )
            #expect(annot.isInvisible)
        }

        @Test("NoView flag")
        func noView() {
            let annot = ValidatedAnnotation(
                subtypeName: "Text",
                flags: [.noView]
            )
            #expect(annot.isNoView)
            #expect(!annot.isVisible)
        }

        @Test("Visible when not hidden and not noView")
        func visible() {
            let annot = ValidatedAnnotation(
                subtypeName: "Link",
                flags: [.print]
            )
            #expect(annot.isVisible)
        }

        @Test("Multiple flags combined")
        func multipleFlags() {
            let annot = ValidatedAnnotation(
                subtypeName: "Widget",
                flags: [.print, .readOnly, .locked]
            )
            #expect(annot.isPrintable)
            #expect(annot.isReadOnly)
            #expect(annot.isLocked)
            #expect(!annot.isHidden)
            #expect(annot.isVisible)
        }
    }

    // MARK: - Computed Properties

    @Suite("Computed Properties")
    struct ComputedPropertyTests {

        @Test("hasContents returns false for nil")
        func noContents() {
            let annot = ValidatedAnnotation(subtypeName: "Link")
            #expect(!annot.hasContents)
        }

        @Test("hasContents returns false for empty string")
        func emptyContents() {
            let annot = ValidatedAnnotation(subtypeName: "Link", contents: "")
            #expect(!annot.hasContents)
        }

        @Test("hasContents returns true for non-empty string")
        func withContents() {
            let annot = ValidatedAnnotation(subtypeName: "Link", contents: "Click here")
            #expect(annot.hasContents)
        }

        @Test("hasStructParent")
        func structParent() {
            let withSP = ValidatedAnnotation(subtypeName: "Link", structParent: 5)
            #expect(withSP.hasStructParent)
            #expect(withSP.structParent == 5)

            let withoutSP = ValidatedAnnotation(subtypeName: "Link")
            #expect(!withoutSP.hasStructParent)
        }

        @Test("hasZeroSizeRect")
        func zeroSizeRect() {
            let zeroWidth = ValidatedAnnotation(
                subtypeName: "Link",
                rect: PDFRect(x: 0, y: 0, width: 0, height: 100)
            )
            #expect(zeroWidth.hasZeroSizeRect)

            let zeroHeight = ValidatedAnnotation(
                subtypeName: "Link",
                rect: PDFRect(x: 0, y: 0, width: 100, height: 0)
            )
            #expect(zeroHeight.hasZeroSizeRect)

            let normal = ValidatedAnnotation(
                subtypeName: "Link",
                rect: PDFRect(x: 0, y: 0, width: 100, height: 50)
            )
            #expect(!normal.hasZeroSizeRect)
        }

        @Test("isLinkAnnotation")
        func isLinkAnnotation() {
            #expect(ValidatedAnnotation(subtypeName: "Link").isLinkAnnotation)
            #expect(!ValidatedAnnotation(subtypeName: "Widget").isLinkAnnotation)
        }

        @Test("isWidgetAnnotation")
        func isWidgetAnnotation() {
            #expect(ValidatedAnnotation(subtypeName: "Widget").isWidgetAnnotation)
            #expect(!ValidatedAnnotation(subtypeName: "Link").isWidgetAnnotation)
        }

        @Test("isPopupAnnotation")
        func isPopupAnnotation() {
            #expect(ValidatedAnnotation(subtypeName: "Popup").isPopupAnnotation)
            #expect(!ValidatedAnnotation(subtypeName: "Text").isPopupAnnotation)
        }

        @Test("isMarkupAnnotation")
        func isMarkupAnnotation() {
            #expect(ValidatedAnnotation(subtypeName: "Highlight").isMarkupAnnotation)
            #expect(ValidatedAnnotation(subtypeName: "Text").isMarkupAnnotation)
            #expect(!ValidatedAnnotation(subtypeName: "Link").isMarkupAnnotation)
        }
    }

    // MARK: - PDF/A Appearance Requirement

    @Suite("PDF/A Appearance Requirement")
    struct AppearanceRequirementTests {

        @Test("Link without appearance fails requirement")
        func linkWithoutAP() {
            let annot = ValidatedAnnotation(subtypeName: "Link")
            #expect(annot.requiresAppearanceStream)
            #expect(!annot.meetsAppearanceRequirement)
        }

        @Test("Link with normal appearance meets requirement")
        func linkWithAP() {
            let annot = ValidatedAnnotation(
                subtypeName: "Link",
                appearanceStreams: AppearanceStreams(hasNormalAppearance: true)
            )
            #expect(annot.meetsAppearanceRequirement)
        }

        @Test("Popup does not require appearance")
        func popupNoRequirement() {
            let annot = ValidatedAnnotation(subtypeName: "Popup")
            #expect(!annot.requiresAppearanceStream)
            #expect(annot.meetsAppearanceRequirement)
        }

        @Test("Unknown type requires appearance by default")
        func unknownRequiresAP() {
            let annot = ValidatedAnnotation(subtypeName: "CustomAnnot")
            #expect(annot.requiresAppearanceStream)
        }
    }

    // MARK: - PDFObject Property Access

    @Suite("PDFObject Property Access")
    struct PropertyAccessTests {

        @Test("Property names are complete")
        func propertyNames() {
            let annot = ValidatedAnnotation(subtypeName: "Link")
            let names = annot.propertyNames
            #expect(names.contains("subtypeName"))
            #expect(names.contains("annotationType"))
            #expect(names.contains("contents"))
            #expect(names.contains("hasNormalAppearance"))
            #expect(names.contains("flags"))
            #expect(names.contains("pageNumber"))
            #expect(names.contains("isHidden"))
            #expect(names.contains("isPrintable"))
            #expect(names.contains("hasAction"))
            #expect(names.contains("hasDestination"))
            #expect(names.contains("fieldType"))
            #expect(names.contains("structParent"))
            #expect(names.contains("hasStructParent"))
            #expect(names.contains("hasContents"))
            #expect(names.contains("isVisible"))
            #expect(names.contains("requiresAppearanceStream"))
            #expect(names.contains("meetsAppearanceRequirement"))
        }

        @Test("String properties")
        func stringProperties() {
            let annot = ValidatedAnnotation(
                subtypeName: "Link",
                contents: "A link",
                annotationName: "annot1",
                modificationDate: "D:20240101",
                appearanceState: "On",
                actionType: "URI",
                fieldType: "Tx",
                fieldName: "name"
            )
            #expect(annot.property(named: "subtypeName") == .string("Link"))
            #expect(annot.property(named: "annotationType") == .string("Link"))
            #expect(annot.property(named: "contents") == .string("A link"))
            #expect(annot.property(named: "annotationName") == .string("annot1"))
            #expect(annot.property(named: "modificationDate") == .string("D:20240101"))
            #expect(annot.property(named: "appearanceState") == .string("On"))
            #expect(annot.property(named: "actionType") == .string("URI"))
            #expect(annot.property(named: "fieldType") == .string("Tx"))
            #expect(annot.property(named: "fieldName") == .string("name"))
        }

        @Test("Null properties")
        func nullProperties() {
            let annot = ValidatedAnnotation(subtypeName: "Link")
            #expect(annot.property(named: "contents") == .null)
            #expect(annot.property(named: "annotationName") == .null)
            #expect(annot.property(named: "modificationDate") == .null)
            #expect(annot.property(named: "appearanceState") == .null)
            #expect(annot.property(named: "actionType") == .null)
            #expect(annot.property(named: "fieldType") == .null)
            #expect(annot.property(named: "fieldName") == .null)
            #expect(annot.property(named: "borderWidth") == .null)
            #expect(annot.property(named: "structParent") == .null)
        }

        @Test("Boolean properties")
        func booleanProperties() {
            let annot = ValidatedAnnotation(
                subtypeName: "Widget",
                appearanceStreams: AppearanceStreams(
                    hasNormalAppearance: true,
                    hasRolloverAppearance: false,
                    hasDownAppearance: true
                ),
                flags: [.print, .readOnly],
                hasBorderStyle: true,
                hasColor: true,
                hasAction: true,
                hasDestination: true,
                hasFieldValue: true,
                hasDefaultValue: true,
                hasPopup: true,
                isOpen: true,
                structParent: 3
            )
            #expect(annot.property(named: "hasNormalAppearance") == .boolean(true))
            #expect(annot.property(named: "hasRolloverAppearance") == .boolean(false))
            #expect(annot.property(named: "hasDownAppearance") == .boolean(true))
            #expect(annot.property(named: "hasAnyAppearance") == .boolean(true))
            #expect(annot.property(named: "isPrintable") == .boolean(true))
            #expect(annot.property(named: "isReadOnly") == .boolean(true))
            #expect(annot.property(named: "isHidden") == .boolean(false))
            #expect(annot.property(named: "hasBorderStyle") == .boolean(true))
            #expect(annot.property(named: "hasColor") == .boolean(true))
            #expect(annot.property(named: "hasAction") == .boolean(true))
            #expect(annot.property(named: "hasDestination") == .boolean(true))
            #expect(annot.property(named: "hasFieldValue") == .boolean(true))
            #expect(annot.property(named: "hasDefaultValue") == .boolean(true))
            #expect(annot.property(named: "hasPopup") == .boolean(true))
            #expect(annot.property(named: "isOpen") == .boolean(true))
            #expect(annot.property(named: "hasStructParent") == .boolean(true))
            #expect(annot.property(named: "hasContents") == .boolean(false))
            #expect(annot.property(named: "isVisible") == .boolean(true))
        }

        @Test("Integer and real properties")
        func numericProperties() {
            let annot = ValidatedAnnotation(
                subtypeName: "Link",
                flags: [.print, .readOnly],
                pageNumber: 5,
                borderWidth: 1.5,
                colorComponentCount: 3,
                structParent: 7
            )
            #expect(annot.property(named: "flags") == .integer(Int64(AnnotationFlags([.print, .readOnly]).rawValue)))
            #expect(annot.property(named: "pageNumber") == .integer(5))
            #expect(annot.property(named: "borderWidth") == .real(1.5))
            #expect(annot.property(named: "colorComponentCount") == .integer(3))
            #expect(annot.property(named: "structParent") == .integer(7))
        }

        @Test("Unknown type returns null for annotationType")
        func unknownType() {
            let annot = ValidatedAnnotation(subtypeName: "CustomAnnot")
            #expect(annot.property(named: "annotationType") == .null)
        }

        @Test("Unknown property returns nil")
        func unknownProperty() {
            let annot = ValidatedAnnotation(subtypeName: "Link")
            #expect(annot.property(named: "nonexistent") == nil)
        }
    }

    // MARK: - Summary

    @Suite("Summary")
    struct SummaryTests {

        @Test("Summary includes subtype and page")
        func basicSummary() {
            let annot = ValidatedAnnotation(subtypeName: "Link", pageNumber: 3)
            let summary = annot.summary
            #expect(summary.contains("Link"))
            #expect(summary.contains("page 3"))
        }

        @Test("Summary includes contents when present")
        func withContents() {
            let annot = ValidatedAnnotation(subtypeName: "Text", contents: "A note")
            #expect(annot.summary.contains("has contents"))
        }

        @Test("Summary includes appearance info")
        func withAppearance() {
            let annot = ValidatedAnnotation(
                subtypeName: "Link",
                appearanceStreams: AppearanceStreams(hasNormalAppearance: true)
            )
            #expect(annot.summary.contains("has AP"))
        }

        @Test("Summary includes field name for widgets")
        func widgetSummary() {
            let annot = ValidatedAnnotation(
                subtypeName: "Widget",
                fieldName: "email"
            )
            #expect(annot.summary.contains("field=email"))
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryTests {

        @Test("link() creates link annotation")
        func linkFactory() {
            let link = ValidatedAnnotation.link(
                pageNumber: 2,
                contents: "Go to page 5",
                hasDestination: true,
                structParent: 10
            )
            #expect(link.subtypeName == "Link")
            #expect(link.annotationType == .link)
            #expect(link.pageNumber == 2)
            #expect(link.contents == "Go to page 5")
            #expect(link.hasDestination)
            #expect(link.structParent == 10)
            #expect(link.appearanceStreams.hasNormalAppearance)
            #expect(link.isPrintable)
        }

        @Test("widget() creates widget annotation")
        func widgetFactory() {
            let widget = ValidatedAnnotation.widget(
                pageNumber: 1,
                fieldType: "Btn",
                fieldName: "submit"
            )
            #expect(widget.subtypeName == "Widget")
            #expect(widget.annotationType == .widget)
            #expect(widget.fieldType == "Btn")
            #expect(widget.fieldName == "submit")
            #expect(widget.appearanceStreams.hasNormalAppearance)
        }

        @Test("textNote() creates text annotation")
        func textNoteFactory() {
            let note = ValidatedAnnotation.textNote(
                pageNumber: 3,
                contents: "Review this section"
            )
            #expect(note.subtypeName == "Text")
            #expect(note.annotationType == .text)
            #expect(note.contents == "Review this section")
            #expect(note.pageNumber == 3)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Same ID means equal")
        func sameId() {
            let id = UUID()
            let annot1 = ValidatedAnnotation(id: id, subtypeName: "Link")
            let annot2 = ValidatedAnnotation(id: id, subtypeName: "Widget")
            #expect(annot1 == annot2)
        }

        @Test("Different ID means not equal")
        func differentId() {
            let annot1 = ValidatedAnnotation(subtypeName: "Link")
            let annot2 = ValidatedAnnotation(subtypeName: "Link")
            #expect(annot1 != annot2)
        }
    }
}
