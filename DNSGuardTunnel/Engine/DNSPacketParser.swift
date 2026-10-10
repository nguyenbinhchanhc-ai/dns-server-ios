//
//  DNSPacketParser.swift
//  DNSGuardTunnel
//
//  Created for iOS Local DNS VPN & Optimizer.
//  High-performance binary parser and serializer for RFC 1035 wire-format DNS packets.
//

import Foundation

public final class DNSPacketParser {
    
    // Max pointer decompression recursion to avoid pointer-loop bombs
    private static let maxCompressionPointerHops = 16
    
    // MARK: - Parsing
    
    public static func parse(data: Data) -> DNSPacket? {
        guard data.count >= 12 else { return nil }
        
        // Parse Header
        let id = UInt16(data[0]) << 8 | UInt16(data[1])
        let byte2 = data[2]
        let byte3 = data[3]
        
        let isResponse = (byte2 & 0x80) != 0
        let opcode = (byte2 & 0x78) >> 3
        let isAuthoritative = (byte2 & 0x04) != 0
        let isTruncated = (byte2 & 0x02) != 0
        let recursionDesired = (byte2 & 0x01) != 0
        
        let recursionAvailable = (byte3 & 0x80) != 0
        let rcodeRaw = byte3 & 0x0F
        let responseCode = DNSResponseCode(rawValue: rcodeRaw) ?? .unknown
        
        let qdCount = UInt16(data[4]) << 8 | UInt16(data[5])
        let anCount = UInt16(data[6]) << 8 | UInt16(data[7])
        let nsCount = UInt16(data[8]) << 8 | UInt16(data[9])
        let arCount = UInt16(data[10]) << 8 | UInt16(data[11])
        
        let header = DNSHeader(
            id: id,
            isResponse: isResponse,
            opcode: opcode,
            isAuthoritative: isAuthoritative,
            isTruncated: isTruncated,
            recursionDesired: recursionDesired,
            recursionAvailable: recursionAvailable,
            responseCode: responseCode,
            questionCount: qdCount,
            answerCount: anCount,
            authorityCount: nsCount,
            additionalCount: arCount
        )
        
        var offset = 12
        var questions: [DNSQuestion] = []
        
        // Parse Questions
        for _ in 0..<qdCount {
            guard let (name, newOffset) = parseDomainName(data: data, offset: offset) else {
                return nil
            }
            offset = newOffset
            guard offset + 4 <= data.count else { return nil }
            
            let qtypeRaw = UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
            let qclass = UInt16(data[offset + 2]) << 8 | UInt16(data[offset + 3])
            offset += 4
            
            let question = DNSQuestion(name: name, type: DNSType(rawValue: qtypeRaw), queryClass: qclass)
            questions.append(question)
        }
        
        // Parse Answers
        var answers: [DNSResourceRecord] = []
        for _ in 0..<anCount {
            guard let (rr, newOffset) = parseResourceRecord(data: data, offset: offset) else { break }
            answers.append(rr)
            offset = newOffset
        }
        
        // Parse Authorities
        var authorities: [DNSResourceRecord] = []
        for _ in 0..<nsCount {
            guard let (rr, newOffset) = parseResourceRecord(data: data, offset: offset) else { break }
            authorities.append(rr)
            offset = newOffset
        }
        
        // Parse Additionals
        var additionals: [DNSResourceRecord] = []
        for _ in 0..<arCount {
            guard let (rr, newOffset) = parseResourceRecord(data: data, offset: offset) else { break }
            additionals.append(rr)
            offset = newOffset
        }
        
        return DNSPacket(
            header: header,
            questions: questions,
            answers: answers,
            authorities: authorities,
            additionals: additionals,
            rawData: data
        )
    }
    
    // MARK: - Domain Name Decompression
    
    public static func parseDomainName(data: Data, offset: Int) -> (String, Int)? {
        var currentOffset = offset
        var labels: [String] = []
        var jumped = false
        var returnOffset = offset
        var hops = 0
        
        while currentOffset < data.count {
            guard hops < maxCompressionPointerHops else { return nil } // Prevent loop attacks
            let length = Int(data[currentOffset])
            
            if length == 0 {
                // End of label
                if !jumped {
                    returnOffset = currentOffset + 1
                }
                break
            } else if (length & 0xC0) == 0xC0 {
                // Compression pointer
                guard currentOffset + 1 < data.count else { return nil }
                let pointerByte1 = length & 0x3F
                let pointerByte2 = Int(data[currentOffset + 1])
                let targetOffset = (pointerByte1 << 8) | pointerByte2
                
                if !jumped {
                    returnOffset = currentOffset + 2
                    jumped = true
                }
                currentOffset = targetOffset
                hops += 1
            } else {
                // Standard label
                currentOffset += 1
                guard currentOffset + length <= data.count else { return nil }
                let labelData = data.subdata(in: currentOffset..<(currentOffset + length))
                if let label = String(data: labelData, encoding: .ascii) {
                    labels.append(label)
                } else {
                    labels.append("invalid")
                }
                currentOffset += length
                if !jumped {
                    returnOffset = currentOffset
                }
            }
        }
        
        let fullName = labels.isEmpty ? "." : labels.joined(separator: ".")
        return (fullName, returnOffset)
    }
    
    // MARK: - Resource Record Parsing
    
