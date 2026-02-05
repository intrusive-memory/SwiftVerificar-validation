import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarValidationProfiles

@Suite("SwiftVerificarValidation Tests")
struct SwiftVerificarValidationTests {

    @Test("Library version is set correctly")
    func versionIsSet() {
        #expect(SwiftVerificarValidation.version == "0.1.0")
    }

    @Test("Validation can be instantiated")
    func canInstantiate() {
        let validation = SwiftVerificarValidation()
        // Just verify it creates successfully (it's a struct, can't be nil)
        #expect(SwiftVerificarValidation.version == "0.1.0")
    }

    @Test("ValidationProfile can be created")
    func canCreateProfile() {
        let profile = ValidationProfile(
            details: ProfileDetails(
                name: "Test Profile",
                description: "A test profile",
                creator: "Test",
                created: Date()
            ),
            rules: [],
            flavour: .pdfUA2
        )
        #expect(profile.details.name == "Test Profile")
        #expect(profile.rules.isEmpty)
    }

    @Test("ValidationResult calculates compliance percentage")
    func compliancePercentage() {
        let result = ValidationResult(
            isCompliant: false,
            profileName: "Test",
            totalRules: 10,
            passedRules: 8,
            failedRules: 2,
            ruleResults: [],
            duration: 1.0
        )
        #expect(result.compliancePercentage == 80.0)
    }
}
