# SwiftVerificar-validation Porting TODO

## Source Repository

**Source:** [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation)
**Branch:** `integration`
**License:** GPLv3+ / MPLv2+ (dual-licensed)

---

## Overview

This document provides a comprehensive porting plan for converting veraPDF-validation (~452 Java classes) to Swift. The validation module consists of 4 submodules:

1. **validation-model** (~315 classes) - PDF/A validation object model
2. **feature-reporting** (~27 classes) - PDF feature extraction
3. **metadata-fixer** (~10 classes) - XMP metadata repair
4. **wcag-validation** (~100 classes) - WCAG accessibility validation

### Swift Advantages to Leverage

- **Actors** for thread-safe validation state
- **Structured concurrency** for parallel rule evaluation
- **Result builders** for declarative rule definitions
- **Property wrappers** for lazy model loading
- **Protocol witnesses** instead of visitor pattern
- **Enums with associated values** for type-safe models

---

## Module 1: validation-model

### 1.1 Foundry and Factory System

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `VeraFoundry` | `ValidationFoundry` (actor) | Singleton factory |
| `VeraGreenfieldFoundryProvider` | Part of `ValidationFoundry` | Consolidate |
| `GFModelParser` | `ModelParser` (struct) | PDF/A parser |

**Swift Improvement:**
```swift
actor ValidationFoundry {
    static let shared = ValidationFoundry()

    func createValidator(profile: ValidationProfile) -> PDFValidator
    func createParser(for url: URL) async throws -> ParsedDocument
}
```

### 1.2 Static Containers → Actor

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `StaticContainers` (ThreadLocal) | `ValidationContext` (actor) | Thread-safe state |

**Swift Improvement:**
```swift
actor ValidationContext {
    var document: ParsedDocument?
    var colorSpaceCache: [COSObjectKey: PDFColorSpace] = [:]
    var fontCache: [COSObjectKey: PDFFont] = [:]
    var structureElementCache: [COSObjectKey: StructureElement] = [:]

    func reset() { /* clear all caches */ }
}
```

### 1.3 COS Layer Implementation (27 classes → ~10)

**Base Pattern:**
| Java Pattern | Swift Pattern |
|-------------|--------------|
| `GFCosObject` extends `GenericModelObject` | Conform to `ValidationObject` protocol |
| Implements model interfaces | Protocol conformance |

**Consolidation Strategy:**

The 27 `GFCos*` classes implement model interfaces. In Swift, use protocol conformance:

```swift
protocol CosValidationObject: ValidationObject {
    var cosValue: COSValue { get }
}

// Single implementation struct instead of 27 classes
struct CosObjectWrapper: CosValidationObject {
    let cosValue: COSValue
    let objectKey: COSObjectKey?

    // Computed properties based on cosValue type
    var stringValue: String? { /* ... */ }
    var integerValue: Int64? { /* ... */ }
}
```

| Java Classes (Consolidate) | Swift Equivalent |
|---------------------------|-----------------|
| `GFCosArray`, `GFCosDict`, `GFCosStream`, etc. | `CosObjectWrapper` (single struct) |
| `GFCosDocument` | `CosDocument` (struct) |
| `GFCosTrailer` | `CosTrailer` (struct) |

### 1.4 Operator Classes (97 classes → ~15)

**Massive Consolidation Opportunity:**

The 97 operator classes (e.g., `GFOp_g_fill`, `GFOp_BT`, `GFOp_Tj`) can be consolidated into a single enum with associated values:

```swift
enum ValidatedOperator: ValidationObject {
    // Color operators
    case setGrayFill(Double)
    case setGrayStroke(Double)
    case setRGBFill(Double, Double, Double)
    case setRGBStroke(Double, Double, Double)
    case setCMYKFill(Double, Double, Double, Double)
    case setCMYKStroke(Double, Double, Double, Double)
    case setColorSpaceFill(ASAtom)
    case setColorSpaceStroke(ASAtom)

    // Text operators
    case beginText
    case endText
    case setFont(ASAtom, Double)
    case setTextMatrix(CGAffineTransform)
    case showText(Data)
    case showTextWithPositioning([(Data, Double)])

    // Path operators
    case moveTo(CGPoint)
    case lineTo(CGPoint)
    case curveTo(CGPoint, CGPoint, CGPoint)
    case closePath
    case stroke
    case fill(FillRule)
    case fillAndStroke(FillRule)

    // Graphics state
    case saveState
    case restoreState
    case setLineWidth(Double)
    case setLineCap(LineCap)
    case setLineJoin(LineJoin)
    case setExtGState(ASAtom)

    // XObject
    case paintXObject(ASAtom)

    // Inline image
    case inlineImage(InlineImageData)

    // Marked content
    case beginMarkedContent(ASAtom, [ASAtom: COSValue]?)
    case endMarkedContent

    // ... etc.
}
```

