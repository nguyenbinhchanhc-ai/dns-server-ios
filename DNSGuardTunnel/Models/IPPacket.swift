//
//  IPPacket.swift
//  DNSGuardTunnel
//
//  Created for iOS Local DNS VPN & Optimizer.
//  Represents raw IPv4/UDP packets captured from NEPacketTunnelProvider.
//

import Foundation

public struct IPv4Header {
    public var version: UInt8
    public var ihl: UInt8
    public var typeOfService: UInt8
    public var totalLength: UInt16
    public var identification: UInt16
    public var flags: UInt8
    public var fragmentOffset: UInt16
    public var timeToLive: UInt8
    public var protocolNumber: UInt8
    public var headerChecksum: UInt16
    public var sourceAddress: UInt32
    public var destinationAddress: UInt32
    
    public init?(data: Data) {
        guard data.count >= 20 else { return nil }
        
        let byte0 = data[0]
        self.version = byte0 >> 4
        self.ihl = byte0 & 0x0F
        guard version == 4, ihl >= 5, data.count >= Int(ihl) * 4 else { return nil }
        
        self.typeOfService = data[1]
        self.totalLength = UInt16(data[2]) << 8 | UInt16(data[3])
        self.identification = UInt16(data[4]) << 8 | UInt16(data[5])
        
        let flagsAndFrag = UInt16(data[6]) << 8 | UInt16(data[7])
        self.flags = UInt8((flagsAndFrag & 0xE000) >> 13)
        self.fragmentOffset = flagsAndFrag & 0x1FFF
        
        self.timeToLive = data[8]
        self.protocolNumber = data[9]
        self.headerChecksum = UInt16(data[10]) << 8 | UInt16(data[11])
        
        self.sourceAddress = UInt32(data[12]) << 24 | UInt32(data[13]) << 16 | UInt32(data[14]) << 8 | UInt32(data[15])
        self.destinationAddress = UInt32(data[16]) << 24 | UInt32(data[17]) << 16 | UInt32(data[18]) << 8 | UInt32(data[19])
    }
}

public struct UDPHeader {
    public var sourcePort: UInt16
    public var destinationPort: UInt16
    public var length: UInt16
    public var checksum: UInt16
    
    public init?(data: Data) {
        guard data.count >= 8 else { return nil }
        self.sourcePort = UInt16(data[0]) << 8 | UInt16(data[1])
        self.destinationPort = UInt16(data[2]) << 8 | UInt16(data[3])
        self.length = UInt16(data[4]) << 8 | UInt16(data[5])
        self.checksum = UInt16(data[6]) << 8 | UInt16(data[7])
    }
}

public struct ParsedPacket {
    public var ipHeader: IPv4Header
    public var udpHeader: UDPHeader
    public var ipHeaderBytes: Data
    public var payload: Data
    public var isChecksumValid: Bool
    
    public init?(data: Data) {
        guard let ip = IPv4Header(data: data) else { return nil }
        let ipHeaderLength = Int(ip.ihl) * 4
        guard data.count >= ipHeaderLength + 8 else { return nil }
        guard ip.protocolNumber == 17 else { return nil } // Protocol 17 = UDP
        
        let udpData = data.subdata(in: ipHeaderLength..<data.count)
        guard let udp = UDPHeader(data: udpData) else { return nil }
        
        let udpPayloadLength = Int(udp.length) - 8
        guard udpPayloadLength >= 0, udpData.count >= Int(udp.length) else { return nil }
        
        self.ipHeader = ip
        self.udpHeader = udp
        self.ipHeaderBytes = data.subdata(in: 0..<ipHeaderLength)
        self.payload = udpData.subdata(in: 8..<(8 + udpPayloadLength))
        self.isChecksumValid = false // Evaluated by PacketRepairer
    }
}
