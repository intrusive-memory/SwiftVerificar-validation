import Testing
import Foundation
@testable import SwiftVerificarValidation

@Suite("ObjectContext Tests")
struct ObjectContextTests {

    @Test("ObjectContext default initialization")
    func defaultInitialization() {
        let context = ObjectContext()

        #expect(context.pageNumber == nil)
        #expect(context.location == nil)
        #expect(context.role == nil)
        #expect(context.metadata.isEmpty)
    }

    @Test("ObjectContext with page number")
    func withPageNumber() {
        let context = ObjectContext(pageNumber: 5)

        #expect(context.pageNumber == 5)
        #expect(context.location == nil)
        #expect(context.role == nil)
    }

    @Test("ObjectContext with location")
    func withLocation() {
        let context = ObjectContext(location: "ContentStream")

        #expect(context.pageNumber == nil)
        #expect(context.location == "ContentStream")
        #expect(context.role == nil)
    }

    @Test("ObjectContext with role")
    func withRole() {
        let context = ObjectContext(role: "Title Font")

        #expect(context.pageNumber == nil)
        #expect(context.location == nil)
        #expect(context.role == "Title Font")
    }

    @Test("ObjectContext with metadata")
    func withMetadata() {
        let metadata = ["key1": "value1", "key2": "value2"]
        let context = ObjectContext(metadata: metadata)

        #expect(context.metadata.count == 2)
        #expect(context.metadata["key1"] == "value1")
        #expect(context.metadata["key2"] == "value2")
    }

    @Test("ObjectContext with all properties")
    func withAllProperties() {
        let context = ObjectContext(
            pageNumber: 3,
            location: "Annotation",
            role: "Link",
            metadata: ["url": "https://example.com"]
        )

        #expect(context.pageNumber == 3)
        #expect(context.location == "Annotation")
        #expect(context.role == "Link")
        #expect(context.metadata["url"] == "https://example.com")
    }

    @Test("ObjectContext withPage builder")
    func withPageBuilder() {
        let original = ObjectContext(location: "Font", role: "Helvetica")
        let modified = original.withPage(7)

        #expect(modified.pageNumber == 7)
        #expect(modified.location == "Font")
        #expect(modified.role == "Helvetica")
    }

    @Test("ObjectContext withLocation builder")
    func withLocationBuilder() {
        let original = ObjectContext(pageNumber: 2, role: "Header")
        let modified = original.withLocation("ContentStream")

        #expect(modified.pageNumber == 2)
        #expect(modified.location == "ContentStream")
        #expect(modified.role == "Header")
    }

    @Test("ObjectContext withRole builder")
    func withRoleBuilder() {
        let original = ObjectContext(pageNumber: 4, location: "Font")
        let modified = original.withRole("Arial")

        #expect(modified.pageNumber == 4)
        #expect(modified.location == "Font")
        #expect(modified.role == "Arial")
    }

    @Test("ObjectContext withMetadata builder merges metadata")
    func withMetadataBuilderMerges() {
        let original = ObjectContext(metadata: ["existing": "value"])
        let modified = original.withMetadata(["new": "data", "another": "entry"])

        #expect(modified.metadata.count == 3)
        #expect(modified.metadata["existing"] == "value")
        #expect(modified.metadata["new"] == "data")
        #expect(modified.metadata["another"] == "entry")
    }

    @Test("ObjectContext withMetadata builder overwrites existing keys")
    func withMetadataBuilderOverwrites() {
        let original = ObjectContext(metadata: ["key": "oldValue"])
        let modified = original.withMetadata(["key": "newValue"])

        #expect(modified.metadata["key"] == "newValue")
    }

    @Test("ObjectContext withMetadata single entry")
    func withMetadataSingleEntry() {
        let original = ObjectContext()
        let modified = original.withMetadata(key: "fontName", value: "Times")

        #expect(modified.metadata["fontName"] == "Times")
    }

    @Test("ObjectContext description with no properties")
    func descriptionWithNoProperties() {
        let context = ObjectContext()
        #expect(context.description == "Unknown context")
    }

    @Test("ObjectContext description with page only")
    func descriptionWithPageOnly() {
        let context = ObjectContext(pageNumber: 5)
        #expect(context.description == "Page 5")
    }

    @Test("ObjectContext description with location only")
    func descriptionWithLocationOnly() {
        let context = ObjectContext(location: "ContentStream")
        #expect(context.description == "ContentStream")
    }

    @Test("ObjectContext description with role only")
    func descriptionWithRoleOnly() {
        let context = ObjectContext(role: "Title")
        #expect(context.description == "(Title)")
    }

    @Test("ObjectContext description with page and location")
    func descriptionWithPageAndLocation() {
        let context = ObjectContext(pageNumber: 3, location: "Annotation")
        #expect(context.description == "Page 3 Annotation")
    }

    @Test("ObjectContext description with all properties")
    func descriptionWithAllProperties() {
        let context = ObjectContext(
            pageNumber: 7,
            location: "Font",
            role: "Helvetica",
            metadata: ["encoding": "WinAnsiEncoding"]
        )

        let desc = context.description
        #expect(desc.contains("Page 7"))
        #expect(desc.contains("Font"))
        #expect(desc.contains("(Helvetica)"))
        #expect(desc.contains("encoding=WinAnsiEncoding"))
    }

    @Test("ObjectContext description with metadata only")
    func descriptionWithMetadataOnly() {
        let context = ObjectContext(metadata: ["key": "value"])
        #expect(context.description.contains("key=value"))
    }

