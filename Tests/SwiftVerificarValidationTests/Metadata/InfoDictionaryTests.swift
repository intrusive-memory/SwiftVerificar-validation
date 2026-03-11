import Testing
import Foundation
@testable import SwiftVerificarValidation
import SwiftVerificarParser

// MARK: - Info Dictionary Tests

@Suite("Info Dictionary Tests")
struct InfoDictionaryTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicProperties {

        @Test("Initialize with all properties")
        func initializeWithAllProperties() throws {
            let info = InfoDictionary(
                title: "Test Document",
                author: "Test Author",
                subject: "Test Subject",
                keywords: "test, keywords",
                creator: "Test Creator App",
                producer: "SwiftVerificar",
                creationDate: "D:20230615120000Z",
                modDate: "D:20230615130000Z",
                trapped: .trapped,
                customProperties: ["Custom": "Value"]
            )

            #expect(info.title == "Test Document")
            #expect(info.author == "Test Author")
            #expect(info.subject == "Test Subject")
            #expect(info.keywords == "test, keywords")
            #expect(info.creator == "Test Creator App")
            #expect(info.producer == "SwiftVerificar")
            #expect(info.creationDate == "D:20230615120000Z")
            #expect(info.modDate == "D:20230615130000Z")
            #expect(info.trapped == .trapped)
            #expect(info.customProperties["Custom"] == "Value")
        }

        @Test("Default initialization")
        func defaultInitialization() throws {
            let info = InfoDictionary()

            #expect(info.title == nil)
            #expect(info.author == nil)
            #expect(info.isEmpty)
        }

