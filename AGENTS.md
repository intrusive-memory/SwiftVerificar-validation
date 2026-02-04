# SwiftVerificar-validation — Agent Instructions

Swift port of [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation).

See the parent [SwiftVerificar/AGENTS.md](../AGENTS.md) for ecosystem overview, implementation roadmap, and general guidelines.

## Purpose

Core validation engine providing:

- Rule execution against parsed PDF documents
- Validation profile management
- Feature reporting
- Validation result generation

## Source Reference

- **Original**: [veraPDF-validation](https://github.com/veraPDF/veraPDF-validation)
- **Language**: Java → Swift
- **License**: GPLv3+ / MPLv2+

## Key Types to Implement

```swift
// Validation Engine
protocol ValidationEngine
actor PDFValidator

// Profiles & Rules
struct ValidationProfile
struct ValidationRule
struct RuleExpression

// Results
struct ValidationResult
struct RuleResult
enum RuleStatus
```

## Modules in Original

The original veraPDF-validation contains:

1. **validation-model** — Core validation logic
2. **feature-reporting** — Detailed feature extraction
3. **metadata-fixer** — PDF metadata repair
4. **wcag-validation** — WCAG-specific validation (separate package in SwiftVerificar)

## Implementation Strategy

1. **Rule expression evaluator** — Parse and execute test expressions from profiles
2. **Object visitor pattern** — Walk PDF structure applying relevant rules
3. **Async validation** — Use Swift actors for thread-safe validation
4. **Result aggregation** — Collect and summarize rule results
