import Testing
import Foundation
@testable import SwiftVerificarValidation

// MARK: - PKCS Validation Tests

@Suite("PKCSValidation")
struct PKCSValidationTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let sig = PKCSValidation()
        #expect(sig.signatureType == .pkcs7Detached)
        #expect(sig.subFilter == nil)
        #expect(sig.filter == nil)
        #expect(sig.byteRange.isEmpty)
        #expect(sig.signatureValueSize == 0)
        #expect(sig.certificateSubject == nil)
        #expect(sig.certificateIssuer == nil)
        #expect(sig.certificateSerialNumber == nil)
        #expect(sig.certificateNotBefore == nil)
        #expect(sig.certificateNotAfter == nil)
        #expect(sig.certificateChainLength == 0)
        #expect(sig.isSelfSigned == false)
        #expect(sig.signatureAlgorithm == nil)
        #expect(sig.keyLength == nil)
        #expect(sig.hasTimestamp == false)
        #expect(sig.timestampAuthority == nil)
        #expect(sig.isTimestampValid == false)
        #expect(sig.isSignatureValid == true)
    }

    @Test("Custom initialization with certificate info")
    func customInitWithCertificate() {
        let sig = PKCSValidation(
            signatureType: .pkcs7Detached,
            subFilter: "adbe.pkcs7.detached",
            filter: "Adobe.PPKLite",
            byteRange: [0, 1000, 3000, 5000],
            signatureValueSize: 2000,
            certificateSubject: "CN=John Doe",
            certificateIssuer: "CN=Test CA",
            certificateSerialNumber: "12345",
            certificateNotBefore: "2024-01-01",
            certificateNotAfter: "2025-01-01",
            certificateChainLength: 3,
            isSelfSigned: false,
            signatureAlgorithm: "SHA256withRSA",
            keyLength: 2048
        )
        #expect(sig.certificateSubject == "CN=John Doe")
        #expect(sig.certificateIssuer == "CN=Test CA")
        #expect(sig.certificateSerialNumber == "12345")
        #expect(sig.certificateChainLength == 3)
        #expect(sig.signatureAlgorithm == "SHA256withRSA")
        #expect(sig.keyLength == 2048)
    }

    // MARK: - Byte Range Tests

    @Test("Valid byte range with 4 entries starting at 0")
    func validByteRange() {
        let sig = PKCSValidation(byteRange: [0, 1000, 3000, 5000])
        #expect(sig.hasValidByteRange == true)
    }

    @Test("Invalid byte range with non-zero start")
    func invalidByteRangeNonZeroStart() {
        let sig = PKCSValidation(byteRange: [100, 1000, 3000, 5000])
        #expect(sig.hasValidByteRange == false)
    }

    @Test("Invalid byte range with wrong count")
    func invalidByteRangeWrongCount() {
        let sig = PKCSValidation(byteRange: [0, 1000])
        #expect(sig.hasValidByteRange == false)
    }

    @Test("Invalid byte range empty")
    func invalidByteRangeEmpty() {
        let sig = PKCSValidation(byteRange: [])
        #expect(sig.hasValidByteRange == false)
    }

    // MARK: - SubFilter Tests

    @Test("Recognized SubFilter values")
    func recognizedSubFilters() {
        let pkcs7d = PKCSValidation(subFilter: "adbe.pkcs7.detached")
        #expect(pkcs7d.hasRecognizedSubFilter == true)

        let pkcs7s = PKCSValidation(subFilter: "adbe.pkcs7.sha1")
        #expect(pkcs7s.hasRecognizedSubFilter == true)

        let x509 = PKCSValidation(subFilter: "adbe.x509.rsa_sha1")
        #expect(x509.hasRecognizedSubFilter == true)

        let cades = PKCSValidation(subFilter: "ETSI.CAdES.detached")
        #expect(cades.hasRecognizedSubFilter == true)

        let rfc3161 = PKCSValidation(subFilter: "ETSI.RFC3161")
        #expect(rfc3161.hasRecognizedSubFilter == true)
    }

    @Test("Unrecognized SubFilter values")
    func unrecognizedSubFilter() {
        let sig = PKCSValidation(subFilter: "custom.signature")
        #expect(sig.hasRecognizedSubFilter == false)
    }

    @Test("Nil SubFilter is not recognized")
    func nilSubFilter() {
        let sig = PKCSValidation(subFilter: nil)
        #expect(sig.hasRecognizedSubFilter == false)
    }

    // MARK: - PDF/A Compliance Tests

    @Test("PDF/A-1 compliant with pkcs7.detached")
    func pdfa1CompliantDetached() {
        let sig = PKCSValidation(
            subFilter: "adbe.pkcs7.detached",
            byteRange: [0, 1000, 3000, 5000],
            isSignatureValid: true
        )
        #expect(sig.isPDFA1Compliant == true)
    }

    @Test("PDF/A-1 compliant with pkcs7.sha1")
    func pdfa1CompliantSHA1() {
        let sig = PKCSValidation(
            subFilter: "adbe.pkcs7.sha1",
            byteRange: [0, 1000, 3000, 5000],
            isSignatureValid: true
        )
        #expect(sig.isPDFA1Compliant == true)
    }

    @Test("PDF/A-1 non-compliant with CAdES")
    func pdfa1NonCompliantCAdES() {
        let sig = PKCSValidation(
            subFilter: "ETSI.CAdES.detached",
            byteRange: [0, 1000, 3000, 5000],
            isSignatureValid: true
        )
        #expect(sig.isPDFA1Compliant == false)
    }

    @Test("PDF/A-1 non-compliant with invalid signature")
    func pdfa1NonCompliantInvalidSig() {
        let sig = PKCSValidation(
            subFilter: "adbe.pkcs7.detached",
            byteRange: [0, 1000, 3000, 5000],
            isSignatureValid: false
        )
        #expect(sig.isPDFA1Compliant == false)
    }

    @Test("PDF/A-1 non-compliant with invalid byte range")
    func pdfa1NonCompliantInvalidRange() {
        let sig = PKCSValidation(
            subFilter: "adbe.pkcs7.detached",
            byteRange: [],
            isSignatureValid: true
        )
        #expect(sig.isPDFA1Compliant == false)
    }

    @Test("PDF/A-1 non-compliant with nil SubFilter")
    func pdfa1NonCompliantNilSubFilter() {
        let sig = PKCSValidation(
            byteRange: [0, 1000, 3000, 5000],
            isSignatureValid: true
        )
        #expect(sig.isPDFA1Compliant == false)
    }

    @Test("PDF/A-2 compliant with CAdES")
    func pdfa2CompliantCAdES() {
        let sig = PKCSValidation(
            subFilter: "ETSI.CAdES.detached",
            byteRange: [0, 1000, 3000, 5000],
            isSignatureValid: true
        )
        #expect(sig.isPDFA2Compliant == true)
    }

    @Test("PDF/A-2 compliant with RFC 3161")
    func pdfa2CompliantRFC3161() {
        let sig = PKCSValidation(
            subFilter: "ETSI.RFC3161",
            byteRange: [0, 1000, 3000, 5000],
            isSignatureValid: true
        )
        #expect(sig.isPDFA2Compliant == true)
    }

    @Test("PDF/A-2 non-compliant with unknown SubFilter")
    func pdfa2NonCompliantUnknown() {
        let sig = PKCSValidation(
            subFilter: "custom.signature",
            byteRange: [0, 1000, 3000, 5000],
            isSignatureValid: true
        )
        #expect(sig.isPDFA2Compliant == false)
    }

    // MARK: - Covers Entire Document Tests

    @Test("Covers entire document with valid range")
    func coversDocument() {
        let sig = PKCSValidation(byteRange: [0, 1000, 3000, 5000])
        #expect(sig.coversEntireDocument == true)
    }

    @Test("Does not cover document with zero first length")
    func doesNotCoverZeroFirstLen() {
        let sig = PKCSValidation(byteRange: [0, 0, 3000, 5000])
        #expect(sig.coversEntireDocument == false)
    }

    @Test("Does not cover document with overlapping ranges")
    func doesNotCoverOverlapping() {
        let sig = PKCSValidation(byteRange: [0, 5000, 3000, 5000])
        #expect(sig.coversEntireDocument == false)
    }

    @Test("Does not cover document with zero second length")
    func doesNotCoverZeroSecondLen() {
        let sig = PKCSValidation(byteRange: [0, 1000, 3000, 0])
        #expect(sig.coversEntireDocument == false)
    }

    @Test("Does not cover with invalid byte range")
    func doesNotCoverInvalidRange() {
        let sig = PKCSValidation(byteRange: [])
        #expect(sig.coversEntireDocument == false)
    }

    // MARK: - Certificate Info Tests

    @Test("Has certificate info with subject")
    func hasCertInfoSubject() {
        let sig = PKCSValidation(certificateSubject: "CN=Test")
        #expect(sig.hasCertificateInfo == true)
    }

    @Test("Has certificate info with issuer")
    func hasCertInfoIssuer() {
        let sig = PKCSValidation(certificateIssuer: "CN=CA")
        #expect(sig.hasCertificateInfo == true)
    }

    @Test("No certificate info")
    func noCertInfo() {
        let sig = PKCSValidation()
        #expect(sig.hasCertificateInfo == false)
    }

    // MARK: - PKCSSignatureType Tests

    @Test("Signature type from SubFilter")
    func signatureTypeFromSubFilter() {
        #expect(PKCSSignatureType(fromSubFilter: "adbe.pkcs7.detached") == .pkcs7Detached)
        #expect(PKCSSignatureType(fromSubFilter: "adbe.pkcs7.sha1") == .pkcs7SHA1)
        #expect(PKCSSignatureType(fromSubFilter: "adbe.x509.rsa_sha1") == .x509RSASHA1)
        #expect(PKCSSignatureType(fromSubFilter: "ETSI.CAdES.detached") == .cadesDetached)
        #expect(PKCSSignatureType(fromSubFilter: "ETSI.RFC3161") == .rfc3161)
        #expect(PKCSSignatureType(fromSubFilter: "custom") == .unknown)
        #expect(PKCSSignatureType(fromSubFilter: nil) == .unknown)
    }

    @Test("Signature type PDF/A-1 support")
    func signatureTypePDFA1() {
        #expect(PKCSSignatureType.pkcs7Detached.isPDFA1Supported == true)
        #expect(PKCSSignatureType.pkcs7SHA1.isPDFA1Supported == true)
        #expect(PKCSSignatureType.x509RSASHA1.isPDFA1Supported == false)
        #expect(PKCSSignatureType.cadesDetached.isPDFA1Supported == false)
        #expect(PKCSSignatureType.rfc3161.isPDFA1Supported == false)
        #expect(PKCSSignatureType.unknown.isPDFA1Supported == false)
    }

    @Test("Signature type PDF/A-2 support")
    func signatureTypePDFA2() {
        #expect(PKCSSignatureType.pkcs7Detached.isPDFA2Supported == true)
        #expect(PKCSSignatureType.pkcs7SHA1.isPDFA2Supported == true)
        #expect(PKCSSignatureType.x509RSASHA1.isPDFA2Supported == true)
        #expect(PKCSSignatureType.cadesDetached.isPDFA2Supported == true)
        #expect(PKCSSignatureType.rfc3161.isPDFA2Supported == true)
        #expect(PKCSSignatureType.unknown.isPDFA2Supported == false)
    }

    @Test("Signature type CAdES and timestamp flags")
    func signatureTypeCAdESAndTimestamp() {
        #expect(PKCSSignatureType.cadesDetached.isCAdES == true)
        #expect(PKCSSignatureType.pkcs7Detached.isCAdES == false)

        #expect(PKCSSignatureType.rfc3161.isTimestampOnly == true)
        #expect(PKCSSignatureType.cadesDetached.isTimestampOnly == false)
    }

    @Test("Signature type CaseIterable")
    func signatureTypeCaseIterable() {
        #expect(PKCSSignatureType.allCases.count == 6)
    }

    // MARK: - PDFObject Conformance Tests

    @Test("Object type is PKCSDataObject")
    func objectType() {
        let sig = PKCSValidation()
        #expect(sig.objectType == "PKCSDataObject")
    }

    @Test("Property names are populated")
    func propertyNames() {
        let sig = PKCSValidation()
        #expect(sig.propertyNames.contains("signatureType"))
        #expect(sig.propertyNames.contains("subFilter"))
        #expect(sig.propertyNames.contains("isPDFA1Compliant"))
        #expect(sig.propertyNames.contains("coversEntireDocument"))
    }

    @Test("Property access for string values")
    func propertyAccessStrings() {
        let sig = PKCSValidation(
            signatureType: .pkcs7Detached,
            subFilter: "adbe.pkcs7.detached",
            filter: "Adobe.PPKLite",
            certificateSubject: "CN=Test",
            certificateIssuer: "CN=CA",
            certificateSerialNumber: "12345",
            certificateNotBefore: "2024-01-01",
            certificateNotAfter: "2025-01-01",
            signatureAlgorithm: "SHA256withRSA",
            timestampAuthority: "http://tsa.example.com"
        )
        #expect(sig.property(named: "signatureType")?.stringValue == "PKCS7Detached")
        #expect(sig.property(named: "subFilter")?.stringValue == "adbe.pkcs7.detached")
        #expect(sig.property(named: "filter")?.stringValue == "Adobe.PPKLite")
        #expect(sig.property(named: "certificateSubject")?.stringValue == "CN=Test")
        #expect(sig.property(named: "certificateIssuer")?.stringValue == "CN=CA")
        #expect(sig.property(named: "certificateSerialNumber")?.stringValue == "12345")
        #expect(sig.property(named: "certificateNotBefore")?.stringValue == "2024-01-01")
        #expect(sig.property(named: "certificateNotAfter")?.stringValue == "2025-01-01")
        #expect(sig.property(named: "signatureAlgorithm")?.stringValue == "SHA256withRSA")
        #expect(sig.property(named: "timestampAuthority")?.stringValue == "http://tsa.example.com")
    }

    @Test("Property access for integer values")
    func propertyAccessIntegers() {
        let sig = PKCSValidation(
            byteRange: [0, 1000, 3000, 5000],
            signatureValueSize: 2000,
            certificateChainLength: 3,
            keyLength: 2048
        )
        #expect(sig.property(named: "byteRangeCount")?.integerValue == 4)
        #expect(sig.property(named: "signatureValueSize")?.integerValue == 2000)
        #expect(sig.property(named: "certificateChainLength")?.integerValue == 3)
        #expect(sig.property(named: "keyLength")?.integerValue == 2048)
    }

    @Test("Property access for boolean values")
    func propertyAccessBooleans() {
        let sig = PKCSValidation(
            isSelfSigned: true,
            hasTimestamp: true,
            isTimestampValid: true,
            isSignatureValid: true
        )
        #expect(sig.property(named: "isSelfSigned")?.boolValue == true)
        #expect(sig.property(named: "hasTimestamp")?.boolValue == true)
        #expect(sig.property(named: "isTimestampValid")?.boolValue == true)
        #expect(sig.property(named: "isSignatureValid")?.boolValue == true)
    }

    @Test("Property access for null values")
    func propertyAccessNulls() {
        let sig = PKCSValidation()
        #expect(sig.property(named: "subFilter")?.isNull == true)
        #expect(sig.property(named: "filter")?.isNull == true)
        #expect(sig.property(named: "certificateSubject")?.isNull == true)
        #expect(sig.property(named: "certificateIssuer")?.isNull == true)
        #expect(sig.property(named: "signatureAlgorithm")?.isNull == true)
        #expect(sig.property(named: "keyLength")?.isNull == true)
        #expect(sig.property(named: "timestampAuthority")?.isNull == true)
    }

    @Test("Property access for unknown property returns nil")
    func propertyAccessUnknown() {
        let sig = PKCSValidation()
        #expect(sig.property(named: "unknownProperty") == nil)
    }

    // MARK: - Factory Method Tests

    @Test("Valid detached signature factory")
    func validDetachedFactory() {
        let sig = PKCSValidation.validDetachedSignature()
        #expect(sig.signatureType == .pkcs7Detached)
        #expect(sig.subFilter == "adbe.pkcs7.detached")
        #expect(sig.filter == "Adobe.PPKLite")
        #expect(sig.hasValidByteRange == true)
        #expect(sig.isSignatureValid == true)
        #expect(sig.hasCertificateInfo == true)
        #expect(sig.isPDFA1Compliant == true)
    }

    @Test("CAdES with timestamp factory")
    func cadesWithTimestampFactory() {
        let sig = PKCSValidation.cadesWithTimestamp()
        #expect(sig.signatureType == .cadesDetached)
        #expect(sig.subFilter == "ETSI.CAdES.detached")
        #expect(sig.hasTimestamp == true)
        #expect(sig.isTimestampValid == true)
        #expect(sig.keyLength == 4096)
        #expect(sig.isPDFA2Compliant == true)
        #expect(sig.isPDFA1Compliant == false)
    }

    // MARK: - Equatable Tests

    @Test("Equatable by id")
    func equatable() {
        let id = UUID()
        let s1 = PKCSValidation(id: id, signatureType: .pkcs7Detached)
        let s2 = PKCSValidation(id: id, signatureType: .cadesDetached)
        #expect(s1 == s2)
    }

    @Test("Not equal with different ids")
    func notEqual() {
        let s1 = PKCSValidation()
        let s2 = PKCSValidation()
        #expect(s1 != s2)
    }

    // MARK: - Protocol Conformance Tests

    @Test("Conforms to PDValidationObject")
    func conformsToPDValidationObject() {
        let sig = PKCSValidation()
        let _: any PDValidationObject = sig
        #expect(sig.objectType == "PKCSDataObject")
    }

    @Test("Validation context defaults")
    func validationContextDefaults() {
        let sig = PKCSValidation(signatureType: .cadesDetached)
        #expect(sig.validationContext.location == "Signature")
        #expect(sig.validationContext.role == "CAdESDetached")
    }

    @Test("Custom validation context")
    func customValidationContext() {
        let ctx = ObjectContext(pageNumber: 1, location: "SignatureField")
        let sig = PKCSValidation(context: ctx)
        #expect(sig.validationContext.pageNumber == 1)
        #expect(sig.validationContext.location == "SignatureField")
    }
}
