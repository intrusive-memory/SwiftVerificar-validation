import Foundation
import Testing
@testable import SwiftVerificarValidation

// MARK: - AnnotationType Tests

@Suite("AnnotationType")
struct AnnotationTypeTests {

    // MARK: - Raw Values

    @Suite("Raw Values")
    struct RawValueTests {

        @Test("All annotation types have correct raw values")
        func rawValues() {
            #expect(AnnotationType.text.rawValue == "Text")
            #expect(AnnotationType.freeText.rawValue == "FreeText")
            #expect(AnnotationType.line.rawValue == "Line")
            #expect(AnnotationType.square.rawValue == "Square")
            #expect(AnnotationType.circle.rawValue == "Circle")
            #expect(AnnotationType.polygon.rawValue == "Polygon")
            #expect(AnnotationType.polyLine.rawValue == "PolyLine")
            #expect(AnnotationType.highlight.rawValue == "Highlight")
            #expect(AnnotationType.underline.rawValue == "Underline")
            #expect(AnnotationType.squiggly.rawValue == "Squiggly")
            #expect(AnnotationType.strikeOut.rawValue == "StrikeOut")
            #expect(AnnotationType.stamp.rawValue == "Stamp")
            #expect(AnnotationType.caret.rawValue == "Caret")
            #expect(AnnotationType.ink.rawValue == "Ink")
            #expect(AnnotationType.link.rawValue == "Link")
            #expect(AnnotationType.widget.rawValue == "Widget")
            #expect(AnnotationType.screen.rawValue == "Screen")
            #expect(AnnotationType.popup.rawValue == "Popup")
            #expect(AnnotationType.fileAttachment.rawValue == "FileAttachment")
            #expect(AnnotationType.sound.rawValue == "Sound")
            #expect(AnnotationType.movie.rawValue == "Movie")
            #expect(AnnotationType.richMedia.rawValue == "RichMedia")
            #expect(AnnotationType.printerMark.rawValue == "PrinterMark")
            #expect(AnnotationType.trapNet.rawValue == "TrapNet")
            #expect(AnnotationType.watermark.rawValue == "Watermark")
            #expect(AnnotationType.threeD.rawValue == "3D")
            #expect(AnnotationType.redact.rawValue == "Redact")
            #expect(AnnotationType.projection.rawValue == "Projection")
        }

        @Test("Total case count is 28")
        func caseCount() {
            #expect(AnnotationType.allCases.count == 28)
        }

        @Test("Creation from raw value works")
        func fromRawValue() {
            #expect(AnnotationType(rawValue: "Link") == .link)
            #expect(AnnotationType(rawValue: "Widget") == .widget)
            #expect(AnnotationType(rawValue: "3D") == .threeD)
            #expect(AnnotationType(rawValue: "Unknown") == nil)
        }

        @Test("from(subtype:) works")
        func fromSubtype() {
            #expect(AnnotationType.from(subtype: "Highlight") == .highlight)
            #expect(AnnotationType.from(subtype: "PopupAnnot") == nil)
        }
    }

    // MARK: - Category Classification

    @Suite("Category Classification")
    struct CategoryTests {

        @Test("Markup annotations are categorized correctly")
        func markupCategory() {
            let markupTypes: [AnnotationType] = [
                .text, .freeText, .line, .square, .circle, .polygon,
                .polyLine, .highlight, .underline, .squiggly, .strikeOut,
                .stamp, .caret, .ink, .redact
            ]
            for annotType in markupTypes {
                #expect(annotType.category == .markup, "Expected \(annotType) to be markup")
            }
        }

        @Test("Interactive annotations are categorized correctly")
        func interactiveCategory() {
            #expect(AnnotationType.link.category == .interactive)
            #expect(AnnotationType.widget.category == .interactive)
            #expect(AnnotationType.screen.category == .interactive)
        }

        @Test("Document annotations are categorized correctly")
        func documentCategory() {
            #expect(AnnotationType.popup.category == .document)
            #expect(AnnotationType.fileAttachment.category == .document)
            #expect(AnnotationType.sound.category == .document)
            #expect(AnnotationType.movie.category == .document)
            #expect(AnnotationType.richMedia.category == .document)
            #expect(AnnotationType.projection.category == .document)
        }

