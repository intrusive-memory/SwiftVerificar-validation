import Foundation
import Testing
@testable import SwiftVerificarValidation

@Suite("ValidationResult Tests")
struct ValidationResultTests {

    // MARK: - Initialization Tests

    @Test("Create ValidationResult with all parameters")
    func createWithAllParameters() {
        let ruleResults = [
            RuleResult(ruleId: "rule-1", status: .passed),
            RuleResult(ruleId: "rule-2", status: .failed, message: "Failed")
        ]

        let result = ValidationResult(
            isCompliant: false,
            profileName: "PDF/A-1b",
            totalRules: 10,
            passedRules: 8,
            failedRules: 2,
            ruleResults: ruleResults,
            duration: 2.5
        )

        #expect(result.isCompliant == false)
        #expect(result.profileName == "PDF/A-1b")
        #expect(result.totalRules == 10)
        #expect(result.passedRules == 8)
        #expect(result.failedRules == 2)
        #expect(result.ruleResults.count == 2)
        #expect(result.duration == 2.5)
    }

    @Test("Create compliant ValidationResult")
    func createCompliantResult() {
        let result = ValidationResult(
            isCompliant: true,
            profileName: "PDF/A-2b",
            totalRules: 5,
            passedRules: 5,
            failedRules: 0,
            ruleResults: [],
            duration: 1.0
        )

        #expect(result.isCompliant == true)
        #expect(result.failedRules == 0)
        #expect(result.ruleResults.isEmpty)
    }

    // MARK: - Compliance Percentage Tests

    @Test("Compliance percentage calculation - 100%")
    func compliancePercentage100() {
        let result = ValidationResult(
            isCompliant: true,
            profileName: "Test",
            totalRules: 10,
            passedRules: 10,
            failedRules: 0,
            ruleResults: [],
            duration: 1.0
        )

        #expect(result.compliancePercentage == 100.0)
    }

    @Test("Compliance percentage calculation - 80%")
    func compliancePercentage80() {
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

    @Test("Compliance percentage calculation - 0%")
    func compliancePercentage0() {
        let result = ValidationResult(
            isCompliant: false,
            profileName: "Test",
            totalRules: 10,
            passedRules: 0,
            failedRules: 10,
            ruleResults: [],
            duration: 1.0
        )

        #expect(result.compliancePercentage == 0.0)
    }

    @Test("Compliance percentage with zero rules")
    func compliancePercentageZeroRules() {
        let result = ValidationResult(
            isCompliant: true,
            profileName: "Test",
            totalRules: 0,
            passedRules: 0,
            failedRules: 0,
            ruleResults: [],
            duration: 0.0
        )

        #expect(result.compliancePercentage == 100.0)
    }

    @Test("Compliance percentage - fractional result")
    func compliancePercentageFractional() {
        let result = ValidationResult(
            isCompliant: false,
            profileName: "Test",
            totalRules: 3,
            passedRules: 2,
            failedRules: 1,
            ruleResults: [],
            duration: 1.0
        )

        #expect(abs(result.compliancePercentage - 66.666666) < 0.001)
    }

    // MARK: - Duration Tests

    @Test("Duration in seconds")
    func durationInSeconds() {
        let result = ValidationResult(
            isCompliant: true,
            profileName: "Test",
            totalRules: 1,
            passedRules: 1,
            failedRules: 0,
            ruleResults: [],
            duration: 5.25
        )

        #expect(result.duration == 5.25)
    }

    @Test("Duration zero for instant validation")
    func durationZero() {
        let result = ValidationResult(
            isCompliant: true,
            profileName: "Test",
            totalRules: 0,
            passedRules: 0,
            failedRules: 0,
            ruleResults: [],
            duration: 0.0
        )

        #expect(result.duration == 0.0)
    }

    // MARK: - Rule Results Tests

    @Test("Multiple rule results")
    func multipleRuleResults() {
        let ruleResults = [
            RuleResult(ruleId: "rule-1", status: .passed),
            RuleResult(ruleId: "rule-2", status: .failed),
            RuleResult(ruleId: "rule-3", status: .warning),
            RuleResult(ruleId: "rule-4", status: .error)
        ]

        let result = ValidationResult(
            isCompliant: false,
            profileName: "Test",
            totalRules: 4,
            passedRules: 1,
            failedRules: 3,
            ruleResults: ruleResults,
            duration: 1.0
        )

        #expect(result.ruleResults.count == 4)
        #expect(result.ruleResults[0].status == .passed)
        #expect(result.ruleResults[1].status == .failed)
        #expect(result.ruleResults[2].status == .warning)
        #expect(result.ruleResults[3].status == .error)
    }

    @Test("Empty rule results")
    func emptyRuleResults() {
        let result = ValidationResult(
            isCompliant: true,
            profileName: "Test",
            totalRules: 0,
            passedRules: 0,
            failedRules: 0,
            ruleResults: [],
            duration: 0.0
        )

        #expect(result.ruleResults.isEmpty)
    }

    // MARK: - Sendable Conformance

    @Test("ValidationResult is Sendable")
    func isSendable() {
        let result = ValidationResult(
            isCompliant: true,
            profileName: "Test",
            totalRules: 1,
            passedRules: 1,
            failedRules: 0,
            ruleResults: [],
            duration: 1.0
        )

        Task {
            let _ = result
            #expect(true)
        }
    }

    // MARK: - Profile Name Tests

    @Test("Profile name for different standards")
    func profileNames() {
        let profiles = ["PDF/A-1a", "PDF/A-1b", "PDF/A-2a", "PDF/A-2b", "PDF/A-3a", "PDF/UA-1"]

        for profileName in profiles {
            let result = ValidationResult(
                isCompliant: true,
                profileName: profileName,
                totalRules: 1,
                passedRules: 1,
                failedRules: 0,
                ruleResults: [],
                duration: 1.0
            )

            #expect(result.profileName == profileName)
        }
    }
}
