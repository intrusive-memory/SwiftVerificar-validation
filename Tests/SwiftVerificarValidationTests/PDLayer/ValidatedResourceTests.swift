import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarParser

// MARK: - ValidatedResource Protocol Tests

@Suite("ValidatedResource Protocol")
struct ValidatedResourceProtocolTests {

    @Test("GenericValidatedResource conforms to ValidatedResource")
    func conformsToProtocol() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font
        )
        let asResource: any ValidatedResource = resource
        #expect(asResource.resourceName == ASAtom("F1"))
        #expect(asResource.resourceType == .font)
    }

    @Test("Default isReferenced is false")
    func defaultIsReferenced() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font
        )
        // GenericValidatedResource has its own stored property, test the default protocol behavior
        #expect(resource.isReferenced == false)
    }

    @Test("Default usedOnPages is empty")
    func defaultUsedOnPages() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font
        )
        #expect(resource.usedOnPages.isEmpty)
    }
}

// MARK: - GenericValidatedResource Tests

@Suite("GenericValidatedResource")
struct GenericValidatedResourceTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font
        )
        #expect(resource.resourceName == ASAtom("F1"))
        #expect(resource.resourceType == .font)
        #expect(resource.isReferenced == false)
        #expect(resource.usedOnPages.isEmpty)
        #expect(resource.subtype == nil)
        #expect(resource.metadata.isEmpty)
        #expect(resource.cosDictionary == nil)
        #expect(resource.objectKey == nil)
    }

    @Test("Full initialization")
    func fullInit() {
        let dict: COSValue = .dictionary([.type: .name(.font), .subtype: .name(ASAtom("Type1"))])
        let key = COSObjectKey(objectNumber: 10)
        let ctx = ObjectContext.font("Helvetica", page: 1)

        let resource = GenericValidatedResource(
            cosDictionary: dict,
            objectKey: key,
            context: ctx,
            resourceName: ASAtom("F1"),
            resourceType: .font,
            isReferenced: true,
            usedOnPages: [1, 3, 5],
            subtype: ASAtom("Type1"),
            metadata: ["baseFont": "Helvetica"]
        )

        #expect(resource.cosDictionary != nil)
        #expect(resource.objectKey == key)
        #expect(resource.validationContext.location == "Font")
        #expect(resource.resourceName == ASAtom("F1"))
        #expect(resource.resourceType == .font)
        #expect(resource.isReferenced == true)
        #expect(resource.usedOnPages == [1, 3, 5])
        #expect(resource.subtype == ASAtom("Type1"))
        #expect(resource.metadata["baseFont"] == "Helvetica")
    }

    // MARK: - PDFObject Conformance Tests

    @Test("Object type includes resource type")
    func objectTypeIncludesResourceType() {
        let font = GenericValidatedResource(resourceName: ASAtom("F1"), resourceType: .font)
        #expect(font.objectType == "PDFont")

        let xObj = GenericValidatedResource(resourceName: ASAtom("Im1"), resourceType: .xObject)
        #expect(xObj.objectType == "PDXObject")

        let cs = GenericValidatedResource(resourceName: ASAtom("CS0"), resourceType: .colorSpace)
        #expect(cs.objectType == "PDColorSpace")

        let gs = GenericValidatedResource(resourceName: ASAtom("GS0"), resourceType: .extGState)
        #expect(gs.objectType == "PDExtGState")
    }

    @Test("Property names include standard resource properties")
    func propertyNamesStandard() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font
        )
        let names = resource.propertyNames
        #expect(names.contains("resourceName"))
        #expect(names.contains("resourceType"))
        #expect(names.contains("isReferenced"))
        #expect(names.contains("usedOnPages"))
        #expect(names.contains("subtype"))
    }

    @Test("Property names include metadata keys")
    func propertyNamesIncludeMetadata() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font,
            metadata: ["baseFont": "Helvetica", "encoding": "WinAnsiEncoding"]
        )
        let names = resource.propertyNames
        #expect(names.contains("baseFont"))
        #expect(names.contains("encoding"))
    }

    // MARK: - Property Access Tests

    @Test("Property access - resourceName")
    func propertyResourceName() {
        let resource = GenericValidatedResource(resourceName: ASAtom("F1"), resourceType: .font)
        let value = resource.property(named: "resourceName")
        #expect(value?.stringValue == "F1")
    }

    @Test("Property access - resourceType")
    func propertyResourceType() {
        let resource = GenericValidatedResource(resourceName: ASAtom("F1"), resourceType: .font)
        let value = resource.property(named: "resourceType")
        #expect(value?.stringValue == "Font")
    }

    @Test("Property access - isReferenced")
    func propertyIsReferenced() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font,
            isReferenced: true
        )
        #expect(resource.property(named: "isReferenced")?.boolValue == true)
    }

    @Test("Property access - usedOnPages")
    func propertyUsedOnPages() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font,
            usedOnPages: [1, 2, 3]
        )
        let value = resource.property(named: "usedOnPages")
        #expect(value?.stringValue == "1,2,3")
    }

    @Test("Property access - subtype when present")
    func propertySubtypePresent() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font,
            subtype: ASAtom("TrueType")
        )
        let value = resource.property(named: "subtype")
        #expect(value?.stringValue == "TrueType")
    }

    @Test("Property access - subtype when absent")
    func propertySubtypeAbsent() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font
        )
        #expect(resource.property(named: "subtype")?.isNull == true)
    }

    @Test("Property access - metadata values")
    func propertyMetadata() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font,
            metadata: ["baseFont": "Helvetica"]
        )
        #expect(resource.property(named: "baseFont")?.stringValue == "Helvetica")
    }

    @Test("Property access - unknown property returns nil")
    func propertyUnknown() {
        let resource = GenericValidatedResource(
            resourceName: ASAtom("F1"),
            resourceType: .font
        )
        #expect(resource.property(named: "nonExistent") == nil)
    }

    // MARK: - Equatable Tests

    @Test("Resources with same ID are equal")
    func equalById() {
        let id = UUID()
        let r1 = GenericValidatedResource(id: id, resourceName: ASAtom("F1"), resourceType: .font)
        let r2 = GenericValidatedResource(id: id, resourceName: ASAtom("F2"), resourceType: .xObject)
        #expect(r1 == r2)
    }

    @Test("Resources with different IDs are not equal")
    func notEqualByDifferentId() {
        let r1 = GenericValidatedResource(resourceName: ASAtom("F1"), resourceType: .font)
        let r2 = GenericValidatedResource(resourceName: ASAtom("F1"), resourceType: .font)
        #expect(r1 != r2)
    }

    // MARK: - Sendable Tests

    @Test("GenericValidatedResource is Sendable")
    func isSendable() {
        let resource = GenericValidatedResource(resourceName: ASAtom("F1"), resourceType: .font)
        let sendable: any Sendable = resource
        #expect(sendable is GenericValidatedResource)
    }
}

