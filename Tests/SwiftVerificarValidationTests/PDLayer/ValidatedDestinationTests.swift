import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - Destination Type Tests

@Suite("DestinationType Tests")
struct DestinationTypeTests {

    @Test("Raw values match PDF specification")
    func rawValues() {
        #expect(DestinationType.xyz.rawValue == "XYZ")
        #expect(DestinationType.fit.rawValue == "Fit")
        #expect(DestinationType.fitH.rawValue == "FitH")
        #expect(DestinationType.fitV.rawValue == "FitV")
        #expect(DestinationType.fitR.rawValue == "FitR")
        #expect(DestinationType.fitB.rawValue == "FitB")
        #expect(DestinationType.fitBH.rawValue == "FitBH")
        #expect(DestinationType.fitBV.rawValue == "FitBV")
        #expect(DestinationType.unknown.rawValue == "Unknown")
    }

    @Test("Creates type from valid string")
    func fromValidString() {
        #expect(DestinationType(fromString: "XYZ") == .xyz)
        #expect(DestinationType(fromString: "Fit") == .fit)
        #expect(DestinationType(fromString: "FitH") == .fitH)
        #expect(DestinationType(fromString: "FitR") == .fitR)
    }

    @Test("Creates unknown for invalid string")
    func fromInvalidString() {
        #expect(DestinationType(fromString: "Invalid") == .unknown)
        #expect(DestinationType(fromString: nil) == .unknown)
    }

    @Test("Requires coordinates")
    func requiresCoordinates() {
        #expect(DestinationType.xyz.requiresCoordinates == true)
        #expect(DestinationType.fitH.requiresCoordinates == true)
        #expect(DestinationType.fitV.requiresCoordinates == true)
        #expect(DestinationType.fitR.requiresCoordinates == true)
        #expect(DestinationType.fitBH.requiresCoordinates == true)
        #expect(DestinationType.fitBV.requiresCoordinates == true)
        #expect(DestinationType.fit.requiresCoordinates == false)
        #expect(DestinationType.fitB.requiresCoordinates == false)
        #expect(DestinationType.unknown.requiresCoordinates == false)
    }

    @Test("Specifies zoom")
    func specifiesZoom() {
        #expect(DestinationType.xyz.specifiesZoom == true)
        #expect(DestinationType.fit.specifiesZoom == false)
        #expect(DestinationType.fitH.specifiesZoom == false)
    }

    @Test("CaseIterable conformance")
    func caseIterable() {
        #expect(DestinationType.allCases.count == 9)
    }
}

// MARK: - Validated Destination Tests

@Suite("ValidatedDestination Tests")
struct ValidatedDestinationTests {

    @Test("Default initialization")
    func defaultInit() {
        let dest = ValidatedDestination()
        #expect(dest.destinationType == .xyz)
        #expect(dest.destinationTypeName == "XYZ")
        #expect(dest.isNamed == false)
        #expect(dest.name == nil)
        #expect(dest.hasPageReference == true)
        #expect(dest.pageIndex == nil)
        #expect(dest.left == nil)
        #expect(dest.top == nil)
        #expect(dest.zoom == nil)
        #expect(dest.objectType == "PDDestination")
    }

    @Test("XYZ destination factory")
    func xyzFactory() {
        let dest = ValidatedDestination.xyz(pageIndex: 2, left: 72, top: 720, zoom: 1.5)
        #expect(dest.destinationType == .xyz)
        #expect(dest.hasPageReference == true)
        #expect(dest.pageIndex == 2)
        #expect(dest.left == 72)
        #expect(dest.top == 720)
        #expect(dest.zoom == 1.5)
        #expect(dest.isValid == true)
        #expect(dest.isExplicit == true)
        #expect(dest.hasCoordinates == true)
        #expect(dest.hasZoom == true)
        #expect(dest.pageNumber == 3)
    }

    @Test("Fit destination factory")
    func fitFactory() {
        let dest = ValidatedDestination.fit(pageIndex: 0)
        #expect(dest.destinationType == .fit)
        #expect(dest.hasPageReference == true)
        #expect(dest.pageIndex == 0)
        #expect(dest.hasCoordinates == false)
        #expect(dest.hasZoom == false)
        #expect(dest.isValid == true)
        #expect(dest.pageNumber == 1)
    }

    @Test("Named destination factory")
    func namedFactory() {
        let dest = ValidatedDestination.named("chapter1")
        #expect(dest.isNamed == true)
        #expect(dest.name == "chapter1")
        #expect(dest.isExplicit == false)
        #expect(dest.isValid == true)
    }

