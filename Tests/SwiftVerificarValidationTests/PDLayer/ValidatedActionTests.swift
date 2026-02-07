import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Action Type Tests

@Suite("ActionType Tests")
struct ActionTypeTests {

    @Test("Raw values match PDF specification")
    func rawValues() {
        #expect(ActionType.goTo.rawValue == "GoTo")
        #expect(ActionType.goToR.rawValue == "GoToR")
        #expect(ActionType.uri.rawValue == "URI")
        #expect(ActionType.launch.rawValue == "Launch")
        #expect(ActionType.javaScript.rawValue == "JavaScript")
        #expect(ActionType.named.rawValue == "Named")
        #expect(ActionType.submitForm.rawValue == "SubmitForm")
        #expect(ActionType.resetForm.rawValue == "ResetForm")
        #expect(ActionType.sound.rawValue == "Sound")
        #expect(ActionType.movie.rawValue == "Movie")
        #expect(ActionType.hide.rawValue == "Hide")
        #expect(ActionType.setOCGState.rawValue == "SetOCGState")
        #expect(ActionType.rendition.rawValue == "Rendition")
        #expect(ActionType.unknown.rawValue == "Unknown")
    }

    @Test("Creates action type from valid string")
    func fromValidString() {
        #expect(ActionType(fromString: "GoTo") == .goTo)
        #expect(ActionType(fromString: "URI") == .uri)
        #expect(ActionType(fromString: "JavaScript") == .javaScript)
        #expect(ActionType(fromString: "Named") == .named)
    }

    @Test("Creates unknown for invalid string")
    func fromInvalidString() {
        #expect(ActionType(fromString: "InvalidType") == .unknown)
        #expect(ActionType(fromString: nil) == .unknown)
    }

    @Test("PDF/A-1 prohibition checks")
    func pdfA1Prohibition() {
        let prohibited: [ActionType] = [
            .launch, .sound, .movie, .javaScript,
            .importData, .resetForm, .submitForm,
            .rendition, .richMediaExecute, .goTo3DView
        ]
        for action in prohibited {
            #expect(action.isProhibitedInPDFA1 == true)
        }

        let allowed: [ActionType] = [.goTo, .goToR, .goToE, .uri, .named, .hide, .setOCGState]
        for action in allowed {
            #expect(action.isProhibitedInPDFA1 == false)
        }
    }

    @Test("Navigation classification")
    func navigation() {
        #expect(ActionType.goTo.isNavigation == true)
        #expect(ActionType.goToR.isNavigation == true)
        #expect(ActionType.goToE.isNavigation == true)
        #expect(ActionType.goToDp.isNavigation == true)
        #expect(ActionType.goTo3DView.isNavigation == true)
        #expect(ActionType.uri.isNavigation == false)
        #expect(ActionType.javaScript.isNavigation == false)
    }

    @Test("Multimedia classification")
    func multimedia() {
        #expect(ActionType.sound.isMultimedia == true)
        #expect(ActionType.movie.isMultimedia == true)
        #expect(ActionType.rendition.isMultimedia == true)
        #expect(ActionType.richMediaExecute.isMultimedia == true)
        #expect(ActionType.goTo.isMultimedia == false)
        #expect(ActionType.uri.isMultimedia == false)
    }

    @Test("Form action classification")
    func formActions() {
        #expect(ActionType.submitForm.isFormAction == true)
        #expect(ActionType.resetForm.isFormAction == true)
        #expect(ActionType.importData.isFormAction == true)
        #expect(ActionType.goTo.isFormAction == false)
        #expect(ActionType.javaScript.isFormAction == false)
    }

    @Test("CaseIterable conformance")
    func caseIterable() {
        #expect(ActionType.allCases.count == 20)
    }
}

// MARK: - Validated Action Tests

@Suite("ValidatedAction Tests")
struct ValidatedActionTests {

    @Test("Default initialization")
    func defaultInit() {
        let action = ValidatedAction()
        #expect(action.actionType == .goTo)
        #expect(action.actionTypeName == "GoTo")
        #expect(action.hasDestination == false)
        #expect(action.destinationName == nil)
        #expect(action.uri == nil)
        #expect(action.isMap == false)
        #expect(action.hasFileSpec == false)
        #expect(action.hasJavaScript == false)
        #expect(action.hasNextAction == false)
        #expect(action.nextActionCount == 0)
        #expect(action.objectType == "PDAction")
    }

    @Test("GoTo action")
    func goToAction() {
        let action = ValidatedAction.goTo(destinationName: "chapter1")
        #expect(action.actionType == .goTo)
        #expect(action.hasDestination == true)
        #expect(action.destinationName == "chapter1")
        #expect(action.isNavigation == true)
        #expect(action.isProhibitedInPDFA1 == false)
        #expect(action.hasValidDestination == true)
    }