// MARK: - ResourceCollection Tests

@Suite("ResourceCollection")
struct ResourceCollectionTests {

    let sampleResources: [GenericValidatedResource] = [
        GenericValidatedResource(resourceName: ASAtom("F1"), resourceType: .font, isReferenced: true),
        GenericValidatedResource(resourceName: ASAtom("F2"), resourceType: .font, isReferenced: false),
        GenericValidatedResource(resourceName: ASAtom("Im1"), resourceType: .xObject, isReferenced: true),
        GenericValidatedResource(resourceName: ASAtom("CS0"), resourceType: .colorSpace, isReferenced: true),
        GenericValidatedResource(resourceName: ASAtom("GS0"), resourceType: .extGState, isReferenced: false),
        GenericValidatedResource(resourceName: ASAtom("P0"), resourceType: .pattern, isReferenced: true),
        GenericValidatedResource(resourceName: ASAtom("Sh0"), resourceType: .shading, isReferenced: true),
        GenericValidatedResource(resourceName: ASAtom("MC0"), resourceType: .properties, isReferenced: true),
    ]

    @Test("Empty collection")
    func emptyCollection() {
        let collection = ResourceCollection()
        #expect(collection.isEmpty == true)
        #expect(collection.count == 0)
        #expect(collection.fonts.isEmpty)
    }

