# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-07

### Added
- Initial release of SwiftVerificarValidation
- Core validation: ValidationEngine protocol, ValidationResult, RuleResult, ValidationContext
- Rule execution: RuleExecutor, ObjectValidator, ProfileRuleEvaluator, EvaluationContext
- PDF/A validators: PDFA1/2/3/4Validator with conformance level support
- PDF/UA validators: PDFUA1/2Validator
- Object model: PDFObject protocol, ValidatedOperator enum (70 operators, 14 categories)
- PD validation: ValidatedDocument, ValidatedPage, ValidatedResource, ValidatedContentStream
- Structure types: StructureElementType enum (55 cases), ValidatedStructTreeRoot, ValidatedStructElem
- Annotation validation: AnnotationType (27 cases), ValidatedAnnotation, ValidatedAcroForm
- Font validation: FontValidation, FontSubtype, Type0/1/TrueType/CIDFont validation
- Color space validation: ColorSpaceFamily, DeviceGray/RGB/CMYK, ICCBased, CalGray/CalRGB
- External object validation: ICCProfile, JPEG2000, EmbeddedFile, PKCS validation
- Remaining PD types: OutputIntent, Action, Destination, OptionalContentGroup, Pattern, Shading, XObject, Outline
- SA layer: SAObject, SADocument, SAPage, SAStructureRoot, SANode, SAStructureElement
- Content analysis: ContentChunkContainer, ContentChunkFactory, WCAGValidationContext
- Serialization: SADocumentEncoder, SALayerHelpers, SAValidationReport
- Feature extraction: FeatureExtractor, FeatureType enum, FeatureNode, FeatureReport
- Metadata fixing: MetadataFixer, XMP schemas, InfoDictionary
- 3050+ tests with 90%+ coverage

[0.1.0]: https://github.com/intrusive-memory/SwiftVerificar-validation/releases/tag/v0.1.0