    @Test("URI action")
    func uriAction() {
        let action = ValidatedAction.uri("https://example.com")
        #expect(action.actionType == .uri)
        #expect(action.uri == "https://example.com")
        #expect(action.hasValidURI == true)
        #expect(action.isNavigation == false)
        #expect(action.isProhibitedInPDFA1 == false)
    }

    @Test("URI action without URI is invalid")
    func uriActionInvalid() {
        let action = ValidatedAction(actionTypeName: "URI")
        #expect(action.hasValidURI == false)

        let emptyURI = ValidatedAction(actionTypeName: "URI", uri: "")
        #expect(emptyURI.hasValidURI == false)
    }

    @Test("JavaScript action")
    func javaScriptAction() {
        let action = ValidatedAction.javaScript()
        #expect(action.actionType == .javaScript)
        #expect(action.hasJavaScript == true)
        #expect(action.isProhibitedInPDFA1 == true)
    }

    @Test("Named action")
    func namedAction() {
        let action = ValidatedAction.named("NextPage")
        #expect(action.actionType == .named)
        #expect(action.namedActionName == "NextPage")
        #expect(action.isProhibitedInPDFA1 == false)
    }

    @Test("Launch action is prohibited in PDF/A-1")
    func launchAction() {
        let action = ValidatedAction(
            actionTypeName: "Launch",
            hasFileSpec: true,
            fileSpecName: "app.exe"
        )
        #expect(action.isProhibitedInPDFA1 == true)
        #expect(action.hasFileSpec == true)
        #expect(action.fileSpecName == "app.exe")
    }

    @Test("Action with next action chain")
    func nextActionChain() {
        let action = ValidatedAction(
            actionTypeName: "GoTo",
            hasDestination: true,
            hasNextAction: true,
            nextActionCount: 3
        )
        #expect(action.hasNextAction == true)
        #expect(action.nextActionCount == 3)
    }

    @Test("GoTo action validity checks")
    func goToValidity() {
        let valid = ValidatedAction(actionTypeName: "GoTo", hasDestination: true)
        #expect(valid.hasValidDestination == true)

        let invalid = ValidatedAction(actionTypeName: "GoTo", hasDestination: false)
        #expect(invalid.hasValidDestination == false)

        let wrongType = ValidatedAction(actionTypeName: "URI", hasDestination: true)
        #expect(wrongType.hasValidDestination == false)
    }

    @Test("Property access")
    func propertyAccess() {
        let action = ValidatedAction(
            actionTypeName: "URI",
            uri: "https://example.com",
            isMap: true,
            hasNextAction: true,
            nextActionCount: 2
        )
        #expect(action.property(named: "actionType")?.stringValue == "URI")
        #expect(action.property(named: "actionTypeName")?.stringValue == "URI")
        #expect(action.property(named: "uri")?.stringValue == "https://example.com")
        #expect(action.property(named: "isMap")?.boolValue == true)
        #expect(action.property(named: "hasNextAction")?.boolValue == true)
        #expect(action.property(named: "nextActionCount")?.integerValue == 2)
        #expect(action.property(named: "isProhibitedInPDFA1")?.boolValue == false)
        #expect(action.property(named: "isNavigation")?.boolValue == false)
        #expect(action.property(named: "isMultimedia")?.boolValue == false)
        #expect(action.property(named: "isFormAction")?.boolValue == false)
        #expect(action.property(named: "nonexistent") == nil)
    }

    @Test("Null property values for absent optional fields")
    func nullProperties() {
        let action = ValidatedAction()
        #expect(action.property(named: "destinationName")?.isNull == true)
        #expect(action.property(named: "uri")?.isNull == true)
        #expect(action.property(named: "fileSpecName")?.isNull == true)
        #expect(action.property(named: "namedActionName")?.isNull == true)
    }

    @Test("Summary description")
    func summary() {
        let uri = ValidatedAction.uri("https://example.com")
        #expect(uri.summary.contains("URI"))
        #expect(uri.summary.contains("https://example.com"))

        let named = ValidatedAction.named("NextPage")
        #expect(named.summary.contains("Named"))
        #expect(named.summary.contains("NextPage"))

        let js = ValidatedAction.javaScript()
        #expect(js.summary.contains("JavaScript"))
        #expect(js.summary.contains("JS"))
    }

    @Test("Equatable by ID")
    func equatable() {
        let id = UUID()
        let a = ValidatedAction(id: id, actionTypeName: "GoTo")
        let b = ValidatedAction(id: id, actionTypeName: "URI")
        let c = ValidatedAction(actionTypeName: "GoTo")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("PropertyNames coverage")
    func propertyNames() {
        let action = ValidatedAction.uri("https://test.com")
        let names = action.propertyNames
        #expect(names.contains("actionType"))
        #expect(names.contains("uri"))
        #expect(names.contains("isProhibitedInPDFA1"))
        for propName in names {
            let value = action.property(named: propName)
            #expect(value != nil)
        }
    }
}