    @Test("ObjectContext description with multiple metadata entries sorted")
    func descriptionWithMultipleMetadataSorted() {
        let context = ObjectContext(metadata: ["zebra": "z", "apple": "a", "banana": "b"])
        let desc = context.description

        // Should be sorted alphabetically
        #expect(desc.contains("apple=a"))
        #expect(desc.contains("banana=b"))
        #expect(desc.contains("zebra=z"))

        // Check that apple comes before banana (alphabetically)
        if let appleRange = desc.range(of: "apple=a"),
           let bananaRange = desc.range(of: "banana=b") {
            #expect(appleRange.lowerBound < bananaRange.lowerBound)
        }
    }

    @Test("ObjectContext equality")
    func equality() {
        let context1 = ObjectContext(pageNumber: 5, location: "Font", role: "Arial")
        let context2 = ObjectContext(pageNumber: 5, location: "Font", role: "Arial")
        let context3 = ObjectContext(pageNumber: 6, location: "Font", role: "Arial")

        #expect(context1 == context2)
        #expect(context1 != context3)
    }

    @Test("ObjectContext equality with metadata")
    func equalityWithMetadata() {
        let context1 = ObjectContext(metadata: ["key": "value"])
        let context2 = ObjectContext(metadata: ["key": "value"])
        let context3 = ObjectContext(metadata: ["key": "different"])

        #expect(context1 == context2)
        #expect(context1 != context3)
    }
}

// MARK: - ObjectContext Factory Tests

@Suite("ObjectContext Factory Tests")
struct ObjectContextFactoryTests {

    @Test("Factory: document context")
    func documentContext() {
        let context = ObjectContext.document
        #expect(context.location == "Document")
    }

    @Test("Factory: catalog context")
    func catalogContext() {
        let context = ObjectContext.catalog
        #expect(context.location == "Catalog")
    }

    @Test("Factory: metadata context")
    func metadataContext() {
        let context = ObjectContext.metadata
        #expect(context.location == "Metadata")
    }

    @Test("Factory: page context")
    func pageContext() {
        let context = ObjectContext.page(5)
        #expect(context.pageNumber == 5)
        #expect(context.location == "Page")
    }

    @Test("Factory: content stream context")
    func contentStreamContext() {
        let context = ObjectContext.contentStream(page: 3)
        #expect(context.pageNumber == 3)
        #expect(context.location == "ContentStream")
    }

    @Test("Factory: annotation context")
    func annotationContext() {
        let context = ObjectContext.annotation(page: 7, type: "Link")
        #expect(context.pageNumber == 7)
        #expect(context.location == "Annotation")
        #expect(context.role == "Link")
    }

    @Test("Factory: font context without page")
    func fontContextWithoutPage() {
        let context = ObjectContext.font("Helvetica")
        #expect(context.pageNumber == nil)
        #expect(context.location == "Font")
        #expect(context.role == "Helvetica")
    }

    @Test("Factory: font context with page")
    func fontContextWithPage() {
        let context = ObjectContext.font("Arial", page: 4)
        #expect(context.pageNumber == 4)
        #expect(context.location == "Font")
        #expect(context.role == "Arial")
    }

    @Test("Factory: color space context without page")
    func colorSpaceContextWithoutPage() {
        let context = ObjectContext.colorSpace("DeviceRGB")
        #expect(context.pageNumber == nil)
        #expect(context.location == "ColorSpace")
        #expect(context.role == "DeviceRGB")
    }

    @Test("Factory: color space context with page")
    func colorSpaceContextWithPage() {
        let context = ObjectContext.colorSpace("ICCBased", page: 2)
        #expect(context.pageNumber == 2)
        #expect(context.location == "ColorSpace")
        #expect(context.role == "ICCBased")
    }

    @Test("Factory: structure element context")
    func structureElementContext() {
        let context = ObjectContext.structureElement("P")
        #expect(context.location == "StructureElement")
        #expect(context.role == "P")
    }

    @Test("Factory: form field context")
    func formFieldContext() {
        let context = ObjectContext.formField("TextField1")
        #expect(context.location == "FormField")
        #expect(context.role == "TextField1")
    }

    @Test("Factory: image context")
    func imageContext() {
        let context = ObjectContext.image(page: 9)
        #expect(context.pageNumber == 9)
        #expect(context.location == "Image")
    }
}

// MARK: - ObjectContext Builder Chain Tests

@Suite("ObjectContext Builder Chain Tests")
struct ObjectContextBuilderChainTests {

    @Test("Chain multiple builders")
    func chainMultipleBuilders() {
        let context = ObjectContext()
            .withPage(5)
            .withLocation("Font")
            .withRole("Helvetica")
            .withMetadata(key: "encoding", value: "UTF-8")

        #expect(context.pageNumber == 5)
        #expect(context.location == "Font")
        #expect(context.role == "Helvetica")
        #expect(context.metadata["encoding"] == "UTF-8")
    }

    @Test("Build from factory and modify")
    func buildFromFactoryAndModify() {
        let context = ObjectContext.page(3)
            .withLocation("ContentStream")
            .withMetadata(["operator": "Tj"])

        #expect(context.pageNumber == 3)
        #expect(context.location == "ContentStream")
        #expect(context.metadata["operator"] == "Tj")
    }

    @Test("Builder chain preserves immutability")
    func builderChainPreservesImmutability() {
        let original = ObjectContext(pageNumber: 1, location: "Original")
        let modified = original.withPage(2)

        // Original should be unchanged
        #expect(original.pageNumber == 1)
        #expect(original.location == "Original")

        // Modified should have new values
        #expect(modified.pageNumber == 2)
        #expect(modified.location == "Original")
    }
}
