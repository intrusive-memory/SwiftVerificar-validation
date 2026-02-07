import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - FeatureType Tests

@Suite("FeatureType Tests")
struct FeatureTypeTests {

    // MARK: - Basic Properties

    @Test("All feature types have unique raw values")
    func uniqueRawValues() {
        let rawValues = FeatureType.allCases.map(\.rawValue)
        let uniqueValues = Set(rawValues)
        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("All feature types have display names")
    func displayNames() {
        for featureType in FeatureType.allCases {
            #expect(!featureType.displayName.isEmpty)
        }
    }

    @Test("All feature types have categories")
    func categories() {
        for featureType in FeatureType.allCases {
            #expect(FeatureCategory.allCases.contains(featureType.category))
        }
    }

    // MARK: - Document Level Features

    @Test("Document feature type properties")
    func documentFeatureType() {
        let docType = FeatureType.document
        #expect(docType.displayName == "Document")
        #expect(docType.category == .document)
        #expect(docType.canHaveChildren == true)
        #expect(docType.expectedChildTypes.contains(.page))
    }

    @Test("Metadata feature type properties")
    func metadataFeatureType() {
        let metaType = FeatureType.metadata
        #expect(metaType.displayName == "Metadata")
        #expect(metaType.category == .document)
        #expect(metaType.canHaveChildren == false)
    }

    @Test("PDF version feature type properties")
    func pdfVersionFeatureType() {
        let versionType = FeatureType.pdfVersion
        #expect(versionType.displayName == "PDF Version")
        #expect(versionType.category == .document)
    }

    // MARK: - Page Level Features

    @Test("Page feature type properties")
    func pageFeatureType() {
        let pageType = FeatureType.page
        #expect(pageType.displayName == "Page")
        #expect(pageType.category == .page)
        #expect(pageType.canHaveChildren == true)
        #expect(pageType.expectedChildTypes.contains(.contentStream))
        #expect(pageType.expectedChildTypes.contains(.annotation))
    }

    @Test("Annotation feature type properties")
    func annotationFeatureType() {
        let annotType = FeatureType.annotation
        #expect(annotType.displayName == "Annotation")
        #expect(annotType.category == .page)
    }

    @Test("Form field feature type properties")
    func formFieldFeatureType() {
        let formType = FeatureType.formField
        #expect(formType.displayName == "Form Field")
        #expect(formType.category == .page)
    }

    // MARK: - Resource Features

    @Test("Font feature type properties")
    func fontFeatureType() {
        let fontType = FeatureType.font
        #expect(fontType.displayName == "Font")
        #expect(fontType.category == .resource)
        #expect(fontType.canHaveChildren == true)
        #expect(fontType.expectedChildTypes.contains(.fontProgram))
        #expect(fontType.expectedChildTypes.contains(.fontDescriptor))
    }

    @Test("Image feature type properties")
    func imageFeatureType() {
        let imageType = FeatureType.image
        #expect(imageType.displayName == "Image")
        #expect(imageType.category == .resource)
    }

    @Test("Color space feature type properties")
    func colorSpaceFeatureType() {
        let csType = FeatureType.colorSpace
        #expect(csType.displayName == "Color Space")
        #expect(csType.category == .resource)
    }

    @Test("ICC profile feature type properties")
    func iccProfileFeatureType() {
        let iccType = FeatureType.iccProfile
        #expect(iccType.displayName == "ICC Profile")
        #expect(iccType.category == .resource)
    }

    // MARK: - Structure Features

    @Test("Tagged structure feature type properties")
    func taggedStructureFeatureType() {
        let tagType = FeatureType.taggedStructure
        #expect(tagType.displayName == "Tagged Structure")
        #expect(tagType.category == .structure)
        #expect(tagType.canHaveChildren == true)
    }

    @Test("Structure element feature type properties")
    func structureElementFeatureType() {
        let elemType = FeatureType.structureElement
        #expect(elemType.displayName == "Structure Element")
        #expect(elemType.category == .structure)
        #expect(elemType.canHaveChildren == true)
        #expect(elemType.expectedChildTypes.contains(.structureElement))
    }

    // MARK: - Low Level Features

    @Test("XRef feature type properties")
    func xrefFeatureType() {
        let xrefType = FeatureType.xref
        #expect(xrefType.displayName == "Cross-Reference")
        #expect(xrefType.category == .lowLevel)
    }

    @Test("Stream feature type properties")
    func streamFeatureType() {
        let streamType = FeatureType.stream
        #expect(streamType.displayName == "Stream")
        #expect(streamType.category == .lowLevel)
    }

    // MARK: - CustomStringConvertible

    @Test("Feature type description equals display name")
    func descriptionEqualsDisplayName() {
        for featureType in FeatureType.allCases {
            #expect(featureType.description == featureType.displayName)
        }
    }

    // MARK: - Codable

    @Test("Feature type is codable")
    func featureTypeIsCodable() throws {
        let original = FeatureType.document
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FeatureType.self, from: data)
        #expect(decoded == original)
    }

