import Foundation

/// Enumeration of feature categories that can be extracted from PDF documents.
///
/// This enum categorizes the different types of features that the feature
/// extraction system can identify and report on. Each category represents
/// a distinct aspect of PDF document structure or content.
///
/// Corresponds to feature categories in veraPDF's feature reporting system.
public enum FeatureType: String, Sendable, Codable, CaseIterable, Hashable {

    // MARK: - Document Level Features

    /// Document-level information (info dictionary, document structure).
    case document

    /// PDF metadata (XMP, document info).
    case metadata

    /// PDF version and conformance information.
    case pdfVersion

    /// Document security and encryption settings.
    case encryption

    /// Digital signatures.
    case signatures

    /// Embedded files (attachments).
    case embeddedFiles

    /// Document outlines (bookmarks).
    case outlines

    /// Document actions (open actions, page actions).
    case actions

    // MARK: - Page Level Features

    /// Page-level features (dimensions, rotation, resources).
    case page

    /// Page content streams.
    case contentStream

    /// Page annotations.
    case annotation

    /// Form fields (AcroForm, XFA).
    case formField

    // MARK: - Resource Features

    /// Font features (type, encoding, embedding).
    case font

    /// Font program (embedded font data).
    case fontProgram

    /// Font descriptor information.
    case fontDescriptor

    /// Color space features.
    case colorSpace

    /// ICC color profiles.
    case iccProfile

    /// Image features (type, dimensions, compression).
    case image

    /// Extended graphics state features.
    case extGState

    /// Pattern features (tiling, shading).
    case pattern

    /// Shading features.
    case shading

    // MARK: - Structure Features

    /// Tagged structure (structure tree).
    case taggedStructure

    /// Structure element.
    case structureElement

    /// Role mapping.
    case roleMapping

    /// Output intents.
    case outputIntent

    // MARK: - Low-Level Features

    /// Cross-reference table features.
    case xref

    /// Stream features.
    case stream

    /// Low-level PDF object features.
    case object

    // MARK: - Properties

    /// A human-readable display name for this feature type.
    public var displayName: String {
        switch self {
        case .document: return "Document"
        case .metadata: return "Metadata"
        case .pdfVersion: return "PDF Version"
        case .encryption: return "Encryption"
        case .signatures: return "Digital Signatures"
        case .embeddedFiles: return "Embedded Files"
        case .outlines: return "Outlines"
        case .actions: return "Actions"
        case .page: return "Page"
        case .contentStream: return "Content Stream"
        case .annotation: return "Annotation"
        case .formField: return "Form Field"
        case .font: return "Font"
        case .fontProgram: return "Font Program"
        case .fontDescriptor: return "Font Descriptor"
        case .colorSpace: return "Color Space"
        case .iccProfile: return "ICC Profile"
        case .image: return "Image"
        case .extGState: return "Extended Graphics State"
        case .pattern: return "Pattern"
        case .shading: return "Shading"
        case .taggedStructure: return "Tagged Structure"
        case .structureElement: return "Structure Element"
        case .roleMapping: return "Role Mapping"
        case .outputIntent: return "Output Intent"
        case .xref: return "Cross-Reference"
        case .stream: return "Stream"
        case .object: return "PDF Object"
        }
    }

    /// The category grouping for this feature type.
    public var category: FeatureCategory {
        switch self {
        case .document, .metadata, .pdfVersion, .encryption, .signatures,
             .embeddedFiles, .outlines, .actions:
            return .document
        case .page, .contentStream, .annotation, .formField:
            return .page
        case .font, .fontProgram, .fontDescriptor, .colorSpace, .iccProfile,
             .image, .extGState, .pattern, .shading:
            return .resource
        case .taggedStructure, .structureElement, .roleMapping, .outputIntent:
            return .structure
        case .xref, .stream, .object:
            return .lowLevel
        }
    }

    /// Whether this feature type can have child features.
    public var canHaveChildren: Bool {
        switch self {
        case .document, .page, .font, .taggedStructure, .structureElement:
            return true
        default:
            return false
        }
    }

    /// The expected child feature types for this feature type.
    public var expectedChildTypes: [FeatureType] {
        switch self {
        case .document:
            return [.page, .font, .colorSpace, .image, .taggedStructure, .embeddedFiles]
        case .page:
            return [.contentStream, .annotation, .formField]
        case .font:
            return [.fontProgram, .fontDescriptor]
        case .taggedStructure:
            return [.structureElement, .roleMapping]
        case .structureElement:
            return [.structureElement]  // Can contain nested structure elements
        default:
            return []
        }
    }
}

// MARK: - Feature Category

/// High-level categories for grouping feature types.
public enum FeatureCategory: String, Sendable, Codable, CaseIterable, Hashable {

    /// Document-level features (metadata, security, etc.).
    case document

    /// Page-level features (content, annotations, etc.).
    case page

    /// Resource features (fonts, images, colors, etc.).
    case resource

    /// Structure features (tagging, accessibility).
    case structure

    /// Low-level PDF features (objects, streams, xref).
    case lowLevel

    /// A human-readable display name for this category.
    public var displayName: String {
        switch self {
        case .document: return "Document Level"
        case .page: return "Page Level"
        case .resource: return "Resources"
        case .structure: return "Structure"
        case .lowLevel: return "Low Level"
        }
    }

    /// The feature types that belong to this category.
    public var featureTypes: [FeatureType] {
        FeatureType.allCases.filter { $0.category == self }
    }
}

// MARK: - CustomStringConvertible

extension FeatureType: CustomStringConvertible {
    public var description: String {
        displayName
    }
}

extension FeatureCategory: CustomStringConvertible {
    public var description: String {
        displayName
    }
}
