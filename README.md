# SwiftVerificar-validation

Swift port of [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation).

## Overview

SwiftVerificar-validation is the core PDF validation engine for the SwiftVerificar ecosystem. It provides rule execution against parsed PDF documents, PD-layer validation types for annotations, fonts, color spaces, and structure trees, SA-layer semantic accessibility types, feature extraction, and metadata fixing. The largest package in the SwiftVerificar suite with 238+ public types across 9 functional layers.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftVerificar-validation.git", from: "0.1.0")
]
```

## Usage

```swift
import SwiftVerificarValidation

// Validate operator types
let op = ValidatedOperator.textShowTj
op.isTextOperator // true
op.category // .textShowing

// Check structure element types
let elemType = StructureElementType.h1
elemType.isHeading // true
elemType.headingLevel // 1
```

## Porting Process

This library was ported from its Java source using a structured, AI-assisted methodology. The original veraPDF Java codebase was analyzed to extract type hierarchies, public APIs, and behavioral contracts. An execution plan decomposed the port into sequential sprints, each targeting a cohesive set of types with explicit entry/exit criteria (build must pass, all tests must pass, 90%+ coverage). AI coding agents (Claude) executed each sprint autonomously — translating Java patterns to idiomatic Swift (enums for sealed hierarchies, structs for value types, actors for thread-safe singletons, async/await for concurrency), writing Swift Testing framework tests, and verifying builds with xcodebuild. A supervisor process coordinated sprint sequencing, tracked cross-package dependencies, and performed reconciliation passes to ensure type agreement across the five-package ecosystem. The result is a clean-room Swift implementation that preserves the original's validation semantics while embracing Swift 6 strict concurrency, value semantics, and protocol-oriented design.

## Stats

- **238+ public types** across 9 functional layers
- **3050+ tests** with 90%+ coverage
- **19 sprints** to complete

## Requirements

- Swift 6.0+
- macOS 14.0+
- iOS 17.0+

## Source Reference

- **Original**: [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation)
- **Language**: Java → Swift
- **License**: GPLv3+ / MPLv2+

## Development

See [AGENTS.md](AGENTS.md) for detailed API reference and agent instructions.

### Building

```bash
xcodebuild build -scheme SwiftVerificarValidation -destination 'platform=macOS'
```

### Testing

```bash
xcodebuild test -scheme SwiftVerificarValidation -destination 'platform=macOS'
```