    @Test("All feature types are codable")
    func allFeatureTypesAreCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for featureType in FeatureType.allCases {
            let data = try encoder.encode(featureType)
            let decoded = try decoder.decode(FeatureType.self, from: data)
            #expect(decoded == featureType)
        }
    }
}

// MARK: - FeatureCategory Tests

@Suite("FeatureCategory Tests")
struct FeatureCategoryTests {

    @Test("All categories have unique raw values")
    func uniqueRawValues() {
        let rawValues = FeatureCategory.allCases.map(\.rawValue)
        let uniqueValues = Set(rawValues)
        #expect(rawValues.count == uniqueValues.count)
    }

    @Test("All categories have display names")
    func displayNames() {
        for category in FeatureCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    @Test("Document category contains document features")
    func documentCategoryFeatures() {
        let features = FeatureCategory.document.featureTypes
        #expect(features.contains(.document))
        #expect(features.contains(.metadata))
        #expect(features.contains(.pdfVersion))
        #expect(features.contains(.encryption))
    }

    @Test("Page category contains page features")
    func pageCategoryFeatures() {
        let features = FeatureCategory.page.featureTypes
        #expect(features.contains(.page))
        #expect(features.contains(.contentStream))
        #expect(features.contains(.annotation))
        #expect(features.contains(.formField))
    }

    @Test("Resource category contains resource features")
    func resourceCategoryFeatures() {
        let features = FeatureCategory.resource.featureTypes
        #expect(features.contains(.font))
        #expect(features.contains(.image))
        #expect(features.contains(.colorSpace))
        #expect(features.contains(.iccProfile))
    }

    @Test("Structure category contains structure features")
    func structureCategoryFeatures() {
        let features = FeatureCategory.structure.featureTypes
        #expect(features.contains(.taggedStructure))
        #expect(features.contains(.structureElement))
        #expect(features.contains(.roleMapping))
        #expect(features.contains(.outputIntent))
    }

    @Test("Low level category contains low level features")
    func lowLevelCategoryFeatures() {
        let features = FeatureCategory.lowLevel.featureTypes
        #expect(features.contains(.xref))
        #expect(features.contains(.stream))
        #expect(features.contains(.object))
    }

    @Test("Category description equals display name")
    func descriptionEqualsDisplayName() {
        for category in FeatureCategory.allCases {
            #expect(category.description == category.displayName)
        }
    }

    @Test("Category is codable")
    func categoryIsCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for category in FeatureCategory.allCases {
            let data = try encoder.encode(category)
            let decoded = try decoder.decode(FeatureCategory.self, from: data)
            #expect(decoded == category)
        }
    }

    @Test("Every feature type belongs to exactly one category")
    func everyFeatureTypeHasCategory() {
        for featureType in FeatureType.allCases {
            var foundInCategories = 0
            for category in FeatureCategory.allCases {
                if category.featureTypes.contains(featureType) {
                    foundInCategories += 1
                }
            }
            #expect(foundInCategories == 1, "Feature type \(featureType) should be in exactly one category")
        }
    }
}