    private static func parseResourceRecord(data: Data, offset: Int) -> (DNSResourceRecord, Int)? {
        guard let (name, afterNameOffset) = parseDomainName(data: data, offset: offset) else {
            return nil
        }
        var cur = afterNameOffset
        guard cur + 10 <= data.count else { return nil }
        
        let typeRaw = UInt16(data[cur]) << 8 | UInt16(data[cur + 1])
        let rclass = UInt16(data[cur + 2]) << 8 | UInt16(data[cur + 3])
        let ttl = UInt32(data[cur + 4]) << 24 | UInt32(data[cur + 5]) << 16 | UInt32(data[cur + 6]) << 8 | UInt32(data[cur + 7])
        let rdLength = Int(UInt16(data[cur + 8]) << 8 | UInt16(data[cur + 9]))
        cur += 10
        
        guard cur + rdLength <= data.count else { return nil }
        let rdata = data.subdata(in: cur..<(cur + rdLength))
        let recordType = DNSType(rawValue: typeRaw)
        
        var display = ""
        if recordType == .a, rdLength == 4 {
            display = "\(rdata[0]).\(rdata[1]).\(rdata[2]).\(rdata[3])"
        } else if recordType == .aaaa, rdLength == 16 {
            var parts: [String] = []
            for i in stride(from: 0, to: 16, by: 2) {
                let part = UInt16(rdata[i]) << 8 | UInt16(rdata[i + 1])
                parts.append(String(format: "%x", part))
            }
            display = parts.joined(separator: ":")
        } else if recordType == .cname {
            if let (cname, _) = parseDomainName(data: data, offset: cur) {
                display = cname
            }
        }
        
        cur += rdLength
        let rr = DNSResourceRecord(name: name, type: recordType, recordClass: rclass, ttl: ttl, data: rdata, displayValue: display)
        return (rr, cur)
    }
    
    // MARK: - Serialization
    
    public static func serialize(packet: DNSPacket) -> Data {
        var data = Data()
        
        // Header
        data.append(UInt8((packet.header.id >> 8) & 0xFF))
        data.append(UInt8(packet.header.id & 0xFF))
        
        var byte2: UInt8 = 0
        if packet.header.isResponse { byte2 |= 0x80 }
        byte2 |= (packet.header.opcode & 0x0F) << 3
        if packet.header.isAuthoritative { byte2 |= 0x04 }
        if packet.header.isTruncated { byte2 |= 0x02 }
        if packet.header.recursionDesired { byte2 |= 0x01 }
        data.append(byte2)
        
        var byte3: UInt8 = 0
        if packet.header.recursionAvailable { byte3 |= 0x80 }
        byte3 |= (packet.header.responseCode.rawValue & 0x0F)
        data.append(byte3)
        
        data.append(UInt8((packet.header.questionCount >> 8) & 0xFF))
        data.append(UInt8(packet.header.questionCount & 0xFF))
        
        data.append(UInt8((packet.header.answerCount >> 8) & 0xFF))
        data.append(UInt8(packet.header.answerCount & 0xFF))
        
        data.append(UInt8((packet.header.authorityCount >> 8) & 0xFF))
        data.append(UInt8(packet.header.authorityCount & 0xFF))
        
        data.append(UInt8((packet.header.additionalCount >> 8) & 0xFF))
        data.append(UInt8(packet.header.additionalCount & 0xFF))
        
        // Questions
        for q in packet.questions {
            encodeDomainName(name: q.name, into: &data)
            data.append(UInt8((q.type.rawValue >> 8) & 0xFF))
            data.append(UInt8(q.type.rawValue & 0xFF))
            data.append(UInt8((q.queryClass >> 8) & 0xFF))
            data.append(UInt8(q.queryClass & 0xFF))
        }
        
        // Answers
        for a in packet.answers {
            encodeResourceRecord(record: a, into: &data)
        }
        
        // Authorities
        for auth in packet.authorities {
            encodeResourceRecord(record: auth, into: &data)
        }
        
        // Additionals
        for add in packet.additionals {
            encodeResourceRecord(record: add, into: &data)
        }
        
        return data
    }
    
    private static func encodeDomainName(name: String, into data: inout Data) {
        if name == "." || name.isEmpty {
            data.append(0)
            return
        }
        let parts = name.split(separator: ".")
        for part in parts {
            let label = String(part)
            guard let labelData = label.data(using: .ascii), labelData.count <= 63 else { continue }
            data.append(UInt8(labelData.count))
            data.append(labelData)
        }
        data.append(0) // Null byte terminator
    }
    
    private static func encodeResourceRecord(record: DNSResourceRecord, into data: inout Data) {
        encodeDomainName(name: record.name, into: &data)
        data.append(UInt8((record.type.rawValue >> 8) & 0xFF))
        data.append(UInt8(record.type.rawValue & 0xFF))
        data.append(UInt8((record.recordClass >> 8) & 0xFF))
        data.append(UInt8(record.recordClass & 0xFF))
        data.append(UInt8((record.ttl >> 24) & 0xFF))
        data.append(UInt8((record.ttl >> 16) & 0xFF))
        data.append(UInt8((record.ttl >> 8) & 0xFF))
        data.append(UInt8(record.ttl & 0xFF))
        
        let rdLen = UInt16(record.data.count)
        data.append(UInt8((rdLen >> 8) & 0xFF))
        data.append(UInt8(rdLen & 0xFF))
        data.append(record.data)
    }
}