        @Test("Print annotations are categorized correctly")
        func printCategory() {
            #expect(AnnotationType.printerMark.category == .print)
            #expect(AnnotationType.trapNet.category == .print)
            #expect(AnnotationType.watermark.category == .print)
        }

        @Test("3D annotations are categorized correctly")
        func threeDCategory() {
            #expect(AnnotationType.threeD.category == .threeD)
        }
    }

    // MARK: - Semantic Properties

    @Suite("Semantic Properties")
    struct SemanticTests {

        @Test("isTextMarkup identifies text markup types")
        func isTextMarkup() {
            #expect(AnnotationType.highlight.isTextMarkup)
            #expect(AnnotationType.underline.isTextMarkup)
            #expect(AnnotationType.squiggly.isTextMarkup)
            #expect(AnnotationType.strikeOut.isTextMarkup)
            #expect(!AnnotationType.text.isTextMarkup)
            #expect(!AnnotationType.ink.isTextMarkup)
            #expect(!AnnotationType.link.isTextMarkup)
        }

        @Test("isMarkup identifies markup annotations")
        func isMarkup() {
            #expect(AnnotationType.text.isMarkup)
            #expect(AnnotationType.ink.isMarkup)
            #expect(AnnotationType.stamp.isMarkup)
            #expect(!AnnotationType.link.isMarkup)
            #expect(!AnnotationType.widget.isMarkup)
            #expect(!AnnotationType.popup.isMarkup)
        }

        @Test("isInteractive identifies interactive annotations")
        func isInteractive() {
            #expect(AnnotationType.link.isInteractive)
            #expect(AnnotationType.widget.isInteractive)
            #expect(AnnotationType.screen.isInteractive)
            #expect(!AnnotationType.text.isInteractive)
            #expect(!AnnotationType.popup.isInteractive)
        }

        @Test("isWidget identifies widget annotations")
        func isWidget() {
            #expect(AnnotationType.widget.isWidget)
            #expect(!AnnotationType.link.isWidget)
            #expect(!AnnotationType.text.isWidget)
        }

        @Test("isLink identifies link annotations")
        func isLink() {
            #expect(AnnotationType.link.isLink)
            #expect(!AnnotationType.widget.isLink)
        }

        @Test("isPopup identifies popup annotations")
        func isPopup() {
            #expect(AnnotationType.popup.isPopup)
            #expect(!AnnotationType.text.isPopup)
        }

        @Test("requiresAppearanceStream")
        func requiresAppearanceStream() {
            #expect(AnnotationType.link.requiresAppearanceStream)
            #expect(AnnotationType.widget.requiresAppearanceStream)
            #expect(AnnotationType.text.requiresAppearanceStream)
            #expect(AnnotationType.highlight.requiresAppearanceStream)
            #expect(!AnnotationType.popup.requiresAppearanceStream)
            #expect(!AnnotationType.printerMark.requiresAppearanceStream)
        }

        @Test("isAccessibilityRelevant")
        func isAccessibilityRelevant() {
            #expect(AnnotationType.link.isAccessibilityRelevant)
            #expect(AnnotationType.widget.isAccessibilityRelevant)
            #expect(AnnotationType.screen.isAccessibilityRelevant)
            #expect(AnnotationType.text.isAccessibilityRelevant)
            #expect(AnnotationType.fileAttachment.isAccessibilityRelevant)
            #expect(!AnnotationType.highlight.isAccessibilityRelevant)
            #expect(!AnnotationType.ink.isAccessibilityRelevant)
            #expect(!AnnotationType.popup.isAccessibilityRelevant)
        }

        @Test("isMultimedia identifies multimedia annotations")
        func isMultimedia() {
            #expect(AnnotationType.sound.isMultimedia)
            #expect(AnnotationType.movie.isMultimedia)
            #expect(AnnotationType.richMedia.isMultimedia)
            #expect(AnnotationType.screen.isMultimedia)
            #expect(!AnnotationType.link.isMultimedia)
            #expect(!AnnotationType.text.isMultimedia)
        }

