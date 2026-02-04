import Testing
@testable import SwiftVerificarValidation

@Suite("SwiftVerificarValidation Tests")
struct SwiftVerificarValidationTests {

    @Test("Library version is set correctly")
    func versionIsSet() {
        #expect(SwiftVerificarValidation.version == "0.1.0")
    }

    @Test("Validation can be instantiated")
    func canInstantiate() {
        let validation = SwiftVerificarValidation()
        #expect(validation != nil)
    }

    @Test("ValidationProfile can be created")
    func canCreateProfile() {
        let profile = ValidationProfile(
            id: "test",
            name: "Test Profile",
            description: "A test profile",
            rules: []
        )
        #expect(profile.id == "test")
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
