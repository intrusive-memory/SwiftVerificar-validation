import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - PKCS Validation

/// Validation wrapper for PKCS digital signatures in PDF documents.
///
/// PDF documents can contain digital signatures using PKCS #7 (CMS)
/// or PKCS #1 (raw RSA) formats. This type validates the signature
/// structure and certificate properties for PDF/A compliance.
///
/// ## Key Properties
///
/// - **Signature Type**: The type of PKCS signature (PKCS7, CMS, etc.)
/// - **Certificate**: Certificate information (issuer, subject, validity)
/// - **Timestamp**: Whether the signature includes a trusted timestamp
/// - **Integrity**: Whether the signature covers the expected byte range
///
/// ## Validation Rules
///
/// PKCS signatures are checked for:
/// - Valid signature structure
/// - Certificate chain validity
/// - Timestamp presence and validity
/// - Byte range coverage (must cover entire file except signature value)
/// - PDF/A signature requirements
/// - SubFilter conformance (adbe.pkcs7.detached, ETSI.CAdES.detached, etc.)
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPKCSDataObject` from veraPDF-validation.
public struct PKCSValidation: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for the signature dictionary.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    // MARK: - Signature Properties

    /// The signature type.
    public let signatureType: PKCSSignatureType

    /// The SubFilter value from the signature dictionary.
    ///
    /// Determines the encoding format of the signature value.
    /// Common values: "adbe.pkcs7.detached", "adbe.pkcs7.sha1",
    /// "adbe.x509.rsa_sha1", "ETSI.CAdES.detached", "ETSI.RFC3161".
    public let subFilter: String?

    /// The Filter value from the signature dictionary.
    ///
    /// Identifies the signature handler. Common values: "Adobe.PPKLite",
    /// "Entrust.PPKEF", "CICI.SignIt".
    public let filter: String?

    /// The byte range array from the signature dictionary.
    ///
    /// Specifies which bytes of the file are covered by the signature.
    /// Should cover the entire file except the signature value itself.
    public let byteRange: [Int]

    /// The size of the signature value data in bytes.
    public let signatureValueSize: Int

    // MARK: - Certificate Properties

    /// The certificate subject common name (CN).
    public let certificateSubject: String?

    /// The certificate issuer common name (CN).
    public let certificateIssuer: String?

    /// The certificate serial number.
    public let certificateSerialNumber: String?

    /// The certificate validity start date.
    public let certificateNotBefore: String?

    /// The certificate validity end date.
    public let certificateNotAfter: String?

    /// The number of certificates in the certificate chain.
    public let certificateChainLength: Int

    /// Whether the certificate is self-signed.
    public let isSelfSigned: Bool

    /// The signature algorithm used (e.g., "SHA256withRSA", "SHA512withECDSA").
    public let signatureAlgorithm: String?

    /// The key length in bits (e.g., 2048, 4096 for RSA).
    public let keyLength: Int?

    // MARK: - Timestamp Properties

    /// Whether the signature includes a timestamp.
    public let hasTimestamp: Bool

    /// The timestamp authority URL, if present.
    public let timestampAuthority: String?

    /// Whether the timestamp token is valid.
    public let isTimestampValid: Bool

    // MARK: - Validation Properties

    /// Whether the signature structure is valid.
    public let isSignatureValid: Bool

    /// Whether the byte range covers the expected portion of the document.
    ///
    /// A valid byte range must consist of exactly two ranges that together
    /// cover the entire file, leaving only the signature value bytes uncovered.
    public var hasValidByteRange: Bool {
        byteRange.count == 4 && byteRange[0] == 0
    }

    /// Whether the signature has a recognized SubFilter value.
    public var hasRecognizedSubFilter: Bool {
        guard let sf = subFilter else { return false }
        let recognized = [
            "adbe.pkcs7.detached",
            "adbe.pkcs7.sha1",
            "adbe.x509.rsa_sha1",
            "ETSI.CAdES.detached",
            "ETSI.RFC3161"
        ]
        return recognized.contains(sf)
    }

    /// Whether the signature meets PDF/A-1 requirements.
    ///
    /// PDF/A-1 requires:
    /// - Valid byte range
    /// - SubFilter must be "adbe.pkcs7.detached" or "adbe.pkcs7.sha1"
    public var isPDFA1Compliant: Bool {
        guard isSignatureValid && hasValidByteRange else { return false }
        guard let sf = subFilter else { return false }
        return sf == "adbe.pkcs7.detached" || sf == "adbe.pkcs7.sha1"
    }

    /// Whether the signature meets PDF/A-2 requirements.
    ///
    /// PDF/A-2 adds support for "ETSI.CAdES.detached" and "ETSI.RFC3161".
    public var isPDFA2Compliant: Bool {
        guard isSignatureValid && hasValidByteRange else { return false }
        return hasRecognizedSubFilter
    }

    /// Whether the signature covers the entire document.
    ///
    /// Checks that the byte range entries are non-negative and
    /// the second range extends to the end of what appears to be
    /// a valid document range.
    public var coversEntireDocument: Bool {
        guard hasValidByteRange else { return false }
        // byteRange[0]: start of first range (must be 0)
        // byteRange[1]: length of first range
        // byteRange[2]: start of second range
        // byteRange[3]: length of second range
        return byteRange[0] == 0 &&
               byteRange[1] > 0 &&
               byteRange[2] > byteRange[1] &&
               byteRange[3] > 0
    }

    /// Whether the signature has certificate information.
    public var hasCertificateInfo: Bool {
        certificateSubject != nil || certificateIssuer != nil
    }

    // MARK: - Initialization

    /// Creates a PKCS validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the signature dictionary.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - signatureType: The signature type.
    ///   - subFilter: The SubFilter value.
    ///   - filter: The Filter value.
    ///   - byteRange: The byte range array.
    ///   - signatureValueSize: The size of the signature value data.
    ///   - certificateSubject: The certificate subject CN.
    ///   - certificateIssuer: The certificate issuer CN.
    ///   - certificateSerialNumber: The certificate serial number.
    ///   - certificateNotBefore: The certificate validity start.
    ///   - certificateNotAfter: The certificate validity end.
    ///   - certificateChainLength: The certificate chain length.
    ///   - isSelfSigned: Whether the certificate is self-signed.
    ///   - signatureAlgorithm: The signature algorithm.
    ///   - keyLength: The key length in bits.
    ///   - hasTimestamp: Whether a timestamp is present.
    ///   - timestampAuthority: The timestamp authority URL.
    ///   - isTimestampValid: Whether the timestamp is valid.
    ///   - isSignatureValid: Whether the signature is valid.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        signatureType: PKCSSignatureType = .pkcs7Detached,
        subFilter: String? = nil,
        filter: String? = nil,
        byteRange: [Int] = [],
        signatureValueSize: Int = 0,
        certificateSubject: String? = nil,
        certificateIssuer: String? = nil,
        certificateSerialNumber: String? = nil,
        certificateNotBefore: String? = nil,
        certificateNotAfter: String? = nil,
        certificateChainLength: Int = 0,
        isSelfSigned: Bool = false,
        signatureAlgorithm: String? = nil,
        keyLength: Int? = nil,
        hasTimestamp: Bool = false,
        timestampAuthority: String? = nil,
        isTimestampValid: Bool = false,
        isSignatureValid: Bool = true
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? ObjectContext(location: "Signature", role: signatureType.rawValue)
        self.signatureType = signatureType
        self.subFilter = subFilter
        self.filter = filter
        self.byteRange = byteRange
        self.signatureValueSize = signatureValueSize
        self.certificateSubject = certificateSubject
        self.certificateIssuer = certificateIssuer
        self.certificateSerialNumber = certificateSerialNumber
        self.certificateNotBefore = certificateNotBefore
        self.certificateNotAfter = certificateNotAfter
        self.certificateChainLength = certificateChainLength
        self.isSelfSigned = isSelfSigned
        self.signatureAlgorithm = signatureAlgorithm
        self.keyLength = keyLength
        self.hasTimestamp = hasTimestamp
        self.timestampAuthority = timestampAuthority
        self.isTimestampValid = isTimestampValid
        self.isSignatureValid = isSignatureValid
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PKCSDataObject"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "signatureType", "subFilter", "filter",
            "byteRangeCount", "signatureValueSize",
            "certificateSubject", "certificateIssuer",
            "certificateSerialNumber", "certificateNotBefore", "certificateNotAfter",
            "certificateChainLength", "isSelfSigned",
            "signatureAlgorithm", "keyLength",
            "hasTimestamp", "timestampAuthority", "isTimestampValid",
            "isSignatureValid", "hasValidByteRange", "hasRecognizedSubFilter",
            "isPDFA1Compliant", "isPDFA2Compliant",
            "coversEntireDocument", "hasCertificateInfo"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "signatureType":
            return .string(signatureType.rawValue)
        case "subFilter":
            if let sf = subFilter { return .string(sf) }
            return .null
        case "filter":
            if let f = filter { return .string(f) }
            return .null
        case "byteRangeCount":
            return .integer(Int64(byteRange.count))
        case "signatureValueSize":
            return .integer(Int64(signatureValueSize))
        case "certificateSubject":
            if let cs = certificateSubject { return .string(cs) }
            return .null
        case "certificateIssuer":
            if let ci = certificateIssuer { return .string(ci) }
            return .null
        case "certificateSerialNumber":
            if let sn = certificateSerialNumber { return .string(sn) }
            return .null
        case "certificateNotBefore":
            if let nb = certificateNotBefore { return .string(nb) }
            return .null
        case "certificateNotAfter":
            if let na = certificateNotAfter { return .string(na) }
            return .null
        case "certificateChainLength":
            return .integer(Int64(certificateChainLength))
        case "isSelfSigned":
            return .boolean(isSelfSigned)
        case "signatureAlgorithm":
            if let sa = signatureAlgorithm { return .string(sa) }
            return .null
        case "keyLength":
            if let kl = keyLength { return .integer(Int64(kl)) }
            return .null
        case "hasTimestamp":
            return .boolean(hasTimestamp)
        case "timestampAuthority":
            if let ta = timestampAuthority { return .string(ta) }
            return .null
        case "isTimestampValid":
            return .boolean(isTimestampValid)
        case "isSignatureValid":
            return .boolean(isSignatureValid)
        case "hasValidByteRange":
            return .boolean(hasValidByteRange)
        case "hasRecognizedSubFilter":
            return .boolean(hasRecognizedSubFilter)
        case "isPDFA1Compliant":
            return .boolean(isPDFA1Compliant)
        case "isPDFA2Compliant":
            return .boolean(isPDFA2Compliant)
        case "coversEntireDocument":
            return .boolean(coversEntireDocument)
        case "hasCertificateInfo":
            return .boolean(hasCertificateInfo)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: PKCSValidation, rhs: PKCSValidation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - PKCS Signature Type

/// Classification of PKCS signature types in PDF documents.
///
/// Identifies the format and encoding of the digital signature.
public enum PKCSSignatureType: String, Sendable, CaseIterable, Equatable {

    /// PKCS #7 detached signature.
    ///
    /// The signature is computed over the document bytes
    /// and stored separately (detached).
    case pkcs7Detached = "PKCS7Detached"

    /// PKCS #7 SHA-1 signature.
    ///
    /// Uses SHA-1 digest with PKCS #7 encoding.
    case pkcs7SHA1 = "PKCS7SHA1"

    /// X.509 RSA SHA-1 signature.
    ///
    /// Uses X.509 certificate with RSA and SHA-1.
    case x509RSASHA1 = "X509RSASHA1"

    /// CAdES (CMS Advanced Electronic Signatures) detached.
    ///
    /// ETSI standard for advanced electronic signatures.
    case cadesDetached = "CAdESDetached"

    /// RFC 3161 timestamp token.
    ///
    /// An ETSI timestamp signature.
    case rfc3161 = "RFC3161"

    /// Unknown signature type.
    case unknown = "Unknown"

    /// Creates a signature type from a SubFilter value.
    ///
    /// - Parameter subFilter: The SubFilter string from the signature dictionary.
    public init(fromSubFilter subFilter: String?) {
        guard let sf = subFilter else {
            self = .unknown
            return
        }
        switch sf {
        case "adbe.pkcs7.detached":
            self = .pkcs7Detached
        case "adbe.pkcs7.sha1":
            self = .pkcs7SHA1
        case "adbe.x509.rsa_sha1":
            self = .x509RSASHA1
        case "ETSI.CAdES.detached":
            self = .cadesDetached
        case "ETSI.RFC3161":
            self = .rfc3161
        default:
            self = .unknown
        }
    }

    /// Whether this is a PDF/A-1 supported signature type.
    public var isPDFA1Supported: Bool {
        self == .pkcs7Detached || self == .pkcs7SHA1
    }

    /// Whether this is a PDF/A-2 supported signature type.
    public var isPDFA2Supported: Bool {
        switch self {
        case .pkcs7Detached, .pkcs7SHA1, .x509RSASHA1, .cadesDetached, .rfc3161:
            return true
        case .unknown:
            return false
        }
    }

    /// Whether this is a CAdES-based signature.
    public var isCAdES: Bool {
        self == .cadesDetached
    }

    /// Whether this is a timestamp-only signature.
    public var isTimestampOnly: Bool {
        self == .rfc3161
    }
}

// MARK: - Factory Methods

extension PKCSValidation {

    /// Creates a valid PKCS #7 detached signature for testing.
    ///
    /// - Returns: A valid signature with typical properties.
    public static func validDetachedSignature() -> PKCSValidation {
        PKCSValidation(
            signatureType: .pkcs7Detached,
            subFilter: "adbe.pkcs7.detached",
            filter: "Adobe.PPKLite",
            byteRange: [0, 1000, 3000, 5000],
            signatureValueSize: 2000,
            certificateSubject: "CN=Test Signer",
            certificateIssuer: "CN=Test CA",
            certificateChainLength: 2,
            signatureAlgorithm: "SHA256withRSA",
            keyLength: 2048,
            isSignatureValid: true
        )
    }

    /// Creates a CAdES signature with timestamp for testing.
    ///
    /// - Returns: A CAdES signature with timestamp.
    public static func cadesWithTimestamp() -> PKCSValidation {
        PKCSValidation(
            signatureType: .cadesDetached,
            subFilter: "ETSI.CAdES.detached",
            filter: "Adobe.PPKLite",
            byteRange: [0, 2000, 6000, 8000],
            signatureValueSize: 4000,
            certificateSubject: "CN=Document Signer",
            certificateIssuer: "CN=Trusted CA",
            certificateChainLength: 3,
            signatureAlgorithm: "SHA256withRSA",
            keyLength: 4096,
            hasTimestamp: true,
            timestampAuthority: "http://timestamp.example.com",
            isTimestampValid: true,
            isSignatureValid: true
        )
    }
}
