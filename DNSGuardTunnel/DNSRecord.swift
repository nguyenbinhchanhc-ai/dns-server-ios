//
//  DNSRecord.swift
//  DNSGuardTunnel
//
//  Created for iOS Local DNS VPN & Optimizer.
//  DNS wire format data models according to RFC 1035, RFC 3596, RFC 6891.
//

import Foundation

public enum DNSType: UInt16 {
    case a = 1
    case ns = 2
    case cname = 5
    case soa = 6
    case ptr = 12
    case mx = 15
    case txt = 16
    case aaaa = 28
    case srv = 33
    case opt = 41
    case https = 65
    case any = 255
    case unknown = 0
    
    public init(rawValue: UInt16) {
        switch rawValue {
        case 1: self = .a
        case 2: self = .ns
        case 5: self = .cname
        case 6: self = .soa
        case 12: self = .ptr
        case 15: self = .mx
        case 16: self = .txt
        case 28: self = .aaaa
        case 33: self = .srv
        case 41: self = .opt
        case 65: self = .https
        case 255: self = .any
        default: self = .unknown
        }
    }
    
    public var name: String {
        switch self {
        case .a: return "A"
        case .ns: return "NS"
        case .cname: return "CNAME"
        case .soa: return "SOA"
        case .ptr: return "PTR"
        case .mx: return "MX"
        case .txt: return "TXT"
        case .aaaa: return "AAAA"
        case .srv: return "SRV"
        case .opt: return "OPT"
        case .https: return "HTTPS"
        case .any: return "ANY"
        case .unknown: return "UNKNOWN"
        }
    }
}

public enum DNSResponseCode: UInt8 {
    case noError = 0
    case formatError = 1
    case serverFailure = 2
    case nameError = 3 // NXDOMAIN
    case notImplemented = 4
    case refused = 5
    case unknown = 15
}

public struct DNSHeader {
    public var id: UInt16
    public var isResponse: Bool           // QR
    public var opcode: UInt8              // 4 bits
    public var isAuthoritative: Bool      // AA
    public var isTruncated: Bool          // TC
    public var recursionDesired: Bool     // RD
    public var recursionAvailable: Bool   // RA
    public var responseCode: DNSResponseCode // RCODE
    public var questionCount: UInt16      // QDCOUNT
    public var answerCount: UInt16        // ANCOUNT
    public var authorityCount: UInt16     // NSCOUNT
    public var additionalCount: UInt16    // ARCOUNT
    
    public init(id: UInt16 = UInt16.random(in: 1...65535),
                isResponse: Bool = false,
                opcode: UInt8 = 0,
                isAuthoritative: Bool = false,
                isTruncated: Bool = false,
                recursionDesired: Bool = true,
                recursionAvailable: Bool = false,
                responseCode: DNSResponseCode = .noError,
                questionCount: UInt16 = 1,
                answerCount: UInt16 = 0,
                authorityCount: UInt16 = 0,
                additionalCount: UInt16 = 0) {
        self.id = id
        self.isResponse = isResponse
        self.opcode = opcode
        self.isAuthoritative = isAuthoritative
        self.isTruncated = isTruncated
        self.recursionDesired = recursionDesired
        self.recursionAvailable = recursionAvailable
        self.responseCode = responseCode
        self.questionCount = questionCount
        self.answerCount = answerCount
        self.authorityCount = authorityCount
        self.additionalCount = additionalCount
    }
}

public struct DNSQuestion: Hashable {
    public var name: String
    public var type: DNSType
    public var queryClass: UInt16 // Usually 1 (IN)
    
    public init(name: String, type: DNSType, queryClass: UInt16 = 1) {
        self.name = name
        self.type = type
        self.queryClass = queryClass
    }
}

public struct DNSResourceRecord {
    public var name: String
    public var type: DNSType
    public var recordClass: UInt16
    public var ttl: UInt32
    public var data: Data
    public var displayValue: String
    
    public init(name: String, type: DNSType, recordClass: UInt16 = 1, ttl: UInt32, data: Data, displayValue: String = "") {
        self.name = name
        self.type = type
        self.recordClass = recordClass
        self.ttl = ttl
        self.data = data
        self.displayValue = displayValue
    }
}

public struct DNSPacket {
    public var header: DNSHeader
    public var questions: [DNSQuestion]
    public var answers: [DNSResourceRecord]
    public var authorities: [DNSResourceRecord]
    public var additionals: [DNSResourceRecord]
    public var rawData: Data
    
    public init(header: DNSHeader,
                questions: [DNSQuestion] = [],
                answers: [DNSResourceRecord] = [],
                authorities: [DNSResourceRecord] = [],
                additionals: [DNSResourceRecord] = [],
                rawData: Data = Data()) {
        self.header = header
        self.questions = questions
        self.answers = answers
        self.authorities = authorities
        self.additionals = additionals
        self.rawData = rawData
    }
}
