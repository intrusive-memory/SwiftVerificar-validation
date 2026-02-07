import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - XMP Basic Schema Tests

@Suite("XMP Basic Schema Tests")
struct XMPBasicSchemaTests {

    // MARK: - Basic Properties

    @Suite("Basic Properties")
    struct BasicProperties {

        @Test("Namespace and prefix")
        func namespaceAndPrefix() throws {
            #expect(XMPBasicSchema.namespaceURI == "http://ns.adobe.com/xap/1.0/")
            #expect(XMPBasicSchema.preferredPrefix == "xmp")
        }

        @Test("Initialize with all properties")
        func initializeWithAllProperties() throws {
            let createDate = Date()
            let modifyDate = Date().addingTimeInterval(3600)
            let metadataDate = Date().addingTimeInterval(7200)

            let schema = XMPBasicSchema(
                createDate: createDate,
                creatorTool: "SwiftVerificar",
                identifier: ["id1", "id2"],
                label: "Test Label",
                metadataDate: metadataDate,
                modifyDate: modifyDate,
                nickname: "TestDoc",
                rating: 4
            )

            #expect(schema.createDate == createDate)
            #expect(schema.creatorTool == "SwiftVerificar")
            #expect(schema.identifier == ["id1", "id2"])
            #expect(schema.label == "Test Label")
            #expect(schema.metadataDate == metadataDate)
            #expect(schema.modifyDate == modifyDate)
            #expect(schema.nickname == "TestDoc")
            #expect(schema.rating == 4)
        }

        @Test("Default initialization")
        func defaultInitialization() throws {
            let schema = XMPBasicSchema()

            #expect(schema.createDate == nil)
            #expect(schema.creatorTool == nil)
            #expect(schema.modifyDate == nil)
            #expect(schema.rating == nil)
        }

        @Test("Property names")
        func propertyNames() throws {
            let schema = XMPBasicSchema()
            let names = schema.propertyNames

            #expect(names.contains("CreateDate"))
            #expect(names.contains("CreatorTool"))
            #expect(names.contains("ModifyDate"))
            #expect(names.contains("Rating"))
        }
    }

    // MARK: - Property Access

    @Suite("Property Access")
    struct PropertyAccess {

        @Test("Get property by name")
        func getPropertyByName() throws {
            let date = Date()
            let schema = XMPBasicSchema(
                createDate: date,
                creatorTool: "Test Tool",
                rating: 3
            )

            #expect(schema.property(named: "CreateDate")?.dateValue == date)
            #expect(schema.property(named: "CreatorTool")?.textValue == "Test Tool")
            #expect(schema.property(named: "Rating")?.integerValue == 3)
        }

        @Test("Set property by name")
        func setPropertyByName() throws {
            var schema = XMPBasicSchema()
            let date = Date()

            schema.setProperty(named: "CreateDate", to: .date(date))
            schema.setProperty(named: "CreatorTool", to: .text("New Tool"))
            schema.setProperty(named: "Rating", to: .integer(5))

            #expect(schema.createDate == date)
            #expect(schema.creatorTool == "New Tool")
            #expect(schema.rating == 5)
        }

        @Test("Set identifier from bag")
        func setIdentifierFromBag() throws {
            var schema = XMPBasicSchema()

            schema.setProperty(named: "Identifier", to: .bag([.text("id1"), .text("id2")]))

            #expect(schema.identifier == ["id1", "id2"])
        }

        @Test("Set identifier from single text")
        func setIdentifierFromSingleText() throws {
            var schema = XMPBasicSchema()

            schema.setProperty(named: "Identifier", to: .text("single-id"))

            #expect(schema.identifier == ["single-id"])
        }
    }

    // MARK: - Rating

    @Suite("Rating")
    struct RatingTests {

        @Test("Rating interpretation - rejected")
        func ratingInterpretationRejected() throws {
            let schema = XMPBasicSchema(rating: -1)

            if case .rejected = schema.ratingInterpretation {
                // Expected
            } else {
                Issue.record("Expected rejected rating")
            }
        }

        @Test("Rating interpretation - unrated")
        func ratingInterpretationUnrated() throws {
            let schema = XMPBasicSchema(rating: 0)

            if case .unrated = schema.ratingInterpretation {
                // Expected
            } else {
                Issue.record("Expected unrated rating")
            }
        }

        @Test("Rating interpretation - rated")
        func ratingInterpretationRated() throws {
            let schema = XMPBasicSchema(rating: 4)

            if case .rated(let value) = schema.ratingInterpretation {
                #expect(value == 4)
            } else {
                Issue.record("Expected rated rating")
            }
        }

        @Test("Set rating from interpretation")
        func setRatingFromInterpretation() throws {
            var schema = XMPBasicSchema()

            schema.setRating(.rejected)
            #expect(schema.rating == -1)

            schema.setRating(.unrated)
            #expect(schema.rating == 0)

            schema.setRating(.rated(5))
            #expect(schema.rating == 5)
        }

