import Foundation
import Testing
@testable import SwiftVerificarValidation

@Suite("ValidationProfile Tests")
struct ValidationProfileTests {

    // MARK: - Initialization Tests

    @Test("Create ValidationProfile with all parameters")
    func createWithAllParameters() {
        let rules = [
            ValidationRule(
                id: "rule-1",
                specification: "PDF/A-1",
                clause: "6.1.2",
                testNumber: 1,
                description: "Test rule 1",
                objectType: "Document",
                test: "property == value",
                errorMessage: "Error 1"
            ),
            ValidationRule(
                id: "rule-2",
                specification: "PDF/A-1",
                clause: "6.1.3",
                testNumber: 2,
                description: "Test rule 2",
                objectType: "Page",
                test: "property != null",
                errorMessage: "Error 2"
            )
        ]

        let profile = ValidationProfile(
            id: "pdfa-1b",
            name: "PDF/A-1b",
            description: "PDF/A-1 Level B conformance",
            rules: rules
        )

        #expect(profile.id == "pdfa-1b")
        #expect(profile.name == "PDF/A-1b")
        #expect(profile.description == "PDF/A-1 Level B conformance")
        #expect(profile.rules.count == 2)
    }

    @Test("Create ValidationProfile with empty rules")
    func createWithEmptyRules() {
        let profile = ValidationProfile(
            id: "empty",
            name: "Empty Profile",
            description: "Profile with no rules",
            rules: []
        )

        #expect(profile.id == "empty")
        #expect(profile.rules.isEmpty)
    }

    // MARK: - Identifiable Conformance

    @Test("ValidationProfile conforms to Identifiable")
    func conformsToIdentifiable() {
        let profile = ValidationProfile(
            id: "test",
            name: "Test",
            description: "Test",
            rules: []
        )

        let id: String = profile.id
        #expect(id == "test")
    }

    // MARK: - Sendable Conformance

    @Test("ValidationProfile is Sendable")
    func isSendable() {
        let profile = ValidationProfile(
            id: "test",
            name: "Test",
            description: "Test",
            rules: []
        )

        Task {
            let _ = profile
            #expect(true)
        }
    }

    // MARK: - Rules Tests

    @Test("Profile with single rule")
    func singleRule() {
        let rule = ValidationRule(
            id: "rule-1",
            specification: "PDF/A-1",
            clause: "6.1.2",
            testNumber: 1,
            description: "Test rule",
            objectType: "Document",
            test: "property == value",
            errorMessage: "Error"
        )

        let profile = ValidationProfile(
            id: "test",
            name: "Test",
            description: "Test",
            rules: [rule]
        )

        #expect(profile.rules.count == 1)
        #expect(profile.rules[0].id == "rule-1")
    }

    @Test("Profile with multiple rules")
    func multipleRules() {
        let rules = (1...10).map { i in
            ValidationRule(
                id: "rule-\(i)",
                specification: "PDF/A-1",
                clause: "6.1.\(i)",
                testNumber: i,
                description: "Test rule \(i)",
                objectType: "Document",
                test: "property == value",
                errorMessage: "Error \(i)"
            )
        }

        let profile = ValidationProfile(
            id: "test",
            name: "Test",
            description: "Test",
            rules: rules
        )

        #expect(profile.rules.count == 10)
    }

    // MARK: - Standard Profile IDs

    @Test("Standard PDF/A profile IDs")
    func standardProfileIds() {
        let profileIds = ["pdfa-1a", "pdfa-1b", "pdfa-2a", "pdfa-2b", "pdfa-2u", "pdfa-3a", "pdfa-3b", "pdfa-3u", "pdfa-4"]

        for profileId in profileIds {
            let profile = ValidationProfile(
                id: profileId,
                name: profileId.uppercased(),
                description: "Test",
                rules: []
            )

            #expect(profile.id == profileId)
        }
    }

    @Test("PDF/UA profile ID")
    func pdfuaProfileId() {
        let profile = ValidationProfile(
            id: "pdfua-1",
            name: "PDF/UA-1",
            description: "PDF/UA-1 conformance",
            rules: []
        )

        #expect(profile.id == "pdfua-1")
        #expect(profile.name == "PDF/UA-1")
    }
}