This eliminates:
- 97 separate class files
- Complex inheritance hierarchy
- Visitor pattern for operator handling

### 1.5 PD Layer Implementation (120+ classes → ~60)

**Core Types:**

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `GFPDObject` | `PDValidationObject` (protocol) | Base protocol |
| `GFPDDocument` | `ValidatedDocument` (struct) | Document |
| `GFPDPage` | `ValidatedPage` (struct) | Page |
| `GFPDResource` | `ValidatedResource` (protocol) | Resource base |
| `GFPDAnnot` | `ValidatedAnnotation` (struct) | Annotation |
| `GFPDContentStream` | `ValidatedContentStream` (struct) | Content |
| `GFPDAcroForm` | `ValidatedAcroForm` (struct) | Form |
| `GFPDExtGState` | `ValidatedExtGState` (struct) | ExtGState |
| `GFPDMetadata` | `ValidatedMetadata` (struct) | XMP |
| `GFPDStructTreeRoot` | `ValidatedStructTreeRoot` (struct) | Structure root |
| `GFPDStructElem` | `ValidatedStructElem` (struct) | Structure element |

**Annotation Types (15 → Enum + Struct):**

```swift
enum AnnotationType {
    case link, widget, popup, markup, screen
    case fileAttachment, sound, movie, richMedia
    case ink, stamp, watermark, trapNet, printerMark, threeD
}

struct ValidatedAnnotation: ValidationObject {
    let type: AnnotationType
    let rect: CGRect
    let contents: String?
    let appearanceStreams: AppearanceStreams?
    // Common annotation properties

    // Type-specific data via associated properties
}
```

**Color Space Types (13 → Protocol + Structs):**

Keep separate structs but with shared protocol:

| Java Class | Swift Equivalent |
|------------|-----------------|
| `GFPDDeviceGray` | `DeviceGrayValidation` |
| `GFPDDeviceRGB` | `DeviceRGBValidation` |
| `GFPDDeviceCMYK` | `DeviceCMYKValidation` |
| `GFPDICCBased` | `ICCBasedValidation` |
| etc. | etc. |

**Font Types (11 → Protocol + Structs):**

| Java Class | Swift Equivalent |
|------------|-----------------|
| `GFPDFont` (abstract) | `FontValidation` (protocol) |
| `GFPDType0Font` | `Type0FontValidation` |
| `GFPDType1Font` | `Type1FontValidation` |
| `GFPDTrueTypeFont` | `TrueTypeFontValidation` |
| `GFPDCIDFont` | `CIDFontValidation` |
| etc. | etc. |

### 1.6 Structure Elements (58 classes → ~20)

**Major Consolidation:**

The 58 `GFSE*` classes (structure element types) can be consolidated:

```swift
enum StructureElementType: String, CaseIterable {
    // Document structure
    case document = "Document"
    case documentFragment = "DocumentFragment"
    case part = "Part"
    case sect = "Sect"
    case div = "Div"
    case aside = "Aside"
    case nonStruct = "NonStruct"

    // Block-level
    case paragraph = "P"
    case heading = "H"
    case h1, h2, h3, h4, h5, h6
    case blockQuote = "BlockQuote"

    // Lists
    case list = "L"
    case listItem = "LI"
    case label = "Lbl"
    case listBody = "LBody"

    // Tables
    case table = "Table"
    case tableRow = "TR"
    case tableHeader = "TH"
    case tableData = "TD"
    case tableHead = "THead"
    case tableBody = "TBody"
    case tableFoot = "TFoot"

    // Inline
    case span = "Span"
    case quote = "Quote"
    case note = "Note"
    case reference = "Reference"
    case bibEntry = "BibEntry"
    case code = "Code"
    case link = "Link"
    case annot = "Annot"

    // Illustration
    case figure = "Figure"
    case formula = "Formula"
    case form = "Form"

    // Ruby/Warichu
    case ruby = "Ruby"
    case rb = "RB"
    case rt = "RT"
    case rp = "RP"
    case warichu = "Warichu"
    case wt = "WT"
    case wp = "WP"

    // PDF 2.0 additions
    case feNote = "FENote"
    case em = "Em"
    case strong = "Strong"
    case sub = "Sub"
    case title = "Title"
    case artifact = "Artifact"
}

struct ValidatedStructureElement: ValidationObject {
    let type: StructureElementType
    let namespace: StructureNamespace?
    let children: [StructureChild]
    let attributes: AttributesDictionary
    let actualText: String?
    let altText: String?
    let lang: String?

    // Computed validation properties
    var isAccessibilityElement: Bool { /* ... */ }
    var needsAltText: Bool { type == .figure }
}
```

### 1.7 External Objects (10 → 5)

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `GFICCProfile` | `ICCProfileValidation` | ICC profile |
| `GFICCInputProfile` | Part of above | Consolidate |
| `GFICCOutputProfile` | Part of above | Consolidate |
| `GFFontProgram` | `FontProgramValidation` | Font program |
| `GFTrueTypeFontProgram` | Part of above | Consolidate |
| `GFCMapFile` | `CMapValidation` | CMap file |
| `GFJPEG2000` | `JPEG2000Validation` | JPEG2000 |
| `GFEmbeddedFile` | `EmbeddedFileValidation` | Embedded file |
| `GFPKCSDataObject` | `PKCSValidation` | Signature data |

---

## Module 2: feature-reporting (~27 classes → ~15)

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `GFFeatureParser` | `FeatureExtractor` (struct) | Main extractor |
| `GFFeaturesObjectCreator` | Part of `FeatureExtractor` | Consolidate |
| `GFAdapterHelper` | Extensions | Utility methods |

**Feature Adapters (24 → Protocol + Extensions):**

```swift
protocol FeatureAdapter {
    associatedtype Source
    func extractFeatures(from source: Source) -> FeatureNode
}

// Single generic implementation for most cases
struct GenericFeatureAdapter<T: ValidationObject>: FeatureAdapter {
    func extractFeatures(from source: T) -> FeatureNode { /* ... */ }
}
```

---

## Module 3: metadata-fixer (~10 classes → ~6)

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `MetadataFixerImpl` | `MetadataFixer` (struct) | Main fixer |
| `GFMetadataFixerImpl` | Part of above | Consolidate |
| `DateConverter` | `extension Date` | Date utilities |
| `InfoDictionaryImpl` | `InfoDictionary` (struct) | Info dict model |
| `MetadataImpl` | `XMPMetadataModel` (struct) | XMP model |
| `PDFDocumentImpl` | Part of fixer | Consolidate |
| `BasicSchemaImpl` | `XMPSchema` (protocol) | Schema protocol |
| `AdobePDFSchemaImpl` | `AdobePDFSchema` (struct) | Adobe PDF schema |
| `DublinCoreSchemaImpl` | `DublinCoreSchema` (struct) | DC schema |
| `XMPBasicSchemaImpl` | `XMPBasicSchema` (struct) | XMP Basic schema |

---

## Module 4: wcag-validation (~100 classes → ~50)

### 4.1 Core WCAG Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `StaticStorages` | `WCAGValidationContext` (actor) | Thread-safe state |
| `ChunkContainer` | `ContentChunkContainer` (struct) | Chunk storage |
| `ChunkFactory` | `ContentChunkFactory` (struct) | Factory |
| `ChunkParser` | `ContentChunkParser` (struct) | Parser |

### 4.2 SA (Structured Accessibility) Layer (~77 classes → ~30)

**Base Types:**

| Java Class | Swift Equivalent |
|------------|-----------------|
| `GFSAObject` | `SAObject` (protocol) |
| `GFSAPDFDocument` | `SADocument` (struct) |
| `GFSAPage` | `SAPage` (struct) |
| `GFSAStructTreeRoot` | `SAStructureRoot` (struct) |
| `GFSAStructElem` | `SAStructureElement` (struct) |
| `GFSANode` | `SANode` (struct) |

