# SwiftVerificar-validation

Swift port of [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation).

## Overview

SwiftVerificar-validation provides the core validation engine for the SwiftVerificar ecosystem, including:

- Rule execution engine
- Validation profile management
- Feature reporting
- Validation result generation

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

let engine = SwiftVerificarValidation()
// Validation functionality coming soon
```

## Source Reference

- **Original**: [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation)
- **Language**: Java → Swift
- **License**: GPLv3+ / MPLv2+

## Development

See the parent [SwiftVerificar/AGENTS.md](../AGENTS.md) for development guidelines.

### Building

```bash
xcodebuild build -scheme SwiftVerificarValidation -destination 'platform=macOS'
```

### Testing

```bash
xcodebuild test -scheme SwiftVerificarValidation -destination 'platform=macOS'
```