        @Test("Rating interpretation numeric values")
        func ratingInterpretationNumericValues() throws {
            #expect(XMPBasicSchema.RatingInterpretation.rejected.numericValue == -1)
            #expect(XMPBasicSchema.RatingInterpretation.unrated.numericValue == 0)
            #expect(XMPBasicSchema.RatingInterpretation.rated(4).numericValue == 4)
        }
    }

    // MARK: - Validation

    @Suite("Validation")
    struct ValidationTests {

        @Test("Valid schema passes validation")
        func validSchemaPassesValidation() throws {
            let createDate = Date()
            let modifyDate = createDate.addingTimeInterval(3600)

            let schema = XMPBasicSchema(
                createDate: createDate,
                modifyDate: modifyDate,
                rating: 3
            )

            let issues = schema.validate()

            #expect(issues.filter { $0.severity == .error }.isEmpty)
        }

        @Test("Invalid rating warning")
        func invalidRatingWarning() throws {
            let schema = XMPBasicSchema(rating: 10) // Invalid: > 5

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "Rating" })
        }

        @Test("Negative invalid rating warning")
        func negativeInvalidRatingWarning() throws {
            let schema = XMPBasicSchema(rating: -5) // Invalid: < -1

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "Rating" })
        }

        @Test("ModifyDate before CreateDate warning")
        func modifyDateBeforeCreateDateWarning() throws {
            let createDate = Date()
            let modifyDate = createDate.addingTimeInterval(-3600) // Before create

            let schema = XMPBasicSchema(
                createDate: createDate,
                modifyDate: modifyDate
            )

            let issues = schema.validate()

            #expect(issues.contains { $0.propertyName == "ModifyDate" })
        }

        @Test("MetadataDate before ModifyDate info")
        func metadataDateBeforeModifyDateInfo() throws {
            let modifyDate = Date()
            let metadataDate = modifyDate.addingTimeInterval(-3600)

            let schema = XMPBasicSchema(
                metadataDate: metadataDate,
                modifyDate: modifyDate
            )

            let issues = schema.validate()

            #expect(issues.contains {
                $0.propertyName == "MetadataDate" && $0.severity == .info
            })
        }
    }

    // MARK: - XML Generation

    @Suite("XML Generation")
    struct XMLGenerationTests {

        @Test("Generate XML with dates")
        func generateXMLWithDates() throws {
            let date = Date()
            let schema = XMPBasicSchema(
                createDate: date,
                modifyDate: date
            )

            let xml = schema.toXML()

            #expect(xml.contains("<xmp:CreateDate>"))
            #expect(xml.contains("<xmp:ModifyDate>"))
        }

        @Test("Generate XML with creator tool")
        func generateXMLWithCreatorTool() throws {
            let schema = XMPBasicSchema(creatorTool: "SwiftVerificar 1.0")

            let xml = schema.toXML()

            #expect(xml.contains("<xmp:CreatorTool>SwiftVerificar 1.0</xmp:CreatorTool>"))
        }

        @Test("Generate XML with identifier bag")
        func generateXMLWithIdentifierBag() throws {
            let schema = XMPBasicSchema(identifier: ["id1", "id2"])

            let xml = schema.toXML()

            #expect(xml.contains("<xmp:Identifier>"))
            #expect(xml.contains("rdf:Bag"))
        }

        @Test("Generate XML with rating")
        func generateXMLWithRating() throws {
            let schema = XMPBasicSchema(rating: 4)

            let xml = schema.toXML()

            #expect(xml.contains("<xmp:Rating>4</xmp:Rating>"))
        }

        @Test("XML escapes special characters")
        func xmlEscapesSpecialCharacters() throws {
            let schema = XMPBasicSchema(creatorTool: "Tool <version> & more")

            let xml = schema.toXML()

            #expect(xml.contains("&lt;"))
            #expect(xml.contains("&amp;"))
        }

        @Test("Empty schema generates no XML")
        func emptySchemaGeneratesNoXML() throws {
            let schema = XMPBasicSchema()

            let xml = schema.toXML()

            #expect(xml.isEmpty)
        }
    }

    // MARK: - Property Descriptors

    @Suite("Property Descriptors")
    struct PropertyDescriptorTests {

        @Test("Property descriptors exist")
        func propertyDescriptorsExist() throws {
            let descriptors = XMPBasicSchema.propertyDescriptors

            #expect(descriptors.count == 8)
            #expect(descriptors.contains { $0.name == "CreateDate" })
            #expect(descriptors.contains { $0.name == "CreatorTool" })
            #expect(descriptors.contains { $0.name == "ModifyDate" })
        }

        @Test("Info dict key mapping")
        func infoDictKeyMapping() throws {
            let descriptors = XMPBasicSchema.propertyDescriptors

            let createDesc = descriptors.first { $0.name == "CreateDate" }
            #expect(createDesc?.infoDictKey == "CreationDate")

            let modifyDesc = descriptors.first { $0.name == "ModifyDate" }
            #expect(modifyDesc?.infoDictKey == "ModDate")

            let toolDesc = descriptors.first { $0.name == "CreatorTool" }
            #expect(toolDesc?.infoDictKey == "Creator")
        }
    }

    // MARK: - Synchronization

    @Suite("Synchronization")
    struct SynchronizationTests {

        @Test("Synchronized properties list")
        func synchronizedPropertiesList() throws {
            let synced = XMPBasicSchema.synchronizedProperties

            #expect(synced.count == 3)
            #expect(synced.contains { $0.xmpProperty == "CreateDate" && $0.infoDictKey == "CreationDate" })
            #expect(synced.contains { $0.xmpProperty == "ModifyDate" && $0.infoDictKey == "ModDate" })
            #expect(synced.contains { $0.xmpProperty == "CreatorTool" && $0.infoDictKey == "Creator" })
        }

        @Test("Create from Info dictionary")
        func createFromInfoDictionary() throws {
            let schema = XMPBasicSchema.fromInfoDictionary(
                creationDate: "D:20230615120000Z",
                modDate: "D:20230615130000Z",
                creator: "Test Creator"
            )

            #expect(schema.createDate != nil)
            #expect(schema.modifyDate != nil)
            #expect(schema.creatorTool == "Test Creator")
        }

        @Test("Create from Info dictionary with invalid dates")
        func createFromInfoDictionaryInvalidDates() throws {
            let schema = XMPBasicSchema.fromInfoDictionary(
                creationDate: "invalid",
                modDate: "invalid",
                creator: "Test"
            )

            #expect(schema.createDate == nil)
            #expect(schema.modifyDate == nil)
            #expect(schema.creatorTool == "Test")
        }

        @Test("Check synchronization - matching values")
        func checkSynchronizationMatching() throws {
            let date = Date()
            let pdfDateStr = date.toPDFDateString(timeZone: TimeZone(secondsFromGMT: 0)!)

            let schema = XMPBasicSchema(
                createDate: date,
                creatorTool: "Test Tool",
                modifyDate: date
            )

            let issues = schema.checkSynchronization(
                infoCreationDate: pdfDateStr,
                infoModDate: pdfDateStr,
                infoCreator: "Test Tool"
            )

            #expect(issues.isEmpty)
        }

        @Test("Check synchronization - mismatched dates")
        func checkSynchronizationMismatchedDates() throws {
            let xmpDate = Date()
            let differentDate = xmpDate.addingTimeInterval(3600)
            let infoPdfDate = differentDate.toPDFDateString()

            let schema = XMPBasicSchema(
                createDate: xmpDate,
                modifyDate: xmpDate
            )

            let issues = schema.checkSynchronization(
                infoCreationDate: infoPdfDate,
                infoModDate: infoPdfDate,
                infoCreator: nil
            )

            #expect(issues.count >= 2)
        }

        @Test("Check synchronization - invalid Info date format")
        func checkSynchronizationInvalidInfoDate() throws {
            let schema = XMPBasicSchema(createDate: Date())

            let issues = schema.checkSynchronization(
                infoCreationDate: "invalid-date",
                infoModDate: nil,
                infoCreator: nil
            )

            #expect(issues.contains { $0.message.contains("invalid format") })
        }

        @Test("Check synchronization - missing XMP values")
        func checkSynchronizationMissingXMP() throws {
            let schema = XMPBasicSchema()

            let issues = schema.checkSynchronization(
                infoCreationDate: "D:20230615120000Z",
                infoModDate: nil,
                infoCreator: "Tool"
            )

            #expect(issues.count == 2)
        }

        @Test("Check synchronization - missing Info values")
        func checkSynchronizationMissingInfo() throws {
            let schema = XMPBasicSchema(
                createDate: Date(),
                creatorTool: "Tool"
            )

            let issues = schema.checkSynchronization(
                infoCreationDate: nil,
                infoModDate: nil,
                infoCreator: nil
            )

            #expect(issues.count == 2)
        }
    }

    // MARK: - Equatable

    @Suite("Equatable")
    struct EquatableTests {

        @Test("Equal schemas")
        func equalSchemas() throws {
            let date = Date()
            let schema1 = XMPBasicSchema(
                createDate: date,
                creatorTool: "Tool"
            )
            let schema2 = XMPBasicSchema(
                createDate: date,
                creatorTool: "Tool"
            )

            #expect(schema1 == schema2)
        }

        @Test("Unequal schemas")
        func unequalSchemas() throws {
            let schema1 = XMPBasicSchema(creatorTool: "Tool 1")
            let schema2 = XMPBasicSchema(creatorTool: "Tool 2")

            #expect(schema1 != schema2)
        }
    }
}