**Structure Elements (55 → Enum + Struct):**

Same consolidation as validation-model:

```swift
// Reuse StructureElementType enum from validation-model
struct SAStructureElement: SAObject {
    let type: StructureElementType
    let semanticNode: SemanticNode
    // WCAG-specific properties
}
```

### 4.3 Serializers (9 → Codable)

Replace Jackson serializers with Swift `Codable`:

```swift
// All SA types conform to Codable
extension SADocument: Codable {}
extension SAPage: Codable {}
extension SAStructureElement: Codable {}

// Custom encoding for specific types
struct SADocumentEncoder {
    func encode(_ document: SADocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(document)
    }
}
```

---

## Testing Strategy

### Unit Tests

1. **Validation Object Model Tests**
   - Test each validation object type
   - Test property access
   - Test relationship navigation

2. **Operator Tests**
   - Test operator parsing
   - Test operator validation

3. **Structure Element Tests**
   - Test all structure element types
   - Test namespace resolution
   - Test role mapping

4. **Feature Extraction Tests**
   - Test each feature type extraction
   - Test tree structure generation

5. **Metadata Fixer Tests**
   - Test XMP schema handling
   - Test date conversion
   - Test metadata repair scenarios

### Integration Tests

1. **Full Document Validation**
   - Validate reference PDFs
   - Compare results with veraPDF Java

2. **WCAG Validation**
   - Test accessibility checks
   - Test semantic structure analysis

### Performance Tests

1. **Large Document Performance**
   - Memory usage during validation
   - Validation speed benchmarks

2. **Parallel Validation**
   - Test concurrent rule evaluation

---

## Phased Implementation

### Phase 1: Core Validation Model (MVP)
1. `ValidationObject` protocol
2. COS layer wrappers
3. PD layer for documents, pages, structure
4. Structure element types
5. Basic content stream operators

### Phase 2: Complete Validation Model
1. All operator types
2. All annotation types
3. All font validation types
4. All color space validation types

### Phase 3: Feature Reporting
1. Feature extraction framework
2. Feature adapters
3. Feature tree generation

### Phase 4: WCAG Validation
1. SA object layer
2. Content chunk system
3. WCAG-specific validation

### Phase 5: Metadata Fixer
1. XMP schema handling
2. Metadata repair logic
3. Document modification

---

## Performance Optimizations

1. **Lazy Validation Object Creation**
   ```swift
   @propertyWrapper
   struct LazyValidation<T: ValidationObject> {
       private var value: T?
       private let factory: () -> T

       var wrappedValue: T {
           mutating get {
               if let value { return value }
               let created = factory()
               value = created
               return created
           }
       }
   }
   ```

2. **Parallel Rule Evaluation**
   ```swift
   func validateRules(_ rules: [ValidationRule]) async -> [RuleResult] {
       await withTaskGroup(of: RuleResult.self) { group in
           for rule in rules {
               group.addTask { await rule.evaluate() }
           }
           return await group.reduce(into: []) { $0.append($1) }
       }
   }
   ```

3. **Object Caching via Actor**
   ```swift
   actor ValidationCache {
       private var objects: [COSObjectKey: any ValidationObject] = [:]

       func getOrCreate<T: ValidationObject>(
           key: COSObjectKey,
           factory: () -> T
       ) -> T {
           if let existing = objects[key] as? T { return existing }
           let new = factory()
           objects[key] = new
           return new
       }
   }
   ```

4. **Enum-Based Operators**
   - Pattern matching is highly optimized
   - No dynamic dispatch overhead
   - Better memory layout

---

## Class Count Summary

| Module | Java Classes | Swift Types | Reduction |
|--------|-------------|-------------|-----------|
| validation-model | 315 | ~120 | 62% |
| feature-reporting | 27 | ~15 | 44% |
| metadata-fixer | 10 | ~6 | 40% |
| wcag-validation | 100 | ~50 | 50% |
| **Total** | **452** | **~191** | **58%** |

Major consolidations:
- 97 operator classes → 1 enum with ~50 cases
- 58 structure element classes → 1 enum + 1 struct
- 55 SA structure classes → reuse of enum + 1 struct
- 27 COS wrapper classes → ~5 generic wrappers
- 24 feature adapters → 1 generic adapter + extensions