    @Test("Named destination validity")
    func namedValidity() {
        let valid = ValidatedDestination(isNamed: true, name: "test")
        #expect(valid.isValid == true)

        let emptyName = ValidatedDestination(isNamed: true, name: "")
        #expect(emptyName.isValid == false)

        let noName = ValidatedDestination(isNamed: true, name: nil)
        #expect(noName.isValid == false)
    }

    @Test("Explicit destination validity")
    func explicitValidity() {
        let valid = ValidatedDestination(hasPageReference: true)
        #expect(valid.isValid == true)

        let invalid = ValidatedDestination(hasPageReference: false)
        #expect(invalid.isValid == false)
    }

    @Test("Zoom detection")
    func zoomDetection() {
        let withZoom = ValidatedDestination(zoom: 1.5)
        #expect(withZoom.hasZoom == true)

        let zeroZoom = ValidatedDestination(zoom: 0)
        #expect(zeroZoom.hasZoom == false)

        let noZoom = ValidatedDestination(zoom: nil)
        #expect(noZoom.hasZoom == false)
    }

    @Test("FitR destination with all coordinates")
    func fitRDestination() {
        let dest = ValidatedDestination(
            destinationTypeName: "FitR",
            hasPageReference: true,
            pageIndex: 0,
            left: 0,
            top: 792,
            right: 612,
            bottom: 0
        )
        #expect(dest.destinationType == .fitR)
        #expect(dest.hasCoordinates == true)
        #expect(dest.left == 0)
        #expect(dest.top == 792)
        #expect(dest.right == 612)
        #expect(dest.bottom == 0)
    }

    @Test("Property access")
    func propertyAccess() {
        let dest = ValidatedDestination.xyz(pageIndex: 1, left: 72, top: 720, zoom: 2.0)
        #expect(dest.property(named: "destinationType")?.stringValue == "XYZ")
        #expect(dest.property(named: "destinationTypeName")?.stringValue == "XYZ")
        #expect(dest.property(named: "isNamed")?.boolValue == false)
        #expect(dest.property(named: "hasPageReference")?.boolValue == true)
        #expect(dest.property(named: "pageIndex")?.integerValue == 1)
        #expect(dest.property(named: "left")?.realValue == 72)
        #expect(dest.property(named: "top")?.realValue == 720)
        #expect(dest.property(named: "zoom")?.realValue == 2.0)
        #expect(dest.property(named: "isValid")?.boolValue == true)
        #expect(dest.property(named: "isExplicit")?.boolValue == true)
        #expect(dest.property(named: "hasCoordinates")?.boolValue == true)
        #expect(dest.property(named: "nonexistent") == nil)
    }

    @Test("Null property values for absent optional fields")
    func nullProperties() {
        let dest = ValidatedDestination()
        #expect(dest.property(named: "name")?.isNull == true)
        #expect(dest.property(named: "pageIndex")?.isNull == true)
        #expect(dest.property(named: "left")?.isNull == true)
        #expect(dest.property(named: "top")?.isNull == true)
        #expect(dest.property(named: "right")?.isNull == true)
        #expect(dest.property(named: "bottom")?.isNull == true)
        #expect(dest.property(named: "zoom")?.isNull == true)
    }

    @Test("Summary description")
    func summary() {
        let xyz = ValidatedDestination.xyz(pageIndex: 5, zoom: 1.5)
        #expect(xyz.summary.contains("XYZ"))
        #expect(xyz.summary.contains("page 6"))
        #expect(xyz.summary.contains("zoom=1.5"))

        let named = ValidatedDestination.named("toc")
        #expect(named.summary.contains("named"))
        #expect(named.summary.contains("'toc'"))
    }

    @Test("Equatable by ID")
    func equatable() {
        let id = UUID()
        let a = ValidatedDestination(id: id, destinationTypeName: "XYZ")
        let b = ValidatedDestination(id: id, destinationTypeName: "Fit")
        let c = ValidatedDestination(destinationTypeName: "XYZ")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("PropertyNames coverage")
    func propertyNames() {
        let dest = ValidatedDestination.xyz(pageIndex: 0, left: 0, top: 792, zoom: 1.0)
        let names = dest.propertyNames
        #expect(names.contains("destinationType"))
        #expect(names.contains("isValid"))
        #expect(names.contains("isExplicit"))
        for propName in names {
            let value = dest.property(named: propName)
            #expect(value != nil)
        }
    }

    @Test("Page number computation")
    func pageNumber() {
        let dest = ValidatedDestination(pageIndex: 0)
        #expect(dest.pageNumber == 1)

        let dest5 = ValidatedDestination(pageIndex: 4)
        #expect(dest5.pageNumber == 5)

        let noPage = ValidatedDestination(pageIndex: nil)
        #expect(noPage.pageNumber == nil)
    }
}