        @Test("Standard keys")
        func standardKeys() throws {
            let keys = InfoDictionary.standardKeys

            #expect(keys.contains("Title"))
            #expect(keys.contains("Author"))
            #expect(keys.contains("Subject"))
            #expect(keys.contains("Keywords"))
            #expect(keys.contains("Creator"))
            #expect(keys.contains("Producer"))
            #expect(keys.contains("CreationDate"))
            #expect(keys.contains("ModDate"))
            #expect(keys.contains("Trapped"))
        }
    }

    // MARK: - Date Accessors

    @Suite("Date Accessors")
    struct DateAccessors {

        @Test("Get creation date value")
        func getCreationDateValue() throws {
            let info = InfoDictionary(creationDate: "D:20230615120000Z")

            #expect(info.creationDateValue != nil)
        }

        @Test("Get mod date value")
        func getModDateValue() throws {
            let info = InfoDictionary(modDate: "D:20230615130000Z")

            #expect(info.modDateValue != nil)
        }

        @Test("Invalid date returns nil")
        func invalidDateReturnsNil() throws {
            let info = InfoDictionary(creationDate: "invalid")

            #expect(info.creationDateValue == nil)
        }

        @Test("Set creation date")
        func setCreationDate() throws {
            var info = InfoDictionary()
            let date = Date()

            info.setCreationDate(date)

            #expect(info.creationDate != nil)
            #expect(info.creationDate!.hasPrefix("D:"))
        }

        @Test("Set mod date")
        func setModDate() throws {
            var info = InfoDictionary()
            let date = Date()

            info.setModDate(date)

            #expect(info.modDate != nil)
            #expect(info.modDate!.hasPrefix("D:"))
        }

        @Test("Set date with specific timezone")
        func setDateWithTimezone() throws {
            var info = InfoDictionary()
            let date = Date()

            info.setCreationDate(date, timeZone: TimeZone(secondsFromGMT: 0)!)

            #expect(info.creationDate?.contains("Z") == true)
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccess {

        @Test("Get value for key")
        func getValueForKey() throws {
            let info = InfoDictionary(
                title: "Test",
                trapped: .trapped
            )

            #expect(info.value(forKey: "Title") == "Test")
            #expect(info.value(forKey: "Trapped") == "True")
            #expect(info.value(forKey: "Author") == nil)
        }

        @Test("Get custom property")
        func getCustomProperty() throws {
            let info = InfoDictionary(customProperties: ["CustomKey": "CustomValue"])

            #expect(info.value(forKey: "CustomKey") == "CustomValue")
        }

        @Test("Set value for key")
        func setValueForKey() throws {
            var info = InfoDictionary()

            info.setValue("New Title", forKey: "Title")
            info.setValue("New Author", forKey: "Author")

            #expect(info.title == "New Title")
            #expect(info.author == "New Author")
        }

        @Test("Set trapped by string")
        func setTrappedByString() throws {
            var info = InfoDictionary()

            info.setValue("True", forKey: "Trapped")
            #expect(info.trapped == .trapped)

            info.setValue("False", forKey: "Trapped")
            #expect(info.trapped == .notTrapped)

            info.setValue("Unknown", forKey: "Trapped")
            #expect(info.trapped == .unknown)
        }

        @Test("Remove property")
        func removeProperty() throws {
            var info = InfoDictionary(title: "Test")

            info.setValue(nil, forKey: "Title")

            #expect(info.title == nil)
        }

        @Test("Set custom property")
        func setCustomProperty() throws {
            var info = InfoDictionary()

            info.setValue("CustomValue", forKey: "CustomKey")

            #expect(info.customProperties["CustomKey"] == "CustomValue")
        }

        @Test("Remove custom property")
        func removeCustomProperty() throws {
            var info = InfoDictionary(customProperties: ["Key": "Value"])

            info.setValue(nil, forKey: "Key")

            #expect(info.customProperties["Key"] == nil)
        }

        @Test("All keys")
        func allKeys() throws {
            let info = InfoDictionary(
                title: "Test",
                author: "Author",
                customProperties: ["Custom": "Value"]
            )

            let keys = info.allKeys

            #expect(keys.contains("Title"))
            #expect(keys.contains("Author"))
            #expect(keys.contains("Custom"))
            #expect(!keys.contains("Subject"))
        }

        @Test("Is empty")
        func isEmpty() throws {
            let emptyInfo = InfoDictionary()
            #expect(emptyInfo.isEmpty)

            let nonEmptyInfo = InfoDictionary(title: "Test")
            #expect(!nonEmptyInfo.isEmpty)
        }
    }

    // MARK: - Trapped Status

    @Suite("Trapped Status")
    struct TrappedStatusTests {

        @Test("Trapped status values")
        func trappedStatusValues() throws {
            #expect(TrappedStatus.trapped.rawValue == "True")
            #expect(TrappedStatus.notTrapped.rawValue == "False")
            #expect(TrappedStatus.unknown.rawValue == "Unknown")
        }

        @Test("Convert to TrappedValue")
        func convertToTrappedValue() throws {
            #expect(TrappedStatus.trapped.trappedValue == .true)
            #expect(TrappedStatus.notTrapped.trappedValue == .false)
            #expect(TrappedStatus.unknown.trappedValue == .unknown)
        }

        @Test("Create from TrappedValue")
        func createFromTrappedValue() throws {
            #expect(TrappedStatus(from: .true) == .trapped)
            #expect(TrappedStatus(from: .false) == .notTrapped)
            #expect(TrappedStatus(from: .unknown) == .unknown)
        }

        @Test("PDF value property")
        func pdfValueProperty() throws {
            #expect(TrappedStatus.trapped.pdfValue == "True")
            #expect(TrappedStatus.notTrapped.pdfValue == "False")
        }
    }

    // MARK: - Validation

    @Suite("Validation")
    struct ValidationTests {

        @Test("Valid info dictionary passes")
        func validInfoDictionaryPasses() throws {
            let info = InfoDictionary(
                title: "Test",
                creationDate: "D:20230615120000Z",
                modDate: "D:20230615130000Z"
            )

            let issues = info.validate()

            #expect(issues.filter { $0.severity == .error }.isEmpty)
        }

        @Test("Invalid creation date error")
        func invalidCreationDateError() throws {
            let info = InfoDictionary(creationDate: "invalid-date")

            let issues = info.validate()

            #expect(issues.contains {
                $0.key == "CreationDate" && $0.severity == .error
            })
        }

        @Test("Invalid mod date error")
        func invalidModDateError() throws {
            let info = InfoDictionary(modDate: "invalid-date")

            let issues = info.validate()

            #expect(issues.contains {
                $0.key == "ModDate" && $0.severity == .error
            })
        }

        @Test("ModDate before CreationDate warning")
        func modDateBeforeCreationDateWarning() throws {
            let info = InfoDictionary(
                creationDate: "D:20230615120000Z",
                modDate: "D:20230615110000Z" // Before creation
            )

            let issues = info.validate()

            #expect(issues.contains {
                $0.key == "ModDate" && $0.severity == .warning
            })
        }

        @Test("Custom properties info")
        func customPropertiesInfo() throws {
            let info = InfoDictionary(customProperties: ["Custom": "Value"])

            let issues = info.validate()

            #expect(issues.contains { $0.severity == .info })
        }
    }

    // MARK: - COS Conversion

    @Suite("COS Conversion")
    struct COSConversionTests {

        @Test("Create from COS dictionary")
        func createFromCOSDictionary() throws {
            let cosDict: [ASAtom: COSValue] = [
                ASAtom("Title"): .string(COSString(string: "Test Title")),
                ASAtom("Author"): .string(COSString(string: "Test Author")),
                ASAtom("Trapped"): .name(ASAtom("True"))
            ]

            let info = InfoDictionary.fromCOSDictionary(cosDict)

            #expect(info.title == "Test Title")
            #expect(info.author == "Test Author")
            #expect(info.trapped == .trapped)
        }

        @Test("Convert to COS dictionary")
        func convertToCOSDictionary() throws {
            let info = InfoDictionary(
                title: "Test Title",
                author: "Test Author",
                trapped: .notTrapped
            )

            let cosDict = info.toCOSDictionary()

            #expect(cosDict[ASAtom("Title")]?.textValue == "Test Title")
            #expect(cosDict[ASAtom("Author")]?.textValue == "Test Author")
            #expect(cosDict[ASAtom("Trapped")]?.nameValue?.stringValue == "False")
        }

        @Test("Roundtrip conversion")
        func roundtripConversion() throws {
            let original = InfoDictionary(
                title: "Test",
                author: "Author",
                keywords: "test, keywords",
                creationDate: "D:20230615120000Z"
            )

            let cosDict = original.toCOSDictionary()
            let restored = InfoDictionary.fromCOSDictionary(cosDict)

            #expect(restored.title == original.title)
            #expect(restored.author == original.author)
            #expect(restored.keywords == original.keywords)
            #expect(restored.creationDate == original.creationDate)
        }
    }

    // MARK: - Validation Issue

    @Suite("Validation Issue")
    struct ValidationIssueTests {

        @Test("Create validation issue")
        func createValidationIssue() throws {
            let issue = InfoDictionaryValidationIssue(
                severity: .error,
                key: "Title",
                message: "Invalid title"
            )

            #expect(issue.severity == .error)
            #expect(issue.key == "Title")
            #expect(issue.message == "Invalid title")
            #expect(issue.id != UUID())
        }

        @Test("Severity levels")
        func severityLevels() throws {
            #expect(InfoDictionaryValidationIssue.Severity.error.rawValue == "error")
            #expect(InfoDictionaryValidationIssue.Severity.warning.rawValue == "warning")
            #expect(InfoDictionaryValidationIssue.Severity.info.rawValue == "info")
        }
    }

    // MARK: - XMP Mapping

    @Suite("XMP Mapping")
    struct XMPMappingTests {

        @Test("XMP mapping exists")
        func xmpMappingExists() throws {
            let mapping = InfoDictionary.xmpMapping

            #expect(mapping.count == 9)
            #expect(mapping.contains { $0.infoKey == "Title" && $0.property == "title" })
            #expect(mapping.contains { $0.infoKey == "Author" && $0.property == "creator" })
            #expect(mapping.contains { $0.infoKey == "CreationDate" && $0.property == "CreateDate" })
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Equal info dictionaries")
        func equalInfoDictionaries() throws {
            let info1 = InfoDictionary(title: "Test", author: "Author")
            let info2 = InfoDictionary(title: "Test", author: "Author")

            #expect(info1 == info2)
        }

        @Test("Unequal info dictionaries")
        func unequalInfoDictionaries() throws {
            let info1 = InfoDictionary(title: "Test 1")
            let info2 = InfoDictionary(title: "Test 2")

            #expect(info1 != info2)
        }
    }
}