    @Test("Collection count")
    func collectionCount() {
        let collection = ResourceCollection(resources: sampleResources)
        #expect(collection.count == 8)
        #expect(collection.isEmpty == false)
    }

    @Test("Filter by type - fonts")
    func filterFonts() {
        let collection = ResourceCollection(resources: sampleResources)
        #expect(collection.fonts.count == 2)
    }

    @Test("Filter by type - xObjects")
    func filterXObjects() {
        let collection = ResourceCollection(resources: sampleResources)
        #expect(collection.xObjects.count == 1)
    }

    @Test("Filter by type - colorSpaces")
    func filterColorSpaces() {
        let collection = ResourceCollection(resources: sampleResources)
        #expect(collection.colorSpaces.count == 1)
    }

    @Test("Filter by type - extGStates")
    func filterExtGStates() {
        let collection = ResourceCollection(resources: sampleResources)
        #expect(collection.extGStates.count == 1)
    }

    @Test("Filter by type - patterns")
    func filterPatterns() {
        let collection = ResourceCollection(resources: sampleResources)
        #expect(collection.patterns.count == 1)
    }

    @Test("Filter by type - shadings")
    func filterShadings() {
        let collection = ResourceCollection(resources: sampleResources)
        #expect(collection.shadings.count == 1)
    }

    @Test("Filter by type - properties")
    func filterProperties() {
        let collection = ResourceCollection(resources: sampleResources)
        #expect(collection.properties.count == 1)
    }

    @Test("Lookup resource by name and type")
    func lookupResourceByNameAndType() {
        let collection = ResourceCollection(resources: sampleResources)
        let font = collection.resource(named: ASAtom("F1"), ofType: .font)
        #expect(font != nil)
        #expect(font?.resourceName == ASAtom("F1"))
    }

    @Test("Lookup missing resource returns nil")
    func lookupMissingResource() {
        let collection = ResourceCollection(resources: sampleResources)
        let missing = collection.resource(named: ASAtom("F99"), ofType: .font)
        #expect(missing == nil)
    }

    @Test("Lookup resource with wrong type returns nil")
    func lookupWrongType() {
        let collection = ResourceCollection(resources: sampleResources)
        let wrong = collection.resource(named: ASAtom("F1"), ofType: .xObject)
        #expect(wrong == nil)
    }

    @Test("Unreferenced resources")
    func unreferencedResources() {
        let collection = ResourceCollection(resources: sampleResources)
        let unreferenced = collection.unreferencedResources
        #expect(unreferenced.count == 2)
        // F2 and GS0 are unreferenced
        let names = unreferenced.map { $0.resourceName.stringValue }
        #expect(names.contains("F2"))
        #expect(names.contains("GS0"))
    }

    @Test("Resources of type method")
    func resourcesOfType() {
        let collection = ResourceCollection(resources: sampleResources)
        let shadings = collection.resources(ofType: .shading)
        #expect(shadings.count == 1)

        let procSets = collection.resources(ofType: .procSet)
        #expect(procSets.isEmpty)
    }

    // MARK: - Equatable Tests

    @Test("ResourceCollection is Equatable")
    func equatable() {
        let r1 = GenericValidatedResource(id: UUID(), resourceName: ASAtom("F1"), resourceType: .font)
        let c1 = ResourceCollection(resources: [r1])
        let c2 = ResourceCollection(resources: [r1])
        #expect(c1 == c2)
    }

    // MARK: - Sendable Tests

    @Test("ResourceCollection is Sendable")
    func isSendable() {
        let collection = ResourceCollection(resources: sampleResources)
        let sendable: any Sendable = collection
        #expect(sendable is ResourceCollection)
    }
}