        @Test("isPDF2Only identifies PDF 2.0 annotations")
        func isPDF2Only() {
            #expect(AnnotationType.richMedia.isPDF2Only)
            #expect(AnnotationType.redact.isPDF2Only)
            #expect(AnnotationType.projection.isPDF2Only)
            #expect(!AnnotationType.link.isPDF2Only)
            #expect(!AnnotationType.text.isPDF2Only)
            #expect(!AnnotationType.widget.isPDF2Only)
        }

        @Test("isTypicallyVisible")
        func isTypicallyVisible() {
            #expect(AnnotationType.link.isTypicallyVisible)
            #expect(AnnotationType.text.isTypicallyVisible)
            #expect(AnnotationType.widget.isTypicallyVisible)
            #expect(!AnnotationType.popup.isTypicallyVisible)
            #expect(!AnnotationType.printerMark.isTypicallyVisible)
            #expect(!AnnotationType.trapNet.isTypicallyVisible)
        }
    }

    // MARK: - Collection Helpers

    @Suite("Collection Helpers")
    struct CollectionTests {

        @Test("allMarkupTypes returns correct types")
        func allMarkupTypes() {
            let markupTypes = AnnotationType.allMarkupTypes
            #expect(markupTypes.count == 15)
            let allAreMarkup = markupTypes.allSatisfy { $0.isMarkup }
            #expect(allAreMarkup)
        }

        @Test("allTextMarkupTypes returns 4 types")
        func allTextMarkupTypes() {
            let textMarkups = AnnotationType.allTextMarkupTypes
            #expect(textMarkups.count == 4)
            #expect(textMarkups.contains(.highlight))
            #expect(textMarkups.contains(.underline))
            #expect(textMarkups.contains(.squiggly))
            #expect(textMarkups.contains(.strikeOut))
        }

        @Test("allInteractiveTypes returns 3 types")
        func allInteractiveTypes() {
            let interactive = AnnotationType.allInteractiveTypes
            #expect(interactive.count == 3)
            #expect(interactive.contains(.link))
            #expect(interactive.contains(.widget))
            #expect(interactive.contains(.screen))
        }

        @Test("typesRequiringAppearanceStream excludes popup and printerMark")
        func typesRequiringAppearance() {
            let types = AnnotationType.typesRequiringAppearanceStream
            #expect(!types.contains(.popup))
            #expect(!types.contains(.printerMark))
            #expect(types.contains(.link))
            #expect(types.contains(.widget))
        }
    }

    // MARK: - Description

    @Suite("Description")
    struct DescriptionTests {

        @Test("description returns raw value")
        func description() {
            #expect(AnnotationType.link.description == "Link")
            #expect(AnnotationType.threeD.description == "3D")
            #expect(AnnotationType.freeText.description == "FreeText")
        }
    }

    // MARK: - Codable

    @Suite("Codable")
    struct CodableTests {

        @Test("Encodes and decodes correctly")
        func codable() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let original = AnnotationType.highlight
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(AnnotationType.self, from: data)
            #expect(decoded == original)
        }

        @Test("Multiple cases round-trip through Codable")
        func multipleRoundTrip() throws {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let testCases: [AnnotationType] = [.link, .widget, .text, .highlight, .threeD, .redact]
            for annotType in testCases {
                let data = try encoder.encode(annotType)
                let decoded = try decoder.decode(AnnotationType.self, from: data)
                #expect(decoded == annotType, "Round-trip failed for \(annotType)")
            }
        }
    }

    // MARK: - Hashable

    @Suite("Hashable")
    struct HashableTests {

        @Test("Can be used as dictionary key")
        func dictionaryKey() {
            var dict: [AnnotationType: String] = [:]
            dict[.link] = "Link annotation"
            dict[.widget] = "Widget annotation"
            #expect(dict[.link] == "Link annotation")
            #expect(dict[.widget] == "Widget annotation")
            #expect(dict[.text] == nil)
        }

        @Test("Can be used in a Set")
        func setMembership() {
            let types: Set<AnnotationType> = [.link, .widget, .text, .link]
            #expect(types.count == 3)
        }
    }
}
